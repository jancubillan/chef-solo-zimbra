execute 'config-static-network' do
  command <<-EOF
    nmcli con mod #{node['network']['default_interface']} ipv4.method manual ipv4.addresses #{node['ipaddress']}/24 ipv4.gateway #{node['network']['default_gateway']}
    nmcli con mod #{node['network']['default_interface']} ipv4.dns "8.8.8.8 8.8.4.4"
    nmcli con reload
    nmcli con up #{node['network']['default_interface']}
  EOF
end

package %w(
  bash-completion 
  tmux 
  telnet
  bind-utils
  tcpdump
  wget
  lsof
  rsync
  tar
  nmap-ncat
  chrony
  perl
  net-tools
) do
  action :install
end

execute 'perform-update' do
  command 'yum clean all && yum update -y'
  action :run
end

service 'chronyd' do
  action [ :enable, :start ]
end

timezone 'config-timezone' do
  timezone 'Asia/Singapore'
end

execute 'config-time-sync' do
  command 'timedatectl set-ntp true'
  action :run
end

service 'chronyd' do
  action :restart
end

hostname 'config-hostname' do
  hostname 'mail.example.com'
end

ohai 'reload' do
  action :reload
end

template '/etc/hosts' do
  source 'hosts.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'config-firewall' do
  command <<-EOF
    firewall-cmd --permanent --add-port 25/tcp
    firewall-cmd --permanent --add-port 465/tcp
    firewall-cmd --permanent --add-port 587/tcp
    firewall-cmd --permanent --add-port 110/tcp
    firewall-cmd --permanent --add-port 995/tcp
    firewall-cmd --permanent --add-port 143/tcp
    firewall-cmd --permanent --add-port 993/tcp
    firewall-cmd --permanent --add-port 80/tcp
    firewall-cmd --permanent --add-port 443/tcp
    firewall-cmd --permanent --add-port 7071/tcp
    firewall-cmd --reload
  EOF
end

service 'postfix' do
  action [ :disable, :stop ]
end

package 'dnsmasq' do
  action :install
end

service 'dnsmasq' do
  action [ :enable, :start ]
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[dnsmasq]', :immediately
end

execute 'config-local-dns' do
  command <<-EOF
    nmcli con mod #{node['network']['default_interface']} ipv4.dns 127.0.0.1
    nmcli con reload
    nmcli con up #{node['network']['default_interface']}
  EOF
end

remote_file '/root/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz' do
  source 'https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz'
end

execute 'extract-zmbra-installer' do
  command 'tar xvf /root/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz -C /root'
end

template '/tmp/zimbra_answers.txt' do
  source 'zimbra_answers.txt.erb'
end

template '/tmp/zimbra_config.txt' do
  source 'zimbra_config.txt.erb'
end

execute 'zimbra-install-phase-1' do
  command './install.sh -s < /tmp/zimbra_answers.txt'
  cwd '/root/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220/'
end

execute 'zimbra-install-phase-2' do
  command '/opt/zimbra/libexec/zmsetup.pl -c /tmp/zimbra_config.txt'
end

execute 'set-trusted-ip' do
  command "./zmprov mcf +zimbraMailTrustedIP 127.0.0.1 +zimbraMailTrustedIP #{node['ipaddress']}"
  cwd '/opt/zimbra/bin'
  user 'zimbra'
end

package 'epel-release' do
  action :install
end

package 'fail2ban' do
  action :install
end

template '/etc/fail2ban/jail.local' do
  source 'jail.local.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/fail2ban/jail.d/zimbra.local' do
  source 'zimbra.local.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/fail2ban/jail.d/sshd.local' do
  source 'sshd.local.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/fail2ban/filter.d/zimbra-webmail.conf' do
  source 'zimbra-webmail.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/fail2ban/filter.d/zimbra-smtp.conf' do
  source 'zimbra-smtp.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/fail2ban/filter.d/zimbra-admin.conf' do
  source 'zimbra-admin.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

service 'fail2ban' do
  action [ :enable, :start ]
end
