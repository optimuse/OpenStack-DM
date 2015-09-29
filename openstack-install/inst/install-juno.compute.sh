#!/bin/bash

SCRIPT_DIR=$(dirname $0)
BASE_DIR=$(cd $SCRIPT_DIR/..; pwd)
source $BASE_DIR/load-environment.sh

##############################

yum install -y http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm
#yum localinstall -y $REPO_BASE/rdo-release-juno.rpm

# Nova (compute)
yum install -y openstack-utils openstack-selinux
yum install -y sysfsutils openstack-nova-compute 
yum install -y kvm libvirt qemu-kvm

#yum install -y libvirt-daemon-driver-nwfilter
#yum install -y libvirt-daemon-config-nwfilter libvirt-daemon-config-network

systemctl enable libvirtd
systemctl start libvirtd

if ! grep -q "^cgroup_device_acl = \[$" /etc/libvirt/qemu.conf; then
sed -i "/^#cgroup_device_acl = \[/,/#\]/s/#//g" /etc/libvirt/qemu.conf
fi

# # Delete the virtual bridge provided by KVM
# virsh net-destroy default
# virsh net-undefine default

sed -i -e "
/#listen_tls/s/#listen_tls/listen_tls/;
/#listen_tcp/s/#listen_tcp/listen_tcp/;
/#auth_tcp/s/#auth_tcp/auth_tcp/;
/auth_tcp/s/sasl/none/;
" /etc/libvirt/libvirtd.conf

sed -i -e "
/#LIBVIRTD_ARGS/c\LIBVIRTD_ARGS=\"--listen\"
" /etc/sysconfig/libvirtd

systemctl enable libvirtd
systemctl restart libvirtd

## load nova.conf
## must enable nova user login on compute node.
usermod -s /bin/bash nova
#chcon system_u:object_r:user_home_t:s0 /var/lib/nova
# DO NOT use chcon -R.

bash $CONF_BASE/juno.nova.conf.sh

systemctl enable libvirtd openstack-nova-compute
systemctl start libvirtd openstack-nova-compute
systemctl restart libvirtd openstack-nova-compute

## If use nova-network's multihost mode, install nova-network on each compute node.
if [[ $USE_MULTIHOST -eq 1 ]]; then
  sh $INST_BASE/install-juno.nova-network.sh
  systemctl enable openstack-nova-metadata-api openstack-nova-network
  systemctl start openstack-nova-metadata-api openstack-nova-network
  systemctl restart openstack-nova-metadata-api openstack-nova-network
fi


yum install -y openstack-ceilometer-compute python-ceilometerclient python-pecan

bash $CONF_BASE/juno.ceilometer.conf.sh

systemctl enable openstack-ceilometer-compute
systemctl start openstack-ceilometer-compute

