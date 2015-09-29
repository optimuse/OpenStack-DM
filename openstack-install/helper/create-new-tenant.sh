#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

if [ $# -ne 4 ]; then
  echo "Usage: $0 <tenant_name> <user_name> <user_pass> <tenant_desc>"
  echo "At moment, <user_name> has no meaning. <tenant_name> will be used as the value of <user_name>."
  echo "This might be changed at future."
  exit 1
fi

tenant_name=$1
user_name=$tenant_name
user_pass=$3
tenant_desc=$4

function get_id () {
  echo `"$@" | awk '/ id / { print $4 }'`
}

ROLE_DEFAULT="Member"
role_default_id=$(get_id keystone role-get $ROLE_DEFAULT 2>/dev/null)
if [[ $role_default_id == "" ]]; then
  echo "[XXX]Default Role $ROLE_DEFAULT not found. Please do a check."
  exit 1
fi

tenant_id=$(get_id keystone tenant-get "$tenant_name" 2>/dev/null)
if [[ $tenant_id != "" ]]; then
  echo "[XXX]Tenant $tenant_name already exist, with tenant id $tenant_id"
  exit 1 
fi

user_id=$(get_id keystone user-get "$user_name")
if [[ $user_id != "" ]]; then
  echo "[XXX]User $user_name already exist, with user id $user_id"
  exit 1
fi

## Create tenant and user.
tenant_id=$(get_id keystone tenant-create --name "$tenant_name" --description "$tenant_desc")
[[ $tenant_id != "" ]] && echo "[:-)] Tenant created."

user_id=$(get_id keystone user-create --name "$user_name" --pass "$user_pass")
[[ $user_id != "" ]] && echo "[:-)] User created."

keystone user-role-add --user $user_id --tenant_id $tenant_id --role $role_default_id

bash $HELPER_BASE/create-user-rc.sh $tenant_name $user_name $user_pass

cat <<EOF 
[:-)] Successfully created tenant $tenant_name.
Tenant ID: $tenant_id
Tenant Name: $tenant_name
Tenant Desc: $tenant_desc
User Name: $user_name
User RC file: $RC_BASE/keystone-rc.$user_name
EOF
