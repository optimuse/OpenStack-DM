#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

if [ $# -ne 1 ]; then
  echo "Usage: $0 <vmuuid>"
  exit 1
fi


VM_UUID=$1

while read n_ip n_hostname; do
  echo $n_ip
  ssh $n_ip "virsh list --all --uuid | grep $VM_UUID" </dev/null
  ssh $n_ip "ls /var/lib/nova/instances/ | grep $VM_UUID" </dev/null
done < $MAP_BASE/compute-node.list
