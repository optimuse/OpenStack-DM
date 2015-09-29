#!/bin/bash

read -p "Are you sure to continue?[yes/no]: " answer
[[ "$answer" == "yes" ]] || exit

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.init

function get_id () {
  echo `"$@" | awk '/ id / { print $4 }'`
}

service_keystone_id=$(get_id keystone service-get keystone)
keystone endpoint-create --region RegionOne --service_id $service_keystone_id \
--publicurl http://$KEYSTONE_API_IP:5000/v2.0 \
--adminurl http://$KEYSTONE_MGMT_IP:35357/v2.0 \
--internalurl http://$KEYSTONE_MGMT_IP:5000/v2.0


service_glance_id=$(get_id keystone service-get glance)
keystone endpoint-create --region RegionOne --service_id $service_glance_id \
--publicurl http://$GLANCE_API_IP:9292 \
--adminurl http://$GLANCE_MGMT_IP:9292 \
--internalurl http://$GLANCE_MGMT_IP:9292


service_cinder_id=$(get_id keystone service-get cinder)
keystone endpoint-create --region RegionOne --service_id $service_cinder_id \
--publicurl http://$CINDER_API_IP:8776/v1/%\(tenant_id\)s \
--adminurl http://$CINDER_MGMT_IP:8776/v1/%\(tenant_id\)s \
--internalurl http://$CINDER_MGMT_IP:8776/v1/%\(tenant_id\)s
# Also register a service and endpoint for version 2 of the Block Storage Service API
service_cinderv2_id=$(get_id keystone service-get cinderv2)
keystone endpoint-create --region RegionOne --service-id $service_cinderv2_id \
--publicurl=http://$CINDER_API_IP:8776/v2/%\(tenant_id\)s \
--internalurl=http://$CINDER_MGMT_IP:8776/v2/%\(tenant_id\)s \
--adminurl=http://$CINDER_MGMT_IP:8776/v2/%\(tenant_id\)s


service_nova_id=$(get_id keystone service-get nova)
keystone endpoint-create --region RegionOne --service_id $service_nova_id \
--publicurl http://$NOVA_API_IP:8774/v2/%\(tenant_id\)s \
--adminurl http://$NOVA_MGMT_IP:8774/v2/%\(tenant_id\)s \
--internalurl http://$NOVA_MGMT_IP:8774/v2/%\(tenant_id\)s


service_ceilometer_id=$(get_id keystone service-get ceilometer)
keystone endpoint-create --region RegionOne --service_id $service_ceilometer_id \
--publicurl http://$CEILOMETER_API_IP:8777/ \
--adminurl http://$CEILOMETER_MGMT_IP:8777/ \
--internalurl http://$CEILOMETER_MGMT_IP:8777/


service_heat_id=$(get_id keystone service-get heat)
service_heat_cfn_id=$(get_id keystone service-get heat-cfn)

keystone endpoint-create --region RegionOne --service_id $service_heat_id \
--publicurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s \
--adminurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s \
--internalurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s

keystone endpoint-create --region RegionOne --service_id $service_heat_cfn_id \
--publicurl http://$HEAT_API_IP:8000/v1/ \
--adminurl http://$HEAT_API_IP:8000/v1/ \
--internalurl http://$HEAT_API_IP:8000/v1/

