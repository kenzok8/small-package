'use strict';
'require form';
'require uci';
'require view';
'require view.xray.shared as shared';

return view.extend({
    load: function () {
        return uci.load("dhcp");
    },

    render: function (result) {
        const m = new form.Map(shared.variant, _('Xray (preview)'), _("WARNING: These features are experimental, may cause a lot of problems and are not guaranteed to be compatible across minor versions."));

        let s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab("dns_hijack", _("DNS Hijacking"));
        s.taboption('dns_hijack', form.Flag, 'align_fast_dns_to_geoip_direct', _('Align Fast DNS & GeoIP Direct'), _("Return only IP addresses from GeoIP Direct List for Fast DNS."));

        let dnsmasq_integration_mode = s.taboption('dns_hijack', form.ListValue, 'dnsmasq_integration_mode', _('Dnsmasq Integration Mode'), _('Per Instance mode requires OpenWrt 24.10 or later versions.'));
        dnsmasq_integration_mode.value("global", _("Global"));
        dnsmasq_integration_mode.value("per_instance", _("Per Instance"));
        dnsmasq_integration_mode.default = "global";

        let dnsmasq_instances = s.taboption('dns_hijack', form.MultiValue, 'dnsmasq_instances', _('Integrated Instances'), _('Select none to disable dnsmasq integration. This could also be used to avoid conflicts with other DNS services, for example<br/>AdGuard Home. Some features like manual transparent proxy with associated domain names still need dnsmasq integration.'));
        dnsmasq_instances.depends("dnsmasq_integration_mode", "per_instance");
        for (let i of uci.sections("dhcp", "dnsmasq")) {
            dnsmasq_instances.value(i[".name"], function () {
                if (i[".anonymous"]) {
                    return _("Default instance");
                }
                return `${_("Instance")} "${i[".name"]}"`;
            }());
        }

        let dns_tcp_hijack = s.taboption('dns_hijack', form.Value, 'dns_tcp_hijack', _('Hijack TCP DNS Requests'), _("Redirect all outgoing TCP requests with destination port 53 to the address specified. In most cases not necessary."));
        dns_tcp_hijack.datatype = 'ip4addrport';

        let dns_udp_hijack = s.taboption('dns_hijack', form.Value, 'dns_udp_hijack', _('Hijack UDP DNS Requests'), _("Redirect all outgoing UDP requests with destination port 53 to the address specified. Recommended to use <code>127.0.0.1:53</code>."));
        dns_udp_hijack.datatype = 'ip4addrport';

        s.tab("firewall", _("Extra Firewall Options"));

        let mark = s.taboption('firewall', form.Value, 'mark', _('Socket Mark Number'), _('Avoid proxy loopback problems with local (gateway) traffic'));
        mark.datatype = 'range(1, 255)';
        mark.placeholder = 255;

        let firewall_priority = s.taboption('firewall', form.Value, 'firewall_priority', _('Priority for Firewall Rules'), _('See firewall status page for rules Xray used and <a href="https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks#Priority_within_hook">Netfilter Internal Priority</a> for reference.'));
        firewall_priority.datatype = 'range(-49, 49)';
        firewall_priority.placeholder = 10;

        let ttl_override = s.taboption('firewall', form.Value, 'ttl_override', _('Override IPv4 TTL'), _("Strongly not recommended. Only used for some network environments with specific restrictions."));
        ttl_override.datatype = 'uinteger';

        let hop_limit_override = s.taboption('firewall', form.Value, 'hop_limit_override', _('Override IPv6 Hop Limit'), _("Strongly not recommended. Only used for some network environments with specific restrictions."));
        hop_limit_override.datatype = 'uinteger';

        let ttl_hop_limit_match = s.taboption('firewall', form.Value, 'ttl_hop_limit_match', _('TTL / Hop Limit Match'), _("Only override TTL / hop limit for packets with specific TTL / hop limit."));
        ttl_hop_limit_match.datatype = 'uinteger';

        let ttl_override_bypass_ports = s.taboption('firewall', form.DynamicList, 'ttl_override_bypass_ports', _('Ports to bypass TTL override'), _("Do not override TTL for packets with these destination TCP / UDP ports."));
        ttl_override_bypass_ports.datatype = 'port';

        s.tab("sniffing", _("Sniffing"));

        s.taboption('sniffing', form.Flag, 'tproxy_sniffing', _('Enable Sniffing'), _('Route requests according to domain settings in "DNS Settings" tab in core settings. Deprecated; use FakeDNS instead.'));

        let route_only = s.taboption('sniffing', form.Flag, 'route_only', _('Route Only'), _('Use sniffed domain for routing only but still access through IP. Reduces unnecessary DNS requests. See <a href="https://github.com/XTLS/Xray-core/commit/a3023e43ef55d4498b1afbc9a7fe7b385138bb1a">here</a> for help.'));
        route_only.depends("tproxy_sniffing", "1");

        let direct_bittorrent = s.taboption('sniffing', form.Flag, 'direct_bittorrent', _('Bittorrent Direct'), _("If enabled, no bittorrent request will be forwarded through Xray."));
        direct_bittorrent.depends("tproxy_sniffing", "1");

        let routing_domain_strategy = s.taboption('sniffing', form.ListValue, 'routing_domain_strategy', _('Routing Domain Strategy'), _("Domain resolution strategy when matching domain against rules. (For tproxy, this is effective only when sniffing is enabled.)"));
        routing_domain_strategy.value("AsIs", "AsIs");
        routing_domain_strategy.value("IPIfNonMatch", "IPIfNonMatch");
        routing_domain_strategy.value("IPOnDemand", "IPOnDemand");
        routing_domain_strategy.depends("tproxy_sniffing", "1");
        routing_domain_strategy.default = "AsIs";

        s.tab('dynamic_direct', _('Dynamic Direct'));

        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_tcp4', _('Enable for IPv4 TCP'), _("This should improve performance with large number of connections."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_tcp6', _('Enable for IPv4 UDP'), _("This may cause problems but worth a try."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_udp4', _('Enable for IPv6 TCP'), _("This may not be very useful but it should be good enough for a try."));
        s.taboption('dynamic_direct', form.Flag, 'dynamic_direct_udp6', _('Enable for IPv6 UDP'), _("This may cause problems and is not very useful at the same time. Not recommended."));

        let dynamic_direct_timeout = s.taboption('dynamic_direct', form.Value, 'dynamic_direct_timeout', _('Dynamic Direct Timeout'), _("Larger value consumes more memory and performs generally better. Unit in seconds."));
        dynamic_direct_timeout.datatype = 'uinteger';
        dynamic_direct_timeout.placeholder = 2233;

        s.tab('deprecated', _('Deprecated Features'));

        let socks_port = s.taboption('deprecated', form.Value, 'socks_port', _('Socks5 proxy port'), _("Deprecated for security concerns and will be removed in next major version. Use Extra Inbound instead."));
        socks_port.datatype = 'port';
        socks_port.placeholder = 1080;

        let http_port = s.taboption('deprecated', form.Value, 'http_port', _('HTTP proxy port'), _("Deprecated for security concerns and will be removed in next major version. Use Extra Inbound instead."));
        http_port.datatype = 'port';
        http_port.placeholder = 1081;

        let custom_config = s.taboption('deprecated', form.TextValue, 'custom_config', _('Custom Configurations'), _('See <a href="https://xtls.github.io/config/features/multiple.html">here</a> for help. Deprecated and will be removed in next major version.'));
        custom_config.monospace = true;
        custom_config.rows = 20;
        custom_config.validate = shared.validate_object;

        return m.render();
    }
});
