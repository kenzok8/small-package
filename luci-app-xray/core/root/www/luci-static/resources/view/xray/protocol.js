'use strict';
'require baseclass';
'require form';

function fingerprints(o) {
    o.value("chrome", "chrome");
    o.value("firefox", "firefox");
    o.value("safari", "safari");
    o.value("ios", "ios");
    o.value("android", "android");
    o.value("edge", "edge");
    o.value("360", "360");
    o.value("qq", "qq");
    o.value("random", "random");
    o.value("randomized", "randomized");
}

function add_flow_and_stream_security_conf(s, tab_name, depends_field_name, protocol_name, have_tls_flow, server_side) {
    let o = s.taboption(tab_name, form.ListValue, `${protocol_name}_tls`, _(`[${protocol_name}] Stream Security`));
    let odep = {};
    odep[depends_field_name] = protocol_name;
    if (server_side) {
        odep["web_server_enable"] = "1";
    } else {
        o.depends(depends_field_name, protocol_name);
        o.value("none", "None");
    }
    o.value("tls", "TLS");
    if (have_tls_flow) {
        o.value("reality", "REALITY (Experimental)");
    }
    o.depends(odep);
    o.rmempty = false;
    o.modalonly = true;

    if (have_tls_flow) {
        let flow_tls = s.taboption(tab_name, form.ListValue, `${protocol_name}_flow_tls`, _(`[${protocol_name}][tls] Flow`));
        let flow_tls_dep = {};
        flow_tls_dep[depends_field_name] = protocol_name;
        flow_tls_dep[`${protocol_name}_tls`] = "tls";
        flow_tls.value("none", "none");
        flow_tls.value("xtls-rprx-vision", "xtls-rprx-vision");
        flow_tls.value("xtls-rprx-vision-udp443", "xtls-rprx-vision-udp443");
        if (server_side) {
            flow_tls_dep["web_server_enable"] = "1";
        }
        flow_tls.depends(flow_tls_dep);
        flow_tls.rmempty = false;
        flow_tls.modalonly = true;

        let flow_reality = s.taboption(tab_name, form.ListValue, `${protocol_name}_flow_reality`, _(`[${protocol_name}][reality] Flow`));
        let flow_reality_dep = {};
        flow_reality_dep[depends_field_name] = protocol_name;
        flow_reality_dep[`${protocol_name}_tls`] = "reality";
        flow_reality.value("none", "none");
        flow_reality.value("xtls-rprx-vision", "xtls-rprx-vision");
        flow_reality.value("xtls-rprx-vision-udp443", "xtls-rprx-vision-udp443");
        if (server_side) {
            flow_reality_dep["web_server_enable"] = "1";
        }
        flow_reality.depends(flow_reality_dep);
        flow_reality.rmempty = false;
        flow_reality.modalonly = true;

        o = s.taboption(tab_name, form.Flag, `${protocol_name}_reality_show`, _(`[${protocol_name}][reality] Show`));
        o.depends(`${protocol_name}_tls`, "reality");
        o.modalonly = true;
    }

    if (server_side) {
        let tls_cert_key_dep = { "web_server_enable": "1" };
        tls_cert_key_dep[`${protocol_name}_tls`] = "tls";
        o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_tls_cert_file`, _(`[${protocol_name}][tls] Certificate File`));
        o.root_directory = "/etc/luci-uploads/xray";
        o.depends(tls_cert_key_dep);

        o = s.taboption(tab_name, form.FileUpload, `${protocol_name}_tls_key_file`, _(`[${protocol_name}][tls] Private Key File`));
        o.root_directory = "/etc/luci-uploads/xray";
        o.depends(tls_cert_key_dep);

        if (have_tls_flow) {
            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_dest`, _(`[${protocol_name}][reality] Dest`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.datatype = "hostport";
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_xver`, _(`[${protocol_name}][reality] Xver`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.datatype = "integer";
            o.modalonly = true;

            o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_reality_server_names`, _(`[${protocol_name}][reality] Server Names`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_private_key`, _(`[${protocol_name}][reality] Private Key`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_min_client_ver`, _(`[${protocol_name}][reality] Min Client Ver`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_max_client_ver`, _(`[${protocol_name}][reality] Max Client Ver`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_max_time_diff`, _(`[${protocol_name}][reality] Max Time Diff`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.datatype = "integer";
            o.modalonly = true;

            o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_reality_short_ids`, _(`[${protocol_name}][reality] Short Ids`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;
        }
    } else {
        o = s.taboption(tab_name, form.Value, `${protocol_name}_tls_host`, _(`[${protocol_name}][tls] Server Name`));
        o.depends(`${protocol_name}_tls`, "tls");
        o.modalonly = true;

        o = s.taboption(tab_name, form.Flag, `${protocol_name}_tls_insecure`, _(`[${protocol_name}][tls] Allow Insecure`));
        o.depends(`${protocol_name}_tls`, "tls");
        o.rmempty = false;
        o.modalonly = true;

        o = s.taboption(tab_name, form.Value, `${protocol_name}_tls_fingerprint`, _(`[${protocol_name}][tls] Fingerprint`));
        o.depends(`${protocol_name}_tls`, "tls");
        o.value("", "(not set)");
        fingerprints(o);
        o.modalonly = true;

        o = s.taboption(tab_name, form.DynamicList, `${protocol_name}_tls_alpn`, _(`[${protocol_name}][tls] ALPN`));
        o.depends(`${protocol_name}_tls`, "tls");
        o.value("h2", "h2");
        o.value("http/1.1", "http/1.1");
        o.modalonly = true;

        if (have_tls_flow) {
            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_fingerprint`, _(`[${protocol_name}][reality] Fingerprint`));
            o.depends(`${protocol_name}_tls`, "reality");
            fingerprints(o);
            o.rmempty = false;
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_server_name`, _(`[${protocol_name}][reality] Server Name`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_public_key`, _(`[${protocol_name}][reality] Public Key`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_reality_short_id`, _(`[${protocol_name}][reality] Short Id`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;

            o = s.taboption(tab_name, form.Value, `${protocol_name}_spider_x`, _(`[${protocol_name}][reality] SpiderX`));
            o.depends(`${protocol_name}_tls`, "reality");
            o.modalonly = true;
        }
    }
}

function shadowsocks_client(protocol, sub_section, tab_name) {
    protocol.value("shadowsocks", "Shadowsocks");

    let shadowsocks_security = sub_section.taboption(tab_name, form.ListValue, "shadowsocks_security", _("[shadowsocks] Encrypt Method"));
    shadowsocks_security.depends("protocol", "shadowsocks");
    shadowsocks_security.value("none", "none");
    shadowsocks_security.value("aes-256-gcm", "aes-256-gcm");
    shadowsocks_security.value("aes-128-gcm", "aes-128-gcm");
    shadowsocks_security.value("chacha20-poly1305", "chacha20-poly1305");
    shadowsocks_security.value("2022-blake3-aes-128-gcm", "2022-blake3-aes-128-gcm");
    shadowsocks_security.value("2022-blake3-aes-256-gcm", "2022-blake3-aes-256-gcm");
    shadowsocks_security.value("2022-blake3-chacha20-poly1305", "2022-blake3-chacha20-poly1305");
    shadowsocks_security.rmempty = false;
    shadowsocks_security.modalonly = true;

    let shadowsocks_udp_over_tcp = sub_section.taboption(tab_name, form.Flag, 'shadowsocks_udp_over_tcp', _('[shadowsocks] UDP over TCP'), _('Only available for shadowsocks-2022 ciphers (2022-*)'));
    shadowsocks_udp_over_tcp.depends("shadowsocks_security", /2022/);
    shadowsocks_udp_over_tcp.rmempty = false;
    shadowsocks_udp_over_tcp.modalonly = true;

    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "shadowsocks", false, false);
}

function vmess_client(protocol, sub_section, tab_name) {
    protocol.value("vmess", "VMess");

    let vmess_security = sub_section.taboption(tab_name, form.ListValue, "vmess_security", _("[vmess] Encrypt Method"));
    vmess_security.depends("protocol", "vmess");
    vmess_security.value("none", "none");
    vmess_security.value("auto", "auto");
    vmess_security.value("aes-128-gcm", "aes-128-gcm");
    vmess_security.value("chacha20-poly1305", "chacha20-poly1305");
    vmess_security.rmempty = false;
    vmess_security.modalonly = true;

    let vmess_alter_id = sub_section.taboption(tab_name, form.ListValue, "vmess_alter_id", _("[vmess] AlterId"), _("Deprecated. Make sure you always use VMessAEAD."));
    vmess_alter_id.depends("protocol", "vmess");
    vmess_alter_id.value(0, "0 (this enables VMessAEAD)");
    vmess_alter_id.value(1, "1");
    vmess_alter_id.value(4, "4");
    vmess_alter_id.value(16, "16");
    vmess_alter_id.value(64, "64");
    vmess_alter_id.value(256, "256");
    vmess_alter_id.rmempty = false;
    vmess_alter_id.modalonly = true;

    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "vmess", false, false);
}

function vless_client(protocol, sub_section, tab_name) {
    protocol.value("vless", "VLESS");

    let vless_encryption = sub_section.taboption(tab_name, form.ListValue, "vless_encryption", _("[vless] Encrypt Method"));
    vless_encryption.depends("protocol", "vless");
    vless_encryption.value("none", "none");
    vless_encryption.rmempty = false;
    vless_encryption.modalonly = true;

    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "vless", true, false);
}

function socks_client(protocol, sub_section, tab_name) {
    protocol.value("socks", "SOCKS");
    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "socks", false, false);
}

function http_client(protocol, sub_section, tab_name) {
    protocol.value("http", "HTTP");
    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "http", false, false);
}

function vless_server(protocol, section, tab_name) {
    protocol.value("vless", "VLESS");
    add_flow_and_stream_security_conf(section, tab_name, "web_server_protocol", "vless", true, true);
}

function trojan_client(protocol, sub_section, tab_name) {
    protocol.value("trojan", "Trojan");
    add_flow_and_stream_security_conf(sub_section, tab_name, "protocol", "trojan", false, false);
}

function trojan_server(protocol, section, tab_name) {
    protocol.value("trojan", "Trojan");
    add_flow_and_stream_security_conf(section, tab_name, "web_server_protocol", "trojan", false, true);
}

return baseclass.extend({
    add_client_protocol: function (protocol, sub_section, tab_name) {
        vmess_client(protocol, sub_section, tab_name);
        vless_client(protocol, sub_section, tab_name);
        trojan_client(protocol, sub_section, tab_name);
        shadowsocks_client(protocol, sub_section, tab_name);
        http_client(protocol, sub_section, tab_name);
        socks_client(protocol, sub_section, tab_name);
    },
    add_server_protocol: function (protocol, section, tab_name) {
        vless_server(protocol, section, tab_name);
        trojan_server(protocol, section, tab_name);
    },
});
