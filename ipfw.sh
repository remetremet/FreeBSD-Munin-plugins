#!/bin/sh
# 
if [ "$1" = "autoconf" ]; then
	echo yes
	exit 0
fi

if [ "$1" = "config" ]; then

	echo 'graph_title IPFW routed packets per second'
        echo 'graph_category security'
	echo 'graph_args --base 1000 -l 0'
	echo 'graph_vlabel Routing pps'
	echo 'packets.label Packets'
        echo 'packets.type DERIVE'
        echo 'packets.min 0'
        echo 'nat.label NAT'
        echo 'nat.type DERIVE'
        echo 'nat.min 0'
	exit 0
fi

#now=$(date +%s)
#boot=$(sysctl kern.boottime | sed 's/,//' | awk '{print $5}')
#uptime=$(( ${now} - ${boot} ))

cnt=$(ipfw -a list | grep " count " | awk '{print $2}' | grep -v "^0$" | paste -s -d + - | bc)
#cnt=$(echo "scale=2; ${cnt}/${uptime}" | bc)
echo "packets.value ${cnt:-0}"
cnt=$(ipfw -a list | grep " nat " | awk '{print $2}' | grep -v "^0$" | paste -s -d + - | bc)
#cnt=$(echo "scale=2; ${cnt}/${uptime}" | bc)
echo "nat.value ${cnt:-0}"
