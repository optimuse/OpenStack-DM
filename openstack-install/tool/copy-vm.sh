#!/bin/bash

[[ $# -ne 2 ]] && echo "Usage: $0 <source_ip> <dest_ip>" && exit

source_ip=$1
dest_ip=$2

source_inst_uuid=$(nova list --all-tenants --ip "^${source_ip}$" | grep $source_ip | awk '{print $2}') 
dest_inst_uuid=$(nova list --all-tenants --ip "^${dest_ip}$" | grep $dest_ip | awk '{print $2}') 

[[ $source_inst_uuid == "" ]] && echo "Error! Can't find instance ${source_ip}, exit" && exit
[[ $dest_inst_uuid == "" ]] && echo "Error! Can't find instance ${dest_ip}, exit" && exit
  
## Make sure DEST instance are shutoff.
## SOURCE instance NOT NEED to be shutoff.
dest_inst_status=$(nova show ${dest_inst_uuid} | grep status  | awk '{print $4}')
[[ ${dest_inst_status} != "SHUTOFF" ]] && echo "${dest_ip} is not SHUTOFF, exit." && exit

source_inst_disk="vms/${source_inst_uuid}_disk"
dest_inst_disk="vms/${dest_inst_uuid}_disk"

time_str=$(date +"%F-%s")
snapshot_name="${source_inst_disk}@snap-${time_str}"

echo "Make snapshot ..."
rbd snap create $snapshot_name
rbd snap protect $snapshot_name

echo "Copying ..."
rbd rm ${dest_inst_disk}
rbd clone ${snapshot_name} ${dest_inst_disk}

[[ $? -eq 0 ]] && echo "Copying finished."
