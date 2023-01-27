#!/bin/sh /etc/rc.common
restart() {
	enabled=$(uci get bandwidthd.@bandwidthd[0].enabled)
	echo $enabled
	if [ ! -z $enabled ] && [ $enabled == "1" ]	
	then 
		/etc/init.d/bandwidthd restart
		/etc/init.d/bandwidthd enable	
	else
		killall bandwidthd
		/etc/init.d/bandwidthd disable
	fi
}