#!/bin/sh
# Update all daed subscriptions through dae-wing GraphQL.

LOG="/tmp/luci-app-daede.daed-sub-update.log"
LOCK="/tmp/luci-app-daede.daed-sub-update.lock"

log() {
	echo "$(date '+%F %T') $*" >> "$LOG"
}

fail() {
	local code="$1"; shift
	log "$*"
	echo "$*" >&2
	exit "$code"
}

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

cleanup() {
	[ -n "$TMPDIR" ] && rm -rf "$TMPDIR"
	rmdir "$LOCK" 2>/dev/null
}

if ! mkdir "$LOCK" 2>/dev/null; then
	fail 1 "daed subscription update already running"
fi
trap cleanup EXIT INT TERM

TMPDIR="$(mktemp -d /tmp/daed-sub-update.XXXXXX)" || exit 1

port="$(uci -q get daed.config.listen_addr | sed -n 's/.*:\([0-9]\{1,5\}\)$/\1/p')"
[ -n "$port" ] || port=2023
endpoint="http://127.0.0.1:$port/graphql"

username="$(uci -q get daed.config.dashboard_username)"
password="$(uci -q get daed.config.dashboard_password)"

if [ -z "$username" ] || [ -z "$password" ]; then
	fail 2 "missing daed dashboard username or password"
fi

if ! /bin/pidof daed >/dev/null 2>&1; then
	fail 3 "daed is not running"
fi

post_graphql() {
	local body="$1" outfile="$2" auth="$3"
	if [ -n "$auth" ]; then
		uclient-fetch -q -O "$outfile" \
			--header="Content-Type: application/json" \
			--header="Authorization: Bearer $auth" \
			--post-file="$body" \
			"$endpoint" 2>>"$LOG"
	else
		uclient-fetch -q -O "$outfile" \
			--header="Content-Type: application/json" \
			--post-file="$body" \
			"$endpoint" 2>>"$LOG"
	fi
}

login_body="$TMPDIR/login.json"
login_resp="$TMPDIR/login.out"
printf '{"query":"query Login($username:String!,$password:String!){token(username:$username,password:$password)}","variables":{"username":"%s","password":"%s"}}' \
	"$(json_escape "$username")" "$(json_escape "$password")" > "$login_body"

log "starting daed subscription update"
if ! post_graphql "$login_body" "$login_resp"; then
	fail 4 "login request failed"
fi

token="$(sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$login_resp")"
if [ -z "$token" ]; then
	fail 5 "login failed: $(cat "$login_resp" 2>/dev/null)"
fi

list_body="$TMPDIR/list.json"
list_resp="$TMPDIR/list.out"
printf '{"query":"query Subscriptions{subscriptions{id tag link}}","variables":{}}' > "$list_body"

if ! post_graphql "$list_body" "$list_resp" "$token"; then
	fail 6 "subscription list request failed"
fi
if grep -q '"errors"' "$list_resp"; then
	fail 7 "subscription list failed: $(cat "$list_resp" 2>/dev/null)"
fi

sed 's/"id"/\
"id"/g' "$list_resp" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' > "$TMPDIR/ids"

count="$(grep -c . "$TMPDIR/ids" 2>/dev/null || echo 0)"
if [ "${count:-0}" -eq 0 ]; then
	log "no daed subscriptions to update"
	exit 0
fi

ok=0
fail=0
while IFS= read -r id || [ -n "$id" ]; do
	[ -n "$id" ] || continue
	update_body="$TMPDIR/update.json"
	update_resp="$TMPDIR/update.out"
	printf '{"query":"mutation Update($id:ID!){updateSubscription(id:$id){id tag status}}","variables":{"id":"%s"}}' \
		"$(json_escape "$id")" > "$update_body"
	if post_graphql "$update_body" "$update_resp" "$token" && ! grep -q '"errors"' "$update_resp"; then
		ok=$((ok + 1))
		log "updated subscription $id"
	else
		fail=$((fail + 1))
		log "failed subscription $id: $(cat "$update_resp" 2>/dev/null)"
	fi
done < "$TMPDIR/ids"

log "finished daed subscription update: ok=$ok fail=$fail total=$count"
[ "$fail" -eq 0 ]
