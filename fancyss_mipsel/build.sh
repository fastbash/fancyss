#!/bin/bash


MODULE=shadowsocks
VERSION=$(cat ./shadowsocks/ss/version)
TITLE=shadowsocks
DESCRIPTION=shadowsocks
HOME_URL=Main_Ss_Content.asp

# Check and include base
DIR=$(cd "$(dirname "$0")";pwd)
if [ 1"$MODULE" == 1"" ];then
	echo "module not found"
	exit 1
fi

if [ -f "$DIR/$MODULE/$MODULE/install.sh" ]; then
	echo "install script not found"
	exit 2
fi

cp_rules(){
	cp -rf ../rules/gfwlist.conf shadowsocks/ss/rules/
	cp -rf ../rules/chnroute.txt shadowsocks/ss/rules/
	cp -rf ../rules/cdn.txt shadowsocks/ss/rules/
	cp -rf ../rules/version1 shadowsocks/ss/rules/version
}

do_backup(){
	HISTORY_DIR="../../fancyss_history_package/fancyss_mipsel"
	# backup latested package after pack
	backup_version=`cat version | sed -n 1p`
	backup_tar_md5=`cat version | sed -n 2p`
	echo backup VERSION $backup_version
	cp ${MODULE}.tar.gz $HISTORY_DIR/${MODULE}_$backup_version.tar.gz
	sed -i "/$backup_version/d" "$HISTORY_DIR"/md5sum.txt
	echo $backup_tar_md5 ${MODULE}_$backup_version.tar.gz >> "$HISTORY_DIR"/md5sum.txt
}

do_build() {
	if [ "$VERSION" = "" ]; then
		echo "version not found"
		exit 3
	fi

	rm -f ${MODULE}.tar.gz
	rm -f $MODULE/.DS_Store
	rm -f $MODULE/*/.DS_Store
	tar -zcvf ${MODULE}.tar.gz $MODULE
	md5value=`md5sum ${MODULE}.tar.gz|tr " " "\n"|sed -n 1p`
	cat > ./version <<-EOF
	$VERSION
	$md5value
	EOF
	cat version

	DATE=`date +%Y-%m-%d_%H:%M:%S`
	cat > ./config.json.js <<-EOF
	{
	"build_date":"$DATE",
	"description":"$DESCRIPTION",
	"home_url":"$HOME_URL",
	"md5":"$md5value",
	"name":"$MODULE",
	"tar_url": "https://raw.githubusercontent.com/fastbash/fancyss/master/fancyss_mipsel/shadowsocks.tar.gz",
	"title":"$TITLE",
	"version":"$VERSION"
	}
	EOF
}



cp_rules
do_build
do_backup

