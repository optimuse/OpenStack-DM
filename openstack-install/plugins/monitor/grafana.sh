#!/bin/bash

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists grafana;
create database grafana;
grant all privileges on grafana.* to "$GRAFANA_DB_USER"@'localhost' identified by "$GRAFANA_DB_PASS";
grant all privileges on grafana.* to "$GRAFANA_DB_USER"@"$CONT_MGMT_NET_2" identified by "$GRAFANA_DB_PASS";
grant all privileges on grafana.* to "$GRAFANA_DB_USER"@'%' identified by "$GRAFANA_DB_PASS";
flush privileges;
MYSQLCOMMAND

crud_grafana="crudini --set /etc/grafana/grafana.ini"

$crud_grafana database type mysql
$crud_grafana database host $CONT_MGMT_NET_2
$crud_grafana database name grafana
$crud_grafana database user $GRAFANA_DB_USER
$crud_grafana database password $GRAFANA_DB_PASS

$crud_grafana http auth enabled
$crud_grafana users allow_sign_up false

  
# Grafana Zabbix Plugin
git clone https://github.com/alexanderzobnin/grafana-zabbix.git
cp -R grafana-zabbix/zabbix /usr/share/grafana/public/app/plugins/datasource/

cd /usr/share/grafana/public/app/plugins/datasource/zabbix/
## vim plugin.json  ## Edit username/password


# Restart grafana
/etc/init.d/grafana-server restart
