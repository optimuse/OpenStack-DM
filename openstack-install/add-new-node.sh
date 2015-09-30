#!/bin/bash

usage() {
  echo "Usage: $0 <hostip> <hostname> <extip>"
  exit 1
}

[[ $# -ne 3 ]] && usage

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

## **********************************************************

export node_ip=$1
export node_hostname=$2
export node_ext_ip=$3


# Add new node entry to etc.hosts, this file will be synced to all nodes.
if ! grep -q $node_ip /etc/hosts; then
  cat <<EOF >> /etc/hosts
$node_ip $node_hostname
EOF
fi

# Record all nodes in openstack cluster.
if ! grep -sq $node_ip $MAP_BASE/all-node.list; then
  cat <<EOF >> $MAP_BASE/all-node.list
$node_ip $node_hostname
EOF
fi

# Configure Deploy Node's password-less login in.
ssh-copy-id -i ~/.ssh/id_rsa.pub $node_ip

# Make sure rysnc is installed.
ssh -o StrictHostKeyChecking=no $node_ip "yum install -y rsync"


# Sync /etc/hosts to all nodes.
# Sync [deploy scripts package] to ALL nodes just for consistency in case of modification.
while read n_ip n_name; do
  echo $n_name
  rsync -az /etc/hosts $n_ip:/etc/hosts
  rsync --exclude my.ip --exclude .git --exclude .gitignore \
        -az $BASE_DIR/../  $n_ip:$DEPLOY_TEMP_DIR/OpenStack-DM/
done < $MAP_BASE/all-node.list

