#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

rm -rf /var/lib/rabbitmq/mnesia/*
systemctl start rabbitmq-server

rabbitmqctl add_user openstack ${MQ_PASS}
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmqctl set_policy ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
