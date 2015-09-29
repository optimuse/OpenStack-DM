#!/bin/bash

usage() {
  echo "Usage: $0 <ipaddress>"
  echo "<ipaddress> is the address on which collectd server listens, can be 0.0.0.0"
  exit
}
[[ $# -ne 1 ]] && usage

#LISTEN_ADDRESS="172.30.0.100"
LISTEN_ADDRESS=$1

yum install -y collectd
#yum install -y collectd-rrdtool
setsebool -P collectd_tcp_network_connect on

## collectd server 

cat <<EOF > /etc/collectd.d/network.conf
LoadPlugin network
<Plugin network>
        <Listen "$LISTEN_ADDRESS" "25826">
                SecurityLevel None
        </Listen>
</Plugin>
EOF

systemctl enable collectd
systemctl start collectd
systemctl restart collectd

