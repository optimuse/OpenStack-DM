##
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

## Make sure root password login.
cat <<EOF >> /usr/share/lightdm/lightdm.conf.d/05-ubuntu.conf
#手工输入登陆系统的用户名和密码
greeter-show-manual-login=true
#禁用guest用户
allow-guest=false
#登陆界面不显示用户名列表
greeter-hide-users=true
EOF

apt-get install -y fglrx
apt-get install -y x11vnc
cd /etc/X11
wget http://bodhizazen.net/tweaks/kvm.xorg.conf
mv kvm.xorg.conf xorg.conf

##创建vnc密码
x11vnc --storepasswd

cat <<EOF > /etc/init/x11vnc.conf
# description "start and stop x11vnc"

description "x11vnc"

start on runlevel [2345]
stop on runlevel [^2345]

console log
#chdir /home/
#setuid 1000
#setgid 1000

respawn
respawn limit 20 5

exec x11vnc -xkb -noxrecord -noxfixes -noxdamage -forever -repeat -display :0 -auth /var/run/lightdm/root/:0 -bg -o /var/log/x11vnc.log -rfb
auth /root/.vnc/passwd -rfbport 5900

EOF

apt-get update
apt-get upgrade -y
apt-get install -y cloud-init cloud-utils cloud-initramfs-growroot cloud-initramfs-rescuevol

cat <<EOF > /etc/cloud/cloud.cfg.d/90_dpkg.cfg
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, Azure, AltCloud, OVF, MAAS, GCE, Openstack, CloudSigma, Ec2, CloudStack, None ]
EOF


cat <<EOF > /etc/cloud/cloud.cfg
user: root
disable_root: 0
preserve_hostname: False
manage_etc_hosts: False
# datasource_list: ["NoCloud", "ConfigDrive", "OVF", "MAAS", "Ec2", "CloudStack"]

cloud_init_modules:
 - bootcmd
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - ssh

cloud_config_modules:
 - disk-setup
 - mounts
 - ssh-import-id
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-update-upgrade
 - landscape
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd
 - byobu

cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - keys-to-console
 - phone-home
EOF


sed -i "
/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0,115200n8 console=tty1 nomodeset\"
/GRUB_GFXMODE/c\GRUB_GFXMODE=800x600
" /etc/default/grub

update-grub
