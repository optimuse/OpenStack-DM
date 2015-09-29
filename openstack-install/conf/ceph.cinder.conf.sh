#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

cp $ENV_BASE/ceph-openstack/* /etc/ceph/

#uuid_secret=$(awk -F '[<>]' '/<uuid>/{print $3}' /etc/ceph/secret.xml)

OSC_cinder="openstack-config --set /etc/cinder/cinder.conf"

$OSC_cinder DEFAULT volume_driver cinder.volume.drivers.rbd.RBDDriver
$OSC_cinder DEFAULT rbd_ceph_conf /etc/ceph/ceph.conf
$OSC_cinder DEFAULT rbd_pool $CEPH_CINDER_POOL
$OSC_cinder DEFAULT glance_api_version 2
$OSC_cinder DEFAULT rbd_user $CEPH_CINDER_USER
$OSC_cinder DEFAULT rbd_secret_uuid ${UUID_SECRET}
$OSC_cinder DEFAULT rbd_flatten_volume_from_snapshot false
$OSC_cinder DEFAULT rbd_max_clone_depth 5
$OSC_cinder DEFAULT rbd_store_chunk_size 4
$OSC_cinder DEFAULT rados_connect_timeout -1

systemctl restart openstack-cinder-volume
