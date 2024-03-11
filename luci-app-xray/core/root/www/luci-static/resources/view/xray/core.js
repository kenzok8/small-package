'use strict';
'require form';
'require fs';
'require network';
'require tools.widgets as widgets';
'require uci';
'require view';
'require view.xray.protocol as protocol';
'require view.xray.shared as shared';
'require view.xray.transport as transport';

function server_alias(v) {
    return v.alias || v.server + ":" + v.server_port;
}

function list_folded_format(config_data, k, noun, max_chars, mapping, empty) {
    return function (s) {
        const null_mapping = v => v;
        const records = (uci.get(config_data, s, k) || []).map(mapping || null_mapping);
        if (records.length == 0) {
            return empty || "-";
        }

        const max_items = function () {
            for (const i in records) {
                const pos = parseInt(i);
                if (records.slice(0, pos + 1).join(", ").length > max_chars) {
                    return pos;
                }
            }
            return records.length;
        }() || 1;

        if (records.length <= max_items) {
            return records.join(", ");
        }
        return E([], [
            records.slice(0, max_items).join(", "),
            ", ... ",
            shared.badge(`+<strong>${records.length - max_items}</strong>`, `${records.length} ${noun}\n${records.join("\n")}`)
        ]);
    };
}

function destination_format(config_data, k, e, max_chars) {
    return function (s) {
        if (e) {
            if (!uci.get(config_data, s, e)) {
                return `<i>${_("use global settings")}</i>`;
            }
        }
        return list_folded_format(config_data, k, "outbounds", max_chars, v => uci.get(config_data, v, "alias"), `<i>${_("direct")}</i>`)(s);
    };
}

function extra_outbound_format(config_data, s, select_item) {
    const inbound_addr = uci.get(config_data, s, "inbound_addr") || "";
    const inbound_port = uci.get(config_data, s, "inbound_port") || "";
    if (inbound_addr == "" && inbound_port == "") {
        return "-";
    }
    const destination = (uci.get(config_data, s, "destination") || []).map(x => server_alias(uci.get(config_data, x)));
    if (select_item) {
        if (destination.length == 0) {
            return `${inbound_addr}:${inbound_port} [direct]`;
        }
        return `${inbound_addr}:${inbound_port} (${destination.join(", ")})`;
    }
    return E([], [
        `${inbound_addr}:${inbound_port} `,
        function () {
            if (destination.length == 0) {
                return shared.badge("<strong>...</strong>", "direct");
            }
            return shared.badge("<strong>...</strong>", `${destination.length} outbounds\n${destination.join("\n")}`);
        }()
    ]);
}

function access_control_format(config_data, s, t) {
    return function (v) {
        switch (uci.get(config_data, v, s)) {
            case "tproxy": {
                return _("Enable tproxy");
            }
            case "bypass": {
                return _("Disable tproxy");
            }
        }
        return extra_outbound_format(config_data, uci.get(config_data, v, t), false);
    };
}

function check_resource_files(load_result) {
    let geoip_existence = false;
    let geoip_size = 0;
    let geosite_existence = false;
    let geosite_size = 0;
    let xray_bin_default = false;
    let xray_running = false;
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
    }
    return {
        geoip_existence: geoip_existence,
        geoip_size: geoip_size,
        geosite_existence: geosite_existence,
        geosite_size: geosite_size,
        xray_bin_default: xray_bin_default,
        xray_running: xray_running,
    };
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load(shared.variant),
            fs.list("/usr/share/xray"),
            network.getHostHints()
        ]);
    },

    render: function (load_result) {
        const config_data = load_result[0];
        const { geoip_existence, geoip_size, geosite_existence, geosite_size, xray_bin_default, xray_running } = check_resource_files(load_result[1]);
        const status_text = xray_running ? _("[Xray is running]") : _("[Xray is stopped]");
        const hosts = load_result[2].hosts;

        let asset_file_status = _('WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/xray. Xray may not work properly. See <a href="https://github.com/yichya/luci-app-xray">here</a> for help.');
        if (geoip_existence) {
            if (geosite_existence) {
                asset_file_status = _('Asset files check: ') + `geoip.dat ${geoip_size}; geosite.dat ${geosite_size}. ` + _('Report issues or request for features <a href="https://github.com/yichya/luci-app-xray">here</a>.');
            }
        }

        const m = new form.Map(shared.variant, _('Xray'), status_text + " " + asset_file_status);

        let s, o, ss;

        s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab('general', _('General Settings'));

        o = s.taboption('general', form.Flag, 'transparent_proxy_enable', _('Enable Xray Service'), _('Uncheck this to disable the entire Xray service.'));

        let tcp_balancer_v4 = s.taboption('general', form.MultiValue, 'tcp_balancer_v4', _('TCP Server (IPv4)'), _("Select multiple outbound servers to enable load balancing. Select none to disable TCP Outbound."));
        tcp_balancer_v4.datatype = "uciname";

        let udp_balancer_v4 = s.taboption('general', form.MultiValue, 'udp_balancer_v4', _('UDP Server (IPv4)'), _("Select multiple outbound servers to enable load balancing. Select none to disable UDP Outbound."));
        udp_balancer_v4.datatype = "uciname";

        let tcp_balancer_v6 = s.taboption('general', form.MultiValue, 'tcp_balancer_v6', _('TCP Server (IPv6)'), _("Select multiple outbound servers to enable load balancing. Select none to disable TCP Outbound."));
        tcp_balancer_v6.datatype = "uciname";

        let udp_balancer_v6 = s.taboption('general', form.MultiValue, 'udp_balancer_v6', _('UDP Server (IPv6)'), _("Select multiple outbound servers to enable load balancing. Select none to disable UDP Outbound."));
        udp_balancer_v6.datatype = "uciname";

        let general_balancer_strategy = s.taboption('general', form.Value, 'general_balancer_strategy', _('Balancer Strategy'), _('Strategy <code>leastPing</code> requires observatory (see "Extra Options" tab) to be enabled.'));
        general_balancer_strategy.value("random");
        general_balancer_strategy.value("leastPing");
        general_balancer_strategy.value("roundRobin");
        general_balancer_strategy.default = "random";
        general_balancer_strategy.rmempty = false;

        o = s.taboption('general', form.SectionValue, "xray_servers", form.GridSection, 'servers', _('Xray Servers'), _("Servers are referenced by index (order in the following list). Deleting servers may result in changes of upstream servers actually used by proxy and bridge."));
        ss = o.subsection;
        ss.sortable = false;
        ss.anonymous = true;
        ss.addremove = true;

        ss.tab('general', _('General Settings'));
        ss.nodescriptions = true;

        o = ss.taboption('general', form.Value, "alias", _("Alias (optional)"));
        o.optional = true;

        o = ss.taboption('general', form.Value, 'server', _('Server Hostname'));
        o.datatype = 'host';
        o.rmempty = false;

        o = ss.taboption('general', form.DynamicList, 'server_port', _('Server Port'));
        o.datatype = 'port';
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('general', form.Value, 'username', _('Email / Username'), _('Optional; username for SOCKS / HTTP outbound, email for other outbound.'));
        o.modalonly = true;

        o = ss.taboption('general', form.Value, 'password', _('UserId / Password'), _('Fill user_id for vmess / VLESS, or password for other outbound (also supports <a href="https://github.com/XTLS/Xray-core/issues/158">Xray UUID Mapping</a>)'));
        o.rmempty = false;

        ss.tab('resolving', _("Server Hostname Resolving"));

        o = ss.taboption('resolving', form.ListValue, 'domain_strategy', _('Domain Strategy'), _("Whether to use IPv4 or IPv6 address if Server Hostname is a domain."));
        o.value("UseIP");
        o.value("UseIPv4");
        o.value("UseIPv6");
        o.default = "UseIP";
        o.modalonly = true;

        o = ss.taboption('resolving', form.Value, 'domain_resolve_dns', _('Resolve Domain via DNS'), _("Specify a DNS to resolve server hostname. Be careful of possible recursion."));
        o.datatype = "or(ipaddr, ipaddrport(1))";
        o.modalonly = true;

        o = ss.taboption('resolving', form.ListValue, 'domain_resolve_dns_method', _('Resolve Domain DNS Method'), _("Effective when DNS above is set. Direct methods will bypass Xray completely so it may get blocked."));
        o.value("udp", _("UDP"));
        o.value("quic+local", _("DNS over QUIC (direct)"));
        o.value("tcp", _("TCP"));
        o.value("tcp+local", _("TCP (direct)"));
        o.value("https", _("DNS over HTTPS"));
        o.value("https+local", _("DNS over HTTPS (direct)"));
        o.default = "udp";
        o.modalonly = true;

        o = ss.taboption('resolving', form.DynamicList, 'domain_resolve_expect_ips', _('Expected Server IPs'), _("Filter resolved IPs by GeoIP or CIDR. Resource file <code>geoip.dat</code> is required for GeoIP filtering."));
        o.modalonly = true;

        ss.tab('protocol', _('Protocol Settings'));

        o = ss.taboption('protocol', form.ListValue, "protocol", _("Protocol"));
        protocol.add_client_protocol(o, ss, 'protocol');
        o.rmempty = false;

        ss.tab('transport', _('Transport Settings'));

        o = ss.taboption('transport', form.ListValue, 'transport', _('Transport'));
        transport.init(o, ss, 'transport');
        o.rmempty = false;

        o = ss.taboption('transport', form.ListValue, 'dialer_proxy', _('Dialer Proxy'), _('Similar to <a href="https://xtls.github.io/config/outbound.html#proxysettingsobject">ProxySettings.Tag</a>'));
        o.datatype = "uciname";
        o.value("disabled", _("Disabled"));
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], server_alias(v));
        }
        o.modalonly = true;

        ss.tab('custom', _('Custom Options'));

        o = ss.taboption('custom', form.TextValue, 'custom_config', _('Custom Configurations'), _('Configurations here override settings in the previous tabs with the following rules: <ol><li>Object values will be replaced recursively so settings in previous tabs matter.</li><li>Arrays will be replaced entirely instead of being merged.</li><li>Tag <code>tag</code> is ignored. </li></ol>Override rules here may be changed later. Use this only for experimental or pre-release features.'));
        o.modalonly = true;
        o.monospace = true;
        o.rows = 10;
        o.validate = shared.validate_object;

        s.tab('inbounds', _('Inbounds'));

        o = s.taboption('inbounds', form.Value, 'tproxy_port_tcp_v4', _('Transparent proxy port (TCP4)'));
        o.datatype = 'port';
        o.placeholder = 1082;

        o = s.taboption('inbounds', form.Value, 'tproxy_port_tcp_v6', _('Transparent proxy port (TCP6)'));
        o.datatype = 'port';
        o.placeholder = 1083;

        o = s.taboption('inbounds', form.Value, 'tproxy_port_udp_v4', _('Transparent proxy port (UDP4)'));
        o.datatype = 'port';
        o.placeholder = 1084;

        o = s.taboption('inbounds', form.Value, 'tproxy_port_udp_v6', _('Transparent proxy port (UDP6)'));
        o.datatype = 'port';
        o.placeholder = 1085;

        o = s.taboption('inbounds', form.DynamicList, 'uids_direct', _('Bypass tproxy for uids'), _("Processes started by users with these uids won't be forwarded through Xray."));
        o.datatype = "integer";

        o = s.taboption('inbounds', form.DynamicList, 'gids_direct', _('Bypass tproxy for gids'), _("Processes started by users in groups with these gids won't be forwarded through Xray."));
        o.datatype = "integer";

        let extra_inbounds = s.taboption('inbounds', form.SectionValue, "extra_inbound_section", form.GridSection, 'extra_inbound', _('Extra Inbounds'), _("Add more socks5 / http inbounds and redirect to other outbounds.")).subsection;
        extra_inbounds.sortable = false;
        extra_inbounds.anonymous = true;
        extra_inbounds.addremove = true;
        extra_inbounds.nodescriptions = true;

        let inbound_addr = extra_inbounds.option(form.Value, "inbound_addr", _("Listen Address"));
        inbound_addr.datatype = "ip4addr";

        let inbound_port = extra_inbounds.option(form.Value, "inbound_port", _("Listen Port"));
        inbound_port.datatype = "port";

        let inbound_type = extra_inbounds.option(form.ListValue, "inbound_type", _("Inbound Type"));
        inbound_type.value("socks5", _("Socks5 Proxy"));
        inbound_type.value("http", _("HTTP Proxy"));
        inbound_type.value("tproxy_tcp", _("Transparent Proxy (TCP)"));
        inbound_type.value("tproxy_udp", _("Transparent Proxy (UDP)"));
        inbound_type.rmempty = false;

        let inbound_username = extra_inbounds.option(form.Value, "inbound_username", _("Username (Optional)"));
        inbound_username.depends("inbound_type", "socks5");
        inbound_username.depends("inbound_type", "http");
        inbound_username.modalonly = true;

        let inbound_password = extra_inbounds.option(form.Value, "inbound_password", _("Password (Optional)"));
        inbound_password.depends("inbound_type", "socks5");
        inbound_password.depends("inbound_type", "http");
        inbound_password.modalonly = true;

        let specify_outbound = extra_inbounds.option(form.Flag, 'specify_outbound', _('Specify Outbound'), _('If not selected, this inbound will use global settings (including sniffing settings).'));
        specify_outbound.modalonly = true;

        let destination = extra_inbounds.option(form.MultiValue, 'destination', _('Destination'), _("Select multiple outbounds for load balancing. If none selected, requests will be sent via direct outbound."));
        destination.depends("specify_outbound", "1");
        destination.datatype = "uciname";
        destination.textvalue = destination_format(config_data, "destination", "specify_outbound", 60);

        let balancer_strategy = extra_inbounds.option(form.Value, 'balancer_strategy', _('Balancer Strategy'), _('Strategy <code>leastPing</code> requires observatory (see "Extra Options" tab) to be enabled.'));
        balancer_strategy.depends("specify_outbound", "1");
        balancer_strategy.value("random");
        balancer_strategy.value("leastPing");
        balancer_strategy.value("roundRobin");
        balancer_strategy.default = "random";
        balancer_strategy.rmempty = false;
        balancer_strategy.modalonly = true;

        s.tab("lan_hosts_access_control", _("LAN Hosts Access Control"));

        let tproxy_ifaces_v4 = s.taboption('lan_hosts_access_control', widgets.DeviceSelect, 'tproxy_ifaces_v4', _("Devices to enable IPv4 tproxy"), _("Enable IPv4 transparent proxy on these interfaces / network devices."));
        tproxy_ifaces_v4.noaliases = true;
        tproxy_ifaces_v4.nocreate = true;
        tproxy_ifaces_v4.multiple = true;

        let tproxy_ifaces_v6 = s.taboption('lan_hosts_access_control', widgets.DeviceSelect, 'tproxy_ifaces_v6', _("Devices to enable IPv6 tproxy"), _("Enable IPv6 transparent proxy on these interfaces / network devices."));
        tproxy_ifaces_v6.noaliases = true;
        tproxy_ifaces_v6.nocreate = true;
        tproxy_ifaces_v6.multiple = true;

        let bypass_ifaces_v4 = s.taboption('lan_hosts_access_control', widgets.DeviceSelect, 'bypass_ifaces_v4', _("Devices to disable IPv4 tproxy"), _("This overrides per-device settings below. FakeDNS and manual transparent proxy won't be affected by this option."));
        bypass_ifaces_v4.noaliases = true;
        bypass_ifaces_v4.nocreate = true;
        bypass_ifaces_v4.multiple = true;

        let bypass_ifaces_v6 = s.taboption('lan_hosts_access_control', widgets.DeviceSelect, 'bypass_ifaces_v6', _("Devices to disable IPv6 tproxy"), _("This overrides per-device settings below. FakeDNS and manual transparent proxy won't be affected by this option."));
        bypass_ifaces_v6.noaliases = true;
        bypass_ifaces_v6.nocreate = true;
        bypass_ifaces_v6.multiple = true;

        let lan_hosts = s.taboption('lan_hosts_access_control', form.SectionValue, "lan_hosts_section", form.GridSection, 'lan_hosts', _('LAN Hosts Access Control'), _("Per-device settings here override per-interface enabling settings above. FakeDNS and manual transparent proxy won't be affected by these options.")).subsection;
        lan_hosts.sortable = false;
        lan_hosts.anonymous = true;
        lan_hosts.addremove = true;

        let title = lan_hosts.option(form.DummyValue, "title", _("Alias / MAC Address"));
        title.modalonly = false;
        title.textvalue = function (s) {
            const item = uci.get(config_data, s);
            if (item.alias) {
                return E([], [item.alias, " ", shared.badge("<strong>...</strong>", item.macaddr)]);
            }
            return item.macaddr;
        };

        let alias = lan_hosts.option(form.Value, "alias", _("Alias (optional)"));
        alias.optional = true;
        alias.modalonly = true;

        let macaddr = lan_hosts.option(form.Value, "macaddr", _("MAC Address"));
        macaddr.datatype = "macaddr";
        macaddr.rmempty = false;
        macaddr.modalonly = true;
        L.sortedKeys(hosts).forEach(function (mac) {
            macaddr.value(mac, E([], [mac, ' (', E('strong', [hosts[mac].name || L.toArray(hosts[mac].ipaddrs || hosts[mac].ipv4)[0] || L.toArray(hosts[mac].ip6addrs || hosts[mac].ipv6)[0] || '?']), ')']));
        });

        let access_control_strategy_v4 = lan_hosts.option(form.ListValue, "access_control_strategy_v4", _("Access Control Strategy (IPv4)"));
        access_control_strategy_v4.value("tproxy", _("Enable transparent proxy"));
        access_control_strategy_v4.value("forward", _("Forward via extra inbound"));
        access_control_strategy_v4.value("bypass", _("Disable transparent proxy"));
        access_control_strategy_v4.modalonly = true;
        access_control_strategy_v4.rmempty = false;

        let access_control_forward_tcp_v4 = lan_hosts.option(form.ListValue, "access_control_forward_tcp_v4", _("Extra inbound (TCP4)"));
        access_control_forward_tcp_v4.depends("access_control_strategy_v4", "forward");
        access_control_forward_tcp_v4.textvalue = access_control_format(config_data, "access_control_strategy_v4", "access_control_forward_tcp_v4");

        let access_control_forward_udp_v4 = lan_hosts.option(form.ListValue, "access_control_forward_udp_v4", _("Extra inbound (UDP4)"));
        access_control_forward_udp_v4.depends("access_control_strategy_v4", "forward");
        access_control_forward_udp_v4.textvalue = access_control_format(config_data, "access_control_strategy_v4", "access_control_forward_udp_v4");

        let access_control_strategy_v6 = lan_hosts.option(form.ListValue, "access_control_strategy_v6", _("Access Control Strategy (IPv6)"));
        access_control_strategy_v6.value("tproxy", _("Enable transparent proxy"));
        access_control_strategy_v6.value("forward", _("Forward via extra inbound"));
        access_control_strategy_v6.value("bypass", _("Disable transparent proxy"));
        access_control_strategy_v6.modalonly = true;
        access_control_strategy_v6.rmempty = false;

        let access_control_forward_tcp_v6 = lan_hosts.option(form.ListValue, "access_control_forward_tcp_v6", _("Extra inbound (TCP6)"));
        access_control_forward_tcp_v6.depends("access_control_strategy_v6", "forward");
        access_control_forward_tcp_v6.textvalue = access_control_format(config_data, "access_control_strategy_v6", "access_control_forward_tcp_v6");

        let access_control_forward_udp_v6 = lan_hosts.option(form.ListValue, "access_control_forward_udp_v6", _("Extra inbound (UDP6)"));
        access_control_forward_udp_v6.depends("access_control_strategy_v6", "forward");
        access_control_forward_udp_v6.textvalue = access_control_format(config_data, "access_control_strategy_v6", "access_control_forward_udp_v6");

        for (const v of uci.sections(config_data, "extra_inbound")) {
            switch (v["inbound_type"]) {
                case "tproxy_tcp": {
                    access_control_forward_tcp_v4.value(v[".name"], extra_outbound_format(config_data, v[".name"], true));
                    access_control_forward_tcp_v6.value(v[".name"], extra_outbound_format(config_data, v[".name"], true));
                    break;
                }
                case "tproxy_udp": {
                    access_control_forward_udp_v4.value(v[".name"], extra_outbound_format(config_data, v[".name"], true));
                    access_control_forward_udp_v6.value(v[".name"], extra_outbound_format(config_data, v[".name"], true));
                    break;
                }
            }
        }

        s.tab('dns', _('DNS'));

        o = s.taboption('dns', form.Value, 'fast_dns', _('Fast DNS'), _("DNS for resolving outbound domains and following bypassed domains"));
        o.datatype = 'or(ip4addr, ip4addrport)';
        o.placeholder = "223.5.5.5:53";

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "bypassed_domain_rules", _('Bypassed domain rules'), _('Specify rules like <code>geosite:cn</code> or <code>domain:bilibili.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        } else {
            o = s.taboption('dns', form.DynamicList, 'bypassed_domain_rules', _('Bypassed domain rules'), _('Specify rules like <code>domain:bilibili.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'));
        }

        o = s.taboption('dns', form.Value, 'secure_dns', _('Secure DNS'), _("DNS for resolving known polluted domains (specify forwarded domain rules here)"));
        o.datatype = 'or(ip4addr, ip4addrport)';
        o.placeholder = "8.8.8.8:53";

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "forwarded_domain_rules", _('Forwarded domain rules'), _('Specify rules like <code>geosite:geolocation-!cn</code> or <code>domain:youtube.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        } else {
            o = s.taboption('dns', form.DynamicList, 'forwarded_domain_rules', _('Forwarded domain rules'), _('Specify rules like <code>domain:youtube.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'));
        }

        o = s.taboption('dns', form.Value, 'default_dns', _('Default DNS'), _("DNS for resolving other sites (not in the rules above) and DNS records other than A or AAAA (TXT and MX for example)"));
        o.datatype = 'or(ip4addr, ip4addrport)';
        o.placeholder = "1.1.1.1:53";

        if (geosite_existence) {
            o = s.taboption('dns', form.DynamicList, "blocked_domain_rules", _('Blocked domain rules'), _('Specify rules like <code>geosite:category-ads</code> or <code>domain:baidu.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        } else {
            o = s.taboption('dns', form.DynamicList, 'blocked_domain_rules', _('Blocked domain rules'), _('Specify rules like <code>domain:baidu.com</code> or see <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.<br/> In order to use Geosite rules you need a valid resource file /usr/share/xray/geosite.dat.<br/>Compile your firmware again with data files to use Geosite rules, or <a href="https://github.com/v2fly/domain-list-community">download one</a> and upload it to your router.'));
        }

        o = s.taboption('dns', form.Flag, 'blocked_to_loopback', _('Blocked to loopback'), _('Return <code>127.127.127.127</code> as response for blocked domain rules. If not selected, <code>NXDOMAIN</code> will be returned.'));
        o.modalonly = true;

        o = s.taboption('dns', form.Value, 'dns_port', _('Xray DNS Server Port'), _("Do not use port 53 (dnsmasq), port 5353 (mDNS) or other common ports"));
        o.datatype = 'port';
        o.placeholder = 5300;

        o = s.taboption('dns', form.Value, 'dns_count', _('Extra DNS Server Ports'), _('Listen for DNS Requests on multiple ports (all of which serves as dnsmasq upstream servers).<br/>For example if Xray DNS Server Port is 5300 and use 3 extra ports, 5300 - 5303 will be used for DNS requests.<br/>Increasing this value may help reduce the possibility of temporary DNS lookup failures.'));
        o.datatype = 'range(0, 50)';
        o.placeholder = 3;

        o = s.taboption('dns', form.ListValue, 'routing_domain_strategy', _('Routing Domain Strategy'), _("Domain resolution strategy when matching domain against rules. (For tproxy, this is effective only when sniffing is enabled.)"));
        o.value("AsIs", "AsIs");
        o.value("IPIfNonMatch", "IPIfNonMatch");
        o.value("IPOnDemand", "IPOnDemand");
        o.default = "AsIs";
        o.rmempty = false;

        s.tab('fake_dns', _('FakeDNS'));

        let tproxy_port_tcp_f4 = s.taboption('fake_dns', form.Value, 'tproxy_port_tcp_f4', _('Transparent proxy port (TCP4)'));
        tproxy_port_tcp_f4.datatype = 'port';
        tproxy_port_tcp_f4.placeholder = 1086;

        let tproxy_port_tcp_f6 = s.taboption('fake_dns', form.Value, 'tproxy_port_tcp_f6', _('Transparent proxy port (TCP6)'));
        tproxy_port_tcp_f6.datatype = 'port';
        tproxy_port_tcp_f6.placeholder = 1087;

        let tproxy_port_udp_f4 = s.taboption('fake_dns', form.Value, 'tproxy_port_udp_f4', _('Transparent proxy port (UDP4)'));
        tproxy_port_udp_f4.datatype = 'port';
        tproxy_port_udp_f4.placeholder = 1088;

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

        let fs = s.taboption('fake_dns', form.SectionValue, "fake_dns_section", form.GridSection, 'fakedns', _('FakeDNS Routing'), _('See <a href="https://github.com/v2ray/v2ray-core/issues/2233">FakeDNS</a> for details.')).subsection;
        fs.sortable = false;
        fs.anonymous = true;
        fs.addremove = true;

        let fake_dns_domain_names = fs.option(form.DynamicList, "fake_dns_domain_names", _("Domain names"));
        fake_dns_domain_names.rmempty = false;
        fake_dns_domain_names.textvalue = list_folded_format(config_data, "fake_dns_domain_names", "domains", 20);

        let fake_dns_forward_server_tcp = fs.option(form.MultiValue, 'fake_dns_forward_server_tcp', _('Force Forward server (TCP)'));
        fake_dns_forward_server_tcp.datatype = "uciname";
        fake_dns_forward_server_tcp.textvalue = destination_format(config_data, "fake_dns_forward_server_tcp", null, 40);

        let fake_dns_forward_server_udp = fs.option(form.MultiValue, 'fake_dns_forward_server_udp', _('Force Forward server (UDP)'));
        fake_dns_forward_server_udp.datatype = "uciname";
        fake_dns_forward_server_udp.textvalue = destination_format(config_data, "fake_dns_forward_server_udp", null, 40);

        let fake_dns_balancer_strategy = fs.option(form.Value, 'fake_dns_balancer_strategy', _('Balancer Strategy'), _('Strategy <code>leastPing</code> requires observatory (see "Extra Options" tab) to be enabled.'));
        fake_dns_balancer_strategy.value("random");
        fake_dns_balancer_strategy.value("leastPing");
        fake_dns_balancer_strategy.value("roundRobin");
        fake_dns_balancer_strategy.default = "random";
        fake_dns_balancer_strategy.rmempty = false;
        fake_dns_balancer_strategy.modalonly = true;

        s.tab('outbound_routing', _('Outbound Routing'));

        if (geoip_existence) {
            let geoip_direct_code_list = s.taboption('outbound_routing', form.DynamicList, 'geoip_direct_code_list', _('GeoIP Direct Code List (IPv4)'), _("Hosts in these GeoIP sets will not be forwarded through Xray. Remove all items to forward all non-private hosts."));
            geoip_direct_code_list.datatype = "string";
            geoip_direct_code_list.value("cn", "cn");
            geoip_direct_code_list.value("telegram", "telegram");

            let geoip_direct_code_list_v6 = s.taboption('outbound_routing', form.DynamicList, 'geoip_direct_code_list_v6', _('GeoIP Direct Code List (IPv6)'), _("Hosts in these GeoIP sets will not be forwarded through Xray. Remove all items to forward all non-private hosts."));
            geoip_direct_code_list_v6.datatype = "string";
            geoip_direct_code_list_v6.value("cn", "cn");
            geoip_direct_code_list_v6.value("telegram", "telegram");
        } else {
            let geoip_direct_code_list = s.taboption('outbound_routing', form.DynamicList, 'geoip_direct_code_list', _('GeoIP Direct Code List (IPv4)'), _("Resource file /usr/share/xray/geoip.dat not exist. All network traffic will be forwarded. <br/> Compile your firmware again with data files to use this feature, or<br/><a href=\"https://github.com/v2fly/geoip\">download one</a> (maybe disable transparent proxy first) and upload it to your router."));
            geoip_direct_code_list.readonly = true;
            geoip_direct_code_list.datatype = "string";

            let geoip_direct_code_list_v6 = s.taboption('outbound_routing', form.DynamicList, 'geoip_direct_code_list_v6', _('GeoIP Direct Code List (IPv6)'), _("Resource file /usr/share/xray/geoip.dat not exist. All network traffic will be forwarded. <br/> Compile your firmware again with data files to use this feature, or<br/><a href=\"https://github.com/v2fly/geoip\">download one</a> (maybe disable transparent proxy first) and upload it to your router."));
            geoip_direct_code_list_v6.readonly = true;
            geoip_direct_code_list_v6.datatype = "string";
        }

        o = s.taboption('outbound_routing', form.DynamicList, "wan_bp_ips", _("Bypassed IP"), _("Requests to these IPs won't be forwarded through Xray."));
        o.datatype = "ipaddr";

        o = s.taboption('outbound_routing', form.DynamicList, "wan_fw_ips", _("Forwarded IP"), _("Requests to these IPs will always be handled by Xray (but still might be bypassed by Xray itself, like private addresses).<br/>Useful for some really strange network. If you really need to forward private addresses, try Manual Transparent Proxy below."));
        o.datatype = "ipaddr";

        o = s.taboption('outbound_routing', form.ListValue, 'transparent_default_port_policy', _('Default Ports Policy'));
        o.value("forwarded", _("Forwarded"));
        o.value("bypassed", _("Bypassed"));
        o.default = "forwarded";

        o = s.taboption('outbound_routing', form.DynamicList, "wan_fw_tcp_ports", _("Forwarded TCP Ports"), _("Requests to these TCP Ports will be forwarded through Xray. Recommended ports: 80, 443, 853"));
        o.depends("transparent_default_port_policy", "bypassed");
        o.datatype = "portrange";

        o = s.taboption('outbound_routing', form.DynamicList, "wan_fw_udp_ports", _("Forwarded UDP Ports"), _("Requests to these UDP Ports will be forwarded through Xray. Recommended ports: 53, 443"));
        o.depends("transparent_default_port_policy", "bypassed");
        o.datatype = "portrange";

        o = s.taboption('outbound_routing', form.DynamicList, "wan_bp_tcp_ports", _("Bypassed TCP Ports"), _("Requests to these TCP Ports won't be forwarded through Xray."));
        o.depends("transparent_default_port_policy", "forwarded");
        o.datatype = "portrange";

        o = s.taboption('outbound_routing', form.DynamicList, "wan_bp_udp_ports", _("Bypassed UDP Ports"), _("Requests to these UDP Ports won't be forwarded through Xray."));
        o.depends("transparent_default_port_policy", "forwarded");
        o.datatype = "portrange";

        o = s.taboption('outbound_routing', form.SectionValue, "access_control_manual_tproxy", form.GridSection, 'manual_tproxy', _('Manual Transparent Proxy'), _('Compared to iptables REDIRECT, Xray could do NAT46 / NAT64 (for example accessing IPv6 only sites). See <a href="https://github.com/v2ray/v2ray-core/issues/2233">FakeDNS</a> for details.'));

        ss = o.subsection;
        ss.sortable = false;
        ss.anonymous = true;
        ss.addremove = true;

        o = ss.option(form.Value, "source_addr", _("Source Address"));
        o.datatype = "ipaddr";

        o = ss.option(form.Value, "source_port", _("Source Port"));

        o = ss.option(form.Value, "dest_addr", _("Destination Address"));
        o.datatype = "host";

        o = ss.option(form.Value, "dest_port", _("Destination Port"));
        o.datatype = "port";

        o = ss.option(form.DynamicList, "domain_names", _("Domain names to associate"));
        o.textvalue = list_folded_format(config_data, "domain_names", "domains", 20);

        o = ss.option(form.Flag, 'rebind_domain_ok', _('Exempt rebind protection'), _('Avoid dnsmasq filtering RFC1918 IP addresses (and some TESTNET addresses as well) from result.<br/>Must be enabled for TESTNET addresses (<code>192.0.2.0/24</code>, <code>198.51.100.0/24</code>, <code>203.0.113.0/24</code>). Addresses like <a href="https://www.as112.net/">AS112 Project</a> (<code>192.31.196.0/24</code>, <code>192.175.48.0/24</code>) or <a href="https://www.nyiix.net/technical/rtbh/">NYIIX RTBH</a> (<code>198.32.160.7</code>) can avoid that.'));
        o.modalonly = true;

        o = ss.option(form.Flag, 'force_forward_tcp', _('Force Forward (TCP)'), _('This destination must be forwarded through an outbound server.'));
        o.modalonly = true;

        o = ss.option(form.ListValue, 'force_forward_server_tcp', _('Force Forward server (TCP)'));
        o.depends("force_forward_tcp", "1");
        o.datatype = "uciname";
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], server_alias(v));
        }
        o.modalonly = true;

        o = ss.option(form.Flag, 'force_forward_udp', _('Force Forward (UDP)'), _('This destination must be forwarded through an outbound server.'));
        o.modalonly = true;

        o = ss.option(form.ListValue, 'force_forward_server_udp', _('Force Forward server (UDP)'));
        o.depends("force_forward_udp", "1");
        o.datatype = "uciname";
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], server_alias(v));
        }
        o.modalonly = true;

        s.tab('xray_server', _('HTTPS Server'));

        o = s.taboption('xray_server', form.Flag, 'web_server_enable', _('Enable Xray HTTPS Server'), _("This will start a HTTPS server which serves both as an inbound for Xray and a reverse proxy web server."));

        o = s.taboption('xray_server', form.Value, 'web_server_port', _('Xray HTTPS Server Port'), _("This port needs to be set <code>accept input</code> manually in firewall settings."));
        o.datatype = 'port';
        o.placeholder = 443;
        o.depends("web_server_enable", "1");

        o = s.taboption('xray_server', form.ListValue, "web_server_protocol", _("Protocol"), _("Only protocols which support fallback are available. Note that REALITY does not support fallback right now."));
        protocol.add_server_protocol(o, s, 'xray_server');
        o.rmempty = false;
        o.depends("web_server_enable", "1");

        o = s.taboption('xray_server', form.DynamicList, 'web_server_password', _('UserId / Password'), _('Fill user_id for vmess / VLESS, or password for shadowsocks / trojan (also supports <a href="https://github.com/XTLS/Xray-core/issues/158">Xray UUID Mapping</a>)'));
        o.depends("web_server_enable", "1");

        o = s.taboption('xray_server', form.Value, 'web_server_address', _('Default Fallback HTTP Server'), _("Only HTTP/1.1 supported here. For HTTP/2 upstream, use Fallback Servers below"));
        o.datatype = 'hostport';
        o.depends("web_server_enable", "1");

        o = s.taboption('xray_server', form.SectionValue, "xray_server_fallback", form.GridSection, 'fallback', _('Fallback Servers'), _("Specify upstream servers here."));
        o.depends({ "web_server_enable": "1", "web_server_protocol": "trojan" });
        o.depends({ "web_server_enable": "1", "web_server_protocol": "vless", "vless_tls": "tls" });
        o.depends({ "web_server_enable": "1", "web_server_protocol": "vless", "vless_tls": "xtls" });

        ss = o.subsection;
        ss.sortable = false;
        ss.anonymous = true;
        ss.addremove = true;

        o = ss.option(form.Value, "name", _("SNI"));

        o = ss.option(form.Value, "alpn", _("ALPN"));

        o = ss.option(form.Value, "path", _("Path"));

        o = ss.option(form.Value, "xver", _("Xver"));
        o.datatype = "uinteger";

        o = ss.option(form.Value, "dest", _("Destination Address"));
        o.datatype = 'hostport';

        s.tab('extra_options', _('Extra Options'));

        o = s.taboption('extra_options', form.Value, 'xray_bin', _('Xray Executable Path'));
        o.rmempty = false;
        if (xray_bin_default) {
            o.value("/usr/bin/xray", _("/usr/bin/xray (default, exist)"));
        }

        o = s.taboption('extra_options', form.ListValue, 'loglevel', _('Log Level'), _('Read Xray log in "System Log" or use <code>logread</code> command.'));
        o.value("debug");
        o.value("info");
        o.value("warning");
        o.value("error");
        o.value("none");
        o.default = "warning";

        o = s.taboption('extra_options', form.Flag, 'access_log', _('Enable Access Log'), _('Access log will also be written to System Log.'));

        o = s.taboption('extra_options', form.Flag, 'dns_log', _('Enable DNS Log'), _('DNS log will also be written to System Log.'));

        o = s.taboption('extra_options', form.Flag, 'xray_api', _('Enable Xray API Service'), _('Xray API Service uses port 8080 and GRPC protocol. Also callable via <code>xray api</code> or <code>ubus call xray</code>. See <a href="https://xtls.github.io/document/command.html#xray-api">here</a> for help.'));

        o = s.taboption('extra_options', form.Flag, 'stats', _('Enable Statistics'), _('Enable statistics of inbounds / outbounds data. Use Xray API to query values.'));

        o = s.taboption('extra_options', form.Flag, 'observatory', _('Enable Observatory'), _('Enable latency measurement for TCP and UDP outbounds.'));

        o = s.taboption('extra_options', form.Flag, 'fw4_counter', _('Enable Firewall Counters'), _('Add <a href="/cgi-bin/luci/admin/status/nftables">counters to firewall4</a> for transparent proxy rules. (Not supported in all OpenWrt versions. )'));

        o = s.taboption('extra_options', form.Flag, 'metrics_server_enable', _('Enable Xray Metrics Server'), _("Enable built-in metrics server for pprof and expvar. See <a href='https://github.com/XTLS/Xray-core/pull/1000'>here</a> for details."));

        o = s.taboption('extra_options', form.Value, 'metrics_server_port', _('Xray Metrics Server Port'), _("Metrics may be sensitive so think twice before setting it as Default Fallback HTTP Server."));
        o.depends("metrics_server_enable", "1");
        o.datatype = 'port';
        o.placeholder = '18888';

        o = s.taboption('extra_options', form.Value, 'handshake', _('Handshake Timeout'), _('Policy: Handshake timeout when connecting to upstream. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = 4;

        o = s.taboption('extra_options', form.Value, 'conn_idle', _('Connection Idle Timeout'), _('Policy: Close connection if no data is transferred within given timeout. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = 300;

        o = s.taboption('extra_options', form.Value, 'uplink_only', _('Uplink Only Timeout'), _('Policy: How long to wait before closing connection after server closed connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = 2;

        o = s.taboption('extra_options', form.Value, 'downlink_only', _('Downlink Only Timeout'), _('Policy: How long to wait before closing connection after client closed connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = 5;

        o = s.taboption('extra_options', form.Value, 'buffer_size', _('Buffer Size'), _('Policy: Internal cache size per connection. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = 512;

        o = s.taboption('extra_options', form.Flag, 'preview_or_deprecated', _('Preview or Deprecated'), _("Show preview or deprecated features (requires reboot to take effect)."));

        o = s.taboption('extra_options', form.SectionValue, "xray_bridge", form.TableSection, 'bridge', _('Bridge'), _('Reverse proxy tool. Currently only client role (bridge) is supported. See <a href="https://xtls.github.io/config/reverse.html#bridgeobject">here</a> for help.'));

        ss = o.subsection;
        ss.sortable = false;
        ss.anonymous = true;
        ss.addremove = true;

        o = ss.option(form.ListValue, "upstream", _("Upstream"));
        o.datatype = "uciname";
        for (const v of uci.sections(config_data, "servers")) {
            o.value(v[".name"], server_alias(v));
        }

        o = ss.option(form.Value, "domain", _("Domain"));
        o.rmempty = false;

        o = ss.option(form.Value, "redirect", _("Redirect address"));
        o.datatype = "hostport";
        o.rmempty = false;

        s.tab('custom_options', _('Custom Options'));
        let custom_configuration_hook = s.taboption('custom_options', form.TextValue, 'custom_configuration_hook', _('Custom Configuration Hook'), _('Read <a href="https://ucode.mein.io/">ucode Documentation</a> for the language used. Code filled here may need to change after upgrading luci-app-xray.'));
        custom_configuration_hook.placeholder = "return function(config) {\n    return config;\n};";
        custom_configuration_hook.monospace = true;
        custom_configuration_hook.rows = 20;

        const servers = uci.sections(config_data, "servers");
        for (let selection of [destination, fake_dns_forward_server_tcp, fake_dns_forward_server_udp, tcp_balancer_v4, tcp_balancer_v6, udp_balancer_v4, udp_balancer_v6]) {
            if (servers.length == 0) {
                selection.value("direct", _("No server configured"));
                selection.readonly = true;
                continue;
            }
            for (const v of servers) {
                selection.value(v[".name"], server_alias(v));
            }
        }
        return m.render();
    }
});
