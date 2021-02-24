#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

RESET="${resetday:-1}"
NEXT=$(( $RESET + 1 ))
TODAY=`date "+%d"`
TODAY=$(( $TODAY + 0 ))
TEMPDIR="/var/munin/if6_traffic"

if [ "$1" = "autoconf" ]; then
 if [ -x /sbin/ipfw ]; then
  IPFW=0
  I1=0
  I2=0
  I3=0
  I4=0
  if [ "${IPFW_WAN1_4IN}" != "" ]; then
   I1=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_4IN} " | wc -l`
  fi
  if [ "${IPFW_WAN1_4OUT}" != "" ]; then
   I2=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_4OUT} " | wc -l`
  fi
  if [ "${IPFW_WAN1_6IN}" != "" ]; then
   I3=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_6IN} " | wc -l`
  fi
  if [ "${IPFW_WAN1_6OUT}" != "" ]; then
   I4=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_6OUT} " | wc -l`
  fi
  IPFW=$(( $IPFW + $I1 + $I2 + $I3 + $I4  ))
  I1=0
  I2=0
  I3=0
  I4=0
  if [ "${IPFW_WAN2_4IN}" != "" ]; then
   I1=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_4IN} " | wc -l`
  fi
  if [ "${IPFW_WAN2_4OUT}" != "" ]; then
   I2=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_4OUT} " | wc -l`
  fi
  if [ "${IPFW_WAN2_6IN}" != "" ]; then
   I3=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_6IN} " | wc -l`
  fi
  if [ "${IPFW_WAN2_6OUT}" != "" ]; then
   I4=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_6OUT} " | wc -l`
  fi
  IPFW=$(( $IPFW + $I1 + $I2 + $I3 + $I4  ))
  I1=0
  I2=0
  I3=0
  I4=0
  if [ "${IPFW_WAN3_4IN}" != "" ]; then
   I1=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_4IN} " | wc -l`
  fi
  if [ "${IPFW_WAN3_4OUT}" != "" ]; then
   I2=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_4OUT} " | wc -l`
  fi
  if [ "${IPFW_WAN3_6IN}" != "" ]; then
   I3=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_6IN} " | wc -l`
  fi
  if [ "${IPFW_WAN3_6OUT}" != "" ]; then
   I4=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_6OUT} " | wc -l`
  fi
  IPFW=$(( $IPFW + $I1 + $I2 + $I3 + $I4  ))
  if (( ${IPFW} < 4 )); then
   echo "no (no valid count rules in IPFW)"
   exit 0
  else
   echo yes
   exit 0
  fi
 else
  echo "no (/sbin/ipfw not found)"
  exit 0
 fi
fi

if [ "$1" = "config" ]; then
 echo "graph_title Traffic of IPv4/IPv6"
 echo "graph_args --base 1024
graph_order ipv4 ipv6
graph_vlabel bytes from last boot
graph_category network
ipv4.label IPv4
ipv4.draw AREA
ipv6.label IPv6
ipv6.draw STACK"
 exit 0
fi

TEMPFILE="${TEMPDIR}/data"

if [ ! -e "${TEMPDIR}" ]; then
 mkdir ${TEMPDIR}
 chmod 777 ${TEMPDIR}
fi
if [ -e "${TEMPFILE}.LASTV4" ]; then
 LASTV4=`/bin/cat ${TEMPFILE}.LASTV4`
 LASTV4=${LASTV4:-0}
else
 LASTV4=0
fi
if [ -e "${TEMPFILE}.LASTV6" ]; then
 LASTV6=`/bin/cat ${TEMPFILE}.LASTV6`
 LASTV6=${LASTV6:-0}
else
 LASTV6=0
fi
RESETSTATE=0
if [ "${RESET}" = "${TODAY}" ]; then
 if [ -e "${TEMPFILE}.RESET" ]; then
  RESETSTATE=`/bin/cat ${TEMPFILE}.RESET`
  RESETSTATE=${RESETSTATE:-0}
 else
  RESETSTATE=0
 fi
 if [ "${RESETSTATE}" = "0" ]; then
  RESETSTATE=1
 else
  RESETSTATE=0
 fi
else
 if [ "${NEXT}" = "${TODAY}" ]; then
  echo "0" > ${TEMPFILE}.RESET
 fi
fi
if [ "${RESETSTATE}" = "1" ]; then
 OLDV4=0
 OLDV6=0
 echo "1" > ${TEMPFILE}.RESET
else
 if [ -e "${TEMPFILE}.V4" ]; then
  OLDV4=`/bin/cat ${TEMPFILE}.V4`
  OLDV4=${OLDV4:-0}
 else
  OLDV4=0
 fi
 if [ -e "${TEMPFILE}.V6" ]; then
  OLDV6=`/bin/cat ${TEMPFILE}.V6`
  OLDV6=${OLDV6:-0}
 else
  OLDV6=0
 fi
fi
IPv4=0
IPV4A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_4IN} " | /usr/bin/awk '{print $3}' `
IPV4A=${IPV4A:-0}
IPV4B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_4OUT} " | /usr/bin/awk '{print $3}' `
IPV4B=${IPV4B:-0}
IPV4=$(( $IPV4 + $IPV4A + $IPV4B ))
IPV4A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_4IN} " | /usr/bin/awk '{print $3}' `
IPV4A=${IPV4A:-0}
IPV4B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_4OUT} " | /usr/bin/awk '{print $3}' `
IPV4B=${IPV4B:-0}
IPV4=$(( $IPV4 + $IPV4A + $IPV4B ))
IPV4A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_4IN} " | /usr/bin/awk '{print $3}' `
IPV4A=${IPV4A:-0}
IPV4B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_4OUT} " | /usr/bin/awk '{print $3}' `
IPV4B=${IPV4B:-0}
IPV4=$(( $IPV4 + $IPV4A + $IPV4B ))
IPV6=0
IPV6A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_6IN} " | /usr/bin/awk '{print $3}' `
IPV6A=${IPV6A:-0}
IPV6B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN1_6OUT} " | /usr/bin/awk '{print $3}' `
IPV6B=${IPV6B:-0}
IPV6=$(( $IPV6 + $IPV6A + $IPV6B ))
IPV6A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_6IN} " | /usr/bin/awk '{print $3}' `
IPV6A=${IPV6A:-0}
IPV6B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN2_6OUT} " | /usr/bin/awk '{print $3}' `
IPV6B=${IPV6B:-0}
IPV6=$(( $IPV6 + $IPV6A + $IPV6B ))
IPV6A=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_6IN} " | /usr/bin/awk '{print $3}' `
IPV6A=${IPV6A:-0}
IPV6B=`/sbin/ipfw -a list | grep "count" | grep "^${IPFW_WAN3_6OUT} " | /usr/bin/awk '{print $3}' `
IPV6B=${IPV6B:-0}
IPV6=$(( $IPV6 + $IPV6A + $IPV6B ))

echo "${IPV4}" > ${TEMPFILE}.LASTV4
echo "${IPV6}" > ${TEMPFILE}.LASTV6

if (( ${LASTV4}<=${IPV4} )); then
 DELTAV4=$(( ${IPV4} - ${LASTV4} ))
else
 DELTAV4="${IPV4}"
fi
if (( ${LASTV6}<=${IPV6} )); then
 DELTAV6=$(( ${IPV6} - ${LASTV6} ))
else
 DELTAV6="${IPV6}"
fi
RESV4=$(( $OLDV4 + $DELTAV4 ))
RESV6=$(( $OLDV6 + $DELTAV6 ))

echo "${RESV4}" > ${TEMPFILE}.V4
echo "${RESV6}" > ${TEMPFILE}.V6

echo "ipv4.value ${RESV4}"
echo "ipv6.value ${RESV6}"
