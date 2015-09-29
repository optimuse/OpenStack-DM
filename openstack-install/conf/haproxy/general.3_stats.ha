# HAProxy web ui
listen stats 0.0.0.0:9000
  mode http
  stats enable
  stats uri /haproxy
  stats realm HAProxy\ Statistics
  stats auth haproxy:haproxy
  stats admin if TRUE
