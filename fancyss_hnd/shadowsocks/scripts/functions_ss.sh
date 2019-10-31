__get_server_resolver() {
	local value_1="$ss_basic_server_resolver"
	local value_2="$ss_basic_server_resolver_user"
	local res

	case "$value_1" in
	  "1")
      if [ -n "$IFIP_DNS1" ]; then
        res="$ISP_DNS1"
      else
        res="114.114.114.114"
      fi
		;;
	  "2")
      res="223.5.5.5"
		;;
	  "3")
      res="223.6.6.6"
		;;
	  "4")
      res="114.114.114.114"
		;;
	  "5")
      res="114.114.115.115"
		;;
	  "6")
      res="1.2.4.8"
		;;
	  "7")
      res="210.2.4.8"
		;;
	  "8")
      res="117.50.11.11"
		;;
	  "9")
      res="117.50.22.22"
		;;
	  "10")
      res="180.76.76.76"
		;;
	  "11")
      res="119.29.29.29"
		;;
	  "12")
      if [ "$value_1" == "12" ]; then
        if [ -n "$value_2" ]; then
          res=$(__valid_ip "$value_2")
          [ -z "$res" ] && res="114.114.114.114"
        else
          res="114.114.114.114"
        fi
		  fi
		;;
		*)
		  res="223.5.5.5"
    ;;
  esac
	echo $res
}

__get_server_resolver_port() {
	local port
	if [ "$ss_basic_server_resolver" == "12" ]; then
		if [ -n "$ss_basic_server_resolver_user" ]; then
			port=$(echo "$ss_basic_server_resolver_user" | awk -F"#|:" '{print $2}')
			[ -z "$port" ] && port="53"
		else
			port="53"
		fi
	else
		port="53"
	fi
	echo $port
}

__resolve_ip() {
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "$domain1" ] || [ -z "$domain2" ]; then
		# not ip, not domain
		echo ""
		return 2
	else
		# domain format
		SERVER_IP=$(nslookup "$1" $(__get_server_resolver):$(__get_server_resolver_port) | sed '1,4d' | awk '{print $3}' | grep -v : | awk 'NR==1{print}' 2>/dev/null)
		SERVER_IP=$(__valid_ip $SERVER_IP)
		if [ -n "$SERVER_IP" ]; then
			# success resolved
			echo "$SERVER_IP"
			return 0
		else
			# resolve failed
			echo ""
			return 1
		fi
	fi
}

__valid_ip() {
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	local format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')
	if [ -n "$format_4" ] && [ -z "$format_6" ]; then
		echo "$format_4"
		return 0
	elif [ -z "$format_4" ] && [ -n "$format_6" ]; then
		echo "$format_6"
		return 0
	else
		echo ""
		return 1
	fi
}