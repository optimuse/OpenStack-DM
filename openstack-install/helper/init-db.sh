#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists keystone;
create database keystone;
grant all privileges on keystone.* to "$KEYSTONE_DB_USER"@'localhost' identified by "$KEYSTONE_DB_PASS";
grant all privileges on keystone.* to "$KEYSTONE_DB_USER"@"$CONT_MGMT_NET_2" identified by "$KEYSTONE_DB_PASS";
grant all privileges on keystone.* to "$KEYSTONE_DB_USER"@'%' identified by "$KEYSTONE_DB_PASS";
flush privileges;
MYSQLCOMMAND

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists glance;
create database glance;
grant all privileges on glance.* to "$GLANCE_DB_USER"@'localhost' identified by "$GLANCE_DB_PASS";
grant all privileges on glance.* to "$GLANCE_DB_USER"@"$CONT_MGMT_NET_2" identified by "$GLANCE_DB_PASS";
grant all privileges on glance.* to "$GLANCE_DB_USER"@'%' identified by "$GLANCE_DB_PASS";
flush privileges;
MYSQLCOMMAND

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists cinder;
create database cinder;
grant all on cinder.* to "$CINDER_DB_USER"@'localhost' identified by "$CINDER_DB_PASS";
grant all on cinder.* to "$CINDER_DB_USER"@"$CONT_MGMT_NET_2" identified by "$CINDER_DB_PASS";
grant all on cinder.* to "$CINDER_DB_USER"@'%' identified by "$CINDER_DB_PASS";
flush privileges;
MYSQLCOMMAND

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists nova;
create database nova;
grant all privileges on nova.* to "$NOVA_DB_USER"@'localhost' identified by "$NOVA_DB_PASS";
grant all privileges on nova.* to "$NOVA_DB_USER"@"$CONT_MGMT_NET_2" identified by "$NOVA_DB_PASS";
grant all privileges on nova.* to "$NOVA_DB_USER"@'%' identified by "$NOVA_DB_PASS";
flush privileges;
MYSQLCOMMAND

mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
drop database if exists heat;
create database heat;
grant all privileges on heat.* to "$HEAT_DB_USER"@'localhost' identified by "$HEAT_DB_PASS";
grant all privileges on heat.* to "$HEAT_DB_USER"@"$CONT_MGMT_NET_2" identified by "$HEAT_DB_PASS";
grant all privileges on heat.* to "$HEAT_DB_USER"@'%' identified by "$HEAT_DB_PASS";
flush privileges;
MYSQLCOMMAND

