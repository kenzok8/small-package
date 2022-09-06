#!/bin/sh

if [ -z "$ACTION" ]; then
log() {
    echo "$*" >&2
}
else
log() {
    logger -t "blockmount" "$*"
}
fi

# uci_section UUID LABEL DEVICE MOUNTPOINT
check_mount() {
    local uuid
    local label
    local device
    local target
    config_get uuid $1 uuid
    config_get label $1 label
    config_get device $1 device
    config_get target $1 target

    if [ "$DEVICE_CONFIGURED" = "0" -a \( "$uuid" = "$2" -o \( -n "$3" -a "$3" = "$label" \) -o \( -n "$4" -a "$4" = "$device" \) \) ]; then
        export -n DEVICE_CONFIGURED=1
        [ -z "$ACTION" ] && log "found $1 ($uuid, $label, $device) match $2 $3 $4"
    fi
}

# UUID LABEL DEVICE MOUNTPOINT
check_configured() {
    local DEVICE_CONFIGURED=0
    config_foreach check_mount mount "$1" "$2" "$3" "$4"
    return $DEVICE_CONFIGURED
}

handle_part() {
    [ -z "$ACTION" ] && log "$1 UUID=$UUID TYPE=$TYPE LABEL=$LABEL MOUNT=$MOUNT"
    [ -n "$1" ] || return 1

    # ignore mounted device, unknown fs type, swap or raid member
    [ -n "$MOUNT" -o -z "$UUID" -o -z "$TYPE" \
        -o "$TYPE" = "swap" \
        -o "$TYPE" = "linux_raid_member" \
    ] && return 0

    local DEVICENAME="${1#/dev/}"
    local candidate="`/usr/sbin/blockphy.sh "$DEVICENAME"`"
    [ -z "$candidate" ] && return 0
    candidate="/mnt/$candidate"

    # check if candidate mount point is busy
    mountpoint -q "$candidate" && return 0

    # check if configured
    check_configured "$UUID" "$LABEL" "$1" "$candidate" || return 0

    log "add mount $UUID => $candidate"

    uci -q batch <<-EOF >/dev/null
        add fstab mount
        set fstab.@mount[-1].uuid=$UUID
        set fstab.@mount[-1].target=$candidate
        set fstab.@mount[-1].enabled=1
EOF

}

scan_all() {
    local line
    block info | while read; do
        line="$REPLY"
        eval "${line##*: } handle_part ${line%%: *}"
    done
}

. /lib/functions.sh

config_load fstab

scan_all

uci commit fstab
