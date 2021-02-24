#!/usr/local/bin/bash -
. $MUNIN_LIBDIR/plugins/_database.new

FIBS4=${MyFIBS:-0}
FIBS4="0 1"
TEMPDIR="/var/munin/if_speed"

if [ "$1" = "autoconf" ]; then
 echo yes
 exit 0
fi

if [ "$1" = "config" ]; then
 echo "graph_order spd_up spd_down"
 echo "graph_title SpeedTest of all WANs"
 echo "graph_args --base 1000"
 echo "graph_vlabel (+) download / (-) upload"
 echo "graph_category network"
 echo "graph_total Total"
 for FIB in ${FIBS4}; do
  echo "spd_fib${FIB}_up.label ${FIBS[$FIB]}"
  echo "spd_fib${FIB}_up.type GAUGE"
  echo "spd_fib${FIB}_up.graph no"
  echo "spd_fib${FIB}_up.min 0"
  echo "spd_fib${FIB}_down.label ${FIBS[$FIB]}"
  echo "spd_fib${FIB}_down.type GAUGE"
  echo "spd_fib${FIB}_down.negative spd_fib${FIB}_up"
  echo "spd_fib${FIB}_down.min 0"
  echo "spd_fib${FIB}_down.info SpeedTest of download (+) and upload (-) on fib ${FIB}"
 done
 exit 0
fi


for FIB in ${FIBS4}; do
 if [ -e "${TEMPDIR}/fib${FIB}.down" ]; then
  Down=`/bin/cat ${TEMPDIR}/fib${FIB}.down`
  Down=${Down:-0}
 else
  Down=0
 fi
 if [ -e "${TEMPDIR}/fib${FIB}.up" ]; then
  Up=`/bin/cat ${TEMPDIR}/fib${FIB}.up`
  Up=${Up:-0}
 else
  Up=0
 fi
 echo "spd_fib${FIB}_down.value ${Down}"
 echo "spd_fib${FIB}_up.value ${Up}"
done
