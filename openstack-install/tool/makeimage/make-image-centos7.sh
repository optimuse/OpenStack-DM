cd /etc/yum.repos.d/
yum install -y wget
wget http://mirrors.163.com/.help/CentOS7-Base-163.repo
mv CentOS-Base.repo CentOS-Base.repo.origin
mv CentOS7-Base-163.repo CentOS-Base.repo
yum clean all

yum install -y epel-release
yum update -y


firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --zone=public --add-port=10050/tcp
firewall-cmd --zone=public --add-port=10051/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp


yum install -y cloud-init cloud-utils cloud-utils-growpart

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
nmcli con mod eth0 connection.autoconnect yes


## Modify grub
# about linux console display resolution, see:
# http://www.gregfolkert.net/info/vesa-display-codes.html

sed -i 's/ rhgb//g' /etc/sysconfig/grub
sed -i 's/ quiet//g' /etc/sysconfig/grub

grep ^GRUB_CMDLINE_LINUX /etc/sysconfig/grub | grep vga=788
if [[ $? -ne 0 ]]; then
sed -i 's/^GRUB_CMDLINE_LINUX=.*$/& serial=tty0 console=ttyS0,115200n8 console=tty1 vga=788/g' /etc/sysconfig/grub
fi

grub2-mkconfig -o /boot/grub2/grub.cfg
