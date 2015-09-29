#!/bin/bash

## swift ports 6000,6001,6002
## rsync 873
## swift proxy 8080

# keepalived vvrp
# ntp 123
# rsyslogd 514
# httpd 80,443
# nagios 5666
# collectd port 25826 (udp)
# redis  6379,26379
# influxdb 8083,8086,8088
# mysql 3306,4444,4567,4568
# message queue 5672,15672,25672,4369
# keystone 5000,35357
# glance 9292,9191
# scsitarget 3260 & cinder 8776
# neutron 9696
# novncproxy 6080 & xvpvncproxy 6081
# ec2 8773 & nova-compute 8774 & metadata 8775
# ceilometer 8777
# heat 8004,8000
# mongodb 27017,28017,27018(arbiter)
# ceph-mon 6789
# ceph-osd 6800:7300
# qemu vnc 5900:5999
# libvirtd 16509
# live-migation 49152:49261

# elasticsearch 9200,9300
# kibana 5601

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

### Modify nova compute node's iptables.
cat <<EOF > /etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT

# keepalived

-A INPUT -p vrrp -j ACCEPT

# Add by openstack
-A INPUT -p udp --dport 123 -j ACCEPT
-A INPUT -p udp --dport 514 -j ACCEPT
-A INPUT -p udp --dport 53 -j ACCEPT
-A INPUT -p udp --dport 67 -j ACCEPT
-A INPUT -p udp --dport 25826 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 6379,26379 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 5666 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 3306,4444,4567,4568 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 5672,15672,25672,4369 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 5000,35357 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8083,8086,8088 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 9292,9191 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 3260,8776 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 9696 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 6080,6081 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8773,8774,8775 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8777 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8004,8000 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 27017,28017,27018,28018 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 6789 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 6800:7300 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 9200,9300 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 5601 -j ACCEPT
-A INPUT -p tcp -m multiport --source $CONT_MGMT_NET --dports 5900:5999 -j ACCEPT
-A INPUT -p tcp -m multiport --source $CONT_MGMT_NET --dports 16509 -j ACCEPT
-A INPUT -p tcp -m multiport --source $CONT_MGMT_NET --dports 49152:49261 -j ACCEPT
# openstack

-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
