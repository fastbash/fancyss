#!/bin/bash
# CurrentDate=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
CURR_PATH="$( cd "$( dirname "$0" )" && pwd )"
RULE_PATH="${CURR_PATH%\/*}"
RULE_FILE="${RULE_PATH}/rules.json"
# OBJECT_1='{}'

prepare(){
	if ! type -p sponge &>/dev/null; then
		if which yum >/dev/null 2>&1;then
			yum install moreutils -y >/dev/null 2>&1
		elif which apt >/dv/null 2>&1;then
			apt install moreutils -y >/dev/null 2>&1
		else
	    	printf '%s\n' "error: sponge is not installed, exiting..."
		fi
	    if ! type -p sponge &>/dev/null; then exit 1;fi
	fi
}

get_gfwlist(){
	echo "---------------------------------get_gfwlist"
	# gfwlist.conf

	# 1. download
	"${CURR_PATH}/fwlist.py" "${CURR_PATH}/gfwlist_download.conf" >/dev/null 2>&1
	if [ ! -f "${CURR_PATH}/gfwlist_download.conf" ]; then
		echo "gfwlist download faild!"
		exit 1
	fi

	# 2. merge
	cat "${CURR_PATH}/gfwlist_download.conf" "${CURR_PATH}/gfwlist_fancyss.conf" "${CURR_PATH}/../../../proxy_list.txt" | sed 's#^full:##g' | grep -v '#' | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >"${CURR_PATH}/gfwlist_merge.conf"
	cat "${CURR_PATH}/gfwlist_download.conf" "${CURR_PATH}/gfwlist_fancyss.conf" "${CURR_PATH}/../../../proxy_list.txt" | sed 's#^full:##g' | grep -v '#' | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/gfwlist/g" >>"${CURR_PATH}/gfwlist_merge.conf"

	# 3. sort
	sort -k 2 -t. -u "${CURR_PATH}/gfwlist_merge.conf" > "${CURR_PATH}/gfwlist_tmp.conf"
	
	# 4. post filter: delete site below
	sed -i '/m-team/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/windowsupdate/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/v2ex/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/apple\.com/d' "${CURR_PATH}/gfwlist_tmp.conf"

	# 5. compare
	md5sum1=$(md5sum "${CURR_PATH}/gfwlist_tmp.conf" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/gfwlist.conf" | awk '{print $1}')
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "gfwlist same md5!"
		return
	fi

	# 6. update file
	echo "update gfwlist!"
	cat "${CURR_PATH}/gfwlist_tmp.conf" > "${RULE_PATH}/gfwlist.conf"

    # 7. write json
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(grep -Ec "^server=" "${RULE_PATH}/gfwlist.conf")
	jq --arg variable "${CURR_DATE}" '.gfwlist.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.gfwlist.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.gfwlist.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_chnroute(){
	echo "---------------------------------get_chnroute"
	# chnroute.txt

	# 1. download
	# source-1：ipip, 20220604: total 6182 subnets, 13240665434 unique IPs
	# wget https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset -qO "${CURR_PATH}/chnroute_tmp.txt"

	# source-2：misakaio, 20220604: total 3403 subnets, 298382954 unique IPs
	URL="https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt"

	# source-3: mayaxcn, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt -qO ${CURR_PATH}/chnroute_tmp.txt

	# source-4: clang, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget https://ispip.clang.cn/all_cn.txt -qO ${CURR_PATH}/chnroute_tmp.txt
	
	# source-5：apnic, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -qO ${CURR_PATH}/apnic.txt
	# cat apnic.txt| awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ${CURR_PATH}/chnroute_tmp.txt
	# rm -rf ${CURR_PATH}/apnic.txt

	wget "$URL" -qO "${CURR_PATH}/chnroute1_tmp.txt"
	
	if [ ! -f "${CURR_PATH}/chnroute1_tmp.txt" ]; then
		echo "chnroute download faild!"
		exit 1
	fi

	# 2. process
	sed '/^#/d' "${CURR_PATH}/chnroute1_tmp.txt" "${RULE_PATH}/chnroute2.txt" "${RULE_PATH}/chnroute3.txt" | sort -u > "${CURR_PATH}/chnroute_tmp.txt"

	# 3. compare
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_tmp.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/chnroute.txt" 2>/dev/null | awk '{print $1}')
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute same md5!"
		return
	fi

	# 5. update file
	# echo "update chnroute, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	cat "${CURR_PATH}/chnroute_tmp.txt" > "${RULE_PATH}/chnroute.txt"
	sed -i '1i192.168.0.0/24;1i172.16.0.0/16;1i10.0.0.0/8' "${RULE_PATH}/chnroute.txt"

	# 4. write json
	# SOURCE_="misakaio"
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_tmp.txt")
	IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' "${CURR_PATH}/chnroute_tmp.txt")
	# jq --arg variable "${SOURCE}" '.chnroute.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	# jq --arg variable "${URL}" '.chnroute.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_chnroute2(){
	# chnroute2.txt from misakaio

	# source-2：ipip, 20220604: total 6182 subnets, 13240665434 unique IPs
	URL="https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset"

	wget -4 "$URL" -qO "${CURR_PATH}/chnroute2_2_tmp.txt"

	if [ ! -f "${CURR_PATH}/chnroute2_2_tmp.txt" ]; then
		echo "chnroute2 download faild!"
		exit 1
	fi

	# source-3: mayaxcn, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt -qO ${CURR_PATH}/chnroute3_tmp.txt
	URL="https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt"

	wget -4 "$URL" -qO "${CURR_PATH}/chnroute2_3_tmp.txt"

	if [ ! -f "${CURR_PATH}/chnroute2_3_tmp.txt" ]; then
		echo "chnroute2.3 download faild!"
		exit 1
	fi

	# 2. process
	sed '/^#/d' "${CURR_PATH}/chnroute2_2_tmp.txt" "${CURR_PATH}/chnroute2_3_tmp.txt" | sort -u > "${CURR_PATH}/chnroute2_tmp.txt"

	# 3. compare
	md5sum1=$(md5sum "${CURR_PATH}/chnroute2_tmp.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/chnroute2.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute2 same md5!"
		return
	fi

	# 4. write json
	SOURCE="misakaio_mayaxcn"
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute2_tmp.txt")
	IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' "${CURR_PATH}/chnroute2_tmp.txt")
	# jq --arg variable "${SOURCE}" '.chnroute2.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	# jq --arg variable "${URL}" '.chnroute2.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute2.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute2.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute2.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute2.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	# echo "update chnroute2, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	cat "${CURR_PATH}/chnroute2_tmp.txt" > "${RULE_PATH}/chnroute2.txt"
}

get_chnroute3(){
	# chnroute3.txt

	# source-4: clang, 20220604: total 8625 subnets, 343364510 unique IPs
	URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"

	wget -4 "$URL" -qO "${CURR_PATH}/chnroute3_4_tmp.txt"

	if [ ! -f "${CURR_PATH}/chnroute3_4_tmp.txt" ]; then
		echo "chnroute3 download faild!"
		exit 1
	fi

	# source-5：apnic, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -qO ${CURR_PATH}/apnic.txt
	# cat apnic.txt| awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ${CURR_PATH}/chnroute3_tmp.txt
	# rm -rf ${CURR_PATH}/apnic.txt
	URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"

	wget -4 "$URL" -qO "${CURR_PATH}/chnroute3_5_tmp.txt"

	if [ ! -f "${CURR_PATH}/chnroute3_5_tmp.txt" ]; then
		echo "chnroute3 download faild!"
		exit 1
	fi


	# 2. process
	awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' "${CURR_PATH}/chnroute3_4_tmp.txt" "${CURR_PATH}/chnroute3_5_tmp.txt" | sed '/^$/d' | sort -u > "${CURR_PATH}/chnroute3_tmp.txt"

	# 3. compare
	md5sum1=$(md5sum "${CURR_PATH}/chnroute3_tmp.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/chnroute3.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute3 same md5!"
		return
	fi

	# 4. write json
	# SOURCE="apnic"
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute3_tmp.txt")
	IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' "${CURR_PATH}/chnroute3_tmp.txt")
	# jq --arg variable "${SOURCE}" '.chnroute3.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	# jq --arg variable "${URL}" '.chnroute3.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute3.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute3.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute3.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute3.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	# echo "update chnroute3, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	cat "${CURR_PATH}/chnroute3_tmp.txt" > "${RULE_PATH}/chnroute3.txt"
}

get_cdn(){
	echo "---------------------------------get_cdn"
	# cdn.txt

	# 1.download
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf -qO "${CURR_PATH}/accelerated-domains.china.conf"
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf -qO "${CURR_PATH}/apple.china.conf"
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf -qO "${CURR_PATH}/google.china.conf"
	if [ ! -f "${CURR_PATH}/accelerated-domains.china.conf" ] || [ ! -f "${CURR_PATH}/apple.china.conf" ] || [ ! -f "${CURR_PATH}/google.china.conf" ]; then
		echo "cdn download faild!"
		exit 1
	fi
	
	# 2.merge
	cat "${CURR_PATH}"/{accelerated-domains.china.conf,apple.china.conf,google.china.conf} "${CURR_PATH}/../../../no_proxy_list.txt" | sed 's#^full:##g' | sed '/#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" > "${CURR_PATH}/cdn_download.txt"
	cat "${CURR_PATH}/cdn_koolcenter.txt" "${CURR_PATH}/cdn_download.txt" | sort -u > "${CURR_PATH}/cdn_tmp.txt"

	# 3. compare
	md5sum1=$(md5sum "${CURR_PATH}/cdn_tmp.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/cdn.txt" 2>/dev/null | awk '{print $1}')
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn list same md5!"
		return
	fi
	
	# 4. update file
	echo "update cdn!"
	cat "${CURR_PATH}/cdn_tmp.txt" > "${RULE_PATH}/cdn.txt"

	# 5. write json
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${RULE_PATH}/cdn.txt")
	jq --arg variable "${CURR_DATE}" '.cdn_china.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.cdn_china.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.cdn_china.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_apple(){
	echo "---------------------------------get_apple"
	# 1. get domain
	sed '/^#/d' "${CURR_PATH}/apple.china.conf" | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > "${CURR_PATH}/apple_download.txt"

	# 2. compare
	md5sum1=$(md5sum "${CURR_PATH}/apple_download.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/apple_china.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "apple china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update apple china list!"
	cat "${CURR_PATH}/apple_download.txt" > "${RULE_PATH}/apple_china.txt"

	# 4. write json
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${RULE_PATH}/apple_china.txt")
	jq --arg variable "${CURR_DATE}" '.apple_china.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.apple_china.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.apple_china.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_google(){
	echo "---------------------------------get_google"
	# 1. get domain
	sed '/^#/d' "${CURR_PATH}/google.china.conf" | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >"${CURR_PATH}/google_download.txt"

	# 2. compare
	md5sum1=$(md5sum "${CURR_PATH}/google_download.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/google_china.txt" 2>/dev/null | awk '{print $1}')
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "google china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update google china list!"
	cat "${CURR_PATH}/google_download.txt" > "${RULE_PATH}/google_china.txt"

	# 4. write json
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${RULE_PATH}/google_china.txt")
	jq --arg variable "${CURR_DATE}" '.google_china.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.google_china.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.google_china.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_cdntest(){
	echo "---------------------------------get_cdntest"
	# 1. get domain
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt -qO "${CURR_PATH}/cdn_test.txt"

	# 2. compare
	md5sum1=$(md5sum "${CURR_PATH}/cdn_test.txt" | awk '{print $1}')
	md5sum2=$(md5sum "${RULE_PATH}/cdn_test.txt" 2>/dev/null | awk '{print $1}')
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn test list same md5!"
		return
	fi
	
	# 3. update file
	echo "update cdn test list!"
	cat "${CURR_PATH}/cdn_test.txt" > "${RULE_PATH}/cdn_test.txt"

	# 4. write json
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	MD5_VALUE="${md5sum1}"
	LINE_COUN=$(wc -l < "${RULE_PATH}/cdn_test.txt")
	jq --arg variable "${CURR_DATE}" '.cdn_test.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.cdn_test.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.cdn_test.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}


finish(){
	rm -f "${CURR_PATH}/gfwlist_tmp.conf"
	rm -f "${CURR_PATH}/gfwlist_merge.conf"
	rm -f "${CURR_PATH}/gfwlist_download.conf"
	rm -f "${CURR_PATH}/chnroute*.txt"
	rm -f "${CURR_PATH}/cdn_tmp.txt"
	rm -f "${CURR_PATH}/accelerated-domains.china.conf"
	rm -f "${CURR_PATH}/cdn_download.txt"
	rm -f "${CURR_PATH}/apple.china.conf"
	rm -f "${CURR_PATH}/apple_download.txt"
	rm -f "${CURR_PATH}/google.china.conf"
	rm -f "${CURR_PATH}/google_download.txt"
	rm -f "${CURR_PATH}/cdn_test.txt"
	echo "---------------------------------"
}

get_rules(){
	prepare
	get_gfwlist
	get_chnroute2
	get_chnroute3
	get_chnroute
	get_cdn
	get_apple
	get_google
	get_cdntest
	finish
}

get_rules
