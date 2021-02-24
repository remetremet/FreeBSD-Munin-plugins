#!/bin/sh
# 

if [ "$1" = "autoconf" ]; then
	echo yes
	exit 0
fi

if [ "$1" = "config" ]; then

	echo 'graph_title IPFW denied packets per second'
        echo 'graph_category security'
	echo 'graph_args --base 1000 -l 0'
	echo 'graph_vlabel Denied packets'
        echo 'graph_total Total'
	echo 'denybl.label Local BL'
        echo 'denybl.type DERIVE'
        echo 'denybl.min 0'
	echo 'denybl_rmt.label Remet BL'
        echo 'denybl_rmt.type DERIVE'
        echo 'denybl_rmt.min 0'
	echo 'denybl_imp.label Imported BL'
        echo 'denybl_imp.type DERIVE'
        echo 'denybl_imp.min 0'
        echo 'denyports.label Restricted Ports'
        echo 'denyports.type DERIVE'
        echo 'denyports.min 0'
	echo 'deny.label Others'
        echo 'deny.type DERIVE'
        echo 'deny.min 0'
	exit 0
fi

cnt=$(ipfw -a list | grep "deny" | grep -E "BLACKLIST6?\)" | awk '{ if($2!="0")print $2; }' | paste -s -d + - | bc)
echo "denybl.value ${cnt:-0}"
cnt=$(ipfw -a list | grep "deny" | grep -E "BLACKLIST_RMT6?\)" | awk '{ if($2!="0")print $2; }' | paste -s -d + - | bc)
echo "denybl_rmt.value ${cnt:-0}"
cnt=$(ipfw -a list | grep "deny" | grep -E "BLACKLIST_IMP6?\)" | awk '{ if($2!="0")print $2; }' | paste -s -d + - | bc)
echo "denybl_imp.value ${cnt:-0}"
cnt=$(ipfw -a list | grep "deny" | grep -v "(BLACKLIST" | grep -v "(BLOCKED_RANGES" | awk '{ if($2!="0")print $2; }' | paste -s -d + - | bc)
echo "denyports.value ${cnt:-0}"
cnt=$(ipfw -a list | grep "deny" | grep -E "BLOCKED_RANGES6?\)" | awk '{ if($2!="0")print $2; }' | paste -s -d + - | bc)
echo "deny.value ${cnt:-0}"
