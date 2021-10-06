#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

# 引用环境变量等
source "/koolshare/scripts/ss_common.sh"

echo_date 开始清理planesocks配置...
confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
for conf in $confs
do
	echo_date 移除$conf
	dbus remove $conf
done
echo_date 设置一些默认参数...
dbus set ss_basic_enable="0"
dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
echo_date 尝试关闭planesocks...
sh /koolshare/ss/ssconfig.sh stop
