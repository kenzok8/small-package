#!/bin/sh
# Author jjm2473@gmail.com

ACTION="${1}"
shift 1

do_install() {
	local id="`uci get shadowrt.@instance[0].id 2>/dev/null`"
	local data="`uci get shadowrt.@instance[0].data 2>/dev/null`"
	local mnt="`uci get shadowrt.@instance[0].mnt 2>/dev/null`"
	local proto=`uci get shadowrt.@instance[0].proto 2>/dev/null`
	local address=`uci get shadowrt.@instance[0].address 2>/dev/null`
	local gateway=`uci get shadowrt.@instance[0].gateway 2>/dev/null`
	local dns="`uci get shadowrt.@instance[0].dns 2>/dev/null`"
	local dhcp_server=`uci get shadowrt.@instance[0].dhcp_server 2>/dev/null`
	local ports="`uci get shadowrt.@instance[0].ports 2>/dev/null`"

	if [ -z "$data" ]; then
		echo "data path is empty!" >&2
		exit 1
	fi

	[ -s /rom/etc/openwrt_release ] || {
		echo "/rom is not a openwrt rootfs!" >&2
		exit 1
	}

	if [ "$proto" = "static" ]; then
		if [ -z "$address" ]; then
			echo "static ip requires address!" >&2
			exit 1
		fi
	fi

	/etc/init.d/docker-lan start || {
		echo "create docker-lan bridge failed!" >&2
		exit 1
	}

	local alpine_image="alpine:3.22.2"
	if ! docker image inspect -f '{}' "$alpine_image" >/dev/null 2>&1; then
		echo "pulling alpine image $alpine_image ..."
		docker pull "$alpine_image" || exit 1
	fi

	if [ -d "$data/$id" ]; then
		echo "WARNING: $data/$id already exists, may use old data." >&2
	fi

	local config="{\"id\":\"$id\",\"data\":\"$data\",\"mnt\":\"$mnt\",\"proto\":\"$proto\",\"address\":\"$address\",\"gateway\":\"$gateway\",\"dns\":\"$dns\",\"dhcp_server\":\"$dhcp_server\",\"ports\":\"$ports\"}"

	local cmd="docker run --restart=unless-stopped -d \
		--stop-signal SIGINT \
		--stop-timeout 30 \
		--security-opt seccomp=unconfined \
		--security-opt apparmor=unconfined \
		--cap-add=SYS_ADMIN \
		--cap-add=SYS_CHROOT \
		--cap-drop=MKNOD \
		--cap-add=LEASE \
		--cap-add=SETGID \
		--cap-add=SETUID \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		--cap-add=NET_BIND_SERVICE \
		--network docker-lan \
		-v /usr/share/shadowrt/container:/shadowrt:ro \
		--entrypoint /shadowrt/entrypoint.sh \
		-v /dev/net:/dev/net \
		--device /dev/fuse:/dev/fuse \
		-v /rom:/rom:ro \
		--label creator=shadowrt \
		--name '$id' \
		--hostname '$id' \
		--label 'com.shadowrt.config=$config' \
		-v '$data/$id/overlay:/overlay:rw' "

	[ -n "$proto" ] && cmd="$cmd -e IP_PROTO=$proto"
	if [ "$proto" = "static" ]; then
		[ -n "$address" ] && cmd="$cmd -e IP_ADDRESS=$address"
		[ -n "$gateway" ] && cmd="$cmd -e IP_GATEWAY=$gateway"
		[ -n "$dns" ] && cmd="$cmd -e 'IP_DNS=$dns'"
	fi
	[ "$dhcp_server" = "1" -o "$dhcp_server" = "on" ] && cmd="$cmd -e DHCP_SERVER=on"
	if [ -n "$ports" ]; then
		for p in $ports; do
			cmd="$cmd -p $p:$p"
		done
	fi
	if [ -n "$dns" ]; then
		for d in $dns; do
			cmd="$cmd --dns $d"
		done
	fi

	local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
	[ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

	if [ "$mnt" = "1" -o "$mnt" = "on" ]; then
		cmd="$cmd -v /mnt:/mnt"
		mountpoint -q /mnt && cmd="$cmd:rshared"
	fi
	cmd="$cmd $alpine_image"

	echo "stopping existing container..."
	docker stop "$id" >/dev/null 2>&1
	docker rm -f "$id"

	echo "starting shadowrt instance $id..."
	echo "$cmd"
	eval "$cmd"

}

do_ls() {
	local name state ip

	echo "["
	docker ps -a -f 'label=creator=shadowrt' --format '{{.Names}} {{.State}}' | sort -n | while read name state; do
		ip=
		if [ "$state" = "running" ]; then
			ip=`docker exec "$name" ip addr show dev br-lan | grep -m1 'inet ' | head -1 | sed -nE 's#.*inet ([0-9\.]*)/([0-9]*) .*#\1#p'`
			if [ -z "$ip" ]; then
				docker exec "$name" test -e /etc/openwrt_release -a ! -e /rom/note || state="starting"
			fi
		fi
		echo '{"name":"'"$name"'","status":"'"$state"'","ip":"'"$ip"'"},'
		#docker container inspect -f '{"name":"'"$name"'","status":"'"$state"'","config":{{index .Config.Labels "com.shadowrt.config"}},"ip":"'"$ip"'"},' "$name"
	done | head -c -2
	echo ""
	echo "]"
}

do_clone() {
	local config_json="`docker container inspect -f '{{index .Config.Labels "com.shadowrt.config"}}' "$1"`"
	[ -z "$config_json" ] && {
		echo "container $1 not found!" >&2
		return 1
	}
	{
		echo "delete shadowrt.@instance[0]"
		echo "add shadowrt instance"
		echo "$config_json" | jsonfilter -e 'id=$.id' \
			-e 'data=$.data' \
			-e 'mnt=$.mnt' \
			-e 'proto=$.proto' \
			-e 'address=$.address' \
			-e 'gateway=$.gateway' \
			-e 'dns=$.dns' \
			-e 'dhcp_server=$.dhcp_server' \
			-e 'ports=$.ports' | sed -e 's/; /\n/g' | sed -e 's/^export /set shadowrt.@instance[0]./g'
		echo "commit shadowrt"
	} | uci batch

	return 0
}

do_reset_network() {
	local name="$1"
	local running=false
	local shell

	docker exec "$name" test -e /etc/openwrt_release -a ! -e /rom/note >/dev/null 2>&1 && running=true
	if $running; then
		shell="exec docker exec -i -w / '$name' /bin/sh"
	else
		docker stop "$name" >/dev/null 2>&1
		local data="`docker container inspect -f '{{index .Config.Labels "com.shadowrt.config"}}' "$name" | jsonfilter -e '$.data'`"
		local dir="$data/$name/overlay/upper"
		[ -d "$dir" ] || return 0
		shell="cd '$dir' && exec /bin/sh"
	fi
	{
		cat <<-EOF
			for f in etc/config/network etc/board.json; do
				rm -f "\$f"
			done
		EOF
		if $running; then
			cat <<-EOF
				/bin/board_detect
				/bin/config_generate
				/bin/sh -c ". /rom/etc/uci-defaults/zzz-dockerenv"
				/bin/sh -c '. /rom/etc/uci-defaults/12_network-generate-ula'
				/etc/init.d/network restart
				sleep 2
			EOF
		else
			echo 'rm -f etc/uci-defaults/zzz-dockerenv etc/uci-defaults/12_network-generate-ula'
		fi
	} | sh -c "$shell"
}

check_all_ready() {
	local names="$1"
	local name
	local ret=0
	for name in $names; do
		if ! docker exec "$name" test -e /etc/openwrt_release -a ! -e /rom/note; then
			ret=1
			break
		fi
	done
	return $ret
}

usage() {
	echo "usage: $0 sub-command"
	echo "where sub-command is one of:"
	echo "      install                    Install/Replace a instance"
	echo "      ls                         List all instances"
	echo "      rm/start/stop/restart {ID} Remove/Start/Stop/Restart the instance"
	echo "      clone {ID}                 Clone an existing instance to uci"
	echo "      rmd {ID}                   Remove an existing instance and its data"
	echo "      reset_network {ID}         Reset network configuration inside the instance"
	echo "      status                     Dummy status for taskd"

}

case "${ACTION}" in
	"install")
		do_install
	;;
	"rm" | "rmd")
		if [ -n "$1" ]; then
			docker stop "$1" >/dev/null 2>&1
			if [ "$ACTION" = "rmd" ]; then
				data="`docker container inspect -f '{{index .Config.Labels "com.shadowrt.config"}}' "$1" | jsonfilter -e '$.data'`"
				[ -n "$data" ] && rm -rf "$data/$1"
			fi
			docker rm -f "$1"
		fi
	;;
	"reset_network")
		if [ -n "$1" ]; then
			do_reset_network "$1"
		fi
	;;
	"start" | "stop" | "restart")
		if [ -n "$1" ]; then
			docker "${ACTION}" $1
			if [ "$ACTION" = "start" -o "$ACTION" = "restart" ]; then
				sleep 2
				for i in $(seq 1 5); do
					check_all_ready "$1" && break
					sleep 1
				done
			fi
		fi
	;;
	"clone")
		if [ -n "$1" ]; then
			do_clone "$1" || exit 1
		fi
	;;
	"status")
		# hack, return empty string, so lib-taskd thinks container is not installed
		exit 0
	;;
	"ls")
		do_ls
	;;
	*)
		usage
		exit 1
	;;
esac
