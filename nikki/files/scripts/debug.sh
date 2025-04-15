#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

enabled=`uci get nikki.config.enabled`

if [ "$enabled" == "0" ]; then
	uci set nikki.config.enabled=1
	uci commit nikki
	/etc/init.d/nikki restart
fi

echo \
"
# Nikki Debug Info
## system
\`\`\`shell
`
cat /etc/openwrt_release
`
\`\`\`
## kernel
\`\`\`
`
uname -a
`
\`\`\`
## application
\`\`\`
`
if [ -x "/bin/opkg" ]; then
	opkg list-installed "nikki"
	opkg list-installed "luci-app-nikki"
elif [ -x "/usr/bin/apk" ]; then
	apk list -I "nikki"
	apk list -I "luci-app-nikki"
fi
`
\`\`\`
## config
\`\`\`json
`
ucode -S -e '
import { connect } from "ubus";
const ubus = connect();
const config = ubus.call("uci", "get", { "config": "nikki" });
const result = {};
for (let section_id in config.values) {
    const section = config.values[section_id];
    const section_type = section[".type"];
	if (result[section_type] == null) {
		result[section_type] = [];
	}
	push(result[section_type], section);
}
for (let section_type in result) {
	for (let section in result[section_type]) {
		delete section[".anonymous"];
		delete section[".type"];
		delete section[".name"];
		delete section[".index"];
	}
}
for (let x in result["subscription"]) {
	x["url"] = "*";
}
for (let x in result["lan_access_control"]) {
	x["ip"] = "*";
	x["ip6"] = "*";
	x["mac"] = "*";
}
delete result["status"];
delete result["editor"];
delete result["log"];
print(result);
'
`
\`\`\`
## profile
\`\`\`yaml
`
yq -M -P '
. |= (
	select(has("secret")) | .secret = "*" |
	select(has("authentication")) | .authentication = []
) |
.proxy-providers.* |= (
	select(has("url")) |= .url = "*" |
	select(has("payload")) |= .payload[] |= (
		select(has("server")) |= .server = "*" |
		select(has("servername")) |= .servername = "*" |
		select(has("sni")) |= .sni = "*" |
		select(has("port")) |= .port = "*" |
		select(has("ports")) |= .ports = "*" |
		select(has("port-range")) |= .port-range = "*" |
		select(has("uuid")) |= .uuid = "*" |
		select(has("private-key")) |= .private-key = "*" |
		select(has("public-key")) |= .public-key = "*" |
		select(has("token")) |= .token="*" |
		select(has("username")) |= .username = "*" |
		select(has("password")) |= .password = "*" |
		select(has("peers")) |= .peers[] |= (
			select(has("server")) |= .server = "*" |
			select(has("public-key")) |= .public-key = "*"
		)
	)
) |
.proxies[] |= (
	select(has("server")) |= .server = "*" |
	select(has("servername")) |= .servername = "*" |
	select(has("sni")) |= .sni = "*" |
	select(has("port")) |= .port = "*" |
	select(has("ports")) |= .ports = "*" |
	select(has("port-range")) |= .port-range = "*" |
	select(has("uuid")) |= .uuid = "*" |
	select(has("private-key")) |= .private-key = "*" |
	select(has("public-key")) |= .public-key = "*" |
	select(has("token")) |= .token="*" |
	select(has("username")) |= .username = "*" |
	select(has("password")) |= .password = "*" |
	select(has("peers")) |= .peers[] |= (
		select(has("server")) |= .server = "*" |
		select(has("public-key")) |= .public-key = "*"
	)
)
' < /etc/nikki/run/config.yaml
`
\`\`\`
## ip rule
\`\`\`
`
ip rule list
`
\`\`\`
## ip route
\`\`\`
TPROXY: 
`
ip route list table "$TPROXY_ROUTE_TABLE"
`

TUN: 
`
ip route list table "$TUN_ROUTE_TABLE"
`
\`\`\`
## ip6 rule
\`\`\`
`
ip -6 rule list
`
\`\`\`
## ip6 route
\`\`\`
TPROXY: 
`
ip -6 route list table "$TPROXY_ROUTE_TABLE"
`

TUN: 
`
ip -6 route list table "$TUN_ROUTE_TABLE"
`
\`\`\`
## nftables
\`\`\`
`
nft list table inet nikki
`
\`\`\`
## service
\`\`\`json
`
/etc/init.d/nikki info
`
\`\`\`
"

if [ "$enabled" == "0" ]; then
	uci set nikki.config.enabled=0
	uci commit nikki
	/etc/init.d/nikki restart
fi
