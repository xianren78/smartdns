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
SMARTDNS_OPT=$CURR_DIR/smartdns-opt.conf
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
	ROOT=/tmp/smartdns-optware
	rm -fr $ROOT

	mkdir -p $ROOT
	cp $CURR_DIR/* $ROOT/ -af
	cd $ROOT/
	mkdir $ROOT/opt/usr/sbin -p
	mkdir $ROOT/opt/etc/init.d -p
	mkdir $ROOT/opt/etc/smartdns/ -p

	cp $SMARTDNS_CONF  $ROOT/opt/etc/smartdns/
	cp $SMARTDNS_OPT $ROOT/opt/etc/smartdns/
	cp $CURR_DIR/S50smartdns $ROOT/opt/etc/init.d/
	$SMARTDNS_CP $ROOT/opt /opt
	if [ $? -ne 0 ]; then
		echo "copy smartdns file failed."
		rm -fr $PKG_ROOT
		return 1
	fi
	if [ $? -ne 0 ]; then
		echo "copy smartdns file failed."
		rm -fr $ROOT/
		return 1
	fi

	if [ $IS_BUILD_SMARTDNS_UI -ne 0 ]; then
		mkdir $ROOT/opt/usr/lib/smartdns -p
		cp $SMARTDNS_DIR/plugin/smartdns-ui/target/smartdns_ui.so $ROOT/opt/usr/lib/smartdns/
		if [ $? -ne 0 ]; then
			echo "copy smartdns_ui.so file failed."
			rm -fr $ROOT/
			return 1
		fi

		mkdir $ROOT/opt/usr/share/smartdns/wwwroot -p
		cp $WORKDIR/smartdns-webui/out/* $ROOT/opt/usr/share/smartdns/wwwroot/ -a
		if [ $? -ne 0 ]; then
			echo "Failed to copy smartdns-ui web files."
			rm -fr $ROOT/
			return 1
		fi
	fi

	sed -i "s/# *server-name smartdns/server-name smartdns/g" $ROOT/opt/etc/smartdns/smartdns.conf
	sed -i "s/^Architecture.*/Architecture: $ARCH/g" $ROOT/control/control
	sed -i "s/Version:.*/Version: $VER/" $ROOT/control/control

	cd $ROOT/control
	sed -i '/^.*:\s*$/d' control
	chmod +x *
	tar zcf ../control.tar.gz --owner=0 --group=0 ./ 
	cd $ROOT

	tar zcf data.tar.gz --owner=0 --group=0 opt
	tar zcf $OUTPUTDIR/smartdns.$VER.$FILEARCH.ipk --owner=0 --group=0 control.tar.gz data.tar.gz debian-binary
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
