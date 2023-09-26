'use strict';
'require form';
'require network';
'require uci';
'require view';

const variant = "xray_core";

function destination_format(k) {
    return function (s) {
        const dest = uci.get(variant, s, k) || [];
        return dest.map(v => uci.get(variant, v, "alias")).join(", ");
    };
}

function extra_outbound_format(config_data, s, with_desc) {
    const inbound_addr = uci.get(config_data, s, "inbound_addr") || "";
    const inbound_port = uci.get(config_data, s, "inbound_port") || "";
    if (inbound_addr == "" && inbound_port == "") {
        return "-";
    }
    if (with_desc) {
        return `${inbound_addr}:${inbound_port} (${destination_format("destination")(s)})`;
    }
    return `${inbound_addr}:${inbound_port}`;
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load(variant),
            network.getHostHints()
        ]);
    },

    render: function (load_result) {
        const m = new form.Map(variant, _('Xray (preview)'), _("WARNING: These features are experimental, may cause a lot of problems and are not guaranteed to be compatible across minor versions."));
        const config_data = load_result[0];
        const hosts = load_result[1].hosts;

        let s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab('fake_dns', _('FakeDNS'));

        let tproxy_port_tcp_f4 = s.taboption('fake_dns', form.Value, 'tproxy_port_tcp_f4', _('Transparent proxy port (TCP4)'));
        tproxy_port_tcp_f4.datatype = 'port';
        tproxy_port_tcp_f4.placeholder = 1086;

        let tproxy_port_udp_f4 = s.taboption('fake_dns', form.Value, 'tproxy_port_udp_f4', _('Transparent proxy port (UDP4)'));
        tproxy_port_udp_f4.datatype = 'port';
        tproxy_port_udp_f4.placeholder = 1087;

        let tproxy_port_tcp_f6 = s.taboption('fake_dns', form.Value, 'tproxy_port_tcp_f6', _('Transparent proxy port (TCP6)'));
        tproxy_port_tcp_f6.datatype = 'port';
        tproxy_port_tcp_f6.placeholder = 1088;

        let tproxy_port_udp_f6 = s.taboption('fake_dns', form.Value, 'tproxy_port_udp_f6', _('Transparent proxy port (UDP6)'));
        tproxy_port_udp_f6.datatype = 'port';
        tproxy_port_udp_f6.placeholder = 1089;

        let pool_v4 = s.taboption('fake_dns', form.Value, 'pool_v4', _('Address Pool (IPv4)'));
        pool_v4.datatype = 'ip4addr';
        pool_v4.placeholder = "198.18.0.0/15";

        let pool_v4_size = s.taboption('fake_dns', form.Value, 'pool_v4_size', _('Address Pool Size (IPv4)'));
        pool_v4_size.datatype = 'integer';
        pool_v4_size.placeholder = 65535;

        let pool_v6 = s.taboption('fake_dns', form.Value, 'pool_v6', _('Address Pool (IPv6)'));
        pool_v6.datatype = 'ip6addr';
        pool_v6.placeholder = "fc00::/18";

        let pool_v6_size = s.taboption('fake_dns', form.Value, 'pool_v6_size', _('Address Pool Size (IPv6)'));
        pool_v6_size.datatype = 'integer';
        pool_v6_size.placeholder = 65535;

        let fake_dns_timeout = s.taboption('fake_dns', form.Value, 'fake_dns_timeout', _('Connection Idle Timeout'), _('Policy: Close connection if no data is transferred within given timeout. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        fake_dns_timeout.datatype = 'uinteger';
        fake_dns_timeout.placeholder = 300;
        fake_dns_timeout.default = 300;

        let fs = s.taboption('fake_dns', form.SectionValue, "fake_dns_section", form.GridSection, 'fakedns', _('FakeDNS Routing'), _('See <a href="https://github.com/v2ray/v2ray-core/issues/2233">FakeDNS</a> for details.')).subsection;
        fs.sortable = false;
        fs.anonymous = true;
        fs.addremove = true;

        let fake_dns_domain_names = fs.option(form.DynamicList, "fake_dns_domain_names", _("Domain names to associate"));
        fake_dns_domain_names.rmempty = true;

        let fake_dns_forward_server_tcp = fs.option(form.MultiValue, 'fake_dns_forward_server_tcp', _('Force Forward server (TCP)'));
        fake_dns_forward_server_tcp.datatype = "uciname";
        fake_dns_forward_server_tcp.textvalue = destination_format("fake_dns_forward_server_tcp");

        let fake_dns_forward_server_udp = fs.option(form.MultiValue, 'fake_dns_forward_server_udp', _('Force Forward server (UDP)'));
        fake_dns_forward_server_udp.datatype = "uciname";
        fake_dns_forward_server_udp.textvalue = destination_format("fake_dns_forward_server_udp");

        s.tab("extra_inbounds", "Extra Inbounds");

        let extra_inbounds = s.taboption('extra_inbounds', form.SectionValue, "extra_inbound_section", form.GridSection, 'extra_inbound', _('Extra Inbounds'), _("Add more socks5 / http inbounds and redirect to other outbounds.")).subsection;
        extra_inbounds.sortable = false;
        extra_inbounds.anonymous = true;
        extra_inbounds.addremove = true;
        extra_inbounds.nodescriptions = true;

        let inbound_addr = extra_inbounds.option(form.Value, "inbound_addr", _("Listen Address"));
        inbound_addr.datatype = "ip4addr";
        inbound_addr.rmempty = true;

        let inbound_port = extra_inbounds.option(form.Value, "inbound_port", _("Listen Port"));
        inbound_port.datatype = "port";
        inbound_port.rmempty = true;

        let inbound_type = extra_inbounds.option(form.ListValue, "inbound_type", _("Inbound Type"));
        inbound_type.value("socks5", _("Socks5 Proxy"));
        inbound_type.value("http", _("HTTP Proxy"));
        inbound_type.value("tproxy_tcp", _("Transparent Proxy (TCP)"));
        inbound_type.value("tproxy_udp", _("Transparent Proxy (UDP)"));
        inbound_type.rmempty = false;

        let specify_outbound = extra_inbounds.option(form.Flag, 'specify_outbound', _('Specify Outbound'), _('If not selected, this inbound will use global settings (including sniffing settings). '));
        specify_outbound.modalonly = true;

        let destination = extra_inbounds.option(form.MultiValue, 'destination', _('Destination'), _("Select multiple outbounds for load balancing. If none selected, requests will be sent via direct outbound."));
        destination.depends("specify_outbound", "1");
        destination.datatype = "uciname";
        destination.textvalue = destination_format("destination");

        const servers = uci.sections(config_data, "servers");
        if (servers.length == 0) {
            destination.value("direct", _("No server configured"));
            fake_dns_forward_server_tcp.value("direct", _("No server configured"));
            fake_dns_forward_server_udp.value("direct", _("No server configured"));

            destination.readonly = true;
            fake_dns_forward_server_tcp.readonly = true;
            fake_dns_forward_server_udp.readonly = true;
        } else {
            for (const v of uci.sections(config_data, "servers")) {
                destination.value(v[".name"], v.alias || v.server + ":" + v.server_port);
                fake_dns_forward_server_tcp.value(v[".name"], v.alias || v.server + ":" + v.server_port);
                fake_dns_forward_server_udp.value(v[".name"], v.alias || v.server + ":" + v.server_port);
            }
        }

        s.tab("lan_hosts_access_control", _("LAN Hosts Access Control"));

        let lan_hosts = s.taboption('lan_hosts_access_control', form.SectionValue, "lan_hosts_section", form.GridSection, 'lan_hosts', _('LAN Hosts Access Control'), _("Override global transparent proxy settings here.")).subsection;
        lan_hosts.sortable = false;
        lan_hosts.anonymous = true;
        lan_hosts.addremove = true;

        let macaddr = lan_hosts.option(form.Value, "macaddr", _("MAC Address"));
        macaddr.datatype = "macaddr";
        macaddr.rmempty = false;
        L.sortedKeys(hosts).forEach(function (mac) {
            macaddr.value(mac, E([], [mac, ' (', E('strong', [hosts[mac].name || L.toArray(hosts[mac].ipaddrs || hosts[mac].ipv4)[0] || L.toArray(hosts[mac].ip6addrs || hosts[mac].ipv6)[0] || '?']), ')']));
        });

        let access_control_strategy_v4 = lan_hosts.option(form.ListValue, "access_control_strategy_v4", _("Access Control Strategy (IPv4)"));
        access_control_strategy_v4.value("global", _("Use global settings"));
        access_control_strategy_v4.value("bypass", _("Bypass Xray completely"));
        access_control_strategy_v4.value("forward", _("Forward via extra inbound"));
        access_control_strategy_v4.modalonly = true;
        access_control_strategy_v4.rmempty = false;

        let access_control_forward_tcp_v4 = lan_hosts.option(form.ListValue, "access_control_forward_tcp_v4", _("Extra inbound (TCP4)"));
        access_control_forward_tcp_v4.depends("access_control_strategy_v4", "forward");
        access_control_forward_tcp_v4.rmempty = true;
        access_control_forward_tcp_v4.textvalue = function (s) {
            switch (uci.get(config_data, s, "access_control_strategy_v4")) {
                case "global": {
                    return _("Use Global Settings");
                }
                case "bypass": {
                    return _("Bypass Xray completely");
                }
            }
            return extra_outbound_format(config_data, uci.get(config_data, s, "access_control_forward_tcp_v4"));
        };

        let access_control_forward_udp_v4 = lan_hosts.option(form.ListValue, "access_control_forward_udp_v4", _("Extra inbound (UDP4)"));
        access_control_forward_udp_v4.depends("access_control_strategy_v4", "forward");
        access_control_forward_udp_v4.rmempty = true;
        access_control_forward_udp_v4.textvalue = function (s) {
            switch (uci.get(config_data, s, "access_control_strategy_v4")) {
                case "global": {
                    return _("Use Global Settings");
                }
                case "bypass": {
                    return _("Bypass Xray completely");
                }
            }
            return extra_outbound_format(config_data, uci.get(config_data, s, "access_control_forward_udp_v4"), false);
        };

        let access_control_strategy_v6 = lan_hosts.option(form.ListValue, "access_control_strategy_v6", _("Access Control Strategy (IPv6)"));
        access_control_strategy_v6.value("global", _("Use global settings"));
        access_control_strategy_v6.value("bypass", _("Bypass Xray completely"));
        access_control_strategy_v6.value("forward", _("Forward via extra inbound"));
        access_control_strategy_v6.modalonly = true;
        access_control_strategy_v6.rmempty = false;

        let access_control_forward_tcp_v6 = lan_hosts.option(form.ListValue, "access_control_forward_tcp_v6", _("Extra inbound (TCP6)"));
        access_control_forward_tcp_v6.depends("access_control_strategy_v6", "forward");
        access_control_forward_tcp_v6.rmempty = true;
        access_control_forward_tcp_v6.textvalue = function (s) {
            switch (uci.get(config_data, s, "access_control_strategy_v6")) {
                case "global": {
                    return _("Use Global Settings");
                }
                case "bypass": {
                    return _("Bypass Xray completely");
                }
            }
            return extra_outbound_format(config_data, uci.get(config_data, s, "access_control_forward_tcp_v6"));
        };

        let access_control_forward_udp_v6 = lan_hosts.option(form.ListValue, "access_control_forward_udp_v6", _("Extra inbound (UDP6)"));
        access_control_forward_udp_v6.depends("access_control_strategy_v6", "forward");
        access_control_forward_udp_v6.rmempty = true;
        access_control_forward_udp_v6.textvalue = function (s) {
            switch (uci.get(config_data, s, "access_control_strategy_v6")) {
                case "global": {
                    return _("Use Global Settings");
                }
                case "bypass": {
                    return _("Bypass Xray completely");
                }
            }
            return extra_outbound_format(config_data, uci.get(config_data, s, "access_control_forward_udp_v6"), false);
        };

        for (const v of uci.sections(config_data, "extra_inbound")) {
            switch (v["inbound_type"]) {
                case "tproxy_tcp": {
                    access_control_forward_tcp_v4.value(v[".name"], `${extra_outbound_format(config_data, v[".name"], true)}`);
                    access_control_forward_tcp_v6.value(v[".name"], `${extra_outbound_format(config_data, v[".name"], true)}`);
                    break;
                }
                case "tproxy_udp": {
                    access_control_forward_udp_v4.value(v[".name"], `${extra_outbound_format(config_data, v[".name"], true)}`);
                    access_control_forward_udp_v6.value(v[".name"], `${extra_outbound_format(config_data, v[".name"], true)}`);
                    break;
                }
            }
        }

        s.tab('dynamic_direct', _('Dynamic Direct'));

        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_tcp4', _('Enable for IPv4 TCP'), _("Recommended."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_tcp6', _('Enable for IPv4 UDP'), _("Recommended."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_udp4', _('Enable for IPv6 TCP'), _("Not recommended."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_udp6', _('Enable for IPv6 UDP'), _("Not recommended."));

        let dynamic_direct_timeout = s.taboption('dynamic_direct', form.Value, 'dynamic_direct_timeout', _('Dynamic Direct Timeout'), _("Larger value consumes more memory and performs generally better. Unit in seconds."));
        dynamic_direct_timeout.datatype = 'uinteger';
        dynamic_direct_timeout.placeholder = 300;
        dynamic_direct_timeout.rmempty = true;

        let ttl_override = s.taboption('dynamic_direct', form.Value, 'ttl_override', _('Override IPv4 TTL'), _("Strongly not recommended. Only used for some network environments with specific restrictions."));
        ttl_override.datatype = 'uinteger';
        ttl_override.rmempty = true;

        let hop_limit_override = s.taboption('dynamic_direct', form.Value, 'hop_limit_override', _('Override IPv6 Hop Limit'), _("Strongly not recommended. Only used for some network environments with specific restrictions."));
        hop_limit_override.datatype = 'uinteger';
        hop_limit_override.rmempty = true;

        let ttl_hop_limit_match = s.taboption('dynamic_direct', form.Value, 'ttl_hop_limit_match', _('TTL / Hop Limit Match'), _("Only override TTL / hop limit for packets with specific TTL / hop limit."));
        ttl_hop_limit_match.datatype = 'uinteger';
        ttl_hop_limit_match.rmempty = true;

        return m.render();
    }
});
