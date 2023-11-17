"use strict";

export function balancer(ref, x, prefix) {
    const v = ref[x] || [];
    if (length(v) == 0) {
        return ["direct"];
    }
    return map(v, (k) => `${prefix}@balancer_outbound:${k}`);
};

export function api_conf(proxy) {
    if (proxy["xray_api"] == '1') {
        return {
            tag: "api",
            services: [
                "HandlerService",
                "LoggerService",
                "StatsService"
            ]
        };
    }
    return null;
};

export function metrics_conf(proxy) {
    if (proxy["metrics_server_enable"] == "1") {
        return {
            tag: "metrics"
        };
    }
    return null;
};

export function policy(proxy) {
    const stats = proxy["stats"] == "1";
    return {
        levels: {
            "0": {
                handshake: int(proxy["handshake"] || 4),
                connIdle: int(proxy["conn_idle"] || 300),
                uplinkOnly: int(proxy["uplink_only"] || 2),
                downlinkOnly: int(proxy["downlink_only"] || 5),
                bufferSize: int(proxy["buffer_size"] || 4),
                statsUserUplink: stats,
                statsUserDownlink: stats,
            }
        },
        system: {
            statsInboundUplink: stats,
            statsInboundDownlink: stats,
            statsOutboundUplink: stats,
            statsOutboundDownlink: stats
        }
    };
};

export function logging(proxy) {
    return {
        access: proxy["access_log"] == "1" ? "" : "none",
        loglevel: proxy["loglevel"] || "warning",
        dnsLog: proxy["dns_log"] == "1"
    };
};

export function system_route_rules(proxy) {
    let result = [];
    if (proxy["xray_api"] == '1') {
        push(result, {
            type: "field",
            inboundTag: ["api"],
            outboundTag: "api"
        });
    }
    if (proxy["metrics_server_enable"] == "1") {
        push(result, {
            type: "field",
            inboundTag: ["metrics"],
            outboundTag: "metrics"
        });
    }
    return result;
};
