#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

ES_DATA_PATH="/data/elasticsearch"
ES_CLUSTERNAME="es-openstack"
ES_AUTH=0
ES_ADMIN_USER=es-admin
ES_ADMIN_PASS=es-admin
KIBANA_AUTH_USERNAME=kibanaadmin
KIBANA_AUTH_USERPASS=kibanaadmin


mkdir -p $ES_DATA_PATH
chown -R elasticsearch.elasticsearch $ES_DATA_PATH

yum install -y java-1.8.0-openjdk

## ElasticSearch

## Online Install ES
: <<comments
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-1.7]
name=Elasticsearch repository for 1.7.x packages
baseurl=http://packages.elastic.co/elasticsearch/1.7/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF

# yum install -y elasticsearch
comments

rpm -ivh elasticsearch-1.7.1.noarch.rpm 


sed -i "
/cluster.name:/c\cluster.name: $ES_CLUSTERNAME
/path.data:/c\path.data: $ES_DATA_PATH
" /etc/elasticsearch/elasticsearch.yml


#### (optional) Elasticsearch Auth

# ElasticSearch Plugins

if [[ $ES_AUTH -eq 1 ]]; then
  cd /usr/share/elasticsearch
  bin/plugin install elasticsearch/license/latest
  bin/plugin install elasticsearch/shield/latest
  
  cd /usr/share/elasticsearch
  bin/shield/esusers useradd $ES_ADMIN_USER -r admin -p $ES_ADMIN_PASS
  bin/shield/esusers useradd $KIBANA_AUTH_USERNAME -r kibana4_server,kibana4 -p $KIBANA_AUTH_USERPASS
fi

# curl -XDELETE http://localhost:9200/.kibana --user es_admin:es_admin
# kibanaadmin is the user 'Kibana Web' HTTP basic auth AND is the user Kibana uses to connect to elasticsearch.
# kibana4 server needs this TWO roles to function correctly.

###################################

:<< comments
yum install -y unzip
mkdir /usr/share/elasticsearch/plugins/license
unzip license-1.0.0.zip -d /usr/share/elasticsearch/plugins/license/
mkdir /usr/share/elasticsearch/plugins/shield
unzip shield-1.3.2.zip -d /usr/share/elasticsearch/plugins/shield/
comments

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch
