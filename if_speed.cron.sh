#!/usr/local/bin/bash -
. /plugins/_database.new

FIBS4=${MyFIBS:-0}
FIBS4="0 1"
TEMPDIR="/var/munin/if_speed"

if [ ! -e "${TEMPDIR}" ]; then
 mkdir ${TEMPDIR}
 chmod 777 ${TEMPDIR}
fi

now=`date +%s`
for FIB in ${FIBS4}; do
 if [ ! -e "${TEMPDIR}/fib${FIB}.log" ]; then
  fibtime=$(( ${now} - 86400 ))
 else
  fibtime=`stat -f %m ${TEMPDIR}/fib${FIB}.log`
 fi
 fibtime=$(( ${now} - ${fibtime} ))
 if (( ${fibtime} > ${SPEEDTEST_PERIOD[$FIB]} )); then
  setfib ${FIB} speedtest-cli --csv --csv-delimiter ";" ${SPEEDTEST_SERVERS} > ${TEMPDIR}/fib${FIB}.log
  cat ${TEMPDIR}/fib${FIB}.log | sed 's/ /_/g' | sed 's/;/ /g' | awk '{print $7" "$8}' | sed 's/\./ /g' > /tmp/.speedtest
  cat /tmp/.speedtest | awk '{print $1}' > ${TEMPDIR}/fib${FIB}.down
  cat /tmp/.speedtest | awk '{print $3}' > ${TEMPDIR}/fib${FIB}.up
 fi
done
rm -f /tmp/.speedtest
