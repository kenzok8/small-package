#!/usr/bin/ucode
const uci = require("uci");
const fs = require("fs");
const cursor = uci.cursor();
cursor.load("xray");
const config = cursor.get_all("xray");
const share_dir = fs.lsdir("/usr/share/xray");

const proxy = config[filter(keys(config), k => config[k][".type"] == "general")[0]];
const tcp_server = config[proxy["main_server"]];
const udp_server = config[proxy["tproxy_udp_server"]];

const geoip_existence = index(share_dir, "geoip.dat") > 0;
const geosite_existence = index(share_dir, "geosite.dat") > 0;

function split_ipv4_host_port(val, port_default) {
    const result = match(val, /([0-9\.]+):([0-9]+)/);
    if (result == null) {
        return {
            address: val,
            port: int(port_default)
        }
    }

    return {
        address: result[1],
        port: int(result[2])
    }
}

function direct_outbound(tag) {
    return {
        protocol: "freedom",
        tag: tag,
        settings: {
            domainStrategy: "UseIPv4"
        },
        streamSettings: {
            sockopt: {
                mark: int(proxy["mark"])
            }
        }
    }
}

function blackhole_outbound() {
    return {
        tag: "blackhole_outbound",
        protocol: "blackhole"
    }
}

function stream_tcp_fake_http_request(server) {
    if (server["tcp_guise"] == "http") {
        return {
            version: "1.1",
            method: "GET",
            path: server["http_path"],
            headers: {
                Host: server["http_host"],
                User_Agent: [
                    "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                ],
                Accept_Encoding: ["gzip, deflate"],
                Connection: ["keep-alive"],
                Pragma: "no-cache"
            }
        }
    }
    return null
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
        }
    }
    return null
}

function stream_tcp(server) {
    if (server["transport"] == "tcp") {
        return {
            header: {
                type: server["tcp_guise"],
                request: stream_tcp_fake_http_request(server),
                response: stream_tcp_fake_http_response(server)
            }
        }
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
        }
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
        }
    }
    return null
}

function stream_ws(server) {
    if (server["transport"] == "ws") {
        let headers = null;
        if (server["ws_host"] != null) {
            headers = {
                Host: server["ws_host"]
            }
        }
        return {
            path: server["ws_path"],
            headers: headers
        }
    }
    return null
}

function stream_kcp(server) {
    if (server["transport"] == "mkcp") {
        let mkcp_seed = null;
        if (server["mkcp_seed"] != "") {
            mkcp_seed = server["mkcp_seed"];
        }
        return {
            mtu: int(server["mkcp_mtu"]),
            tti: int(server["mkcp_tti"]),
            uplinkCapacity: int(server["mkcp_uplink_capacity"]),
            downlinkCapacity: int(server["mkcp_downlink_capacity"]),
            congestion: server["mkcp_congestion"] == "1",
            readBufferSize: int(server["mkcp_read_buffer_size"]),
            writeBufferSize: int(server["mkcp_write_buffer_size"]),
            seed: mkcp_seed,
            header: {
                type: server["mkcp_guise"]
            }
        }
    }
    return null
}

function stream_quic(server) {
    if (server["transport"] == "quic") {
        return {
            security: server["quic_security"],
            key: server["quic_key"],
            header: {
                type: server["quic_guise"]
            }
        }
    }
    return null
}

function tls_settings(server, protocol) {
    let result = {
        serverName: server[protocol + "_tls_host"],
        allowInsecure: server[protocol + "_tls_insecure"] != "0",
        fingerprint: server[protocol + "_tls_fingerprint"] || ""
    };

    if (server[protocol + "_tls_alpn"] != null) {
        result["alpn"] = server[protocol + "_tls_alpn"];
    }

    return result;
}

function xtls_settings(server, protocol) {
    let result = {
        serverName: server[protocol + "_xtls_host"],
        allowInsecure: server[protocol + "_xtls_insecure"] != "0"
    };

    if (server[protocol + "_xtls_alpn"] != null) {
        result["alpn"] = server[protocol + "_xtls_alpn"];
    }

    return result;
}

function reality_settings(server, protocol) {
    let result = {
        show: server[protocol + "_reality_show"],
        fingerprint: server[protocol + "_reality_fingerprint"],
        serverName: server[protocol + "_reality_server_name"],
        publicKey: server[protocol + "_reality_public_key"],
        shortId: server[protocol + "_reality_short_id"],
        spiderX: server[protocol + "_reality_spider_x"],
    };

    return result;
}

function stream_settings(server, protocol, tag) {
    const security = server[protocol + "_tls"];
    let tlsSettings = null;
    let xtlsSettings = null;
    let realitySettings = null;
    if (security == "tls") {
        tlsSettings = tls_settings(server, protocol);
    } else if (security == "xtls") {
        xtlsSettings = xtls_settings(server, protocol);
    } else if (security == "reality") {
        realitySettings = reality_settings(server, protocol);
    }

    let dialer_proxy = null;
    let dialer_proxy_tag = null;
    if (server["dialer_proxy"] != null && server["dialer_proxy"] != "disabled") {
        dialer_proxy = server["dialer_proxy"];
        dialer_proxy_tag = "dialer_proxy_" + tag;
    }
    return {
        stream_settings: {
            network: server["transport"],
            sockopt: {
                mark: int(proxy["mark"]),
                domainStrategy: server["domain_strategy"] || "UseIP",
                dialerProxy: dialer_proxy_tag
            },
            security: security,
            tlsSettings: tlsSettings,
            xtlsSettings: xtlsSettings,
            realitySettings: realitySettings,
            quicSettings: stream_quic(server),
            tcpSettings: stream_tcp(server),
            kcpSettings: stream_kcp(server),
            wsSettings: stream_ws(server),
            grpcSettings: stream_grpc(server),
            httpSettings: stream_h2(server)
        },
        dialer_proxy: dialer_proxy
    }
}

function shadowsocks_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "shadowsocks", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "shadowsocks",
            tag: tag,
            settings: {
                servers: [
                    {
                        address: server["server"],
                        port: int(server["server_port"]),
                        password: server["password"],
                        method: server["shadowsocks_security"],
                        uot: server["shadowsocks_udp_over_tcp"] == '1'
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    }
}

function vmess_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "vmess", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "vmess",
            tag: tag,
            settings: {
                vnext: [
                    {
                        address: server["server"],
                        port: int(server["server_port"]),
                        users: [
                            {
                                id: server["password"],
                                alterId: int(server["alter_id"]),
                                security: server["vmess_security"]
                            }
                        ]
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    }
}

function vless_outbound(server, tag) {
    let flow = null;
    if (server["vless_tls"] == "xtls") {
        flow = server["vless_flow"]
    } else if (server["vless_tls"] == "tls") {
        flow = server["vless_flow_tls"]
    } else if (server["vless_tls"] == "reality") {
        flow = server["vless_flow_reality"]
    }
    if (flow == "none") {
        flow = null;
    }
    const stream_settings_object = stream_settings(server, "vless", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "vless",
            tag: tag,
            settings: {
                vnext: [
                    {
                        address: server["server"],
                        port: int(server["server_port"]),
                        users: [
                            {
                                id: server["password"],
                                flow: flow,
                                encryption: server["vless_encryption"]
                            }
                        ]
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    }
}

function trojan_outbound(server, tag) {
    let flow = null;
    if (server["trojan_tls"] == "xtls") {
        flow = server["trojan_flow"]
    }
    if (flow == "none") {
        flow = null;
    }
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
                        password: server["password"],
                        flow: flow,
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    }
}

function override_custom_config_recursive(x, y) {
    if (type(x) != "object" || type(y) != "object") {
        return y;
    }
    for (k in y) {
        x[k] = override_custom_config_recursive(x[k], y[k])
    }
    return x;
}

function server_outbound_recursive(t, server, tag) {
    let outbound_result = null;
    if (server["protocol"] == "vmess") {
        outbound_result = vmess_outbound(server, tag);
    } else if (server["protocol"] == "vless") {
        outbound_result = vless_outbound(server, tag);
    } else if (server["protocol"] == "shadowsocks") {
        outbound_result = shadowsocks_outbound(server, tag);
    } else if (server["protocol"] == "trojan") {
        outbound_result = trojan_outbound(server, tag);
    }
    if (outbound_result == null) {
        die("unknown outbound server protocol");
    }
    let outbound = outbound_result["outbound"];
    const custom_config_outbound_string = server["custom_config"];

    if (custom_config_outbound_string != null && custom_config_outbound_string != "") {
        let custom_config_outbound = json(custom_config_outbound_string);
        for (k in custom_config_outbound) {
            if (k == "tag") {
                continue;
            }
            outbound[k] = override_custom_config_recursive(outbound[k], custom_config_outbound[k])
        }
    }

    const dialer_proxy = outbound_result["dialer_proxy"];
    const result = [...t, outbound];

    if (dialer_proxy != null) {
        const dialer_proxy_section = config[dialer_proxy];
        return server_outbound_recursive(result, dialer_proxy_section, "dialer_proxy_" + tag)
    }
    return result
}

function server_outbound(server, tag) {
    if (server == null) {
        return [direct_outbound(tag)]
    }
    return server_outbound_recursive([], server, tag)
}

function tproxy_tcp_inbound() {
    return {
        port: proxy["tproxy_port_tcp"],
        protocol: "dokodemo-door",
        tag: "tproxy_tcp_inbound",
        sniffing: proxy["tproxy_sniffing"] == "1" ? {
            enabled: true,
            routeOnly: proxy["route_only"] == "1",
            destOverride: ["http", "tls"],
            metadataOnly: false
        } : null,
        settings: {
            network: "tcp",
            followRedirect: true
        },
        streamSettings: {
            sockopt: {
                tproxy: "tproxy",
                mark: int(proxy["mark"])
            }
        }
    }
}

function tproxy_udp_inbound() {
    return {
        port: proxy["tproxy_port_udp"],
        protocol: "dokodemo-door",
        tag: "tproxy_udp_inbound",
        settings: {
            network: "udp",
            followRedirect: true
        },
        streamSettings: {
            sockopt: {
                tproxy: "tproxy",
                mark: int(proxy["mark"])
            }
        }
    }
}

function http_inbound() {
    return {
        port: proxy["http_port"],
        protocol: "http",
        tag: "http_inbound",
        settings: {
            allowTransparent: false
        }
    }
}

function socks_inbound() {
    return {
        port: proxy["socks_port"],
        protocol: "socks",
        tag: "socks_inbound",
        settings: {
            udp: true
        }
    }
}

function fallbacks() {
    let f = [];
    for (key in filter(keys(config), k => config[k][".type"] == "fallback")) {
        const s = config[key];
        if (s["dest"] != null) {
            push(f, {
                dest: s["dest"],
                alpn: s["alpn"],
                name: s["name"],
                xver: s["xver"],
                path: s["path"]
            })
        }
    }
    push(f, {
        dest: proxy["web_server_address"]
    });
    return f
}

function tls_inbound_settings(protocol_name) {
    let wscert = proxy[protocol_name + "_tls_cert_file"];
    if (wscert == null) {
        wscert = proxy["web_server_cert_file"]
    }
    let wskey = proxy[protocol_name + "_tls_key_file"];
    if (wskey == null) {
        wskey = proxy["web_server_key_file"]
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
    }
}

function xtls_inbound_settings(protocol_name) {
    let wscert = proxy[protocol_name + "_xtls_cert_file"];
    if (wscert == null) {
        wscert = proxy["web_server_cert_file"]
    }
    let wskey = proxy[protocol_name + "_xtls_key_file"];
    if (wskey == null) {
        wskey = proxy["web_server_key_file"]
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
    }
}

function reality_inbound_settings(protocol_name) {
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
    }
}

function https_trojan_inbound() {
    let flow = null;
    if (proxy["trojan_tls"] == "xtls") {
        flow = proxy["trojan_flow"]
    }
    if (flow == "none") {
        flow = null;
    }
    return {
        port: proxy["web_server_port"] || 443,
        protocol: "trojan",
        tag: "https_inbound",
        settings: {
            clients: [
                {
                    password: proxy["web_server_password"],
                    flow: flow
                }
            ],
            fallbacks: fallbacks()
        },
        streamSettings: {
            network: "tcp",
            security: proxy["trojan_tls"],
            tlsSettings: proxy["trojan_tls"] == "tls" ? tls_inbound_settings("trojan") : null,
            xtlsSettings: proxy["trojan_tls"] == "xtls" ? xtls_inbound_settings("trojan") : null
        }
    }
}

function https_vless_inbound() {
    let flow = null;
    if (proxy["vless_tls"] == "xtls") {
        flow = proxy["vless_flow"]
    } else if (proxy["vless_tls"] == "tls") {
        flow = proxy["vless_flow_tls"]
    } else if (proxy["vless_tls"] == "reality") {
        flow = proxy["vless_flow_reality"]
    }
    if (flow == "none") {
        flow = null;
    }
    return {
        port: proxy["web_server_port"] || 443,
        protocol: "vless",
        tag: "https_inbound",
        settings: {
            clients: [
                {
                    id: proxy["web_server_password"],
                    flow: flow
                }
            ],
            decryption: "none",
            fallbacks: fallbacks()
        },
        streamSettings: {
            network: "tcp",
            security: proxy["vless_tls"],
            tlsSettings: proxy["vless_tls"] == "tls" ? tls_inbound_settings("vless") : null,
            xtlsSettings: proxy["vless_tls"] == "xtls" ? xtls_inbound_settings("vless") : null,
            realitySettings: proxy["vless_tls"] == "reality" ? reality_inbound_settings("vless") : null,
        }
    }
}

function https_inbound() {
    if (proxy["web_server_protocol"] == "vless") {
        return https_vless_inbound()
    }
    if (proxy["web_server_protocol"] == "trojan") {
        return https_trojan_inbound()
    }
    return nil
}

function dns_server_inbounds() {
    const default_dns = split_ipv4_host_port(proxy["default_dns"], 53);
    let result = [];
    const dns_port = int(proxy["dns_port"]);
    const dns_count = int(proxy["dns_count"] || 0);
    for (let i = dns_port; i <= dns_port + dns_count; i++) {
        push(result, {
            port: i,
            protocol: "dokodemo-door",
            tag: sprintf("dns_server_inbound_%d", i),
            settings: {
                address: default_dns["address"],
                port: default_dns["port"],
                network: "tcp,udp"
            }
        });
    }
    return result
}

function dns_server_tags() {
    let result = [];
    const dns_port = int(proxy["dns_port"]);
    const dns_count = int(proxy["dns_count"] || 0);
    for (let i = dns_port; i <= dns_port + dns_count; i++) {
        push(result, sprintf("dns_server_inbound_%d", i));
    }
    return result
}

function dns_server_outbound() {
    return {
        protocol: "dns",
        streamSettings: {
            sockopt: {
                mark: int(proxy["mark"])
            }
        },
        tag: "dns_server_outbound"
    }
}

function upstream_domain_names() {
    let domain_names_set = {};
    if (tcp_server != null) {
        domain_names_set[tcp_server["server"]] = true;
    }
    if (udp_server != null) {
        domain_names_set[udp_server["server"]] = true;
    }
    return keys(domain_names_set)
}

function domain_rules(k) {
    if (proxy[k] == null) {
        return []
    }
    return filter(proxy[k], function (x) {
        if (substr(x, 0, 8) == "geosite:") {
            return geosite_existence;
        }
        return true;
    })
}

function secure_domain_rules() {
    return domain_rules("forwarded_domain_rules");
}

function fast_domain_rules() {
    return domain_rules("bypassed_domain_rules");
}

function blocked_domain_rules() {
    return domain_rules("blocked_domain_rules");
}

function dns_conf() {
    const fast_dns_object = split_ipv4_host_port(proxy["fast_dns"], 53);
    const default_dns_object = split_ipv4_host_port(proxy["default_dns"], 53);
    let servers = [
        {
            address: fast_dns_object["address"],
            port: fast_dns_object["port"],
            domains: [...upstream_domain_names(), ...fast_domain_rules()],
        },
        default_dns_object,
    ];

    if (length(secure_domain_rules()) > 0) {
        const secure_dns_object = split_ipv4_host_port(proxy["secure_dns"], 53);
        splice(servers, 1, 0, {
            address: secure_dns_object["address"],
            port: secure_dns_object["port"],
            domains: secure_domain_rules(),
        });
    }

    let hosts = null;
    if (length(blocked_domain_rules()) > 0) {
        hosts = {};
        for (rule in (blocked_domain_rules())) {
            hosts[rule] = ["127.127.127.127", "100::6c62:636f:656b:2164"] // blocked!
        }
    }

    return {
        hosts: hosts,
        servers: servers,
        tag: "dns_conf_inbound",
        queryStrategy: "UseIPv4"
    }
}

function api_conf() {
    if (proxy["xray_api"] == '1') {
        return {
            tag: "api",
            services: [
                "HandlerService",
                "LoggerService",
                "StatsService"
            ]
        }
    }
    return null
}

function metrics_conf() {
    if (proxy["metrics_server_enable"] == "1") {
        return {
            tag: "metrics"
        }
    }
    return null
}

function inbounds() {
    let i = [
        http_inbound(),
        tproxy_tcp_inbound(),
        tproxy_udp_inbound(),
        socks_inbound(),
        ...dns_server_inbounds(),
    ];
    if (proxy["web_server_enable"] == "1") {
        push(i, https_inbound());
    }
    if (proxy["metrics_server_enable"] == '1') {
        push(i, {
            listen: "0.0.0.0",
            port: proxy["metrics_server_port"] || 18888,
            protocol: "dokodemo-door",
            settings: {
                address: "127.0.0.1"
            },
            tag: "metrics"
        })
    }
    if (proxy["xray_api"] == '1') {
        push(i, {
            listen: "127.0.0.1",
            port: 8080,
            protocol: "dokodemo-door",
            settings: {
                address: "127.0.0.1"
            },
            tag: "api"
        })
    }
    return i
}

function manual_tproxy_outbounds() {
    let result = [];
    let i = 0;
    for (key in filter(keys(config), k => config[k][".type"] == "manual_tproxy")) {
        const v = config[key];
        i = i + 1;
        let tcp_tag = "direct";
        let udp_tag = "direct";
        if (v["force_forward"] == "1") {
            if (v["force_forward_server_tcp"] != nil) {
                if (v["force_forward_server_tcp"] == proxy["main_server"]) {
                    tcp_tag = "tcp_outbound"
                } else {
                    tcp_tag = sprintf("manual_tproxy_force_forward_tcp_outbound_%d", i);
                    const force_forward_server_tcp = config[v["force_forward_server_tcp"]];
                    push(result, ...server_outbound(force_forward_server_tcp, tcp_tag));
                }
            } else {
                tcp_tag = "tcp_outbound"
            }
            if (v["force_forward_server_udp"] != nil) {
                if (v["force_forward_server_udp"] == proxy["tproxy_udp_server"]) {
                    udp_tag = "udp_outbound"
                } else {
                    udp_tag = sprintf("manual_tproxy_force_forward_udp_outbound_%d", i);
                    const force_forward_server_udp = config[v["force_forward_server_udp"]];
                    push(result, ...server_outbound(force_forward_server_udp, udp_tag));
                }

            } else {
                udp_tag = "udp_outbound"
            }
        }
        push(result, {
            protocol: "freedom",
            tag: sprintf("manual_tproxy_outbound_tcp_%d", i),
            settings: {
                redirect: sprintf("%s:%d", v["dest_addr"], v["dest_port"]),
                domainStrategy: v["domain_strategy"] || "UseIP"
            },
            proxySettings: {
                tag: tcp_tag
            }
        });
        push(result, {
            protocol: "freedom",
            tag: sprintf("manual_tproxy_outbound_udp_%d", i),
            settings: {
                redirect: sprintf("%s:%d", v["dest_addr"], v["dest_port"]),
                domainStrategy: v["domain_strategy"] || "UseIP"
            },
            proxySettings: {
                tag: udp_tag
            }
        });
    }
    return result
}

function manual_tproxy_rules() {
    let result = [];
    let i = 0;
    for (key in filter(keys(config), k => config[k][".type"] == "manual_tproxy")) {
        const v = config[key];
        i = i + 1;
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_tcp_inbound", "socks_inbound", "https_inbound", "http_inbound"],
            ip: [v["source_addr"]],
            port: v["source_port"],
            outboundTag: sprintf("manual_tproxy_outbound_tcp_%d", i)
        });
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_udp_inbound"],
            ip: [v["source_addr"]],
            port: v["source_port"],
            outboundTag: sprintf("manual_tproxy_outbound_udp_%d", i)
        });
    }
    return result
}

function bridges() {
    let result = [];
    let i = 0;
    for (key in filter(keys(config), k => config[k][".type"] == "bridge")) {
        const v = config[key];
        i = i + 1;
        push(result, {
            tag: sprintf("bridge_inbound_%d", i),
            domain: v["domain"]
        })
    }
    return result
}

function bridge_outbounds() {
    let result = [];
    let i = 0;
    for (key in filter(keys(config), k => config[k][".type"] == "bridge")) {
        const v = config[key];
        i = i + 1;
        const bridge_server = config[v["upstream"]];
        for (i in server_outbound(bridge_server, sprintf("bridge_upstream_outbound_%d", i))) {
            splice(result, 0, 0, f);
        }
        splice(result, 0, 0, {
            tag: sprintf("bridge_freedom_outbound_%d", i),
            protocol: "freedom",
            settings: {
                redirect: v["redirect"]
            }
        })
    }
    return result
}

function bridge_rules() {
    let result = [];
    for (key in filter(keys(config), k => config[k][".type"] == "bridge")) {
        const v = config[key];
        i = i + 1;
        push(result, {
            type: "field",
            inboundTag: [sprintf("bridge_inbound_%d", i)],
            outboundTag: sprintf("bridge_freedom_outbound_%d", i)
        });
        push(result, {
            type: "field",
            inboundTag: [sprintf("bridge_inbound_%d", i)],
            domain: [sprintf("full:%s", v["domain"])],
            outboundTag: sprintf("bridge_upstream_outbound_%d", i)
        });
    }
    return result
}

function rules() {
    let result = [
        {
            type: "field",
            inboundTag: ["tproxy_tcp_inbound", "dns_conf_inbound", "socks_inbound", "https_inbound", "http_inbound"],
            outboundTag: "tcp_outbound"
        },
        {
            type: "field",
            inboundTag: ["tproxy_udp_inbound"],
            outboundTag: "udp_outbound"
        },
        {
            type: "field",
            inboundTag: dns_server_tags(),
            outboundTag: "dns_server_outbound"
        },
        {
            type: "field",
            inboundTag: ["api"],
            outboundTag: "api"
        }
    ];
    if (proxy["metrics_server_enable"] == "1") {
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["metrics"],
            outboundTag: "metrics"
        })
    }
    if (geoip_existence) {
        if (proxy["geoip_direct_code"] == null || proxy["geoip_direct_code"] == "upgrade") {
            if (proxy["geoip_direct_code_list"] != null) {
                const geoip_direct_code_list = map(proxy["geoip_direct_code_list"], v => "geoip:" + v);
                splice(result, 0, 0, {
                    type: "field",
                    inboundTag: ["tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"],
                    outboundTag: "direct",
                    ip: geoip_direct_code_list
                })
            }
        } else {
            splice(result, 0, 0, {
                type: "field",
                inboundTag: ["tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"],
                outboundTag: "direct",
                ip: ["geoip:" + proxy["geoip_direct_code"]]
            })
        }
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound", "socks_inbound", "https_inbound", "http_inbound"],
            outboundTag: "direct",
            ip: ["geoip:private"]
        })
    }
    if (proxy["tproxy_sniffing"] == "1") {
        if (length(secure_domain_rules()) > 0) {
            splice(result, 0, 0, {
                type: "field",
                inboundTag: ["tproxy_udp_inbound"],
                outboundTag: "udp_outbound",
                domain: secure_domain_rules(),
            });
            splice(result, 0, 0, {
                type: "field",
                inboundTag: ["tproxy_tcp_inbound", "dns_conf_inbound"],
                outboundTag: "tcp_outbound",
                domain: secure_domain_rules(),
            });
        }
        if (length(blocked_domain_rules()) > 0) {
            splice(result, 0, 0, {
                type: "field",
                inboundTag: ["tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"],
                outboundTag: "blackhole_outbound",
                domain: blocked_domain_rules(),
            })
        }
        splice(result, 0, 0, {
            type: "field",
            inboundTag: ["tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound", "https_inbound", "http_inbound"],
            outboundTag: "direct",
            domain: fast_domain_rules()
        });
        if (proxy["direct_bittorrent"] == "1") {
            splice(result, 0, 0, {
                type: "field",
                outboundTag: "direct",
                protocol: ["bittorrent"]
            })
        }
    }
    splice(result, 0, 0, ...manual_tproxy_rules());
    splice(result, 0, 0, ...bridge_rules());
    return result
}

function outbounds() {
    return [
        direct_outbound("direct"),
        dns_server_outbound(),
        blackhole_outbound(),
        ...server_outbound(tcp_server, "tcp_outbound"),
        ...server_outbound(udp_server, "udp_outbound"),
        ...manual_tproxy_outbounds(),
        ...bridge_outbounds()
    ]
}

function policy() {
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
    }
}

function logging() {
    return {
        access: proxy["access_log"] == "1" ? "" : "none",
        loglevel: proxy["loglevel"] || "warning",
        dnsLog: proxy["dns_log"] == "1"
    }
}

function observatory() {
    if (proxy["observatory"] == "1") {
        return {
            subjectSelector: ["tcp_outbound", "udp_outbound", "direct", "manual_tproxy_force_forward"],
            probeInterval: "1s",
            probeUrl: "http://www.apple.com/library/test/success.html"
        }
    }
    return null
}

function gen_config() {
    return {
        inbounds: inbounds(),
        outbounds: outbounds(),
        dns: dns_conf(),
        api: api_conf(),
        metrics: metrics_conf(),
        policy: policy(),
        log: logging(),
        stats: proxy["stats"] == "1" ? {
            place: "holder"
        } : null,
        observatory: observatory(),
        reverse: {
            bridges: bridges()
        },
        routing: {
            domainStrategy: proxy["routing_domain_strategy"] || "AsIs",
            rules: rules()
        }
    }
}

print(gen_config());
