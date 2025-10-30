#!/bin/sh
#
# Copyright (C) 2018-2025 Ruilin Peng (Nick) <pymumu@gmail.com>.
#
# smartdns is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# smartdns is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
CURR_DIR=$(cd $(dirname $0);pwd)

VER="`date +"1.%Y.%m.%d-%H%M"`"
SMARTDNS_DIR=$CURR_DIR/../../
SMARTDNS_CP=$SMARTDNS_DIR/package/copy-smartdns.sh
SMARTDNS_BIN=$SMARTDNS_DIR/src/smartdns
SMARTDNS_CONF=$SMARTDNS_DIR/etc/smartdns/smartdns.conf
ADDRESS_CONF=$CURR_DIR/address.conf
BLACKLIST_IP_CONF=$CURR_DIR/blacklist-ip.conf
CUSTOM_CONF=$CURR_DIR/custom.conf
DOMAIN_BLOCK_LIST=$CURR_DIR/domain-block.list
DOMAIN_FORWARDING_LIST=$CURR_DIR/domain-forwarding.list
IS_BUILD_SMARTDNS_UI=0

showhelp()
{
	echo "Usage: make [OPTION]"
	echo "Options:"
	echo " -o               output directory."
	echo " --arch           archtecture."
	echo " --ver            version."
	echo " --with-ui        build with smartdns-ui plugin."
	echo " -h               show this message."
}

build()
{
	ROOT=/tmp/smartdns-openwrt
	rm -fr $ROOT

	mkdir -p $ROOT
	cp $CURR_DIR/* $ROOT/ -af
	cd $ROOT/
	mkdir $ROOT/root/usr/sbin -p
	mkdir $ROOT/root/etc/init.d -p
	mkdir $ROOT/root/etc/smartdns/ -p
	mkdir $ROOT/root/etc/smartdns/domain-set/ -p 
	mkdir $ROOT/root/etc/smartdns/ip-set/ -p 
	mkdir $ROOT/root/etc/smartdns/conf.d/ -p 
	mkdir $ROOT/root/etc/smartdns/download/ -p 

	cp $SMARTDNS_CONF  $ROOT/root/etc/smartdns/
	cp $ADDRESS_CONF $ROOT/root/etc/smartdns/
	cp $BLACKLIST_IP_CONF $ROOT/root/etc/smartdns/
	cp $CUSTOM_CONF $ROOT/root/etc/smartdns/
	cp $DOMAIN_BLOCK_LIST $ROOT/root/etc/smartdns/
	cp $DOMAIN_FORWARDING_LIST $ROOT/root/etc/smartdns/
	cp $CURR_DIR/files/etc $ROOT/root/ -af
	$SMARTDNS_CP $ROOT/root
	if [ $? -ne 0 ]; then
		echo "copy smartdns file failed."
		rm -fr $ROOT/
		return 1
	fi

	if [ $IS_BUILD_SMARTDNS_UI -ne 0 ]; then
		mkdir $ROOT/root/usr/lib/smartdns -p
		cp $SMARTDNS_DIR/plugin/smartdns-ui/target/smartdns_ui.so $ROOT/root/usr/lib/smartdns/
		if [ $? -ne 0 ]; then
			echo "copy smartdns_ui.so file failed."
			rm -fr $ROOT/
			return 1
		fi

		mkdir $ROOT/root/usr/share/smartdns/wwwroot -p
		cp $WORKDIR/smartdns-webui/out/* $ROOT/root/usr/share/smartdns/wwwroot/ -a
		if [ $? -ne 0 ]; then
			echo "Failed to copy smartdns-ui web files."
			rm -fr $ROOT/
			return 1
		fi
	fi

	chmod +x $ROOT/root/etc/init.d/smartdns
	INST_SIZE="`du -sb $ROOT/root/ | awk '{print $1}'`"

	sed -i "s/^Architecture.*/Architecture: $ARCH/g" $ROOT/control/control
	sed -i "s/Version:.*/Version: $VER/" $ROOT/control/control
	sed -i "s/^\(bind .*\):53/\1:6053/g" $ROOT/root/etc/smartdns/smartdns.conf
	if [ ! -z "$INST_SIZE" ]; then
		echo "Installed-Size: $INST_SIZE" >> $ROOT/control/control
	fi

	if [ "$STATIC" = "yes" ]; then
		sed -i "s/Depends:.*/Depends: libc/" $ROOT/control/control
	fi

	cd $ROOT/control
	chmod +x *
	tar zcf ../control.tar.gz --owner=0 --group=0 ./
	cd $ROOT

	tar zcf $ROOT/data.tar.gz -C root --owner=0 --group=0 .
	tar zcf $OUTPUTDIR/smartdns.$VER.$FILEARCH.ipk --owner=0 --group=0 ./control.tar.gz ./data.tar.gz ./debian-binary

	which apk >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		APK_VER="`echo $VER | sed 's/[-]/-r/'`"
		ARCH="`echo $ARCH | sed 's/all/noarch/g'`"
		apk mkpkg \
			--info "name:smartdns" \
			--info "version:$APK_VER" \
			--info "description:A smartdns Server" \
			--info "arch:$ARCH" \
			--info "license:GPL" \
			--info "origin: https://github.com/pymumu/smartdns.git" \
			--info "depends:libc libpthread" \
			--script "post-install:$ROOT/control/postinst" \
			--script "pre-deinstall:$ROOT/control/prerm" \
			--files "$ROOT/root/" \
			--output "$OUTPUTDIR/smartdns.$VER.$FILEARCH.apk"
		if [ $? -ne 0 ]; then
			echo "build apk package failed."
			rm -fr $ROOT/
			return 1
		fi
	else
		echo "== warning: apk tool not found, skip build apk package. =="
	fi

	rm -fr $ROOT/
}

main()
{
	OPTS=`getopt -o o:h --long arch:,ver:,with-ui,filearch: \
		-n  "" -- "$@"`

	if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

	# Note the quotes around `$TEMP': they are essential!
	eval set -- "$OPTS"

	while true; do
		case "$1" in
		--arch)
			ARCH="$2"
			shift 2;;
		--filearch)
			FILEARCH="$2"
			shift 2;;
		--with-ui)
			IS_BUILD_SMARTDNS_UI=1
			shift ;;
		--ver)
			VER="$2"
			shift 2;;
		-o )
			OUTPUTDIR="$2"
			shift 2;;
		-h | --help )
			showhelp
			return 0
			shift ;;
		-- ) shift; break ;;
		* ) break ;;
		esac
	done

	if [ -z "$ARCH" ]; then
		echo "please input arch."
		return 1;
	fi

	if [ -z "$FILEARCH" ]; then
		FILEARCH=$ARCH
	fi

	if [ -z "$OUTPUTDIR" ]; then
		OUTPUTDIR=$CURR_DIR;
	fi

	build
}

main $@
exit $?


