#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

[[ $# -ne 2 ]] && echo "Usage: $0 <src_image_id> <dst_image_id>" && exit

src_image_id=$1
dst_image_id=$2

update_instance_imageid="update nova.instances set image_ref = '${dst_image_id}' where image_ref = '${src_image_id}'"

exec_sql() {
  SQLstr="$1"
  mysql -u"${NOVA_DB_USER}" -p"${NOVA_DB_PASS}" -Dnova -ss -e "$SQLstr"
}


exec_sql "$update_instance_imageid"
