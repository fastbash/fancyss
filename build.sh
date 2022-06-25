#!/usr/bin/env bash

. ./fancyss/scripts/ss_var.sh

VERSION=$(cat ./fancyss/ss/version|sed -n 1p)
TITLE="科学上网"
DESCRIPTION="科学上网"
HOME_URL="Module_${MODULE}.asp"
CURR_PATH="$( cd "$( dirname "$0" )" && pwd )"

cp_rules(){
	cp -rf "${CURR_PATH}"/rules/gfwlist.conf "${CURR_PATH}"/fancyss/ss/rules/
	cp -rf "${CURR_PATH}"/rules/chnroute.txt "${CURR_PATH}"/fancyss/ss/rules/
	cp -rf "${CURR_PATH}"/rules/cdn.txt "${CURR_PATH}"/fancyss/ss/rules/
	cp -rf "${CURR_PATH}"/rules/cdn_test.txt "${CURR_PATH}"/fancyss/ss/rules/
	cp -rf "${CURR_PATH}"/rules/rules.json "${CURR_PATH}"/fancyss/ss/rules/rules.json
}

sync_binary(){
	# hnd & qca (RT-AC86U, TUF-AX3000, RT-AX86U, GT-AX6000, RT-AX89X ...)
	local v2ray_version=$(cat "${CURR_PATH}"/binaries/v2ray/latest.txt)
	local xray_version=$(cat "${CURR_PATH}"/binaries/xray/latest.txt)
	cp -rf "${CURR_PATH}"/binaries/v2ray/${v2ray_version}/v2ray_armv7 "${CURR_PATH}"/fancyss/bin-hnd/v2ray
	cp -rf "${CURR_PATH}"/binaries/v2ray/${v2ray_version}/v2ray_armv7 "${CURR_PATH}"/fancyss/bin-qca/v2ray
	cp -rf "${CURR_PATH}"/binaries/v2ray/${v2ray_version}/v2ray_armv5 "${CURR_PATH}"/fancyss/bin-arm/v2ray
	cp -rf "${CURR_PATH}"/binaries/xray/${xray_version}/xray_armv7 "${CURR_PATH}"/fancyss/bin-hnd/xray
	cp -rf "${CURR_PATH}"/binaries/xray/${xray_version}/xray_armv7 "${CURR_PATH}"/fancyss/bin-qca/xray
	cp -rf "${CURR_PATH}"/binaries/xray/${xray_version}/xray_armv5 "${CURR_PATH}"/fancyss/bin-arm/xray
}

gen_folder(){
	local platform=$1
	local pkgtype=$2
	cd "${CURR_PATH}"
	rm -rf "${MODULE}"
	cp -rf fancyss "${MODULE}"

	# different platform
	if [ "${platform}" == "hnd" ];then
		rm -rf ./"${MODULE}"/bin-hnd_v8
		rm -rf ./"${MODULE}"/bin-arm
		rm -rf ./"${MODULE}"/bin-qca
		mv "${MODULE}"/bin-hnd ./"${MODULE}"/bin
		echo hnd > ./"${MODULE}"/.valid
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_hnd_full/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_hnd_lite/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
	fi
	if [ "${platform}" == "qca" ];then
		rm -rf ./"${MODULE}"/bin-hnd_v8
		rm -rf ./"${MODULE}"/bin-arm
		rm -rf ./"${MODULE}"/bin-hnd
		mv "${MODULE}"/bin-qca ./"${MODULE}"/bin
		echo qca > ./"${MODULE}"/.valid
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_qca_full/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_qca_lite/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
	fi
	if [ "${platform}" == "arm" ];then
		rm -rf ./"${MODULE}"/bin-hnd_v8
		rm -rf ./"${MODULE}"/bin-hnd
		rm -rf ./"${MODULE}"/bin-qca
		mv "${MODULE}"/bin-arm ./"${MODULE}"/bin
		echo arm > ./"${MODULE}"/.valid
		echo arm384 >> ./"${MODULE}"/.valid
		echo arm386 >> ./"${MODULE}"/.valid
		sed -i '/fancyss-hnd/d' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_mcore\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_tfo\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_arm_full/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_arm_lite/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
	fi
	
	if [ "${MODULE}" != "shadowsocks" ];then
		sed -i "s#Module_shadowsocks#Module_${MODULE}#g" ./"${MODULE}"/res/ss-menu.js
		if [ -f "./fancyss/res/icon-shadowsocks.png" ] && [ ! -f "./fancyss/res/icon-${MODULE}.png" ];then
			\cp "./fancyss/res/icon-shadowsocks.png" "./fancyss/res/icon-${MODULE}.png"
		fi
	fi

	if [ "${pkgtype}" == "full" ];then
		# remove tag mark
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./"${MODULE}"/res/ss-menu.js
		sed -i 's/[ \t]*\/\/fancyss-koolgame//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		# remove comment
		sed -i 's/#@//g' ./"${MODULE}"/scripts/ss_proc_status.sh
		# modify asp page
		sed -i 's/科学上网插件\s\-\sFull/科学上网插件/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
	fi

	if [ "${pkgtype}" == "lite" ];then
		# remove binaries
		rm -rf ./"${MODULE}"/bin/v2ray
		rm -rf ./"${MODULE}"/bin/v2ray-plugin
		rm -rf ./"${MODULE}"/bin/kcptun
		rm -rf ./"${MODULE}"/bin/trojan
		rm -rf ./"${MODULE}"/bin/ss-tunnel
		rm -rf ./"${MODULE}"/bin/trojan
		rm -rf ./"${MODULE}"/bin/koolgame
		rm -rf ./"${MODULE}"/bin/pdu
		rm -rf ./"${MODULE}"/bin/speederv1
		rm -rf ./"${MODULE}"/bin/speederv2
		rm -rf ./"${MODULE}"/bin/udp2raw
		rm -rf ./"${MODULE}"/bin/haproxy
		rm -rf ./"${MODULE}"/bin/smartdns
		rm -rf ./"${MODULE}"/bin/cdns
		rm -rf ./"${MODULE}"/bin/chinadns
		rm -rf ./"${MODULE}"/bin/chinadns1
		rm -rf ./"${MODULE}"/bin/smartdns
		rm -rf ./"${MODULE}"/bin/haveged
		# remove scripts
		rm -rf ./"${MODULE}"/scripts/ss_lb_config.sh
		rm -rf ./"${MODULE}"/scripts/ss_v2ray.sh
		rm -rf ./"${MODULE}"/scripts/ss_rust_update.sh
		rm -rf ./"${MODULE}"/scripts/ss_socks5.sh
		rm -rf ./"${MODULE}"/scripts/ss_udp_status.sh
		# remove rules
		rm -rf ./"${MODULE}"/ss/rules/chn.acl
		rm -rf ./"${MODULE}"/ss/rules/gfwlist.acl
		rm -rf ./"${MODULE}"/ss/rules/cdns.json
		rm -rf ./"${MODULE}"/ss/rules/smartdns_template.conf
		# remove pages
		rm -rf ./"${MODULE}"/webs/Module_${MODULE}_lb.asp
		rm -rf ./"${MODULE}"/webs/Module_${MODULE}_local.asp
		# remove line
		sed -i '/fancyss-full/d' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i '/fancyss-full/d' ./"${MODULE}"/res/ss-menu.js
		sed -i '/fancyss-koolgame/d' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i '/#@/d' ./"${MODULE}"/scripts/ss_proc_status.sh
		sed -i '/#@/d' ./"${MODULE}"/scripts/ss_conf.sh
		sed -i '/koolgame/d' ./"${MODULE}"/res/ss-menu.js
		# remove lines
		sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i '/fancyss_koolgame_1/,/fancyss_koolgame_2/d' ./"${MODULE}"/webs/Module_${MODULE}.asp
		# remove dns option
		sed -i 's/\, \[\"1\"\, \"cdns\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \[\"2\"\, \"chinadns2\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \[\"4\"\, \"ss-tunnel\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \[\"5\"\, \"chinadns1\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \[\"9\"\, \"SmartDNS\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \[\"13\"\, \"SmartDNS\"\]//' ./"${MODULE}"/webs/Module_${MODULE}.asp
		# remove strings from page
		sed -i 's/\,\s\"ss_basic_vcore\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_tcore\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_rust\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_v2ray\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_v2ray_opts\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"use_kcp\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_lport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_server\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_port\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_parameter\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_method\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_password\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_mode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_encrypt\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_mtu\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_rcvwnd\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_conn\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_extra\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp_software\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp_node\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_password\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_mode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_nu\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_time\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_jitter\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_report\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_drop\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_password\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_fec\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_timeout\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_report\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mtu\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_jitter\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_interval\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_drop\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_other\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rserver\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rport\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_password\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rawmode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_ciphermode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_authmode\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lowerlevel\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_other\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu_value\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_kcp_nocomp\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp_boost_enable\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv1_disable_filter\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disableobscure\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disablechecksum\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_boost_enable\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_a\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_keeprule\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"koolgame_udp\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/ || koolgame_on//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_game2_dns_foreign\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\,\s\"ss_game2_dns2ss_user\"//g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/\, \"负载均衡设置\"//g' ./"${MODULE}"/res/ss-menu.js
		sed -i 's/\, \"Socks5设置\"//g' ./"${MODULE}"/res/ss-menu.js
		# sed -i 's/\, \"Module_shadowsocks_lb\.asp\"//g' ./"${MODULE}"/res/ss-menu.js
		# sed -i 's/\, \"Module_shadowsocks_local\.asp\"//g' ./"${MODULE}"/res/ss-menu.js
		sed -i "/Module_${MODULE}_lb.asp/d" ./"${MODULE}"/res/ss-menu.js
		sed -i "/Module_${MODULE}_local.asp/d" ./"${MODULE}"/res/ss-menu.js
		# modify words
		sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/六种客户端/五种客户端/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/16\.67/20/g' ./"${MODULE}"/webs/Module_${MODULE}.asp
		sed -i 's/六种客户端/五种客户端/g' ./"${MODULE}"/res/ss-menu.js
		sed -i 's/ss\/ssr\/koolgame\/v2ray/ss\/ssr\/v2ray/g' ./"${MODULE}"/res/ss-menu.js
		sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./"${MODULE}"/res/ss-menu.js
		sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./"${MODULE}"/res/ss-menu.js
		# add css
		echo ".show-btn5, .show-btn6{display: none; !important}" >> ./"${MODULE}"/res/shadowsocks.css
	fi
	
	# remove all comment line from page
	sed -i '/^[ \t]*\/\//d' ./"${MODULE}"/webs/Module_${MODULE}.asp
	sed -i '/^[ \t]*\/\//d' ./"${MODULE}"/res/ss-menu.js

	# when develop in other branch
	# master/fancyss_hnd
	# local CURRENT_BRANCH=$(git branch | head -n1 |awk '{print $2}')
	# if [ "${CURRENT_BRANCH}" != "master" ];then
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./"${MODULE}"/webs/Module_shadowsocks.asp
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./"${MODULE}"/res/ss-menu.js
	# fi
}

build_pkg() {
	local platform=$1
	local pkgtype=$2
	# different platform
	echo "打包：fancyss_${platform}_${pkgtype}.tar.gz"
	tar -zcf "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz" "${MODULE}" >/dev/null
	md5value=$(md5sum "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz"|tr " " "\n"|sed -n 1p)
	cat >>"${CURR_PATH}/packages/version_tmp.json.js" <<-EOF
		,"md5_${platform}_${pkgtype}":"${md5value}"
	EOF
}

do_backup(){
	local platform=$1
	local pkgtype=$2
	cd "${CURR_PATH}"
	HISTORY_DIR="${CURR_PATH}/../fancyss_history_package/fancyss_${platform}"
	if [ ! -d "${HISTORY_DIR}" ];then mkdir -p "${HISTORY_DIR}";fi
	# backup latested package after pack
	local backup_version="${VERSION}"
	local backup_tar_md5="${md5value}"
	
	echo "备份：fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
	cp "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz" "${HISTORY_DIR}/fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
	sed -i "/fancyss_${platform}_${pkgtype}_${backup_version}/d" "${HISTORY_DIR}/md5sum.txt"
	if [ ! -f "${HISTORY_DIR}/md5sum.txt" ];then
		touch "${HISTORY_DIR}/md5sum.txt"
	fi
	echo "${backup_tar_md5} fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz" >> "${HISTORY_DIR}/md5sum.txt"
	cat "${CURR_PATH}/README.md" > "${CURR_PATH}/../fancyss_history_package/README.md"
}

papare(){
	rm -f "${CURR_PATH}"/packages/*
	cp_rules
	sync_binary
	cat >"${CURR_PATH}/packages/version_tmp.json.js" <<-EOF
	{
	"name":"fancyss"
	,"version":"${VERSION}"
	EOF
}
finish(){
	echo "}" >>"${CURR_PATH}/packages/version_tmp.json.js"
	jq . ${CURR_PATH}/packages/version_tmp.json.js > ${CURR_PATH}/packages/version.json.js
	rm -rf "${CURR_PATH}/packages/version_tmp.json.js"
}


pack(){
	gen_folder "$1" "$2"
	build_pkg "$1" "$2"
	do_backup "$1" "$2"
	rm -rf "${CURR_PATH}"/"${MODULE}"/
}

make(){
	papare
	pack hnd full
	pack hnd lite
	pack qca full
	pack qca lite
	pack arm full
	pack arm lite
	finish
}


make

