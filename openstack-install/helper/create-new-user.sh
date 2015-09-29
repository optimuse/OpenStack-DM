#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh
source $RC_BASE/keystone-rc.admin

if [ $# -ne 3 ]; then
  echo "Usage: $0 <tenant_name> <user_name> <user_pass>"
  exit 1
fi

tenant_name=$1
user_name=$2
user_pass=$3

function get_id () {
echo `"$@" | awk '/ id / { print $4 }'`
}

ROLE_DEFAULT="Member"
role_default_id=$(get_id keystone role-get $ROLE_DEFAULT)
if [[ $role_default_id == "" ]]; then
  echo "[XXX]Default Role $ROLE_DEFAULT not found. Please do a check."
  exit 1
fi

tenant_id=$(get_id keystone tenant-get "$tenant_name" 2>/dev/null)
if [[ $tenant_id == "" ]]; then
  echo "[XXX]Tenant $tenant_name NOT exist, please create the tenant first."
  exit 1
fi

user_id=$(get_id keystone user-get "$user_name" 2>/dev/null)
if [[ $user_id != "" ]]; then
  echo "[XXX]User $user_name already exist, with user id $user_id."
  exit 1
fi

## Create User.
user_id=$(get_id keystone user-create --name "$user_name" --pass "$user_pass")
[[ $user_id != "" ]] && echo "[:-)] User created."

keystone user-role-add --user $user_id --tenant_id $tenant_id --role $role_default_id

cat <<EOF 
[:--)] Successflly created User $user_name.
User ID: $user_id
User Name: $user_name
Tenant Name: $tenant_name
Role: $ROLE_DEFAULT
EOF
