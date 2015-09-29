#!/bin/bash

usage() {
  echo "Usage: $0  {initial|extra}"
  echo "'initial' means this is the first controller."
  echo "'extra' means this is NOT the first controller."
  exit 1
}

[[ $# -ne 1 ]] && usage
[[ $1 == "initial" ]] || [[ $1 == "extra" ]] || usage

FLAG=$1

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh


## **********************************************************


##
## MongoDB for Ceilometer.

if [ -f /etc/mongod.conf ]; then
  yum remove -y mongodb-server mongodb
  rm -rf /etc/mongod.conf
  rm -rf /var/lib/mongodb/
fi

yum install -y mongodb-server mongodb

if [[ $FLAG == "initial" ]]; then
  openssl rand -base64 741 > $ENV_BASE/mongodb-keyfile
fi

rsync -az $ENV_BASE/mongodb-keyfile /var/lib/mongodb/mongodb-keyfile
chmod 600 /var/lib/mongodb/mongodb-keyfile
chown mongodb.mongodb /var/lib/mongodb/mongodb-keyfile
restorecon -R /var/lib/mongodb/

crud_mongod="crudini --set /etc/mongod.conf"

## Generic configuration.
$crud_mongod '' bind_ip 0.0.0.0
$crud_mongod '' port 27017
$crud_mongod '' dbpath /var/lib/mongodb
$crud_mongod '' rest true
$crud_mongod '' smallfiles true
## Don't enable auth before mongo admin is created.
$crud_mongod '' auth false
$crud_mongod '' replSet rs0

systemctl enable mongod
systemctl start mongod
systemctl restart mongod

## Initial
if [[ $FLAG == "initial" ]]; then
  bash -x $HELPER_BASE/init-mongodb.sh
fi

## Enable auth 
$crud_mongod '' keyFile /var/lib/mongodb/mongodb-keyfile
$crud_mongod '' auth true
systemctl restart mongod

mongo --host $MONGO_MGMT_IP <<EOF
use admin
db.auth("$MONGO_ADMIN_USER", "$MONGO_ADMIN_PASS")
rs.add("$NODE_HOSTNAME:27017") 
rs.add("$NODE_HOSTNAME:27017") 
rs.status()
exit
EOF
