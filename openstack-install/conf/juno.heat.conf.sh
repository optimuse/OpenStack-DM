#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_heat="openstack-config --set /etc/heat/heat.conf"
OSC_heat_del="openstack-config --del /etc/heat/heat.conf"
$OSC_heat DEFAULT verbose True
$OSC_heat DEFAULT notification_driver messagingv2
$OSC_heat DEFAULT control_exchange heat
$OSC_heat DEFAULT lock_path /var/lib/heat/tmp

$OSC_heat DEFAULT rpc_backend rabbit
$OSC_heat DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_heat DEFAULT rabbit_userid openstack
$OSC_heat DEFAULT rabbit_password $MQ_PASS
$OSC_heat DEFAULT rabbit_retry_interval 1
$OSC_heat DEFAULT rabbit_retry_backoff 2
$OSC_heat DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  $OSC_heat_del DEFAULT rabbit_hosts
  $OSC_heat_del DEFAULT rabbit_durable_queues
  $OSC_heat_del DEFAULT rabbit_ha_queues
else
  $OSC_heat DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_heat DEFAULT rabbit_durable_queues true
  $OSC_heat DEFAULT rabbit_ha_queues true
fi



$OSC_heat DEFAULT heat_metadata_server_url http://$HEAT_MGMT_IP:8000
$OSC_heat DEFAULT heat_waitcondition_server_url http://$HEAT_MGMT_IP:8000/v1/waitcondition
$OSC_heat database connection mysql://$HEAT_DB_USER:$HEAT_DB_PASS@$MYSQL_MGMT_IP/heat

$OSC_heat DEFAULT auth_strategy keystone
$OSC_heat keystone_authtoken identity_uri http://$KEYSTONE_MGMT_IP:35357/
$OSC_heat keystone_authtoken auth_uri http://$KEYSTONE_API_IP:5000/
$OSC_heat keystone_authtoken admin_user heat
$OSC_heat keystone_authtoken admin_tenant_name service
$OSC_heat keystone_authtoken admin_password $USER_SERVICE_PASS
$OSC_heat ec2authtoken auth_uri http://$KEYSTONE_MGMT_IP:5000/

## Listen address.
if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_heat heat_api bind_host $MGMT_IP
  $OSC_heat heat_api_cfn bind_host $MGMT_IP
  $OSC_heat heat_api_cloudwatch bind_host $MGMT_IP
else
  $OSC_heat heat_api bind_host 0.0.0.0
  $OSC_heat heat_api_cfn bind_host 0.0.0.0
  $OSC_heat heat_api_cloudwatch bind_host 0.0.0.0
fi

