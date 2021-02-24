#!/usr/local/bin/bash

oid=".1.3.6.1.2.1.2.2.1.5"
file_host=${0##*/snmp_switch_ports_}
host=${file_host:-${host:-192.168.255.240}}
if [ "${host}" == ".new" ]; then
 host="192.168.255.240"
fi

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title Switch ${host} active ports"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Active ports'
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'ports.label no of ports'
        echo 'ports.draw LINE1'
#        echo 'ports.info sig'
        exit 0
fi

#PRT="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 "
#ports=0
#for i in ${PRT}; do
# port=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid}.${i} | /usr/bin/awk '{print $4}'`
# if [ ${port:0} -gt 0 ]; then
#  ((ports=ports+1))
# fi
#done

PARAM="-i 0.1 -c 8 -t 1"
PING=`/sbin/ping ${PARAM} -q ${host} 2>&1 | grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed s/\%// | /usr/bin/sed s/..$//`
if [ "${PING:-100}" -lt "25" ]; then
 ports=`/usr/local/bin/snmpwalk -v1 -cpublic -Ovq ${host} ${oid} | /usr/bin/grep -v "^0$" | /usr/bin/wc -l`
 ((ports=ports+0))
 echo "ports.value ${ports:-0}"
else
 echo "ports.value 0"
fi
