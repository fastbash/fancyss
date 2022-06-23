#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

# 此脚本用以存放一些公用的变量


# MODULE=shadowsocks
KSROOT=koolshare
MODULE=planesocks
github_user="hq450"
github_user="fastbash"
github_url="https://raw.githubusercontent.com/${github_user}"
update_url="${github_url}/fancyss/3.0/packages"
rust_url="${github_url}/fancyss/3.0/binaries/ss_rust"
rule_url="${github_url}/fancyss/3.0/rules"
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'



set_skin(){
	UI_TYPE=ASUSWRT
	SC_SKIN="$(nvram get sc_skin)"
	ROG_FLAG="$(grep -o "680516" /www/form_style.css|head -n1)"
	TUF_FLAG="$(grep -o "D0982C" /www/form_style.css|head -n1)"
	if [ -n "${ROG_FLAG}" ] || grep -q 'rgb(62,3,13)' /www/form_style.css;then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	
	if [ -z "${SC_SKIN}" ] || [ "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}