#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

bash -x $CONF_BASE/iptables.openstack.sh
systemctl restart iptables
