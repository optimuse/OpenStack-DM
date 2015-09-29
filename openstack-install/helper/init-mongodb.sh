#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

## This should be done before enable mongodb auth.

mongo --host $MONGO_MGMT_IP <<EOF
rs.initiate()
exit
EOF
sleep 2

## create mongo admin.
mongo --host $MONGO_MGMT_IP <<EOF
use admin
db.createUser({
user: "$MONGO_ADMIN_USER", 
pwd: "$MONGO_ADMIN_PASS",
roles:["root"]})
exit
EOF

## create ceilometer.
mongo --host $MONGO_MGMT_IP <<EOF
db = db.getSiblingDB("ceilometer")
db.createUser({user: "$CEILOMETER_DB_USER", 
pwd: "$CEILOMETER_DB_PASS",
roles: ["readWrite", "dbAdmin" ]})
EOF
