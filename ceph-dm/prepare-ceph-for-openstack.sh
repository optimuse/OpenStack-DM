#!/bin/bash

usage() {
  echo "Usage: $0 <ceph-deploy-dir>"
  exit
}

[[ $# -ne 1 ]] && exit

BASE_DIR=$(dirname $0)
BASE_DIR=$(cd $BASE_DIR; pwd)

## Enter ceph-deploy work dir.
CEPH_DEPLOY_DIR=$BASE_DIR/$1
CEPH_OPENSTACK_DIR="$BASE_DIR/ceph-openstack"

if [ ! -d $CEPH_DEPLOY_DIR ]; then
  echo "$CEPH_DEPLOY_DIR not exist, exit"
  exit
fi

[[ ! -d $CEPH_OPENSTACK_DIR ]] && mkdir $CEPH_OPENSTACK_DIR

###############################################

cd $CEPH_DEPLOY_DIR

## Create ceph pools for openstack.
## images pool to store Glance uploaded images
## volumes pool to store Cinder volumes
## vms pool to store Nova ephemeral disks.

ceph_cinder_pool=volumes
ceph_glance_pool=images
ceph_nova_pool=vms
ceph_cinder_backup_pool=backups

ceph_cinder_user=cinder
ceph_glance_user=glance
ceph_nova_user=cinder
ceph_cinder_backup_user=cinder-backup

## Create ceph pools.
ceph osd pool create $ceph_cinder_pool 1024
ceph osd pool create $ceph_glance_pool 1024
ceph osd pool create $ceph_nova_pool 1024
ceph osd pool create $ceph_cinder_backup_pool 1024

## Setup replication level for ceph pools.
ceph osd pool set $ceph_cinder_pool size 3
ceph osd pool set $ceph_glance_pool size 3
ceph osd pool set $ceph_nova_pool size 3
ceph osd pool set $ceph_cinder_backup_pool size 3

## Setup ceph client authentication
## Create Ceph user for Nova/Cinder/Glance
ceph auth get-or-create client.$ceph_cinder_user mon 'allow r' osd "allow class-read object_prefix rbd_children, allow rwx pool=$ceph_cinder_pool, allow rwx pool=$ceph_nova_pool, allow rx pool=$ceph_glance_pool"
ceph auth get-or-create client.$ceph_glance_user mon 'allow r' osd "allow class-read object_prefix rbd_children, allow rwx pool=$ceph_glance_pool"
ceph auth get-or-create client.$ceph_cinder_backup_user mon 'allow r' osd "allow class-read object_prefix rbd_children, allow rwx pool=$ceph_cinder_backup_pool"

## For simplicity, store keyring files of Ceph user client.glance and client.cinder in a centralized place.
ceph auth get-or-create client.$ceph_glance_user | tee $CEPH_OPENSTACK_DIR/ceph.client.glance.keyring
ceph auth get-or-create client.$ceph_cinder_user | tee $CEPH_OPENSTACK_DIR/ceph.client.cinder.keyring
ceph auth get-key client.$ceph_cinder_user | tee $CEPH_OPENSTACK_DIR/client.cinder.key.tmp
rsync -az $CEPH_DEPLOY_DIR/ceph.conf $CEPH_OPENSTACK_DIR/ceph.conf


if [ -f $CEPH_OPENSTACK_DIR/secret.xml ]; then
  uuid_secret=$(cat $CEPH_OPENSTACK_DIR/secret.xml | xargs | sed 's%.*<uuid>\(.*\)</uuid>.*%\1%' | tr -d ' ')
fi

[[ $uuid_secret == "" ]] && uuid_secret=$(uuidgen)

cat <<EOF > $CEPH_OPENSTACK_DIR/secret.xml
<secret ephemeral='no' private='no'>
  <uuid>${uuid_secret}</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF

## Output the environment.
cat <<EOF > $CEPH_OPENSTACK_DIR/ceph-openstack.env
CEPH_CINDER_POOL=$ceph_cinder_pool
CEPH_GLANCE_POOL=$ceph_glance_pool
CEPH_NOVA_POOL=$ceph_nova_pool
CEPH_CINDER_BACKUP_POOL=$ceph_cinder_backup_pool

CEPH_CINDER_USER=$ceph_cinder_user
CEPH_GLANCE_USER=$ceph_glance_user
CEPH_NOVA_USER=$ceph_nova_user
CEPH_CINDER_BACKUP_USER=$ceph_cinder_backup_user

UUID_SECRET=$uuid_secret
EOF

rsync -az $CEPH_OPENSTACK_DIR $BASE_DIR/../openstack-install/env/
