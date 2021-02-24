#!/usr/local/bin/bash -
. $MUNIN_LIBDIR/plugins/_database.new

INTERFACE=${0##*if_speed_fib}
INTERFACE=${INTERFACE:-0}
TEMPDIR="/var/munin/if_speed"
if [ "${INTERFACE}" == ".new" ]; then
 INTERFACE="0"
fi

if [ "$1" = "autoconf" ]; then
 echo yes
 exit 0
fi

if [ "$1" = "config" ]; then
 echo "graph_order spd_up spd_down"
 echo "graph_title SpeedTest of ${FIBS[$INTERFACE]}"
 echo "graph_args --base 1000"
 echo "graph_vlabel (+) download / (-) upload"
 echo "graph_category network"
 echo "spd_up.label bps"
 echo "spd_up.type GAUGE"
 echo "spd_up.graph no"
 echo "spd_up.min 0"
 echo "spd_down.label bps"
 echo "spd_down.type GAUGE"
 echo "spd_down.negative spd_up"
 echo "spd_down.min 0"
 echo "spd_down.info Speed of download (+) and upload (-) on the FIB ${INTERFACE} (by Speedtest.net)"
 if [ ! "${warning}" = "" ]; then
  echo "spd_up.warning ${warning}"
  echo "spd_down.warning ${warning}"
 fi
 if [ ! "${critical}" = "" ]; then
  echo "spd_up.critical ${critical}"
  echo "spd_down.critical ${critical}"
 fi
 exit 0
fi


if [ -e "${TEMPDIR}/fib${INTERFACE}.down" ]; then
 Down=`/bin/cat ${TEMPDIR}/fib${INTERFACE}.down`
 Down=${Down:-0}
else
 Down=0
fi
if [ -e "${TEMPDIR}/fib${INTERFACE}.up" ]; then
 Up=`/bin/cat ${TEMPDIR}/fib${INTERFACE}.up`
 Up=${Up:-0}
else
 Up=0
fi
echo "spd_down.value ${Down}"
echo "spd_up.value ${Up}"
