#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh


## Restart Controller services on this controller node.
sh -x $TOOL_BASE/ssr-service.sh restart controller

## Restart Compute services on every compute node.
while read n_ip n_name; do
  echo "Operating on Compute: $n_name, $n_ip"
  ssh -o StrictHostKeyChecking=no $n_ip "$DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/tool/ssr-service.sh restart compute" < /dev/null
done < $MAP_BASE/compute-node.list

## Restart Controller services on other controller node.
while read n_ip n_name n_ext_ip; do
  echo "Operating on Controller: $n_name, $n_ip"
  [[ $n_ip == $MGMT_IP ]] && continue
  ssh -o StrictHostKeyChecking=no $n_ip "$DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/tool/ssr-service.sh restart controller" </dev/null
done < $MAP_BASE/controller-node.list
