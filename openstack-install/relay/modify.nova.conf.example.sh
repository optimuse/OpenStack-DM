#!/bin/bash

echo $MGMT_IP
OSC_nova="openstack-config --set /etc/nova/nova.conf"

$OSC_nova DEFAULT verbose True
$OSC_nova DEFAULT debug True

$OSC_nova DEFAULT public_interface eth0
$OSC_nova DEFAULT vlan_interface eth1

systemctl restart openstack-nova-compute
