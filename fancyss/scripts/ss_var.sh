#!/bin/sh

MODULE=planesocks


set_lock(){
    # 获取脚本名称
    local _self_name
	_self_name="${1##*/}"
    if [ -z "$_self_name" ]; then
        _self_name="${0##*/}"
    fi

    # 设置默认锁文件路径
    if [ -z "$LOCK_FILE" ]; then
        LOCK_FILE="/var/lock/${_self_name}.lock"
    fi

	# echo_date "当前锁文件路径 $LOCK_FILE"

	# 原锁机制
	# exec 8>"$LOCK_FILE"
	# flock -n 8 || {
	# 	echo_date "已存在执行任务，请勿重复执行..."
	# 	exit 0
	# }

    # 检查并尝试创建锁
    if [ -f "${LOCK_FILE}" ]; then
        # 锁已存在，检查其有效性
        local PID
        PID=$(cat "${LOCK_FILE}" 2>/dev/null)
		# echo_date "锁文件 $LOCK_FILE:$PID 存在"
		# echo_date "$(ps | grep -v grep | grep "$_self_name")"
		# echo_date "$(cat "$LOCK_FILE")"

        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            # echo_date "$_self_name 已经在运行（PID: $PID），请稍候再试！"
			echo_date "已存在执行任务，请勿重复执行..."
			exit 1
        else
            # echo_date "锁文件 $LOCK_FILE:$PID 无效，清理..."
            rm -f "${LOCK_FILE:?}"
        fi
    fi

	if [ ! -f "$LOCK_FILE" ];then
		PID=$$
		# 创建成功，记录当前进程 PID
		# echo_date "记录当前 PID:$PID 到锁文件 $LOCK_FILE "
		echo "$PID" > "${LOCK_FILE}"
	fi
}

unset_lock(){
	# echo_date "计时，避免脚本结束"
	# sleep 120

	# 原锁机制
	# flock -u 8

	rm -f "${LOCK_FILE:?}"
}

run(){
	env -i PATH="${PATH}" "$@"
}

__md5_file(){
    md5sum "$1" | awk '{print $1}' 2>/dev/null
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

__valid_ip() {
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4
	format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$")
	local format_6
	format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')

	if [ -n "${format_4}" ] && [ -z "${format_6}" ]; then
		echo "${format_4}"
		return 0
	elif [ -z "${format_4}" ] && [ -n "${format_6}" ]; then
		echo "$format_6"
		return 0
	else
		return 1
	fi
}

__valid_port() {
	local port
	port=$1
	if [ "$(number_test "${port}")" != "0" ];then
		echo ""
		return 1
	fi

	if [ "${port}" -gt "1" ] && [ "${port}" -lt "65535" ];then
		echo "${port}"
		return 0
	else
		echo ""
		return 1
	fi
}