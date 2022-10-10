#!/bin/bash

export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

is_root=$(id -u)

if (( is_root != 0 )); then
  echo "Please run as root user." >&2
  exit 1
fi

ZIMBRA_CONFIG_DEFAULT='cookbooks/zimbra/templates/default/zimbra_config.txt.default'
ZIMBRA_CONFIG_TEMPLATE='cookbooks/zimbra/templates/default/zimbra_config.txt.erb'
ZIMBRA_RECIPE_DEFAULT='cookbooks/zimbra/templates/default/default.rb.default'
ZIMBRA_RECIPE='cookbooks/zimbra/recipes/default.rb'

if [[ "$*" =~ "--uninstall" ]]; then
  zimbra_installer='/root/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220/install.sh'

  if [[ -f "${zimbra_installer}" ]]; then
    cd "$(dirname ${zimbra_installer})" || { echo "Unable to run uninstall script, exiting..."; exit 1; }
    ./install.sh -u
  else
    echo "Unable to find uninstall script, exiting..." >&2
    exit 1
  fi

  zimbra_packages=$(rpm -qa | grep zimbra | paste -s -d" ")

  if [[ -n "${zimbra_packages}" ]]; then
    yum remove -y "${zimbra_packages}"
  fi

  if pgrep -f zimbra >/dev/null; then
    kill -9 "$(pgrep -f zimbra)"
  fi

  userdel -r zimbra
  rm -rf /opt/zimbra
  cd - || { echo "Unable access to Chef Solo directory, exiting..."; exit 1; }
  cp -v "${ZIMBRA_CONFIG_DEFAULT}" "${ZIMBRA_CONFIG_TEMPLATE}"
  cp -v "${ZIMBRA_RECIPE_DEFAULT}" "${ZIMBRA_RECIPE}"
  exit 0
fi

if [[ -d /opt/zimbra ]]; then
  echo "Zimbra directory detected, uninstall Zimbra first. Exiting..." >&2
  exit 1
fi

echo ""
read -rp "What is the admin password? [zimbra4ever] " ZIMBRA_ADMIN_PASSWORD
read -rp "What is the fully qualified domain name? [mail.example.com] " ZIMBRA_FQDN
read -rp "What is the Timezone? [Asia/Singapore] " ZIMBRA_TIMEZONE

echo ""
echo "Here are the details"
echo ""
echo "Zimbra Administrator Password: ${ZIMBRA_ADMIN_PASSWORD:-zimbra4ever}"
echo "Zimbra Fully Qualified Domain Name: ${ZIMBRA_FQDN:-mail.example.com}"
echo "Zimbra Timezone: ${ZIMBRA_TIMEZONE:-Asia/Singapore}"

echo ""
read -rp "Do you want to proceed with installation? (y/n)? [n] " answer
case "${answer:0:1}" in
  y|Y)
    echo ""
    echo "Installing Zimbra..."
    ;;
  *)
    echo ""
    echo "Exiting..."
    exit 0
    ;;
esac

ZIMBRA_MAILBOXD_MEMORY=$(free -m | awk 'NR==2{printf "%.0f\n", $2*0.25 }')
ZIMBRA_SYSTEM_MEMORY=$(free -h | awk 'NR==2{printf "%.0f\n", $2 }')

ZIMBRA_RANDOM_CHARS_1=$(date | md5sum | cut -c 1-9)
sleep 3
ZIMBRA_RANDOM_CHARS_2=$(date | md5sum | cut -c 1-14)

cp -v "${ZIMBRA_CONFIG_DEFAULT}" "${ZIMBRA_CONFIG_TEMPLATE}"
cp -v "${ZIMBRA_RECIPE_DEFAULT}" "${ZIMBRA_RECIPE}"

sed -i "s|_ZIMBRA_ADMIN_PASSWORD|${ZIMBRA_ADMIN_PASSWORD:-zimbra4ever}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_FQDN|${ZIMBRA_FQDN:-mail.example.com}|g" "${ZIMBRA_RECIPE}"
sed -i "s|_ZIMBRA_MAILBOXD_MEMORY|${ZIMBRA_MAILBOXD_MEMORY}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_SYSTEM_MEMORY|${ZIMBRA_SYSTEM_MEMORY}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_RANDOM_CHARS_1|${ZIMBRA_RANDOM_CHARS_1}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_RANDOM_CHARS_2|${ZIMBRA_RANDOM_CHARS_2}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_TIMEZONE|${ZIMBRA_TIMEZONE:-Asia/Singapore}|g" "${ZIMBRA_CONFIG_TEMPLATE}"
sed -i "s|_ZIMBRA_TIMEZONE|${ZIMBRA_TIMEZONE:-Asia/Singapore}|g" "${ZIMBRA_RECIPE}"

if grep -q 'CentOS Linux release 7.9.2009 (Core)' /etc/centos-release; then
  if ! command -v chef-solo >/dev/null; then
    curl -L https://omnitruck.chef.io/install.sh | bash -s -- -P chef -v 14.15.6
  fi

  chef-solo -c solo.rb -j zimbra.json
else
  echo "Unsupported Operating System, exiting..." >&2
  exit 1
fi
