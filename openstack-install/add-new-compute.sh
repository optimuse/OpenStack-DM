#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 <hostip> <hostname> [<extip>]"
  echo "<hostip> is the Management IP of the node."
  echo "<extip> is optional, and is the External IP of the node if exist."
  exit 1
fi

export node_ip=$1
export node_hostname=$2
[[ -n $3 ]] && node_ext_ip=$3 || node_ext_ip=$node_ip

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)
source $BASE_DIR/load-environment.sh

## **********************************************************

# Record all compute nodes, this file will be used as a reference to sync nova-ssh to all compute nodes.
if ! grep -sq $node_ip $MAP_BASE/compute-node.list; then
  cat <<EOF >> $MAP_BASE/compute-node.list
$node_ip $node_hostname
EOF
fi

# Gather nova host key.
node_host_key="$(awk '/'$node_ip'/{print $2,$3}' /root/.ssh/known_hosts)"

if ! grep -sq $node_ip $ENV_BASE/nova-ssh/known_hosts; then
  cat <<EOF >> $ENV_BASE/nova-ssh/known_hosts
$node_hostname,$node_ip $node_host_key
EOF
fi

## Common things need to do when adding a new node.
bash $BASE_DIR/add-new-node.sh $node_ip $node_hostname $node_ext_ip


## When adding a new compute node, we need to make sure all controller node(s)
## can password-less login to this compute node.
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
while read n_ip n_hostname n_ext_ip; do 
  ssh -o StrictHostKeyChecking=no -A $n_ip "
    ssh -o StrictHostKeyChecking=no $node_ip "hostname"
    ssh-copy-id -i ~/.ssh/id_rsa.pub $node_ip
  " < /dev/null
done < $MAP_BASE/controller-node.list


ssh $node_ip "

cat <<EOF > $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/env/my.ip
export MGMT_IP=$node_ip
export EXT_IP=$node_ext_ip
export NODE_HOSTNAME=$node_hostname
EOF

## 1. Prepare Host(update).
bash -x $DEPLOY_TEMP_DIR/OpenStack-DM/common/prepare-host-centos7.sh

## 2. Setup iptables on node.
bash -x $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/helper/setup-iptables-on-node.sh

## 3. Install compute node.
bash -x $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/inst/install-juno.compute.sh $FLAG

## 4. Install ceph client.
bash -x $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/inst/install-ceph-client.sh

## 5. Configure ceph for nova.
bash -x $DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/helper/setup-ceph-on-nova.sh

"

# When compute node installation finished, /var/lib/nova/ directory should exist.
# Because known_hosts file records this new compute node, so we need to sync nova-ssh/* to all compute nodes.

while read n_ip n_name; do
  echo $n_name
  rsync -av $ENV_BASE/nova-ssh/* $n_ip:/var/lib/nova/.ssh/
  ssh $n_ip "
    chown -R nova.nova /var/lib/nova/.ssh/
    chmod 600 /var/lib/nova/.ssh/id_rsa
    chmod 644 /var/lib/nova/.ssh/{id_rsa.pub,authorized_keys,known_hosts}
    # chcon system_u:object_r:user_home_t:s0 /var/lib/nova
    chcon -R unconfined_u:object_r:user_home_t:s0 /var/lib/nova/.ssh
  " < /dev/null
done < $MAP_BASE/compute-node.list
