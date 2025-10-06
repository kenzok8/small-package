#!/bin/sh
[ -f "/etc/config/hostnames" ] || {
	echo 'config hostname' > /etc/config/hostnames
}

exit 0
