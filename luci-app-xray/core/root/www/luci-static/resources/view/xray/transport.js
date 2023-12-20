'use strict';
'require baseclass';
'require form';

function transport_tcp(transport, sub_section, tab_name) {
    transport.value("tcp", "TCP");

    let tcp_guise = sub_section.taboption(tab_name, form.ListValue, "tcp_guise", _("[tcp] Fake Header Type"));
    tcp_guise.depends("transport", "tcp");
    tcp_guise.value("none", _("None"));
    tcp_guise.value("http", "HTTP");
    tcp_guise.modalonly = true;

    let http_host = sub_section.taboption(tab_name, form.DynamicList, "http_host", _("[tcp][fake_http] Host"));
    http_host.depends("tcp_guise", "http");
    http_host.rmempty = false;
    http_host.modalonly = true;

    let http_path = sub_section.taboption(tab_name, form.DynamicList, "http_path", _("[tcp][fake_http] Path"));
    http_path.depends("tcp_guise", "http");
    http_path.modalonly = true;
}

function transport_mkcp(transport, sub_section, tab_name) {
    transport.value("mkcp", "mKCP");

    let mkcp_guise = sub_section.taboption(tab_name, form.ListValue, "mkcp_guise", _("[mkcp] Fake Header Type"));
    mkcp_guise.depends("transport", "mkcp");
    mkcp_guise.value("none", _("None"));
    mkcp_guise.value("srtp", _("VideoCall (SRTP)"));
    mkcp_guise.value("utp", _("BitTorrent (uTP)"));
    mkcp_guise.value("wechat-video", _("WechatVideo"));
    mkcp_guise.value("dtls", "DTLS 1.2");
    mkcp_guise.value("wireguard", "WireGuard");
    mkcp_guise.modalonly = true;

    let mkcp_mtu = sub_section.taboption(tab_name, form.Value, "mkcp_mtu", _("[mkcp] Maximum Transmission Unit"));
    mkcp_mtu.datatype = "uinteger";
    mkcp_mtu.depends("transport", "mkcp");
    mkcp_mtu.placeholder = 1350;
    mkcp_mtu.modalonly = true;

    let mkcp_tti = sub_section.taboption(tab_name, form.Value, "mkcp_tti", _("[mkcp] Transmission Time Interval"));
    mkcp_tti.datatype = "uinteger";
    mkcp_tti.depends("transport", "mkcp");
    mkcp_tti.placeholder = 50;
    mkcp_tti.modalonly = true;

    let mkcp_uplink_capacity = sub_section.taboption(tab_name, form.Value, "mkcp_uplink_capacity", _("[mkcp] Uplink Capacity"));
    mkcp_uplink_capacity.datatype = "uinteger";
    mkcp_uplink_capacity.depends("transport", "mkcp");
    mkcp_uplink_capacity.placeholder = 5;
    mkcp_uplink_capacity.modalonly = true;

    let mkcp_downlink_capacity = sub_section.taboption(tab_name, form.Value, "mkcp_downlink_capacity", _("[mkcp] Downlink Capacity"));
    mkcp_downlink_capacity.datatype = "uinteger";
    mkcp_downlink_capacity.depends("transport", "mkcp");
    mkcp_downlink_capacity.placeholder = 20;
    mkcp_downlink_capacity.modalonly = true;

    let mkcp_read_buffer_size = sub_section.taboption(tab_name, form.Value, "mkcp_read_buffer_size", _("[mkcp] Read Buffer Size"));
    mkcp_read_buffer_size.datatype = "uinteger";
    mkcp_read_buffer_size.depends("transport", "mkcp");
    mkcp_read_buffer_size.placeholder = 2;
    mkcp_read_buffer_size.modalonly = true;

    let mkcp_write_buffer_size = sub_section.taboption(tab_name, form.Value, "mkcp_write_buffer_size", _("[mkcp] Write Buffer Size"));
    mkcp_write_buffer_size.datatype = "uinteger";
    mkcp_write_buffer_size.depends("transport", "mkcp");
    mkcp_write_buffer_size.placeholder = 2;
    mkcp_write_buffer_size.modalonly = true;

    let mkcp_congestion = sub_section.taboption(tab_name, form.Flag, "mkcp_congestion", _("[mkcp] Congestion Control"));
    mkcp_congestion.depends("transport", "mkcp");
    mkcp_congestion.modalonly = true;

    let mkcp_seed = sub_section.taboption(tab_name, form.Value, "mkcp_seed", _("[mkcp] Seed"));
    mkcp_seed.depends("transport", "mkcp");
    mkcp_seed.modalonly = true;
}

function transport_ws(transport, sub_section, tab_name) {
    transport.value("ws", "WebSocket");

    let ws_host = sub_section.taboption(tab_name, form.Value, "ws_host", _("[websocket] Host"));
    ws_host.depends("transport", "ws");
    ws_host.modalonly = true;

    let ws_path = sub_section.taboption(tab_name, form.Value, "ws_path", _("[websocket] Path"));
    ws_path.depends("transport", "ws");
    ws_path.modalonly = true;
}

function transport_h2(transport, sub_section, tab_name) {
    transport.value("h2", "HTTP/2");

    let h2_host = sub_section.taboption(tab_name, form.DynamicList, "h2_host", _("[http2] Host"));
    h2_host.depends("transport", "h2");
    h2_host.modalonly = true;

    let h2_path = sub_section.taboption(tab_name, form.Value, "h2_path", _("[http2] Path"));
    h2_path.depends("transport", "h2");
    h2_path.modalonly = true;

    let h2_health_check = sub_section.taboption(tab_name, form.Flag, "h2_health_check", _("[h2] Health Check"));
    h2_health_check.depends("transport", "h2");
    h2_health_check.modalonly = true;

    let h2_read_idle_timeout = sub_section.taboption(tab_name, form.Value, "h2_read_idle_timeout", _("[h2] Read Idle Timeout"));
    h2_read_idle_timeout.depends({ "transport": "h2", "h2_health_check": "1" });
    h2_read_idle_timeout.modalonly = true;
    h2_read_idle_timeout.placeholder = 10;
    h2_read_idle_timeout.datatype = 'integer';

    let h2_health_check_timeout = sub_section.taboption(tab_name, form.Value, "h2_health_check_timeout", _("[h2] Health Check Timeout"));
    h2_health_check_timeout.depends({ "transport": "h2", "h2_health_check": "1" });
    h2_health_check_timeout.modalonly = true;
    h2_health_check_timeout.placeholder = 20;
    h2_health_check_timeout.datatype = 'integer';
}

function transport_quic(transport, sub_section, tab_name) {
    transport.value("quic", "QUIC");

    let quic_security = sub_section.taboption(tab_name, form.ListValue, "quic_security", _("[quic] Security"));
    quic_security.depends("transport", "quic");
    quic_security.value("none", "none");
    quic_security.value("aes-128-gcm", "aes-128-gcm");
    quic_security.value("chacha20-poly1305", "chacha20-poly1305");
    quic_security.rmempty = false;
    quic_security.modalonly = true;

    let quic_key = sub_section.taboption(tab_name, form.Value, "quic_key", _("[quic] Key"));
    quic_key.depends("transport", "quic");
    quic_key.modalonly = true;

    let quic_guise = sub_section.taboption(tab_name, form.ListValue, "quic_guise", _("[quic] Fake Header Type"));
    quic_guise.depends("transport", "quic");
    quic_guise.value("none", _("None"));
    quic_guise.value("srtp", _("VideoCall (SRTP)"));
    quic_guise.value("utp", _("BitTorrent (uTP)"));
    quic_guise.value("wechat-video", _("WechatVideo"));
    quic_guise.value("dtls", "DTLS 1.2");
    quic_guise.value("wireguard", "WireGuard");
    quic_guise.default = "none";
    quic_guise.modalonly = true;
}

function transport_grpc(transport, sub_section, tab_name) {
    transport.value("grpc", "gRPC");

    let grpc_service_name = sub_section.taboption(tab_name, form.Value, "grpc_service_name", _("[grpc] Service Name"));
    grpc_service_name.depends("transport", "grpc");
    grpc_service_name.modalonly = true;

    let grpc_multi_mode = sub_section.taboption(tab_name, form.Flag, "grpc_multi_mode", _("[grpc] Multi Mode"));
    grpc_multi_mode.depends("transport", "grpc");
    grpc_multi_mode.modalonly = true;

    let grpc_health_check = sub_section.taboption(tab_name, form.Flag, "grpc_health_check", _("[grpc] Health Check"));
    grpc_health_check.depends("transport", "grpc");
    grpc_health_check.modalonly = true;

    let grpc_idle_timeout = sub_section.taboption(tab_name, form.Value, "grpc_idle_timeout", _("[grpc] Idle Timeout"));
    grpc_idle_timeout.depends({ "transport": "grpc", "grpc_health_check": "1" });
    grpc_idle_timeout.modalonly = true;
    grpc_idle_timeout.placeholder = 10;
    grpc_idle_timeout.datatype = 'integer';

    let grpc_health_check_timeout = sub_section.taboption(tab_name, form.Value, "grpc_health_check_timeout", _("[grpc] Health Check Timeout"));
    grpc_health_check_timeout.depends({ "transport": "grpc", "grpc_health_check": "1" });
    grpc_health_check_timeout.modalonly = true;
    grpc_health_check_timeout.placeholder = 20;
    grpc_health_check_timeout.datatype = 'integer';

    let grpc_permit_without_stream = sub_section.taboption(tab_name, form.Flag, "grpc_permit_without_stream", _("[grpc] Permit Without Stream"));
    grpc_permit_without_stream.depends({ "transport": "grpc", "grpc_health_check": "1" });
    grpc_permit_without_stream.modalonly = true;

    let grpc_initial_windows_size = sub_section.taboption(tab_name, form.Value, "grpc_initial_windows_size", _("[grpc] Initial Windows Size"), _("Set to 524288 to avoid Cloudflare sending ENHANCE_YOUR_CALM."));
    grpc_initial_windows_size.depends("transport", "grpc");
    grpc_initial_windows_size.modalonly = true;
    grpc_initial_windows_size.placeholder = 0;
    grpc_initial_windows_size.datatype = 'integer';
}

return baseclass.extend({
    init: function (transport, sub_section, tab_name) {
        transport_tcp(transport, sub_section, tab_name);
        transport_mkcp(transport, sub_section, tab_name);
        transport_ws(transport, sub_section, tab_name);
        transport_h2(transport, sub_section, tab_name);
        transport_quic(transport, sub_section, tab_name);
        transport_grpc(transport, sub_section, tab_name);
    }
});
