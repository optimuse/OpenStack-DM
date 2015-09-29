#!/bin/bash

systemctl restart iptables
systemctl restart libvirtd

systemctl restart \
  openstack-nova-api.service openstack-nova-cert.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
 
systemctl restart openstack-nova-network

