#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_ceilometer="openstack-config --set /etc/ceilometer/ceilometer.conf"
OSC_ceilometer_del="openstack-config --del /etc/ceilometer/ceilometer.conf"

$OSC_ceilometer database connection mongodb://$CEILOMETER_DB_USER:$CEILOMETER_DB_PASS@$MYSQL_MGMT_IP:27017/ceilometer
$OSC_ceilometer DEFAULT verbose True

$OSC_ceilometer DEFAULT rpc_backend rabbit
$OSC_ceilometer DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_ceilometer DEFAULT rabbit_userid openstack
$OSC_ceilometer DEFAULT rabbit_password $MQ_PASS
$OSC_ceilometer DEFAULT rabbit_retry_interval 1
$OSC_ceilometer DEFAULT rabbit_retry_backoff 2
$OSC_ceilometer DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  #$OSC_ceilometer DEFAULT rabbit_hosts $MQ_MGMT_IP
  $OSC_ceilometer_del DEFAULT rabbit_hosts
  $OSC_ceilometer_del DEFAULT rabbit_durable_queues
  $OSC_ceilometer_del DEFAULT rabbit_ha_queues
else
  $OSC_ceilometer DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_ceilometer DEFAULT rabbit_durable_queues true
  $OSC_ceilometer DEFAULT rabbit_ha_queues true
fi

$OSC_ceilometer DEFAULT auth_strategy keystone
$OSC_ceilometer keystone_authtoken identity_uri http://$KEYSTONE_MGMT_IP:35357/
$OSC_ceilometer keystone_authtoken auth_uri http://$KEYSTONE_API_IP:5000/
$OSC_ceilometer keystone_authtoken admin_tenant_name service
$OSC_ceilometer keystone_authtoken admin_user ceilometer
$OSC_ceilometer keystone_authtoken admin_password $USER_SERVICE_PASS

$OSC_ceilometer service_credentials os_auth_url http://$KEYSTONE_API_IP:5000/v2.0
$OSC_ceilometer service_credentials os_tenant_name service 
$OSC_ceilometer service_credentials os_username ceilometer
$OSC_ceilometer service_credentials os_password $USER_SERVICE_PASS
$OSC_ceilometer service_credentials os_endpoint_type internalURL

$OSC_ceilometer publisher metering_secret $METERING_SECRET

$OSC_ceilometer DEFAULT notification_driver ceilometer.openstack.common.notifier.rpc_notifier

if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_ceilometer api host $MGMT_IP
else
  $OSC_ceilometer api host 0.0.0.0
fi
