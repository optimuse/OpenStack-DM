#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

LOGSTASH_IP=10.5.255.4

yum install -y java-1.8.0-openjdk

yum install -y logstash-forwarder

cat <<EOF > /etc/logstash-forwarder.conf
{
  "network": {
    "servers": [ "${LOGSTASH_IP}:5043" ],
    "ssl key": "/etc/pki/tls/private/logstash-forwarder.key",
    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt",
    "timeout": 15
  },

  "files": [
    {
      "paths": [
        "/var/log/messages",
        "/var/log/secure"
       ],
      "fields": { "type": "syslog" }
    }
  ]
