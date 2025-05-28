#!/bin/sh
NFTABLES=false

lookup() {
    local MAC=$1
    local IP=$2
    local USERSFILE
    local USER
    for USERSFILE in /tmp/dhcp.leases /tmp/hosts /tmp/dnsmasq.conf /etc/dnsmasq.conf /etc/hosts; do
        [ -e "$USERSFILE" ] || continue
        case $USERSFILE in
        /tmp/dhcp.leases)
            USER=$(grep -i "$MAC" $USERSFILE | cut -f4 -s -d' ')
            ;;
        /etc/hosts)
            USER=$(grep "^$IP " $USERSFILE | cut -f2 -s -d' ')
            ;;
        /tmp/hosts)
            USER=$(grep -rhm1 "^$IP " $USERSFILE | head -1 | cut -f2 -s -d' ')
            ;;
        *)
            USER=$(grep -i "$MAC" "$USERSFILE" | cut -f2 -s -d,)
            ;;
        esac
        [ "$USER" = "*" ] && USER=
        [ -n "$USER" ] && break
    done
    [ -z "$USER" ] && return 1
    echo $USER
}

get_wan_iface() {
    tail -n +2 /proc/net/route | sed -n -e 's/^\([^\t]\+\)\t00000000\t[^\t]\+\t[^\t]\+\t[^\t]\+\t[^\t]\+\t[^\t]\+\t00000000\t.*$/\1/p' | head -1
}

get_arp_excluded() {
    tail -n +2 /proc/net/arp | grep -v " ${1//\./\\\.}\$" | sed -n -e 's/^\([^ ]\+\) \+0x[^ ]\+ \+0x2 \+\([^ ]\+\) .* \([^ ]\+\)$/\1\t\2\t\3/p'
}

enforce_wan_iface() {
    local INTERFACE="$1"
    [[ "$INTERFACE" = "br-lan" ]] && INTERFACE=`uci show network.wan | grep -E 'network\.wan\.(device|ifname)=' | sed -n -e "1s/network\\.wan\\.[^=]\\+='\\([^']\\+\\)'\$/\\1/p"`
    [ -z "$INTERFACE" ] && INTERFACE="/"
    echo "$INTERFACE"
}

merge() {
    local arpfile="$1"
    local countfile="$2"
    local outfile="$3"
    local pkts bytes src dest ip mac iface up down ignored
    while read pkts bytes src dest ignored; do
        if [[ "$dest" = '0.0.0.0/0' ]]; then
            eval "local up_${src//[.:]/_}=\"$pkts,$bytes\""
        else
            eval "local down_${dest//[.:]/_}=\"$pkts,$bytes\""
        fi
    done < "$countfile"
    while read ip mac iface; do
        eval "up=\$up_${ip//[.:]/_}"
        eval "down=\$down_${ip//[.:]/_}"
        printf "%s,%s,%s,%s,%s,%s\n" "$ip" "$mac" "$iface" "${up:-0,0}" "${down:-0,0}" "`lookup $mac $ip`"
    done < "$arpfile" > "$outfile"
}

do_clean() {
    if $NFTABLES; then
        nft delete table rtbwmon 2>/dev/null
    fi
    iptables -t mangle -D FORWARD -j RTBWMON_IFACE 2>/dev/null
    iptables -t mangle -F RTBWMON_IFACE 2>/dev/null
    iptables -t mangle -F RTBWMON_IP 2>/dev/null
    iptables -t mangle -X RTBWMON_IFACE 2>/dev/null
    iptables -t mangle -X RTBWMON_IP 2>/dev/null
    rm -f /var/run/rtbwmon.tmp.* /var/run/rtbwmon.csv
}

do_update() {
    local ip handler
    local INTERFACE="$1"

    find /var/run/rtbwmon.csv -mmin +30 2>/dev/null | grep -q . && do_clean

    if $NFTABLES; then
        nft -f- <<-EOF
table ip rtbwmon {
    chain FORWARD {
        type filter hook forward priority mangle; policy accept;
    }

    chain RTBWMON_IFACE {
    }

    chain RTBWMON_IP {
    }
}
flush chain rtbwmon FORWARD
flush chain rtbwmon RTBWMON_IFACE
table ip rtbwmon {
    chain FORWARD {
        jump RTBWMON_IFACE
    }

    chain RTBWMON_IFACE {
        iifname "$INTERFACE" jump RTBWMON_IP
        oifname "$INTERFACE" jump RTBWMON_IP
    }
}
EOF
    else
        # init iptable
        iptables -t mangle -C FORWARD -j RTBWMON_IFACE 2>/dev/null || {
            iptables -t mangle -N RTBWMON_IFACE 2>/dev/null
            iptables -t mangle -N RTBWMON_IP 2>/dev/null
            iptables -t mangle -I FORWARD -j RTBWMON_IFACE
            # iptables -t mangle -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j RTBWMON_IFACE
        }

        # if interface changed, clean chain
        iptables -t mangle -C RTBWMON_IFACE -o "$INTERFACE" -j RTBWMON_IP 2>/dev/null || {
            iptables -t mangle -F RTBWMON_IP
            iptables -t mangle -F RTBWMON_IFACE
            # iptables -t mangle -A RTBWMON_IFACE -m addrtype --dst-type LOCAL -j RETURN
            iptables -t mangle -A RTBWMON_IFACE -i "$INTERFACE" -j RTBWMON_IP
            iptables -t mangle -A RTBWMON_IFACE -o "$INTERFACE" -j RTBWMON_IP
        }
    fi

    # schedule cleaning task
    /etc/init.d/rtbwmon start

    # save system state
    if $NFTABLES; then
        nft -at list chain rtbwmon RTBWMON_IP | tail -n +3 | grep 'ip ' | sed -n \
            -e 's@^\t\+ip saddr \([0-9.]\+\) counter packets \([0-9]\+\) bytes \([0-9]\+\) return # handle \([0-9]\+\)$@\2 \3 \1 0.0.0.0/0 \4@' \
            -e 's@^\t\+ip daddr \([0-9.]\+\) counter packets \([0-9]\+\) bytes \([0-9]\+\) return # handle \([0-9]\+\)$@\2 \3 0.0.0.0/0 \1 \4@' \
            -e 's/ \+/\t/gp' >/var/run/rtbwmon.tmp.count
    else
        iptables -t mangle -nvxL RTBWMON_IP | tail -n +3 | grep -Fv 'Zeroing chain' | sed -e 's/ \+/\t/g' | cut -f2,3,9,10 >/var/run/rtbwmon.tmp.count
    fi
    get_arp_excluded "$(enforce_wan_iface "$INTERFACE")" >/var/run/rtbwmon.tmp.arp

    # get ip
    cut -f3 /var/run/rtbwmon.tmp.count | grep -Fwv '0.0.0.0/0' >/var/run/rtbwmon.tmp.oips
    cut -f1 /var/run/rtbwmon.tmp.arp >/var/run/rtbwmon.tmp.nips

    # delete offline ip
    if $NFTABLES; then
        { cut -f3,5 /var/run/rtbwmon.tmp.count ; cut -f4,5 /var/run/rtbwmon.tmp.count; } | grep -Fwv '0.0.0.0/0' >/var/run/rtbwmon.tmp.oips-nft
        grep -Fwvf /var/run/rtbwmon.tmp.nips /var/run/rtbwmon.tmp.oips-nft | cut -f2 | while read handler; do
            nft delete rule rtbwmon RTBWMON_IP handle $handler
        done
    else
        grep -Fwvf /var/run/rtbwmon.tmp.nips /var/run/rtbwmon.tmp.oips | while read ip; do
            iptables -t mangle -D RTBWMON_IP -s "$ip" -j RETURN
            iptables -t mangle -D RTBWMON_IP -d "$ip" -j RETURN
        done
    fi

    # add new ip
    if $NFTABLES; then
        {
            echo "table ip rtbwmon {"
            echo "    chain RTBWMON_IP {"
            grep -Fwvf /var/run/rtbwmon.tmp.oips /var/run/rtbwmon.tmp.nips | while read ip; do
                echo "        ip saddr $ip counter return"
                echo "        ip daddr $ip counter return"
            done
            echo "    }"
            echo "}"
        } | nft -f-
    else
        grep -Fwvf /var/run/rtbwmon.tmp.oips /var/run/rtbwmon.tmp.nips | while read ip; do
            iptables -t mangle -A RTBWMON_IP -s "$ip" -j RETURN
            iptables -t mangle -A RTBWMON_IP -d "$ip" -j RETURN
        done
    fi

    merge /var/run/rtbwmon.tmp.arp /var/run/rtbwmon.tmp.count /var/run/rtbwmon.csv

    rm -f /var/run/rtbwmon.tmp.*

    return 0
}

update() {
    local WAN_INTERFACE=`get_wan_iface`

    exec 1000>/var/run/rtbwmon.lock
    flock -n 1000 2>/dev/null || {
        flock 1000 2>/dev/null
        [ -f /var/run/rtbwmon.csv ] && cat /var/run/rtbwmon.csv
        flock -u 1000 2>/dev/null
        return 1
    }

    if [ -z "$WAN_INTERFACE" ]; then
        do_clean
    else
        do_update "$WAN_INTERFACE"
        cat /var/run/rtbwmon.csv
    fi
    flock -u 1000 2>/dev/null
    return 0
}

clean() {
    exec 1000>/var/run/rtbwmon.lock
    flock 1000
    do_clean
    flock -u 1000
}

run_gc() {
    local pid
    exec 1001>/var/run/rtbwmon_gc.lock
    flock -n 1001 2>/dev/null || return 0
    while :; do
        sleep 360 </dev/null >/dev/null 2>&1 1000>/dev/null 1001>/dev/null &
        pid=$!
        trap "kill $pid;trap TERM;kill -TERM $$" TERM
        wait $pid
        trap TERM
        if ! find /var/run/rtbwmon.csv -mmin -5 2>/dev/null | grep -q .; then
            break
        fi
    done
    [ -f /var/run/rtbwmon.csv ] && clean
    flock -u 1001
    return 0
}

show_ifaces() {
    local WAN_INTERFACE=`get_wan_iface`
    [ -z "$WAN_INTERFACE" ] && return 1
    WAN_INTERFACE="$(enforce_wan_iface "$WAN_INTERFACE")"
    ip addr show scope global up | grep '^ \+inet ' | sed -n -e 's/^.* \([^ ]\+\)$/\1/p' | grep -Fxv "$WAN_INTERFACE" | sort -u
}

prerm() {
    # avoid invoke
    chmod 644 /usr/libexec/rtbwmon.sh

    exec 1000>/var/run/rtbwmon.lock
    flock 1000
    sleep 1 </dev/null >/dev/null 2>&1 1000>/dev/null
    do_clean
    flock -u 1000
}

[ -x /sbin/fw4 ] && NFTABLES=true

case $1 in
"clean")
    clean
    ;;
"update")
    update
    ;;
"ifaces")
    show_ifaces
    ;;
"gc")
    run_gc
    ;;
"prerm")
    prerm
    ;;
*)
    echo \
        "Usage: $0 {update|clean|ifaces}
Actions:
   update update and get
   clean clean iptables and temp files
   ifaces show up interfaces
"
    ;;
esac
