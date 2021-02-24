#!/bin/sh
# 
# 
# Script to show auth stuff
#
# Parameters understood:
#
# 	config   (required)
# 	autoconf (optional - used by munin-config)
#
#
# Magic markers (optional - used by munin-config and installation
# scripts):
#
#%# family=auto
#%# capabilities=autoconf

MAXLABEL=20
LOGFILE=${auth_logfile:-/var/log/auth.log}

if [ "$1" = "autoconf" ]; then
	echo yes
	exit 0
fi

if [ "$1" = "config" ]; then

	echo 'graph_title Auth Log Parser'
        echo 'graph_category security'
	echo 'graph_args --base 1000 -l 0'
	echo 'graph_vlabel Daily Auth Counters'
	echo 'illegal_user.label Illegal User'
	echo 'possible_breakin.label Breakin Attempt'
	echo 'authentication_failure.label Authentication Fail'
	exit 0
fi

echo -n "illegal_user.value "
echo $(grep "Illegal user\|Invalid user" ${LOGFILE} | grep "`date '+%b %e'`" | wc -l | sed 's/ //g')
echo -n
echo -n "possible_breakin.value "
echo $(grep -i "POSSIBLE BREAK-IN ATTEMPT" ${LOGFILE} | grep "`date '+%b %e'`" | wc -l | sed 's/ //g')
echo -n "authentication_failure.value "
echo $(grep "authentication error" ${LOGFILE} | grep "`date '+%b %e'`" | wc -l | sed 's/ //g')
