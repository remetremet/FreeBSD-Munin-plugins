#!/bin/sh
# -*- sh -*-
#
# Plugin to monitor various statistics exported by a UPS.
#
# Written by Andras Korn in 2005. Licensed under the GPL.
#
# usage: ups_upsid_function
#
#   env.upsc    <command>   (default: "/bin/upsc")
#   env.upsconf <filename>  (default: "/etc/nut/ups.conf")
#
#%# family=contrib
#%# capabilities=autoconf suggest

UPS=$(basename $0 | cut -d_ -f2)
FUNCTION=$(basename $0 | cut -d_ -f3)
UPSC=${upsc:-/usr/local/bin/upsc}
UPSCONF=${upsconf:-/usr/local/etc/nut/ups.conf}

if [ "$1" = "autoconf" ]; then
	[ -x $UPSC ] && [ -r $UPSCONF ] && echo yes && exit 0
	echo "no ($UPSC or $UPSCONF not found)"
	exit 0
fi

if [ "$1" = "suggest" ]; then
	grep '^\[[^]]*\]$' $UPSCONF \
		| tr -d '][' \
		| while read ups; do
			for i in voltages freq charge current; do
				echo ${ups}_${i}
			done
		done
fi


info() {
	$UPSC $UPS | sed -n '/device.mfr/{s/.*: //;p;}
                             /device.model/{s/.*: / /;p;}
                    	    ' | tr -d '\n'
}

voltages() {
	if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " voltages"
		echo "graph_args --base 1000 -l 0"
		echo "graph_vlabel Volt"
		echo "input.label Input"
		echo "input.type GAUGE"
		echo "input.max 260"
		echo "input.min 210"
		echo "output.label Output"
		echo "output.type GAUGE"
		echo "output.max 260"
		echo "output.min 210"
		echo "nominal.label Nominal"
		echo "nominal.type GAUGE"
		echo "nominal.max 260"
		echo "nominal.min 210"
	else
		$UPSC $UPS | sed -n '/output.voltage.nominal/{s/.*:/nominal.value/;p;}
                                     /output.voltage:/{s/.*:/output.value/;p;}
                                     /input.voltage:/{s/.*:/input.value/;p;}
	                     	    '
	fi
}

battery() {
	if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " battery"
		echo "graph_args --base 1000 -l 0"
		echo "graph_vlabel %"
		echo "charge.label Charge"
		echo "charge.type GAUGE"
		echo "charge.max 100"
		echo "charge.min 0"
		echo "voltage.label Voltage"
		echo "voltage.type GAUGE"
		echo "voltage.max 100"
		echo "voltage.min 0"
		echo "nominal.label Nominal"
		echo "nominal.type GAUGE"
		echo "nominal.max 100"
		echo "nominal.min 0"
	else
		$UPSC $UPS | sed -n '/battery.voltage.nominal/{s/.*:/nominal.value/;p;}
                                     /battery.voltage:/{s/.*:/voltage.value/;p;}
                                     /battery.charge:/{s/.*:/charge.value/;p;}
	                     	    '
	fi
}

frequency() {
	if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " frequency"
		echo "graph_args --base 1000 -l 0"
		echo "graph_vlabel frequency 1/s"
		echo "freq.label AC frequency"
		echo "freq.type GAUGE"
		echo "freq.max 60"
		echo "freq.min 40"
	else
		$UPSC $UPS | sed -n '/input.frequency:/{s/.*:/freq.value/;p;}
	                     	    '
	fi
}

current() {
	if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " current"
		echo "graph_args --base 1000 -l 0"
		echo "graph_vlabel Amper"
		echo "input.label Input current"
		echo "input.type GAUGE"
		echo "input.max 16"
		echo "input.min 0"
		echo "output.label Output current"
		echo "output.type GAUGE"
		echo "output.max 16"
		echo "output.min 0"
		echo "pf.label Power Factor"
		echo "pf.type GAUGE"
		echo "pf.max 1"
		echo "pf.min 0"
	else
		$UPSC $UPS | sed -n '/input.current/{s/.*:/input.value/;p;}
                                     /output.current/{s/.*:/output.value/;p;}
                                     /output.powerfactor/{s/.*:/pf.value/;p;}
	                     	    '
	fi
}
time() {
        if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " runtime"
                echo "graph_args --base 1000 -l 0"
                echo "graph_vlabel seconds"
                echo "runtime.label IN"
                echo "runtime.type GAUGE"
                echo "runtime.max 10800"
                echo "runtime.min 0"
        else
		$UPSC $UPS | sed -n '/battery.runtime/{s/.*:/runtime.value/;p;}
	                     	    '
        fi
}
power() {
        if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " power usage"
                echo "graph_args --base 1000 -l 0"
                echo "graph_vlabel Watt / VoltAmpere"
                echo "power.label Power VA"
                echo "power.type GAUGE"
                echo -n "power.max "
		$UPSC $UPS | sed -n '/ups.power.nominal/{s/.*: //;p;}'
                echo "power.min 0"
                echo "realpower.label Power W"
                echo "realpower.type GAUGE"
                echo -n "realpower.max "
		$UPSC $UPS | sed -n '/ups.realpower.nominal/{s/.*: //;p;}'
                echo "realpower.min 0"
        else
		$UPSC $UPS | sed -n '/ups.power:/{s/.*:/power.value/;p;}
                                     /ups.realpower:/{s/.*:/realpower.value/;p;}
                                    '
        fi
}
load() {
        if [ "$1" = "config" ]; then
		echo -n "graph_title "
                info
		echo " load"
                echo "graph_args --base 1000 -l 0"
                echo "graph_vlabel %"
                echo "load.label Load"
                echo "load.type GAUGE"
                echo "load.max 100"
                echo "load.min 0"
                echo "efficiency.label Efficiency"
                echo "efficiency.type GAUGE"
                echo "efficiency.max 100"
                echo "efficiency.min 0"
        else
		$UPSC $UPS | sed -n '/ups.load:/{s/.*:/load.value/;p;}
                                     /ups.efficiency/{s/.*:/efficiency.value/;p;}
                                    '
        fi
}

[ "$1" = "config" ] && echo "graph_category sensors"

case "$FUNCTION" in
	voltages)
		voltages $1
		;;
	battery)
		battery $1
		;;
	freq)
		frequency $1
		;;
	current)
		current $1
		;;
        power)
                power $1
                ;;
        time)
                time $1
                ;;
        load)
                load $1
                ;;
esac

