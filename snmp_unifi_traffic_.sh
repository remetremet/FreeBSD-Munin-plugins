#!/usr/local/bin/bash

oidin="1.3.6.1.2.1.2.2.1.10.6"
oidout="1.3.6.1.2.1.2.2.1.16.6"
oidname="1.3.6.1.2.1.1.5.0"
file_host=${0##*/snmp_unifi_traffic_}
host=${host:-${file_host:-192.168.255.200}}
if [ "${host}" == ".new" ]; then
 host="192.168.255.200"
fi

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

PARAM="-i 0.1 -c 8 -t 1"
PING=`/sbin/ping ${PARAM} -q ${host} 2>&1 | grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed s/\%// | /usr/bin/sed s/..$//`
if [ "${PING:-100}" -lt "25" ]; then
 unifiname=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oidname} | /usr/bin/awk '{print $4}'`
fi

if [ "$1" = "config" ]; then
        echo "graph_title Unifi AP ${unifiname} traffic"
        echo 'graph_args --base 1024'
        echo "graph_vlabel ${unifiname} traffic"
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'graph_total Total'
        echo 'IN.label IN'
        echo 'IN.draw AREA'
        echo 'OUT.label OUT'
        echo 'OUT.draw STACK'
        exit 0
fi

if [ "${PING:-100}" -lt "25" ]; then
 IN=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oidin} | /usr/bin/awk '{print $4}'`
 echo -n "IN.value "
 echo ${IN:-0}
 OUT=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oidout} | /usr/bin/awk '{print $4}'`
 echo -n "OUT.value "
 echo ${OUT:-0}
fi
