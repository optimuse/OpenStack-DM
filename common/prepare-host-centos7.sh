sed -i -e "
/keepcache/c\keepcache=1
" /etc/yum.conf
#/metadata_expire/c\metadata_expire=never

## Add epel and OpenStack repository.
yum install -y epel-release
#yum localinstall -y ./repo/epel-release*.rpm


## Timezone and ntp
timedatectl set-timezone Asia/Shanghai

yum install -y ntp
systemctl enable ntpd
systemctl start ntpd


## Fireall service

# Remove firewalld, using iptables as linux firewall service.

#1. Disable firewalld service
systemctl mask firewalld
systemctl disable firewalld
yum remove -y firewalld

#2. Install iptables service
yum install -y iptables-services

#3. Enable iptables service
systemctl enable iptables
# systemctl enable ip6tables
systemctl start iptables
# systemctl start ip6tables

## 
yum install -y tcpdump net-tools lsof vim wget

## Update os and reboot.
yum update -y


