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
#yum localinstall -y $REPO_BASE/rdo-release-juno.rpm

## Install openstack tools.
yum install -y openstack-selinux openstack-utils

## NTP
yum install -y ntp
grep -q "^server $NTP_SERVER$" /etc/ntp.conf \
    || echo "server $NTP_SERVER" >> /etc/ntp.conf

systemctl enable ntpd
systemctl start ntpd
systemctl restart ntpd


####################
##
## Install keystone.

yum install -y openstack-keystone python-keystone python-keystoneclient

bash -x $CONF_BASE/juno.keystone.conf.sh

keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /etc/keystone/ssl/
chmod -R o-rwx /etc/keystone/ssl
chown -R keystone:keystone /var/log/keystone

[[ $FLAG == "initial" ]] &&
  su keystone -s /bin/sh -c "keystone-manage db_sync"

systemctl enable openstack-keystone
systemctl start openstack-keystone
systemctl restart openstack-keystone

# Use cron to periodically purge expired tokens hourly.
(crontab -l -u keystone 2>&1 | grep -q token_flush) || \
  echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' \
  > /var/spool/cron/keystone

## Init keystone.
[[ $FLAG == "initial" ]] &&
  bash -x $HELPER_BASE/init-keystone.sh


## 
source $RC_BASE/keystone-rc.admin

## Install glance.
yum install -y openstack-glance python-glance python-glanceclient

## Configure glance.

bash -x $CONF_BASE/juno.glance-api.conf.sh
bash -x $CONF_BASE/juno.glance-registry.conf.sh

[[ $FLAG == "initial" ]] &&
  su -s /bin/sh -c "glance-manage db_sync" glance

chown -R glance:glance /var/log/glance

systemctl enable openstack-glance-api openstack-glance-registry
systemctl start openstack-glance-api openstack-glance-registry
systemctl restart openstack-glance-api openstack-glance-registry

glance image-list

## Cinder

yum install -y lvm2
yum install -y openstack-cinder python-cinderclient python-oslo-db targetcli MySQL-python

bash -x $CONF_BASE/juno.cinder.conf.sh

[[ $FLAG == "initial" ]] &&
  su cinder -s /bin/sh -c "cinder-manage db sync"

## If NOT use ceph.
if [[ $USE_CEPH -ne 1 ]]; then
  pvcreate $CINDER_VOLUME_DISK_PATH
  vgcreate cinder-volumes $CINDER_VOLUME_DISK_PATH

  ## configure /etc/lvm/lvm.conf to filter 
  sed -i "/^devices {/a\    filter = [ \"a/$CINDER_VOLUME_DISK/\", \"r/.*/\"]" /etc/lvm/lvm.conf 
fi

systemctl enable lvm2-lvmetad
systemctl start lvm2-lvmetad
systemctl enable openstack-cinder-api openstack-cinder-scheduler
systemctl start openstack-cinder-api openstack-cinder-scheduler

systemctl enable openstack-cinder-volume target
systemctl start openstack-cinder-volume target

## Test cinder volume.
# cinder create --display-name test-volume1 1

systemctl restart openstack-cinder-api
systemctl restart openstack-cinder-scheduler
systemctl restart openstack-cinder-volume


## NOVA

yum install  -y \
openstack-nova-api \
openstack-nova-scheduler \
openstack-nova-conductor \
openstack-nova-cert \
openstack-nova-console \
openstack-nova-novncproxy \
python-novaclient

## Load nova.conf
bash -x $CONF_BASE/juno.nova.conf.sh

[[ $FLAG == "initial" ]] &&
  su nova -s /bin/sh -c "nova-manage db sync"

systemctl enable \
  openstack-nova-api openstack-nova-cert \
  openstack-nova-consoleauth openstack-nova-scheduler \
  openstack-nova-conductor openstack-nova-novncproxy
  
systemctl start \
  openstack-nova-api openstack-nova-cert \
  openstack-nova-consoleauth openstack-nova-scheduler \
  openstack-nova-conductor openstack-nova-novncproxy

systemctl restart \
  openstack-nova-api openstack-nova-cert \
  openstack-nova-consoleauth openstack-nova-scheduler \
  openstack-nova-conductor openstack-nova-novncproxy


# Ceilometer

yum install -y openstack-ceilometer-api \
openstack-ceilometer-collector \
openstack-ceilometer-notification \
openstack-ceilometer-central \
openstack-ceilometer-alarm \
python-ceilometerclient

bash -x $CONF_BASE/juno.ceilometer.conf.sh 

systemctl enable openstack-ceilometer-api  \
    openstack-ceilometer-notification \
    openstack-ceilometer-central \
    openstack-ceilometer-collector \
    openstack-ceilometer-alarm-evaluator \
    openstack-ceilometer-alarm-notifier
  
systemctl restart openstack-ceilometer-api  \
    openstack-ceilometer-notification \
    openstack-ceilometer-central \
    openstack-ceilometer-collector \
    openstack-ceilometer-alarm-evaluator \
    openstack-ceilometer-alarm-notifier

## Dashboard
yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached
sed -i "
/^DEBUG/c\DEBUG = True
/^ALLOWED_HOSTS/c\ALLOWED_HOSTS = ['*']
/^OPENSTACK_HOST/c\OPENSTACK_HOST = \"$CONT_API_IP\"
/^OPENSTACK_KEYSTONE_DEFAULT_ROLE/c\OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"$ROLE_DEFAULT\"
/^TIME_ZONE/c\TIME_ZONE = \"Asia/Shanghai\"
" /etc/openstack-dashboard/local_settings

# Edit Memcached.

## Bind http to management interface not all.
if [[ $CONT_HAPROXY -eq 1 ]]; then
  sed -i "
/^Listen /c\Listen $MGMT_IP:80
" /etc/httpd/conf/httpd.conf
fi


setsebool -P httpd_can_network_connect on
chown -R apache:apache /usr/share/openstack-dashboard/static
systemctl enable httpd.service memcached.service
systemctl start httpd.service memcached.service


## Heat
yum install -y openstack-heat-api openstack-heat-api-cfn openstack-heat-engine python-heatclient

bash -x $CONF_BASE/juno.heat.conf.sh

[[ $FLAG == "initial" ]] &&
  su heat -s /bin/sh -c "heat-manage db_sync"

systemctl enable openstack-heat-api openstack-heat-api-cfn openstack-heat-engine
systemctl start openstack-heat-api openstack-heat-api-cfn openstack-heat-engine
systemctl restart openstack-heat-api openstack-heat-api-cfn openstack-heat-engine
