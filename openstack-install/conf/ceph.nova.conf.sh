#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

cp $ENV_BASE/ceph-openstack/* /etc/ceph/

chown nova:nova /etc/ceph/ceph.client.cinder.keyring

## Remove old secret uuid if exists to avoid conflict.
old_secret_uuid=$(virsh secret-list | grep "client.cinder secret" | awk '{print $1}')
[[ $old_secret_uuid != "" ]] && virsh secret-undefine $old_secret_uuid

virsh secret-define --file /etc/ceph/secret.xml
virsh secret-set-value --secret $UUID_SECRET --base64 $(cat /etc/ceph/client.cinder.key.tmp)

## 'EOF' close variable substitution.
cat <<'EOF' >> /etc/ceph/ceph.conf
[client]
rbd cache = true
rbd cache writethrough until flush = true
admin socket = /var/run/ceph/$cluster-$type.$id.$pid.$cctid.asok
EOF

OSC_nova="openstack-config --set /etc/nova/nova.conf"

# see http://ceph.com/docs/master/rbd/rbd-openstack/

# Access cinder volumes stored in ceph.
$OSC_nova libvirt rbd_user $CEPH_NOVA_USER
$OSC_nova libvirt rbd_secret_uuid $UUID_SECRET


# Store ephemeral disk into ceph.

$OSC_nova libvirt images_type rbd
$OSC_nova libvirt images_rbd_pool $CEPH_NOVA_POOL
$OSC_nova libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
$OSC_nova libvirt rbd_user $CEPH_NOVA_USER
$OSC_nova libvirt rbd_secret_uuid $UUID_SECRET
$OSC_nova libvirt disk_cachemodes network=writeback

$OSC_nova libvirt inject_password False
$OSC_nova libvirt inject_key False
$OSC_nova libvirt inject_partition -2
# $OSC_nova libvirt live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
$OSC_nova libvirt live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_TUNNELLED,VIR_MIGRATE_PERSIST_DEST

systemctl restart openstack-nova-compute
