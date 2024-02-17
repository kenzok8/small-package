"use strict";

import { http_outbound } from "../protocol/http.mjs";
import { shadowsocks_outbound } from "../protocol/shadowsocks.mjs";
import { socks_outbound } from "../protocol/socks.mjs";
import { trojan_outbound } from "../protocol/trojan.mjs";
import { vless_outbound } from "../protocol/vless.mjs";
import { vmess_outbound } from "../protocol/vmess.mjs";

function override_custom_config_recursive(x, y) {
    if (type(x) != "object" || type(y) != "object") {
        return y;
    }
    for (let k in y) {
        x[k] = override_custom_config_recursive(x[k], y[k]);
    }
    return x;
}

function server_outbound_recursive(t, server, tag, config) {
    let outbound_result = null;
    if (server["protocol"] == "vmess") {
        outbound_result = vmess_outbound(server, tag);
    } else if (server["protocol"] == "vless") {
        outbound_result = vless_outbound(server, tag);
    } else if (server["protocol"] == "shadowsocks") {
        outbound_result = shadowsocks_outbound(server, tag);
    } else if (server["protocol"] == "trojan") {
        outbound_result = trojan_outbound(server, tag);
    } else if (server["protocol"] == "http") {
        outbound_result = http_outbound(server, tag);
    } else if (server["protocol"] == "socks") {
        outbound_result = socks_outbound(server, tag);
    }
    if (outbound_result == null) {
        die(`unknown outbound server protocol ${server["protocol"]}`);
    }
    let outbound = outbound_result["outbound"];
    const custom_config_outbound_string = server["custom_config"];

    if (custom_config_outbound_string != null && custom_config_outbound_string != "") {
        const custom_config_outbound = json(custom_config_outbound_string);
        for (let k in custom_config_outbound) {
            if (k == "tag") {
                continue;
            }
            outbound[k] = override_custom_config_recursive(outbound[k], custom_config_outbound[k]);
        }
    }

    const dialer_proxy = outbound_result["dialer_proxy"];
    const result = [...t, outbound];

    if (dialer_proxy != null) {
        const dialer_proxy_section = config[dialer_proxy];
        return server_outbound_recursive(result, dialer_proxy_section, `${tag}@dialer_proxy:${dialer_proxy}`, config);
    }
    return result;
}

export function direct_outbound(tag, redirect) {
    return {
        protocol: "freedom",
        tag: tag,
        settings: {
            domainStrategy: "UseIPv4",
            redirect: redirect || ""
        },
        streamSettings: {
            sockopt: {
                mark: 252,
            }
        }
    };
};

export function blackhole_outbound() {
    return {
        tag: "blackhole_outbound",
        protocol: "blackhole"
    };
};

export function server_outbound(server, tag, config) {
    if (server == null) {
        return [direct_outbound(tag, null)];
    }
    return server_outbound_recursive([], server, tag, config);
};
