#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

DISKID=${HDD_PARTS:-${hddid:-p1}}

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo 'graph_title SSD Life'
#        echo 'graph_args -l 0'
        echo 'graph_category disk'
        echo 'graph_scale no'
        echo 'graph_info This graph shows SSD life expectance.'
        for i in $(/sbin/sysctl -n kern.disks)
        do
         if [[ -e "/dev/${i}" ]] ; then
          Err1=`/usr/local/sbin/smartctl -A /dev/${i} | /usr/bin/awk '/Wear_Range_Delta/{print $0}' | /usr/bin/awk '{print $10}'`
          Err2=`/usr/local/sbin/smartctl -A /dev/${i} | /usr/bin/awk '/SSD_Life_Left/{print $0}' | /usr/bin/awk '{print $10}'`
          if [ -n "${Err1}" ]; then
           if [ -n "${Err2}" ]; then
            echo "wear_${i}.label ${i} W/L"
            echo "wear_$i.min 0"
            echo "wear_$i.max 100"
            echo "wear_${i}.warning 10"
            echo "wear_${i}.critical 50"
            echo "life_${i}.label ${i} Life"
            echo "life_$i.min 0"
            echo "life_$i.max 100"
            echo "life_${i}.warning 10:"
            echo "life_${i}.critical 1:"
           fi
          fi
         fi
        done
        exit 0
fi

for i in $(/sbin/sysctl -n kern.disks)
do
     seagateshit=`/usr/local/sbin/smartctl -i /dev/${i} | grep "Model Family" | grep "Seagate" | wc -l | sed 's/ //g'`
     if [ ${seagateshit} == 0 ]; then
      if [[ -e "/dev/${i}" ]] ; then
       Err1=`/usr/local/sbin/smartctl -A /dev/${i} | /usr/bin/awk '/Wear_Range_Delta/{print $0}' | /usr/bin/awk '{print $10}'`
       Err2=`/usr/local/sbin/smartctl -A /dev/${i} | /usr/bin/awk '/SSD_Life_Left/{print $0}' | /usr/bin/awk '{print $10}'`
       if [ -n "${Err1}" ]; then
        if [ -n "${Err2}" ]; then
         echo "wear_${i}.value ${Err1:-0}"
         echo "life_${i}.value ${Err2:-0}"
        fi
       fi
      fi
     fi
done
