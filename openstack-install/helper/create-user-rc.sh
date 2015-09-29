#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

if ! [ $# -ne 3 -o $# -ne 0 ] ; then
  echo "Usage 1: $0"
  echo "Usage 2: $0 <tenant_name> <user_name> <user_pass>"
  exit 1
fi


# Create keystone init rc file.

## When keystone is just installed, there's no any user/password information in it.
## So you must use a temporary authentication token to initialize keystone. ('initialize' means
## create user/role/project/service/endpoint.)
## When keystone initialization is completed, do NOT use the temporary token any longer.

if [ $# -eq 0 ]; then

cat <<EOF > $RC_BASE/keystone-rc.init
export OS_SERVICE_ENDPOINT="http://$KEYSTONE_MGMT_IP:35357/v2.0"
export OS_SERVICE_TOKEN=$ADMIN_TOKEN
# export SERVICE_ENDPOINT="http://$KEYSTONE_MGMT_IP:35357/v2.0"
# export SERVICE_TOKEN=$ADMIN_TOKEN

function desourcerc () {
  unset OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_AUTH_URL OS_REGION_NAME
  unset OS_SERVICE_ENDPOINT OS_SERVICE_TOKEN
  export PS1='[\u@\h \W]\$ '
}
EOF
fi
  

## Create keystone user rc file.
if [ $# -eq 3 ]; then

tenant_name=$1
user_name=$2
user_pass=$3

cat <<EOF > $RC_BASE/keystone-rc.${user_name}
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT

export OS_TENANT_NAME=${tenant_name}
export OS_USERNAME=${user_name}
export OS_PASSWORD=${user_pass}
# Port 35357 is used for administrative functions only.
export OS_AUTH_URL="http://$KEYSTONE_API_IP:35357/v2.0/"
export OS_REGION_NAME=RegionOne
export PS1='[\u@\h \W(keystone_${tenant_name})]\$ '

function desourcerc() {
  unset OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_AUTH_URL OS_REGION_NAME
  unset OS_SERVICE_ENDPOINT OS_SERVICE_TOKEN
  export PS1='[\u@\h \W]\$ '
}
EOF
fi

