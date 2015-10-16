#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

[[ $# -lt 2 ]] && echo "Usage: $0 <vip> <instance_ip1> <instance_ip1> ... <instance_ipN>" && exit

vip=$1
INSTANCES="${@##$1}"


for inst_ip in ${INSTANCES}; do
  ## Instance uuid.
  inst_uuid=$(nova list --all-tenants --ip "${inst_ip}$" | grep $inst_ip | awk '{print $2}') 
  [[ $inst_uuid == "" ]] && echo "Error! Can't find instance ${inst_ip}, exit" && exit
  if ! grep -sq "$vip $inst_uuid" $MAP_BASE/vip-map.list; then
    echo "$vip $inst_uuid" >> $MAP_BASE/vip-map.list
  fi

  ## Instance name.
  inst_name=$(nova list --all-tenants --ip "${inst_ip}$" --field instance_name | grep $inst_uuid | awk '{print $4}')
  ## Host where instance reside.
  inst_host=$(nova list --all-tenants --ip "${inst_ip}$" --field host | grep $inst_uuid | awk '{print $4}')

  virtual_interface_id_sqlstr="select virtual_interface_id from fixed_ips where address = '"${inst_ip}"' and instance_uuid = '"${inst_uuid}"'"
  virtual_interface_id=$(mysql -u"${NOVA_DB_USER}" -p"${NOVA_DB_PASS}" -Dnova -ss -e "$virtual_interface_sqlstr")

  interface_mac_sqlstr="select address from virtual_interfaces where id = '"${virtual_interface_id}"' and instance_uuid = '"${inst_uuid}"'"
  interface_mac=$(mysql -u"${NOVA_DB_USER}" -p"${NOVA_DB_PASS}" -Dnova -ss -e "$interface_mac_sqlstr")
  interface_mac=$(echo $interface_mac | tr -d [:])

  inst_nwfilter_file="/etc/libvirt/nwfilter/nova-instance-${inst_name}-${interface_mac}.xml"
  parameter_ip_str="<parameter name='IP' value='"$vip"'/>"

  ssh $inst_host "
  if ! grep -sq $parameter_ip_str ${inst_nwfilter_file}; then
    sed -i "/<filterref filter='nova-base'>/a\$paramter_ip_str" $inst_nwfilter_file
  fi"
done



  
    
