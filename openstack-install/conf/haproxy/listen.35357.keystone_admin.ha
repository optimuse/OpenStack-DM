listen keystone_admin_35357
  balance source
  option tcpka
  option tcp-check
  option tcplog
  # server <hostname> $MGMT_IP:35357 check inter 2000 rise 2 fall 5
