#!/bin/bash

usage() {
  echo "Usage: $0 <ipaddress>"
  echo "<ipaddress> is the address on which collectd server listens."
  echo "Collecd client sends data to this address."
  exit
}
[[ $# -ne 1 ]] && usage

# COLLECTD_SERVER_IP="172.30.0.100"
COLLECTD_SERVER_IP=$1

## collectd client, send data to collectd server.

yum install -y collectd collectd-virt
#yum install -y collectd-rrdtool
setsebool -P collectd_tcp_network_connect on

cat <<EOF > /etc/collectd.d/network.conf
LoadPlugin network
<Plugin network>
        <Server "$COLLECTD_SERVER_IP" "25826">
                SecurityLevel None
        </Server>
</Plugin>
EOF


## collectd <=5.4  libvirt
## collectd >= 5.5 virt
cat <<EOF > /etc/collectd.d/virt.conf
LoadPlugin virt
<Plugin virt>
        Connection "qemu+tcp:///system"
        RefreshInterval 60
#       Domain "name"
#       BlockDevice "name:device"
#       InterfaceDevice "name:device"
#       IgnoreSelected false
        HostnameFormat uuid
</Plugin>
EOF

systemctl enable collectd
systemctl start collectd
systemctl restart collectd
