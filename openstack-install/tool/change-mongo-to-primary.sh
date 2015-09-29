#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <node_ip>"
  echo "<node_ip> is the host where mongo instance resides."
  exit 1
fi

NODE_IP=$1

## Sleep and wait the mongo replica set members failover to choose a new primary.
## replica set members need 10 seconds to mark other inaccessible.
sleep 12

## Test whether the node is the mongo primary.
## If yes, do nothing and exit.
is_master=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["ismaster"]')
if [[ $is_master == "true" ]]; then
  exit 
fi

## If not, we should promote this node to primary by adjust priority.
## Find the current primary mongod instance.
primary_host=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["primary"]')

if [[ $? -ne 0 ]]; then
  echo "Can't get mongodb primary instance.!!!"
  exit 1
else
  pri_host=`echo $primary_host | awk -F: '{print $1}'`
  pri_port=`echo $primary_host | awk -F: '{print $2}'`
fi

# pri_host=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["primary"].split(":")[0]')
# pri_port=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["primary"].split(":")[1]')


me_host=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["me"].split(":")[0]')
me_port=$(mongo --quiet --host $NODE_IP --eval 'db.isMaster()["me"].split(":")[1]')

echo $pri_host
echo $me_host

mongo --host $pri_host --port $pri_port  --eval "
    //javascript 

    conn = new Mongo(\"$pri_host:$pri_port\")
    db = conn.getDB(\"admin\")
    db.auth(\"mongoadmin\", \"mongoadmin4test\")
    
    cfg = rs.conf()
    rs_members = cfg.members

    // set the current instance's priority to 2, all others to 1.
    // thus the current instance will become primary.
    var i = 0
    while (i < rs_members.length) {
      if (rs_members[i].host == \"$me_host:$me_port\") {
        cfg.members[i].priority = 2
      } else {
        cfg.members[i].priority = 1
      }
      i++
    }
    rs.reconfig(cfg)
"

sleep 5
## Now, $me_host is primary.

mongo --host $me_host --port $me_port <<EOF
db.isMaster()
EOF
