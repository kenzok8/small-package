"use strict";

import { reality_outbound_settings, tls_outbound_settings } from "./tls.mjs";

function stream_tcp_fake_http_request(server) {
    if (server["tcp_guise"] == "http") {
        return {
            version: "1.1",
            method: "GET",
            path: server["http_path"],
            headers: {
                "Host": server["http_host"],
                "User-Agent": [
                    "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36",
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                ],
                "Accept-Encoding": ["gzip, deflate"],
                "Connection": ["keep-alive"],
                "Pragma": "no-cache"
            }
        };
    }
    return null;
}

function stream_tcp_fake_http_response(server) {
    if (server["tcp_guise"] == "http") {
        return {
            version: "1.1",
            status: "200",
            reason: "OK",
            headers: {
                Content_Type: ["application/octet-stream", "video/mpeg"],
                Transfer_Encoding: ["chunked"],
                Connection: ["keep-alive"],
                Pragma: "no-cache"
            }
        };
    }
    return null;
}

function stream_tcp(server) {
    if (server["transport"] == "tcp") {
        return {
            header: {
                type: server["tcp_guise"],
                request: stream_tcp_fake_http_request(server),
                response: stream_tcp_fake_http_response(server)
            }
        };
    }
    return null;
}

function stream_h2(server) {
    if (server["transport"] == "h2") {
        return {
            path: server["h2_path"],
            host: server["h2_host"],
            read_idle_timeout: server["h2_health_check"] == "1" ? int(server["h2_read_idle_timeout"] || 10) : null,
            health_check_timeout: server["h2_health_check"] == "1" ? int(server["h2_health_check_timeout"] || 20) : null,
        };
    }
    return null;
}

function stream_grpc(server) {
    if (server["transport"] == "grpc") {
        return {
            serviceName: server["grpc_service_name"],
            multiMode: server["grpc_multi_mode"] == "1",
            initial_windows_size: int(server["grpc_initial_windows_size"] || 0),
            idle_timeout: server["grpc_health_check"] == "1" ? int(server["grpc_idle_timeout"] || 10) : null,
            health_check_timeout: server["grpc_health_check"] == "1" ? int(server["grpc_health_check_timeout"] || 20) : null,
            permit_without_stream: server["grpc_health_check"] == "1" ? (server["grpc_permit_without_stream"] == "1") : null
        };
    }
    return null;
}

function stream_ws(server) {
    if (server["transport"] == "ws") {
        let headers = null;
        if (server["ws_host"] != null) {
            headers = {
                Host: server["ws_host"]
            };
        }
        return {
            path: server["ws_path"],
            headers: headers
        };
    }
    return null;
}

function stream_kcp(server) {
    if (server["transport"] == "mkcp") {
        let mkcp_seed = null;
        if (server["mkcp_seed"] != "") {
            mkcp_seed = server["mkcp_seed"];
        }
        return {
            mtu: int(server["mkcp_mtu"] || 1350),
            tti: int(server["mkcp_tti"] || 50),
            uplinkCapacity: int(server["mkcp_uplink_capacity"] || 5),
            downlinkCapacity: int(server["mkcp_downlink_capacity"] || 20),
            congestion: server["mkcp_congestion"] == "1",
            readBufferSize: int(server["mkcp_read_buffer_size"] || 2),
            writeBufferSize: int(server["mkcp_write_buffer_size"] || 2),
            seed: mkcp_seed,
            header: {
                type: server["mkcp_guise"] || "none"
            }
        };
    }
    return null;
}

function stream_quic(server) {
    if (server["transport"] == "quic") {
        return {
            security: server["quic_security"],
            key: server["quic_key"],
            header: {
                type: server["quic_guise"]
            }
        };
    }
    return null;
}

export function port_array(i) {
    if (type(i) === 'array') {
        return map(i, v => int(v));
    }
    return [int(i)];
};

export function stream_settings(server, protocol, tag) {
    const security = server[protocol + "_tls"];
    let tlsSettings = null;
    let realitySettings = null;
    if (security == "tls") {
        tlsSettings = tls_outbound_settings(server, protocol);
    } else if (security == "reality") {
        realitySettings = reality_outbound_settings(server, protocol);
    }

    let dialer_proxy = null;
    let dialer_proxy_tag = null;
    if (server["dialer_proxy"] != null && server["dialer_proxy"] != "disabled") {
        dialer_proxy = server["dialer_proxy"];
        dialer_proxy_tag = tag + `@dialer_proxy:${dialer_proxy}`;
    }
    return {
        stream_settings: {
            network: server["transport"],
            sockopt: {
                mark: 253,
                domainStrategy: server["domain_strategy"] || "UseIP",
                dialerProxy: dialer_proxy_tag
            },
            security: security,
            tlsSettings: tlsSettings,
            realitySettings: realitySettings,
            quicSettings: stream_quic(server),
            tcpSettings: stream_tcp(server),
            kcpSettings: stream_kcp(server),
            wsSettings: stream_ws(server),
            grpcSettings: stream_grpc(server),
            httpSettings: stream_h2(server)
        },
        dialer_proxy: dialer_proxy
    };
};
