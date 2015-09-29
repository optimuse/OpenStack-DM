#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_cinder="openstack-config --set /etc/cinder/cinder.conf"
OSC_cinder_del="openstack-config --del /etc/cinder/cinder.conf"
$OSC_cinder DEFAULT verbose True
$OSC_cinder DEFAULT notification_driver messagingv2
$OSC_cinder DEFAULT control_exchange cinder
$OSC_cinder DEFAULT lock_path /var/lib/cinder/tmp

$OSC_cinder DEFAULT rpc_backend rabbit
$OSC_cinder DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_cinder DEFAULT rabbit_userid openstack
$OSC_cinder DEFAULT rabbit_password $MQ_PASS
$OSC_cinder DEFAULT rabbit_retry_interval 1
$OSC_cinder DEFAULT rabbit_retry_backoff 2
$OSC_cinder DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  $OSC_cinder_del DEFAULT rabbit_hosts
  $OSC_cinder_del DEFAULT rabbit_durable_queues
  $OSC_cinder_del DEFAULT rabbit_ha_queues
else
  $OSC_cinder DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_cinder DEFAULT rabbit_durable_queues true
  $OSC_cinder DEFAULT rabbit_ha_queues true
fi




$OSC_cinder DEFAULT my_ip $CONT_MGMT_IP
#$OSC_cinder DEFAULT my_ip $CINDER_VOLUME_IP
$OSC_cinder DEFAULT glance_host $GLANCE_MGMT_IP
$OSC_cinder DEFAULT auth_strategy keystone
$OSC_cinder database connection mysql://$CINDER_DB_USER:$CINDER_DB_PASS@$MYSQL_MGMT_IP/cinder
$OSC_cinder keystone_authtoken identity_uri http://$KEYSTONE_MGMT_IP:35357/
$OSC_cinder keystone_authtoken auth_uri http://$KEYSTONE_API_IP:5000/
$OSC_cinder keystone_authtoken admin_user cinder
$OSC_cinder keystone_authtoken admin_tenant_name service
$OSC_cinder keystone_authtoken admin_password $USER_SERVICE_PASS

$OSC_cinder DEFAULT volume_driver cinder.volume.drivers.lvm.LVMISCSIDriver
$OSC_cinder DEFAULT volume_grouop cinder-volumes
$OSC_cinder DEFAULT iscsi_protocol iscsi
$OSC_cinder DEFAULT iscsi_helper lioadm
$OSC_cinder DEFAULT iscsi_ip_address $CINDER_VOLUME_IP

## see: http://www.gossamer-threads.com/lists/openstack/dev/33436
$OSC_cinder DEFAULT host $CINDER_VOLUME_HOST

## Listen address
if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_cinder DEFAULT osapi_volume_listen $MGMT_IP
else
  $OSC_cinder DEFAULT osapi_volume_listen 0.0.0.0
fi
