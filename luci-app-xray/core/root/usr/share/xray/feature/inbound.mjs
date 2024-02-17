"use strict";

import { https_trojan_inbound } from "../protocol/trojan.mjs";
import { https_vless_inbound } from "../protocol/vless.mjs";
import { balancer } from "./system.mjs";

export function dokodemo_inbound(listen, port, tag, sniffing, sniffing_route_only, sniffing_dest_override, sniffing_metadata_only, network, tproxy, timeout) {
    let result = {
        port: int(port),
        protocol: "dokodemo-door",
        tag: tag,
        sniffing: sniffing == "1" ? {
            enabled: true,
            routeOnly: sniffing_route_only == "1",
            destOverride: sniffing_dest_override,
            metadataOnly: sniffing_metadata_only == "1"
        } : null,
        settings: {
            network: network,
            followRedirect: true,
            timeout: int(timeout || 300),
        },
        streamSettings: {
            sockopt: {
                tproxy: tproxy
            }
        }
    };
    if (listen) {
        result["listen"] = listen;
    }
    return result;
};

export function http_inbound(addr, port, tag, username, password) {
    let accounts = null;
    if (username && password) {
        accounts = [
            {
                "user": username,
                "pass": password
            }
        ];
    }
    return {
        listen: addr || "0.0.0.0",
        port: port,
        protocol: "http",
        tag: tag,
        settings: {
            accounts: accounts,
            allowTransparent: false
        }
    };
};

export function socks_inbound(addr, port, tag, username, password) {
    let auth = "noauth";
    let accounts = null;
    if (username && password) {
        auth = "password";
        accounts = [
            {
                "user": username,
                "pass": password
            }
        ];
    }
    return {
        listen: addr || "0.0.0.0",
        port: port,
        protocol: "socks",
        tag: tag,
        settings: {
            auth: auth,
            accounts: accounts,
            udp: true
        }
    };
};

export function https_inbound(proxy, config) {
    if (proxy["web_server_protocol"] == "vless") {
        return https_vless_inbound(proxy, config);
    }
    if (proxy["web_server_protocol"] == "trojan") {
        return https_trojan_inbound(proxy, config);
    }
    return null;
};

export function extra_inbounds(proxy, extra_inbound) {
    let result = [];
    for (let v in extra_inbound) {
        const tag = `extra_inbound:${v[".name"]}`;
        if (v["inbound_type"] == "http") {
            push(result, http_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag, v["inbound_username"], v["inbound_password"]));
        } else if (v["inbound_type"] == "socks5") {
            push(result, socks_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag, v["inbound_username"], v["inbound_password"]));
        } else if (v["inbound_type"] == "tproxy_tcp") {
            push(result, dokodemo_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag, proxy["tproxy_sniffing"], proxy["route_only"], ["http", "tls"], "0", "tcp", "tproxy"));
        } else if (v["inbound_type"] == "tproxy_udp") {
            push(result, dokodemo_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag, proxy["tproxy_sniffing"], proxy["route_only"], ["quic"], "0", "udp", "tproxy"));
        } else {
            die(`unknown inbound type ${v["inbound_type"]}`);
        }
    }
    return result;
};

export function extra_inbound_rules(extra_inbound) {
    let result = [];
    for (let v in extra_inbound) {
        if (v["specify_outbound"] == "1") {
            push(result, {
                type: "field",
                inboundTag: [`extra_inbound:${v[".name"]}`],
                balancerTag: `extra_inbound_outbound:${v[".name"]}`
            });
        }
    }
    return result;
};

export function extra_inbound_balancers(extra_inbound) {
    let result = [];
    for (let e in extra_inbound) {
        if (e["specify_outbound"] == "1") {
            push(result, {
                "tag": `extra_inbound_outbound:${e[".name"]}`,
                "selector": balancer(e, "destination", `extra_inbound:${e[".name"]}`),
                "strategy": {
                    "type": e["balancer_strategy"] || "random"
                }
            });
        }
    }
    return result;
};

export function extra_inbound_global(extra_inbound) {
    const global_tags = filter(extra_inbound, v => v["specify_outbound"] != "1");
    return {
        "tproxy_tcp": map(filter(global_tags, v => v["inbound_type"] == "tproxy_tcp"), v => `extra_inbound_${v[".name"]}`),
        "tproxy_udp": map(filter(global_tags, v => v["inbound_type"] == "tproxy_udp"), v => `extra_inbound_${v[".name"]}`),
        "http": map(filter(global_tags, v => v["inbound_type"] == "http"), v => `extra_inbound_${v[".name"]}`),
        "socks5": map(filter(global_tags, v => v["inbound_type"] == "socks5"), v => `extra_inbound_${v[".name"]}`),
    };
};