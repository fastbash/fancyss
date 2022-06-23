#! /bin/sh

# fancyss script for asuswrt/merlin based router with software center


. "$(find / -name ss_base.sh)"
if [ "$MODULE" = "" ];then . "$(find / -name 'ss_var.sh')";fi
echo "正在卸载……"
sh /koolshare/ss/ssconfig.sh stop >/dev/null 2>&1
sh /koolshare/scripts/ss_conf.sh koolshare 3 >/dev/null 2>&1
sleep 1

rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Module_${MODULE}*
rm -rf /koolshare/bin/ss-redir
rm -rf /koolshare/bin/ss-tunnel
rm -rf /koolshare/bin/ss-local
rm -rf /koolshare/bin/rss-redir
rm -rf /koolshare/bin/rss-tunnel
rm -rf /koolshare/bin/rss-local
rm -rf /koolshare/bin/obfs-local
rm -rf /koolshare/bin/koolgame
rm -rf /koolshare/bin/pdu
rm -rf /koolshare/bin/haproxy
rm -rf /koolshare/bin/dnscrypt-proxy
rm -rf /koolshare/bin/dns2socks
rm -rf /koolshare/bin/kcptun
rm -rf /koolshare/bin/cdns
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/chinadns1
rm -rf /koolshare/bin/chinadns-ng
rm -rf /koolshare/bin/smartdns
rm -rf /koolshare/bin/resolveip
rm -rf /koolshare/bin/speederv1
rm -rf /koolshare/bin/speederv2
rm -rf /koolshare/bin/udp2raw
rm -rf /koolshare/bin/trojan
rm -rf /koolshare/bin/xray
rm -rf /koolshare/bin/v2ray
rm -rf /koolshare/bin/v2ray-plugin
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/httping
rm -rf /koolshare/bin/haveged
rm -rf /koolshare/bin/isutf8
rm -rf /koolshare/res/icon-${MODULE}.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/qrcode.js
rm -rf /koolshare/res/tablednd.js
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfw.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/ss
find /koolshare/init.d/ -name "*${MODULE}.sh" -exec rm -rf {} \;
find /koolshare/init.d/ -name "*socks5.sh" -exec rm -rf {} \;

# legacy
rm -rf /koolshare/bin/v2ctl
rm -rf /koolshare/bin/dnsmasq >/dev/null 2>&1
rm -rf /koolshare/bin/Pcap_DNSProxy >/dev/null 2>&1
rm -rf /koolshare/bin/client_linux_arm*

dbus remove softcenter_module_${MODULE}_home_url
dbus remove softcenter_module_${MODULE}_install
dbus remove softcenter_module_${MODULE}_md5
dbus remove softcenter_module_${MODULE}_version

dbus remove ss_basic_enable
dbus remove ss_basic_version_local
dbus remove ss_basic_version_web
dbus remove ss_basic_v2ray_version