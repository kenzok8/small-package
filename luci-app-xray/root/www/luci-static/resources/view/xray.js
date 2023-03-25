'use strict';
'require view';
'require uci';
'require form';
'require fs';
'require network';
'require tools.widgets as widgets';

function validate_object(id, a) {
    if (a == "") {
        return true
    }
    try {
        const t = JSON.parse(a)
        if (Array.isArray(t)) {
            return "TypeError: Requires an object here, got an array"
        }
        if (t instanceof Object) {
            return true
        }
        return "TypeError: Requires an object here, got a " + typeof t
    } catch (e) {
        return e
    }
}

function add_flow_and_stream_security_conf(s, tab_name, depends_field_name, protocol_name, have_xtls, have_tls_flow, client_side, fw4_enabled) {
    let o = s.taboption(tab_name, form.ListValue, `${protocol_name}_tls`, _(`[${protocol_name}] Stream Security`))
    let odep = {}
    odep[depends_field_name] = protocol_name
    if (client_side) {
        o.depends(depends_field_name, protocol_name)
        o.value("none", "None")
    } else {
        odep["web_server_enable"] = "1"
    }
    o.value("tls", "TLS")
    if (have_xtls) {
        o.value("xtls", "XTLS")
    }
    if (have_tls_flow && fw4_enabled) {
        o.value("reality", "REALITY (Experimental)")
    }
    o.depends(odep)
    o.rmempty = false
    o.modalonly = true

    if (have_xtls) {
        let flow = s.taboption(tab_name, form.ListValue, `${protocol_name}_flow`, _(`[${protocol_name}][xtls] Flow`))
        let flow_dep = {}
        flow_dep[depends_field_name] = protocol_name
        flow_dep[`${protocol_name}_tls`] = "xtls"
        flow.value("none", "none")
        flow.value("xtls-rprx-origin", "xtls-rprx-origin")
        flow.value("xtls-rprx-origin-udp443", "xtls-rprx-origin-udp443")
        flow.value("xtls-rprx-direct", "xtls-rprx-direct")
        flow.value("xtls-rprx-direct-udp443", "xtls-rprx-direct-udp443")
        if (client_side) {
            flow.value("xtls-rprx-splice", "xtls-rprx-splice")
            flow.value("xtls-rprx-splice-udp443", "xtls-rprx-splice-udp443")
        } else {
            flow_dep["web_server_enable"] = "1"
        }
        flow.depends(flow_dep)
        flow.rmempty = false
        flow.modalonly = true
    }

    if (have_tls_flow) {
        let flow_tls = s.taboption(tab_name, form.ListValue, `${protocol_name}_flow_tls`, _(`[${protocol_name}][tls] Flow`))
        let flow_tls_dep = {}
        flow_tls_dep[depends_field_name] = protocol_name
        flow_tls_dep[`${protocol_name}_tls`] = "tls"
        flow_tls.value("none", "none")
        flow_tls.value("xtls-rprx-vision", "xtls-rprx-vision")
        flow_tls.value("xtls-rprx-vision-udp443", "xtls-rprx-vision-udp443")
        if (client_side) {
            // wait for some other things
        } else {
            flow_tls_dep["web_server_enable"] = "1"
        }
        flow_tls.depends(flow_tls_dep)
        flow_tls.rmempty = false
        flow_tls.modalonly = true

        let flow_reality = s.taboption(tab_name, form.ListValue, `${protocol_name}_flow_reality`, _(`[${protocol_name}][reality] Flow`))
        let flow_reality_dep = {}
        flow_reality_dep[depends_field_name] = protocol_name
        flow_reality_dep[`${protocol_name}_tls`] = "reality"
        flow_reality.value("none", "none")
        flow_reality.value("xtls-rprx-vision", "xtls-rprx-vision")
        flow_reality.value("xtls-rprx-vision-udp443", "xtls-rprx-vision-udp443")
        if (client_side) {
            // wait for some other things
        } else {
            flow_reality_dep["web_server_enable"] = "1"
        }
        flow_reality.depends(flow_reality_dep)
        flow_reality.rmempty = false
        flow_reality.modalonly = true

        o = s.taboption(tab_name, form.Flag, `${protocol_name}_reality_show`, _(`[${protocol_name}][reality] Show`))
        o.depends(`${protocol_name}_tls`, "reality")
        o.rmempty = true
        o.modalonly = true
    }

    if (client_side) {
        o = s.taboption(tab_name, form.Value, `${protocol_name}_tls_host`, _(`[${protocol_name}][tls] Server Name`))
        o.depends(`${protocol_name}_tls`, "tls")
        o.rmempty = true
        o.modalonly = true

        o = s.taboption(tab_name, form.Flag, `${protocol_name}_tls_insecure`, _(`[${protocol_name}][tls] Allow Insecure`))
        o.depends(`${protocol_name}_tls`, "tls")
        o.rmempty = false
        o.modalonly = true

        o = s.taboption(tab_name, form.Value, `${protocol_name}_tls_fingerprint`, _(`[${protocol_name}][tls] Fingerprint`))
        o.depends(`${protocol_name}_tls`, "tls")
        o.value("", "(not set)")
        o.value("chrome", "chrome")
        o.value("firefox", "firefox")
        o.value("safari", "safari")
        o.value("ios", "ios")
        o.value("android", "android")
        o.value("edge", "edge")
        o.value("360", "360")
        o.value("qq", "qq")
        o.value("random", "random")
        o.value("randomized", "randomized")
        o.rmempty = true
        o.modalonly = true

        o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_tls_alpn`, _(`[${protocol_name}][tls] ALPN`))
        o.depends(`${protocol_name}_tls`, "tls")
        o.value("h2", "h2")
        o.value("http/1.1", "http/1.1")
        o.rmempty = true
        o.modalonly = true

        if (have_xtls) {
            o = s.taboption(tab_name, form.Value, `${protocol_name}_xtls_host`, _(`[${protocol_name}][xtls] Server Name`))
            o.depends(`${protocol_name}_tls`, "xtls")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Flag, `${protocol_name}_xtls_insecure`, _(`[${protocol_name}][xtls] Allow Insecure`))
            o.depends(`${protocol_name}_tls`, "xtls")
            o.rmempty = false
            o.modalonly = true

            o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_xtls_alpn`, _(`[${protocol_name}][xtls] ALPN`))
            o.depends(`${protocol_name}_tls`, "xtls")
            o.value("h2", "h2")
            o.value("http/1.1", "http/1.1")
            o.rmempty = true
            o.modalonly = true
        }
        if (have_tls_flow) {
            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_fingerprint`, _(`[${protocol_name}][reality] Fingerprint`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.value("chrome", "chrome")
            o.value("firefox", "firefox")
            o.value("safari", "safari")
            o.value("ios", "ios")
            o.value("android", "android")
            o.value("edge", "edge")
            o.value("360", "360")
            o.value("qq", "qq")
            o.value("random", "random")
            o.value("randomized", "randomized")
            o.rmempty = false
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_server_name`, _(`[${protocol_name}][reality] Server Name`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_public_key`, _(`[${protocol_name}][reality] Public Key`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_short_id`, _(`[${protocol_name}][reality] Short Id`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_spider_x`, _(`[${protocol_name}][reality] SpiderX`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true
        }
    } else {
        let tls_cert_key_dep = {"web_server_enable": "1"}
        tls_cert_key_dep[`${protocol_name}_tls`] = "tls"
        o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_tls_cert_file`, _(`[${protocol_name}][tls] Certificate File`));
        o.root_directory = "/etc/luci-uploads/xray"
        o.depends(tls_cert_key_dep)
        
        o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_tls_key_file`, _(`[${protocol_name}][tls] Private Key File`));
        o.root_directory = "/etc/luci-uploads/xray"
        o.depends(tls_cert_key_dep)

        if (have_xtls) {
            let xtls_cert_key_dep = {"web_server_enable": "1"}
            xtls_cert_key_dep[`${protocol_name}_tls`] = "xtls"

            o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_xtls_cert_file`, _(`[${protocol_name}][xtls] Certificate File`));
            o.root_directory = "/etc/luci-uploads/xray"
            o.depends(xtls_cert_key_dep)
            
            o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_xtls_key_file`, _(`[${protocol_name}][xtls] Private Key File`));
            o.root_directory = "/etc/luci-uploads/xray"
            o.depends(xtls_cert_key_dep)
        }

        if (have_tls_flow) {
            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_dest`, _(`[${protocol_name}][reality] Dest`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.datatype = "hostport"
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_xver`, _(`[${protocol_name}][reality] Xver`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.datatype = "integer"
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_reality_server_names`, _(`[${protocol_name}][reality] Server Names`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_private_key`, _(`[${protocol_name}][reality] Private Key`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_min_client_ver`, _(`[${protocol_name}][reality] Min Client Ver`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_max_client_ver`, _(`[${protocol_name}][reality] Max Client Ver`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_max_time_diff`, _(`[${protocol_name}][reality] Max Time Diff`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.datatype = "integer"
            o.rmempty = true
            o.modalonly = true

            o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_reality_short_ids`, _(`[${protocol_name}][reality] Short Ids`))
            o.depends(`${protocol_name}_tls`, "reality")
            o.rmempty = true
            o.modalonly = true
        }
    }
}

function check_resource_files(load_result) {
    let geoip_existence = false;
    let geoip_size = 0;
    let geosite_existence = false;
    let geosite_size = 0;
    let firewall4 = false;
    let xray_bin_default = false;
    let xray_running = false;
    let optional_features = {};
    for (const f of load_result) {
        if (f.name == "xray") {
            xray_bin_default = true;
        }
        if (f.name == "xray.pid") {
            xray_running = true;
        }
        if (f.name == "geoip.dat") {
            geoip_existence = true;
            geoip_size = '%.2mB'.format(f.size);
        }
        if (f.name == "geosite.dat") {
            geosite_existence = true;
            geosite_size = '%.2mB'.format(f.size);
        }
        if (f.name == "firewall_include.ut") {
            firewall4 = true;
        }
        if (f.name.startsWith("optional_feature_")) {
            optional_features[f.name] = true;
        }
    }
    return {
        geoip_existence: geoip_existence,
        geoip_size: geoip_size,
        geosite_existence: geosite_existence,
        geosite_size: geosite_size,
        optional_features: optional_features,
        firewall4: firewall4,
        xray_bin_default: xray_bin_default,
        xray_running: xray_running,
    }
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load("xray"),
            fs.list("/usr/share/xray"),
            network.getHostHints()
        ])
    },

    render: function (load_result) {
        const config_data = load_result[0];
        const geoip_direct_code = uci.get_first(config_data, "general", "geoip_direct_code");
        const { geoip_existence, geoip_size, geosite_existence, geosite_size, optional_features, firewall4, xray_bin_default, xray_running } = check_resource_files(load_result[1]);
        const status_text = xray_running ? _("[Xray is running]") : _("[Xray is stopped]");
        const fw_text = firewall4 ? _("[fw4]"): _("[fw3]");

        let asset_file_status = _('WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/xray. Xray may not work properly. See <a href="https://github.com/yichya/luci-app-xray">here</a> for help.')
        if (geoip_existence) {
            if (geosite_existence) {
                asset_file_status = _('Asset files check: ') + `geoip.dat ${geoip_size}; geosite.dat ${geosite_size}. ` + _('Report issues or request for features <a href="https://github.com/yichya/luci-app-xray">here</a>.')
            }
        }

        const m = new form.Map('xray', _('Xray'), status_text + " " + fw_text + " " + asset_file_status);

        var s, o, ss;

        s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab('general', _('General Settings'));

        o = s.taboption('general', form.Value, 'xray_bin', _('Xray Executable Path'))
        o.rmempty = false
        if (xray_bin_default) {
            o.value("/usr/bin/xray", _("/usr/bin/xray (default, exist)"))
        }

        o = s.taboption('general', form.ListValue, 'main_server', _('TCP Server'))
        o.datatype = "uciname"
        o.value("disabled", _("Disabled"))
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }

        o = s.taboption('general', form.ListValue, 'tproxy_udp_server', _('UDP Server'))
        o.datatype = "uciname"
        o.value("disabled", _("Disabled"))
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }

        o = s.taboption('general', form.Flag, 'transparent_proxy_enable', _('Enable Transparent Proxy'), _('This enables DNS query forwarding and TProxy for both TCP and UDP connections.'))

        o = s.taboption('general', form.Flag, 'tproxy_sniffing', _('Enable Sniffing'), _('If sniffing is enabled, requests will be routed according to domain settings in "DNS Settings" tab.'))
        o.depends("transparent_proxy_enable", "1")

        o = s.taboption('general', form.Flag, 'route_only', _('Route Only'), _('Use sniffed domain for routing only but still access through IP. Reduces unnecessary DNS requests. See <a href="https://github.com/XTLS/Xray-core/commit/a3023e43ef55d4498b1afbc9a7fe7b385138bb1a">here</a> for help.'))
        o.depends({ "transparent_proxy_enable": "1", "tproxy_sniffing": "1" })

        o = s.taboption('general', form.Flag, 'direct_bittorrent', _('Bittorrent Direct'), _("If enabled, all bittorrent request won't be forwarded through Xray."))
        o.depends({ "transparent_proxy_enable": "1", "tproxy_sniffing": "1" })

        o = s.taboption('general', form.SectionValue, "xray_servers", form.GridSection, 'servers', _('Xray Servers'), _("Servers are referenced by index (order in the following list). Deleting servers may result in changes of upstream servers actually used by proxy and bridge."))
        ss = o.subsection
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        ss.tab('general', _('General Settings'));

        o = ss.taboption('general', form.Value, "alias", _("Alias (optional)"))
        o.rmempty = true

        o = ss.taboption('general', form.Value, 'server', _('Server Hostname'))
        o.datatype = 'host'

        o = ss.taboption('general', form.ListValue, 'domain_strategy', _('Domain Strategy'))
        o.value("UseIP")
        o.value("UseIPv4")
        o.value("UseIPv6")
        o.default = "UseIP"
        o.modalonly = true

        o = ss.taboption('general', form.Value, 'server_port', _('Server Port'))
        o.datatype = 'port'
        o.placeholder = '443'

        o = ss.taboption('general', form.Value, 'password', _('UserId / Password'), _('Fill user_id for vmess / VLESS, or password for shadowsocks / trojan (also supports <a href="https://github.com/XTLS/Xray-core/issues/158">Xray UUID Mapping</a>)'))
        o.modalonly = true

        ss.tab('protocol', _('Protocol Settings'));

        o = ss.taboption('protocol', form.ListValue, "protocol", _("Protocol"))
        o.value("vmess", "VMess")
        o.value("vless", "VLESS")
        o.value("trojan", "Trojan")
        o.value("shadowsocks", "Shadowsocks")
        o.rmempty = false

        add_flow_and_stream_security_conf(ss, "protocol", "protocol", "trojan", true, false, true, firewall4)

        o = ss.taboption('protocol', form.ListValue, "shadowsocks_security", _("[shadowsocks] Encrypt Method"))
        o.depends("protocol", "shadowsocks")
        o.value("none", "none")
        o.value("aes-256-gcm", "aes-256-gcm")
        o.value("aes-128-gcm", "aes-128-gcm")
        o.value("chacha20-poly1305", "chacha20-poly1305")
        o.value("2022-blake3-aes-128-gcm", "2022-blake3-aes-128-gcm")
        o.value("2022-blake3-aes-256-gcm", "2022-blake3-aes-256-gcm")
        o.value("2022-blake3-chacha20-poly1305", "2022-blake3-chacha20-poly1305")
        o.rmempty = false
        o.modalonly = true

        o = ss.taboption('protocol', form.Flag, 'shadowsocks_udp_over_tcp', _('[shadowsocks] UDP over TCP'), _('Only available for shadowsocks-2022 ciphers (2022-*)'))
        o.depends("shadowsocks_security", /2022/)
        o.rmempty = false
        o.modalonly = true

        add_flow_and_stream_security_conf(ss, "protocol", "protocol", "shadowsocks", false, false, true, firewall4)

        o = ss.taboption('protocol', form.ListValue, "vmess_security", _("[vmess] Encrypt Method"))
        o.depends("protocol", "vmess")
        o.value("none", "none")
        o.value("auto", "auto")
        o.value("aes-128-gcm", "aes-128-gcm")
        o.value("chacha20-poly1305", "chacha20-poly1305")
        o.rmempty = false
        o.modalonly = true

        o = ss.taboption('protocol', form.ListValue, "vmess_alter_id", _("[vmess] AlterId"), _("Deprecated. Make sure you always use VMessAEAD."))
        o.depends("protocol", "vmess")
        o.value(0, "0 (this enables VMessAEAD)")
        o.value(1, "1")
        o.value(4, "4")
        o.value(16, "16")
        o.value(64, "64")
        o.value(256, "256")
        o.rmempty = false
        o.modalonly = true

        add_flow_and_stream_security_conf(ss, "protocol", "protocol", "vmess", false, false, true, firewall4)

        o = ss.taboption('protocol', form.ListValue, "vless_encryption", _("[vless] Encrypt Method"))
        o.depends("protocol", "vless")
        o.value("none", "none")
        o.rmempty = false
        o.modalonly = true

        add_flow_and_stream_security_conf(ss, "protocol", "protocol", "vless", true, true, true, firewall4)

        ss.tab('transport', _('Transport Settings'));

        o = ss.taboption('transport', form.ListValue, 'transport', _('Transport'))
        o.value("tcp", "TCP")
        o.value("mkcp", "mKCP")
        o.value("ws", "WebSocket")
        o.value("h2", "HTTP/2")
        o.value("quic", "QUIC")
        o.value("grpc", "gRPC")
        o.rmempty = false

        o = ss.taboption('transport', form.ListValue, "tcp_guise", _("[tcp] Fake Header Type"))
        o.depends("transport", "tcp")
        o.value("none", _("None"))
        o.value("http", "HTTP")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.DynamicList, "http_host", _("[tcp][fake_http] Host"))
        o.depends("tcp_guise", "http")
        o.rmempty = false
        o.modalonly = true

        o = ss.taboption('transport', form.DynamicList, "http_path", _("[tcp][fake_http] Path"))
        o.depends("tcp_guise", "http")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.ListValue, "mkcp_guise", _("[mkcp] Fake Header Type"))
        o.depends("transport", "mkcp")
        o.value("none", _("None"))
        o.value("srtp", _("VideoCall (SRTP)"))
        o.value("utp", _("BitTorrent (uTP)"))
        o.value("wechat-video", _("WechatVideo"))
        o.value("dtls", "DTLS 1.2")
        o.value("wireguard", "WireGuard")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_mtu", _("[mkcp] Maximum Transmission Unit"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 1350
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_tti", _("[mkcp] Transmission Time Interval"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 50
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_uplink_capacity", _("[mkcp] Uplink Capacity"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 5
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_downlink_capacity", _("[mkcp] Downlink Capacity"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 20
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_read_buffer_size", _("[mkcp] Read Buffer Size"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 2
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_write_buffer_size", _("[mkcp] Write Buffer Size"))
        o.datatype = "uinteger"
        o.depends("transport", "mkcp")
        o.default = 2
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Flag, "mkcp_congestion", _("[mkcp] Congestion Control"))
        o.depends("transport", "mkcp")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "mkcp_seed", _("[mkcp] Seed"))
        o.depends("transport", "mkcp")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.ListValue, "quic_security", _("[quic] Security"))
        o.depends("transport", "quic")
        o.value("none", "none")
        o.value("aes-128-gcm", "aes-128-gcm")
        o.value("chacha20-poly1305", "chacha20-poly1305")
        o.rmempty = false
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "quic_key", _("[quic] Key"))
        o.depends("transport", "quic")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.ListValue, "quic_guise", _("[quic] Fake Header Type"))
        o.depends("transport", "quic")
        o.value("none", _("None"))
        o.value("srtp", _("VideoCall (SRTP)"))
        o.value("utp", _("BitTorrent (uTP)"))
        o.value("wechat-video", _("WechatVideo"))
        o.value("dtls", "DTLS 1.2")
        o.value("wireguard", "WireGuard")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.DynamicList, "h2_host", _("[http2] Host"))
        o.depends("transport", "h2")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "h2_path", _("[http2] Path"))
        o.depends("transport", "h2")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Flag, "h2_health_check", _("[h2] Health Check"))
        o.depends("transport", "h2")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "h2_read_idle_timeout", _("[h2] Read Idle Timeout"))
        o.depends({ "transport": "h2", "h2_health_check": "1" })
        o.rmempty = true
        o.modalonly = true
        o.default = 10
        o.datatype = 'integer'

        o = ss.taboption('transport', form.Value, "h2_health_check_timeout", _("[h2] Health Check Timeout"))
        o.depends({ "transport": "h2", "h2_health_check": "1" })
        o.rmempty = true
        o.modalonly = true
        o.default = 20
        o.datatype = 'integer'

        o = ss.taboption('transport', form.Value, "grpc_service_name", _("[grpc] Service Name"))
        o.depends("transport", "grpc")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Flag, "grpc_multi_mode", _("[grpc] Multi Mode"))
        o.depends("transport", "grpc")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Flag, "grpc_health_check", _("[grpc] Health Check"))
        o.depends("transport", "grpc")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "grpc_idle_timeout", _("[grpc] Idle Timeout"))
        o.depends({ "transport": "grpc", "grpc_health_check": "1" })
        o.rmempty = true
        o.modalonly = true
        o.default = 10
        o.datatype = 'integer'

        o = ss.taboption('transport', form.Value, "grpc_health_check_timeout", _("[grpc] Health Check Timeout"))
        o.depends({ "transport": "grpc", "grpc_health_check": "1" })
        o.rmempty = true
        o.modalonly = true
        o.default = 20
        o.datatype = 'integer'

        o = ss.taboption('transport', form.Flag, "grpc_permit_without_stream", _("[grpc] Permit Without Stream"))
        o.depends({ "transport": "grpc", "grpc_health_check": "1" })
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "grpc_initial_windows_size", _("[grpc] Initial Windows Size"), _("Set to 524288 to avoid Cloudflare sending ENHANCE_YOUR_CALM."))
        o.depends("transport", "grpc")
        o.rmempty = true
        o.modalonly = true
        o.default = 0
        o.datatype = 'integer'

        o = ss.taboption('transport', form.Value, "ws_host", _("[websocket] Host"))
        o.depends("transport", "ws")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.Value, "ws_path", _("[websocket] Path"))
        o.depends("transport", "ws")
        o.rmempty = true
        o.modalonly = true

        o = ss.taboption('transport', form.ListValue, 'dialer_proxy', _('Dialer Proxy'), _('Similar to <a href="https://xtls.github.io/config/outbound.html#proxysettingsobject">ProxySettings.Tag</a>'))
        o.datatype = "uciname"
        o.value("disabled", _("Disabled"))
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }
        o.modalonly = true

        if (firewall4) {
            ss.tab('custom', _('Custom Options'));

            o = ss.taboption('custom', form.TextValue, 'custom_config', _('Custom Configurations'), _('Configurations here override settings in the previous tabs with the following rules: <ol><li>Object values will be replaced recursively so settings in previous tabs matters.</li><li>Arrays will be replaced entirely instead of being merged.</li><li>Tag <code>tag</code> is ignored. </li></ol>Override rules here may be changed later. Use this only for experimental or pre-release features.'))
            o.modalonly = true
            o.monospace = true
            o.rows = 10
            o.validate = validate_object;
        }

        s.tab('proxy', _('Proxy Settings'));

        o = s.taboption('proxy', form.Value, 'tproxy_port_tcp', _('Transparent Proxy Port (TCP)'))
        o.datatype = 'port'
        o.default = 1080

        o = s.taboption('proxy', form.Value, 'tproxy_port_udp', _('Transparent Proxy Port (UDP)'))
        o.datatype = 'port'
        o.default = 1081

        o = s.taboption('proxy', form.Value, 'socks_port', _('Socks5 Proxy Port'))
        o.datatype = 'port'
        o.default = 1082

        o = s.taboption('proxy', form.Value, 'http_port', _('HTTP Proxy Port'))
        o.datatype = 'port'
        o.default = 1083

        if (firewall4) {
            o = s.taboption('proxy', form.DynamicList, 'uids_direct', _('Skip Proxy for uids'), _("Processes started by users with these uids won't be forwarded through Xray."))
            o.datatype = "integer"

            o = s.taboption('proxy', form.DynamicList, 'gids_direct', _('Skip Proxy for gids'), _("Processes started by users in groups with these gids won't be forwarded through Xray."))
            o.datatype = "integer"
        }

        o = s.taboption('proxy', widgets.DeviceSelect, 'lan_ifaces', _("LAN Interface"))
        o.noaliases = true
        o.rmempty = false
        o.nocreate = true

        o = s.taboption('proxy', form.SectionValue, "access_control_lan_hosts", form.TableSection, 'lan_hosts', _('LAN Hosts Access Control'), _("Will not enable transparent proxy for these MAC addresses."))

        ss = o.subsection;
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        o = ss.option(form.Value, "macaddr", _("MAC Address"))
        L.sortedKeys(load_result[2].hosts).forEach(function (mac) {
            o.value(mac, E([], [mac, ' (', E('strong', [load_result[2].hosts[mac].name || L.toArray(load_result[2].hosts[mac].ipaddrs || load_result[2].hosts[mac].ipv4)[0] || L.toArray(load_result[2].hosts[mac].ip6addrs || load_result[2].hosts[mac].ipv6)[0] || '?']), ')']));
        });

        o.datatype = "macaddr"
        o.rmempty = false

        o = ss.option(form.ListValue, "bypassed", _("Access Control Strategy"))
        o.value("0", "Always forwarded")
        o.value("1", "Always bypassed")
        o.rmempty = false

        s.tab('dns', _('DNS Settings'));

        o = s.taboption('dns', form.Value, 'fast_dns', _('Fast DNS'), _("DNS for resolving outbound domains and following bypassed domains"))
        o.datatype = 'or(ip4addr, ip4addrport)'
        o.placeholder = "114.114.114.114"

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "bypassed_domain_rules", _('Bypassed domain rules'), _('Specify rules like <code>geosite:cn</code> or <code>domain:bilibili.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'))
        } else {
            o = s.taboption('dns', form.DynamicList, 'bypassed_domain_rules', _('Bypassed domain rules'), _('Specify rules like <code>domain:bilibili.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'))
        }
        o.rmempty = true

        o = s.taboption('dns', form.Value, 'secure_dns', _('Secure DNS'), _("DNS for resolving known polluted domains (specify forwarded domain rules here)"))
        o.datatype = 'or(ip4addr, ip4addrport)'
        o.placeholder = "1.1.1.1"

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "forwarded_domain_rules", _('Forwarded domain rules'), _('Specify rules like <code>geosite:geolocation-!cn</code> or <code>domain:youtube.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'))
        } else {
            o = s.taboption('dns', form.DynamicList, 'forwarded_domain_rules', _('Forwarded domain rules'), _('Specify rules like <code>domain:youtube.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'))
        }
        o.rmempty = true

        o = s.taboption('dns', form.Value, 'default_dns', _('Default DNS'), _("DNS for resolving other sites (not in the rules above) and DNS records other than A or AAAA (TXT and MX for example)"))
        o.datatype = 'or(ip4addr, ip4addrport)'
        o.placeholder = "8.8.8.8"

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "blocked_domain_rules", _('Blocked domain rules'), _('Specify rules like <code>geosite:category-ads</code> or <code>domain:baidu.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'))
        } else {
            o = s.taboption('dns', form.DynamicList, 'blocked_domain_rules', _('Blocked domain rules'), _('Specify rules like <code>domain:baidu.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'))
        }
        o.rmempty = true

        o = s.taboption('dns', form.Value, 'dns_port', _('Xray DNS Server Port'), _("Do not use port 53 (dnsmasq), port 5353 (mDNS) or other common ports"))
        o.datatype = 'port'
        o.default = 5300

        o = s.taboption('dns', form.Value, 'dns_count', _('Extra DNS Server Ports'), _('Listen for DNS Requests on multiple ports (all of which serves as dnsmasq upstream servers).<br/>For example if Xray DNS Server Port is 5300 and use 3 extra ports, 5300 - 5303 will be used for DNS requests.<br/>Increasing this value may help reduce the possibility of temporary DNS lookup failures.'))
        o.datatype = 'range(0, 50)'
        o.default = 0

        s.tab('transparent_proxy_rules', _('Transparent Proxy Rules'));

        if (geoip_direct_code === "upgrade" || geoip_direct_code === void 0) {
            if (geoip_existence) {
                o = s.taboption('transparent_proxy_rules', form.DynamicList, 'geoip_direct_code_list', _('GeoIP Direct Code List'), _("Hosts in these GeoIP sets will not be forwarded through Xray. Remove all items to forward all non-private hosts."))
            } else {
                o = s.taboption('transparent_proxy_rules', form.DynamicList, 'geoip_direct_code_list', _('GeoIP Direct Code List'), _("Resource file /usr/share/xray/geoip.dat not exist. All network traffic will be forwarded. <br/> Compile your firmware again with data files to use this feature, or<br/><a href=\"https://github.com/v2fly/geoip\">download one</a> (maybe disable transparent proxy first) and upload it to your router."))
                o.readonly = true
            }
        } else {
            if (geoip_existence) {
                o = s.taboption('transparent_proxy_rules', form.Value, 'geoip_direct_code', _('GeoIP Direct Code'), _("Hosts in this GeoIP set will not be forwarded through Xray. <br/> Switching to new format (by selecting 'Unspecified') is recommended for multiple GeoIP options here, <br/> and is required if you want to forward all non-private hosts. This legacy option will be removed later."))
            } else {
                o = s.taboption('transparent_proxy_rules', form.Value, 'geoip_direct_code', _('GeoIP Direct Code'), _("Resource file /usr/share/xray/geoip.dat not exist. All network traffic will be forwarded. <br/> Compile your firmware again with data files to use this feature, or<br/><a href=\"https://github.com/v2fly/geoip\">download one</a> (maybe disable transparent proxy first) and upload it to your router."))
                o.readonly = true
            }
        }
        o.value("cn", "cn")
        o.value("telegram", "telegram")
        o.datatype = "string"

        o = s.taboption('transparent_proxy_rules', form.ListValue, 'routing_domain_strategy', _('Routing Domain Strategy'), _("Domain resolution strategy when matching domain against rules."))
        o.value("AsIs", "AsIs")
        o.value("IPIfNonMatch", "IPIfNonMatch")
        o.value("IPOnDemand", "IPOnDemand")
        o.default = "AsIs"
        o.rmempty = false

        o = s.taboption('transparent_proxy_rules', form.Value, 'mark', _('Socket Mark Number'), _('Avoid proxy loopback problems with local (gateway) traffic'))
        o.datatype = 'range(1, 255)'
        o.default = 255

        o = s.taboption('transparent_proxy_rules', form.DynamicList, "wan_bp_ips", _("Bypassed IP"), _("Requests to these IPs won't be forwarded through Xray."))
        o.datatype = "ip4addr"
        o.rmempty = true

        o = s.taboption('transparent_proxy_rules', form.DynamicList, "wan_fw_ips", _("Forwarded IP"))
        o.datatype = "ip4addr"
        o.rmempty = true

        o = s.taboption('transparent_proxy_rules', form.SectionValue, "access_control_manual_tproxy", form.GridSection, 'manual_tproxy', _('Manual Transparent Proxy'), _('Compared to iptables REDIRECT, Xray could do NAT46 / NAT64 (for example accessing IPv6 only sites). See <a href="https://github.com/v2ray/v2ray-core/issues/2233">FakeDNS</a> for details.'))

        ss = o.subsection;
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        o = ss.option(form.Value, "source_addr", _("Source Address"))
        o.datatype = "ipaddr"
        o.rmempty = true

        o = ss.option(form.Value, "source_port", _("Source Port"))
        o.rmempty = true

        o = ss.option(form.Value, "dest_addr", _("Destination Address"))
        o.datatype = "host"
        o.rmempty = true

        o = ss.option(form.Value, "dest_port", _("Destination Port"))
        o.datatype = "port"
        o.rmempty = true

        o = ss.option(form.ListValue, 'domain_strategy', _('Domain Strategy'))
        o.value("UseIP")
        o.value("UseIPv4")
        o.value("UseIPv6")
        o.default = "UseIP"
        o.modalonly = true

        o = ss.option(form.Flag, 'force_forward', _('Force Forward'), _('This destination must be forwarded through an outbound server.'))
        o.modalonly = true

        o = ss.option(form.ListValue, 'force_forward_server_tcp', _('Force Forward server (TCP)'))
        o.depends("force_forward", "1")
        o.datatype = "uciname"
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }
        o.modalonly = true

        o = ss.option(form.ListValue, 'force_forward_server_udp', _('Force Forward server (UDP)'))
        o.depends("force_forward", "1")
        o.datatype = "uciname"
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }
        o.modalonly = true

        s.tab('xray_server', _('HTTPS Server'));

        o = s.taboption('xray_server', form.Flag, 'web_server_enable', _('Enable Xray HTTPS Server'), _("This will start a HTTPS server which serves both as an inbound for Xray and a reverse proxy web server."));

        o = s.taboption('xray_server', form.Value, 'web_server_port', _('Xray HTTPS Server Port'), _("This port needs to be set <code>accept input</code> manually in firewall settings."))
        o.datatype = 'port'
        o.default = 443
        o.depends("web_server_enable", "1")

        o = s.taboption('xray_server', form.ListValue, "web_server_protocol", _("Protocol"), _("Only protocols which support fallback are available. Note that REALITY does not support fallback right now."));
        o.value("vless", "VLESS")
        o.value("trojan", "Trojan")
        o.rmempty = false
        o.depends("web_server_enable", "1")

        add_flow_and_stream_security_conf(s, "xray_server", "web_server_protocol", "vless", true, true, false, firewall4)

        add_flow_and_stream_security_conf(s, "xray_server", "web_server_protocol", "trojan", true, false, false, firewall4)

        o = s.taboption('xray_server', form.Value, 'web_server_password', _('UserId / Password'), _('Fill user_id for vmess / VLESS, or password for shadowsocks / trojan (also supports <a href="https://github.com/XTLS/Xray-core/issues/158">Xray UUID Mapping</a>)'))
        o.depends("web_server_enable", "1")

        o = s.taboption('xray_server', form.Value, 'web_server_address', _('Default Fallback HTTP Server'), _("Only HTTP/1.1 supported here. For HTTP/2 upstream, use Fallback Servers below"))
        o.datatype = 'hostport'
        o.depends("web_server_enable", "1")

        o = s.taboption('xray_server', form.SectionValue, "xray_server_fallback", form.GridSection, 'fallback', _('Fallback Servers'), _("Specify upstream servers here."))
        o.depends({"web_server_enable": "1", "web_server_protocol": "trojan"})
        o.depends({"web_server_enable": "1", "web_server_protocol": "vless", "vless_tls": "tls"})
        o.depends({"web_server_enable": "1", "web_server_protocol": "vless", "vless_tls": "xtls"})

        ss = o.subsection;
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        o = ss.option(form.Value, "name", _("SNI"))
        o.rmempty = true

        o = ss.option(form.Value, "alpn", _("ALPN"))
        o.rmempty = true

        o = ss.option(form.Value, "path", _("Path"))
        o.rmempty = true

        o = ss.option(form.Value, "xver", _("Xver"))
        o.datatype = "uinteger"
        o.rmempty = true

        o = ss.option(form.Value, "dest", _("Destination Address"))
        o.datatype = 'hostport'
        o.rmempty = true

        s.tab('extra_options', _('Extra Options'))

        o = s.taboption('extra_options', form.ListValue, 'loglevel', _('Log Level'), _('Read Xray log in "System Log" or use <code>logread</code> command.'))
        o.value("debug")
        o.value("info")
        o.value("warning")
        o.value("error")
        o.value("none")
        o.default = "warning"

        o = s.taboption('extra_options', form.Flag, 'access_log', _('Enable Access Log'), _('Access log will also be written to System Log.'))

        o = s.taboption('extra_options', form.Flag, 'dns_log', _('Enable DNS Log'), _('DNS log will also be written to System Log.'))

        o = s.taboption('extra_options', form.Flag, 'xray_api', _('Enable Xray API Service'), _('Xray API Service uses port 8080 and GRPC protocol. Also callable via <code>xray api</code> or <code>ubus call xray</code>. See <a href="https://xtls.github.io/document/command.html#xray-api">here</a> for help.'))

        o = s.taboption('extra_options', form.Flag, 'stats', _('Enable Statistics'), _('Enable statistics of inbounds / outbounds data. Use Xray API to query values.'))

        o = s.taboption('extra_options', form.Flag, 'observatory', _('Enable Observatory'), _('Enable latency measurement for TCP and UDP outbounds. Support for balancers and strategy will be added later.'))

        o = s.taboption('extra_options', form.Flag, 'metrics_server_enable', _('Enable Xray Metrics Server'), _("Enable built-in metrics server for pprof and expvar. See <a href='https://github.com/XTLS/Xray-core/pull/1000'>here</a> for details."));

        o = s.taboption('extra_options', form.Value, 'metrics_server_port', _('Xray Metrics Server Port'), _("Metrics may be sensitive so think twice before setting it as Default Fallback HTTP Server."))
        o.depends("metrics_server_enable", "1")
        o.datatype = 'port'
        o.placeholder = '18888'

        o = s.taboption('extra_options', form.Value, 'handshake', _('Handshake Timeout'), _('Policy: Handshake timeout when connecting to upstream. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'))
        o.datatype = 'uinteger'
        o.placeholder = 4
        o.default = 4

        o = s.taboption('extra_options', form.Value, 'conn_idle', _('Connection Idle Timeout'), _('Policy: Close connection if no data is transferred within given timeout. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'))
        o.datatype = 'uinteger'
        o.placeholder = 300
        o.default = 300

        o = s.taboption('extra_options', form.Value, 'uplink_only', _('Uplink Only Timeout'), _('Policy: How long to wait before closing connection after server closed connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'))
        o.datatype = 'uinteger'
        o.placeholder = 2
        o.default = 2

        o = s.taboption('extra_options', form.Value, 'downlink_only', _('Downlink Only Timeout'), _('Policy: How long to wait before closing connection after client closed connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'))
        o.datatype = 'uinteger'
        o.placeholder = 5
        o.default = 5

        o = s.taboption('extra_options', form.Value, 'buffer_size', _('Buffer Size'), _('Policy: Internal cache size per connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'))
        o.datatype = 'uinteger'
        o.placeholder = 512
        o.default = 512

        o = s.taboption('extra_options', form.SectionValue, "xray_bridge", form.TableSection, 'bridge', _('Bridge'), _('Reverse proxy tool. Currently only client role (bridge) is supported. See <a href="https://xtls.github.io/config/reverse.html#bridgeobject">here</a> for help.'))

        ss = o.subsection;
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        o = ss.option(form.ListValue, "upstream", _("Upstream"))
        o.datatype = "uciname"
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], v.alias || v.server + ":" + v.server_port)
        }

        o = ss.option(form.Value, "domain", _("Domain"))
        o.rmempty = false

        o = ss.option(form.Value, "redirect", _("Redirect address"))
        o.datatype = "hostport"
        o.rmempty = false

        // if (Object.keys(optional_features).length > 0) {
        //     s.tab('optional_features', _('Optional Features'), _("Warning: all settings on this page are experimental, not guaranteed to be stable, and quite likely to be changed very frequently. Use at your own risk."))
        // }

        s.tab('custom_options', _('Custom Options'))
        o = s.taboption('custom_options', form.TextValue, 'custom_config', _('Custom Configurations'), _('Check <code>/var/etc/xray/config.json</code> for tags of generated inbounds and outbounds. See <a href="https://xtls.github.io/config/features/multiple.html">here</a> for help'))
        o.monospace = true
        o.rows = 10
        o.validate = validate_object

        return m.render();
    }
});
