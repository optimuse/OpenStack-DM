#!/bin/bash

# wget https://packages.graylog2.org/repo/packages/graylog-1.2-repository-el7_latest.rpm

rpm -ivh  graylog-1.2-repository-el7_latest.rpm
yum install -y graylog-server graylog-web

yum install -y graylog-collector

yum install -y pwgen

graylog_secret=$(pwgen -N 1 -s 96)
graylog_password=$(echo -n graylogpass | sha256sum | awk '{print $1}')

crud_gray_server="crudini --set /etc/graylog/server/server.conf"
$crud_gray_server '' password_secret $graylog_secret
$crud_gray_server '' root_username graylogadmin
$crud_gray_server '' root_password_sha2 $graylog_password
$crud_gray_server '' root_timezone Asia/Shanghai

$crud_gray_server '' elasticsearch_cluster_name elasticsearch
$crud_gray_server '' elasticsearch_discovery_zen_ping_multicast_enabled false
$crud_gray_server '' elasticsearch_discovery_zen_ping_unicast_hosts \"http://10.61.1.1:9200\"

crud_gray_web="crudini --set /etc/graylog/web/web.conf"
$crud_gray_web '' application.secret $graylog_secret
$crud_gray_web '' graylog2-server.uris \"http://10.61.1.1:12900\"
$crud_gray_web '' timezone \"Asia/Shanghai\"

crud_gray_collector="crudini --set /etc/graylog/collector/collector.conf"
$crud_gray_collector '' server-url \"http://10.61.1.1:12900\"



systemctl start graylog-server
systemctl start graylog-web
systemctl start graylog-collector
