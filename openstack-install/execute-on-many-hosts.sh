#!/bin/bash

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

if [ $# -ne 2 ]; then
  echo "Usage: $0 <node_list_file> <script_to_execute>"
  echo "Example: $0 $MAP_BASE/compute-node.list $RELAY_BASE/modfiy.nova.conf.example.sh"
  exit 1
fi

node_list_file=$1
script_to_execute=$2
script_basename=$(basename $2)

while read n_ip n_name; do
  echo $n_name
  rsync -av $script_to_execute $n_ip:/tmp/$script_basename
  ssh -n $n_ip "
  export MGMT_IP=$n_ip
  bash -x /tmp/$script_basename
  "
done < $node_list_file
