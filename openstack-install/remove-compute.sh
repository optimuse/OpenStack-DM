#!/bin/bash

usage() {
  echo "Usage: $0 <hostip> <hostname>"
  exit 1
}

[[ $# -ne 2 ]] && usage

export node_ip=$1
export node_hostname=$2

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

## **********************************************************


# Remove node entry from /etc/hosts, this file will be synced to all nodes.
if grep -q $node_ip /etc/hosts; then
  sed -i "/$node_ip $node_hostname/d" /etc/hosts
fi

# Remove node entry from all-node.list
if grep -sq $node_ip $MAP_BASE/all-node.list; then
  sed -i "/$node_ip $node_hostname/d" $MAP_BASE/all-node.list
fi

# Remove node entry from compute-node.list
if grep -sq $node_ip $MAP_BASE/compute-node.list; then
  sed -i "/$node_ip $node_hostname/d" $MAP_BASE/compute-node.list
fi

source $RC_BASE/keystone-rc.admin
service_id=$(nova service-list --binary nova-compute --host $node_hostname | sed -n '4p' | awk '{print $2}')
[[ -n $service_id ]] && nova service-delete  $service_id
service_id=$(nova service-list --binary nova-network --host $node_hostname | sed -n '4p' | awk '{print $2}')
[[ -n $service_id ]] && nova service-delete  $service_id

# Sync /etc/hosts to all nodes.
while read n_ip n_name; do
  echo $n_name
  rsync -az /etc/hosts $n_ip:/etc/hosts
done < $MAP_BASE/all-node.list
