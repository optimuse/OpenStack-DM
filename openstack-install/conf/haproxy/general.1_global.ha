global
  log 127.0.0.1 local2
  chroot /var/lib/haproxy
  daemon
  group haproxy
  maxconn 4000
  pidfile /var/run/haproxy.pid
  user haproxy
