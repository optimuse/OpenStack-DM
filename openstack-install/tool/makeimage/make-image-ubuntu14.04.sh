apt-get update
apt-get install -y cloud-init cloud-utils cloud-initramfs-growroot cloud-initramfs-rescuevol

cat <<EOF > /etc/cloud/cloud.cfg.d/90_dpkg.cfg
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, Azure, AltCloud, OVF, MAAS, GCE, Openstack, CloudSigma, Ec2, CloudStack, None ]
EOF


cat <<EOF > /etc/cloud/cloud.cfg
user: root
disable_root: 0
preserve_hostname: False
manage_etc_hosts: False
# datasource_list: ["NoCloud", "ConfigDrive", "OVF", "MAAS", "Ec2", "CloudStack"]

cloud_init_modules:
 - bootcmd
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - ssh

cloud_config_modules:
 - disk-setup
 - mounts
 - ssh-import-id
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-update-upgrade
 - landscape
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd
 - byobu

cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - keys-to-console
 - phone-home
EOF


sed -i "
/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0,115200n8 console=tty1 nomodeset\"
/GRUB_GFXMODE/c\GRUB_GFXMODE=800x600
" /etc/default/grub

update-grub
