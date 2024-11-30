#!/bin/sh

. /koolshare/scripts/base.sh
. /koolshare/scripts/ss_var.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
rm -rf /tmp/upload/dns*.txt
# LOCK_FILE=/var/lock/koolss_dns.lock

selfname="$0"
selfname="${selfname##*/}"
LOCK_FILE="/var/lock/${selfname}.lock"

# set_lock() {
# 	exec 1000>"$LOCK_FILE"
# 	flock -x 1000
# }

# unset_lock() {
# 	flock -u 1000
# 	rm -rf "$LOCK_FILE"
# }

count=0
font_bold() {
	if [ "${web_test}" = "0" ];then
		printf "\e[1m%s\e[0m" "$*"
	else
		printf "%s" "$*"
	fi
}

color_yellow() {
	if [ "${web_test}" = "0" ];then
		printf "\e[35m%s\e[0m" "$*"
	else
		printf "%s" "$*"
	fi
}

color_green() {
	if [ "${web_test}" = "0" ];then
		printf "\e[32m%s\e[0m" "$*"
	else
		printf "%s" "$*"
	fi
}

color_red() {
	if [ "${web_test}" = "0" ];then
		printf "\e[31m%s\e[0m" "$*"
	else
		printf "%s" "$*"
	fi
}

trap 'sigterm' INT # Ctrl-C
trap 'sigterm' QUIT # Ctrl-\
trap 'sigterm' TERM # kill

sigterm(){
	END=$(date +%s)
	summary
	exit 0
}

TARGET_SET=$(ipset -L chnroute)
ENTTRIES=$(ipset -L chnroute| grep "Number of entries"|awk '{print $NF}')

if [ -z "${TARGET_SET}" ] || [ "${ENTTRIES}" = "0" ];then
	echo "创建ipset chnroute"
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
fi


test(){
	START=$(date +%s)
	for line in ${LISTS_FILE}; do
		IP=$(dnsclient -p 53 -t 3 -i 1 @127.0.0.1 "${line}" 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
		#IP=$(nslookup "$line" 127.0.0.1:53 | sed '1,4d' | awk '{print $3}' | grep -v ":" | awk 'NR==1{print}' 2>/dev/null)
		#IP=$(nslookup www.baidu.com 114.114.114.114|grep Address|grep -v "#"|sed 's/Address: //g'|head -n1)
		IP=$(_valid_ip "${IP}")
		
		count=$((count + 1))
		
		if [ -n "${IP}" ]; then
			ipset test chnroute "${IP}" >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 是国外IP
				area="overseas_ip"
			else
				# 是国内ip 
				area="mainland_ip"
			fi
			printf "%s\t%s\t%s!\t%s\n" "${count}" "${IP}" "${area}" "${line}"
		else
			printf "%s\t---------------\t------------\t%s\n" "${count}" "${line}"
		fi
	done
	END=$(date +%s)
	summary
}

summary(){
	echo 
	color_yellow ------------------------------------------------------------------------
	RESOLVED=$(awk '{print $3}' "${RESULT_FILE}" | grep -c "ip")
	FAILED=$((count - RESOLVED))
	OVERSEAS=$(awk '{print $3}' "${RESULT_FILE}" | grep -c "overseas")
	MAINLAND=$(awk '{print $3}' "${RESULT_FILE}" | grep -c "mainland")
	RUNTIME=$((END - START))
	printf "解析总共耗时: \t%s秒\n" "$(color_yellow ${RUNTIME})"
	printf "总共解析域名: \t%s个\n" "$(color_yellow ${count})"
	printf "解析成功个数: \t%s个\n" "$(color_green "${RESOLVED}")"
	printf "解析失败个数: \t%s个\n" "$(color_red "${FAILED}")"
	printf "解析为大陆ip: \t%s个\n" "$(color_green "${MAINLAND}")"
	printf "解析为海外ip: \t%s个\n" "$(color_red "${OVERSEAS}")"
	color_yellow ------------------------------------------------------------------------
}

resolv_test(){
	case $1 in
	1|cdn)
		RESULT_FILE=/tmp/upload/dns_cdn.txt
		LISTS_FILE=$(cat /koolshare/ss/rules/cdn_test.txt)
		;;
	2|apple)
		RESULT_FILE=/tmp/upload/dns_cdn_apple.txt
		LISTS_FILE=$(cat /koolshare/ss/rules/apple_china.txt)
		;;
	3|google)
		RESULT_FILE=/tmp/upload/dns_cdn_google.txt
		LISTS_FILE=$(cat /koolshare/ss/rules/google_china.txt)
		;;
	4|gfw)
		RESULT_FILE=/tmp/upload/dns_gfwlist.txt
		LISTS_FILE=$(sed '/^#/d' /koolshare/ss/rules/gfwlist.conf | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sed '/^ipset=/d' | shuf -n 100)
		;;
	5|china)
		RESULT_FILE=/tmp/upload/dns_cdn_china.txt
		LISTS_FILE=$(shuf -n 100 /koolshare/ss/rules/cdn.txt)
		;;
	esac
	true > "${RESULT_FILE}"
	usleep 100000
	http_response "12344"
	test | tee -a "${RESULT_FILE}"
	echo XU6J03M6 >> "${RESULT_FILE}"
}

detect_dig(){
	if [ -x "/koolshare/bin/dig" ];then
		DIG_BIN=/koolshare/bin/dig
		return
	fi

	if [ -x "/tmp/dig_install/dig" ];then
		DIG_BIN=/tmp/dig_install/dig
		return
	fi
	
	JFFS_AVAIL1=$(df | grep -w "/jffs" | awk '{print $4}')
	JFFS_AVAIL2=$((JFFS_AVAIL1 - 2048))
	JFFS_NEEDED="6108"

	# 情况1：可用空间不足
	if [ "${JFFS_AVAIL1}" -le "${JFFS_NEEDED}" ];then
		# 空间不够的情况下，dig安装到tmp
		if [ ! -x "/tmp/dig_install/dig" ] && [ ! -x "/koolshare/bin/dig" ];then
			echo_date "没有检测到dig二进制文件, 准备下载并安装dig..."
			echo_date "当前jffs分区剩余: ${JFFS_AVAIL1}KB, dig安装至少需要${JFFS_NEEDED}！"
			echo_date "因/jffs分区空间不足，dig将默认安装在/tmp/dig_install目录下"
			install_dig_tmp
		fi
	fi

	# 情况2：预留2MB后，可用空间不足
	if [ "${JFFS_AVAIL1}" -gt "${JFFS_NEEDED}" ] && [ "${JFFS_AVAIL2}" -lt "${JFFS_NEEDED}" ];then
		# 空间不够的情况下，dig安装到tmp
		if [ ! -x "/tmp/dig_install/dig" ] && [ ! -x "/koolshare/bin/dig..." ];then
			echo_date "没有检测到dig二进制文件，准备下载并安装dig"
			echo_date "当前jffs分区剩余：${JFFS_AVAIL1}KB, dig安装至少需要${JFFS_NEEDED}"
			echo_date "为了避免系统服务因使用JFFS分区出现容量问题，还会给jffs预留2MB的空间！"
			echo_date "如果安装dig到/jffs，会导致jffs可用空间小于2MB，因此dig将安装在/tmp/dig_install目录下"
			install_dig_tmp
		fi
	fi
	# 情况3：预留2MB后，可用空间满足
	if [ "${JFFS_AVAIL2}" -gt "${JFFS_NEEDED}" ];then
		# 空间足够的情况下，dig安装到jffs
		if [ ! -x "/tmp/dig_install/dig" ] && [ ! -x "/koolshare/bin/dig"  ];then
			echo_date "没有检测到dig二进制文件，准备下载dig并安装到/koolshare/bin..."
			install_dig_jffs
		fi
	fi
}

download_dig(){
	rm -rf /tmp/dig_download
	mkdir -p /tmp/dig_download
	cd /tmp/dig_download

	echo_date "开始下载校验文件：md5sum.txt"
	wget -4 --no-check-certificate --timeout=20 -qO - https://fw.koolcenter.com/binary/dig/md5sum.txt > /tmp/dig_download/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi

	echo_date "开始下载dig程序"
	wget -4 --no-check-certificate --timeout=20 --tries=1 https://fw.koolcenter.com/binary/dig/dig
	if [ "$?" != "0" ];then
		echo_date "dig下载失败！"
		dig_ok=0
	else
		echo_date "dig程序下载成功..."
		dig_ok=1
	fi

	if [ "${md5sum_ok}" = "1" ] && [ "${dig_ok}" = "1" ];then
		echo_date "校验下载的文件!"
		LOCAL_MD5=$(md5sum dig|awk '{print $1}')
		ONLINE_MD5=$(cat md5sum.txt)
		if [ "${LOCAL_MD5}" = "${ONLINE_MD5}" ];then
			echo_date "文件校验通过!校验值：${LOCAL_MD5}"
		else
			echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
			echo_date "==================================================================="
			echo XU6J03M6
			exit 1
		fi
	else
		echo_date "下载失败，请检查你的网络！"
		echo_date "==================================================================="
		echo XU6J03M6
		exit 1
	fi
}

install_dig_jffs(){
	download_dig
	echo_date "准备安装dig到/koolshare/bin!"
	mv /tmp/dig_download/dig /koolshare/bin/
	chmod +x /koolshare/bin/dig
	echo_date "dig成功安装到/koolshare/bin目录！"
	rm -rf /tmp/dig_download
	DIG_BIN=/koolshare/bin/dig
}

install_dig_tmp(){
	download_dig
	echo_date "准备安装dig到/tmp/dig_install!"
	rm -rf /tmp/dig_install
	mkdir /tmp/dig_install
	mv /tmp/dig_download/dig /tmp/dig_install
	chmod +x /tmp/dig_install/dig
	echo_date "dig临时安装成功！"
	rm -rf /tmp/dig_download
	DIG_BIN=/tmp/dig_install/dig
}

dig_test(){
	# detect dig exist
	detect_dig
	
	# before test, we need to flush dnsmasq cache
	killall -1 dnsmasq
	local domain
	domain="$(dbus get ss_basic_dig_opt)"
	echo "运行命令：dig -4 ${domain}，请稍后..."
	local ret
	ret=$(${DIG_BIN} -4 "${domain}" 2>/dev/null)
	echo "--------------------------------------------------------------------------------------------------"
	echo "${ret}"
	echo "--------------------------------------------------------------------------------------------------"
	local IPS
	IPS=$(echo "${ret}" | grep -Ew "A" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	if [ -n "${IPS}" ];then
		local ECS_TAG
		ECS_TAG=$(echo "${ret}" | grep -E "CLIENT-SUBNET" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
		local RESULT_NU
		RESULT_NU=$(echo "${IPS}" | wc -l)
		if [ -n "${ECS_TAG}" ];then
			echo "ECS支持：yes ✔️"
		else
			echo "ECS支持：no ❌"
		fi
		echo "解析小结：共获得${RESULT_NU}条ipv4解析结果"
		echo "──────────────────────────────"
		echo "IP地址		IP属地"
		echo "──────────────────────────────"
		for IP in ${IPS}
		do
			ipset test chnroute ${IP} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 是国外IP
				area="海外"
				# echo -e ${IP}"\t"海外IP!"\t"${ping_time}
			else
				ping_text=$(ping -4 "$IP" -c 1 -w 1 -q)
				ping_time=$(echo "$ping_text" | grep avg | awk -F '/' '{print $4}')
				if [ -z "$ping_time" ];then
					ping_time="ping failed"
				else
					ping_time="${ping_time}ms"
				fi
				# 是国内IP
				area="国内"
				# echo -e ${IP}"\t"大陆IP!"\t"${ping_time}
			fi
			printf "%s\t%sIP!\t%s\n" "$IP" "$area" "$ping_time"
		done
		echo "──────────────────────────────"
	fi
}

if [ "$#" = "0" ];then
	# bad command
	echo "运行参数错误-1！退出！！"
	exit 1
elif [ "$#" = "1" ];then
	# bad command
	web_test=0
	resolv_test "$1"
elif [ "$#" = "2" ];then
	web_test=1
	if [ "$2" = "6" ];then
		true > /tmp/upload/dns_dig_result.txt
		http_response "12344"
		dig_test >> /tmp/upload/dns_dig_result.txt
		echo XU6J03M6 >> /tmp/upload/dns_dig_result.txt
	else
		resolv_test "$2"
	fi
fi
