#!/bin/bash

[[ $# -ne 2 ]] && echo "Usage: $0 <source_ip> <dest_ip>" && exit

source_ip=$1
dest_ip=$2

source_inst_uuid=$(nova list --all-tenants --ip "^${source_ip}$" | grep $source_ip | awk '{print $2}') 
dest_inst_uuid=$(nova list --all-tenants --ip "^${dest_ip}$" | grep $dest_ip | awk '{print $2}') 

[[ $source_inst_uuid == "" ]] && echo "Error! Can't find instance ${source_ip}, exit" && exit
[[ $dest_inst_uuid == "" ]] && echo "Error! Can't find instance ${dest_ip}, exit" && exit
  
## Make sure DEST and SOURCE instances are shutoff.
source_inst_status=$(nova show ${source_inst_uuid} | grep status  | awk '{print $4}')
[[ ${source_inst_status} != "SHUTOFF" ]] && echo "${source_ip} is not SHUTOFF, exit." && exit

dest_inst_status=$(nova show ${dest_inst_uuid} | grep status  | awk '{print $4}')
[[ ${dest_inst_status} != "SHUTOFF" ]] && echo "${dest_ip} is not SHUTOFF, exit." && exit


source_inst_disk="vms/${source_inst_uuid}_disk"
dest_inst_disk="vms/${dest_inst_uuid}_disk"

rbd rm $dest_inst_disk
[[ $? -ne 0 ]] && echo "Error, exit." && exit

rbd mv $source_inst_disk $dest_inst_disk
[[ $? -eq 0 ]] && echo "Transfer finished."
