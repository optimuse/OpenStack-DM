#!/bin/bash

cat <<'EOF' > /etc/nginx/conf.d/graylog.conf
server {
    listen 8080;
    server_name graylog.galaxy.com;

    # auth_basic "Restricted Access";
    # auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

