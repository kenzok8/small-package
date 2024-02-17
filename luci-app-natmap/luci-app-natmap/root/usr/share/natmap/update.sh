#!/bin/sh

. /usr/share/libubox/jshn.sh

(
	json_init
	json_add_string ip "$1"
	json_add_int port "$2"
	json_add_int inner_port "$4"
	json_add_string protocol "$5"
	json_add_string name "$GENERAL_NAT_NAME"
	json_dump >/var/run/natmap/$PPID.json
)

echo "natmap update json: $(cat /var/run/natmap/$PPID.json)"

# link setting
[ "${LINK_ENABLE}" == 1 ] && source /usr/share/natmap/link.sh "$@"

# forward setting
[ "${FORWARD_ENABLE}" == 1 ] && source /usr/share/natmap/forward.sh "$@"

# notify setting
[ "${NOTIFY_ENABLE}" == 1 ] && source /usr/share/natmap/notify.sh "$@"

# custom setting
[ "${CUSTOM_SCRIPT_ENABLE}" == 1 ] && [ -n "${CUSTOM_SCRIPT_PATH}" ] && {
	export -n CUSTOM_SCRIPT_PATH
	source "${CUSTOM_SCRIPT_PATH}" "$@"
}
