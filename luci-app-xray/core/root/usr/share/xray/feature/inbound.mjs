"use strict";

import { https_trojan_inbound } from "../protocol/trojan.mjs";
import { https_vless_inbound } from "../protocol/vless.mjs";

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
            timeout: timeout == null ? 300 : int(timeout),
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

export function http_inbound(addr, port, tag) {
    return {
        listen: addr || "0.0.0.0",
        port: port,
        protocol: "http",
        tag: tag,
        settings: {
            allowTransparent: false
        }
    };
};

export function socks_inbound(addr, port, tag) {
    return {
        listen: addr || "0.0.0.0",
        port: port,
        protocol: "socks",
        tag: tag,
        settings: {
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
