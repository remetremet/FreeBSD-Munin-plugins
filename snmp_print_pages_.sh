#!/usr/local/bin/bash

oid="1.3.6.1.2.1.43.10.2.1.4.1.1"
file_host="${0##*/snmp_print_pages_}"
host="${file_host:-${printhost}}"
host="${host:-192.168.255.210}"

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title Pages (${host})"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Total printed pages'
        echo 'graph_category print'
        echo 'graph_info This graph numer of printed pages'
        echo 'pages.label pages'
        echo 'pages.draw LINE1'
        echo 'pages.info total pages printed'
        exit 0
fi

pages=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid} | /usr/bin/awk '{print $4}'`
echo "pages.value ${pages:-0}"
