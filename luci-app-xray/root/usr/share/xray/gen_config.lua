#!/usr/bin/lua
local ucursor = require "luci.model.uci"
local json = require "luci.jsonc"
local nixiofs = require "nixio.fs"

local proxy_section = ucursor:get_first("xray", "general")
local proxy = ucursor:get_all("xray", proxy_section)

local tcp_server_section = arg[1] == nil and proxy.main_server or arg[1]
local tcp_server = ucursor:get_all("xray", tcp_server_section)

local udp_server_section = arg[2] == nil and proxy.tproxy_udp_server or arg[2]
local udp_server = ucursor:get_all("xray", udp_server_section)

local geoip_existence = false
local geosite_existence = false
local optional_feature_1000 = false

local xray_data_file_iterator = nixiofs.dir("/usr/share/xray")

repeat
    local fn = xray_data_file_iterator()
    if fn == "geoip.dat" then
        geoip_existence = true
    end
    if fn == "geosite.dat" then
        geosite_existence = true
    end
    if fn == "optional_feature_1000" then
        optional_feature_1000 = true
    end
until fn == nil

local function split_ipv4_host_port(val, port_default)
    local found, _, ip, port = val:find("([%d.]+):(%d+)")
    if found == nil then
        return val, tonumber(port_default)
    else
        return ip, tonumber(port)
    end
end

local function direct_outbound()
    return {
        protocol = "freedom",
        tag = "direct",
        streamSettings = {
            sockopt = {
                mark = tonumber(proxy.mark)
            }
        }
    }
end

local function blackhole_outbound()
    return {
        tag = "blackhole_outbound",
        protocol = "blackhole"
    }
end

local function manual_tproxy_outbounds()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "manual_tproxy", function(v)
        i = i + 1
        table.insert(result, {
            protocol = "freedom",
            tag = string.format("manual_tproxy_outbound_tcp_%d", i),
            settings = {
                redirect = string.format("%s:%d", v.dest_addr, v.dest_port),
                domainStrategy = v.domain_strategy or "UseIP"
            },
            proxySettings = v.force_forward == "1" and {
                tag = "tcp_outbound"
            } or nil
        })
        table.insert(result, {
            protocol = "freedom",
            tag = string.format("manual_tproxy_outbound_udp_%d", i),
            settings = {
                redirect = string.format("%s:%d", v.dest_addr, v.dest_port),
                domainStrategy = v.domain_strategy or "UseIP"
            },
            proxySettings = v.force_forward == "1" and {
                tag = "udp_outbound"
            } or nil
        })
    end)
    return result
end

local function stream_tcp_fake_http_request(server)
    if server.tcp_guise == "http" then
        return {
            version = "1.1",
            method = "GET",
            path = server.http_path,
            headers = {
                Host = server.http_host,
                User_Agent = {
                    "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                },
                Accept_Encoding = {"gzip, deflate"},
                Connection = {"keep-alive"},
                Pragma = "no-cache"
            }
        }
    else
        return nil
    end
end

local function stream_tcp_fake_http_response(server)
    if server.tcp_guise == "http" then
        return {
            version = "1.1",
            status = "200",
            reason = "OK",
            headers = {
                Content_Type = {"application/octet-stream", "video/mpeg"},
                Transfer_Encoding = {"chunked"},
                Connection = {"keep-alive"},
                Pragma = "no-cache"
            }
        }
    else
        return nil
    end
end

local function stream_tcp(server)
    if server.transport == "tcp" then
        return {
            header = {
                type = server.tcp_guise,
                request = stream_tcp_fake_http_request(server),
                response = stream_tcp_fake_http_response(server)
            }
        }
    else
        return nil
    end
end

local function stream_h2(server)
    if (server.transport == "h2") then
        return {
            path = server.h2_path,
            host = server.h2_host
        }
    else
        return nil
    end
end

local function stream_grpc(server)
    if (server.transport == "grpc") then
        return {
            serviceName = server.grpc_service_name,
            multiMode = server.grpc_multi_mode == "1",
            initial_windows_size = tonumber(server.grpc_initial_windows_size or 0),
            idle_timeout = server.grpc_health_check == "1" and tonumber(server.grpc_idle_timeout or 10) or nil,
            health_check_timeout = server.grpc_health_check == "1" and tonumber(server.grpc_health_check_timeout or 20) or nil,
            permit_without_stream = server.grpc_health_check == "1" and (server.grpc_permit_without_stream == "1") or nil
        }
    else
        return nil
    end
end

local function stream_ws(server)
    if server.transport == "ws" then
        local headers = nil
        if (server.ws_host ~= nil) then
            headers = {
                Host = server.ws_host
            }
        end
        return {
            path = server.ws_path,
            headers = headers
        }
    else
        return nil
    end
end

local function stream_kcp(server)
    if server.transport == "mkcp" then
        local mkcp_seed = nil
        if server.mkcp_seed ~= "" then
            mkcp_seed = server.mkcp_seed
        end
        return {
            mtu = tonumber(server.mkcp_mtu),
            tti = tonumber(server.mkcp_tti),
            uplinkCapacity = tonumber(server.mkcp_uplink_capacity),
            downlinkCapacity = tonumber(server.mkcp_downlink_capacity),
            congestion = server.mkcp_congestion == "1",
            readBufferSize = tonumber(server.mkcp_read_buffer_size),
            writeBufferSize = tonumber(server.mkcp_write_buffer_size),
            seed = mkcp_seed,
            header = {
                type = server.mkcp_guise
            }
        }
    else
        return nil
    end
end

local function stream_quic(server)
    if server.transport == "quic" then
        return {
            security = server.quic_security,
            key = server.quic_key,
            header = {
                type = server.quic_guise
            }
        }
    else
        return nil
    end
end

local function tls_settings(server, protocol)
    local result = {
        serverName = server[protocol .. "_tls_host"],
        allowInsecure = server[protocol .. "_tls_insecure"] ~= "0",
        fingerprint = server[protocol .. "_tls_fingerprint"] or "",
    }

    if server[protocol .. "_tls_alpn"] ~= nil then
        local alpn = {}
        for _, x in ipairs(server[protocol .. "_tls_alpn"]) do
            table.insert(alpn, x)
        end
        result["alpn"] = alpn
    end

    return result
end

local function xtls_settings(server, protocol)
    local result = {
        serverName = server[protocol .. "_xtls_host"],
        allowInsecure = server[protocol .. "_xtls_insecure"] ~= "0",
    }

    if server[protocol .. "_xtls_alpn"] ~= nil then
        local alpn = {}
        for _, x in ipairs(server[protocol .. "_xtls_alpn"]) do
            table.insert(alpn, x)
        end
        result["alpn"] = alpn
    end

    return result
end

local function shadowsocks_outbound(server, tag)
    return {
        protocol = "shadowsocks",
        tag = tag,
        settings = {
            servers = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    password = server.password,
                    method = server.shadowsocks_security
                }
            }
        },
        streamSettings = {
            network = server.transport,
            sockopt = {
                mark = tonumber(proxy.mark),
                domainStrategy = server.domain_strategy or "UseIP"
            },
            security = server.shadowsocks_tls,
            tlsSettings = server.shadowsocks_tls == "tls" and tls_settings(server, "shadowsocks") or nil,
            quicSettings = stream_quic(server),
            tcpSettings = stream_tcp(server),
            kcpSettings = stream_kcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server)
        }
    }
end

local function vmess_outbound(server, tag)
    return {
        protocol = "vmess",
        tag = tag,
        settings = {
            vnext = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    users = {
                        {
                            id = server.password,
                            alterId = tonumber(server.alter_id),
                            security = server.vmess_security
                        }
                    }
                }
            }
        },
        streamSettings = {
            network = server.transport,
            sockopt = {
                mark = tonumber(proxy.mark),
                domainStrategy = server.domain_strategy or "UseIP"
            },
            security = server.vmess_tls,
            tlsSettings = server.vmess_tls == "tls" and tls_settings(server, "vmess") or nil,
            quicSettings = stream_quic(server),
            tcpSettings = stream_tcp(server),
            kcpSettings = stream_kcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server)
        }
    }
end

local function vless_outbound(server, tag)
    local flow = server.vless_flow
    if server.vless_flow == "none" then
        flow = nil
    end
    return {
        protocol = "vless",
        tag = tag,
        settings = {
            vnext = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    users = {
                        {
                            id = server.password,
                            flow = flow,
                            encryption = server.vless_encryption
                        }
                    }
                }
            }
        },
        streamSettings = {
            network = server.transport,
            sockopt = {
                mark = tonumber(proxy.mark),
                domainStrategy = server.domain_strategy or "UseIP"
            },
            security = server.vless_tls,
            tlsSettings = server.vless_tls == "tls" and tls_settings(server, "vless") or nil,
            xtlsSettings = server.vless_tls == "xtls" and xtls_settings(server, "vless") or nil,
            quicSettings = stream_quic(server),
            tcpSettings = stream_tcp(server),
            kcpSettings = stream_kcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server)
        }
    }
end

local function trojan_outbound(server, tag)
    local flow = server.trojan_flow
    if server.trojan_flow == "none" then
        flow = nil
    end
    return {
        protocol = "trojan",
        tag = tag,
        settings = {
            servers = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    password = server.password,
                    flow = flow,
                }
            }
        },
        streamSettings = {
            network = server.transport,
            sockopt = {
                mark = tonumber(proxy.mark),
                domainStrategy = server.domain_strategy or "UseIP"
            },
            security = server.trojan_tls,
            tlsSettings = server.trojan_tls == "tls" and tls_settings(server, "trojan") or nil,
            xtlsSettings = server.trojan_tls == "xtls" and xtls_settings(server, "trojan") or nil,
            quicSettings = stream_quic(server),
            tcpSettings = stream_tcp(server),
            kcpSettings = stream_kcp(server),
            wsSettings = stream_ws(server),
            grpcSettings = stream_grpc(server),
            httpSettings = stream_h2(server)
        }
    }
end

local function server_outbound(server, tag)
    if server.protocol == "vmess" then
        return vmess_outbound(server, tag)
    end
    if server.protocol == "vless" then
        return vless_outbound(server, tag)
    end
    if server.protocol == "shadowsocks" then
        return shadowsocks_outbound(server, tag)
    end
    if server.protocol == "trojan" then
        return trojan_outbound(server, tag)
    end
    error("unknown outbound server protocol")
end

local function tproxy_tcp_inbound()
    return {
        port = proxy.tproxy_port_tcp,
        protocol = "dokodemo-door",
        tag = "tproxy_tcp_inbound",
        sniffing = proxy.tproxy_sniffing == "1" and {
            enabled = true,
            routeOnly = proxy.route_only == "1",
            destOverride = {"http", "tls"},
            metadataOnly = false
        } or nil,
        settings = {
            network = "tcp",
            followRedirect = true
        },
        streamSettings = {
            sockopt = {
                tproxy = "tproxy",
                mark = tonumber(proxy.mark)
            }
        }
    }
end

local function tproxy_udp_inbound()
    return {
        port = proxy.tproxy_port_udp,
        protocol = "dokodemo-door",
        tag = "tproxy_udp_inbound",
        settings = {
            network = "udp",
            followRedirect = true
        },
        streamSettings = {
            sockopt = {
                tproxy = "tproxy",
                mark = tonumber(proxy.mark)
            }
        }
    }
end

local function http_inbound()
    return {
        port = proxy.http_port,
        protocol = "http",
        tag = "http_inbound",
        settings = {
            allowTransparent = false
        }
    }
end

local function socks_inbound()
    return {
        port = proxy.socks_port,
        protocol = "socks",
        tag = "socks_inbound",
        settings = {
            udp = true
        }
    }
end

local function fallbacks()
    local f = {}
    ucursor:foreach("xray", "fallback", function(s)
        if s.dest ~= nil then
            table.insert(f, {
                dest = s.dest,
                alpn = s.alpn,
                name = s.name,
                xver = s.xver,
                path = s.path
            })
        end
    end)
    table.insert(f, {
        dest = proxy.web_server_address
    })
    return f
end

local function https_trojan_inbound()
    return {
        port = 443,
        protocol = "trojan",
        tag = "https_inbound",
        settings = {
            clients = {
                {
                    password = proxy.web_server_password,
                    flow = proxy.trojan_tls == "xtls" and proxy.trojan_flow or nil
                }
            },
            fallbacks = fallbacks()
        },
        streamSettings = {
            network = "tcp",
            security = proxy.trojan_tls,
            tlsSettings = proxy.trojan_tls == "tls" and {
                alpn = {
                    "http/1.1"
                },
                certificates = {
                    {
                        certificateFile = proxy.web_server_cert_file,
                        keyFile = proxy.web_server_key_file
                    }
                }
            } or nil,
            xtlsSettings = proxy.trojan_tls == "xtls" and {
                alpn = {
                    "http/1.1"
                },
                certificates = {
                    {
                        certificateFile = proxy.web_server_cert_file,
                        keyFile = proxy.web_server_key_file
                    }
                }
            } or nil
        }
    }
end

local function https_vless_inbound()
    return {
        port = 443,
        protocol = "vless",
        tag = "https_inbound",
        settings = {
            clients = {
                {
                    id = proxy.web_server_password,
                    flow = proxy.vless_tls == "xtls" and proxy.vless_flow or nil
                }
            },
            decryption = "none",
            fallbacks = fallbacks()
        },
        streamSettings = {
            network = "tcp",
            security = proxy.vless_tls,
            tlsSettings = proxy.vless_tls == "tls" and {
                alpn = {
                    "http/1.1"
                },
                certificates = {
                    {
                        certificateFile = proxy.web_server_cert_file,
                        keyFile = proxy.web_server_key_file
                    }
                }
            } or nil,
            xtlsSettings = proxy.vless_tls == "xtls" and {
                alpn = {
                    "http/1.1"
                },
                certificates = {
                    {
                        certificateFile = proxy.web_server_cert_file,
                        keyFile = proxy.web_server_key_file
                    }
                }
            } or nil
        }
    }
end

local function https_inbound()
    if proxy.web_server_protocol == "vless" then
        return https_vless_inbound()
    end
    if proxy.web_server_protocol == "trojan" then
        return https_trojan_inbound()
    end
    return nil
end

local function dns_server_inbounds()
    local result = {}
    for i = proxy.dns_port, proxy.dns_port + (proxy.dns_count or 0), 1 do
        local default_dns_ip, default_dns_port = split_ipv4_host_port(proxy.default_dns, 53)
        table.insert(result, {
            port = i,
            protocol = "dokodemo-door",
            tag = string.format("dns_server_inbound_%d", i),
            settings = {
                address = default_dns_ip,
                port = default_dns_port,
                network = "tcp,udp"
            }
        })
    end
    return result
end

local function dns_server_tags()
    local result = {}
    for i = proxy.dns_port, proxy.dns_port + (proxy.dns_count or 0), 1 do
        table.insert(result, string.format("dns_server_inbound_%d", i))
    end
    return result
end

local function dns_server_outbound()
    return {
        protocol = "dns",
        streamSettings = {
            sockopt = {
                mark = tonumber(proxy.mark)
            }
        },
        tag = "dns_server_outbound"
    }
end

local function upstream_domain_names()
    local result = {
        tcp_server.server,
    }
    if tcp_server.server ~= udp_server.server then
        table.insert(result, udp_server.server)
    end
    return result
end

local function domain_rules(k)
    if proxy[k] == nil then
        return nil
    end

    local result = {}
    for _, x in ipairs(proxy[k]) do
        if x:sub(1, 8) == "geosite:" then
            if geosite_existence then
                table.insert(result, x)
            end
        else
            table.insert(result, x)
        end
    end
    return result
end

local function secure_domain_rules()
    return domain_rules("forwarded_domain_rules")
end

local function fast_domain_rules()
    return domain_rules("bypassed_domain_rules")
end

local function blocked_domain_rules()
    return domain_rules("blocked_domain_rules")
end

local function dns_conf()
    local fast_dns_ip, fast_dns_port = split_ipv4_host_port(proxy.fast_dns, 53)
    local default_dns_ip, default_dns_port = split_ipv4_host_port(proxy.default_dns, 53)
    local hosts = nil
    local servers = {
        {
            address = fast_dns_ip,
            port = fast_dns_port,
            domains = upstream_domain_names(),
        },
        {
            address = default_dns_ip,
            port = default_dns_port,
        }
    }

    if fast_domain_rules() ~= nil then
        table.insert(servers, 2, {
            address = fast_dns_ip,
            port = fast_dns_port,
            domains = fast_domain_rules(),
        })
    end

    if secure_domain_rules() ~= nil then
        local secure_dns_ip, secure_dns_port = split_ipv4_host_port(proxy.secure_dns, 53)
        table.insert(servers, 2, {
            address = secure_dns_ip,
            port = secure_dns_port,
            domains = secure_domain_rules(),
        })
    end

    if blocked_domain_rules() ~= nil then
        hosts = {}
        for _, rule in ipairs(blocked_domain_rules()) do
            hosts[rule] = {"127.127.127.127", "100::6c62:636f:656b:2164"} -- blocked!
        end
    end

    return {
        hosts = hosts,
        servers = servers,
        tag = "dns_conf_inbound"
    }
end

local function api_conf()
    if proxy.xray_api == '1' then
        return {
            tag = "api",
            services = {
                "HandlerService",
                "LoggerService",
                "StatsService"
            }
        }
    else
        return nil
    end
end

local function metrics_conf()
    if optional_feature_1000 then
        if proxy.metrics_server_enable == "1" then
            return {
                tag = "metrics",
            }
        end
    end
    return nil
end

local function inbounds()
    local i = {
        http_inbound(),
        tproxy_tcp_inbound(),
        tproxy_udp_inbound(),
        socks_inbound(),
    }
    for _, v in ipairs(dns_server_inbounds()) do
        table.insert(i, v)
    end
    if proxy.web_server_enable == "1" then
        table.insert(i, https_inbound())
    end
    if optional_feature_1000 then
        if proxy.metrics_server_enable == '1' then
            table.insert(i, {
                listen = "0.0.0.0",
                port = proxy.metrics_server_port or 18888,
                protocol = "dokodemo-door",
                settings = {
                    address = "127.0.0.1"
                },
                tag = "metrics"
            })
        end
    end
    if proxy.xray_api == '1' then
        table.insert(i, {
            listen = "127.0.0.1",
            port = 8080,
            protocol = "dokodemo-door",
            settings = {
                address = "127.0.0.1"
            },
            tag = "api"
        })
    end
    return i
end

local function manual_tproxy_rules()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "manual_tproxy", function(v)
        i = i + 1
        table.insert(result, {
            type = "field",
            inboundTag = {"tproxy_tcp_inbound", "socks_inbound", "https_inbound", "http_inbound"},
            ip = {v.source_addr},
            port = v.source_port,
            outboundTag = string.format("manual_tproxy_outbound_tcp_%d", i)
        })
        table.insert(result, {
            type = "field",
            inboundTag = {"tproxy_udp_inbound"},
            ip = {v.source_addr},
            port = v.source_port,
            outboundTag = string.format("manual_tproxy_outbound_udp_%d", i)
        })
    end)
    return result
end

local function bridges()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "bridge", function(v)
        i = i + 1
        table.insert(result, {
            tag = string.format("bridge_inbound_%d", i),
            domain = v.domain
        })
    end)
    return result
end

local function bridge_outbounds()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "bridge", function(v)
        i = i + 1
        local bridge_server = ucursor:get_all("xray", v.upstream)
        table.insert(result, 1, server_outbound(bridge_server, string.format("bridge_upstream_outbound_%d", i)))
        table.insert(result, 1, {
            tag = string.format("bridge_freedom_outbound_%d", i),
            protocol = "freedom",
            settings = {
                redirect = v.redirect
            }
        })
    end)
    return result
end

local function bridge_rules()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "bridge", function(v)
        i = i + 1
        table.insert(result, {
            type = "field",
            inboundTag = {string.format("bridge_inbound_%d", i)},
            outboundTag = string.format("bridge_freedom_outbound_%d", i)
        })
        table.insert(result, {
            type = "field",
            inboundTag = {string.format("bridge_inbound_%d", i)},
            domain = {string.format("full:%s", v.domain)},
            outboundTag = string.format("bridge_upstream_outbound_%d", i)
        })
    end)
    return result
end

local function rules()
    local result = {
        {
            type = "field",
            inboundTag = {"tproxy_tcp_inbound", "dns_conf_inbound", "socks_inbound", "https_inbound", "http_inbound"},
            outboundTag = "tcp_outbound"
        },
        {
            type = "field",
            inboundTag = {"tproxy_udp_inbound"},
            outboundTag = "udp_outbound"
        },
        {
            type = "field",
            inboundTag = dns_server_tags(),
            outboundTag = "dns_server_outbound"
        },
        {
            type = "field",
            inboundTag = {"api"},
            outboundTag = "api"
        }
    }
    if optional_feature_1000 then
        if proxy.metrics_server_enable == "1" then
            table.insert(result, 1, {
                type = "field",
                inboundTag = {"metrics"},
                outboundTag = "metrics"
            })
        end
    end
    if geoip_existence then
        if proxy.geoip_direct_code ~= nil then
            table.insert(result, 1, {
                type = "field",
                inboundTag = {"tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"},
                outboundTag = "direct",
                ip = {"geoip:" .. proxy.geoip_direct_code}
            })
        end
        table.insert(result, 1, {
            type = "field",
            inboundTag = {"tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound", "socks_inbound", "https_inbound", "http_inbound"},
            outboundTag = "direct",
            ip = {"geoip:private"}
        })
    end
    if proxy.tproxy_sniffing == "1" then
        if secure_domain_rules() ~= nil then
            table.insert(result, 1, {
                type = "field",
                inboundTag = {"tproxy_udp_inbound"},
                outboundTag = "udp_outbound",
                domain = secure_domain_rules(),
            })
            table.insert(result, 1, {
                type = "field",
                inboundTag = {"tproxy_tcp_inbound", "dns_conf_inbound"},
                outboundTag = "tcp_outbound",
                domain = secure_domain_rules(),
            })
        end
        if blocked_domain_rules() ~= nil then
            table.insert(result, 1, {
                type = "field",
                inboundTag = {"tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"},
                outboundTag = "blackhole_outbound",
                domain = blocked_domain_rules(),
            })
        end
        table.insert(result, 1, {
            type = "field",
            inboundTag = {"tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound", "https_inbound", "http_inbound"},
            outboundTag = "direct",
            domain = fast_domain_rules()
        })
    end
    for _, v in ipairs(manual_tproxy_rules()) do
        table.insert(result, 1, v)
    end
    for _, v in ipairs(bridge_rules()) do
        table.insert(result, 1, v)
    end
    return result
end

local function outbounds()
    local result = {
        server_outbound(tcp_server, "tcp_outbound"),
        server_outbound(udp_server, "udp_outbound"),
        direct_outbound(),
        dns_server_outbound(),
        blackhole_outbound()
    }
    for _, v in ipairs(manual_tproxy_outbounds()) do
        table.insert(result, v)
    end
    for _, v in ipairs(bridge_outbounds()) do
        table.insert(result, v)
    end
    return result
end

local function policy()
    local stats = proxy.stats == "1"
    return {
        levels = {
            ["0"] = {
                handshake = proxy.handshake == nil and 4 or tonumber(proxy.handshake),
                connIdle = proxy.conn_idle == nil and 300 or tonumber(proxy.conn_idle),
                uplinkOnly = proxy.uplink_only == nil and 2 or tonumber(proxy.uplink_only),
                downlinkOnly = proxy.downlink_only == nil and 5 or tonumber(proxy.downlink_only),
                bufferSize = proxy.buffer_size == nil and 4 or tonumber(proxy.buffer_size),
                statsUserUplink = stats,
                statsUserDownlink = stats,
            }
        },
        system = {
            statsInboundUplink = stats,
            statsInboundDownlink = stats,
            statsOutboundUplink = stats,
            statsOutboundDownlink = stats
        }
    }
end

local function logging()
    return {
        access = proxy.access_log == "1" and "" or "none",
        loglevel = proxy.loglevel or "warning",
        dnsLog = proxy.dns_log == "1"
    }
end

local function observatory()
    if proxy.observatory == "1" then
        return {
            subjectSelector = {"tcp_outbound", "udp_outbound"},
            probeInterval = "1s"
        }
    end
    return nil
end

local xray = {
    inbounds = inbounds(),
    outbounds = outbounds(),
    dns = dns_conf(),
    api = api_conf(),
    metrics = metrics_conf(),
    policy = policy(),
    log = logging(),
    stats = proxy.stats == "1" and {
        place = "holder"
    } or nil,
    observatory = observatory(),
    reverse = {
        bridges = bridges()
    },
    routing = {
        domainStrategy = proxy.routing_domain_strategy or "AsIs",
        rules = rules()
    }
}

print(json.stringify(xray, true))
