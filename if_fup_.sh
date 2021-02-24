#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/_database.new

INTERFACE=${0##*if_fup_}
INTERFACE=${INTERFACE:-lo0}
RESET="${resetday:-1}"
NEXT=$(( $RESET + 1 ))
TODAY=`date "+%d"`
TODAY=$(( $TODAY + 0 ))
TEMPDIR="/var/munin/if_fup"
L1=""
L2=""
L3=""
L4=""
if [ "${INTERFACE}" = "${IPFW_LAN1}" ]; then
 L1=${IPFW_LAN1_4IN}
 L2=${IPFW_LAN1_4OUT}
 L3=${IPFW_LAN1_6IN}
 L4=${IPFW_LAN1_6OUT}
fi
if [ "${INTERFACE}" = "${IPFW_LAN2}" ]; then
 L1=${IPFW_LAN2_4IN}
 L2=${IPFW_LAN2_4OUT}
 L3=${IPFW_LAN2_6IN}
 L4=${IPFW_LAN2_6OUT}
fi
if [ "${INTERFACE}" = "${IPFW_LAN3}" ]; then
 L1=${IPFW_LAN3_4IN}
 L2=${IPFW_LAN3_4OUT}
 L3=${IPFW_LAN3_6IN}
 L4=${IPFW_LAN3_6OUT}
fi
if [ "${INTERFACE}" = "${IPFW_WAN1}" ]; then
 L1=${IPFW_WAN1_4IN}
 L2=${IPFW_WAN1_4OUT}
 L3=${IPFW_WAN1_6IN}
 L4=${IPFW_WAN1_6OUT}
fi
if [ "${INTERFACE}" = "${IPFW_WAN2}" ]; then
 L1=${IPFW_WAN2_4IN}
 L2=${IPFW_WAN2_4OUT}
 L3=${IPFW_WAN2_6IN}
 L4=${IPFW_WAN2_6OUT}
fi
if [ "${INTERFACE}" = "${IPFW_WAN3}" ]; then
 L1=${IPFW_WAN3_4IN}
 L2=${IPFW_WAN3_4OUT}
 L3=${IPFW_WAN3_6IN}
 L4=${IPFW_WAN3_6OUT}
fi
if [ "${L1}" = "" ]; then
 INTERFACE="lo0"
 L1=${IPFW_WAN1_4IN}
 L2=${IPFW_WAN1_4OUT}
 L3=${IPFW_WAN1_6IN}
 L4=${IPFW_WAN1_6OUT}
fi
TEMPFILE="${TEMPDIR}/${INTERFACE}"

if [ "$1" = "autoconf" ]; then
 if [ -x /sbin/ipfw ]; then
  echo yes
  exit 0
 else
  echo "no (/sbin/ipfw not found)"
  exit 0
 fi
fi

if [ "$1" = "suggest" ]; then
 if [ -x /sbin/ipfw ]; then
  /usr/bin/netstat -i -b -n | sed -n -e '/^usbus/d' -e '/^ipfw/d' -e '/^wlan/d' -e '/^faith/d' -e '/^lo[0-9]/d' -e '/^pflog/d' -e '/<Link#[0-9]*>/s/\** .*//p'
  exit 0
 else
  exit 1
 fi
fi

if [ "$1" = "config" ]; then
 echo "graph_title Interface ${INTS[$INTERFACE]} FUP"
 echo "graph_args --base 1024
graph_order fupin fupout
graph_vlabel bytes
graph_category network
graph_total Total
fupin.label IN
fupin.info Bytes IN (reseted by $RESET day of month)
fupin.draw AREA
fupout.label OUT
fupout.info Bytes OUT (reseted by $RESET day of month)
fupout.draw STACK"
 if [ ! "${warning}" = "" ]; then
  echo "fupin.warning ${warning}"
  echo "fupout.warning ${warning}"
 fi 
 if [ ! "${critical}" = "" ]; then
  echo "fupin.critical ${critical}"
  echo "fupout.critical ${critical}"
 fi
 exit 0
fi

if [ ! -e "${TEMPDIR}" ]; then
 mkdir ${TEMPDIR}
 chmod 777 ${TEMPDIR}
fi
if [ "${L1}" != "" ]; then
 if [ -e "${TEMPFILE}.LASTIN" ]; then
  LASTIN=`/bin/cat ${TEMPFILE}.LASTIN`
  LASTIN=${LASTIN:-0}
 else
  LASTIN=0
 fi
fi
if [ "${L2}" != "" ]; then
 if [ -e "${TEMPFILE}.LASTOUT" ]; then
  LASTOUT=`/bin/cat ${TEMPFILE}.LASTOUT`
  LASTOUT=${LASTOUT:-0}
 else
  LASTOUT=0
 fi
fi
if [ "${L3}" != "" ]; then
 if [ -e "${TEMPFILE}.LAST2IN" ]; then
  LAST2IN=`/bin/cat ${TEMPFILE}.LAST2IN`
  LAST2IN=${LAST2IN:-0}
 else
  LAST2IN=0
 fi
fi
if [ "${L4}" != "" ]; then
 if [ -e "${TEMPFILE}.LAST2OUT" ]; then
  LAST2OUT=`/bin/cat ${TEMPFILE}.LAST2OUT`
  LAST2OUT=${LAST2OUT:-0}
 else
  LAST2OUT=0
 fi
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
 OLDIN=0
 OLDOUT=0
 WARIN="${WARIN} ResetDay"
 WAROUT="${WAROUT} ResetDay"
 echo "1" > ${TEMPFILE}.RESET
else
 if [ -e "${TEMPFILE}.IN" ]; then
  OLDIN=`/bin/cat ${TEMPFILE}.IN`
  OLDIN=${OLDIN:-0}
 else
  OLDIN=0
  WARIN="${WARIN} NoFile"
 fi
 if [ -e "${TEMPFILE}.OUT" ]; then
  OLDOUT=`/bin/cat ${TEMPFILE}.OUT`
  OLDOUT=${OLDOUT:-0}
 else
  OLDOUT=0
  WAROUT="${WAROUT} NoFile"
 fi
fi
if [ "${L1}" != "" ]; then
 FUPIN=`/sbin/ipfw -a list | grep "${INTERFACE}" | grep "count" | grep " in" | grep "^${L1} " | head -n1 | /usr/bin/awk '{print $3}' `
 FUPIN=${FUPIN:-0}
 echo "${FUPIN}" > ${TEMPFILE}.LASTIN
fi
if [ "${L3}" != "" ]; then
 FUP2IN=`/sbin/ipfw -a list | grep "${INTERFACE}" | grep "count" | grep " in" | grep "^${L3} " | head -n1 | /usr/bin/awk '{print $3}' `
 FUP2IN=${FUP2IN:-0}
 echo "${FUP2IN}" > ${TEMPFILE}.LAST2IN
fi
if [ "${L2}" != "" ]; then
 FUPOUT=`/sbin/ipfw -a list | grep "${INTERFACE}" | grep "count" | grep " out" | grep "^${L2} " | head -n1 | /usr/bin/awk '{print $3}' `
 FUPOUT=${FUPOUT:-0}
 echo "${FUPOUT}" > ${TEMPFILE}.LASTOUT
fi
if [ "${L4}" != "" ]; then
 FUP2OUT=`/sbin/ipfw -a list | grep "${INTERFACE}" | grep "count" | grep " out" | grep "^${L4} " | head -n1 | /usr/bin/awk '{print $3}' `
 FUP2OUT=${FUP2OUT:-0}
 echo "${FUP2OUT}" > ${TEMPFILE}.LAST2OUT
fi

DELTAIN=0
DELTAOUT=0
DELTA2IN=0
DELTA2OUT=0
if (( ${LASTIN}<=${FUPIN} )); then
 DELTAIN=$(( ${FUPIN} - ${LASTIN} ))
else
 DELTAIN="${FUPIN}"
 WARIN="${WARIN} IPFWoverflow"
fi
if [ "${L3}" != "" ]; then
 if (( ${LAST2IN}<=${FUP2IN} )); then
  DELTA2IN=$(( ${FUP2IN} - ${LAST2IN} ))
 else
  DELTA2IN="${FUP2IN}"
  WARIN="${WARIN} IPFWoverflow"
 fi
fi
if (( ${LASTOUT}<=${FUPOUT} )); then
 DELTAOUT=$(( ${FUPOUT} - ${LASTOUT} ))
else
 DELTAOUT="${FUPOUT}"
 WAROUT="${WAROUT} IPFWoverflow"
fi
if [ "${L4}" != "" ]; then
 if (( ${LAST2OUT}<=${FUP2OUT} )); then
  DELTA2OUT=$(( ${FUP2OUT} - ${LAST2OUT} ))
 else
  DELTA2OUT="${FUP2OUT}"
  WAROUT="${WAROUT} IPFWoverflow"
 fi
fi
if (( ${DELTAIN}<0 )); then
 DELTAIN=0
 WARIN="${WARIN} NegativeDelta"
fi
if (( ${DELTAOUT}<0 )); then
 DELTAOUT=0
 WAROUT="${WAROUT} NegativeDelta"
fi
MAXDELTA=3750000000
if (( "${DELTAIN}">"${MAXDELTA}" )); then
 DELTAIN=${MAXDELTA}
 WARIN="${WARIN} DeltaOverMax"
fi
if (( "${DELTAOUT}">"${MAXDELTA}" )); then
 DELTAOUT=${MAXDELTA}
 WAROUT="${WAROUT} DeltaOverMax"
fi
if (( ${DELTA2IN}<0 )); then
 DELTA2IN=0
 WARIN="${WARIN} NegativeDelta"
fi
if (( ${DELTA2OUT}<0 )); then
 DELTA2OUT=0
 WAROUT="${WAROUT} NegativeDelta"
fi
MAXDELTA=3750000000
if (( "${DELTA2IN}">"${MAXDELTA}" )); then
 DELTA2IN=${MAXDELTA}
 WARIN="${WARIN} DeltaOverMax"
fi
if (( "${DELTA2OUT}">"${MAXDELTA}" )); then
 DELTA2OUT=${MAXDELTA}
 WAROUT="${WAROUT} DeltaOverMax"
fi
RESIN=$(( ${OLDIN} + ${DELTAIN} + ${DELTA2IN} ))
RESOUT=$(( ${OLDOUT} + ${DELTAOUT} + ${DELTA2OUT} ))

echo "${RESIN}" > ${TEMPFILE}.IN
echo "${RESOUT}" > ${TEMPFILE}.OUT

WARN=0
if [[ "${WARIN}" != "" ]]; then
 WARN=1
fi
if [[ "${WAROUT}" != "" ]]; then
 WARN=1
fi
if (( ${WARN} == 1 )); then
 date >> ${TEMPFILE}.LOG
 echo "LAST: ${LASTIN}" >> ${TEMPFILE}.LOG
 echo "NOW: ${FUPIN}" >> ${TEMPFILE}.LOG
 echo "DELTA: ${DELTAIN}" >> ${TEMPFILE}.LOG
 echo "LAST2: ${LAST2IN}" >> ${TEMPFILE}.LOG
 echo "NOW2: ${FUP2IN}" >> ${TEMPFILE}.LOG
 echo "DELTA2: ${DELTA2IN}" >> ${TEMPFILE}.LOG
 echo "OLD: ${OLDIN}" >> ${TEMPFILE}.LOG
 echo "RES: ${RESIN}" >> ${TEMPFILE}.LOG
 if [[ "${WARIN}" != "" ]]; then
  echo "WARNING: ${WARIN}" >> ${TEMPFILE}.LOG
 fi
 echo "LAST: ${LASTOUT}" >> ${TEMPFILE}.LOG
 echo "NOW: ${FUPOUT}" >> ${TEMPFILE}.LOG
 echo "DELTA: ${DELTAOUT}" >> ${TEMPFILE}.LOG
 echo "LAST2: ${LAST2OUT}" >> ${TEMPFILE}.LOG
 echo "NOW2: ${FUP2OUT}" >> ${TEMPFILE}.LOG
 echo "DELTA2: ${DELTA2OUT}" >> ${TEMPFILE}.LOG
 echo "OLD: ${OLDOUT}" >> ${TEMPFILE}.LOG
 echo "RES: ${RESOUT}" >> ${TEMPFILE}.LOG
 if [[ "${WAROUT}" != "" ]]; then
  echo "WARNING: ${WAROUT}" >> ${TEMPFILE}.LOG
 fi
 /sbin/ipfw -a list | grep "count" >> ${TEMPFILE}.LOG
 echo "" >> ${TEMPFILE}.LOG
fi

echo "fupin.value ${RESIN}"
echo "fupout.value ${RESOUT}"
