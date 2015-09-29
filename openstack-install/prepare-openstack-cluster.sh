#!/bin/bash


BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

##################################


mk_dir() {
  [ ! -d "$1" ] && mkdir -p "$1"
}

mk_dir $ENV_BASE
mk_dir $RC_BASE
mk_dir $REPO_BASE
mk_dir $CONF_BASE
mk_dir $MAP_BASE
mk_dir $HELPER_BASE
mk_dir $RELAY_BASE

## Store tokens used by openstack components.
ENV_TOKEN="$ENV_BASE/openstack-install.token"

## Create tokens.
if [ -f $ENV_TOKEN ]; then
  echo "!!! Wrong: $ENV_TOKEN file already exists, may be you already have a openstack cluster, exit"
  echo "If you want to re-create openstack cluster, just delete $ENV_TOKEN and re-execute this script."
  exit
fi

ADMIN_TOKEN=$(openssl rand -hex 10)
USER_SERVICE_PASS=$(openssl rand -hex 10)
METERING_SECRET=$(openssl rand -hex 10)

cat <<EOF > $ENV_TOKEN
export ADMIN_TOKEN=$ADMIN_TOKEN
export USER_SERVICE_PASS=$USER_SERVICE_PASS
export METERING_SECRET=$METERING_SECRET
EOF


## Create keystone init rc file. [NOT provide arguements.]
bash $HELPER_BASE/create-user-rc.sh

## Create keystone user rc file.
# create-user-rc.sh <tenant_name> <user_name> <user_pass>
bash $HELPER_BASE/create-user-rc.sh admin admin $USER_ADMIN_PASS
bash $HELPER_BASE/create-user-rc.sh demo demo $USER_DEMO_PASS

## Generate public key for password-less login.
[[ ! -f ~/.ssh/id_rsa ]] && ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""

## Create nova user's ssh password login.
[ -d $ENV_BASE/nova-ssh ] && mkdir -p $ENV_BASE/nova-ssh/
ssh-keygen -q -t rsa -f $ENV_BASE/nova-ssh/id_rsa -C "nova@compute" -N ""
cp -f $ENV_BASE/nova-ssh/id_rsa.pub $ENV_BASE/nova-ssh/authorized_keys
