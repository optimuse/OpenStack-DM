#!/bin/bash

## When use Ceph as OpenStack's Storage base, then
## nodes running 'glance-api', 'cinder-volume', 'nova-compute' become 'Ceph Client Node'.
## So all openstack nodes (controller node and compute node) need to install ceph.

yum install -y http://ceph.com/rpm-hammer/el7/noarch/ceph-release-1-0.el7.noarch.rpm
yum install -y ceph
