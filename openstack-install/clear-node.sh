#!/bin/bash

usage() {
  echo "Usage: $0 <node-ip>" 
  exit
}

[[ $# -ne 1 ]] && usage

NODE_IP=$1

ssh $NODE_IP "
  # clear mysql
  systemctl stop mysql
  systemctl stop mysql@bootstrap
  rm -rf /var/lib/mysql/*
  rm -rf /etc/my.cnf.d/pxc_openstack.cnf
  yum remove -y Percona-XtraDB-Cluster-55 Percona-XtraDB-Cluster-server-55 Percona-XtraDB-Cluster-client-55 Percona-XtraDB-Cluster-galera-2

  # clear mongodb
  systemctl stop mongod
  rm -rf /etc/mongod.conf
  rm -rf /var/lib/mongodb/*
  yum remove -y mongodb-server mongodb

  # clear redis
  systemctl stop redis
  rm -rf /etc/redis.conf
  rm -rf /var/lib/redis/*
  yum remove -y redis

  # clear rabbitmqctl
  systemctl stop rabbitmq-server
  rm -rf /var/lib/rabbitmq/*
  rm -rf /etc/rabbitmq/*
  yum remove -y rabbitmq-server

  # clear openstack core component

  yum remove -y openstack-keystone python-keystone python-keystoneclient
  rm -rf /etc/keystone/ /var/lib/keystone/ /var/log/keystone/

  yum remove -y openstack-glance python-glance python-glanceclient
  rm -rf /etc/glance/ /var/lib/glance/ /var/log/glance/

  yum remove -y openstack-cinder python-cinderclient python-oslo-db targetcli MySQL-python
  rm -rf /etc/cinder/ /var/lib/cinder/ /var/log/cinder/

  yum remove -y openstack-ceilometer-api openstack-ceilometer-notification openstack-ceilometer-central openstack-ceilometer-common
  rm -rf /etc/ceilometer/ /var/lib/cinder/ /var/log/ceilometer/

  yum remove -y openstack-heat-api openstack-heat-api-cfn openstack-heat-engine python-heatclient openstack-heat-common
  rm -rf /etc/heat/ /var/lib/cinder/ /var/log/heat/

  yum remove -y openstack-nova-commpute openstack-nova-api openstack-nova-scheduler openstack-nova-conductor openstack-nova-cert openstack-nova-console openstack-nova-novncproxy openstack-nova-common openstack-nova-network
  rm -rf /etc/nova/ /var/lib/nova/ /var/log/nova/
  killall dnsmasq

  yum remove -y openstack-dashboard httpd mod_wsgi memcached python-memcached
  yum remove -y keepalived haproxy
  rm -rf /etc/keepalived/ /etc/haproxy/
  
"
