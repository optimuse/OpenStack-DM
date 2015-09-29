#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

## Configure Keystone
OSC_key="openstack-config --set /etc/keystone/keystone.conf"
OSC_key_del="openstack-config --del /etc/keystone/keystone.conf"
$OSC_key DEFAULT verbose True
$OSC_key DEFAULT admin_token $ADMIN_TOKEN
$OSC_key database connection mysql://$KEYSTONE_DB_USER:$KEYSTONE_DB_PASS@$MYSQL_MGMT_IP/keystone
$OSC_key memcache servers $MEMCACHE_MGMT_IP:11211
$OSC_key token provider keystone.token.providers.uuid.Provider
#$OSC_key token driver keystone.token.persistence.backends.memcache.Token
$OSC_key token driver keystone.token.persistence.backends.sql.Token
$OSC_key revoke driver keystone.contrib.revoke.backends.sql.Revoke

$OSC_key DEFAULT rpc_backend rabbit
$OSC_key DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_key DEFAULT rabbit_userid openstack
$OSC_key DEFAULT rabbit_password $MQ_PASS
$OSC_key DEFAULT rabbit_retry_interval 1
$OSC_key DEFAULT rabbit_retry_backoff 2
$OSC_key DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  $OSC_key_del DEFAULT rabbit_hosts
  $OSC_key_del DEFAULT rabbit_durable_queues
  $OSC_key_del DEFAULT rabbit_ha_queues
else
  $OSC_key DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_key DEFAULT rabbit_durable_queues true
  $OSC_key DEFAULT rabbit_ha_queues true
fi



## keystone default token expiration time is too short.
## see: https://bugs.launchpad.net/nova/+bug/1407592
$OSC_key cache expiration_time 86400
$OSC_key token expiration 36000
$OSC_key token revocation_cache_time 36000

## Listen address.
if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_key DEFAULT public_bind_host $EXT_IP
  $OSC_key DEFAULT admin_bind_host $MGMT_IP
else
  $OSC_key DEFAULT public_bind_host 0.0.0.0
  $OSC_key DEFAULT admin_bind_host 0.0.0.0
fi
