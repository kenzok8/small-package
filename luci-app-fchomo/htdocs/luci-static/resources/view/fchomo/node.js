'use strict';
'require form';
'require uci';
'require ui';
'require view';

'require fchomo as hm';
'require tools.widgets as widgets';

function parseProviderYaml(field, name, cfg) {
	if (!cfg.type)
		return null;

	// key mapping
	let config = hm.removeBlankAttrs({
		id: cfg.hm_id,
		label: cfg.hm_label,
		type: cfg.type,
		...(cfg.type === 'inline' ? {
			//dialer_proxy: cfg["dialer-proxy"],
			payload: cfg.payload, // string: array
		} : {
			url: cfg.url,
			size_limit: cfg["size-limit"],
			interval: cfg.interval,
			proxy: cfg.proxy ? hm.preset_outbound.full.map(([key, label]) => key).includes(cfg.proxy) ? cfg.proxy : this.calcID(hm.glossary["proxy_group"].field, cfg.proxy) : null,
			header: cfg.header ? JSON.stringify(cfg.header, null, 2) : null, // string: object
			/* Health fields */
			health_enable: hm.bool2str(hm.getValue(cfg, "health-check.enable")), // bool
			health_url: hm.getValue(cfg, "health-check.url"),
			health_interval: hm.getValue(cfg, "health-check.interval"),
			health_timeout: hm.getValue(cfg, "health-check.timeout"),
			health_lazy: hm.bool2str(hm.getValue(cfg, "health-check.lazy")), // bool
			health_expected_status: hm.getValue(cfg, "health-check.expected-status"),
			/* Override fields */
			override_prefix: hm.getValue(cfg, "override.additional-prefix"),
			override_suffix: hm.getValue(cfg, "override.additional-suffix"),
			override_replace: (hm.getValue(cfg, "override.proxy-name") || []).map((obj) => JSON.stringify(obj)), // array.string: array.object
			// Configuration Items
			override_tfo: hm.bool2str(hm.getValue(cfg, "override.tfo")), // bool
			override_mptcp: hm.bool2str(hm.getValue(cfg, "override.mptcp")), // bool
			override_udp: hm.bool2str(hm.getValue(cfg, "override.udp")), // bool
			override_uot: hm.bool2str(hm.getValue(cfg, "override.udp-over-tcp")), // bool
			override_up: hm.getValue(cfg, "override.up"),
			override_down: hm.getValue(cfg, "override.down"),
			override_skip_cert_verify: hm.bool2str(hm.getValue(cfg, "override.skip-cert-verify")), // bool
			//override_dialer_proxy: hm.getValue(cfg, "override.dialer-proxy"),
			override_interface_name: hm.getValue(cfg, "override.interface-name"),
			override_routing_mark: hm.getValue(cfg, "override.routing-mark"),
			override_ip_version: hm.getValue(cfg, "override.ip-version"),
			/* General fields */
			filter: [cfg.filter], // array.string: string
			exclude_filter: [cfg["exclude-filter"]], // array.string: string
			exclude_type: [cfg["exclude-type"]] // array.string: string
		})
	});

	return config;
}

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo')
		]);
	},

	render(data) {
		let m, s, o, ss, so;

		m = new form.Map('fchomo', _('Edit node'));

		s = m.section(form.NamedSection, 'global', 'fchomo');

		/* Proxy Node START */
		s.tab('node', _('Proxy Node'));

		/* Proxy Node */
		o = s.taboption('node', form.SectionValue, '_node', hm.GridSection, 'node', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Node'), _('Add a Node') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = true;

		ss.tab('field_general', _('General fields'));
		ss.tab('field_tls', _('TLS fields'));
		ss.tab('field_transport', _('Transport fields'));
		ss.tab('field_multiplex', _('Multiplex fields'));
		ss.tab('field_dial', _('Dial fields'));

		so = ss.taboption('field_general', form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.taboption('field_general', form.ListValue, 'type', _('Type'));
		so.default = hm.outbound_type[0][0];
		hm.outbound_type.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.taboption('field_general', form.Value, 'server', _('Server address'));
		so.datatype = 'host';
		so.rmempty = false;
		so.depends({type: 'direct', '!reverse': true});

		so = ss.taboption('field_general', form.Value, 'port', _('Port'));
		so.datatype = 'port';
		so.rmempty = false;
		so.depends({type: /^(direct|mieru)$/, '!reverse': true});

		/* HTTP / SOCKS fields */
		/* hm.validateAuth */
		so = ss.taboption('field_general', form.Value, 'username', _('Username'));
		so.validate = L.bind(hm.validateAuthUsername, so);
		so.depends({type: /^(http|socks5|mieru|ssh)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'password', _('Password'));
		so.password = true;
		so.validate = L.bind(hm.validateAuthPassword, so);
		so.depends({type: /^(http|socks5|mieru|trojan|anytls|hysteria2|tuic|ssh)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', hm.TextValue, 'headers', _('HTTP header'));
		so.placeholder = '{\n  "User-Agent": [\n    "Clash/v1.18.0",\n    "mihomo/1.18.3"\n  ],\n  "Authorization": [\n    //"token 1231231"\n  ]\n}';
		so.validate = L.bind(hm.validateJson, so);
		so.depends('type', 'http');
		so.modalonly = true;

		/* Hysteria / Hysteria2 fields */
		so = ss.taboption('field_general', form.DynamicList, 'hysteria_ports', _('Ports pool'));
		so.datatype = 'or(port, portrange)';
		so.depends({type: /^(hysteria|hysteria2)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'hysteria_up_mbps', _('Max upload speed'),
			_('In Mbps.'));
		so.datatype = 'uinteger';
		so.depends({type: /^(hysteria|hysteria2)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'hysteria_down_mbps', _('Max download speed'),
			_('In Mbps.'));
		so.datatype = 'uinteger';
		so.depends({type: /^(hysteria|hysteria2)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'hysteria_obfs_type', _('Obfuscate type'));
		so.value('', _('Disable'));
		so.value('salamander', _('Salamander'));
		so.depends('type', 'hysteria2');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'hysteria_obfs_password', _('Obfuscate password'),
			_('Enabling obfuscation will make the server incompatible with standard QUIC connections, losing the ability to masquerade with HTTP/3.'));
		so.password = true;
		so.rmempty = false;
		so.depends('type', 'hysteria');
		so.depends({type: 'hysteria2', hysteria_obfs_type: /.+/});
		so.modalonly = true;

		/* SSH fields */
		so = ss.taboption('field_general', form.TextValue, 'ssh_priv_key', _('Priv-key'));
		so.depends('type', 'ssh');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'ssh_priv_key_passphrase', _('Priv-key passphrase'));
		so.password = true;
		so.depends({type: 'ssh', ssh_priv_key: /.+/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'ssh_host_key_algorithms', _('Host-key algorithms'));
		so.placeholder = 'rsa';
		so.depends('type', 'ssh');
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'ssh_host_key', _('Host-key'));
		so.placeholder = 'ssh-rsa AAAAB3NzaC1yc2EAA...';
		so.depends({type: 'ssh', ssh_host_key_algorithms: /.+/});
		so.modalonly = true;

		/* Shadowsocks fields */
		so = ss.taboption('field_general', form.ListValue, 'shadowsocks_chipher', _('Chipher'));
		so.default = hm.shadowsocks_cipher_methods[1][0];
		hm.shadowsocks_cipher_methods.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends('type', 'ss');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'shadowsocks_password', _('Password'));
		so.password = true;
		so.validate = function(section_id, value) {
			const encmode = this.section.getOption('shadowsocks_chipher').formvalue(section_id);
			return hm.validateShadowsocksPassword.call(this, encmode, section_id, value);
		}
		so.depends({type: 'ss', shadowsocks_chipher: /.+/});
		so.modalonly = true;

		/* Mieru fields */
		so = ss.taboption('field_general', form.Value, 'mieru_port_range', _('Port range'));
		so.datatype = 'portrange';
		so.depends('type', 'mieru');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'mieru_transport', _('Transport'));
		so.value('TCP');
		so.default = 'TCP';
		so.depends('type', 'mieru');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'mieru_multiplexing', _('Multiplexing'));
		so.value('MULTIPLEXING_OFF');
		so.value('MULTIPLEXING_LOW');
		so.value('MULTIPLEXING_MIDDLE');
		so.value('MULTIPLEXING_HIGH');
		so.default = 'MULTIPLEXING_LOW';
		so.depends('type', 'mieru');
		so.modalonly = true;

		/* Snell fields */
		so = ss.taboption('field_general', form.Value, 'snell_psk', _('Pre-shared key'));
		so.password = true;
		so.rmempty = false;
		so.validate = L.bind(hm.validateAuthPassword, so);
		so.depends('type', 'snell');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'snell_version', _('Version'));
		so.value('1', _('v1'));
		so.value('2', _('v2'));
		so.value('3', _('v3'));
		so.default = '3';
		so.depends('type', 'snell');
		so.modalonly = true;

		/* TUIC fields */
		so = ss.taboption('field_general', form.Value, 'uuid', _('UUID'));
		so.rmempty = false;
		so.validate = L.bind(hm.validateUUID, so);
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'tuic_ip', _('IP override'),
			_('Override the IP address of the server that DNS response.'));
		so.datatype = 'ipaddr(1)';
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'tuic_congestion_controller', _('Congestion controller'),
			_('QUIC congestion controller.'));
		so.default = 'cubic';
		so.value('cubic', _('cubic'));
		so.value('new_reno', _('new_reno'));
		so.value('bbr', _('bbr'));
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'tuic_udp_relay_mode', _('UDP relay mode'),
			_('UDP packet relay mode.'));
		so.value('native', _('Native'));
		so.value('quic', _('QUIC'));
		so.depends({type: 'tuic', tuic_udp_over_stream: '0'});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'tuic_udp_over_stream', _('UDP over stream'),
			_('This is the TUIC port of the SUoT protocol, designed to provide a QUIC stream based UDP relay mode that TUIC does not provide.'));
		so.default = so.disabled;
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'tuic_udp_over_stream_version', _('UDP over stream version'));
		so.value('1', _('v1'));
		so.depends({type: 'tuic', tuic_udp_over_stream: '1'});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'tuic_max_udp_relay_packet_size', _('Max UDP relay packet size'));
		so.datatype = 'uinteger';
		so.placeholder = '1500';
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'tuic_reduce_rtt', _('Enable 0-RTT handshake'),
			_('Enable 0-RTT QUIC connection handshake on the client side. This is not impacting much on the performance, as the protocol is fully multiplexed.<br/>' +
				'Disabling this is highly recommended, as it is vulnerable to replay attacks.'));
		so.default = so.disabled;
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'tuic_heartbeat', _('Heartbeat interval'),
			_('In millisecond.'));
		so.datatype = 'uinteger';
		so.placeholder = '10000';
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'tuic_request_timeout', _('Request timeout'),
			_('In millisecond.'));
		so.datatype = 'uinteger';
		so.placeholder = '8000';
		so.depends('type', 'tuic');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'tuic_max_open_streams', _('Max open streams'));
		so.datatype = 'uinteger';
		so.placeholder = '100';
		so.depends('type', 'tuic');
		so.modalonly = true;

		/* Trojan fields */
		so = ss.taboption('field_general', form.Flag, 'trojan_ss_enabled', _('Shadowsocks encrypt'));
		so.default = so.disabled;
		so.depends('type', 'trojan');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'trojan_ss_chipher', _('Shadowsocks chipher'));
		so.default = hm.trojan_cipher_methods[0][0];
		hm.trojan_cipher_methods.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends({type: 'trojan', trojan_ss_enabled: '1'});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'trojan_ss_password', _('Shadowsocks password'));
		so.password = true;
		so.validate = function(section_id, value) {
			const encmode = this.section.getOption('trojan_ss_chipher').formvalue(section_id);
			return hm.validateShadowsocksPassword.call(this, encmode, section_id, value);
		}
		so.depends({type: 'trojan', trojan_ss_enabled: '1'});
		so.modalonly = true;

		/* AnyTLS fields */
		so = ss.taboption('field_general', form.Value, 'anytls_idle_session_check_interval', _('Idle session check interval'),
			_('In seconds.'));
		so.placeholder = '30';
		so.validate = L.bind(hm.validateTimeDuration, so);
		so.depends('type', 'anytls');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'anytls_idle_session_timeout', _('Idle session timeout'),
			_('In seconds.'));
		so.placeholder = '30';
		so.validate = L.bind(hm.validateTimeDuration, so);
		so.depends('type', 'anytls');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'anytls_min_idle_session', _('Min of idle sessions to keep'));
		so.datatype = 'uinteger';
		so.placeholder = '0';
		so.depends('type', 'anytls');
		so.modalonly = true;

		/* VMess / VLESS fields */
		so = ss.taboption('field_general', form.Value, 'vmess_uuid', _('UUID'));
		so.rmempty = false;
		so.validate = L.bind(hm.validateUUID, so);
		so.depends({type: /^(vmess|vless)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'vless_flow', _('Flow'));
		so.default = hm.vless_flow[0][0];
		hm.vless_flow.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends('type', 'vless');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'vmess_alterid', _('Alter ID'));
		so.datatype = 'uinteger';
		so.default = '0';
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'vmess_chipher', _('Chipher'));
		so.default = 'auto';
		so.value('auto', _('auto'));
		so.value('none', _('none'));
		so.value('zero', _('zero'));
		so.value('aes-128-gcm', _('aes-128-gcm'));
		so.value('chacha20-poly1305', _('chacha20-poly1305'));
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'vmess_global_padding', _('Global padding'),
			_('Protocol parameter. Will waste traffic randomly if enabled (enabled by default in v2ray and cannot be disabled).'));
		so.default = so.enabled;
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'vmess_authenticated_length', _('Authenticated length'),
			_('Protocol parameter. Enable length block encryption.'));
		so.default = so.disabled;
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'vmess_packet_encoding', _('Packet encoding'));
		so.value('', _('none'));
		so.value('packetaddr', _('packet addr (v2ray-core v5+)'));
		so.value('xudp', _('Xudp (Xray-core)'));
		so.depends({type: /^(vmess|vless)$/});
		so.modalonly = true;

		/* WireGuard fields */
		so = ss.taboption('field_general', form.Value, 'wireguard_ip', _('Local address'),
			_('The %s address used by local machine in the Wireguard network.').format('IPv4'));
		so.datatype = 'ip4addr(1)';
		so.rmempty = false;
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'wireguard_ipv6', _('Local IPv6 address'),
			_('The %s address used by local machine in the Wireguard network.').format('IPv6'));
		so.datatype = 'ip6addr(1)';
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'wireguard_private_key', _('Private key'),
			_('WireGuard requires base64-encoded private keys.'));
		so.password = true;
		so.validate = L.bind(hm.validateBase64Key, so, 44);
		so.rmempty = false;
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'wireguard_peer_public_key', _('Peer pubkic key'),
			_('WireGuard peer public key.'));
		so.validate = L.bind(hm.validateBase64Key, so, 44);
		so.rmempty = false;
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'wireguard_pre_shared_key', _('Pre-shared key'),
			_('WireGuard pre-shared key.'));
		so.password = true;
		so.validate = L.bind(hm.validateBase64Key, so, 44);
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'wireguard_allowed_ips', _('Allowed IPs'),
			_('Destination addresses allowed to be forwarded via Wireguard.'));
		so.datatype = 'cidr';
		so.placeholder = '0.0.0.0/0';
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'wireguard_reserved', _('Reserved field bytes'));
		so.datatype = 'integer';
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'wireguard_mtu', _('MTU'));
		so.datatype = 'range(0,9000)';
		so.placeholder = '1408';
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'wireguard_remote_dns_resolve', _('Remote DNS resolve'),
			_('Force DNS remote resolution.'));
		so.default = so.disabled;
		so.depends('type', 'wireguard');
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'wireguard_dns', _('DNS server'));
		so.datatype = 'or(host, hostport)';
		so.depends('wireguard_remote_dns_resolve', '1');
		so.modalonly = true;

		/* Plugin fields */
		so = ss.taboption('field_general', form.ListValue, 'plugin', _('Plugin'));
		so.value('', _('none'));
		so.value('obfs', _('obfs-simple'));
		//so.value('v2ray-plugin', _('v2ray-plugin'));
		//so.value('gost-plugin', _('gost-plugin'));
		so.value('shadow-tls', _('shadow-tls'));
		so.value('restls', _('restls'));
		so.depends('type', 'ss');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'plugin_opts_obfsmode', _('Plugin: ') + _('Obfs Mode'));
		so.value('http', _('HTTP'));
		so.value('tls', _('TLS'));
		so.depends('plugin', 'obfs');
		so.depends('type', 'snell');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'plugin_opts_host', _('Plugin: ') + _('Host that supports TLS 1.3'));
		so.datatype = 'hostname';
		so.placeholder = 'cloud.tencent.com';
		so.rmempty = false;
		so.depends({plugin: /^(obfs|v2ray-plugin|shadow-tls|restls)$/});
		so.depends('type', 'snell');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'plugin_opts_thetlspassword', _('Plugin: ') + _('Password'));
		so.password = true;
		so.rmempty = false;
		so.depends({plugin: /^(shadow-tls|restls)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'plugin_opts_shadowtls_version', _('Plugin: ') + _('Version'));
		so.value('1', _('v1'));
		so.value('2', _('v2'));
		so.value('3', _('v3'));
		so.default = '2';
		so.depends({plugin: 'shadow-tls'});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'plugin_opts_restls_versionhint', _('Plugin: ') + _('Version hint'));
		so.default = 'tls13';
		so.rmempty = false;
		so.depends({plugin: 'restls'});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'plugin_opts_restls_script', _('Plugin: ') + _('Restls script'));
		so.default = '300?100<1,400~100,350~100,600~100,300~200,300~100';
		so.rmempty = false;
		so.depends({plugin: 'restls'});
		so.modalonly = true;

		/* Extra fields */
		so = ss.taboption('field_general', form.Flag, 'udp', _('UDP'));
		so.default = so.disabled;
		so.depends({type: /^(direct|socks5|ss|mieru|vmess|vless|trojan|anytls|wireguard)$/});
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'uot', _('UoT'),
			_('Enable the SUoT protocol, requires server support. Conflict with Multiplex.'));
		so.default = so.disabled;
		so.depends('type', 'ss');
		so.modalonly = true;

		so = ss.taboption('field_general', form.ListValue, 'uot_version', _('SUoT version'));
		so.value('1', _('v1'));
		so.value('2', _('v2'));
		so.default = '2';
		so.depends('uot', '1');
		so.modalonly = true;

		/* TLS fields */
		so = ss.taboption('field_general', form.Flag, 'tls', _('TLS'));
		so.default = so.disabled;
		so.validate = function(section_id, value) {
			const type = this.section.getOption('type').formvalue(section_id);
			let tls = this.section.getUIElement(section_id, 'tls').node.querySelector('input');

			// Force enabled
			if (['trojan', 'anytls', 'hysteria', 'hysteria2', 'tuic'].includes(type)) {
				tls.checked = true;
				tls.disabled = true;
			} else {
				tls.disabled = null;
			}

			return true;
		}
		so.depends({type: /^(http|socks5|vmess|vless|trojan|anytls|hysteria|hysteria2|tuic)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Flag, 'tls_disable_sni', _('Disable SNI'),
			_('Donot send server name in ClientHello.'));
		so.default = so.disabled;
		so.depends({tls: '1', type: /^(tuic)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Value, 'tls_sni', _('TLS SNI'),
			_('Used to verify the hostname on the returned certificates.'));
		so.depends({tls: '1', type: /^(http|vmess|vless|trojan|anytls|hysteria|hysteria2)$/});
		so.depends({tls: '1', tls_disable_sni: '0', type: /^(tuic)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.DynamicList, 'tls_alpn', _('TLS ALPN'),
			_('List of supported application level protocols, in order of preference.'));
		so.validate = function(section_id, value) {
			const type = this.section.getOption('type').formvalue(section_id);
			//const plugin = this.section.getOption('plugin').formvalue(section_id);
			let tls_alpn = this.section.getUIElement(section_id, 'tls_alpn');

			// Default alpn
			if (!`${tls_alpn.getValue()}`) {
				let def_alpn;

				switch (type) {
					case 'ss':
						def_alpn = ['h2', 'http/1.1']; // when plugin === 'shadow-tls'
						break;
					case 'hysteria':
					case 'hysteria2':
					case 'tuic':
						def_alpn = ['h3'];
						break;
					case 'vmess':
					case 'vless':
					case 'trojan':
					case 'anytls':
						def_alpn = ['h2', 'http/1.1'];
						break;
					default:
						def_alpn = [];
				}

				tls_alpn.setValue(def_alpn);
			}

			return true;
		}
		so.depends({tls: '1', type: /^(vmess|vless|trojan|anytls|hysteria|hysteria2|tuic)$/});
		so.depends({type: 'ss', plugin: 'shadow-tls'});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Value, 'tls_fingerprint', _('Cert fingerprint'),
			_('Certificate fingerprint. Used to implement SSL Pinning and prevent MitM.'));
		so.validate = function(section_id, value) {
			if (!value)
				return true;
			if (!((value.length === 64) && (value.match(/^[0-9a-fA-F]+$/))))
				return _('Expecting: %s').format(_('valid SHA256 string with %d characters').format(64));

			return true;
		}
		so.depends({tls: '1', type: /^(http|socks5|vmess|vless|trojan|hysteria|hysteria2)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Flag, 'tls_skip_cert_verify', _('Skip cert verify'),
			_('Donot verifying server certificate.') +
			'<br/>' +
			_('This is <strong>DANGEROUS</strong>, your traffic is almost like <strong>PLAIN TEXT</strong>! Use at your own risk!'));
		so.default = so.disabled;
		so.depends({tls: '1', type: /^(http|socks5|vmess|vless|trojan|anytls|hysteria|hysteria2|tuic)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Flag, 'tls_ech', _('Enable ECH'));
		so.default = so.disabled;
		so.depends({tls: '1', type: /^(vmess|vless|trojan|anytls|hysteria|hysteria2|tuic)$/});
		so.depends({type: 'ss', plugin: /^(shadow-tls|restls)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Value, 'tls_ech_config', _('ECH config'),
			_('The ECH parameter of the HTTPS record for the domain. Leave empty to resolve via DNS.'));
		so.placeholder = 'AEn+DQBFKwAgACABWIHUGj4u+PIggYXcR5JF0gYk3dCRioBW8uJq9H4mKAAIAAEAAQABAANAEnB1YmxpYy50bHMtZWNoLmRldgAA';
		so.depends('tls_ech', '1');
		so.modalonly = true;

		// uTLS fields
		so = ss.taboption('field_tls', form.ListValue, 'tls_client_fingerprint', _('Client fingerprint'));
		so.default = hm.tls_client_fingerprints[0][0];
		hm.tls_client_fingerprints.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends({tls: '1', type: /^(vmess|vless|trojan|anytls)$/});
		so.depends({type: 'ss', plugin: /^(shadow-tls|restls)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Flag, 'tls_reality', _('REALITY'));
		so.default = so.disabled;
		so.depends({tls: '1', type: /^(vmess|vless|trojan)$/});
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Value, 'tls_reality_public_key', _('REALITY public key'));
		so.rmempty = false;
		so.depends('tls_reality', '1');
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Value, 'tls_reality_short_id', _('REALITY short ID'));
		so.rmempty = false;
		so.depends('tls_reality', '1');
		so.modalonly = true;

		so = ss.taboption('field_tls', form.Flag, 'tls_reality_support_x25519mlkem768', _('REALITY X25519MLKEM768 PQC support'),
			_('Requires server support.'));
		so.default = so.disabled;
		so.depends('tls_reality', '1');
		so.modalonly = true;

		/* Transport fields */
		so = ss.taboption('field_general', form.Flag, 'transport_enabled', _('Transport'));
		so.default = so.disabled;
		so.depends({type: /^(vmess|vless|trojan)$/});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.ListValue, 'transport_type', _('Transport type'));
		so.default = 'http';
		so.value('http', _('HTTP'));
		so.value('h2', _('HTTPUpgrade'));
		so.value('grpc', _('gRPC'));
		so.value('ws', _('WebSocket'));
		so.validate = function(section_id, value) {
			const type = this.section.getOption('type').formvalue(section_id);

			switch (type) {
				case 'vmess':
				case 'vless':
					if (!['http', 'h2', 'grpc', 'ws'].includes(value))
						return _('Expecting: only support %s.').format(_('HTTP') +
							' / ' + _('HTTPUpgrade') +
							' / ' + _('gRPC') +
							' / ' + _('WebSocket'));
					break;
				case 'trojan':
					if (!['grpc', 'ws'].includes(value))
						return _('Expecting: only support %s.').format(_('gRPC') +
							' / ' + _('WebSocket'));
					break;
				default:
					break;
			}

			return true;
		}
		so.depends('transport_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_transport', form.DynamicList, 'transport_hosts', _('Server hostname'));
		so.datatype = 'list(hostname)';
		so.placeholder = 'example.com';
		so.depends({transport_enabled: '1', transport_type: 'h2'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Value, 'transport_http_method', _('HTTP request method'));
		so.value('GET', _('GET'));
		so.value('POST', _('POST'));
		so.value('PUT', _('PUT'));
		so.default = 'GET';
		so.rmempty = false;
		so.depends({transport_enabled: '1', transport_type: 'http'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.DynamicList, 'transport_paths', _('Request path'));
		so.placeholder = '/video';
		so.default = '/';
		so.rmempty = false;
		so.depends({transport_enabled: '1', transport_type: 'http'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Value, 'transport_path', _('Request path'));
		so.placeholder = '/';
		so.default = '/';
		so.rmempty = false;
		so.depends({transport_enabled: '1', transport_type: /^(h2|ws)$/});
		so.modalonly = true;

		so = ss.taboption('field_transport', hm.TextValue, 'transport_http_headers', _('HTTP header'));
		so.placeholder = '{\n  "Host": "example.com",\n  "Connection": [\n    "keep-alive"\n  ]\n}';
		so.validate = L.bind(hm.validateJson, so);
		so.depends({transport_enabled: '1', transport_type: /^(http|ws)$/});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Value, 'transport_grpc_servicename', _('gRPC service name'));
		so.depends({transport_enabled: '1', transport_type: 'grpc'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Value, 'transport_ws_max_early_data', _('Max Early Data'),
			_('Early Data first packet length limit.'));
		so.datatype = 'uinteger';
		so.value('2048');
		so.depends({transport_enabled: '1', transport_type: 'ws'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Value, 'transport_ws_early_data_header', _('Early Data header name'));
		so.value('Sec-WebSocket-Protocol');
		so.depends({transport_enabled: '1', transport_type: 'ws'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Flag, 'transport_ws_v2ray_http_upgrade', _('V2ray HTTPUpgrade'));
		so.default = so.disabled;
		so.depends({transport_enabled: '1', transport_type: 'ws'});
		so.modalonly = true;

		so = ss.taboption('field_transport', form.Flag, 'transport_ws_v2ray_http_upgrade_fast_open', _('V2ray HTTPUpgrade fast open'));
		so.default = so.disabled;
		so.depends({transport_enabled: '1', transport_type: 'ws', transport_ws_v2ray_http_upgrade: '1'});
		so.modalonly = true;

		/* Multiplex fields */ // TCP protocol only
		so = ss.taboption('field_general', form.Flag, 'smux_enabled', _('Multiplex'));
		so.default = so.disabled;
		so.depends({type: /^(vmess|vless|trojan)$/});
		so.depends({type: 'ss', uot: '0'});
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.ListValue, 'smux_protocol', _('Protocol'));
		so.default = 'h2mux';
		so.value('smux', _('smux'));
		so.value('yamux', _('yamux'));
		so.value('h2mux', _('h2mux'));
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Value, 'smux_max_connections', _('Maximum connections'));
		so.datatype = 'uinteger';
		so.placeholder = '4';
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Value, 'smux_min_streams', _('Minimum streams'),
			_('Minimum multiplexed streams in a connection before opening a new connection.'));
		so.datatype = 'uinteger';
		so.placeholder = '4';
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Value, 'smux_max_streams', _('Maximum streams'),
			_('Maximum multiplexed streams in a connection before opening a new connection.<br/>' +
			'Conflict with <code>%s</code> and <code>%s</code>.')
			.format(_('Maximum connections'), _('Minimum streams')));
		so.datatype = 'uinteger';
		so.placeholder = '0';
		so.depends({smux_enabled: '1', smux_max_connections: '', smux_min_streams: ''});
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Flag, 'smux_padding', _('Enable padding'));
		so.default = so.disabled;
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Flag, 'smux_only_tcp', _('TCP only'),
			_('Enable multiplexing only for TCP.'));
		so.default = so.disabled;
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Flag, 'smux_statistic', _('Enable statistic'),
			_('Show connections in the dashboard for breaking connections easier.'));
		so.default = so.disabled;
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Flag, 'smux_brutal', _('Enable TCP Brutal'),
			_('Enable TCP Brutal congestion control algorithm'));
		so.default = so.disabled;
		so.depends('smux_enabled', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Value, 'smux_brutal_up', _('Upload bandwidth'),
			_('Upload bandwidth in Mbps.'));
		so.datatype = 'uinteger';
		so.depends('smux_brutal', '1');
		so.modalonly = true;

		so = ss.taboption('field_multiplex', form.Value, 'smux_brutal_down', _('Download bandwidth'),
			_('Download bandwidth in Mbps.'));
		so.datatype = 'uinteger';
		so.depends('smux_brutal', '1');
		so.modalonly = true;

		/* Dial fields */
		so = ss.taboption('field_dial', form.Flag, 'tfo', _('TFO'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.taboption('field_dial', form.Flag, 'mptcp', _('mpTCP'));
		so.default = so.disabled;
		so.modalonly = true;

		/* Features are implemented in proxy chain
		so = ss.taboption('field_dial', form.Value, 'dialer_proxy', _('dialer-proxy'));
		so.readonly = true;
		so.modalonly = true;
		*/

		so = ss.taboption('field_dial', widgets.DeviceSelect, 'interface_name', _('Bind interface'),
			_('Bind outbound interface.</br>') +
			_('Priority: Proxy Node > Global.'));
		so.multiple = false;
		so.noaliases = true;
		so.modalonly = true;

		so = ss.taboption('field_dial', form.Value, 'routing_mark', _('Routing mark'),
			_('Priority: Proxy Node > Global.'));
		so.datatype = 'uinteger';
		so.modalonly = true;

		so = ss.taboption('field_dial', form.ListValue, 'ip_version', _('IP version'));
		so.default = hm.ip_version[0][0];
		hm.ip_version.forEach((res) => {
			so.value.apply(so, res);
		})
		so.modalonly = true;
		/* Proxy Node END */

		/* Provider START */
		s.tab('provider', _('Provider'));

		/* Provider */
		o = s.taboption('provider', form.SectionValue, '_provider', hm.GridSection, 'provider', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Provider'), _('Add a provider') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = false;
		/* Import mihomo config and Remove idle files start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'proxy-providers:\n' +
							'  provider1:\n' +
							'    type: http\n' +
							'    url: "http://test.com"\n' +
							'    path: ./proxy_providers/provider1.yaml\n' +
							'    interval: 3600\n' +
							'    proxy: DIRECT\n' +
							'    size-limit: 0\n' +
							'    header:\n' +
							'      User-Agent:\n' +
							'      - "Clash/v1.18.0"\n' +
							'      - "mihomo/1.18.3"\n' +
							'      Accept:\n' +
							"      - 'application/vnd.github.v3.raw'\n" +
							'      Authorization:\n' +
							"      - 'token 1231231'\n" +
							'    health-check:\n' +
							'      enable: true\n' +
							'      interval: 600\n' +
							'      timeout: 5000\n' +
							'      lazy: true\n' +
							'      url: https://cp.cloudflare.com/generate_204\n' +
							'      expected-status: 204\n' +
							'    override:\n' +
							'      tfo: false\n' +
							'      mptcp: false\n' +
							'      udp: true\n' +
							'      udp-over-tcp: false\n' +
							'      down: "50 Mbps"\n' +
							'      up: "10 Mbps"\n' +
							'      skip-cert-verify: true\n' +
							'      dialer-proxy: proxy\n' +
							'      interface-name: tailscale0\n' +
							'      routing-mark: 233\n' +
							'      ip-version: ipv4-prefer\n' +
							'      additional-prefix: "[provider1]"\n' +
							'      additional-suffix: "test"\n' +
							'      proxy-name:\n' +
							'        - pattern: "test"\n' +
							'          target: "TEST"\n' +
							'        - pattern: "IPLC-(.*?)倍"\n' +
							'          target: "iplc x $1"\n' +
							'    filter: "(?i)港|hk|hongkong|hong kong"\n' +
							'    exclude-filter: "xxx"\n' +
							'    exclude-type: "ss|http"\n' +
							'  provider2:\n' +
							'    type: inline\n' +
							'    dialer-proxy: proxy\n' +
							'    payload:\n' +
							'      - name: "ss1"\n' +
							'        type: ss\n' +
							'        server: test.server.com\n' +
							'        port: 443\n' +
							'        cipher: chacha20-ietf-poly1305\n' +
							'        password: "password"\n' +
							'  provider3:\n' +
							'    type: http\n' +
							'    url: "http://test.com"\n' +
							'    path: ./proxy_providers/provider3.yaml\n' +
							'    proxy: proxy\n' +
							'  test:\n' +
							'    type: file\n' +
							'    path: /test.yaml\n' +
							'    health-check:\n' +
							'      enable: true\n' +
							'      interval: 36000\n' +
							'      url: https://cp.cloudflare.com/generate_204\n' +
							'  ...'
			o.parseYaml = function(field, name, cfg) {
				let config = hm.HandleImport.prototype.parseYaml.call(this, field, name, cfg);

				return config ? parseProviderYaml.call(this, field, name, config) : null;
			};

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Remove idles'),
				'click': ui.createHandlerFn(this, hm.handleRemoveIdles)
			}, [ _('Remove idles') ]));

			return el;
		}
		/* Import mihomo config and Remove idle files end */

		ss.tab('field_general', _('General fields'));
		ss.tab('field_override', _('Override fields'));
		ss.tab('field_health', _('Health fields'));

		/* General fields */
		so = ss.taboption('field_general', form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.taboption('field_general', form.ListValue, 'type', _('Type'));
		so.value('file', _('Local'));
		so.value('http', _('Remote'));
		so.value('inline', _('Inline'));
		so.default = 'http';

		so = ss.option(form.DummyValue, '_value', _('Value'));
		so.load = function(section_id) {
			const option = uci.get(data[0], section_id, 'type');

			switch (option) {
				case 'file':
					return uci.get(data[0], section_id, '.name');
				case 'http':
					return uci.get(data[0], section_id, 'url');
				case 'inline':
					return uci.get(data[0], section_id, '.name');
				default:
					return null;
			}
		}
		so.modalonly = false;

		so = ss.taboption('field_general', hm.TextValue, '_editer', _('Editer'),
			_('Please type <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/proxy-providers/content/', _('Contents')));
		so.placeholder = _('Content will not be verified, Please make sure you enter it correctly.');
		so.load = function(section_id) {
			return L.resolveDefault(hm.readFile(this.section.sectiontype, section_id), '');
		}
		so.write = L.bind(hm.writeFile, so, so.section.sectiontype);
		so.remove = L.bind(hm.writeFile, so, so.section.sectiontype);
		so.rmempty = false;
		so.retain = true;
		so.depends('type', 'file');
		so.modalonly = true;

		so = ss.taboption('field_general', hm.TextValue, 'payload', 'payload:',
			_('Please type <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/proxy-providers/content/', _('Payload')));
		so.placeholder = '- name: "ss1"\n  type: ss\n  server: server\n  port: 443\n  cipher: chacha20-ietf-poly1305\n  password: "password"\n# ' + _('Content will not be verified, Please make sure you enter it correctly.');
		so.rmempty = false;
		so.depends('type', 'inline');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'url', _('Provider URL'));
		so.validate = L.bind(hm.validateUrl, so);
		so.rmempty = false;
		so.depends('type', 'http');
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'size_limit', _('Size limit'),
			_('In bytes. <code>%s</code> will be used if empty.').format('0'));
		so.placeholder = '0';
		so.validate = L.bind(hm.validateBytesize, so);
		so.depends('type', 'http');

		so = ss.taboption('field_general', form.Value, 'interval', _('Update interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('86400'));
		so.placeholder = '86400';
		so.validate = L.bind(hm.validateTimeDuration, so);
		so.depends('type', 'http');

		so = ss.taboption('field_general', form.ListValue, 'proxy', _('Proxy group'),
			_('Name of the Proxy group to download provider.'));
		so.default = hm.preset_outbound.direct[0][0];
		hm.preset_outbound.direct.forEach((res) => {
			so.value.apply(so, res);
		})
		so.load = L.bind(hm.loadProxyGroupLabel, so, hm.preset_outbound.direct);
		so.textvalue = L.bind(hm.textvalue2Value, so);
		//so.editable = true;
		so.depends('type', 'http');

		so = ss.taboption('field_general', hm.TextValue, 'header', _('HTTP header'),
			_('Custom HTTP header.'));
		so.placeholder = '{\n  "User-Agent": [\n    "Clash/v1.18.0",\n    "mihomo/1.18.3"\n  ],\n  "Accept": [\n    //"application/vnd.github.v3.raw"\n  ],\n  "Authorization": [\n    //"token 1231231"\n  ]\n}';
		so.validate = L.bind(hm.validateJson, so);
		so.depends('type', 'http');
		so.modalonly = true;

		/* Override fields */
		// https://github.com/muink/mihomo/blob/43f21c0b412b7a8701fe7a2ea6510c5b985a53d6/adapter/provider/parser.go#L30

		so = ss.taboption('field_override', form.Value, 'override_prefix', _('Add prefix'));
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Value, 'override_suffix', _('Add suffix'));
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.DynamicList, 'override_replace', _('Replace name'),
			_('Replace node name. ') +
			_('For format see <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/proxy-providers/#overrideproxy-name', _('override.proxy-name')));
		so.placeholder = '{"pattern": "IPLC-(.*?)倍", "target": "iplc x $1"}';
		so.validate = L.bind(hm.validateJson, so);
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.DummyValue, '_config_items', null);
		so.load = function() {
			return '<a target="_blank" href="%s" rel="noreferrer noopener">%s</a>'
				.format('https://wiki.metacubex.one/config/proxy-providers/#_2', _('Configuration Items'));
		}
		so.rawhtml = true;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Flag, 'override_tfo', _('TFO'));
		so.default = so.disabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Flag, 'override_mptcp', _('mpTCP'));
		so.default = so.disabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Flag, 'override_udp', _('UDP'));
		so.default = so.enabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Flag, 'override_uot', _('UoT'),
			_('Enable the SUoT protocol, requires server support. Conflict with Multiplex.'));
		so.default = so.disabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Value, 'override_up', _('up'),
			_('In Mbps.'));
		so.datatype = 'uinteger';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Value, 'override_down', _('down'),
			_('In Mbps.'));
		so.datatype = 'uinteger';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Flag, 'override_skip_cert_verify', _('Skip cert verify'),
			_('Donot verifying server certificate.') +
			'<br/>' +
			_('This is <strong>DANGEROUS</strong>, your traffic is almost like <strong>PLAIN TEXT</strong>! Use at your own risk!'));
		so.default = so.disabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		/* Features are implemented in proxy chain
		so = ss.taboption('field_override', form.Value, 'override_dialer_proxy', _('dialer-proxy'));
		so.readonly = true;
		so.modalonly = true;
		*/

		so = ss.taboption('field_override', widgets.DeviceSelect, 'override_interface_name', _('Bind interface'),
			_('Bind outbound interface.</br>') +
			_('Priority: Proxy Node > Global.'));
		so.multiple = false;
		so.noaliases = true;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.Value, 'override_routing_mark', _('Routing mark'),
			_('Priority: Proxy Node > Global.'));
		so.datatype = 'uinteger';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_override', form.ListValue, 'override_ip_version', _('IP version'));
		so.default = hm.ip_version[0][0];
		hm.ip_version.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		/* Health fields */
		so = ss.taboption('field_health', form.Flag, 'health_enable', _('Enable'));
		so.default = so.enabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'health_url', _('Health check URL'));
		so.default = hm.health_checkurls[0][0];
		hm.health_checkurls.forEach((res) => {
			so.value.apply(so, res);
		})
		so.validate = L.bind(hm.validateUrl, so);
		so.retain = true;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'health_interval', _('Health check interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('600'));
		so.placeholder = '600';
		so.validate = L.bind(hm.validateTimeDuration, so);
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'health_timeout', _('Health check timeout'),
			_('In millisecond. <code>%s</code> will be used if empty.').format('5000'));
		so.datatype = 'uinteger';
		so.placeholder = '5000';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Flag, 'health_lazy', _('Lazy'),
			_('No testing is performed when this provider node is not in use.'));
		so.default = so.enabled;
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'health_expected_status', _('Health check expected status'),
			_('Expected HTTP code. <code>204</code> will be used if empty. ') +
			_('For format see <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/proxy-groups/#expected-status', _('Expected status')));
		so.placeholder = '200/302/400-503';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		/* General fields */
		so = ss.taboption('field_general', form.DynamicList, 'filter', _('Node filter'),
			_('Filter nodes that meet keywords or regexps.'));
		so.placeholder = '(?i)港|hk|hongkong|hong kong';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'exclude_filter', _('Node exclude filter'),
			_('Exclude nodes that meet keywords or regexps.'));
		so.default = '重置|到期|过期|剩余|套餐 海外用户|回国'
		so.placeholder = 'xxx';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'exclude_type', _('Node exclude type'),
			_('Exclude matched node types.'));
		so.placeholder = 'ss|http';
		so.depends({type: 'inline', '!reverse': true});
		so.modalonly = true;

		so = ss.option(form.DummyValue, '_update');
		so.cfgvalue = L.bind(hm.renderResDownload, so);
		so.editable = true;
		so.modalonly = false;
		/* Provider END */

		/* Proxy chain START */
		s.tab('dialer_proxy', _('Proxy chain'));

		/* Proxy chain */
		o = s.taboption('dialer_proxy', form.SectionValue, '_dialer_proxy', hm.GridSection, 'dialer_proxy', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Proxy chain'), _('Add a proxy chain') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = true;

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.ListValue, 'type', _('Type'));
		so.value('node', _('Proxy Node'));
		so.value('provider', _('Provider'));
		so.default = 'node';
		so.textvalue = L.bind(hm.textvalue2Value, so);

		so = ss.option(form.DummyValue, '_value', _('Value'));
		so.load = function(section_id) {
			const type = uci.get(data[0], section_id, 'type');
			const detour = uci.get(data[0], section_id, 'chain_tail_group') || uci.get(data[0], section_id, 'chain_tail');

			switch (type) {
				case 'node':
					return '%s » %s'.format(
						uci.get(data[0], section_id, 'chain_head'),
						detour
					);
				case 'provider':
					return '%s » %s'.format(
						uci.get(data[0], section_id, 'chain_head_sub'),
						detour
					);
				default:
					return null;
			}
		}
		so.modalonly = false;

		so = ss.option(form.ListValue, 'chain_head_sub', _('Chain head'));
		so.load = L.bind(hm.loadProviderLabel, so, [['', _('-- Please choose --')]]);
		so.rmempty = false;
		so.depends('type', 'provider');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'chain_head', _('Chain head'),
			_('Recommended to use UoT node.</br>such as <code>%s</code>.')
			.format('ss|ssr|vmess|vless|trojan|tuic'));
		so.load = L.bind(hm.loadNodeLabel, so, [['', _('-- Please choose --')]]);
		so.rmempty = false;
		so.validate = function(section_id, value) {
			const chain_tail = this.section.getUIElement(section_id, 'chain_tail').getValue();

			if (value === chain_tail)
				return _('Expecting: %s').format(_('Different chain head/tail'));

			return true;
		}
		so.depends('type', 'node');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'chain_tail_group', _('Chain tail'));
		so.load = L.bind(hm.loadProxyGroupLabel, so, [['', _('-- Please choose --')]]);
		so.rmempty = false;
		so.depends({chain_tail: /.+/, '!reverse': true});
		so.modalonly = true;

		so = ss.option(form.ListValue, 'chain_tail', _('Chain tail'),
			_('Recommended to use UoT node.</br>such as <code>%s</code>.')
			.format('ss|ssr|vmess|vless|trojan|tuic'));
		so.load = L.bind(hm.loadNodeLabel, so, [['', _('-- Please choose --')]]);
		so.rmempty = false;
		so.validate = function(section_id, value) {
			const chain_head = this.section.getUIElement(section_id, 'chain_head').getValue();

			if (value === chain_head)
				return _('Expecting: %s').format(_('Different chain head/tail'));

			return true;
		}
		so.depends({chain_tail_group: /.+/, '!reverse': true});
		so.modalonly = true;
		/* Proxy chain END */

		return m.render();
	}
});
