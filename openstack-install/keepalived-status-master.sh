#!/usr/bin/bash

## keepalived use this script 
## 1. to start/stop haproxy.
## 2. to promote mongo on this node a primary
## 3. to make redis on this node a master (slaveof no one)
## 4. to restart ceilomter (ceilomter-api can't reautoconnect mongodb).
## 5. to restart rabbitmq
## 5. to restart all openstack-related services.(reconnect rabbitmq)

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh


# systemctl restart haproxy

# mysql
# nothing need to do for mysql

# mongodb
sh -x $TOOL_BASE/change-mongo-to-primary.sh 127.0.0.1

# redis
redis-cli -h 127.0.0.1 -p 6379 slaveof no one
redis-cli -h 127.0.0.1 -p 6379 config rewrite

# rabbitmq-server
systemctl stop rabbitmq-server
sleep 2
systemctl start rabbitmq-server
systemctl restart rabbitmq-server

# openstack components
sh -x $TOOL_BASE/restart-openstack.sh
