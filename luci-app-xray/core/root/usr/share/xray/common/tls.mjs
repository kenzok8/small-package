"use strict";

export function fallbacks(proxy, config) {
    const fallback = filter(keys(config), k => config[k][".type"] == "fallback") || [];
    let f = [];
    for (let key in fallback) {
        const s = config[key];
        if (s["dest"] != null) {
            push(f, {
                dest: s["dest"],
                alpn: s["alpn"],
                name: s["name"],
                xver: s["xver"],
                path: s["path"]
            });
        }
    }
    push(f, {
        dest: proxy["web_server_address"]
    });
    return f;
};

export function tls_outbound_settings(server, protocol) {
    let result = {
        serverName: server[protocol + "_tls_host"],
        allowInsecure: server[protocol + "_tls_insecure"] != "0",
        fingerprint: server[protocol + "_tls_fingerprint"] || ""
    };

    if (server[protocol + "_tls_alpn"] != null) {
        result["alpn"] = server[protocol + "_tls_alpn"];
    }

    return result;
};

export function tls_inbound_settings(proxy, protocol_name) {
    let wscert = proxy[protocol_name + "_tls_cert_file"];
    if (wscert == null) {
        wscert = proxy["web_server_cert_file"];
    }
    let wskey = proxy[protocol_name + "_tls_key_file"];
    if (wskey == null) {
        wskey = proxy["web_server_key_file"];
    }
    return {
        alpn: [
            "http/1.1"
        ],
        certificates: [
            {
                certificateFile: wscert,
                keyFile: wskey
            }
        ]
    };
};

export function reality_outbound_settings(server, protocol) {
    let result = {
        show: server[protocol + "_reality_show"],
        fingerprint: server[protocol + "_reality_fingerprint"],
        serverName: server[protocol + "_reality_server_name"],
        publicKey: server[protocol + "_reality_public_key"],
        shortId: server[protocol + "_reality_short_id"],
        spiderX: server[protocol + "_reality_spider_x"],
    };

    return result;
};

export function reality_inbound_settings(proxy, protocol_name) {
    return {
        show: proxy[protocol_name + "_reality_show"],
        dest: proxy[protocol_name + "_reality_dest"],
        xver: proxy[protocol_name + "_reality_xver"],
        serverNames: proxy[protocol_name + "_reality_server_names"],
        privateKey: proxy[protocol_name + "_reality_private_key"],
        minClientVer: proxy[protocol_name + "_reality_min_client_ver"],
        maxClientVer: proxy[protocol_name + "_reality_max_client_ver"],
        maxTimeDiff: proxy[protocol_name + "_reality_max_time_diff"],
        shortIds: proxy[protocol_name + "_reality_short_ids"],
    };
};
