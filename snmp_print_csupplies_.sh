#!/usr/local/bin/bash

oid_y="1.3.6.1.2.1.43.11.1.1.9.1.1"
oid_m="1.3.6.1.2.1.43.11.1.1.9.1.2"
oid_c="1.3.6.1.2.1.43.11.1.1.9.1.3"
oid_k="1.3.6.1.2.1.43.11.1.1.9.1.4"
oid_o="1.3.6.1.2.1.43.11.1.1.9.1.5"
oid_maxy="1.3.6.1.2.1.43.11.1.1.8.1.1"
oid_maxm="1.3.6.1.2.1.43.11.1.1.8.1.2"
oid_maxc="1.3.6.1.2.1.43.11.1.1.8.1.3"
oid_maxk="1.3.6.1.2.1.43.11.1.1.8.1.4"
oid_maxo="1.3.6.1.2.1.43.11.1.1.8.1.5"

file_host=${0##*/snmp_print_supplies_}
host="${file_host:-${printhost}}"
host="${host:-192.168.255.210}"

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title Supplies (${host})"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Total supplies left in device'
        echo 'graph_category print'
        echo 'graph_info This graph numer of printed pages'
        echo 'supply_c.label C'
        echo 'supply_c.draw LINE1'
        echo 'supply_c.info percent of Cyan supply available'
        echo 'supply_m.label M'
        echo 'supply_m.draw LINE1'
        echo 'supply_m.info percent od Magenta supply available'
        echo 'supply_y.label Y'
        echo 'supply_y.draw LINE1'
        echo 'supply_y.info percent od Yellow supply available'
        echo 'supply_k.label K'
        echo 'supply_k.draw LINE1'
        echo 'supply_k.info percent od Black supply available'
        echo 'supply_o.label Unit'
        echo 'supply_o.draw LINE1'
        echo 'supply_o.info percent od Optics available'
        exit 0
fi

max=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_maxc} | /usr/bin/awk '{print $4}'`
count=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_c} | /usr/bin/awk '{print $4}'`
count=`expr ${count:-0} \* 100 \/ ${max:-1}`
echo -n "supply_c.value "
echo ${count:-0}
max=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_maxm} | /usr/bin/awk '{print $4}'`
count=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_m} | /usr/bin/awk '{print $4}'`
count=`expr ${count:-0} \* 100 \/ ${max:-1}`
echo -n "supply_m.value "
echo ${count:-0}
max=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_maxy} | /usr/bin/awk '{print $4}'`
count=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_y} | /usr/bin/awk '{print $4}'`
count=`expr ${count:-0} \* 100 \/ ${max:-1}`
echo -n "supply_y.value "
echo ${count:-0}
max=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_maxk} | /usr/bin/awk '{print $4}'`
count=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_k} | /usr/bin/awk '{print $4}'`
count=`expr ${count:-0} \* 100 \/ ${max:-1}`
echo -n "supply_k.value "
echo ${count:-0}
max=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_maxo} | /usr/bin/awk '{print $4}'`
count=`/usr/local/bin/snmpget -v1 -cpublic -On ${host} ${oid_o} | /usr/bin/awk '{print $4}'`
count=`expr ${count:-0} \* 100 \/ ${max:-1}`
echo -n "supply_o.value "
echo ${count:-0}
