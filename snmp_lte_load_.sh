#!/usr/local/bin/bash

oid="1.3.6.1.4.1.2021.10.1.3.2"
file_host=${0##*/snmp_lte_load_}
host=${host:-${file_host:-192.168.0.1}}

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title LTE/3G router CPU load"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Router load'
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'load.label %'
        echo 'load.draw AREA'
        echo 'load.info Load'
        exit 0
fi

load=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid} | /usr/bin/awk '{print $4}' | /usr/bin/sed s/..//`
echo -n "load.value "
echo ${load:-0}
