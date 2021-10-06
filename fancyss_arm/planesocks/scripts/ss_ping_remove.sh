#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

# 引用环境变量等
source "/koolshare/scripts/ss_common.sh"

# flush previous ping value in the table
pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ -n "$pings" ];then
	for ping in $pings
	do
		dbus remove "$ping"
	done
fi



