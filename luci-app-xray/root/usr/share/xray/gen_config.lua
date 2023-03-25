#!/usr/bin/lua
local ucursor = require "luci.model.uci"
local json = require "luci.jsonc"
local nixiofs = require "nixio.fs"

local proxy_section = ucursor:get_first("xray", "general")
local proxy = ucursor:get_all("xray", proxy_section)

local tcp_server_section = arg[1] == nil and proxy.main_server or arg[1]
local tcp_server = nil
if tcp_server_section ~= nil and tcp_server_section ~= "disabled" then
    tcp_server = ucursor:get_all("xray", tcp_server_section)
end

local udp_server_section = arg[2] == nil and proxy.tproxy_udp_server or arg[2]
local udp_server = nil
if udp_server_section ~= nil and udp_server_section ~= "disabled" then
    udp_server = ucursor:get_all("xray", udp_server_section)
end

local geoip_existence = false
local geosite_existence = false

local xray_data_file_iterator = nixiofs.dir("/usr/share/xray")

repeat
    local fn = xray_data_file_iterator()
    if fn == "geoip.dat" then
        geoip_existence = true
    end
    if fn == "geosite.dat" then
        geosite_existence = true
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

local function direct_outbound(tag)
    return {
        protocol = "freedom",
        tag = tag,
        settings = {
            domainStrategy = "UseIPv4"
        },
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
            host = server.h2_host,
            read_idle_timeout = server.h2_health_check == "1" and tonumber(server.h2_read_idle_timeout or 10) or nil,
            health_check_timeout = server.h2_health_check == "1" and tonumber(server.h2_health_check_timeout or 20) or nil,
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

local function stream_settings(server, protocol, xtls, tag)
    local security = server[protocol .. "_tls"]
    local tlsSettings = nil
    local xtlsSettings = nil
    if security == "tls" then
        tlsSettings = tls_settings(server, protocol)
    elseif security == "xtls" and xtls then
        xtlsSettings = xtls_settings(server, protocol)
    end
    local dialerProxySection = nil
    local dialerProxy = nil
    if server.dialer_proxy ~= nil and server.dialer_proxy ~= "disabled" then
        dialerProxySection = server.dialer_proxy
        dialerProxy = "dialer_proxy_" .. tag
    end
    return {
        network = server.transport,
        sockopt = {
            mark = tonumber(proxy.mark),
            domainStrategy = server.domain_strategy or "UseIP",
            dialerProxy = dialerProxy
        },
        security = security,
        tlsSettings = tlsSettings,
        xtlsSettings = xtlsSettings,
        quicSettings = stream_quic(server),
        tcpSettings = stream_tcp(server),
        kcpSettings = stream_kcp(server),
        wsSettings = stream_ws(server),
        grpcSettings = stream_grpc(server),
        httpSettings = stream_h2(server)
    }, dialerProxySection
end

local function shadowsocks_outbound(server, tag)
    local streamSettings, dialerProxy = stream_settings(server, "shadowsocks", false, tag)
    return {
        protocol = "shadowsocks",
        tag = tag,
        settings = {
            servers = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    password = server.password,
                    method = server.shadowsocks_security,
                    uot = server.shadowsocks_udp_over_tcp == '1'
                }
            }
        },
        streamSettings = streamSettings
    }, dialerProxy
end

local function vmess_outbound(server, tag)
    local streamSettings, dialerProxy = stream_settings(server, "vmess", false, tag)
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
        streamSettings = streamSettings
    }, dialerProxy
end

local function vless_outbound(server, tag)
    local flow = nil
    if server.vless_tls == "xtls" then
        flow = server.vless_flow
    elseif server.vless_tls == "tls" then
        flow = server.vless_flow_tls
    end
    if flow == "none" then
        flow = nil
    end
    local streamSettings, dialerProxy = stream_settings(server, "vless", true, tag)
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
        streamSettings = streamSettings
    }, dialerProxy
end

local function trojan_outbound(server, tag)
    local flow = nil
    if server.trojan_tls == "xtls" then
        flow = server.trojan_flow
    end
    if flow == "none" then
        flow = nil
    end
    local streamSettings, dialerProxy = stream_settings(server, "trojan", true, tag)
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
        streamSettings = streamSettings
    }, dialerProxy
end

local function server_outbound_recursive(t, server, tag)
    local outbound = nil
    local dialerProxy = nil
    if server.protocol == "vmess" then
        outbound, dialerProxy = vmess_outbound(server, tag)
    elseif server.protocol == "vless" then
        outbound, dialerProxy = vless_outbound(server, tag)
    elseif server.protocol == "shadowsocks" then
        outbound, dialerProxy = shadowsocks_outbound(server, tag)
    elseif server.protocol == "trojan" then
        outbound, dialerProxy = trojan_outbound(server, tag)
    end
    if outbound == nil then
        error("unknown outbound server protocol")
    end

    local result = {outbound}
    for _, f in ipairs(t) do
        table.insert(result, 1, f)
    end
    if dialerProxy ~= nil then
        local dialer_proxy_section = ucursor:get_all("xray", dialerProxy)
        return server_outbound_recursive(result, dialer_proxy_section, "dialer_proxy_" .. tag)
    else
        return result
    end
end

local function server_outbound(server, tag)
    if server == nil then
        return {direct_outbound(tag)}
    end
    return server_outbound_recursive({}, server, tag)
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

local function tls_inbound_settings()
    return {
        alpn = {
            "http/1.1"
        },
        certificates = {
            {
                certificateFile = proxy.web_server_cert_file,
                keyFile = proxy.web_server_key_file
            }
        }
    }
end

local function https_trojan_inbound()
    local flow = nil
    if proxy.trojan_tls == "xtls" then
        flow = proxy.trojan_flow
    end
    if flow == "none" then
        flow = nil
    end
    return {
        port = proxy.web_server_port or 443,
        protocol = "trojan",
        tag = "https_inbound",
        settings = {
            clients = {
                {
                    password = proxy.web_server_password,
                    flow = flow
                }
            },
            fallbacks = fallbacks()
        },
        streamSettings = {
            network = "tcp",
            security = proxy.trojan_tls,
            tlsSettings = proxy.trojan_tls == "tls" and tls_inbound_settings() or nil,
            xtlsSettings = proxy.trojan_tls == "xtls" and tls_inbound_settings() or nil
        }
    }
end

local function https_vless_inbound()
    local flow = nil
    if proxy.vless_tls == "xtls" then
        flow = proxy.vless_flow
    elseif proxy.vless_tls == "tls" then
        flow = proxy.vless_flow_tls
    end
    if flow == "none" then
        flow = nil
    end
    return {
        port = proxy.web_server_port or 443,
        protocol = "vless",
        tag = "https_inbound",
        settings = {
            clients = {
                {
                    id = proxy.web_server_password,
                    flow = flow
                }
            },
            decryption = "none",
            fallbacks = fallbacks()
        },
        streamSettings = {
            network = "tcp",
            security = proxy.vless_tls,
            tlsSettings = proxy.vless_tls == "tls" and tls_inbound_settings() or nil,
            xtlsSettings = proxy.vless_tls == "xtls" and tls_inbound_settings() or nil
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
    local default_dns_ip, default_dns_port = split_ipv4_host_port(proxy.default_dns, 53)
    for i = proxy.dns_port, proxy.dns_port + (proxy.dns_count or 0), 1 do
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
    local domain_names = {}
    local hash = {}
    local result = {}
    if tcp_server ~= nil then
        table.insert(domain_names, tcp_server.server)
    end
    if udp_server ~= nil then
        table.insert(domain_names, udp_server.server)
    end
    for _, v in ipairs(domain_names) do
        if (not hash[v]) then
            result[#result+1] = v
            hash[v] = true
        end
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
        tag = "dns_conf_inbound",
        queryStrategy = "UseIPv4"
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
    if proxy.metrics_server_enable == "1" then
        return {
            tag = "metrics",
        }
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

local function manual_tproxy_outbounds()
    local result = {}
    local i = 0
    ucursor:foreach("xray", "manual_tproxy", function(v)
        i = i + 1
        local tcp_tag = "direct"
        local udp_tag = "direct"
        if v.force_forward == "1" then
            if v.force_forward_server_tcp ~= nil then
                if v.force_forward_server_tcp == proxy.main_server then
                    tcp_tag = "tcp_outbound"
                else
                    tcp_tag = string.format("manual_tproxy_force_forward_tcp_outbound_%d", i)
                    local force_forward_server_tcp = ucursor:get_all("xray", v.force_forward_server_tcp)
                    for _, f in ipairs(server_outbound(force_forward_server_tcp, tcp_tag)) do
                        table.insert(result, f)
                    end
                end
            else
                tcp_tag = "tcp_outbound"
            end
            if v.force_forward_server_udp ~= nil then
                if v.force_forward_server_udp == proxy.tproxy_udp_server then
                    udp_tag = "udp_outbound"
                else
                    udp_tag = string.format("manual_tproxy_force_forward_udp_outbound_%d", i)
                    local force_forward_server_udp = ucursor:get_all("xray", v.force_forward_server_udp)
                    for _, f in ipairs(server_outbound(force_forward_server_udp, udp_tag)) do
                        table.insert(result, f)
                    end                
                end
            else
                udp_tag = "udp_outbound"
            end
        end

        table.insert(result, {
            protocol = "freedom",
            tag = string.format("manual_tproxy_outbound_tcp_%d", i),
            settings = {
                redirect = string.format("%s:%d", v.dest_addr, v.dest_port),
                domainStrategy = v.domain_strategy or "UseIP"
            },
            proxySettings = {
                tag = tcp_tag
            }
        })
        table.insert(result, {
            protocol = "freedom",
            tag = string.format("manual_tproxy_outbound_udp_%d", i),
            settings = {
                redirect = string.format("%s:%d", v.dest_addr, v.dest_port),
                domainStrategy = v.domain_strategy or "UseIP"
            },
            proxySettings = {
                tag = udp_tag
            }
        })
    end)
    return result
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
        for _, f in ipairs(server_outbound(bridge_server, string.format("bridge_upstream_outbound_%d", i))) do
            table.insert(result, 1, f)
        end
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
    if proxy.metrics_server_enable == "1" then
        table.insert(result, 1, {
            type = "field",
            inboundTag = {"metrics"},
            outboundTag = "metrics"
        })
    end
    if geoip_existence then
        if proxy.geoip_direct_code == nil or proxy.geoip_direct_code == "upgrade" then
            if proxy.geoip_direct_code_list ~= nil then
                local geoip_direct_code_list = {}
                for _, v in ipairs(proxy.geoip_direct_code_list) do
                    table.insert(geoip_direct_code_list, "geoip:" .. v)
                end
                table.insert(result, 1, {
                    type = "field",
                    inboundTag = {"tproxy_tcp_inbound", "tproxy_udp_inbound", "dns_conf_inbound"},
                    outboundTag = "direct",
                    ip = geoip_direct_code_list
                })
            end
        else
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
        if proxy.direct_bittorrent == "1" then
            table.insert(result, 1, {
                type = "field",
                outboundTag: "direct",
                protocol: ["bittorrent"]
            })
        end
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
        direct_outbound("direct"),
        dns_server_outbound(),
        blackhole_outbound()
    }
    for _, v in ipairs(server_outbound(tcp_server, "tcp_outbound")) do
        table.insert(result, v)
    end
    for _, v in ipairs(server_outbound(udp_server, "udp_outbound")) do
        table.insert(result, v)
    end
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
            subjectSelector = {"tcp_outbound", "udp_outbound", "direct", "manual_tproxy_force_forward"},
            probeInterval = "1s",
            probeUrl = "http://www.apple.com/library/test/success.html"
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
