#!/usr/local/bin/bash -

oid="1.3.6.1.2.1.1.3.0"
file_host=${0##*/snmp_switch_uptime_}
host=${file_host:-${host:-192.168.255.240}}
if [ "${host}" == ".new" ]; then
 host="192.168.255.240"
fi

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
        echo "graph_title Switch ${host} uptime"
        echo 'graph_args --base 1000 -l 0'
        echo 'graph_scale no'
        echo 'graph_vlabel Uptime in days'
        echo 'graph_category devices'
        echo 'graph_info This graph % of signal quality'
        echo 'uptime.label days'
        echo 'uptime.draw AREA'
        echo "uptime.info Uptime of ${host}"
        exit 0
fi

PARAM="-i 0.1 -c 8 -t 1"
PING=`/sbin/ping ${PARAM} -q ${host} 2>&1 | grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed s/\%// | /usr/bin/sed s/..$//`
if [ "${PING:-100}" -lt "25" ]; then
 uptime=`/usr/local/bin/snmpget -v1 -cpublic -Ovt ${host} ${oid}`
 if [ "${uptime:-0}" != "0" ]; then
  uptime=$(div ${uptime} 8640000)
  echo "uptime.value ${uptime}"
 else
  uptime=`/usr/local/bin/snmpget -v1 -cpublic -Ovt ${host} ${oid}`
  if [ "${uptime:-0}" != "0" ]; then
   uptime=$(div ${uptime} 8640000)
   echo "uptime.value ${uptime}"
  fi
 fi
else
 echo "uptime.value 0"
fi
