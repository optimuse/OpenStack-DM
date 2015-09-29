#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_g_reg="openstack-config --set /etc/glance/glance-registry.conf"
OSC_g_reg_del="openstack-config --del /etc/glance/glance-registry.conf"
$OSC_g_reg DEFAULT verbose True
$OSC_g_reg DEFAULT notification_driver messagingv2
$OSC_g_reg DEFAULT rpc_backend rabbit
$OSC_g_reg DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_g_reg DEFAULT rabbit_userid openstack
$OSC_g_reg DEFAULT rabbit_password $MQ_PASS
$OSC_g_reg DEFAULT rabbit_retry_interval 1
$OSC_g_reg DEFAULT rabbit_retry_backoff 2
$OSC_g_reg DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  $OSC_g_reg_del DEFAULT rabbit_hosts
  $OSC_g_reg_del DEFAULT rabbit_durable_queues
  $OSC_g_reg_del DEFAULT rabbit_ha_queues
else
  $OSC_g_reg DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_g_reg DEFAULT rabbit_durable_queues true
  $OSC_g_reg DEFAULT rabbit_ha_queues true
fi



$OSC_g_reg database connection mysql://$GLANCE_DB_USER:$GLANCE_DB_PASS@$MYSQL_MGMT_IP/glance
# $OSC_g_reg keystone_authtoken auth_host $KEYSTONE_MGMT_IP
# $OSC_g_reg keystone_authtoken auth_port 35357
# $OSC_g_reg keystone_authtoken auth_protocol http
$OSC_g_reg keystone_authtoken identity_uri http://$KEYSTONE_MGMT_IP:35357/
$OSC_g_reg keystone_authtoken auth_uri http://$KEYSTONE_API_IP:5000/
$OSC_g_reg keystone_authtoken admin_user glance
$OSC_g_reg keystone_authtoken admin_tenant_name service
$OSC_g_reg keystone_authtoken admin_password $USER_SERVICE_PASS
$OSC_g_reg paste_deploy flavor keystone

## Listen address
if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_g_reg DEFAULT bind_host $MGMT_IP
else
  $OSC_g_reg DEFAULT bind_host 0.0.0.0
fi


