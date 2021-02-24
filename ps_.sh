#!/bin/sh
. $MUNIN_LIBDIR/plugins/plugin.sh

myname=`basename $0 | sed 's/^ps_//g'`
name="${name:-$myname}"
REGEX="${regex:-$name}"

if [ "$1" = "autoconf" ]; then
	echo no
	exit 0
fi
if [ "$1" = "suggest" ]; then
	exit 0
fi
if [ "$1" = "config" ]; then
	echo graph_title Number of $myname processes
	echo 'graph_args --base 1000 --vertical-label processes -l 0'
	echo 'graph_category system'
	echo "count.label $myname"
        if [ ! "${ps_warning}" = "" ]; then
	 echo "count.warning ${ps_warning}"
	fi
        if [ ! "${ps_critical}" = "" ]; then
	 echo "count.critical ${ps_critical}"
	fi
	exit 0
fi

printf "count.value "
ps auxwww | grep "${REGEX}" | grep -v "ps_${REGEX}" | grep -v grep | wc -l | sed 's/ //g'
