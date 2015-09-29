listen rabbitmq_5672
  timeout client 3600s
  timeout server 3600s
  balance source
  option tcplog
  option tcpka
