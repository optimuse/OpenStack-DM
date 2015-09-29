#!/bin/bash

cat <<'EOF' > /etc/nginx/conf.d/grafana.conf
server {
    listen 8080;
    server_name grafana.galaxy.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

