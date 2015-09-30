#!/bin/bash

yum install -y collectd collectd-virt
setsebool -P collectd_tcp_network_connect on

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
