#!/bin/bash

## First, use 'add-new-ceph.sh' script to install ceph on Ceph Nodes.

usage() {
  echo "Usage: $0 <ceph-deploy-dir> <ceph-rgw-node1> <ceph-rgw-node2> ..."
  echo "<ceph-deploy-dir> IS the ceph-deploy base directory."
  echo "<ceph-rgw-node> is the hostname of the rgw node."
  exit 
}

[[ $# -lt 2 ]] && usage

DEPLOY_DIRNAME="$1"
CEPH_RGW_NODES="${@##$1}"

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)

for rgw_node in $CEPH_RGW_NODES; do
  ssh $rgw_node "yum install -y rsync ceph-radosgw mailcap python-boto httpd"
done
  

RADOSGW_KEYRING=$BASE_DIR/$DEPLOY_DIRNAME/ceph.client.radosgw.keyring

for rgw_node in $CEPH_RGW_NODES; do
  HOSTNAME=$rgw_node
  cd $BASE_DIR/$DEPLOY_DIRNAME
  
  if [[ ! -f $RADOSGW_KEYRING ]]; then
    ceph-authtool $RADOSGW_KEYRING --create-keyring
  fi
  chmod +r $RADOSGW_KEYRING
  
  ceph-authtool $RADOSGW_KEYRING -n client.radosgw.$HOSTNAME --gen-key
  ceph-authtool $RADOSGW_KEYRING -n client.radosgw.$HOSTNAME --cap osd 'allow rwx' --cap mon 'allow rwx' 

  ceph auth del client.radosgw.$HOSTNAME
  ceph auth add client.radosgw.$HOSTNAME -i $RADOSGW_KEYRING 

  ## modify ceph.conf in ceph-deploy base dir.
  crud_ceph="crudini --set ceph.conf"
  
  $crud_ceph global osd_pool_default_pg_num 1024
  
  $crud_ceph client.radosgw.$HOSTNAME host $HOSTNAME
  $crud_ceph client.radosgw.$HOSTNAME keyring /etc/ceph/ceph.client.radosgw.keyring
  $crud_ceph client.radosgw.$HOSTNAME rgw_frontends "fastcgi socket_port=9000 socket_host=0.0.0.0"
  $crud_ceph client.radosgw.$HOSTNAME log_file /var/log/ceph/radosgw.log
  $crud_ceph client.radosgw.$HOSTNAME rgw_dns_name $HOSTNAME
done


for rgw_node in $CEPH_RGW_NODES; do
  HOSTNAME=$rgw_node
  cd $BASE_DIR/$DEPLOY_DIRNAME

  ceph-deploy --overwrite-conf config push $HOSTNAME
   
  # keyring file.
  rsync -az $RADOSGW_KEYRING $HOSTNAME:/etc/ceph/
 
  # apache rgw conf
  rsync -az apache_rgw.conf $HOSTNAME:/etc/httpd/conf.d/rgw.conf

  ssh $HOSTNAME "
    sed -i \"/ServerName/c\ServerName $HOSTNAME\" /etc/httpd/conf.d/rgw.conf

    chkconfig ceph-radosgw on
    /etc/init.d/ceph-radosgw start

    systemctl enable httpd
    systemctl start httpd
  "
done
