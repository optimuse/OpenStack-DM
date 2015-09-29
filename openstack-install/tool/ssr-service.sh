#!/bin/bash


SERVICES_keystone=(openstack-keystone)

SERVICES_glance=(
openstack-glance-api
openstack-glance-registry
)

SERVICES_cinder=(
openstack-cinder-api
openstack-cinder-scheduler
openstack-cinder-volume
)

SERVICES_nova=(
openstack-nova-api 
openstack-nova-cert 
openstack-nova-consoleauth 
openstack-nova-scheduler
openstack-nova-conductor
openstack-nova-novncproxy
)

SERVICES_ceilometer=(
openstack-ceilometer-api
openstack-ceilometer-notification
openstack-ceilometer-central
openstack-ceilometer-collector
openstack-ceilometer-alarm-evaluator
openstack-ceilometer-alarm-notifier)

SERVICES_heat=(
openstack-heat-api
openstack-heat-api-cfn
openstack-heat-engine
)


####################

SERVICES_compute=(
openstack-nova-metadata-api
openstack-nova-network
openstack-nova-compute
openstack-ceilometer-compute
)

SERVICES_controller=(
keystone
glance
cinder
nova
ceilometer
heat
)

######################

action=$1
service_name=$2

if [[ $service_name == "controller" ]]; then
  for s in ${SERVICES_controller[*]}; do
    eval systemctl \$action \${SERVICES_${s}[*]}
  done
else
  eval systemctl \$action \${SERVICES_${service_name}[*]}
fi

