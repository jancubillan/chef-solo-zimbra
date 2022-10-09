chef-solo-zimbra
================

This Chef Solo repo automates the process of installing single-server Zimbra Open Source Edition v8.8.15 on CentOS 7.

Requirements
------------

1) Must be a fresh CentOS 7 minimal installation.
2) Static network configuration must be already set.
3) This repo will be cloned on the node where Zimbra will be installed.
4) Run as root.
5) Repo is cloned at /root directory.

Running the script
------------------

To install:

    # cd /root/chef-solo-zimbra
    # ./install.sh

To uninstall:

    # cd /root/chef-solo-zimbra
    # ./install.sh --uninstall

Other Features
--------------

The recipe in the cookbook also installs Fail2Ban configured with predetermined jails and filters. You can view them in /etc/fail2ban directory.

    # fail2ban-client status
      Status
      |- Number of jail:	4
      `- Jail list:	sshd, zimbra-admin, zimbra-smtp, zimbra-webmail

License
-------

MIT License

Author Information
------------------

- Author: Jan Cubillan
- GitHub: https://github.com/jancubillan
