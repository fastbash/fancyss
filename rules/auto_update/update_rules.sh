#!/bin/bash
CurrentDate=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
CURR_PATH="$(cd "$(dirname "$0")"; pwd)"
RULE_PATH=${CURR_PATH%\/*}
RULE_FILE=${RULE_PATH}/rules.json.js
OBJECT_1='{}'

# iprange https://github.com/firehol/iprange

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
	cd "${CURR_PATH}"
}

get_gfwlist(){
	# gfwlist.conf

	# 1. download
	chmod +x "${CURR_PATH}/fwlist.py"
	"${CURR_PATH}/fwlist.py" gfwlist_1.txt >/dev/null 2>&1
	if [ ! -f "gfwlist_1.txt" ]; then
		echo "gfwlist download faild!"
		exit 1
	fi

	curl -4sk https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt > "${CURR_PATH}/gfwlist_2.txt"

	# merge list
	cat "${CURR_PATH}/gfwlist_1.txt" "${CURR_PATH}/gfwlist_2.txt" "${CURR_PATH}/gfwlist_ext.txt" "${CURR_PATH}/../../../proxy_list.txt" | sed 's#^full:##g' | grep -v '#' | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sort -u > "${CURR_PATH}/gfwlist_merge.txt"

	# modify
	sed -i '/hasi\./d' "${CURR_PATH}/gfwlist_merge.txt"

	# 2. merge
	sed "s/^/server=&\/./g" "${CURR_PATH}/gfwlist_merge.txt" | sed "s/$/\/127.0.0.1#7913/g" >"${CURR_PATH}/gfwlist_merge.conf"
	sed "s/^/ipset=&\/./g" "${CURR_PATH}/gfwlist_merge.txt" | sed "s/$/\/gfwlist/g" >> "${CURR_PATH}/gfwlist_merge.conf"

	# 3. sort
	sort -k 2 -t. -u "${CURR_PATH}/gfwlist_merge.conf" > "${CURR_PATH}/gfwlist_tmp.conf"
	
	# 4. post filter: delete site below
	sed -i '/m-team/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/windowsupdate/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/v2ex/d' "${CURR_PATH}/gfwlist_tmp.conf"
	sed -i '/apple\.com/d' "${CURR_PATH}/gfwlist_tmp.conf"

	# 5. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/gfwlist_tmp.conf" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/gfwlist.conf" | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "gfwlist same md5!"
		return
	fi

	# 6. update file
	echo "update gfwlist!"
	mv -f "${CURR_PATH}/gfwlist_tmp.conf" "${RULE_PATH}/gfwlist.conf"

	# 7. write json
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(grep -Ec "^server=" "${RULE_PATH}/gfwlist.conf")
	jq --arg variable "${CURR_DATE}" '.gfwlist.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.gfwlist.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.gfwlist.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_function(){
	# chnroute
	_pre="$1"
	# misakaio
	dst_name_short="$2"
	# chnroute_misakaio
	dst_name="${_pre}_${dst_name_short}"

	# https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt
	raw_url="$3"

	# https://github.com/misakaio/chnroutes2/blob/master/chnroutes.txt
	if [ -n "$4" ];then
		_url="$4"
	else
		_url="$raw_url"
	fi

	if [ "$raw_url" != "0" ];then
		curl -4sk "$raw_url" > "${CURR_PATH}/${dst_name}_tmp.txt"
	fi

	if [ ! -f "${dst_name}_tmp.txt" ]; then
		echo "${dst_name} download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' "${CURR_PATH}/${dst_name}_tmp.txt"

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/${dst_name}_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/${dst_name}.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/${dst_name}.txt")
		echo "${dst_name} same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="${dst_name_short}"
	local URL="$_url"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/${dst_name}_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/${dst_name}_tmp.txt")
	jq --arg variable "${SOURCE}" ".${dst_name}.source = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" ".${dst_name}.url = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" ".${dst_name}.date = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" ".${dst_name}.md5 = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" ".${dst_name}.count = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" ".${dst_name}.count_ip = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update ${_pre} from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/${dst_name}_tmp.txt" "${RULE_PATH}/${dst_name}.txt"
}

get_chnroute_misakaio(){
	# chnroute.txt from misakaio
	# 项目地址：https://github.com/misakaio/chnroutes2
	# 详情：This project uses BGP feed from various sources to provide more accurate and up-to-date CN routes.

	curl -4sk https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt > "${CURR_PATH}/chnroute_misakaio_tmp.txt"

	if [ ! -f "chnroute_misakaio_tmp.txt" ]; then
		echo "chnroute_misakaio download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_misakaio_tmp.txt

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_misakaio_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute_misakaio.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute_misakaio.txt")
		echo "chnroute_misakaio same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="misakaio"
	local URL="https://github.com/misakaio/chnroutes2/blob/master/chnroutes.txt"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_misakaio_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_misakaio_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute_misakaio.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute_misakaio.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute_misakaio.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute_misakaio.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute_misakaio.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute_misakaio.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_misakaio_tmp.txt" "${RULE_PATH}/chnroute_misakaio.txt"
}

get_chnroute_cnisp(){
	# 项目地址：https://github.com/gaoyifan/china-operator-ip
	# 详情：依据中国网络运营商分类的IP地址库

	curl -4sk https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt > "${CURR_PATH}/chnroute_cnisp_tmp.txt"

	if [ ! -f "chnroute_cnisp_tmp.txt" ]; then
		echo "chnroute_cnisp download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_cnisp_tmp.txt

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_cnisp_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute_cnisp.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute_cnisp.txt")
		echo "chnroute_cnisp same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="cnisp"
	local URL="https://github.com/gaoyifan/china-operator-ip"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_cnisp_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_cnisp_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute_cnisp.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute_cnisp.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute_cnisp.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute_cnisp.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute_cnisp.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute_cnisp.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_cnisp_tmp.txt" "${RULE_PATH}/chnroute_cnisp.txt"
}

get_chnroute_apnic(){
	# chnroute_apnic.txt

	curl -4sk http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > "${CURR_PATH}/chnroute_apnic_tmp.txt"
	
	if [ ! -f "chnroute_apnic_tmp.txt" ]; then
		echo "chnroute_apnic download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_apnic_tmp.txt

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_apnic_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute_apnic.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute_apnic.txt")
		echo "chnroute_apnic same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="apnic"
	local URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_apnic_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_apnic_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute_apnic.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute_apnic.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute_apnic.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute_apnic.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute_apnic.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute_apnic.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_apnic_tmp.txt" "${RULE_PATH}/chnroute_apnic.txt"
}

get_chnroute_17mon(){
	# chnroute_17mon.txt from 17mon
	# 项目地址：https://github.com/17mon/china_ip_list
	# ip来源：IPList for China by IPIP.NET

	curl -4s https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt > "${CURR_PATH}/chnroute_17mon_tmp.txt"

	if [ ! -f "chnroute_17mon_tmp.txt" ]; then
		echo "chnroute_17mon download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_17mon_tmp.txt

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_17mon_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute_17mon.txt 2>/dev/null" | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute_17mon.txt")
		echo "chnroute_17mon same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="17mon/ipip"
	local URL="https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_17mon_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_17mon_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute_17mon.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute_17mon.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute_17mon.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute_17mon.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute_17mon.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute_17mon.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_17mon_tmp.txt" "${RULE_PATH}/chnroute_17mon.txt"
}

get_chnroute_ipip(){
	# chnroute_ipip.txt from ipip
	# source: firehol/blocklist-ipsets

	curl -4sk https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset > "${CURR_PATH}/chnroute_ipip_tmp.txt"

	if [ ! -f "chnroute_ipip_tmp.txt" ]; then
		echo "chnroute_ipip download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_ipip_tmp.txt

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_ipip_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute_ipip.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute_ipip.txt")
		echo "chnroute_ipip same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="ipip.net"
	local URL="https://github.com/firehol/blocklist-ipsets/blob/master/ipip_country/ipip_country_cn.netset"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_ipip_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_ipip_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute_ipip.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute_ipip.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute_ipip.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute_ipip.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute_ipip.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute_ipip.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_ipip_tmp.txt" "${RULE_PATH}/chnroute_ipip.txt"
}

get_chnroute_maxmind(){
	# chnroute_maxmind.txt from maxmind
	# source: firehol/blocklist-ipsets

	curl -4sk https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/geolite2_country/country_cn.netset >${CURR_PATH}/chnroute_maxmind_tmp.txt

	if [ ! -f "chnroute_maxmind_tmp.txt" ]; then
		echo "chnroute_maxmind download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_maxmind_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_maxmind_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_maxmind.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_maxmind.txt)
		echo "chnroute_maxmind same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="maxmind/geolite2"
	local URL="https://github.com/firehol/blocklist-ipsets/blob/master/geolite2_country/country_cn.netset"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_maxmind_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_maxmind_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_maxmind.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_maxmind.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_maxmind.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_maxmind.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_maxmind.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_maxmind.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_maxmind_tmp.txt ${RULE_PATH}/chnroute_maxmind.txt
}

gen_chnroute_fancyss(){
	# 1. merge rules
	cat "${RULE_PATH}"/{chnroute_misakaio.txt,chnroute_cnisp.txt,chnroute_apnic.txt,chnroute_17mon.txt,chnroute_ipip.txt,chnroute_maxmind.txt} | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | iprange > "${CURR_PATH}/chnroute_tmp.txt"
	sed -i '1i192.168.0.0/16\n172.16.0.0/16\n10.0.0.0/8' "${CURR_PATH}/chnroute_tmp.txt"

	# 2. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/chnroute_tmp.txt" 2>/dev/null | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/chnroute.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT
		_IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${RULE_PATH}/chnroute.txt")
		echo "chnroute same md5! total $_IP_COUNT ips!"
		return
	fi

	# 3. write json
	local SOURCE
	SOURCE="fancyss"
	local URL
	URL="https://github.com/fastbash/fancyss/tree/3.0/rules"
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE
	MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${CURR_PATH}/chnroute_tmp.txt")
	local IP_COUNT
	IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' "${CURR_PATH}/chnroute_tmp.txt")
	jq --arg variable "${SOURCE}" '.chnroute.source = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${URL}" '.chnroute.url = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${CURR_DATE}" '.chnroute.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.chnroute.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.chnroute.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${IP_COUNT}" '.chnroute.count_ip = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"

	# 4. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f "${CURR_PATH}/chnroute_tmp.txt" "${RULE_PATH}/chnroute.txt"
}

get_cdn(){
	# cdn.txt

	# 1.download
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf > "${CURR_PATH}/accelerated-domains.china.conf"
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf > "${CURR_PATH}/apple.china.conf"
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf > "${CURR_PATH}/google.china.conf"
	if [ ! -f "accelerated-domains.china.conf" ] || [ ! -f "apple.china.conf" ] || [ ! -f "google.china.conf" ]; then
		echo "cdn download faild!"
		exit 1
	fi
	
	# 2.merge
	cat "${CURR_PATH}"/{accelerated-domains.china.conf,apple.china.conf,google.china.conf} "${CURR_PATH}/../../../no_proxy_list.txt" | sed 's#^full:##g' | sed '/#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" > "${CURR_PATH}/cdn_download.txt"
	cat "${CURR_PATH}"/{cdn_koolcenter.txt,cdn_download.txt} | sort -u > "${CURR_PATH}/cdn_tmp.txt"

	# 3. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/cdn_tmp.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/cdn.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn list same md5!"
		return
	fi
	
	# 4. update file
	echo "update cdn!"
	mv -f "${CURR_PATH}/cdn_tmp.txt" "${RULE_PATH}/cdn.txt"

	# 5. write json
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${RULE_PATH}/cdn.txt")
	jq --arg variable "${CURR_DATE}" '.cdn_china.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.cdn_china.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.cdn_china.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_file(){
	# apple.china.conf
	raw_file="$1"
	# apple_download.txt
	tmp_file="$2"
	# apple_china
	dst_file="$3"

	# 1. get domain
	if [ "$raw_file" != "0" ];then
		sed '/^#/d' "${CURR_PATH}/${raw_file}" | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > "${CURR_PATH}/${tmp_file}"
	fi

	# 2. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/${tmp_file}" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/${dst_file}.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "${dst_file} list same md5!"
		return
	fi

	# 3. update file
	echo "update ${dst_file} list!"
	mv -f "${CURR_PATH}/${tmp_file}" "${RULE_PATH}/${dst_file}.txt"

	# 4. write json
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${RULE_PATH}/${dst_file}.txt")
	jq --arg variable "${CURR_DATE}" ".${dst_file}.date = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" ".${dst_file}.md5 = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" ".${dst_file}.count = \$variable" "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_apple(){
	# 1. get domain
	sed '/^#/d' "${CURR_PATH}/apple.china.conf" | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > "${CURR_PATH}/apple_download.txt"

	# 2. compare
	local md5sum1
	md5sum1=$(md5sum "${CURR_PATH}/apple_download.txt" | awk '{print $1}')
	local md5sum2
	md5sum2=$(md5sum "${RULE_PATH}/apple_china.txt" 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "apple china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update apple china list!"
	mv -f "${CURR_PATH}/apple_download.txt" "${RULE_PATH}/apple_china.txt"

	# 4. write json
	local CURR_DATE
	CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN
	LINE_COUN=$(wc -l < "${RULE_PATH}/apple_china.txt")
	jq --arg variable "${CURR_DATE}" '.apple_china.date = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${MD5_VALUE}" '.apple_china.md5 = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
	jq --arg variable "${LINE_COUN}" '.apple_china.count = $variable' "${RULE_FILE}" | sponge "${RULE_FILE}"
}

get_google(){
	# 1. get domain
	cat google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >${CURR_PATH}/google_download.txt

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/google_download.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/google_china.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "google china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update google china list!"
	mv -f ${CURR_PATH}/google_download.txt ${RULE_PATH}/google_china.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/google_china.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.google_china.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.google_china.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.google_china.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}

get_cdntest(){
	# 1. get domain
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt > "${CURR_PATH}/cdn_test.txt"

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/cdn_test.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/cdn_test.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn test list same md5!"
		return
	fi
	
	# 3. update file
	echo "update cdn test list!"
	mv -f ${CURR_PATH}/cdn_test.txt ${RULE_PATH}/cdn_test.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/cdn_test.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.cdn_test.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.cdn_test.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.cdn_test.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}


finish(){
	list="gfwlist_tmp.conf gfwlist_merge.conf gfwlist_merge.txt gfwlist_1.txt gfwlist_2.txt gfwlist_ext.txt chnroute_tmp.txt chnroute_ipip_tmp.txt chnroute_apnic_tmp.txt chnroute_misakaio_tmp.txt chnroute_17mon_tmp.txt chnroute_maxmind_tmp.txt chnroute_cnisp_tmp.txt cdn_tmp.txt accelerated-domains.china.conf cdn_download.txt apple.china.conf apple_download.txt google.china.conf google_download.txt cdn_test.txt cdn_test.txt"
	for file in $list;do
		rm -f "${CURR_PATH}/${file}"
	done
	echo "---------------------------------"
}

clear_chnroute(){
	# find ${RULE_PATH} -maxdepth 1 -name "*chnroute*"|xargs -I {} sh -c "echo \"\" > '{}'"
	find "${RULE_PATH}" -maxdepth 1 -name "*chnroute*" -exec sh -c 'echo "" > "$1"' _ {} \;
	for val in cdn.txt gfwlist.conf google_china.txt apple_china.txt cdn_test.txt;do
		echo "" > "${RULE_PATH}/$val"
	done
}

get_rules(){
	prepare
	get_gfwlist
	# get_chnroute_misakaio
	# This project uses BGP feed from various sources to provide more accurate and up-to-date CN routes.
	get_function "chnroute" "misakaio" "https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt" "https://github.com/misakaio/chnroutes2/blob/master/chnroutes.txt"
	# get_chnroute_cnisp
	# 依据中国网络运营商分类的IP地址库
	get_function "chnroute" "cnisp" "https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt" "https://github.com/gaoyifan/china-operator-ip"
	# get_chnroute_apnic
	curl -4sk http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > "${CURR_PATH}/chnroute_apnic_tmp.txt"
	get_function "chnroute" "apnic" "0" "http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
	# get_chnroute_17mon
	# IPList for China by IPIP.NET
	get_function "chnroute" "17mon" "https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt" "https://github.com/17mon/china_ip_list"
	# get_chnroute_ipip
	# firehol/blocklist-ipsets
	get_function "chnroute" "ipip" "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset" "https://github.com/firehol/blocklist-ipsets/blob/master/ipip_country/ipip_country_cn.netset"
	# get_chnroute_maxmind
	# firehol/blocklist-ipsets
	get_function "chnroute" "maxmind" "https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/geolite2_country/country_cn.netset" "https://github.com/firehol/blocklist-ipsets/blob/master/geolite2_country/country_cn.netset"
	gen_chnroute_fancyss 
	get_cdn
	# get_apple
	get_file "apple.china.conf" "apple_download.txt" "apple_china"
	# get_google
	get_file "google.china.conf" "google_download.txt" "google_china"
	# get_cdntest
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt > "${CURR_PATH}/cdn_test.txt"
	get_file "0" "cdn_test.txt" "cdn_test"
	cat "${RULE_FILE}" > "${RULE_FILE%.*}"
	finish
}

case $1 in
update)
	get_rules
	;;
clear)
	clear_chnroute
	;;
esac