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


yum install -y http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm
#yum localinstall -y $REPO_BASE/rdo-release-juno.rpm

##
## Install message queue server.
yum install -y rabbitmq-server

if [[ $CONT_HAPROXY -eq 1 ]]; then
cat <<EOF > /etc/rabbitmq/rabbitmq-env.conf
export RABBITMQ_NODE_IP_ADDRESS=$MGMT_IP
EOF
fi

rabbitmq-plugins enable rabbitmq_management

cookie_path="/var/lib/rabbitmq/.erlang.cookie"


if [[ $USE_RABBITMQ_MIRROR -eq 0 ]]; then
  systemctl enable rabbitmq-server
  systemctl start rabbitmq-server
  systemctl restart rabbitmq-server
  ## Add a rabbitmq user 'openstack' and set its permissions 'configuration', 'write', and 'read' access.
  rabbitmqctl add_user openstack ${MQ_PASS}
  rabbitmqctl set_permissions openstack ".*" ".*" ".*"
   
  exit 0
fi


if [[ $FLAG == "initial" ]]; then
  systemctl enable rabbitmq-server
  systemctl start rabbitmq-server
  systemctl restart rabbitmq-server
  # rsync -az $cookie_path $ENV_BASE/erlang.cookie

  ## Add a rabbitmq user 'openstack' and set its permissions 'configuration', 'write', and 'read' access.
  rabbitmqctl add_user openstack ${MQ_PASS}
  rabbitmqctl set_permissions openstack ".*" ".*" ".*"
  rabbitmqctl set_policy ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
else
  rsync -az $ENV_BASE/erlang.cookie $cookie_path
  chown rabbitmq.rabbitmq $cookie_path
  chmod 400 $cookie_path
  systemctl enable rabbitmq-server
  systemctl start rabbitmq-server
  systemctl restart rabbitmq-server

  rabbitmqctl stop_app
  rabbitmqctl cluster_status
  rabbitmqctl join_cluster rabbit@$FIRST_CONT_HOSTNAME
  rabbitmqctl cluster_status
  rabbitmqctl start_app

  rabbitmqctl cluster_status
  rabbitmqctl set_policy ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
fi
