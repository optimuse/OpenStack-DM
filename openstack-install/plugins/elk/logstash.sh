#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

yum install -y java-1.8.0-openjdk

yum install -y logstash
yum install -y logstash-forwarder

cd /etc/logstash
curl -O "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
gzip -d GeoLiteCity.dat.gz

## Generate SSL Certificates

#Edit /etc/pki/tls/openssl.cnf
yum install -y crudini
crudini --set /etc/pki/tls/openssl.cnf ' v3_ca ' subjectAltName IP:10.5.255.4

openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/logstash-forwarder.key \
  -out /etc/pki/tls/certs/logstash-forwarder.crt

# openssl req -subj '/CN=logstash_server_fqdn/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 \
#  -keyout private/logstash-forwarder.key \
#  -out certs/logstash-forwarder.crt

#### Logstach conf.d

## logstash input
cat <<EOF > /etc/logstash/conf.d/00-lumberjack.conf
input {
  lumberjack {
    port => 5043
    type => "logs"
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
EOF

cat <<EOF > /etc/logstash/conf.d/01-syslog.conf
input {
  syslog {
    host => 5514
  }
}
EOF

## logstash filter

## logstash output
cat <<EOF > /etc/logstash/conf.d/60-elasticsearch.conf
output {
  stdout {}
  elasticsearch {
    embedded => false
    protocol => http
    host => "10.5.255.4"
    cluster => "es-openstack"
    # user => "es_admin"
    # password => "es_admin"
  }
}
EOF
