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


: <<comments
# Remove node entry from /etc/hosts, this file will be synced to all nodes.
if grep -q $node_ip /etc/hosts; then
  sed -i "/$node_ip $node_hostname/d" /etc/hosts
fi
comments

# Remove node entry from all-node.list
if grep -sq $node_ip $MAP_BASE/all-node.list; then
  sed -i "/$node_ip $node_hostname/d" $MAP_BASE/all-node.list
fi

# Remove node entry from controller-node.list
if grep -sq $node_ip $MAP_BASE/controller-node.list; then
  sed -i "/$node_ip $node_hostname/d" $MAP_BASE/controller-node.list
fi

source $RC_BASE/keystone-rc.admin

delete_service_nova() {
  service_id=$(nova service-list --binary $1 --host $2 | sed -n '4p' | awk '{print $2}')
  [[ -n $service_id ]] && nova service-delete  $service_id
}

delete_service_nova nova-conductor $node_hostname
delete_service_nova nova-consoleauth $node_hostname
delete_service_nova nova-cert $node_hostname
delete_service_nova nova-scheduler $node_hostname
delete_service_nova nova-network $node_hostname


## Remove mongo slave instance.
mongo --host $MONGO_MGMT_IP <<EOF
use admin
db.auth("$MONGO_ADMIN_USER", "$MONGO_ADMIN_PASS")
rs.status()
rs.remove("$node_hostname:27017")
rs.status()
exit
EOF
