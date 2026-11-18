# 由 postinst-pkg source，保证恢复先于默认 start；exit 只退出子 shell。
[ -n "${IPKG_INSTROOT}" ] && exit 0
P=/etc/.honk-preupgrade
pending=$(cat "$P/pending" 2>/dev/null)
case "$pending" in ''|*[!0-9a-f]*) exit 0 ;; esac
[ "${#pending}" -eq 32 ] || exit 0
d="$P/txn-$pending"
[ -d "$d" ] && [ -f "$d/manifest" ] || { rm -f "$P/pending"; exit 0; }
getv() { sed -n "s/^$1=//p" "$d/manifest" 2>/dev/null | head -n 1; }
[ "$(getv format)" = 1 ] || { rm -f "$P/pending"; exit 0; }
[ "$(getv state)" = ready ] || { rm -f "$P/pending"; exit 0; }
if [ -f /lib/apk/db/installed ]; then
	mtxnid=$(getv apk_txnid)
	bid=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)
	rest=$(sed 's/^[0-9]* (.*) //' "/proc/$PPID/stat" 2>/dev/null)
	st=$(printf '%s\n' "$rest" | awk '{print $20}')
	case "$bid" in ''|*[!0-9a-f-]*) bid= ;; esac
	case "$st" in ''|*[!0-9]*) st= ;; esac
	cid=
	[ -n "$bid" ] && [ -n "$st" ] && cid="$bid:$PPID:$st"
	[ -n "$mtxnid" ] && [ -n "$cid" ] && [ "$mtxnid" = "$cid" ] || { rm -f "$P/pending"; exit 0; }
fi
csha=$(getv config_sha256)
ssha=$(getv system_sha256)
saved=$(getv saved_at)
case "$saved" in ''|*[!0-9]*) rm -f "$P/pending"; exit 0 ;; esac
delta=$(( $(date +%s) - saved ))
[ "$delta" -ge 0 ] && [ "$delta" -le 900 ] || { rm -f "$P/pending"; exit 0; }
[ -f "$d/config.dae" ] || { rm -f "$P/pending"; exit 0; }
[ "$(sha256sum "$d/config.dae" 2>/dev/null | awk '{print $1}')" = "$csha" ] || { rm -f "$P/pending"; exit 0; }
pidof honk-core >/dev/null 2>&1 && { rm -f "$P/pending"; exit 0; }
cur=$(sha256sum /etc/honk/config.dae 2>/dev/null | awk '{print $1}')
[ "$cur" = "$csha" ] && { rm -f "$P/pending"; rm -rf "$d"; exit 0; }
def=$(sha256sum /usr/share/honk/default-config.dae 2>/dev/null | awk '{print $1}')
[ -n "$def" ] && [ "$cur" = "$def" ] || { rm -f "$P/pending"; exit 0; }
if [ "$ssha" = absent ]; then
	[ -e /etc/honk/system.dae ] && { rm -f "$P/pending"; exit 0; }
else
	[ "$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')" = "$ssha" ] || { rm -f "$P/pending"; exit 0; }
fi
# 候选放在 /etc/honk 内且保留 .dae 后缀，include { system.dae } 才能解析
tmpcand=$(mktemp /etc/honk/.candidate.XXXXXX) || { rm -f "$P/pending"; exit 0; }
cand="$tmpcand.dae"
if ! mv -f "$tmpcand" "$cand" || ! cp -p "$d/config.dae" "$cand" || ! chmod 0600 "$cand"; then
	rm -f "$tmpcand" "$cand"; rm -f "$P/pending"
	logger -t honk "preupgrade restore: candidate write failed"
	exit 0
fi
cand_ok=1
[ "$(sha256sum "$cand" 2>/dev/null | awk '{print $1}')" = "$csha" ] || cand_ok=0
if [ "$cand_ok" = 1 ]; then
	/usr/bin/honk-core config validate --config "$cand" >/dev/null 2>&1 || cand_ok=0
fi
if [ "$cand_ok" != 1 ]; then
	rm -f "$cand"; rm -f "$P/pending"
	logger -t honk "preupgrade restore: candidate validation failed, nothing replaced"
	exit 0
fi
# 替换前重查：核心进程、当前主配置、关联文件
sys_changed=0
if [ "$ssha" = absent ]; then
	[ -e /etc/honk/system.dae ] && sys_changed=1
else
	[ "$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')" != "$ssha" ] && sys_changed=1
fi
if pidof honk-core >/dev/null 2>&1 ||
	[ "$(sha256sum /etc/honk/config.dae 2>/dev/null | awk '{print $1}')" != "$cur" ] ||
	[ "$sys_changed" = 1 ]; then
	rm -f "$cand"; rm -f "$P/pending"
	logger -t honk "preupgrade restore: state changed before replace"
	exit 0
fi
orig_sha="$cur"
snapshot_ok=0
if cp -p /etc/honk/config.dae "$d/pre-restore.dae" 2>/dev/null &&
	[ "$(sha256sum "$d/pre-restore.dae" 2>/dev/null | awk '{print $1}')" = "$orig_sha" ]; then
	snapshot_ok=1
fi
if [ "$snapshot_ok" != 1 ]; then
	rm -f "$cand" "$d/pre-restore.dae"; rm -f "$P/pending"
	logger -t honk "preupgrade restore: cannot snapshot current config"
	exit 0
fi
if mv -f "$cand" /etc/honk/config.dae &&
	[ "$(sha256sum /etc/honk/config.dae 2>/dev/null | awk '{print $1}')" = "$csha" ]; then
	rm -f "$P/pending"
	rm -rf "$d"
	logger -t honk "preupgrade restore: previous config restored"
	exit 0
fi
rm -f "$cand"
rb=$(mktemp /etc/honk/.rollback.XXXXXX)
if [ -n "$rb" ] && cp -p "$d/pre-restore.dae" "$rb" 2>/dev/null && chmod 0600 "$rb" 2>/dev/null && mv -f "$rb" /etc/honk/config.dae 2>/dev/null; then
	if [ "$(sha256sum /etc/honk/config.dae 2>/dev/null | awk '{print $1}')" = "$orig_sha" ]; then
		logger -t honk "preupgrade restore: replace mismatch, rolled back"
	else
		logger -t honk "preupgrade restore: replace mismatch, rollback hash mismatch"
	fi
else
	logger -t honk "preupgrade restore: replace mismatch, rollback write failed"
fi
rm -f "$rb"
rm -f "$P/pending"
exit 0
