#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.init

function get_id () {
echo `"$@" | awk '/ id / { print $4 }'`
}

tenant_service_id=$(get_id keystone tenant-create --name service --description "Service Tenant")

service_keystone_id=$(get_id keystone service-create --name keystone --type identity --description "Openstack Identity Servcie")
keystone endpoint-create --region RegionOne --service_id $service_keystone_id \
--publicurl http://$KEYSTONE_API_IP:5000/v2.0 \
--adminurl http://$KEYSTONE_MGMT_IP:35357/v2.0 \
--internalurl http://$KEYSTONE_MGMT_IP:5000/v2.0


user_glance_id=$(get_id keystone user-create --name glance --pass $USER_SERVICE_PASS)
keystone user-role-add --user $user_glance_id --role $role_admin_id --tenant_id $tenant_service_id
service_glance_id=$(get_id keystone service-create --name glance --type image --description "Openstack Image Service")
keystone endpoint-create --region RegionOne --service_id $service_glance_id \
--publicurl http://$GLANCE_API_IP:9292 \
--adminurl http://$GLANCE_MGMT_IP:9292 \
--internalurl http://$GLANCE_MGMT_IP:9292


user_cinder_id=$(get_id keystone user-create --name cinder --pass $USER_SERVICE_PASS)
keystone user-role-add --user $user_cinder_id --role $role_admin_id --tenant_id $tenant_service_id
service_cinder_id=$(get_id keystone service-create --name cinder --type volume --description "OpenStack Block Storage Service")
keystone endpoint-create --region RegionOne --service_id $service_cinder_id \
--publicurl http://$CINDER_API_IP:8776/v1/%\(tenant_id\)s \
--adminurl http://$CINDER_MGMT_IP:8776/v1/%\(tenant_id\)s \
--internalurl http://$CINDER_MGMT_IP:8776/v1/%\(tenant_id\)s
# Also register a service and endpoint for version 2 of the Block Storage Service API
service_cinderv2_id=$(get_id keystone service-create --name cinderv2 --type volumev2 --description "OpenStack Block Storage Service V2")
keystone endpoint-create --region RegionOne --service-id $service_cinderv2_id \
--publicurl=http://$CINDER_API_IP:8776/v2/%\(tenant_id\)s \
--internalurl=http://$CINDER_MGMT_IP:8776/v2/%\(tenant_id\)s \
--adminurl=http://$CINDER_MGMT_IP:8776/v2/%\(tenant_id\)s


user_nova_id=$(get_id keystone user-create --name nova --pass $USER_SERVICE_PASS)
keystone user-role-add --user $user_nova_id --role $role_admin_id --tenant_id $tenant_service_id
service_nova_id=$(get_id keystone service-create --name nova --type compute --description "Openstack Compute Service")
keystone endpoint-create --region RegionOne --service_id $service_nova_id \
--publicurl http://$NOVA_API_IP:8774/v2/%\(tenant_id\)s \
--adminurl http://$NOVA_MGMT_IP:8774/v2/%\(tenant_id\)s \
--internalurl http://$NOVA_MGMT_IP:8774/v2/%\(tenant_id\)s


user_ceilometer_id=$(get_id keystone user-create --name ceilometer --pass $USER_SERVICE_PASS)
keystone user-role-add --user $user_ceilometer_id --role $role_admin_id --tenant_id $tenant_service_id
service_ceilometer_id=$(get_id keystone service-create --name ceilometer --type metering --description "OpenStack Telemetry Service")
keystone endpoint-create --region RegionOne --service_id $service_ceilometer_id \
--publicurl http://$CEILOMETER_API_IP:8777/ \
--adminurl http://$CEILOMETER_MGMT_IP:8777/ \
--internalurl http://$CEILOMETER_MGMT_IP:8777/


user_heat_id=$(get_id keystone user-create --name heat --pass $USER_SERVICE_PASS)
keystone user-role-add --user $user_heat_id --role $role_admin_id --tenant_id $tenant_service_id

keystone role-create --name heat_stack_owner
keystone user-role-add --user $user_admin_id --tenant $tenant_admin_id --role heat_stack_owner
# You must add the heat_stack_owner role to users that manage stacks.

keystone role-create --name heat_stack_user

# The Orchestration service automatically assigns the heat_stack_user role 
# to users that it creates during stack deployment. 
# By default, this role restricts API operations. 
# To avoid conflicts, do not add this role to users with the heat_stack_owner role.

service_heat_id=$(get_id keystone service-create --name heat --type orchestration --description "Orchestration")
service_heat_cfn_id=$(get_id keystone service-create --name heat-cfn --type cloudformation --description "Orchestration")

keystone endpoint-create --region RegionOne --service_id $service_heat_id \
--publicurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s \
--adminurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s \
--internalurl http://$HEAT_API_IP:8004/v1/%\(tenant_id\)s

keystone endpoint-create --region RegionOne --service_id $service_heat_cfn_id \
--publicurl http://$HEAT_API_IP:8000/v1/ \
--adminurl http://$HEAT_API_IP:8000/v1/ \
--internalurl http://$HEAT_API_IP:8000/v1/

