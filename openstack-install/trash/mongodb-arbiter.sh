: <<comments
#### Deploy a mongodb-arbiter on port 27018.

if [[ $FLAG == "extra" ]]; then

rsync -az /etc/mongod.conf /etc/mongod-arbiter.conf
restorecon /etc/mongod-arbiter.conf

mkdir /var/lib/mongodb/arbiter
chown -R mongodb.mongodb /var/lib/mongodb/arbiter/ 

rsync -az /etc/sysconfig/mongod /etc/sysconfig/mongod-arbiter
restorecon /etc/sysconfig/mongod-arbiter

rsync -az /usr/lib/systemd/system/mongod.service /usr/lib/systemd/system/mongod-arbiter.service
restorecon /usr/lib/systemd/system/mongod-arbiter.service

crud_mongod_a="crudini --set /etc/mongod-arbiter.conf"
$crud_mongod_a '' bind_ip 0.0.0.0
$crud_mongod_a '' port 27018

$crud_mongod_a '' pidfilepath /var/run/mongodb/mongod-arbiter.pid
$crud_mongod_a '' logpath /var/log/mongodb/mongod-arbiter.log
$crud_mongod_a '' unixSocketPrefix /var/run/mongodb
$crud_mongod_a '' dbpath /var/lib/mongodb/arbiter
$crud_mongod_a '' keyFile /var/lib/mongodb/mongodb-keyfile

$crud_mongod_a '' replSet rs0
$crud_mongod_a '' dbpath /var/lib/mongodb/arbiter
$crud_mongod_a '' auth true
$crud_mongod_a '' rest true
$crud_mongod_a '' smallfiles true


crudini --set /etc/sysconfig/mongod-arbiter '' OPTIONS '"--quiet -f /etc/mongod-arbiter.conf"'

crud_mongod_a_service="crudini --set /usr/lib/systemd/system/mongod-arbiter.service"
$crud_mongod_a_service Service EnvironmentFile /etc/sysconfig/mongod-arbiter
$crud_mongod_a_service Service PIDFile \${PIDFILE-/var/run/mongodb/mongod-arbiter.pid}

systemctl daemon-reload
systemctl enable mongod-arbiter
systemctl start mongod-arbiter
systemctl restart mongod-arbiter
fi
comments
