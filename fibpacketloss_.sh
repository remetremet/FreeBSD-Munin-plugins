#!/usr/local/bin/bash -
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

TEMPFILE=`echo "${0#*/}" | /usr/bin/sed "s/\//_/g"`
TEMPFILE="/tmp/.munin_${TEMPFILE}"
PARTS=1
FIBS4=${MyFIBS:-0}
FIBS6=${MyFIBS6:-0}
TIMEOUT=12

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

case $0 in
    *packetloss6_*)
        PING=ping6
        file_host=${0##*/fibpacketloss6_}
        V=IPv6
        PARAM="-i 0.1 -c 100"
        ;;
    *packetloss_*)
        PING=ping
        file_host=${0##*/fibpacketloss_}
        V=IPv4
        PARAM="-i 0.1 -c 100 -t 11"
        ;;
esac

host=${file_host:-${host:-127.0.0.1}}
if [ "${HOSTS[$host]}" == "" ]; then
 HOSTS[${host}]=${host}
fi
name=${host}
if [ "${host}" == ".new" ]; then
 PARTS=2
 host="127.0.0.1"
 name="Localhost"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2="::1"
fi
if [ "${host}" == ".localhost" ]; then
 PARTS=2
 host="127.0.0.1"
 name="Localhost"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2="::1"
fi
if [ "${host}" == "nix" ]; then
 PARTS=2
 host=${NIX}
 name="NIX"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2=${NIX6}
fi
if [ "${host}" == "pdns" ]; then
 PARTS=2
 host=${PDNS}
 name="Public DNS"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2=${PDNS6}
fi
if [ "${host}" == "isp" ]; then
 PARTS=2
 host=${MyISP:-127.0.0.1}
 name="ISP"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2=${MyISP6:-\:\:1}
fi
if [ "${host}" == "gw" ]; then
 PARTS=2
 host=${MyGW:-127.0.0.1}
 name="GW"
 V2=IPv6
 PARAM2="-i 0.1 -c 100"
 PING2="ping6"
 host2=${MyGW6:-\:\:1}
fi

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
	echo 'graph_args -l 0'
	echo 'graph_vlabel %'
	echo 'graph_category network'
	echo 'graph_info This graph shows packet loss statistics.'
        for FIB in ${FIBS4}; do
         hcnt=0
         for h in ${host}; do
 	  echo "pl${FIB}a${hcnt}.label ${FIBS[$FIB]} -> ${HOSTS[$h]}"
 	  echo "pl${FIB}a${hcnt}.info FIB ${FIB} (${FIBS[$FIB]}) packet loss to ${h}"
          hcnt=$((${hcnt}+1))
         done
        done
        if [ "${PARTS}" == "2" ]; then
         for FIB in ${FIBS6}; do
          hcnt=0
          for h in ${host2}; do
           echo "pl${FIB}b${hcnt}.label ${FIBS[$FIB]} -> ${HOSTS[$h]}"
           echo "pl${FIB}b${hcnt}.info FIB ${FIB} (${FIBS[$FIB]}) IPv6 packet loss to ${h}"
           hcnt=$((${hcnt}+1))
          done
         done
        fi
        echo "graph_title Packet loss to ${name} (all FIBs)"
	exit 0
fi

for FIB in ${FIBS4}; do
 hcnt=0
 for h in ${host}; do
  /usr/sbin/setfib ${FIB} ${PING:-/sbin/ping} ${PARAM} -q ${h} 2>&1 | /usr/bin/grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed "s/\%//" > ${TEMPFILE}.${FIB}.PLA${hcnt} &
  hcnt=$((${hcnt}+1))
 done
done
if [ "${PARTS}" == "2" ]; then
 hcnt=0
 for FIB in ${FIBS6}; do
  for h in ${host2}; do
   /usr/sbin/setfib ${FIB} ${PING2:-/sbin/ping6} ${PARAM2} -q ${h} 2>&1 | /usr/bin/grep "packet loss" | /usr/bin/awk '{print $7}' | /usr/bin/sed "s/\%//" > ${TEMPFILE}.${FIB}.PLB${hcnt} &
   hcnt=$((${hcnt}+1))
  done
 done
fi
/bin/sleep ${TIMEOUT}

for FIB in ${FIBS4}; do
 hcnt=0
 for h in ${host}; do
  PL=`/usr/bin/tail -n 1 ${TEMPFILE}.${FIB}.PLA${hcnt}`
  echo "pl${FIB}a${hcnt}.value ${PL:-100}"
  /bin/rm -f ${TEMPFILE}.${FIB}.PLA${hcnt}
  hcnt=$((${hcnt}+1))
 done
done
if [ "${PARTS}" == "2" ]; then
 for FIB in ${FIBS6}; do
  hcnt=0
  for h in ${host2}; do
   PL2=`/usr/bin/tail -n 1 ${TEMPFILE}.${FIB}.PLB${hcnt}`
   echo "pl${FIB}b${hcnt}.value ${PL2:-100}"
   /bin/rm -f ${TEMPFILE}.${FIB}.PLB${hcnt}
   hcnt=$((${hcnt}+1))
  done
 done
fi
