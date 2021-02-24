#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

DISKID=${MyDISKS:-${hddid:-p1}}

TEMPDIR="/var/munin/smart"
TEMPFILE="${TEMPDIR}/smart"
fts=0
tts=`date +%s`
use=0

if [ ! -e "${TEMPDIR}" ]; then
 mkdir ${TEMPDIR}
 chmod 777 ${TEMPDIR}
fi

if [ "$1" = "autoconf" ]; then
 echo yes
 exit 0
fi

if [ "$1" = "config" ]; then
 echo 'graph_title Spin-up time'
# echo 'graph_args -l 0'
 echo 'graph_category disk'
 echo 'graph_scale no'
 echo 'graph_info This graph shows disk spin-up time in ms.'
 for i in $(/sbin/sysctl -n kern.disks)
 do
  if [[ -e "/dev/${i}${DISKID}" ]] ; then
   if [[ -e "${TEMPFILE}_${i}.info" ]]; then
    fts=`stat -f %m ${TEMPFILE}_${i}.info`
    fts=$((${fts}+3600))        # 15 minutes old file
    if (( ${fts} > ${tts} )); then
     use=1
    else
     fts=$((${fts}+86400))        # 3 hours old file
     if (( ${fts} > ${tts} )); then
      spinning=`/usr/local/sbin/smartctl -i -n never /dev/${i} | grep "Power mode" | awk '{ print $4 }'`
      if [ "${spinning}" = "ACTIVE" ]; then
       use=0
      else
       use=1
      fi
     else
      use=0
     fi
    fi
   fi
   if [ "${use}" = "0" ]; then
    /usr/local/sbin/smartctl -i /dev/${i} > ${TEMPFILE}_${i}.info
   fi
   dn=`/bin/cat ${TEMPFILE}_${i}.info | /usr/bin/awk '/Device Model/{print $0}' | /usr/bin/awk '{print $4}'`
   if [ "${dn:0:2}" = "WD" ]; then
    if [ "${dn:10:1}" = "-" ]; then
     ds=${dn:2:2}
     dt=${dn:6:2}
     case "${ds}" in
      "10") ds="1" ;;
      "20") ds="2" ;;
      "30") ds="3" ;;
      "32") ds="320" ;;
      "40") ds="4" ;;
      "50") ds="5" ;;
      "60") ds="6" ;;
      "64") ds="640" ;;
      "75") ds="750" ;;
      "80") ds="8" ;;
     esac
    fi
    if [ "${dn:9:1}" = "-" ]; then
     ds=${dn:2:2}
     dt=${dn:5:2}
     case "${ds}" in
      "10") ds="10" ;;
      "12") ds="12" ;;
      "14") ds="14" ;;
     esac
    fi
    if [ "${dn:8:1}" = "-" ]; then
     ds=${dn:2:2}
     dt=${dn:4:2}
     case "${ds}" in
      "10") ds="1" ;;
      "20") ds="2" ;;
      "30") ds="3" ;;
      "40") ds="4" ;;
      "50") ds="5" ;;
      "60") ds="6" ;;
      "80") ds="8" ;;
     esac
    fi
    case "${dt}" in
     "EF") dt="Red" ;;
     "FF") dt="RedPro" ;;
     "KF") dt="RedPro" ;;
     "FR") dt="Gold" ;;
     "KR") dt="Gold" ;;
     "FY") dt="Gold" ;;
     "FB") dt="Gold" ;;
     "EA") dt="Green" ;;
     "EZ") dt="Green" ;;
     "BP") dt="Blue" ;;
     "FZ") dt="Black" ;;
     "FA") dt="Black" ;;
    esac
    diskname="WD_${dt} ${ds}"
   else
    if [ "${dn:0:2}" = "ST" ]; then
     ds3=${dn:2:3}
     ds4=${dn:2:4}
     ds5=${dn:2:5}
     dt1=${dn:5:2}
     dt2=${dn:6:2}
     dt3=${dn:7:2}
     case "${ds5}" in
      "10000") ds="10" ;;
      "12000") ds="12" ;;
      "14000") ds="14" ;;
            *)
             case "${ds4}" in
              "8000") ds="8" ;;
              "6000") ds="6" ;;
              "5000") ds="5" ;;
              "4000") ds="4" ;;
              "3000") ds="3" ;;
              "2000") ds="2" ;;
              "1000") ds="1" ;;
                   *)
                    case "${ds3}" in
                     "750") ds="750" ;;
                     "640") ds="640" ;;
                     "500") ds="500" ;;
                     "320") ds="320" ;;
                     "250") ds="250" ;;
                     "160") ds="160" ;;
                    esac
                   ;;
             esac
            ;;
     esac
     case "${dt1}" in
      "DM") dt="BarraCuda" ;;
      "VN") dt="IronWolf" ;;
      "NE") dt="IronWolfPro" ;;
      "AS") dt="Archive" ;;
      "NM") dt="Enterprise" ;;
         *)
          case "${dt2}" in
           "DM") dt="BarraCuda" ;;
           "VN") dt="IronWolf" ;;
           "NE") dt="IronWolfPro" ;;
           "AS") dt="Archive" ;;
           "NM") dt="Enterprise" ;;
              *)
               case "${dt3}" in
                "DM") dt="BarraCuda" ;;
                "VN") dt="IronWolf" ;;
                "NE") dt="IronWolfPro" ;;
                "AS") dt="Archive" ;;
                "NM") dt="Enterprise" ;;
               esac
              ;;
          esac
         ;;
     esac
     diskname="ST_${dt} ${ds}"
    else
     diskname=${dn}
    fi
   fi
   serial=`/bin/cat ${TEMPFILE}_${i}.info | /usr/bin/awk '/Serial Number/{print $0}' | /usr/bin/awk '{print $3}'`
   serial=${serial:(-4)}
   echo "${i}.label ${i}/${diskname} ${serial}"
#   echo "${i}.min 0"
#   echo "${i}.max 60"
#   echo "${i}.warning 1000"  # 5 years of run
#   echo "${i}.critical 5000" # 7 years of run
  fi
 done
 exit 0
fi

for i in $(/sbin/sysctl -n kern.disks)
do
 if [[ -e "/dev/${i}${DISKID}" ]] ; then
  if [[ -e "${TEMPFILE}_${i}.all" ]]; then
   fts=`stat -f %m ${TEMPFILE}_${i}.all`
   fts=$((${fts}+180))        # 15 minutes old file
   if (( ${fts} > ${tts} )); then
    use=1
   else
    fts=$((${fts}+28800))        # 3 hours old file
    if (( ${fts} > ${tts} )); then
     spinning=`/usr/local/sbin/smartctl -i -n never /dev/${i} | grep "Power mode" | awk '{ print $4 }'`
     if [ "${spinning}" = "ACTIVE" ]; then
      use=0
     else
      use=1
     fi
    else
     use=0
    fi
   fi
  fi
  if [ "${use}" = "0" ]; then
   /usr/local/sbin/smartctl -a /dev/${i} > ${TEMPFILE}_${i}.all
  fi
  LASTSTATE=`/bin/cat ${TEMPFILE}_${i}.all | /usr/bin/awk '/Spin_Up_Time/{print $0}' | /usr/bin/awk '{print $10}'`
  echo "${i}.value ${LASTSTATE:-0}"
 fi
done
