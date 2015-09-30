#!/bin/bash

usage() {
  echo "Usage: $0 <hostip> <hostname> <extip> {initial|extra}"
  echo "'initial' means this is the first controller."
  echo "'extra' means this is NOT the first controller."
  exit 1
}

[[ $# -ne 4 ]] && usage
[[ $4 == "initial" ]] || [[ $4 == "extra" ]] || usage

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

## **********************************************************


prepare_prompt() {
  read -p "Do you have execute $BASE_DIR/prepare-openstack-cluster.sh script to prepare your openstack? [y|n] " ANSWER
  [ $ANSWER == "n" ] && exit
  [ $ANSWER == "y" ] && return
  prepare_prompt
}

export node_ip=$1
export node_hostname=$2
export node_ext_ip=$3
export FLAG=$4

[[ $FLAG == "initial" ]] && prepare_prompt


# Record controller nodes, record external ip as well.
if ! grep -sq $node_ip $MAP_BASE/controller-node.list; then
  cat <<EOF >> $MAP_BASE/controller-node.list
$node_ip $node_hostname $node_ext_ip
EOF
fi


if [[ $USE_RABBITMQ_MIRROR -eq 1 ]]; then
  ## Update all rabbit_hosts in the configurations.
  rabbit_hosts_list="$CONT_MGMT_IP:5672,"
  while read n_ip n_host n_ext_ip; do
    rabbit_hosts_list="${rabbit_hosts_list}${n_ip}:5672,"
  done < $MAP_BASE/controller-node.list
fi

## Common things need to do when adding a new node.
bash $BASE_DIR/add-new-node.sh $node_ip $node_hostname $node_ext_ip


## When adding a new controller node, we need to make sure this controller node
## can password-less login to all other nodes.
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
ssh -A $node_ip "
[[ ! -f ~/.ssh/id_rsa ]] && ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''
source $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/load-environment.sh
while read n_ip n_hostname; do
  ssh -o StrictHostKeyChecking=no \$n_ip "hostname" </dev/null
  ssh-copy-id -i ~/.ssh/id_rsa.pub \$n_ip < /dev/null
done < \$MAP_BASE/all-node.list
"


# Install
ssh $node_ip "

cat <<EOF > $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/env/my.ip
export MGMT_IP=$node_ip
export EXT_IP=$node_ext_ip
export NODE_HOSTNAME=$node_hostname
EOF

## 1. Prepare Host(update).
bash $DEPLOY_TEMP_DIR/OpenStack-DM/common/prepare-host-centos7.sh

## 2. Setup iptables on node.
bash $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/helper/setup-iptables-on-node.sh

## 3. Install controller node.
bash $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/inst/install-juno.controller.sh $FLAG

## 4. Install ceph client.
bash $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/inst/install-ceph-client.sh

## 5. Configure ceph for glance/cinder.
bash $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/helper/setup-ceph-on-glance.sh 
bash $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/helper/setup-ceph-on-cinder.sh
"


## Fetch
cookie_path="/var/lib/rabbitmq/.erlang.cookie"
if [[ $FLAG == "initial" ]]; then
  rsync -az $node_ip:$cookie_path $ENV_BASE/erlang.cookie
fi


## If use haproxy.
if [[ $CONT_HAPROXY -eq 1 ]]; then
## Update haproxy.cfg file of every controller node.
bash $HELPER_BASE/create-haproxy-cfg.sh /tmp/haproxy.cfg.tmp

while read n_ip n_name n_ext_ip; do
  echo $n_name
  rsync -az /tmp/haproxy.cfg.tmp  $n_ip:/etc/haproxy/haproxy.cfg
  ssh $n_ip "systemctl restart haproxy" < /dev/null
done < $MAP_BASE/controller-node.list
fi


## Update PXC cluster addresses of mysql configuration on every controller node.
openstack_mysql_cnf="/etc/my.cnf.d/pxc_openstack.cnf"
controller_ip_list=""
while read n_ip n_host n_ext_ip; do
  controller_ip_list="${controller_ip_list}${n_ip},"
done < $MAP_BASE/controller-node.list

echo $controller_ip_list

while read n_ip n_name n_ext_ip; do
  ssh $n_ip "crudini --set $openstack_mysql_cnf mysqld wsrep_cluster_address \"gcomm://$controller_ip_list\"" < /dev/null
done < $MAP_BASE/controller-node.list
