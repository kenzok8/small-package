#!/bin/sh

#i=457
#echo $i > /sys/class/gpio/export
#echo "out" > /sys/class/gpio/gpio${i}/direction
	
while true
do
	#echo "1" > /sys/class/gpio/gpio${i}/value
	if [ -f /usr/bin/gpiofind ]; then
		gpioset `gpiofind "watchdog"`=1 2>&1 >/dev/null
	else
		gpioset -t0 watchdog=1 2>&1 >/dev/null
	fi
	sleep 1
	#echo "0" > /sys/class/gpio/gpio${i}/value
	if [ -f /usr/bin/gpiofind ]; then
		gpioset `gpiofind "watchdog"`=0 2>&1 >/dev/null
	else
		gpioset -t0 watchdog=0 2>&1 >/dev/null
	fi
	sleep 1
done