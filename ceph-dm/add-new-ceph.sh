#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <hostip> <hostname>"
  exit 1
fi 

ceph_ip=$1
ceph_hostname=$2

CEPH_NODE_LIST=./ceph-node.list

### Configure ssh password-less login
ssh-copy-id -i ~/.ssh/id_rsa.pub $ceph_ip

## Install Ceph

# see http://ceph.com/docs/master/install/get-packages/
ssh $ceph_ip "
yum install -y http://ceph.com/rpm-hammer/el7/noarch/ceph-release-1-0.el7.noarch.rpm
yum install -y ceph rsync
yum install -y ceph-deploy
## visudo
## comment out 'Defaults requiretty'
## setenforce 0
"
ssh $ceph_ip "bash -s" -- < ./setup-iptables-on-ceph.sh

# Note: ceph-deploy is only needed on the 'Admin Node', here we install ceph-deploy on
# every Ceph Node just for simplicity and convenience.

# /etc/hosts file
if ! grep -q $ceph_ip /etc/hosts; then
  echo "$ceph_ip $ceph_hostname" >> /etc/hosts
fi

if ! grep -q $ceph_ip $CEPH_NODE_LIST; then
  echo "$ceph_ip $ceph_hostname" >> $CEPH_NODE_LIST
fi

while read node_ip node_name; do
  echo $node_name
  rsync -av /etc/hosts ${node_ip}:/etc/hosts
done < $CEPH_NODE_LIST
