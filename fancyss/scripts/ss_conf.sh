#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

. /koolshare/scripts/ss_base.sh
# alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

backup_conf(){
	rm -rf /tmp/files
	rm -rf "/koolshare/webs/files"
	mkdir -p /tmp/files
	ln -sf /tmp/files "/koolshare/webs/files"
	dbus list ss | grep -v "ss_basic_enable" | grep -v "ssid_" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed "1 isource /koolshare/scripts/base.sh" |sed '1 i#!/bin/sh' > "/koolshare/webs/files/ssconf_backup.sh"
}

backup_tar(){
	rm -rf /tmp/files
	rm -rf "/koolshare/webs/files"
	mkdir -p /tmp/files
	ln -sf /tmp/files "/koolshare/webs/files"
	echo_date "开始打包..."
	cd /tmp ||  ( echo_date "目录 /tmp 异常!";exit 1 )
	mkdir "${MODULE}"
	mkdir "${MODULE}"/bin
	mkdir "${MODULE}"/scripts
	mkdir "${MODULE}"/webs
	mkdir "${MODULE}"/res
	echo_date "请等待一会儿..."
	TARGET_FOLDER=/tmp/"${MODULE}"
	cp /"koolshare"/scripts/ss_install.sh $TARGET_FOLDER/install.sh
	cp /"koolshare"/scripts/uninstall_shadowsocks.sh $TARGET_FOLDER/uninstall.sh
	cp /"koolshare"/scripts/ss_* $TARGET_FOLDER/scripts/
	cp /"koolshare"/bin/isutf8 $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/ss-local $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/ss-redir $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/obfs-local $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/rss-local $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/rss-redir $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/dns2socks $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/chinadns-ng $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/resolveip $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/sponge $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/jq $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/xray $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/https_dns_proxy $TARGET_FOLDER/bin/
	cp /"koolshare"/bin/httping $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/ss-tunnel $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/koolgame $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/pdu $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/cdns $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/chinadns $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/chinadns1 $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/smartdns $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/haproxy $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/kcptun $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/speeder* $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/udp2raw $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/trojan $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/v2ray $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/v2ray-plugin $TARGET_FOLDER/bin/
	@cp /"koolshare"/bin/haveged $TARGET_FOLDER/bin/
	#cp /"koolshare"/bin/dnsmasq $TARGET_FOLDER/bin/
	#cp /"koolshare"/bin/v2ctl $TARGET_FOLDER/bin/
	#cp /"koolshare"/bin/client_linux_arm7 $TARGET_FOLDER/bin/
	cp /"koolshare"/webs/Module_shadowsocks*.asp $TARGET_FOLDER/webs/
	cp /"koolshare"/res/accountadd.png $TARGET_FOLDER/res/
	cp /"koolshare"/res/accountdelete.png $TARGET_FOLDER/res/
	cp /"koolshare"/res/accountedit.png $TARGET_FOLDER/res/
	cp /"koolshare"/res/icon-shadowsocks.png $TARGET_FOLDER/res/
	cp /"koolshare"/res/ss-menu.js $TARGET_FOLDER/res/
	cp /"koolshare"/res/tablednd.js $TARGET_FOLDER/res/
	cp /"koolshare"/res/qrcode.js $TARGET_FOLDER/res/
	cp /"koolshare"/res/shadowsocks.css $TARGET_FOLDER/res/
	cp -r /"koolshare"/ss $TARGET_FOLDER/
	rm -rf $TARGET_FOLDER/ss/*.json
	tar -czv -f "/tmp/${MODULE}.tar.gz" "${MODULE}/"
	rm -rf "$TARGET_FOLDER"
	mv "/tmp/${MODULE}.tar.gz" /tmp/files
	echo_date "打包完毕！"
}

remove_now(){
	echo_date 开始清理科学上网配置...
	confs=$(dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign")
	for conf in $confs
	do
		echo_date "移除$conf"
		dbus remove "$conf"
	done
	echo_date "设置一些默认参数..."

	# default values
	echo_date "设置一些默认值..."
	# 1.9.15：国内DNS默认使用运营商DNS
	dbus set ss_basic_enable="0"
	[ -z "$(dbus get ss_dns_china)" ] && dbus set ss_dns_china=1
	# 1.9.15：国外dns解析设置为chinadns-ng，并默认丢掉AAAA记录
	[ -z "$(dbus get ss_dns_foreign)" ] && dbus set ss_dns_foreign=10
	[ -z "$(dbus get ss_disable_aaaa)" ] && dbus set ss_disable_aaaa=1
	# others
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=1
	[ -z "$(dbus get ss_acl_default_port)" ] && dbus set ss_acl_default_port=all
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	dbus set ss_basic_version_local="$(cat /"koolshare"/ss/version) "
	echo_date "尝试关闭科学上网..."
	sh /"koolshare"/ss/ssconfig.sh stop
}

remove_silent(){
	echo_date "先清除已有的参数..."
	confs=$(dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign")
	for conf in $confs
	do
		echo_date "移除$conf"
		dbus remove "$conf"
	done
	echo_date "设置一些默认参数..."
	dbus set ss_basic_version_local="$(cat /"koolshare"/ss/version) "
	echo_date "--------------------"
}

restore_sh(){
	echo_date "检测到科学上网备份文件..."
	echo_date "开始恢复配置..."
	chmod +x /tmp/upload/ssconf_backup.sh
	sh /tmp/upload/ssconf_backup.sh
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local="$(cat /"koolshare"/ss/version)"
	echo_date "配置恢复成功！"
}

restore_json(){
	echo_date "检测到ss json配置文件..."
	ss_format=$(echo "$confs"|grep "obfs")
	jq --tab . /tmp/ssconf_backup.json > /tmp/ssconf_backup_formated.json
	if [ -z "$ss_format" ];then
		# SS json
		echo_date "检测到shadowsocks json配置文件..."
		servers=$(grep -w server /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=$(grep -w server_port /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		passwords=$(grep -w password /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		methods=$(grep -w method /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		remarks=$(grep -w remarks /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=$(dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1)
		if [ ! -z "$last_node" ];then
			k=$((last_node + 1))
		else
			k=1
		fi
		min=1
		max=$(grep -wc server /tmp/ssconf_backup_formated.json)
		while [ "$min" -le "$max" ]
		do
		    echo_date "==============="
		    echo_date import node "$min"
		    echo_date "$k"
		    
		    server=$(echo "$servers" | awk "{print $"$min"}")
			port=$(echo "$ports" | awk "{print $"$min"}")
			password=$(echo "$passwords" | awk "{print $"$min"}")
			method=$(echo "$methods" | awk "{print $"$min"}")
			remark=$(echo "$remarks" | awk "{print $"$min"}")
			
			echo_date "$server"
			echo_date "$port"
			echo_date "$password"
			echo_date "$method"
			echo_date "$remark"
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"="$(echo "$password" | base64_encode)"
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_use_rss_"$k"=0
			dbus set ssconf_basic_mode_"$k"=2
		    min=$((min + 1))
		    k=$((k + 1))
		done
		echo_date "导入配置成功！"
	else
		# SSR json
		echo_date "检测到ssr json配置文件..."
		servers=$(grep -w server /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=$(grep -w server_port /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		passwords=$(grep -w password /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		methods=$(grep -w method /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		remarks=$(grep -w remarks /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		obfs=$(grep -w obfs /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		obfsparam=$(grep -w obfsparam /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		protocol=$(grep -w protocol /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		protocolparam=$(grep -w protocolparam /tmp/ssconf_backup_formated.json|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|sed 's/protocolparam://g')
		
		echo_date "开始导入配置...导入json配置不会覆盖原有配置."
		last_node=$(dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1)
		if [ ! -z "$last_node" ];then
			k=$((last_node + 1))
		else
			k=1
		fi
		min=1
		max=$(grep -wc server /tmp/ssconf_backup_formated.json)
		while [ "$min" -le "$max" ]
		do
		    echo_date "==============="
		    echo_date import node "$min"
		    echo_date "$k"
		    
		    server=$(echo "$servers" | awk "{print $"$min"}")
			port=$(echo "$ports" | awk "{print $"$min"}")
			password=$(echo "$passwords" | awk "{print $"$min"}")
			method=$(echo "$methods" | awk "{print $"$min"}")
			remark=$(echo "$remarks" | awk "{print $"$min"}")
			obf=$(echo "$obfs" | awk "{print $"$min"}")
			obfspara=$(echo "$obfsparam" | awk "{print $"$min"}")
			protoco=$(echo "$protocol" | awk "{print $"$min"}")
			protocolpara=$(echo "$protocolparam" | awk "{print $"$min"}")
			
			echo_date "$server"
			echo_date "$port"
			echo_date "$password"
			echo_date "$method"
			echo_date "$remark"
			echo_date "$obf"
			echo_date "$obfspara"
			echo_date "$protoco"
			echo_date "$protocolpara"
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"="$(echo "$password" | base64_encode)"
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_rss_obfs_"$k"="$obf"
			dbus set ssconf_basic_rss_obfs_param_"$k"="$obfspara"
			dbus set ssconf_basic_rss_protocol_"$k"="$protoco"
			dbus set ssconf_basic_rss_protocol_para_"$k"="$protocolpara"
			dbus set ssconf_basic_use_rss_"$k"=1
			dbus set ssconf_basic_mode_"$k"=2
		    min=$((min + 1))
		    k=$((k + 1))
		done
		echo_date "导入配置成功！"
	fi
}

restore_now(){
	[ -f "/tmp/upload/ssconf_backup.sh" ] && restore_sh
	[ -f "/tmp/upload/ssconf_backup.json" ] && restore_json
	echo_date "一点点清理工作..."
	rm -rf /tmp/ss_conf_*
	echo_date "完成！"
}

reomve_ping(){
	# flush previous ping value in the table
	pings=$(dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1)
	if [ -n "$pings" ];then
		for ping in $pings
		do
			echo "remove $ping"
			dbus remove "$ping"
		done
	fi
}

download_ssf(){
	rm -rf /tmp/files
	rm -rf /"koolshare"/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /"koolshare"/webs/files
	if [ -f "/tmp/upload/ssf_status.txt" ];then
		cp -rf /tmp/upload/ssf_status.txt /tmp/files/ssf_status.txt
	else
		echo "日志为空" > /tmp/files/ssf_status.txt
	fi
}

download_ssc(){
	rm -rf /tmp/files
	rm -rf /"koolshare"/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /"koolshare"/webs/files
	if [ -f "/tmp/upload/ssc_status.txt" ];then
		cp -rf /tmp/upload/ssc_status.txt /tmp/files/ssc_status.txt
	else
		echo "日志为空" > /tmp/files/ssc_status.txt
	fi
}

restart_dnsmasq(){
	echo_date "重启dnsmasq..."
	local OLD_PID="$(pidof dnsmasq)"
	if [ -n "${OLD_PID}" ];then
		echo_date "当前dnsmasq正常运行中，pid: ${OLD_PID}，准备重启！"
	else
		echo_date "当前dnsmasq未运行，尝试重启！"
	fi
	
	service restart_dnsmasq >/dev/null 2>&1

	local DPID
	local i=50
	until [ -n "${DPID}" ]; do
		i=$((i - 1))
		DPID="$(pidof dnsmasq)"
		if [ "$i" -lt "1" ]; then
			echo_date "dnsmasq重启失败，请检查你的dnsmasq配置！"
		fi
		usleep 250000
	done
	echo_date "dnsmasq重启成功，pid: ${DPID}"
}

case $2 in
1)
	true > /tmp/upload/ss_log.txt
	backup_conf
	http_response "$1"
	;;
2)
	true > /tmp/upload/ss_log.txt
	backup_tar >> /tmp/upload/ss_log.txt
	sleep 1
	http_response "$1"
	sleep 2	
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
3)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
4)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_silent >> /tmp/upload/ss_log.txt
	restore_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
5)
	reomve_ping
	;;
6)
	true > /tmp/upload/ss_log.txt
	download_ssf
	http_response "$1"
	;;
7)
	true > /tmp/upload/ss_log.txt
	download_ssc
	http_response "$1"
	;;
8)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	restart_dnsmasq >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac
