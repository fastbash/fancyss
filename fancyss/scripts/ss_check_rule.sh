#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

. /koolshare/scripts/ss_base.sh
eval "$(dbus export ss_)"



check_rule(){
    if [ ! -f /jffs/.koolshare/scripts/ss_base.sh ];then echo_date 'ssr plugin is not exsit!';return 1;fi
    domain="$1"
    echo_date "domain: $domain"
    dnsPort=$(find /jffs/configs/dnsmasq.d/ -name "*" | xargs grep -w "$domain" 2>/dev/null | grep -w 'server=' | awk -F'#' '{print $2}' | head -n1)
    if [ "$ss_basic_mode" = 1 ];then #gfwlist
        echo_date "plugin mode: gfwlist"
        if [ "$dnsPort" = "" ];then
            echo_date "gfwlist file: false"
            dnsPort=53
        elif [ "$dnsPort" = "7913" ];then
            echo_date "gfwlist file: true"
        fi
    elif [ "$ss_basic_mode" = 2 ];then #whitelist
        echo_date "plugin mode: whitelist"
        if [ "$dnsPort" = "53" ];then #in cdnlist
            echo_date "cdn file: true"
        elif [ "$dnsPort" = "" ];then #not in cdnlist
            dnsPort=7913
            echo_date "cdn file: false"
        fi
    else
        echo_date "pass by direct"
    fi
    # check chnroute, get domain ip
    if [ "$dnsPort" != "" ];then
        tmp_ip=$(nslookup "$domain" 127.0.0.1:$dnsPort | grep 'Address 1:' | tail -n1 | awk '{print $3}')
        if echo "$tmp_ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$';then #is a ip address
            if ipset list | grep -q chnroute;then #confirm ipset chnroute is exsit
                if ipset test chnroute "$tmp_ip";then # direct
                    echo_date "pass by direct"
                else # proxy
                    echo_date "pass by proxy"
                fi 
            else
                echo_date "ipset chnroute is not exist!"
            fi
        else
            echo_date "get domain $domain 's ip address failed!"
        fi
    fi
}
true > /tmp/upload/ss_log.txt
http_response "$1"
{ echo_date "==================================================================="
echo_date "rule check"
echo_date "==================================================================="
#echo $* >> /tmp/upload/ss_log.txt
check_rule "$2" >> /tmp/upload/ss_log.txt
echo XU6J03M6 >> /tmp/upload/ss_log.txt
} >> /tmp/upload/ss_log.txt

#if [ "$1" != "" ];then check_rule "$1";fi