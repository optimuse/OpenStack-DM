#!/bin/bash

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

# Sync deploy package to all nodes just for consistency in case of modification.
while read n_ip n_name; do
  echo $n_name
  rsync -az /etc/hosts $n_ip:/etc/hosts
  rsync --exclude my.ip --exclude .git --exclude .gitignore \
        -az $BASE_DIR/../  $n_ip:$DEPLOY_TEMP_DIR/openstack-dm/
done < $MAP_BASE/all-node.list

