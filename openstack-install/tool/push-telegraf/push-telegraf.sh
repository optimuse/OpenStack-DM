#!/bin/bash

IPFILE=$1

push_telegraf_to_init() {
  ssh $SSH_OPTIONS $1 "
    stop telegraf
    killall telegraf
  "

  scp telegraf.conf $1:/etc/telegraf.conf
  scp init-telegraf.conf $1:/etc/init/telegraf.conf
  scp telegraf.bin $1:/usr/local/bin/telegraf

  ssh $SSH_OPTIONS $1 "
    sed -i '/hostname =/c\    hostname = \"$1\"' /etc/telegraf.conf
    chmod +x /usr/local/bin/telegraf
    killall telegraf
    stop telegraf
    start telegraf
    status telegraf
  "
}


push_telegraf_to_systemd() {
  ssh $SSH_OPTIONS $1 "
    systemctl stop telegraf
    killall telegraf
  "
  scp telegraf.conf $1:/etc/telegraf.conf
  scp systemd-teleconf.service $1:/lib/systemd/system/telegraf.service
  scp telegraf.bin $1:/usr/local/bin/telegraf

  ssh $1 "
    sed -i '/hostname =/c\    hostname = \"$1\"' /etc/telegraf.conf
    systemctl daemon-reload
    chmod +x /usr/local/bin/telegraf
    killall telegraf
    systemctl stop telegraf
    systemctl enable telegraf
    systemctl start telegraf
    systemctl status telegraf
 "
}

> /tmp/push.log

SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=10s"

while read -u10 IP; do
  ssh $SSH_OPTIONS $IP "hostname"
  [[ $? -ne 0 ]] && echo "$IP - Not Connected"  >> /tmp/push.log && continue

  if ssh $SSH_OPTIONS $IP "cat /etc/redhat-release 2>/dev/null" | grep -sq 'CentOS Linux release 7'; then
    os_release='CentOS 7'
  elif ssh $SSH_OPTIONS $IP "cat /etc/redhat-release 2>/dev/null" | grep -sq 'CentOS release 6'; then
    os_release='CentOS 6'
  elif ssh $SSH_OPTIONS $IP "cat /etc/issue 2>/dev/null" | grep -sq 'Ubuntu 14'; then
    os_release='Ubuntu 14'
  elif ssh $SSH_OPTIONS $IP "cat /etc/issue 2>/dev/null" | grep -sq 'Ubuntu 12'; then
    os_release='Ubuntu 12'
  elif ssh $SSH_OPTIONS $IP "cat /etc/issue 2>/dev/null" | grep -sq 'openSUSE 13'; then
    os_release='openSUSE 13'
  elif ssh $SSH_OPTIONS $IP "cat /etc/issue 2>/dev/null" | grep -sq 'Debian GNU/Linux 8'; then
    os_release='Debian 8'
  else
    os_release='Unknown'
  fi

  case "$os_release" in
    'CentOS 6' | 'Ubuntu 12' | 'Ubuntu 14' )
       push_telegraf_to_init $IP
       echo "$IP - $os_release" >> /tmp/push.log
       ;;
    'CentOS 7' | 'Debian 8' | 'openSUSE 13')
       push_telegraf_to_systemd $IP
       echo "$IP - $os_release" >> /tmp/push.log
       ;;
       
    *)
       echo "$IP - Unkown OS"  >> /tmp/push.log
       ;;
  esac
done 10< $IPFILE
