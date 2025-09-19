#!/bin/sh

. /usr/share/libubox/jshn.sh

(
	json_init
	json_add_string ip "$1"
	json_add_int port "$2"
	json_add_int inner_port "$4"
	json_add_string protocol "$5"
	json_add_string name "$NAT_NAME"
	json_dump > /var/run/natmap/$PPID.json
)

[ -n "${NOTIFY_SCRIPT}" ] && {
	export -n NOTIFY_SCRIPT
	source "${NOTIFY_SCRIPT}" "$@"
}

if [ ! -z $INTERNAL_DEFINE_SCRIPT ]; then
	echo "$NAT_NAME Excute internal define script: $INTERNAL_DEFINE_SCRIPT"
	$INTERNAL_DEFINE_SCRIPT "$@"
fi

source /usr/lib/natmap/forward.sh "$@"

source /usr/lib/natmap/notify.sh "$@"