#!/bin/sh

if [ -z "$CURR_NODE" ];then
    CURR_NODE=$(dbus get ssconf_basic_node)
fi

get_type_name() {
	case "$1" in
		0)
			echo "ss"
		;;
		1)
			echo "ssr"
		;;
		3)
			echo "V2ray"
		;;
		4)
			echo "xray"
		;;
		5)
			echo "trojan"
		;;
		6)
			echo "NaïveProxy"
		;;
		7)
			echo "tuic"
		;;
		8)
			echo "hysteria2"
		;;
	esac
}

dnsmasq_rule(){
	# better way todo: resolve first and add ip to ipset:router mannuly
	local ACTION
	ACTION="$1"
	local DOMAIN
	DOMAIN="$2"
	local DNSF_PORT
	DNSF_PORT=7913
	local DOMAIN_FILE
	DOMAIN_FILE=/jffs/configs/dnsmasq.d/ss_domain.conf
	if [ "${ACTION}" = "add" ];then
		if [ ! -f "${DOMAIN_FILE}" ] || [ "$(grep -c "${DOMAIN}" "${DOMAIN_FILE}" 2>/dev/null)" != "2" ];then
			echo_date "✅添加域名：${DOMAIN} 到本机走代理名单..."
			rm -rf "${DOMAIN_FILE}"
			echo "server=/${DOMAIN}/127.0.0.1#$DNSF_PORT" >> "${DOMAIN_FILE}"
			echo "ipset=/${DOMAIN}/router" >> "${DOMAIN_FILE}"
			sync
			service restart_dnsmasq >/dev/null 2>&1
		fi
	elif [ "${ACTION}" = "remove" ];then
		if [ -f "${DOMAIN_FILE}" ];then
			rm -rf "${DOMAIN_FILE}"
			sync
			service restart_dnsmasq >/dev/null 2>&1
		fi
	fi
}

go_proxy(){
	# 4. subscribe go through proxy or not
	if [ "$(dbus get ss_basic_online_links_goss)" = "1" ]; then
		if [ "$(get_fancyss_running_status)" = "1" ];then
			echo_date "✈️使用当前$(get_type_name "$(dbus get "ssconf_basic_type_${CURR_NODE}")")节点：[$(dbus get "ssconf_basic_name_${CURR_NODE}")]提供的网络下载..."
			dnsmasq_rule add "${DOMAIN_NAME}"
		else
			echo_date "⚠️当前$(get_type_name "$(dbus get "ssconf_basic_type_${CURR_NODE}")")节点工作异常，改用常规网络下载..."
			dnsmasq_rule remove
		fi
	else
		echo_date "⬇️使用常规网络下载..."
		dnsmasq_rule remove
	fi
}

download_by_curl(){
    local _curl_arg
    _curl_arg="-4sSkL"

    local EXT_ARG
	if [ "$(dbus get ss_basic_online_links_goss)" = "1" ]; then
		SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|naive|tuic")
		if [ -n "${SOCKS5_OPEN}" ];then
            EXT_ARG="-x socks5h://127.0.0.1:23456"
			echo_date "✈️使用当前$(get_type_name "$(dbus get "ssconf_basic_type_${CURR_NODE}")")节点：[$(dbus get "ssconf_basic_name_${CURR_NODE}")]提供的网络下载..."
		else
            EXT_ARG=""
			echo_date "⚠️当前$(get_type_name "$(dbus get "ssconf_basic_type_${CURR_NODE}")")节点工作异常，改用常规网络下载..."
		fi
	else
		echo_date "⬇️使用常规网络下载..."
		dnsmasq_rule remove
	fi

	local url_encode
    url_encode=$(echo "$1" | sed 's/[[:space:]]/%20/g')
    _download_by_curl_output="$2"
    if [ -z "$_download_by_curl_output" ];then 
        _download_by_curl_output="${DIR}/sub_file_encode_${SUB_LINK_HASH_STR}.txt"
    fi
	
	echo_date "1️⃣使用curl下载订阅，第一次尝试下载..."
	run curl-fancyss ${_curl_arg} ${EXT_ARG} --connect-timeout 6 "${url_encode}" 2>/dev/null > "$_download_by_curl_output"
	if [ "$?" = "0" ]; then
		return 0
	fi
	
	echo_date "2️⃣使用curl下载订阅失败，第二次尝试下载..."
	run curl-fancyss ${_curl_arg} ${EXT_ARG} --connect-timeout 10 "${url_encode}" 2>/dev/null > "$_download_by_curl_output"
	if [ "$?" = "0" ]; then
		return 0
	fi

    SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|naive|tuic")
    if [ -n "${SOCKS5_OPEN}" ];then
	    echo_date "3️⃣使用curl下载订阅失败，第三次尝试下载..."
        EXT_ARG="-x socks5h://127.0.0.1:23456"
        echo_date "✈️使用当前$(get_type_name "$(dbus get "ssconf_basic_type_${CURR_NODE}")")节点：[$(dbus get "ssconf_basic_name_${CURR_NODE}")]提供的网络下载..."
        run curl-fancyss ${_curl_arg} ${EXT_ARG} --connect-timeout 12 "${url_encode}" 2>/dev/null > "$_download_by_curl_output"
        if [ "$?" = "0" ]; then
            return 0
        fi	
    fi

	return 1
}


download_by_wget(){
	# if go proxy or not
	go_proxy
	
    local EXT_OPT
    EXT_OPT=""
	if echo "$1" | grep -Eq "^https"; then
        EXT_OPT="--no-check-certificate"
	fi
	
	local url_encode
    url_encode=$(echo "$1" | sed 's/[[:space:]]/%20/g')
    _download_by_wget_output="$2"
    if [ -z "$_download_by_wget_output" ];then
        _download_by_wget_output="${DIR}/sub_file_encode_${SUB_LINK_HASH_STR}.txt"
    fi
	
	echo_date "1️⃣使用wget下载订阅，第一次尝试下载..."
	if wget -4 -t 1 -T 10 --dns-timeout=5 -q ${EXT_OPT} "${url_encode}" -O "$_download_by_wget_output"; then
		return 0
	fi

	echo_date "2️⃣使用wget下载订阅，第二次尝试下载..."
	if wget -4 -t 1 -T 15 --dns-timeout=10 -q ${EXT_OPT} "${url_encode}" -O "$_download_by_wget_output"; then
		return 0
	fi	
	
	echo_date "3️⃣使用wget下载订阅，第三次尝试下载..."
	if wget -4 -t 1 -T 20 --dns-timeout=15 -q ${EXT_OPT} "${url_encode}" -O "$_download_by_wget_output"; then
		return 0
	fi

	return 1
}

download_by_aria2(){
	go_proxy
	echo_date "⬇️使用aria2c下载订阅..."
    _download_by_aria2_output="$2"
    if [ -f "$_download_by_aria2_output" ];then rm -f "$_download_by_aria2_output";fi
	# rm -rf "${DIR}/sub_file_encode_${SUB_LINK_HASH_STR}.txt"
    _download_by_aria2_dir="${_download_by_aria2_output%/*}"
    _download_by_aria2_file="${_download_by_aria2_output##*/}"
	if /koolshare/aria2/aria2c --check-certificate=false --quiet=true -d "$_download_by_aria2_dir" -o "$_download_by_aria2_file" "$1"; then
		return 0
	fi

	return 1
}

_download(){
    _download_url="$1"
    _download_file="$2"

    echo_date "$_download_url"

    if download_by_curl "$_download_url" "$_download_file";then
        echo_date "🆗下载成功，继续检测下载内容..."

		# 404
		if grep -q "404: Not Found" "$_download_file" && [ "$(wc -l < "$_download_file")" = "1" ];then
			echo_date "⚠️解析错误！原因：该链接无法访问，错误代码：404！"
			return 1
		fi

    else
		echo_date "⚠️使用curl下载订阅失败，尝试更换wget进行下载..."
        if [ -f "$_download_file" ];then
			rm -f "$_download_file"
		fi

		#返回错误
		if ! download_by_wget "${_download_url}" "$_download_file";then
			if [ -x "/koolshare/aria2/aria2c" ];then
				
				if ! download_by_aria2 "${_download_url}" "$_download_file"; then
					echo_date "⬇️使用aria2c下载订阅失败！请检查你的网络！"
					return 1
				fi
			else
				echo_date "⚠️更换wget下载订阅失败！"
				return 1
			fi
		fi
    fi

}