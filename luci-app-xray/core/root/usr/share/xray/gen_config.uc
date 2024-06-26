#!/usr/bin/ucode
"use strict";

import { access } from "fs";
import { load_config } from "./common/config.mjs";
import { bridge_outbounds, bridge_rules, bridges } from "./feature/bridge.mjs";
import { blocked_domain_rules, dns_conf, dns_rules, dns_server_inbounds, dns_server_outbounds, fast_domain_rules, secure_domain_rules } from "./feature/dns.mjs";
import { fake_dns_balancers, fake_dns_conf, fake_dns_rules } from "./feature/fake_dns.mjs";
import { dokodemo_inbound, extra_inbound_balancers, extra_inbound_global, extra_inbound_rules, extra_inbounds, http_inbound, https_inbound, socks_inbound } from "./feature/inbound.mjs";
import { manual_tproxy_outbound_tags, manual_tproxy_outbounds, manual_tproxy_rules } from "./feature/manual_tproxy.mjs";
import { blackhole_outbound, direct_outbound, server_outbound } from "./feature/outbound.mjs";
import { api_conf, balancer, logging, metrics_conf, policy, system_route_rules } from "./feature/system.mjs";

function inbounds(proxy, config, extra_inbound) {
    const tproxy_sniffing = proxy["tproxy_sniffing"];
    const route_only = proxy["route_only"];
    const conn_idle = proxy["conn_idle"];

    let i = [
        socks_inbound("0.0.0.0", proxy["socks_port"] || 1080, "socks_inbound"),
        http_inbound("0.0.0.0", proxy["http_port"] || 1081, "http_inbound"),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_tcp_v4"] || 1082, "tproxy_tcp_inbound_v4", tproxy_sniffing, route_only, ["http", "tls"], "0", "tcp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_tcp_v6"] || 1083, "tproxy_tcp_inbound_v6", tproxy_sniffing, route_only, ["http", "tls"], "0", "tcp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_udp_v4"] || 1084, "tproxy_udp_inbound_v4", tproxy_sniffing, route_only, ["quic"], "0", "udp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_udp_v6"] || 1085, "tproxy_udp_inbound_v6", tproxy_sniffing, route_only, ["quic"], "0", "udp", "tproxy", conn_idle),
        ...extra_inbounds(proxy, extra_inbound),
        ...dns_server_inbounds(proxy),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_tcp_f4"] || 1086, "tproxy_tcp_inbound_f4", "1", "0", ["fakedns"], "1", "tcp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_tcp_f6"] || 1087, "tproxy_tcp_inbound_f6", "1", "0", ["fakedns"], "1", "tcp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_udp_f4"] || 1088, "tproxy_udp_inbound_f4", "1", "0", ["fakedns"], "1", "udp", "tproxy", conn_idle),
        dokodemo_inbound("0.0.0.0", proxy["tproxy_port_udp_f6"] || 1089, "tproxy_udp_inbound_f6", "1", "0", ["fakedns"], "1", "udp", "tproxy", conn_idle),
    ];
    if (proxy["web_server_enable"] == "1") {
        push(i, https_inbound(proxy, config));
    }
    if (proxy["metrics_server_enable"] == '1') {
        push(i, {
            listen: "0.0.0.0",
            port: int(proxy["metrics_server_port"]) || 18888,
            protocol: "dokodemo-door",
            settings: {
                address: "127.0.0.1"
            },
            tag: "metrics"
        });
    }
    if (proxy["xray_api"] == '1') {
        push(i, {
            listen: "127.0.0.1",
            port: 8080,
            protocol: "dokodemo-door",
            settings: {
                address: "127.0.0.1"
            },
            tag: "api"
        });
    }
    return i;
}

function outbounds(proxy, config, manual_tproxy, bridge, extra_inbound, fakedns) {
    let result = [
        blackhole_outbound(),
        direct_outbound("direct", null),
        ...dns_server_outbounds(proxy),
        ...manual_tproxy_outbounds(config, manual_tproxy),
        ...bridge_outbounds(config, bridge)
    ];
    let outbound_balancers_all = {};
    for (let b in ["tcp_balancer_v4", "udp_balancer_v4", "tcp_balancer_v6", "udp_balancer_v6"]) {
        for (let i in balancer(proxy, b, b)) {
            if (i != "direct") {
                outbound_balancers_all[i] = true;
            }
        }
    }
    for (let e in extra_inbound) {
        if (e["specify_outbound"] == "1") {
            for (let i in balancer(e, "destination", `extra_inbound:${e[".name"]}`)) {
                if (i != "direct") {
                    outbound_balancers_all[i] = true;
                }
            }
        }
    }
    for (let f in fakedns) {
        for (let i in balancer(f, "fake_dns_forward_server_tcp", `fake_dns_tcp:${f[".name"]}`)) {
            if (i != "direct") {
                outbound_balancers_all[i] = true;
            }
        }
        for (let i in balancer(f, "fake_dns_forward_server_udp", `fake_dns_udp:${f[".name"]}`)) {
            if (i != "direct") {
                outbound_balancers_all[i] = true;
            }
        }
    }
    for (let i in keys(outbound_balancers_all)) {
        push(result, ...server_outbound(config[substr(i, -9)], i, config));
    }
    return result;
}

function rules(proxy, bridge, manual_tproxy, extra_inbound, fakedns) {
    const geoip_existence = access("/usr/share/xray/geoip.dat") || false;
    const tproxy_tcp_inbound_v4_tags = ["tproxy_tcp_inbound_v4"];
    const tproxy_udp_inbound_v4_tags = ["tproxy_udp_inbound_v4"];
    const tproxy_tcp_inbound_v6_tags = ["tproxy_tcp_inbound_v6"];
    const tproxy_udp_inbound_v6_tags = ["tproxy_udp_inbound_v6"];
    const extra_inbound_global_tags = extra_inbound_global();
    const extra_inbound_global_tcp_tags = extra_inbound_global_tags["tproxy_tcp"] || [];
    const extra_inbound_global_udp_tags = extra_inbound_global_tags["tproxy_udp"] || [];
    const extra_inbound_global_http_tags = extra_inbound_global_tags["http"] || [];
    const extra_inbound_global_socks5_tags = extra_inbound_global_tags["socks5"] || [];
    const built_in_tcp_inbounds = [...tproxy_tcp_inbound_v4_tags, ...extra_inbound_global_tcp_tags, ...extra_inbound_global_http_tags, ...extra_inbound_global_socks5_tags, "socks_inbound", "https_inbound", "http_inbound"];
    const built_in_udp_inbounds = [...tproxy_udp_inbound_v4_tags, ...extra_inbound_global_udp_tags, "dns_conf_inbound"];
    let result = [
        ...fake_dns_rules(fakedns),
        ...manual_tproxy_rules(manual_tproxy),
        ...extra_inbound_rules(extra_inbound),
        ...system_route_rules(proxy),
        ...bridge_rules(bridge),
        ...dns_rules(proxy, [...tproxy_tcp_inbound_v6_tags, ...tproxy_tcp_inbound_v4_tags, ...extra_inbound_global_tcp_tags], [...tproxy_udp_inbound_v6_tags, ...tproxy_udp_inbound_v4_tags, ...extra_inbound_global_udp_tags]),
        ...function () {
            let direct_rules = [];
            if (geoip_existence) {
                if (proxy["geoip_direct_code_list"] != null) {
                    const geoip_direct_code_list = map(proxy["geoip_direct_code_list"] || [], v => index(v, ":") > 0 ? v : `geoip:${v}`);
                    if (length(geoip_direct_code_list) > 0) {
                        push(direct_rules, {
                            type: "field",
                            inboundTag: [...built_in_tcp_inbounds, ...built_in_udp_inbounds],
                            outboundTag: "direct",
                            ip: geoip_direct_code_list
                        });
                    }
                    const geoip_direct_code_list_v6 = map(proxy["geoip_direct_code_list_v6"] || [], v => index(v, ":") > 0 ? v : `geoip:${v}`);
                    if (length(geoip_direct_code_list_v6) > 0) {
                        push(direct_rules, {
                            type: "field",
                            inboundTag: [...tproxy_tcp_inbound_v6_tags, ...tproxy_udp_inbound_v6_tags],
                            outboundTag: "direct",
                            ip: geoip_direct_code_list_v6
                        });
                    }
                }
                push(direct_rules, {
                    type: "field",
                    inboundTag: [...tproxy_tcp_inbound_v6_tags, ...tproxy_udp_inbound_v6_tags, ...built_in_tcp_inbounds, ...built_in_udp_inbounds],
                    outboundTag: "direct",
                    ip: ["geoip:private"]
                });
            }
            return direct_rules;
        }(),
        {
            type: "field",
            inboundTag: tproxy_tcp_inbound_v6_tags,
            balancerTag: "tcp_outbound_v6"
        },
        {
            type: "field",
            inboundTag: tproxy_udp_inbound_v6_tags,
            balancerTag: "udp_outbound_v6"
        },
        {
            type: "field",
            inboundTag: built_in_tcp_inbounds,
            balancerTag: "tcp_outbound_v4"
        },
        {
            type: "field",
            inboundTag: built_in_udp_inbounds,
            balancerTag: "udp_outbound_v4"
        },
    ];
    if (proxy["tproxy_sniffing"] == "1") {
        if (length(secure_domain_rules(proxy)) > 0) {
            splice(result, 0, 0, {
                type: "field",
                inboundTag: [...tproxy_tcp_inbound_v4_tags, ...extra_inbound_global_tcp_tags],
                balancerTag: "tcp_outbound_v4",
                domain: secure_domain_rules(proxy),
            }, {
                type: "field",
                inboundTag: [...tproxy_udp_inbound_v4_tags, ...extra_inbound_global_udp_tags],
                balancerTag: "udp_outbound_v4",
                domain: secure_domain_rules(proxy),
            }, {
                type: "field",
                inboundTag: [...tproxy_tcp_inbound_v6_tags],
                balancerTag: "tcp_outbound_v6",
                domain: secure_domain_rules(proxy),
            }, {
                type: "field",
                inboundTag: [...tproxy_udp_inbound_v6_tags],
                balancerTag: "udp_outbound_v6",
                domain: secure_domain_rules(proxy),
            });
        }
        if (length(blocked_domain_rules(proxy)) > 0) {
            splice(result, 0, 0, {
                type: "field",
                inboundTag: [...tproxy_tcp_inbound_v4_tags, ...tproxy_udp_inbound_v4_tags, ...tproxy_tcp_inbound_v6_tags, ...tproxy_udp_inbound_v6_tags, ...extra_inbound_global_tcp_tags, ...extra_inbound_global_udp_tags],
                outboundTag: "blackhole_outbound",
                domain: blocked_domain_rules(proxy),
            });
        }
        splice(result, 0, 0, {
            type: "field",
            inboundTag: [...tproxy_tcp_inbound_v4_tags, ...tproxy_udp_inbound_v4_tags, ...tproxy_tcp_inbound_v6_tags, ...tproxy_udp_inbound_v6_tags, ...extra_inbound_global_tcp_tags, ...extra_inbound_global_udp_tags],
            outboundTag: "direct",
            domain: fast_domain_rules(proxy)
        });
        if (proxy["direct_bittorrent"] == "1") {
            splice(result, 0, 0, {
                type: "field",
                outboundTag: "direct",
                protocol: ["bittorrent"]
            });
        }
    }
    return result;
}

function balancers(proxy, extra_inbound, fakedns) {
    const general_balancer_strategy = proxy["general_balancer_strategy"] || "random";
    const built_in_outbounds = ["tcp_outbound_v4", "udp_outbound_v4", "tcp_outbound_v6", "udp_outbound_v6"];
    const built_in_balancers = ["tcp_balancer_v4", "udp_balancer_v4", "tcp_balancer_v6", "udp_balancer_v6"];
    return [
        ...map(built_in_balancers, function (balancer_tag, index) {
            return {
                "tag": built_in_outbounds[index],
                "selector": balancer(proxy, balancer_tag, balancer_tag),
                "strategy": {
                    "type": general_balancer_strategy
                }
            };
        }),
        ...extra_inbound_balancers(extra_inbound),
        ...fake_dns_balancers(fakedns),
    ];
};

function observatory(proxy, manual_tproxy) {
    if (proxy["observatory"] == "1") {
        return {
            subjectSelector: ["tcp_balancer_v4@balancer_outbound", "udp_balancer_v4@balancer_outbound", "tcp_balancer_v6@balancer_outbound", "udp_balancer_v6@balancer_outbound", "extra_inbound", "fake_dns", "direct", ...manual_tproxy_outbound_tags(manual_tproxy)],
            probeInterval: "100ms",
            probeUrl: "http://www.apple.com/library/test/success.html"
        };
    }
    return null;
}

function gen_config() {
    const config = load_config();
    const bridge = filter(values(config), v => v[".type"] == "bridge") || [];
    const fakedns = filter(values(config), v => v[".type"] == "fakedns") || [];
    const extra_inbound = filter(values(config), v => v[".type"] == "extra_inbound") || [];
    const manual_tproxy = filter(values(config), v => v[".type"] == "manual_tproxy") || [];

    const general = filter(values(config), k => k[".type"] == "general")[0] || {};
    const custom_configuration_hook = loadstring(general["custom_configuration_hook"] || "return i => i;")();
    return custom_configuration_hook({
        inbounds: inbounds(general, config, extra_inbound),
        outbounds: outbounds(general, config, manual_tproxy, bridge, extra_inbound, fakedns),
        dns: dns_conf(general, config, manual_tproxy, fakedns),
        fakedns: fake_dns_conf(general),
        api: api_conf(general),
        metrics: metrics_conf(general),
        policy: policy(general),
        log: logging(general),
        stats: general["stats"] == "1" ? {
            place: "holder"
        } : null,
        observatory: observatory(general, manual_tproxy),
        reverse: {
            bridges: bridges(bridge)
        },
        routing: {
            domainStrategy: general["routing_domain_strategy"] || "AsIs",
            rules: rules(general, bridge, manual_tproxy, extra_inbound, fakedns),
            balancers: balancers(general, extra_inbound, fakedns)
        }
    });
}

print(gen_config());
