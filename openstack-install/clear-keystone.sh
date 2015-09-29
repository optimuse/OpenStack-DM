#!/bin/bash

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.init


function create_get_id () {
echo `"$@" | awk '/ id / { print $4 }'`
}

function list_get_id () {
echo `"$@" | awk '/ id / { print $2}'`
}

function remove_keystone_type() {
  type=$1
  ids=$(eval keystone ${type}-list | head -n-1 | tail -n+4 | awk '{print $2}' | xargs)
  for id in $ids; do eval keystone ${type}-delete $id; done

  # user_ids=$(keystone user-list | head -n-1 | tail -n+4 | awk '{print $2}' | xargs)
  # for id in $user_ids; do keystone user-delete $id; done
}


## Remove keystone tenants, users, roles, services, endpoints.
remove_keystone_type tenant
remove_keystone_type user
remove_keystone_type role
remove_keystone_type service
remove_keystone_type endpoint

