#!/usr/local/bin/bash

oid="1.3.6.1.2.1.1.3.0"
file_host=${0##*/snmp_lte_uptime_}
host=${host:-${file_host:-192.168.0.1}}

div ()  # Arguments: dividend and divisor
{
 if [ $2 -eq 0 ]; then echo division by 0; exit; fi
 p=4                            # precision
 c=${c:-0}                       # precision counter
 d=.                             # decimal separator
 r=$(($1/$2)); echo -n $r        # result of division
 m=$(($r*$2))
 [ $c -eq 0 ] && [ $m -ne $1 ] && echo -n $d
 [ $1 -eq $m ] || [ $c -eq $p ] && exit
 d=$(($1-$m))
 let c=c+1
 div $(($d*10)) $2
}


if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title LTE/3G router uptime"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Uptime in days'
        echo 'graph_category devices'
#        echo 'graph_info This graph % of signal quality'
        echo 'uptime.label days'
        echo 'uptime.draw AREA'
#        echo 'uptime.info sig'
        exit 0
fi

uptime=`/usr/local/bin/snmpget -v2c -cpublic -On ${host} ${oid} | /usr/bin/awk '{print $4}' | /usr/bin/sed s/^.// | /usr/bin/sed s/.$//`
uptime=$(div ${uptime} 8640000)
echo -n "uptime.value "
echo ${uptime}
