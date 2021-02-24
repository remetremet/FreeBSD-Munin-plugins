#!/usr/local/bin/bash

oid="1.3.6.1.4.1.10002.1.1.1.4.2.1.3.1"
oidname="1.3.6.1.2.1.1.5.0"
file_host=${0##*/snmp_unifi_load_}
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
        echo "graph_title Unifi AP ${unifiname} load"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo "graph_vlabel ${unifiname} load"
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'load.label %'
        echo 'load.draw AREA'
        echo 'load.info Load'
        exit 0
fi

if [ "${PING:-100}" -lt "25" ]; then
 load=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid} | /usr/bin/awk '{print $4}' | /usr/bin/sed s/..//`
 echo "load.value ${load:-0}"
fi
