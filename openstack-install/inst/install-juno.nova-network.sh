#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

##############################

yum install -y http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm

# Nova (nova-network)
yum install -y openstack-utils openstack-selinux
yum install -y openstack-nova-network openstack-nova-api

bash -x $CONF_BASE/juno.nova.conf.sh

if [ $USE_MULTIHOST -eq 0 ]; then
  ## Start nova-network service on controller node if not using multihost
  systemctl enable openstack-nova-network
  systemctl start openstack-nova-network
  systemctl restart openstack-nova-network
else
  ## Start nova-metadata-api service on each compute node if using multihost.
  systemctl enable openstack-nova-metadata-api
  systemctl start openstack-nova-metadata-api
  systemctl restart openstack-nova-metadata-api
fi
