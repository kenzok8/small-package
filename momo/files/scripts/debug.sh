#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

enabled=`uci get momo.config.enabled`

if [ "$enabled" == "0" ]; then
	uci set momo.config.enabled=1
	uci commit momo
	/etc/init.d/momo restart
fi

echo \
"
# Momo Debug Info
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
	opkg list-installed "momo"
	opkg list-installed "luci-app-momo"
elif [ -x "/usr/bin/apk" ]; then
	apk list -I "momo"
	apk list -I "luci-app-momo"
fi
`
\`\`\`
## config
\`\`\`json
`
ucode -S -e '
import { cursor } from "uci";

const uci = cursor();

const config = uci.get_all("momo");
const result = {};

for (let section_id in config) {
	const section = config[section_id];
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
if (exists(result, "subscription")) {
	for (let x in result["subscription"]) {
		if (exists(x, "url")) {
			x["url"] = "*";
		}
	}
}
if (exists(result, "lan_access_control")) {
	for (let x in result["lan_access_control"]) {
		if (exists(x, "ip")) {
			for (let i = 0; i < length(x["ip"]); i++) {
				x["ip"][i] = "*";
			}
		}
		if (exists(x, "ip6")) {
			for (let i = 0; i < length(x["ip6"]); i++) {
				x["ip6"][i] = "*";
			}
		}
		if (exists(x, "mac")) {
			for (let i = 0; i < length(x["mac"]); i++) {
				x["mac"][i] = "*";
			}
		}
	}
}
delete result["placeholder"];
print(result);
'
`
\`\`\`
## profile
\`\`\`json
`
ucode -S -e '
import { readfile } from "fs";

function desensitize_inbounds(inbounds) {
	for (let x in inbounds) {
		if (exists(x, "password")) {
			x["password"] = "*";
		}
		if (exists(x, "users")) {
			x["users"] = "*";
		}
		if (exists(x, "obfs")) {
			if (exists(x["obfs"], "password")) {
				x["obfs"]["password"] = "*";
			}
		}
		if (exists(x, "tls")) {
			if (exists(x["tls"], "server_name")) {
				x["tls"]["server_name"] = "*";
			}
			if (exists(x["tls"], "certificate")) {
				x["tls"]["certificate"] = "*";
			}
			if (exists(x["tls"], "key")) {
				x["tls"]["key"] = "*";
			}
			if (exists(x["tls"], "acme")) {
				x["tls"]["acme"] = {};
			}
			if (exists(x["tls"], "reality")) {
				if (exists(x["tls"]["reality"], "private_key")) {
					x["tls"]["reality"]["private_key"] = "*";
				}
				if (exists(x["tls"]["reality"], "short_id")) {
					x["tls"]["reality"]["short_id"] = "*";
				}
			}
		}
		if (exists(x, "transport")) {
			if (exists(x["transport"], "host")) {
				x["transport"]["host"] = "*";
			}
			if (exists(x["transport"], "path")) {
				x["transport"]["path"] = "*";
			}
			if (exists(x["transport"], "server_name")) {
				x["transport"]["server_name"] = "*";
			}
		}
	}
}

function desensitize_outbounds(outbounds) {
	for (let x in outbounds) {
		if (exists(x, "server")) {
			x["server"] = "*";
		}
		if (exists(x, "server_port")) {
			x["server_port"] = "*";
		}
		if (exists(x, "server_ports")) {
			x["server_port"] = "*";
		}
		if (exists(x, "sni")) {
			x["sni"] = "*";
		}
		if (exists(x, "ports")) {
			x["ports"] = "*";
		}
		if (exists(x, "port-range")) {
			x["port-range"] = "*";
		}
		if (exists(x, "uuid")) {
			x["uuid"] = "*";
		}
		if (exists(x, "private-key")) {
			x["private-key"] = "*";
		}
		if (exists(x, "public-key")) {
			x["public-key"] = "*";
		}
		if (exists(x, "token")) {
			x["token"] = "*";
		}
		if (exists(x, "user")) {
			x["user"] = "*";
		}
		if (exists(x, "username")) {
			x["username"] = "*";
		}
		if (exists(x, "password")) {
			x["password"] = "*";
		}
		if (exists(x, "obfs")) {
			if (exists(x["obfs"], "password")) {
				x["obfs"]["password"] = "*";
			}
		}
		if (exists(x, "tls")) {
			if (exists(x["tls"], "server_name")) {
				x["tls"]["server_name"] = "*";
			}
			if (exists(x["tls"], "certificate")) {
				x["tls"]["certificate"] = "*";
			}
			if (exists(x["tls"], "reality")) {
				if (exists(x["tls"]["reality"], "public_key")) {
					x["tls"]["reality"]["public_key"] = "*";
				}
				if (exists(x["tls"]["reality"], "short_id")) {
					x["tls"]["reality"]["short_id"] = "*";
				}
			}
		}
		if (exists(x, "transport")) {
			if (exists(x["transport"], "host")) {
				x["transport"]["host"] = "*";
			}
			if (exists(x["transport"], "path")) {
				x["transport"]["path"] = "*";
			}
			if (exists(x["transport"], "server_name")) {
				x["transport"]["server_name"] = "*";
			}
		}
	}
}

function desensitize_endpoints(endpoints) {
	for (let x in endpoints) {
		if (exists(x, "private_key")) {
			x["private_key"] = "*";
		}
		if (exists(x, "peers")) {
			for (let y in x["peers"]) {
				if (exists(y, "address")) {
					y["address"] = "*";
				}
				if (exists(y, "port")) {
					y["port"] = "*";
				}
				if (exists(y, "public_key")) {
					y["public_key"] = "*";
				}
				if (exists(y, "pre_shared_key")) {
					y["pre_shared_key"] = "*";
				}
			}
		}
		if (exists(x, "auth_key")) {
			x["auth_key"] = "*";
		}
		if (exists(x, "control_url")) {
			x["control_url"] = "*";
		}
	}
}

function desensitize_profile() {
	const profile = json(readfile("/etc/momo/run/config.json"));
	if (exists(profile, "experimental") && exists(profile["experimental"], "clash_api") && exists(profile["experimental"]["clash_api"], "secret")) {
		profile["secret"] = "*";
	}
	if (exists(profile, "inbounds")) {
		desensitize_inbounds(profile["inbounds"]);
	}
	if (exists(profile, "outbounds")) {
		desensitize_outbounds(profile["outbounds"]);
	}
	if (exists(profile, "endpoints")) {
		desensitize_endpoints(profile["endpoints"]);
	}
	if (exists(profile, "services")) {
		profile["services"] = [];
	}
	return profile;
}

print(desensitize_profile());
'
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
ip route list table "$(uci get momo.routing.tproxy_route_table)"
`

TUN: 
`
ip route list table "$(uci get momo.routing.tun_route_table)"
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
ip -6 route list table "$(uci get momo.routing.tproxy_route_table)"
`

TUN: 
`
ip -6 route list table "$(uci get momo.routing.tun_route_table)"
`
\`\`\`
## firewall tables
\`\`\`
`
nft list tables
`
\`\`\`
## firewall
\`\`\`
`
nft list table inet momo
`
\`\`\`
## service
\`\`\`json
`
/etc/init.d/momo info
`
\`\`\`
"

if [ "$enabled" == "0" ]; then
	uci set momo.config.enabled=0
	uci commit momo
	/etc/init.d/momo restart
fi
