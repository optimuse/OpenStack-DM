#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

function usage() {
  cat <<EOF

Usage: $0 -h [options]
Options:
  -h | --help  
		Print usage information.
  -t | --tenant_name  <tenant_name|none>
		Tenant name. If you don't want this network belong to a specific tenant, provide 'none' here.
  -l | --network_label  <network_label>
		Network label.
  -r | --network_range  <network_range>
		Network range.
  -s | --network_size  <network_size>
		Network size.
  -v | --vlan_id  <vlan_id>
		Vlan ID.
  -g | --gateway  <gateway>
		OpenStack will create dhcp server on nova-network by this ip and this ip will be VM's default gateway.
  -g2 | --gateway2  <gateway2>
		If you use an hardware router for VMs, specify the gateway address here.
  -d | --dns <dns>
		DNS addresses. More than one address should be enclosed in double quote and delimited by comma.
		Like 8.8.8.8 or "8.8.8.8,114.114.114.114"
EOF
  exit $1
}

if [ $# -eq 0 ]; then
  usage 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -t|--tenant_name) tenant_name=$2; shift ;;
    -l|--network_label) network_label=$2; shift ;;
    -r|--network_range) network_range=$2; shift ;;
    -s|--network_size) network_size=$2; shift ;;
    -v|--vlan_id) vlan_id=$2; shift ;;
    -g|--gateway) gateway=$2; shift ;;
    -g2|--gateway2) gateway2=$2; shift ;;
    -d|--dns) dns=$2; shift ;;
    *) echo "Wrong option: $1"; usage 1 ;;
  esac
  shift
done

source $RC_BASE/keystone-rc.admin

function get_id () {
  echo `"$@" | awk '/ id / { print $4 }'`
}

if [[ -n $tenant_name ]]; then
  tenant_id=$(get_id keystone tenant-get $tenant_name)
fi

nova-manage network list | awk '{print $2}' | grep -sq "$network_range"
if [[ $? -eq 0 ]]; then
  echo "$network_range already exists."
  exit 1
fi
  
[[ $USE_MULTIHOST -eq 0 ]] && MULTIHOST_FLAG="F" || MULTIHOST_FLAG="T"

if [[ $tenant_name != "none" ]]; then
## Create fixed network for tenant
  nova-manage network create --label $network_label --project_id $tenant_id \
--fixed_range_v4 $network_range --num_networks 1 --network_size $network_size --vlan $vlan_id \
--gateway $gateway --bridge br$vlan_id \
--multi_host $MULTIHOST_FLAG
else
  nova-manage network create --label $network_label \
--fixed_range_v4 $network_range --num_networks 1 --network_size $network_size --vlan $vlan_id \
--gateway $gateway --bridge br$vlan_id \
--multi_host $MULTIHOST_FLAG
fi

## If we use hardware route for VM's gateway.
if [[ $gateway2 != "" ]]; then
  nova-manage fixed reserve --address $gateway2
  # nova-manage fixed unreserve --address $gateway
  cat <<EOF >> /etc/nova/dnsmasq.nova.conf

dhcp-option=tag:${network_label},option:router,$gateway2
dhcp-option=tag:${network_label},121,169.254.169.254/32,$gateway,0.0.0.0/0,$gateway2
EOF
fi
# The 'DHCP Client Behavior' section of RFC3442 says, in part:
# "If the DHCP server returns both a Classless Static Routes option and a Router option, the DHCP client MUST ignore the Router option."
# Just add the default route to your classless routes, make sure default route be configured correctly.

if [[ $dns != "" ]]; then
  cat <<EOF >> /etc/nova/dnsmasq.nova.conf
dhcp-option=tag:${network_label},option:dns-server,$dns
EOF
fi

source $RC_BASE/keystone-rc.${tenant_name}
default_secgroup_id_for_the_tenant=$(nova secgroup-list | grep default | awk '{print $2}')

nova secgroup-add-rule $default_secgroup_id_for_the_tenant icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule $default_secgroup_id_for_the_tenant tcp 22 22 0.0.0.0/0
nova secgroup-add-rule $default_secgroup_id_for_the_tenant tcp 10050 10050 0.0.0.0/0

while read n_ip n_hostname; do
  echo $n_hostname
  rsync /etc/nova/dnsmasq.nova.conf $n_ip:/etc/nova/dnsmasq.nova.conf
done < $MAP_BASE/all-node.list
