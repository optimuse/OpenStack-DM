#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

SERVICES_all=(
keystone
glance
cinder
nova
ceilometer
heat
)

config_service() {
  case "$1" in
    keystone) bash -x $CONF_BASE/juno.keystone.conf.sh ;;
    glance) bash -x $CONF_BASE/juno.glance-api.conf.sh; \
            bash -x $CONF_BASE/juno.glance-registry.conf.sh; \
            bash -x $CONF_BASE/ceph.glance.conf.sh ;;
    cinder) bash -x $CONF_BASE/juno.cinder.conf.sh; \
            bash -x $CONF_BASE/ceph.cinder.conf.sh ;;
    nova) bash -x $CONF_BASE/juno.nova.conf.sh; \
          bash -x $CONF_BASE/ceph.nova.conf.sh ;;
    ceilometer) bash -x $CONF_BASE/juno.ceilometer.conf.sh ;;
    heat) bash -x $CONF_BASE/juno.heat.conf.sh ;;
    *) ;;
  esac
}

SERVICES_name="$*"

for s in $SERVICES_name; do 
  if [[ $s != "all" ]]; then
    config_service $s
  else
    for i in ${SERVICES_all[*]}; do
      config_service $i
    done
  fi
done
