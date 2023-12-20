"use strict";

import { dokodemo_inbound, http_inbound, socks_inbound } from "./inbound.mjs";
import { balancer } from "./system.mjs";

export function extra_inbounds(proxy, extra_inbound) {
    let result = [];
    for (let v in extra_inbound) {
        const tag = `extra_inbound:${v[".name"]}`;
        if (v["inbound_type"] == "http") {
            push(result, http_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag));
        } else if (v["inbound_type"] == "socks5") {
            push(result, socks_inbound(v["inbound_addr"] || "0.0.0.0", v["inbound_port"], tag));
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

export function extra_inbound_global_tcp_tags(extra_inbound) {
    return map(filter(extra_inbound, v => v["specify_outbound"] != "1" && v["inbound_type"] != "tproxy_udp"), v => `extra_inbound_${v[".name"]}`);
};

export function extra_inbound_global_udp_tags(extra_inbound) {
    return map(filter(extra_inbound, v => v["specify_outbound"] != "1" && v["inbound_type"] == "tproxy_udp"), v => `extra_inbound_${v[".name"]}`);
};
