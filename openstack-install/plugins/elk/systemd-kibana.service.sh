#!/bin/bash

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

