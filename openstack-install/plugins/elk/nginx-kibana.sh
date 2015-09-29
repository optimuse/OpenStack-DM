#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh


rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum install -y nginx
bash $CONF_BASE/elk/nginx-kibana.conf.sh

setsebool -P httpd_can_network_connect on
systemctl start nginx
systemctl enable nginx
