#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

rm -rf /var/lib/rabbitmq/mnesia/*
systemctl start rabbitmq-server

rabbitmqctl stop_app
rabbitmqctl cluster_status
rabbitmqctl join_cluster rabbit@$FIRST_CONT_HOSTNAME
rabbitmqctl cluster_status
rabbitmqctl start_app

rabbitmqctl cluster_status
rabbitmqctl set_policy ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'

