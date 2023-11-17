"use strict";

import { stream_settings } from "../common/stream.mjs";
import { tls_inbound_settings, fallbacks } from "../common/tls.mjs";

function trojan_inbound_user(k) {
    return {
        password: k,
    };
}

export function trojan_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "trojan", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "trojan",
            tag: tag,
            settings: {
                servers: [
                    {
                        address: server["server"],
                        port: int(server["server_port"]),
                        password: server["password"]
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    };
};

export function https_trojan_inbound(proxy, config) {
    return {
        port: proxy["web_server_port"] || 443,
        protocol: "trojan",
        tag: "https_inbound",
        settings: {
            clients: map(proxy["web_server_password"], trojan_inbound_user),
            fallbacks: fallbacks(proxy, config)
        },
        streamSettings: {
            network: "tcp",
            security: proxy["trojan_tls"],
            tlsSettings: proxy["trojan_tls"] == "tls" ? tls_inbound_settings(proxy, "trojan") : null
        }
    };
};
