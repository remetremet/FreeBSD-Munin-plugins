#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

DISKID=${MyDISKS:-${hddid:-p1}}

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo 'graph_title Disk free space'
        echo 'graph_args --base 1024 -l 0'
        echo 'graph_vlabel bytes'
        echo 'graph_category disk'
        echo 'graph_info This graph shows disk free in bytes.'
        echo 'graph_total Total'
        cnt=0
        for i in $(/sbin/sysctl -n kern.disks)
        do
         if [[ -e "/dev/${i}${DISKID}" ]] ; then
          echo -n "${i}.label "
          echo ${i}
          echo "${i}.min 0"
          if [ "${cnt}" = "0" ]; then
           echo "${i}.draw AREA"
           cnt=1
          else
           echo "${i}.draw STACK"
          fi
         fi
        done
        exit 0
fi

for i in $(/sbin/sysctl -n kern.disks)
do
   if [[ -e "/dev/${i}${DISKID}" ]] ; then
        size=`/bin/df -P -l -k | grep "/dev/${i}${DISKID}" | /usr/bin/awk '{print $4}'`
        size=`expr ${size:-0} \* 1024`
        echo -n "${i}.value "
        echo ${size:-0}
   fi
done
