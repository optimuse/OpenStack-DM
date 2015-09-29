cd /etc/yum.repos.d/
yum install -y wget
wget http://mirrors.163.com/.help/CentOS5-Base-163.repo
mv CentOS-Base.repo CentOS-Base.repo.origin
mv CentOS5-Base-163.repo CentOS-Base.repo
yum clean all

yum install -y epel-release
yum update -y

yum install -y cloud-init

cat <<EOF > /etc/cloud/cloud.cfg
user: root
disable_root: False
preserve_hostname: False
manage_etc_hosts: False

## lock-passwd defaults to True
users:
  - name: root
    lock-passwd: False

cloud_init_modules:
 - migrator
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - rsyslog
 - users-groups
 - ssh

cloud_config_modules:
 - mounts
 - locale
 - set-passwords
 - yum-add-repo
 - package-update-upgrade-install
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd

cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message
EOF

yum install -y ntp
chkconfig ntpd on


## Enable dhcp on eth0
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet 
ONBOOT=yes
BOOTPROTO=dhcp
EOF

## Disable zerocon route 169.254.0.0
## see: http://www.cyberciti.biz/faq/fedora-centos-rhel-linux-disable-zeroconf-route-169-254-0-0/

cat <<EOF > /etc/sysconfig/network
NETWORKING=yes
NOZEROCONF=yes
EOF

## Clean up MAC addresses.
