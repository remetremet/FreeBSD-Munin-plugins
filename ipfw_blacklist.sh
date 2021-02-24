#!/bin/sh
# 

if [ "$1" = "autoconf" ]; then
	echo yes
	exit 0
fi

if [ "$1" = "config" ]; then

	echo 'graph_title IPFW blacklist table rules'
        echo 'graph_category security'
	echo 'graph_args --base 1000 -l 0'
        echo 'graph_noscale true'
	echo 'graph_vlabel IPFW blacklist IPs'
        echo 'blacklist.label Local BL IPv4s'
        echo 'blacklist6.label Local BL IPv6s'
        echo 'blacklist_rmt.label Remet BL IPv4s'
        echo 'blacklist_rmt6.label Remet BL IPv6s'
	echo 'blacklist_imp.label Imported BL IPv4s'
        echo 'blacklist_imp6.label Imported BL IPv6s'
	exit 0
fi

cnt=$(ipfw table BLACKLIST list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist.value ${cnt}"
cnt=$(ipfw table BLACKLIST6 list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist6.value ${cnt}"
cnt=$(ipfw table BLACKLIST_RMT list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist_rmt.value ${cnt}"
cnt=$(ipfw table BLACKLIST_RMT6 list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist_rmt6.value ${cnt}"
cnt=$(ipfw table BLACKLIST_IMP list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist_imp.value ${cnt}"
cnt=$(ipfw table BLACKLIST_IMP6 list | wc -l | sed 's/ //g')
cnt=$(( ${cnt} - 1 ))
echo "blacklist_imp6.value ${cnt}"
