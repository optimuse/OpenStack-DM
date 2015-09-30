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

## Install Keepalived

yum install -y keepalived

## Keepalived log
## disable shell variable substitution
cat <<'EOF' > /etc/rsyslog.d/keepalived.conf
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

local0.*        /var/log/keepalived.log
EOF

## Install Haproxy.

if [[ $CONT_HAPROXY -eq 1 ]]; then
  yum install -y haproxy

## Haproxy log
## disable shell variable substitution
  cat <<'EOF' > /etc/rsyslog.d/haproxy.conf
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

local2.*	/var/log/haproxy.log
& ~
# & ~ means to stop processing the message after it was written to the log

# $template Haproxy,"%msg%\n"
# local1.=info -/var/log/haproxy.log;Haproxy
# local2.notice -/var/log/haproxy-status.log;Haproxy
# local2.* ~
EOF
fi


cd $BASE_DIR
restorecon -R /etc/rsyslog.d/
systemctl restart rsyslog


## Configure Haproxy.

if [[ $CONT_HAPROXY -eq 1 ]]; then
  # Allow non-local Virtual IPs binding.
  crudini --set /etc/sysctl.conf '' net.ipv4.ip_nonlocal_bind 1
  sysctl -p

  ## Generate haproxy.cfg
  HAPROXY_CFG=/tmp/haproxy.cfg.tmp
  sh -x $HELPER_BASE/create-haproxy-cfg.sh $HAPROXY_CFG
  rsync -az $HAPROXY_CFG /etc/haproxy/haproxy.cfg

  systemctl enable haproxy
  systemctl start haproxy
  systemctl restart haproxy
fi

## Configure Keepalived.

crudini --set /etc/sysconfig/keepalived '' KEEPALIVED_OPTIONS '"-D -S0 -d"'


# keepalived.conf

rsync -az  $CONF_BASE/keepalived/keepalived.conf.tmpl /etc/keepalived/keepalived.conf

sed -i "
s/<CONT_API_IP>/$CONT_API_IP/g;
s/<CONT_MGMT_IP>/$CONT_MGMT_IP/g;
" /etc/keepalived/keepalived.conf


if [[ $FLAG == "initial" ]]; then
  sed -i "s/<PRIORITY>/100/g" /etc/keepalived/keepalived.conf
else
  sed -i "s/<PRIORITY>/99/g" /etc/keepalived/keepalived.conf
fi


# script used by keepalived.

rsync -az $CONF_BASE/keepalived/keepalived-status-change.sh.tmpl /usr/libexec/keepalived/keepalived-status-change.sh

sed -i "
s%<OPENSTACK_INSTALL_DIR>%$DEPLOY_TEMP_DIR/OpenStack-DM/openstack-install/%g;
" /usr/libexec/keepalived/keepalived-status-change.sh
chmod +x /usr/libexec/keepalived/keepalived-status-change.sh
restorecon -R /usr/libexec/keepalived/


systemctl enable keepalived
systemctl start keepalived
systemctl restart keepalived
