#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

OSC_g_api="openstack-config --set /etc/glance/glance-api.conf"

# see http://ceph.com/docs/master/rbd/rbd-openstack/
# see https://bugs.launchpad.net/fuel/+bug/1374366

$OSC_g_api DEFAULT known_stores glance.store.rbd.Store
$OSC_g_api glance_store stores "glance.store.filesystem.Store,glance.store.rbd.Store"
$OSC_g_api glance_store default_store rbd
$OSC_g_api glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
$OSC_g_api glance_store rbd_store_user $CEPH_GLANCE_USER
$OSC_g_api glance_store rbd_store_pool $CEPH_GLANCE_POOL
$OSC_g_api glance_store rbd_store_chunk_size 8

# enable copy-on-write cloning of images
$OSC_g_api DEFAULT show_image_direct_url True
$OSC_g_api DEFAULT enable_v2_api True

systemctl restart openstack-glance-api
