#!/bin/sh

if [ "$1" = "autoconf" ]; then
        echo yes
        exit 0
fi

if [ "$1" = "config" ]; then
        echo 'graph_title Disks at work'
        echo 'graph_args -l 0'
        echo 'graph_category disk'
        echo 'graph_scale no'
        echo 'graph_info This graph shows how many disks are spinning.'
        echo -n "hddspin.label "
        echo "Disks spinning"
        echo "hddspin.min 0"
        exit 0
fi

spin=0
for i in $(/sbin/sysctl -n kern.disks)
do
        tests=""
        tests=`/usr/local/sbin/smartctl -i -n standby /dev/${i} | /usr/bin/awk '/Serial Number:/{print $0}' | /usr/bin/awk '{print $3}'`
        if [ "${tests}" != "" ]; then
         spin=`/bin/expr ${spin} + 1`        
        fi
done
echo -n "hddspin.value "
echo ${spin:-0}
