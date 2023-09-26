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
                handshake: proxy["handshake"] == null ? 4 : int(proxy["handshake"]),
                connIdle: proxy["conn_idle"] == null ? 300 : int(proxy["conn_idle"]),
                uplinkOnly: proxy["uplink_only"] == null ? 2 : int(proxy["uplink_only"]),
                downlinkOnly: proxy["downlink_only"] == null ? 5 : int(proxy["downlink_only"]),
                bufferSize: proxy["buffer_size"] == null ? 4 : int(proxy["buffer_size"]),
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
