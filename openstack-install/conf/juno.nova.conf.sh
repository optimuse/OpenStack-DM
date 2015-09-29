#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_nova="openstack-config --set /etc/nova/nova.conf"
OSC_nova_del="openstack-config --del /etc/nova/nova.conf"

$OSC_nova DEFAULT verbose true
$OSC_nova DEFAULT my_ip $MGMT_IP
$OSC_nova DEFAULT lock_path /var/lib/nova/tmp

# Database
$OSC_nova database connection mysql://$NOVA_DB_USER:$NOVA_DB_PASS@$MYSQL_MGMT_IP/nova

# Message Queue
$OSC_nova DEFAULT rpc_backend rabbit
$OSC_nova DEFAULT rabbit_host $MQ_MGMT_IP
$OSC_nova DEFAULT rabbit_userid openstack
$OSC_nova DEFAULT rabbit_password $MQ_PASS
$OSC_nova DEFAULT rabbit_retry_interval 1
$OSC_nova DEFAULT rabbit_retry_backoff 2
$OSC_nova DEFAULT rabbit_max_retries 0
if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  $OSC_nova_del DEFAULT rabbit_hosts
  $OSC_nova_del DEFAULT rabbit_durable_queues
  $OSC_nova_del DEFAULT rabbit_ha_queues
else
  $OSC_nova DEFAULT rabbit_hosts $RABBIT_HOSTS
  $OSC_nova DEFAULT rabbit_durable_queues true
  $OSC_nova DEFAULT rabbit_ha_queues true
fi



# Authentication
$OSC_nova DEFAULT auth_strategy keystone
$OSC_nova keystone_authtoken identity_uri http://$KEYSTONE_MGMT_IP:35357/
$OSC_nova keystone_authtoken auth_uri http://$KEYSTONE_API_IP:5000/
$OSC_nova keystone_authtoken admin_tenant_name service
$OSC_nova keystone_authtoken admin_user nova
$OSC_nova keystone_authtoken admin_password $USER_SERVICE_PASS
# $OSC_nova  keystone_authtoken auth_host $KEYSTONE_MGMT_IP
# $OSC_nova  keystone_authtoken auth_port 35357
# $OSC_nova  keystone_authtoken auth_protocol http
# $OSC_nova  keystone_authtoken signing_dir /tmp/keystone-signing-nova

# nova-scheduler
$OSC_nova DEFAULT scheduler_default_filters RetryFilter,AggregateInstanceExtraSpecsFilter,AggregateMultiTenancyIsolation,AggregateImagePropertiesIsolation,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter

# VNC
$OSC_nova DEFAULT vnc_enabled true
$OSC_nova DEFAULT novncproxy_base_url http://$CONT_VNC_IP:6080/vnc_auto.html 
$OSC_nova DEFAULT vncserver_proxyclient_address $MGMT_IP 
# vncserver_proxyclient_address must points to compute node's self MANAGEMNET IP.
$OSC_nova DEFAULT vncserver_listen 0.0.0.0
# Spice
# $OSC_nova DEFAULT vnc_enabled false
# $OSC_nova Spice enabled true
# $OSC_nova Spice agent_enabled true
# $OSC_nova Spice html5proxy_base http://$CONT_API_IP:6082/spice_auto.html
# $OSC_nova Spice server_proxyclient_address $MGMT_IP
# $OSC_nova Spice server_listen 0.0.0.0

# Cinder
$OSC_nova cinder catalog_info volumev2:cinder:internalURL

# Glance
$OSC_nova glance api_servers $GLANCE_MGMT_IP:9292


# Notification
$OSC_nova DEFAULT instance_usage_audit true
$OSC_nova DEFAULT instance_usage_audit_period hour
$OSC_nova DEFAULT notify_on_state_change vm_and_task_state
$OSC_nova DEFAULT notification_driver messagingv2

## nova-network
$OSC_nova DEFAULT network_api_class nova.network.api.API
$OSC_nova DEFAULT security_group_api nova
$OSC_nova DEFAULT firewall_driver nova.virt.libvirt.firewall.IptablesFirewallDriver

# influence vm's dhcp /etc/resolv.conf search option.
$OSC_nova DEFAULT dhcp_domain $DHCP_DOMAIN
# $OSC_nova DEFAULT use_network_dns_servers false

$OSC_nova DEFAULT public_interface $FLOAT_IF
$OSC_nova DEFAULT routing_source_ip $EXT_IP

# $OSC_nova DEFAULT network_manager nova.network.manager.FlatDHCPManager
# $OSC_nova DEFAULT flat_interface $FLAT_IF
# $OSC_nova DEFAULT flat_network_bridge br100
$OSC_nova DEFAULT network_manager nova.network.manager.VlanManager
$OSC_nova DEFAULT vlan_interface $FLAT_IF
$OSC_nova DEFAULT vlan_start 100

$OSC_nova DEFAULT flat_injected false
$OSC_nova DEFAULT force_dhcp_release true
$OSC_nova DEFAULT dhcpbridge /usr/bin/nova-dhcpbridge
$OSC_nova DEFAULT dnsmasq_config_file /etc/nova/dnsmasq.nova.conf
touch /etc/nova/dnsmasq.nova.conf

# Metadata
$OSC_nova DEFAULT enabled_apis ec2,osapi_compute,metadata
$OSC_nova DEFAULT metadata_host $CONT_MGMT_IP

# Network Mode
$OSC_nova DEFAULT multi_host false
$OSC_nova DEFAULT send_arp_for_ha true

if [[ $USE_MULTIHOST -eq 1 ]]; then
  $OSC_nova DEFAULT metadata_host $MGMT_IP
  $OSC_nova DEFAULT multi_host true
  $OSC_nova DEFAULT share_dhcp_address true
else
  $OSC_nova DEFAULT metadata_host $CONT_MGMT_IP
  $OSC_nova DEFAULT multi_host false
fi

# Libivrt
$OSC_nova libvirt virt_type kvm

# Others
$OSC_nova DEFAULT multi_instance_display_name_template  "%(name)s-%(count)s"

$OSC_nova DEFAULT resize_confirm_window 0
$OSC_nova conductor use_local true

## neutron
# $OSC_nova DEFAULT network_api_class nova.network.neutronv2.api.API
# $OSC_nova DEFAULT security_group_api neutron
# $OSC_nova neutron ...

## Listen address.
if [[ $CONT_HAPROXY -eq 1 ]]; then
  $OSC_nova DEFAULT ec2_listen $MGMT_IP
  $OSC_nova DEFAULT osapi_compute_listen $MGMT_IP
  $OSC_nova DEFAULT metadata_listen $MGMT_IP
  $OSC_nova DEFAULT novncproxy_host $MGMT_IP
  $OSC_nova DEFAULT s3_listen $MGMT_IP
else
  $OSC_nova DEFAULT ec2_listen 0.0.0.0
  $OSC_nova DEFAULT osapi_compute_listen 0.0.0.0
  $OSC_nova DEFAULT metadata_listen 0.0.0.0
  $OSC_nova DEFAULT novncproxy_host 0.0.0.0
  $OSC_nova DEFAULT s3_listen 0.0.0.0
fi
