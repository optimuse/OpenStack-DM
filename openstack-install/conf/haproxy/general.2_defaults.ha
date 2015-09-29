defaults
  log global
  maxconn 4000
  option redispatch
  retries 3
  timeout http-request 10s
  timeout queue 1m
  timeout connect 10s
  timeout client 100s
  timeout server 100s
 # timeout check 100s
