#!/bin/bash

yum install -y collectd collectd-ceph
setsebool -P collectd_tcp_network_connect on

## collectd can't work with selinux.
setenforce 0
sed -i '/^SELINUX=/c\SELINUX=permissive' /etc/selinux/config
##


## collectd ceph plugin.
cat <<EOF > /etc/collectd.d/ceph.conf
LoadPlugin ceph
<Plugin ceph>
  LongRunAvgLatency false
  ConvertSpecialMetricTypes true
EOF
for i in `ls /var/run/ceph/*.asok`; do
  filename=${i##*/}; echo $filename;
  fileprefix=${filename%%.asok}; echo $fileprefix;
  cat <<EOF >> /etc/collectd.d/ceph.conf
  <Daemon "$fileprefix">
    SocketPath "$i"
  </Daemon>
EOF
done
cat <<EOF >> /etc/collectd.d/ceph.conf
</Plugin>
EOF

systemctl enable collectd
systemctl start collectd
systemctl restart collectd
