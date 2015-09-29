#!/bin/bash

usage() {
  echo "Usage: $0  {initial|extra}"
  echo "'initial' means this is the first controller."
  echo "'extra' means this is NOT the first controller."
  exit 1
}

[[ $# -ne 1 ]] && usage
[[ $1 == "initial" ]] || [[ $1 == "extra" ]] || usage

FLAG=$1

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

## **********************************************************


yum install -y http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm

## Install database.

## Empty mysql directory.
[[ $FLAG == "initial" ]] && [[ -d /var/lib/mysql/ ]] && rm -rf /var/lib/mysql/*

## for galera cluster
yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm

yum install -y socat
yum install -y Percona-XtraDB-Cluster-55 Percona-XtraDB-Cluster-server-55 Percona-XtraDB-Cluster-client-55 Percona-XtraDB-Cluster-galera-2

  
openstack_mysql_cnf="/etc/my.cnf.d/pxc_openstack.cnf"

cat <<EOF > $openstack_mysql_cnf
[mysqld]
wait_timeout = 300
interactive_timeout = 300
max_connections = 3000

log-error = /var/log/pxc.log
datadir = /var/lib/mysql
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table = true
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

binlog_format=ROW
innodb_autoinc_lock_mode=2

wsrep_provider=/usr/lib64/libgalera_smm.so
wsrep_provider_options="gcache.size=300M; gcache.page_size=1G"
wsrep_cluster_name="pxc_openstack"
wsrep_cluster_address="gcomm://"

wsrep_sst_method=xtrabackup-v2

# make sure create user and grant privileges to sstuser
# grant all on *.* to 'sstuser'@'localhost' identified by 'sstpass';
# grant all on *.* to 'sstuser'@'%' identified by 'sstpass';
wsrep_sst_auth="sstuser:sstpass"
EOF

controller_ip_list=""
while read n_ip n_host n_ext_ip; do
  controller_ip_list="${controller_ip_list}${n_ip},"
done < $MAP_BASE/controller-node.list

echo $controller_ip_list


# disable SELinux for mysql
semanage permissive -a mysqld_t
semanage permissive -a mysqld_safe_t

# Do not start mysql automatically on boot.
# systemctl enable mysql
systemctl disable mysql

: << comments
if [[ $FLAG == "initial" ]]; then
  systemctl start mysql@bootstrap
  bash -x $BASE_DIR/create-db.sh
else
  crudini --set $openstack_mysql_cnf mysqld wsrep_cluster_address \"gcomm://$controller_ip_list\"
  systemctl start mysql
fi
comments


##  CASE 1
##  Just start mysql if this is not the First node.
if [[ $FLAG == "extra" ]]; then
  crudini --set $openstack_mysql_cnf mysqld wsrep_cluster_address \"gcomm://$controller_ip_list\"
  systemctl start mysql
  exit
fi

## CASE 2
## If this is the fist node, do all the below things.

systemctl start mysql@bootstrap
systemctl restart mysql@bootstrap

## Secure
echo -e "\nn\nY\nn\nY\nY\n" | mysql_secure_installation
# n: No [Change the root password]
# y: Yes [Remove anonymous users]
# n: No [Disallow root login remotely]
# Y: Yes [Remove test database and access to it]
# Y: Yes [Reload privilege tables now]

## Modify database root password.
/usr/bin/mysqladmin -uroot password $MYSQL_PASS

## Remove this later.
mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
grant all on *.* to 'root'@'%' identified by "$MYSQL_PASS";
MYSQLCOMMAND
  

## For galera cluster sync.
mysql -uroot -p$MYSQL_PASS <<MYSQLCOMMAND
grant all on *.* to 'sstuser'@'localhost' identified by 'sstpass';
grant all on *.* to 'sstuser'@"$CONT_MGMT_NET_2" identified by 'sstpass';
MYSQLCOMMAND

## Initial openstack database.
bash -x $HELPER_BASE/init-db.sh
