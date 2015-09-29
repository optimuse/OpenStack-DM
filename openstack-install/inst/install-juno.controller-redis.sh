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


##
## redis for Ceilometer.

yum install -y redis

# bind 0.0.0.0

if [[ $FLAG == "extra" ]]; then
  if ! grep -sq '^slaveof ' /etc/redis.conf; then
    echo "slaveof $CONT_MGMT_IP 6379" >> /etc/redis.conf
  else
    sed -i "/^slaveof /c\slaveof $CONT_MGMT_IP 6379" /etc/redis.conf
  fi 
fi
 

systemctl enable redis
systemctl start redis
systemctl restart redis

:<<comments
if ! grep -sq '^sentinel monitor mymaster' /etc/redis-sentinel.conf; then
  echo "sentinel monitor mymaster $MGMT_IP 6379 2" >> /etc/redis-sentinel.conf
else
  sed -i "/^sentinel monitor mymaster/c\sentinel monitor mymaster $MGMT_IP 6379 2" /etc/redis-sentinel.conf
fi

systemctl enable redis-sentinel
systemctl start redis-sentinel
systemctl restart redis-sentinel
comments
