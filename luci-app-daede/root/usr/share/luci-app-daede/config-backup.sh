#!/bin/sh
# config-backup.sh export|import — back up/restore the whole daede config
# (dae + daed + active backend). export: prints base64(tar.gz) to stdout.
# import: decodes /tmp/daede-import.b64, validates, restores, restarts backend.
set -eu

ACTION="${1:-}"
LOG="/tmp/luci-app-daede.backup.log"
IMPORT_B64="/tmp/daede-import.b64"
MAX_TAR=184320   # 180 KiB tar.gz -> ~240 KiB base64, under the ubus limit

# relative paths (no leading /) so tar entries match the extraction whitelist
WHITELIST="etc/config/dae etc/config/daed etc/config/daede etc/dae/config.dae etc/daed/wing.db"

b64enc() { ucode -e 'let f=require("fs"); print(b64enc(f.open(ARGV[0],"r").read("all")));' -- "$1"; }
b64dec() { ucode -e 'let f=require("fs"); let r=b64dec(trim(f.open(ARGV[0],"r").read("all"))); if(!r)exit(1); let o=f.open(ARGV[1],"w"); o.write(r); o.close();' -- "$1" "$2"; }

case "$ACTION" in
export)
	exist=""
	for p in $WHITELIST; do [ -e "/$p" ] && exist="$exist $p"; done
	[ -n "$exist" ] || { echo "no config to back up" >&2; exit 1; }
	tmp="$(mktemp)"
	( cd / && tar -czf "$tmp" $exist ) 2>/dev/null || { rm -f "$tmp"; echo "tar failed" >&2; exit 1; }
	if [ "$(wc -c < "$tmp")" -gt "$MAX_TAR" ]; then
		rm -f "$tmp"; echo "config too large; use System Backup instead" >&2; exit 2
	fi
	b64enc "$tmp"
	rm -f "$tmp"
	;;

import)
	[ -f "$IMPORT_B64" ] || { echo "no upload found" >&2; exit 1; }
	(
		exec >"$LOG" 2>&1
		echo "$(date '+%F %T') begin import"
		rc=0
		tmp="$(mktemp)"
		if ! b64dec "$IMPORT_B64" "$tmp"; then
			echo "decode failed"; rc=1
		elif ! gzip -t "$tmp" 2>/dev/null; then
			echo "not a valid backup archive"; rc=1
		else
			# reject any entry outside the whitelist (path-traversal guard)
			bad="$(tar -tzf "$tmp" 2>/dev/null | grep -vxE 'etc/config/dae|etc/config/daed|etc/config/daede|etc/dae/config\.dae|etc/daed/wing\.db' | head -1)"
			if [ -n "$bad" ]; then
				echo "rejected: unexpected entry '$bad'"; rc=1
			else
				ab="$(uci -q get daede.config.active_backend || echo dae)"
				[ -x "/etc/init.d/$ab" ] && /etc/init.d/"$ab" stop 2>/dev/null || true
				if ( cd / && tar -xzf "$tmp" ); then
					echo "restored config"
				else
					echo "extract failed"; rc=1
				fi
				ab="$(uci -q get daede.config.active_backend || echo "$ab")"
				[ -x "/etc/init.d/$ab" ] && { /etc/init.d/"$ab" enabled || /etc/init.d/"$ab" enable; /etc/init.d/"$ab" restart 2>/dev/null || /etc/init.d/"$ab" start 2>/dev/null; } || true
			fi
		fi
		rm -f "$tmp" "$IMPORT_B64"
		if [ "$rc" = 0 ]; then echo "result: config restored, backend restarted"; else echo "result: import failed"; fi
		echo "$(date '+%F %T') done (rc=$rc)"
	) </dev/null >/dev/null 2>&1 &
	echo "started in background, see $LOG"
	;;

*)
	echo "usage: $0 export|import" >&2
	exit 64
	;;
esac
