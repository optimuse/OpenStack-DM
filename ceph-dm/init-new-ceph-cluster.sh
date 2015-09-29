#!/bin/bash

## First, use 'add-new-ceph.sh' script to install ceph on Ceph Nodes.

usage() {
  echo "Usage: $0 <ceph-deploy-dir> <ceph-mon-node1-hostname> <ceph-mon-node2-hostname>..."
  echo "<ceph-deploy-dir> will be used as the ceph-deploy base directory."
  exit 
}

[[ $# -lt 2 ]] && usage

DEPLOY_DIRNAME="$1"
CEPH_MON_NODES="${@##$1}"

mkdir ./$DEPLOY_DIRNAME
cd ./$DEPLOY_DIRNAME

# ceph-deploy new ceph-mon-1 ceph-mon-2 ceph-mon-3
ceph-deploy new $CEPH_MON_NODES
ceph-deploy mon create-initial

## example to add ceph osd node.
# ceph-deploy disk list ceph-61-2-4
# ceph-deploy osd create ceph-61-2-4:sdb
# ceph-deploy osd create ceph-61-2-4:sdc
