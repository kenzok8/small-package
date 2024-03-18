"use strict";

import { access } from "fs";
import { fake_dns_domains } from "./fake_dns.mjs";
import { direct_outbound } from "./outbound.mjs";

const fallback_fast_dns = "223.5.5.5:53";
const fallback_secure_dns = "8.8.8.8:53";
const fallback_default_dns = "1.1.1.1:53";
const geoip_existence = access("/usr/share/xray/geoip.dat") || false;
const geosite_existence = access("/usr/share/xray/geosite.dat") || false;

function parse_ip_port(val, port_default) {
    const split_dot = split(val, ".");
    if (length(split_dot) > 1) {
        const split_ipv4 = split(val, ":");
        return {
            ip: split_ipv4[0],
            port: int(split_ipv4[1])
        };
    }
    const split_ipv6_port = split(val, "]:");
    if (length(split_ipv6_port) == 2) {
        return {
            ip: ltrim(split_ipv6_port[0], "["),
            port: int(split_ipv6_port[1]),
        };
    }
    return {
        ip: val,
        port: port_default
    };
}

function format_dns(method, val) {
    const parsed = parse_ip_port(val, 53);
    if (method == "udp") {
        return {
            address: parsed["ip"],
            port: parsed["port"]
        };
    }
    let url_suffix = "";
    if (substr(method, 0, 5) == "https") {
        url_suffix = "/dns-query";
    }
    return {
        address: `${method}://${val}${url_suffix}`
    };
}

function domain_rules(proxy, k) {
    if (proxy[k] == null) {
        return [];
    }
    return filter(proxy[k], function (x) {
        if (substr(x, 0, 8) == "geosite:") {
            return geosite_existence;
        }
        return true;
    });
}

export function secure_domain_rules(proxy) {
    return domain_rules(proxy, "forwarded_domain_rules");
};

export function fast_domain_rules(proxy) {
    return domain_rules(proxy, "bypassed_domain_rules");
};

export function blocked_domain_rules(proxy) {
    return domain_rules(proxy, "blocked_domain_rules");
};

export function dns_server_inbounds(proxy) {
    let result = [];
    const dns_port = int(proxy["dns_port"] || 5300);
    const dns_count = int(proxy["dns_count"] || 3);
    const default_dns = format_dns("udp", proxy["default_dns"] || fallback_default_dns);
    for (let i = dns_port; i <= dns_port + dns_count; i++) {
        push(result, {
            port: i,
            protocol: "dokodemo-door",
            tag: sprintf("dns_server_inbound:%d", i),
            settings: {
                address: default_dns["address"],
                port: default_dns["port"],
                network: "tcp,udp"
            }
        });
    }
    return result;
};

export function dns_rules(proxy, tcp_hijack_inbound_tags, udp_hijack_inbound_tags) {
    const dns_port = int(proxy["dns_port"] || 5300);
    const dns_count = int(proxy["dns_count"] || 3);
    let dns_server_tags = [];
    for (let i = dns_port; i <= dns_port + dns_count; i++) {
        push(dns_server_tags, sprintf("dns_server_inbound:%d", i));
    }
    let result = [
        {
            type: "field",
            inboundTag: dns_server_tags,
            outboundTag: "dns_server_outbound"
        },
    ];
    if (proxy.dns_tcp_hijack) {
        push(result, {
            type: "field",
            port: "53",
            inboundTag: tcp_hijack_inbound_tags,
            outboundTag: "dns_tcp_hijack_outbound"
        });
    }
    if (proxy.dns_udp_hijack) {
        push(result, {
            type: "field",
            port: "53",
            inboundTag: udp_hijack_inbound_tags,
            outboundTag: "dns_udp_hijack_outbound"
        });
    }
    return result;
};

export function dns_server_outbounds(proxy) {
    let result = [
        {
            protocol: "dns",
            settings: {
                nonIPQuery: "skip"
            },
            streamSettings: {
                sockopt: {
                    mark: 254
                }
            },
            tag: "dns_server_outbound"
        }
    ];
    if (proxy.dns_tcp_hijack) {
        push(result, direct_outbound("dns_tcp_hijack_outbound", proxy.dns_tcp_hijack));
    }
    if (proxy.dns_udp_hijack) {
        push(result, direct_outbound("dns_udp_hijack_outbound", proxy.dns_udp_hijack));
    }
    return result;
};

export function dns_conf(proxy, config, manual_tproxy, fakedns) {
    const fast_dns_object = format_dns("udp", proxy["fast_dns"] || fallback_fast_dns);
    const default_dns_object = format_dns("udp", proxy["default_dns"] || fallback_default_dns);

    let domain_names_set = {};
    let domain_extra_options = {};

    for (let server in filter(values(config), i => i[".type"] == "servers")) {
        if (iptoarr(server["server"])) {
            continue;
        }
        if (server["domain_resolve_dns"]) {
            domain_extra_options[server["server"]] = `${server["domain_resolve_dns_method"] || "udp"};${server["domain_resolve_dns"]};${join(",", server["domain_resolve_expect_ips"] || [])}`;
        } else {
            domain_names_set[`domain:${server["server"]}`] = true;
        }
    }

    let resolve_merged = {};
    for (let k in keys(domain_extra_options)) {
        const v = domain_extra_options[k];
        let original = resolve_merged[v] || [];
        push(original, `domain:${k}`);
        resolve_merged[v] = original;
    }

    let servers = [
        ...fake_dns_domains(fakedns),
        ...map(keys(resolve_merged), function (k) {
            const dns_split = split(k, ";");
            const resolve_dns_object = format_dns(dns_split[0], dns_split[1]);
            let result = {
                address: resolve_dns_object["address"],
                port: resolve_dns_object["port"],
                domains: uniq(resolve_merged[k]),
                skipFallback: true,
            };
            if (length(dns_split[2]) > 0) {
                const expect_ips = filter(split(dns_split[2], ",") || [], function (i) {
                    if (!geoip_existence) {
                        if (substr(i, 0, 6) === "geoip:") {
                            return false;
                        }
                    }
                    return true;
                });
                result["expectIPs"] = expect_ips;
            }
            return result;
        }),
        default_dns_object,
        {
            address: fast_dns_object["address"],
            port: fast_dns_object["port"],
            domains: [...keys(domain_names_set), ...fast_domain_rules(proxy)],
            skipFallback: true,
        },
    ];

    if (length(secure_domain_rules(proxy)) > 0) {
        const secure_dns_object = format_dns("udp", proxy["secure_dns"] || fallback_secure_dns);
        push(servers, {
            address: secure_dns_object["address"],
            port: secure_dns_object["port"],
            domains: secure_domain_rules(proxy),
        });
    }

    let hosts = {};
    if (length(blocked_domain_rules(proxy)) > 0) {
        for (let rule in (blocked_domain_rules(proxy))) {
            hosts[rule] = ["127.127.127.127", "100::6c62:636f:656b:2164"]; // blocked!
        }
    }

    for (let v in manual_tproxy) {
        if (v.domain_names != null) {
            for (let d in v.domain_names) {
                hosts[d] = [v.source_addr];
            }
        }
    }

    return {
        hosts: hosts,
        servers: servers,
        tag: "dns_conf_inbound",
        queryStrategy: "UseIP"
    };
};

export function dns_direct_servers(config) {
    let result = [];
    for (let server in filter(values(config), i => i[".type"] == "servers")) {
        if (iptoarr(server["server"])) {
            continue;
        }
        if (server["domain_resolve_dns"]) {
            if (index(server["domain_resolve_dns_method"], "local") > 1) {
                push(result, parse_ip_port(server["domain_resolve_dns"])["ip"]);
            }
        }
    }
    return result;
};
