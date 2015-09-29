#!/bin/bash

usage() {
  echo "Usage: $0  {initial|extra}"
  echo "'initial' means this is the first controller."
  echo "'extra' means this is NOT the first controller."
  exit 1
}

[[ $# -ne 1 ]] && usage
[[ $1 == "initial" ]] || [[ $1 == "extra" ]] || usage

FLAG=$1

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh


## **********************************************************

## HA
bash $INST_BASE/install-juno.controller-ha.sh $FLAG

## Base
bash $INST_BASE/install-juno.controller-db.sh $FLAG
bash $INST_BASE/install-juno.controller-mq.sh $FLAG
bash $INST_BASE/install-juno.controller-mongodb.sh $FLAG
bash $INST_BASE/install-juno.controller-redis.sh $FLAG 

## OpenStack Core Components.
# bash $INST_BASE/install-juno.controller-core.sh $FLAG

if [[ $USE_MULTIHOST -eq 0 ]]; then
  # bash $INST_BASE/install-juno.nova-network.sh
  exit
fi

