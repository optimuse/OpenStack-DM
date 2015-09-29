#!/bin/bash

## Download InfluxDB rpm packages.
# see https://influxdb.com/download/index.html


## Install InfluxDB
# yum localinstall -y influxdb-0.9.4.1-1.x86_64.rpm
# yum localinstall -y telegraf-0.1.8-1.x86_64.rpm
yum localinstall -y influxdb-*.rpm
yum localinstall -y telegraf-*.rpm

# InfluxDB collectd plugin need this.
yum install -y collectd



# service init file for systemd
# /opt/influxdb/versions/0.9.4.1/scripts/influxdb.service
# cp /opt/influxdb/versions/0.9.4.1/scripts/influxdb.service /usr/lib/systemd/system/

# service init file for init.d
# /opt/influxdb/versions/0.9.4.1/scripts/init.sh

DATA_DIR="/data/influxdb"
[[ ! -d $DATA_DIR ]] && mkdir -p $DATA_DIR
chown -R influxdb.influxdb $DATA_DIR

##!!!!!!!!
## influxdb.conf is NOT INI format. It's TOML format.

## To Be changed.

# Delete blank space at the begining of the line, or ini parsing errors.
sed  -i 's/^ *//' /etc/opt/influxdb/influxdb.conf

# [[graphite]] and [[udp]] does not compatible with ini format.
sed -i 's/\[\[graphite\]\]/[graphite]/g' /etc/opt/influxdb/influxdb.conf
sed -i 's/\[\[udp\]\]/[udp]/g' /etc/opt/influxdb/influxdb.conf

crud_influxdb="crudini --set /etc/opt/influxdb/influxdb.conf"

$crud_influxdb meta dir \"$DATA_DIR/meta\"
$crud_influxdb data dir \"$DATA_DIR/data\"
$crud_influxdb data wal-dir \"$DATA_DIR/wal\"
$crud_influxdb hinted-handoff dir \"$DATA_DIR/hh\"

$crud_influxdb admin enabled true
$crud_influxdb http enabled true
$crud_influxdb http auth-enabled true

# listener for graphite
$crud_influxdb graphite enabled true
$crud_influxdb graphite bind-address \":2003\"

# listener for collectd
$crud_influxdb collectd enabled true
$crud_influxdb collectd bind-address \":25826\"
$crud_influxdb collectd database \"collectd\"
$crud_influxdb collectd typesdb \"/usr/share/collectd/types.db\"

# listener for opentsdb
$crud_influxdb opentsdb enabled true
#$crud_influxdb opentsdb bind-address 

sed -i 's/\[graphite\]/[[graphite]]/g' /etc/opt/influxdb/influxdb.conf
sed -i 's/\[udp\]/[[udp]]/g' /etc/opt/influxdb/influxdb.conf

# chkconfig influxdb on
# /etc/init.d/influxdb start

systemctl daemon-reload
systemctl start influxdb


##
## How to use InfluxDB 
##

## create InfluxDB admin user.
/opt/influxdb/influx <<EOF
CREATE USER influxadmin WITH PASSWORD 'influxadmin4test' WITH ALL PRIVILEGES
EOF


/opt/influxdb/influx -username influxadmin -password influxadmin4test  <<EOF
create database os_report
create database telegraf
create user telegraf with password 'telegrafpass'
grant all on telegraf to telegraf
EOF

####  Auth
## Using Basic Auth
# curl -G http://localhost:8086/query -u mydb_username:mydb_password --data-urlencode "q=CREATE DATABASE mydb"

## or Sending credentials via query parameters
# curl -G http://localhost:8086/query --data-urlencode "u=mydb_username" --data-urlencode "p=mydb_password" --data-urlencode "q=CREATE DATABASE mydb"

# Only admin users are allowed to create databases
