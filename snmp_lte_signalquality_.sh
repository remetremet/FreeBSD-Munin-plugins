#!/usr/local/bin/bash

oid="1.3.6.1.4.1.12823.1.3.9.23.1.0"
oid="1.3.6.1.4.1.171.9.1.1.5.1.1.4.1"
file_host=${0##*/snmp_lte_signalquality_}
host=${host:-${file_host:-192.168.113.1}}

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title LTE/3G signal quality"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Signal quality (%)'
        echo 'graph_category devices'
        echo 'graph_info This graph % of signal quality'
        echo 'sq.label %'
        echo 'sq.draw LINE1'
        echo 'sq.info signal quality'
        if [ ! "${warning}" = "" ]; then
         echo "sq.warning ${warning}"
        fi
        if [ ! "${critical}" = "" ]; then
         echo "sq.critical ${critical}"
        fi
        exit 0
fi

sq=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid} | /usr/bin/awk '{print $4}'`
echo -n "sq.value "
echo ${sq:-0}
