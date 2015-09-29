nova list --all-tenants | grep -vi 'wvss' | grep -v 'SHUTOFF' | awk -F'|' '{print $7}' | awk -F';' '{print $1}' | awk -F= '{print $2}' | awk -F',' '{print $1}'   > /tmp/ip.list

