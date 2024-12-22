#!/usr/bin/env bash

MODULE=planesocks
VERSION=$(sed -n 1p ./fancyss/ss/version)
TITLE="科学上网"
DESCRIPTION="科学上网"
HOME_URL=Module_${MODULE}.asp
CURR_PATH="$(cd "$(dirname "$0")"; pwd)"

cp_rules(){
	cp -rf "${CURR_PATH}/rules/gfwlist.conf" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/chnroute.txt" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/cdn.txt" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/cdn_test.txt" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/apple_china.txt" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/google_china.txt" "${CURR_PATH}/fancyss/ss/rules/"
	cp -rf "${CURR_PATH}/rules/rules.json.js" "${CURR_PATH}/fancyss/ss/rules/rules.json.js"
}

sync_binary(){
	BINS_REMOVE="v2ray-plugin kcptun"
	for BIN_REMOVE in $BINS_REMOVE;
	do
		echo ">>> remove old bin $BIN_REMOVE"
		rm -rf "${CURR_PATH}/fancyss/bin-mtk/${BIN_REMOVE}"
		rm -rf "${CURR_PATH}/fancyss/bin-hnd_v8/${BIN_REMOVE}"
		rm -rf "${CURR_PATH}/fancyss/bin-hnd/${BIN_REMOVE}"
		rm -rf "${CURR_PATH}/fancyss/bin-qca/${BIN_REMOVE}"
		rm -rf "${CURR_PATH}/fancyss/bin-arm/${BIN_REMOVE}"
	done
	
	BINS_COPY="v2ray xray naive ss_rust hysteria2"
	for BIN in $BINS_COPY;
	do
		local VERSION_FLAG
		VERSION_FLAG="latest.txt"
		if [ "${BIN}" == "v2ray" ];then
			VERSION_FLAG="latest_v5.txt"
		fi

		if [ "${BIN}" == "xray" ];then
			VERSION_FLAG="latest_2.txt"
		fi
		
		local REAL_BIN
		if [ "${BIN}" == "ss_rust" ];then
			REAL_BIN="sslocal"
		else
			REAL_BIN="${BIN}"
		fi
	
		local version
		version="$(cat "${CURR_PATH}/binaries/${BIN}/${VERSION_FLAG}")"
		echo ">>> start to copy latest ${BIN}, version: ${version}"
		cp -rf "${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_arm64" "${CURR_PATH}/fancyss/bin-mtk/${REAL_BIN}"
		cp -rf "${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_arm64" "${CURR_PATH}/fancyss/bin-hnd_v8/${REAL_BIN}"
		cp -rf "${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv7" "${CURR_PATH}/fancyss/bin-hnd/${REAL_BIN}"
		cp -rf "${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv7" "${CURR_PATH}/fancyss/bin-qca/${REAL_BIN}"
		cp -rf "${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv5" "${CURR_PATH}/fancyss/bin-arm/${REAL_BIN}"
	done
}

gen_folder(){
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	cd "${CURR_PATH}"
	rm -rf planesocks
	cp -rf fancyss planesocks

	# different platform	
	if [ "${platform}" == "hnd" ];then
		rm -rf ./planesocks/bin-arm
		rm -rf ./planesocks/bin-hnd_v8
		rm -rf ./planesocks/bin-qca
		rm -rf ./planesocks/bin-mtk
		mv ./planesocks/bin-hnd ./planesocks/bin
		rm -rf ./planesocks/bin/uredir
		rm -rf ./planesocks/ss/websocket_arm
		rm -rf ./planesocks/ss/websocket_mtk
		rm -rf ./planesocks/ss/websocket_qca
		mv ./planesocks/ss/websocket_hnd ./planesocks/ss/websocket
		echo hnd > ./planesocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	if [ "${platform}" == "hnd_v8" ];then
		rm -rf ./planesocks/bin-arm
		rm -rf ./planesocks/bin-hnd
		rm -rf ./planesocks/bin-qca
		rm -rf ./planesocks/bin-mtk
		mv ./planesocks/bin-hnd_v8 ./planesocks/bin
		rm -rf ./planesocks/bin/uredir
		rm -rf ./planesocks/ss/websocket_arm
		rm -rf ./planesocks/ss/websocket_mtk
		rm -rf ./planesocks/ss/websocket_qca
		mv ./planesocks/ss/websocket_hnd ./planesocks/ss/websocket
		echo hnd_v8 > ./planesocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd_v8\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	if [ "${platform}" == "qca" ];then
		rm -rf ./planesocks/bin-arm
		rm -rf ./planesocks/bin-hnd
		rm -rf ./planesocks/bin-hnd_v8
		rm -rf ./planesocks/bin-mtk
		mv ./planesocks/bin-qca ./planesocks/bin
		rm -rf ./planesocks/bin/uredir
		rm -rf ./planesocks/ss/websocket_arm
		rm -rf ./planesocks/ss/websocket_mtk
		rm -rf ./planesocks/ss/websocket_hnd
		mv ./planesocks/ss/websocket_qca ./planesocks/ss/websocket
		echo qca > ./planesocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"qca\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	if [ "${platform}" == "arm" ];then
		rm -rf ./planesocks/bin-hnd
		rm -rf ./planesocks/bin-hnd_v8
		rm -rf ./planesocks/bin-qca
		rm -rf ./planesocks/bin-mtk
		mv ./planesocks/bin-arm ./planesocks/bin
		rm -rf ./planesocks/ss/websocket_qca
		rm -rf ./planesocks/ss/websocket_mtk
		rm -rf ./planesocks/ss/websocket_hnd
		mv ./planesocks/ss/websocket_arm ./planesocks/ss/websocket
		echo arm > ./planesocks/.valid
		sed -i '/fancyss-hnd/d' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_mcore\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_tfo\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"arm\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	if [ "${platform}" == "mtk" ];then
		rm -rf ./planesocks/bin-arm
		rm -rf ./planesocks/bin-hnd
		rm -rf ./planesocks/bin-hnd_v8
		rm -rf ./planesocks/bin-qca
		mv ./planesocks/bin-mtk ./planesocks/bin
		rm -rf ./planesocks/bin/uredir
		rm -rf ./planesocks/ss/websocket_arm
		rm -rf ./planesocks/ss/websocket_qca
		rm -rf ./planesocks/ss/websocket_hnd
		mv ./planesocks/ss/websocket_mtk ./planesocks/ss/websocket
		rm -rf ./planesocks/bin/README.md
		echo mtk > ./planesocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"mtk\"/g' ./planesocks/webs/Module_planesocks.asp
	fi

	# remove some binary because it's not default provide by install packages
	find ./planesocks/bin -name "speederv1" -exec rm -rf {} +
	find ./planesocks/bin -name "speederv2" -exec rm -rf {} +
	find ./planesocks/bin -name "udp2raw" -exec rm -rf {} +
	find ./planesocks/bin -name "tuic-client" -exec rm -rf {} +

	# wirte type string
	if [ "${release_type}" != "debug" ];then
		sed -i 's/PKG_EXTA=\"_debug\"/PKG_EXTA=\"\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	if [ "${pkgtype}" == "lite" ];then
		sed -i 's/var PKG_TYPE=\"full\"/var PKG_TYPE=\"lite\"/g' ./planesocks/webs/Module_planesocks.asp
	fi
	
	# if [ "${pkgtype}" == "lite" -a "${platform}" == "hnd" ];then
	# 	# for small jffs router: RT-AX56U_V2 and RT-AX57, use smaller version of XRAY 1.8.3
	# 	cp ./binaries/xray/v1.8.3/xray_armv7 ./planesocks/bin/xray
	# fi

	
	if [ "${pkgtype}" == "full" ];then
		# remove marked comment
		# rm -rf ./planesocks/bin/sslocal
		sed -i 's/#@//g' ./planesocks/scripts/ss_proc_status.sh
		sed -i 's/#@//g' ./planesocks/scripts/ss_conf.sh
		echo ".show-btn5, .show-btn6{display: inline; !important}" >> ./planesocks/res/fancyss.css
	elif [ "${pkgtype}" == "lite" ];then
		# remove binaries
		rm -rf ./planesocks/bin/sslocal
		rm -rf ./planesocks/bin/v2ray
		rm -rf ./planesocks/bin/speederv1
		rm -rf ./planesocks/bin/speederv2
		rm -rf ./planesocks/bin/udp2raw
		rm -rf ./planesocks/bin/naive
		rm -rf ./planesocks/bin/tuic-client
		rm -rf ./planesocks/bin/ipt2socks
		rm -rf ./planesocks/bin/haveged
		rm -rf ./planesocks/bin/hysteria2

		if [ "${platform}" == "hnd" ];then
			rm -rf ./planesocks/bin/websocketd
		fi
		# remove scripts
		rm -rf ./planesocks/scripts/ss_v2ray.sh
		rm -rf ./planesocks/scripts/ss_rust_update.sh
		rm -rf ./planesocks/scripts/ss_udp_status.sh
		# remove rules
		rm -rf ./planesocks/ss/rules/chn.acl
		rm -rf ./planesocks/ss/rules/gfwlist.acl
		# remove line
		sed -i '/fancyss-full/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/fancyss-full/d' ./planesocks/res/ss-menu.js
		sed -i '/fancyss-dns/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/naiveproxy/d' ./planesocks/res/ss-menu.js
		sed -i '/naiveproxy/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/tuic/d' ./planesocks/res/ss-menu.js
		# remove options from shadowsocks-rust: shadowsocks2022 encryption method
		sed -i 's/\,\s\"2022-blake3-aes-128-gcm\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"2022-blake3-aes-256-gcm\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"2022-blake3-chacha20-poly1305\"//g' ./planesocks/webs/Module_planesocks.asp
		# remove lines bewteen matchs
		sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/fancyss_naive_1/,/fancyss_naive_2/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/fancyss_tuic_1/,/fancyss_tuic_2/d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/fancyss_hy2_1/,/fancyss_hy2_2/d' ./planesocks/webs/Module_planesocks.asp
		# remove strings from page
		sed -i 's/\,\s\"naive_prot\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_prot\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_server\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_port\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_user\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_pass\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"naive_json\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"tuic_json\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_vcore\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_tcore\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_rust\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_on\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_on\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_v2ray\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_v2ray_opts\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"use_kcp\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_server\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_port\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_parameter\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_method\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_password\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_encrypt\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mtu\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_rcvwnd\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_conn\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_extra\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_software\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_node\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_password\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_mode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_nu\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_time\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_jitter\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_report\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_drop\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_password\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_fec\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_timeout\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_report\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mtu\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_jitter\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_interval\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_drop\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_other\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rserver\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rport\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_password\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rawmode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_ciphermode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_authmode\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lowerlevel\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_other\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu_value\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_nocomp\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp_boost_enable\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_disable_filter\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disableobscure\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disablechecksum\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_boost_enable\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_a\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_keeprule\"//g' ./planesocks/webs/Module_planesocks.asp
		# hysteria2
		sed -i 's/\,\s\"ss_basic_hy2_up_speed\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_hy2_dl_speed\"//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\,\s\"ss_basic_hy2_tfo_switch\"//g' ./planesocks/webs/Module_planesocks.asp
		# modify words
		# trojan 用xray运行，所以trojan多核心功能删除
		sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/八种客户端/五种客户端/g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/科学上网工具/科学上网、游戏加速工具/g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/14\.286/20/g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/\s\&\&\s\!\snaive_on//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/八种客户端/五种客户端/g' ./planesocks/res/ss-menu.js
		sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./planesocks/res/ss-menu.js
		sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./planesocks/res/ss-menu.js
	fi

	if [ "${release_type}" == "release" ];then
		# 移除注释
		# remove match words: //fancyss-full //fancyss-full_1 //fancyss-full_2
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./planesocks/res/ss-menu.js

		# remove match words: <!--fancyss-full-->
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./planesocks/webs/Module_planesocks.asp
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./planesocks/res/ss-menu.js

		# remove line contain: <!--fancyss_full_1--> <!--fancyss_full_1-->
		sed -i 's/[ \t]*<!--fancyss_full_[1-2]-->//g' ./planesocks/webs/Module_planesocks.asp
		
		# remove line start of: //
		sed -i '/^[ \t]*\/\//d' ./planesocks/webs/Module_planesocks.asp
		sed -i '/^[ \t]*\/\//d' ./planesocks/res/ss-menu.js

		# remove line <!-- ?? -->
		sed -i 's/<!--.*-->//g' ./planesocks/webs/Module_planesocks.asp

		# remove empty line
		sed -i '/^[[:space:]]*$/d' ./planesocks/webs/Module_planesocks.asp
	fi

	# when develop in other branch
	# master/fancyss_hnd
	# local CURRENT_BRANCH=$(git branch | head -n1 |awk '{print $2}')
	# if [ "${CURRENT_BRANCH}" != "master" ];then
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./planesocks/webs/Module_planesocks.asp
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./planesocks/res/ss-menu.js
	# fi
}

build_pkg() {
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	# different platform
	if [ "${release_type}" == "release" ];then
		echo "打包：fancyss_${platform}_${pkgtype}.tar.gz"
		tar -zcf "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz" planesocks >/dev/null
		md5value=$(md5sum "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz" | awk '{print $1}')
		cat >> "${CURR_PATH}/packages/version_tmp.json.js" <<-EOF
			,"md5_${platform}_${pkgtype}":"${md5value}"
		EOF
	elif [ "${release_type}" == "debug" ];then
		echo "打包：fancyss_${platform}_${pkgtype}_${release_type}.tar.gz"
		tar -zcf "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}_${release_type}.tar.gz" planesocks >/dev/null
	fi
}

do_backup(){
	mkdir -p "${CURR_PATH}/../fancyss_history_package"
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	if [ "${release_type}" == "release" ];then
		cd ${CURR_PATH}
		HISTORY_DIR="${CURR_PATH}/../fancyss_history_package/fancyss_${platform}"
		mkdir -p "${HISTORY_DIR}"
		# backup latested package after pack
		local backup_version=${VERSION}
		local backup_tar_md5=${md5value}
		
		echo "备份：fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
		cp "${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz" "${HISTORY_DIR}/fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
		sed -i "/fancyss_${platform}_${pkgtype}_${backup_version}/d" "${HISTORY_DIR}/md5sum.txt"
		if [ ! -f "${HISTORY_DIR}/md5sum.txt" ];then
			touch "${HISTORY_DIR}/md5sum.txt"
		fi
		echo "${backup_tar_md5} fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz" >> "${HISTORY_DIR}/md5sum.txt"
	fi
}

papare(){
	rm -f "${CURR_PATH}"/packages/*
	cp_rules
	sync_binary
	cat > "${CURR_PATH}/packages/version_tmp.json.js" <<-EOF
	{
	"name":"fancyss"
	,"version":"${VERSION}"
	EOF
}

finish(){
	echo "}" >> "${CURR_PATH}/packages/version_tmp.json.js"
	jq '.' "${CURR_PATH}/packages/version_tmp.json.js" > "${CURR_PATH}/packages/version.json.js"
	rm -rf "${CURR_PATH}/packages/version_tmp.json.js"
	echo "完成！生成的离线安装包在：${CURR_PATH}/packages"
}

pack(){
	gen_folder $1 $2 $3
	build_pkg $1 $2 $3
	if [ "$3" == "release" ];then
		do_backup  $1 $2 $3
	fi
	rm -rf "${CURR_PATH}/planesocks/"
}

make(){
	papare
	# --- for release ---
	pack hnd full release
	pack hnd lite release
	pack hnd_v8 full release
	pack hnd_v8 lite release
	pack hnd lite release
	pack qca full release
	pack qca lite release
	pack arm full release
	pack arm lite release
	pack mtk full release
	pack mtk lite release
	# --- for debug ---
	pack hnd full debug
	pack hnd_v8 full debug
	pack qca full debug
	pack arm full debug
	pack mtk full debug
	finish
}

make
