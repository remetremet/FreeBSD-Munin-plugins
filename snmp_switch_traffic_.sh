#!/usr/local/bin/bash -

oid=".1.3.6.1.2.1.2.2.1.10"
oid2=".1.3.6.1.2.1.2.2.1.16"
file_host=${0##*/snmp_switch_traffic_}
host=${file_host:-${host:-192.168.255.240}}
if [ "${host}" == ".new" ]; then
 host="192.168.255.240"
fi

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title Switch ${host} traffic"
        echo 'graph_args --base 1024 -l 0'
        echo 'graph_scale yes'
        echo 'graph_vlabel Traffic in bytes'
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'ports.label Total traffic through the switch'
        echo 'ports.draw AREA'
#        echo 'ports.info sig'
        exit 0
fi

#PRT="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 "
#ports=0
#for i in ${PRT}; do
# tin=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid}.${i} | /usr/bin/awk '{print $4}'`
# tout=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid2}.${i} | /usr/bin/awk '{print $4}'`
# ((ports=ports+tin+tout))
#done

PARAM="-i 0.1 -c 8 -t 1"
PING=`/sbin/ping ${PARAM} -q ${host} 2>&1 | grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed s/\%// | /usr/bin/sed s/..$//`
if [ "${PING:-100}" -lt "25" ]; then
 ports=0
 tin=`/usr/local/bin/snmpwalk -v1 -cpublic -Ovq ${host} ${oid} | /usr/bin/grep -v "^0$" | /usr/bin/awk '{s+=$1} END {printf "%.0f\n", s}'`
 tout=`/usr/local/bin/snmpwalk -v1 -cpublic -Ovq ${host} ${oid2} | /usr/bin/grep -v "^0$" | /usr/bin/awk '{s+=$1} END {printf "%.0f\n", s}'`
 ((ports=tin+tout))
 echo "ports.value ${ports:-0}"
else
 echo "ports.value 0"
fi
