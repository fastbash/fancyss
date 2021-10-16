#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

source "/koolshare/scripts/ss_common.sh"
source helper.sh


case $ACTION in
start)
	set_lock
	if [ "$ss_basic_enable" == "1" ];then
		logger "[软件中心]: 启动科学上网插件！"
		set_ulimit >> "$LOG_FILE"
		apply_ss >> "$LOG_FILE"
		write_numbers >> "$LOG_FILE"
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
stop)
	set_lock
	ss_pre_stop
	disable_ss
	echo_date
	echo_date 你已经成功关闭planesocks服务~
	echo_date See you again!
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
restart)
	set_lock
	set_ulimit
	apply_ss
	write_numbers
	echo_date
	echo_date "Across the Great Wall we can reach every corner in the world!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
flush_nat)
	set_lock
	flush_nat
	unset_lock
	;;
*)
	set_lock
	if [ "$ss_basic_enable" == "1" ];then
		set_ulimit
		apply_ss
		write_numbers
	fi
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
esac
