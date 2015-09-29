#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

ES_AUTH=0
ES_IP=10.5.255.4
KIBANA_AUTH_USERNAME=kibanaadmin
KIBANA_AUTH_USERPASS=kibanaadmin

# Install kibana
yum install -y java-1.8.0-openjdk

wget -c -P /opt https://download.elastic.co/kibana/kibana/kibana-4.1.1-linux-x64.tar.gz
tar -xzf /opt/kibana-4.1.1-linux-x64.tar.gz -C /opt

# mv /opt/kibana-4.1.1-linux-x64 /opt/kibana
ln -s /opt/kibana-4.1.1-linux-x64 /opt/kibana


# Create a kibana start file.
cat <<EOF > /etc/systemd/system/kibana.service
[Service]
ExecStart=/opt/kibana/bin/kibana
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=kibana4
User=root
Group=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF


sed -i "
/elasticsearch_url:/c\elasticsearch_url: \"http://${ES_IP}:9200\"
" /opt/kibana/config/kibana.yml 


## If Elasticsearch auth enabled.
if [[ ES_AUTH -eq 1 ]]; then
  sed -i "
  /kibana_elasticsearch_username:/c\kibana_elasticsearch_username: $KIBANA_USERNAME
  /kibana_elasticsearch_password:/c\kibana_elasticsearch_password: $KIBANA_USERPASS
  " /opt/kibana/config/kibana.yml 
fi

## Start kibana
systemctl daemon-reload
systemctl enable kibana
systemctl start kibana
