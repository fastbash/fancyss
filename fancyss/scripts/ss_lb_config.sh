#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

. /koolshare/scripts/ss_base.sh
eval "$(dbus export ss)"
username=$(nvram get http_username)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
IFIP_DNS1=$(echo "$ISP_DNS1"|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
IFIP_DNS2=$(echo "$ISP_DNS2"|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")


write_haproxy_cfg(){
	local tmp server_ip
	rm -rf /jffs/configs/dnsmasq.d/ss_server.conf
	echo_date "生成haproxy配置文件到/koolshare/configs目录."
	cat > "/koolshare/configs/haproxy.cfg" <<-EOF
		global
		    log         127.0.0.1 local2
		    chroot      /usr/bin
		    pidfile     /var/run/haproxy.pid
		    maxconn     4000
		    user        nobody
		    daemon
		defaults
		    mode                    tcp
		    log                     global
		    option                  tcplog
		    option                  dontlognull
		    option http-server-close
		    #option forwardfor      except 127.0.0.0/8
		    option                  redispatch
		    retries                 2
		    timeout http-request    10s
		    timeout queue           1m
		    timeout connect         3s                                   
		    timeout client          1m
		    timeout server          1m
		    timeout http-keep-alive 10s
		    timeout check           10s
		    maxconn                 3000
	
		listen admin_status
		    bind 0.0.0.0:1188
		    mode http                
		    stats refresh 30s    
		    stats uri  /
		    stats auth $username:$ss_lb_passwd
		    #stats hide-version  
		    stats admin if TRUE
		resolvers mydns
		    # nameserver dns1 119.29.29.29:53
		    nameserver dns1 $(__get_server_resolver):$(__get_server_resolver_port)
		    nameserver dns2 114.114.114.114:53
		    resolve_retries       3
		    timeout retry         2s
		    hold valid           10s
		listen shadowscoks_balance_load
		    bind 0.0.0.0:$ss_lb_port
		    mode tcp
		    balance $ss_lb_balance
	EOF
	
	if [ "$ss_lb_heartbeat" = "1" ];then
		echo_date "启用故障转移心跳..."
	else
		echo_date "不启用故障转移心跳..."
	fi

	lb_node=$(dbus list ssconf_basic_use_lb_|sed 's/ssconf_basic_use_lb_//g' |cut -d "=" -f 1 | sort -n | sed '/^$/d')
	for node in $lb_node
	do
		nick_name=$(dbus get ssconf_basic_name_$node)
		if [ ! -z "$nick_name" ];then
			kcp=$(dbus get ssconf_basic_use_kcp_$node)
			if [ "$kcp" = "1" ];then
				port="1091"
				name=$(dbus get ssconf_basic_server_$node):kcp
				server="127.0.0.1"
			else
				port=$(dbus get ssconf_basic_port_$node)
				name=$(dbus get ssconf_basic_server_$node):$port
				server=$(dbus get ssconf_basic_server_$node)
				# tmp=$(__valid_ip "$server")
				# if [ $? = 0 ];then
				# 	echo_date "检测到【"${nick_name}"】节点已经是IP格式，跳过解析... "
					server_ip=$server
				# else
				# 	echo_date "使用nslookup方式解析负载均衡服务器【${nick_name}】的ip地址，解析DNS：$(__get_server_resolver):$(__get_server_resolver_port)"
				# 	server_ip=$(__resolve_ip "$server")
				# 	case $? in
				# 	0)
				# 		# server is domain format and success resolved.
				# 		echo_date "【${nick_name}】节点【${server}】的ip地址解析成功：${server_ip}"
				# 		echo "server=/${server}/$(__get_server_resolver)#$(__get_server_resolver_port)" >> /jffs/configs/dnsmasq.d/ss_server.conf
				# 		;;
				# 	1)
				# 		# server is domain format and failed to resolve.
				# 		echo_date "【警告】：【${nick_name}】节点【${server}】的ip解析失败，将不会添加到负载均衡列表！"
				# 		echo "server=/${server}/$(__get_server_resolver)#$(__get_server_resolver_port)" >> /jffs/configs/dnsmasq.d/ss_server.conf
				# 		continue
				# 		;;
				# 	2)
				# 		# server is not ip either domain!
				# 		echo_date "错误！！检测【${nick_name}】节点【${server}】既不是ip地址，也不是域名格式！"
				# 		echo_date "此节点将不会添加到负载均衡列表！"
				# 		continue
				# 		;;
				# 	esac
				# fi
			fi
			weight=$(dbus get ssconf_basic_weight_$node)
			mode=$(dbus get ssconf_basic_lbmode_$node)
			if [ "$ss_lb_heartbeat" = "1" ];then
				up=$(dbus get ss_lb_up)
				down=$(dbus get ss_lb_down)
				interval=$(dbus get ss_lb_interval)
				sp_args="rise ${up} fall ${down} check inter ${interval}"
			else
				sp_args=""
			fi
			
			if [ "$mode" = "3" ];then
				echo_date "载入【$nick_name】【$server】作为备用节点..."
				cat >> "/koolshare/configs/haproxy.cfg" <<-EOF
				    server ${name} ${server_ip}:${port} maxconn 20480 weight ${weight} ${sp_args} resolvers mydns backup
				EOF
			elif [ "$mode" = "2" ];then
				echo_date "载入【${nick_name}】【${server}】作为主用节点..."
				cat >> "/koolshare/configs/haproxy.cfg" <<-EOF
				    server $name $server_ip:$port maxconn 20480 weight ${weight} ${sp_args} resolvers mydns
				EOF
			else
				echo_date "载入【${nick_name}】【${server}】作为负载均衡节点..."
				cat >> "/koolshare/configs/haproxy.cfg" <<-EOF
				    server ${name} ${server_ip}:${port} maxconn 20480 weight ${weight} ${sp_args} resolvers mydns
				EOF
			fi
		else
			#检测到这个节点是空的，可能是某一次的残留，用这个方式处理一下
			dbus remove ssconf_basic_use_lb_$node
		fi
	done
}

start_haproxy(){
	local pid="$(pidof haproxy)"
	if [ -z "$pid" ];then
		echo_date "┏启动haproxy主进程..."
		echo_date "┣如果此处等待过久，可能服务器域名解析失败造成的！可以刷新页面后关闭一次SS!"
		echo_date "┣然后进入附加设置-SS服务器地址解析，更改解析dns或者更换解析方式！"
		echo_date "┗启动haproxy主进程..."
		haproxy -f "/koolshare/configs/haproxy.cfg"
	fi
}

if [ -z "$2" ];then
	#this is for autoupdate
	if [ "$ss_lb_enable" = "1" ];then
		killall haproxy > /dev/null 2>&1
		write_haproxy_cfg >> /tmp/upload/ss_log.txt
		start_haproxy >> /tmp/upload/ss_log.txt
		echo_date 成功！
	else
		killall haproxy >/dev/null 2>&1
	fi
fi

case $2 in
start)
	if [ "$ss_lb_enable" = "1" ];then
		true > /tmp/upload/ss_log.txt
		http_response "$1"
		killall haproxy > /dev/null 2>&1
		{ 
			write_haproxy_cfg 
			start_haproxy 
			echo_date "成功！"
			echo XU6J03M6 
		} >> /tmp/upload/ss_log.txt
	else
		true > /tmp/upload/ss_log.txt
		http_response "$1"
		echo_date "关闭haproxy进程！">> /tmp/upload/ss_log.txt
		killall haproxy >/dev/null 2>&1
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
	fi
	;;
esac