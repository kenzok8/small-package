"use strict";

import { server_outbound } from "./outbound.mjs";

function manual_tproxy_redirect(v) {
    return sprintf("%s:%d", v["dest_addr"] || "", v["dest_port"] || 0);
}

function manual_tproxy_outbound_tag(v, name) {
    return `manual_tproxy:${v[".name"]}@${name}`;
}

function manual_tproxy_force_forward_tag(v, name, force_forward_key, server_key) {
    if (v[force_forward_key] !== "1" || v[server_key] == null) {
        return null;
    }
    return `manual_tproxy:${v[".name"]}@${name}@force_forward:${v[server_key]}`;
}

function manual_tproxy_needs_dialer_proxy(v, force_forward_key, server_key) {
    if (v[force_forward_key] !== "1") {
        return true;
    }
    if (v[server_key] == null) {
        return true;
    }
    if (manual_tproxy_redirect(v) !== ":0") {
        return true;
    }
    return false;
}

function manual_tproxy_outbound(config, v, name, force_forward_key, server_key) {
    const force_forward_tag = manual_tproxy_force_forward_tag(v, name, force_forward_key, server_key);
    let result = [];
    if (force_forward_tag != null) {
        push(result, ...server_outbound(config[v[server_key]], force_forward_tag, config));
    }
    if (manual_tproxy_needs_dialer_proxy(v, force_forward_key, server_key)) {
        push(result, {
            protocol: "freedom",
            tag: manual_tproxy_outbound_tag(v, name),
            settings: {
                redirect: manual_tproxy_redirect(v),
                domainStrategy: "AsIs"
            },
            streamSettings: {
                sockOpt: {
                    dialerProxy: force_forward_tag != null ? force_forward_tag : "direct"
                }
            }
        });
    }
    return result;
}

function manual_tproxy_rule_tag(v, name, force_forward_key, server_key) {
    if (manual_tproxy_needs_dialer_proxy(v, force_forward_key, server_key)) {
        return manual_tproxy_outbound_tag(v, name);
    }
    return manual_tproxy_force_forward_tag(v, name, force_forward_key, server_key);
}

export function manual_tproxy_outbounds(config, manual_tproxy) {
    let result = [];
    for (let v in manual_tproxy) {
        push(result, ...manual_tproxy_outbound(config, v, "tcp_outbound", "force_forward_tcp", "force_forward_server_tcp"));
        push(result, ...manual_tproxy_outbound(config, v, "udp_outbound", "force_forward_udp", "force_forward_server_udp"));
    }
    return result;
};

export function manual_tproxy_outbound_tags(manual_tproxy) {
    let result = [];
    for (let v in manual_tproxy) {
        const tcp_tag = manual_tproxy_force_forward_tag(v, "tcp_outbound", "force_forward_tcp", "force_forward_server_tcp");
        if (tcp_tag != null) {
            push(result, tcp_tag);
        }
        const udp_tag = manual_tproxy_force_forward_tag(v, "udp_outbound", "force_forward_udp", "force_forward_server_udp");
        if (udp_tag != null) {
            push(result, udp_tag);
        }
    }
    return result;
};

export function manual_tproxy_rules(manual_tproxy) {
    let result = [];
    for (let v in manual_tproxy) {
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_tcp_inbound_v4", "tproxy_tcp_inbound_v6", "socks_inbound", "https_inbound", "http_inbound"],
            ip: [v["source_addr"]],
            port: v["source_port"],
            outboundTag: manual_tproxy_rule_tag(v, "tcp_outbound", "force_forward_tcp", "force_forward_server_tcp")
        });
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_udp_inbound_v4", "tproxy_udp_inbound_v6"],
            ip: [v["source_addr"]],
            port: v["source_port"],
            outboundTag: manual_tproxy_rule_tag(v, "udp_outbound", "force_forward_udp", "force_forward_server_udp")
        });
    }
    return result;
};
