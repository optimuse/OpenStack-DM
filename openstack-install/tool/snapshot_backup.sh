#!/bin/bash
##脚本分为两种模式，backup和recovery，backup模式会为所有虚拟机创建当天的快照，recovery模式为恢复指定虚拟机快照，需要把IP和日期传进来,日期格式XXXX-XX-XX
mode=$1
source /root/dont-delete-me/openstack-install/rc/keystone-rc.admin

if [ "$mode" = "backup" ];then
uuids=`nova list --all-tenants  | awk 'NR>2 {print $2}'`
time_str=$(date +"%F")
time_end=$(date +"%F" -d "4 days ago")
for uuid in $uuids
do
	echo vms/${uuid}_disk@${uuid}_${time_str}
#	rbd snap create vms/${uuid}_disk@${uuid}_${time_str}
#	rbd snap protect vms/${uuid}_disk@${uuid}_${time_str}
#	rbd snap unprotect vms/${uuid}_disk@${uuid}_${time_end}
#	rbd snap rm vms/${uuid}_disk@${uuid}_${time_end}
done

elif [ "$mode" = "recovery" ];then
ip=$2
recovery_date=$3

if [ -z $ip ];then
echo "Please input recovery ip "
exit 1
fi

if [ -z $recovery_date ];then
echo "Please input the recovery date of snap"
exit 1
fi

uuid=$(nova list --all-tenants --ip "^$ip$" | grep $ip | awk '{print $2}')
echo vms/${uuid}_disk
#rbd snap unprotect vms/${uuid}_disk
#rbd snap rm vms/${uuid}_disk
#rbd snap mv vms/${uuid}_disk@${uuid}_${recovery_date} vms/${uuid}_disk@${uuid}_recovery_${recovery_date}
#rbd snap clone vms/${uuid}_disk@${uuid}_recovery_${recovery_date} vms/${uuid}_disk
echo 

else 
echo "Please select mode backup/recovery"
exit 1
fi
