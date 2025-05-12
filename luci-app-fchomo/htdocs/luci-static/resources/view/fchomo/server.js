'use strict';
'require form';
'require poll';
'require uci';
'require ui';
'require view';

'require fchomo as hm';

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo'),
			hm.getFeatures()
		]);
	},

	render(data) {
		const dashboard_repo = uci.get(data[0], 'api', 'dashboard_repo');
		const features = data[1];

		let m, s, o;

		m = new form.Map('fchomo', _('Mihomo server'),
			_('When used as a server, HomeProxy is a better choice.'));

		s = m.section(form.TypedSection);
		s.render = function () {
			poll.add(function() {
				return hm.getServiceStatus('mihomo-s').then((isRunning) => {
					hm.updateStatus(document.getElementById('_server_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-s', true);
				});
			});

			return E('div', { class: 'cbi-section' }, [
				E('p', [
					hm.renderStatus('_server_bar', false, 'mihomo-s', true)
				])
			]);
		}

		s = m.section(form.NamedSection, 'routing', 'fchomo', null);

		/* Server switch */
		o = s.option(form.Button, '_reload_server', _('Quick Reload'));
		o.inputtitle = _('Reload');
		o.inputstyle = 'apply';
		o.onclick = L.bind(hm.handleReload, o, 'mihomo-s');

		o = s.option(form.Flag, 'server_enabled', _('Enable'));
		o.default = o.disabled;

		o = s.option(form.Flag, 'server_auto_firewall', _('Auto configure firewall'));
		o.default = o.disabled;

		/* Server settings START */
		s = m.section(hm.GridSection, 'server', null);
		s.addremove = true;
		s.rowcolors = true;
		s.sortable = true;
		s.nodescriptions = true;
		s.hm_modaltitle = [ _('Server'), _('Add a server') ];
		s.hm_prefmt = hm.glossary[s.sectiontype].prefmt;
		s.hm_field  = hm.glossary[s.sectiontype].field;
		s.hm_lowcase_only = false;

		s.tab('field_general', _('General fields'));
		s.tab('field_tls', _('TLS fields'));
		s.tab('field_transport', _('Transport fields'));
		s.tab('field_multiplex', _('Multiplex fields'));
		s.tab('field_listen', _('Listen fields'));

		/* General fields */
		o = s.taboption('field_general', form.Value, 'label', _('Label'));
		o.load = L.bind(hm.loadDefaultLabel, o);
		o.validate = L.bind(hm.validateUniqueValue, o);
		o.modalonly = true;

		o = s.taboption('field_general', form.Flag, 'enabled', _('Enable'));
		o.default = o.enabled;
		o.editable = true;

		o = s.taboption('field_general', form.ListValue, 'type', _('Type'));
		o.default = hm.inbound_type[0][0];
		hm.inbound_type.forEach((res) => {
			o.value.apply(o, res);
		})

		o = s.taboption('field_general', form.Value, 'listen', _('Listen address'));
		o.datatype = 'ipaddr';
		o.placeholder = '::';
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'port', _('Listen port') + ' / ' + _('Ports pool'));
		o.datatype = 'or(port, portrange)';
		//o.placeholder = '1080,2079-2080,3080'; // Incompatible with firewall
		o.rmempty = false;
		//o.validate = L.bind(hm.validateCommonPort, o); // Incompatible with firewall

		// dev: Features under development
		// rule
		// proxy

		/* HTTP / SOCKS fields */
		/* hm.validateAuth */
		o = s.taboption('field_general', form.Value, 'username', _('Username'));
		o.validate = L.bind(hm.validateAuthUsername, o);
		o.depends({type: /^(http|socks|mixed|trojan|anytls|hysteria2)$/});
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'password', _('Password'));
		o.password = true;
		o.validate = L.bind(hm.validateAuthPassword, o);
		o.rmempty = false;
		o.depends({type: /^(http|socks|mixed|trojan|anytls|hysteria2)$/, username: /.+/});
		o.depends({type: /^(tuic)$/, uuid: /.+/});
		o.modalonly = true;

		/* Hysteria2 fields */
		o = s.taboption('field_general', form.Value, 'hysteria_up_mbps', _('Max upload speed'),
			_('In Mbps.'));
		o.datatype = 'uinteger';
		o.depends('type', 'hysteria2');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'hysteria_down_mbps', _('Max download speed'),
			_('In Mbps.'));
		o.datatype = 'uinteger';
		o.depends('type', 'hysteria2');
		o.modalonly = true;

		o = s.taboption('field_general', form.Flag, 'hysteria_ignore_client_bandwidth', _('Ignore client bandwidth'),
			_('Tell the client to use the BBR flow control algorithm instead of Hysteria CC.'));
		o.default = o.disabled;
		o.depends({type: 'hysteria2', hysteria_up_mbps: '', hysteria_down_mbps: ''});
		o.modalonly = true;

		o = s.taboption('field_general', form.ListValue, 'hysteria_obfs_type', _('Obfuscate type'));
		o.value('', _('Disable'));
		o.value('salamander', _('Salamander'));
		o.depends('type', 'hysteria2');
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'hysteria_obfs_password', _('Obfuscate password'),
			_('Enabling obfuscation will make the server incompatible with standard QUIC connections, losing the ability to masquerade with HTTP/3.'));
		o.password = true;
		o.rmempty = false;
		o.depends('type', 'hysteria');
		o.depends({type: 'hysteria2', hysteria_obfs_type: /.+/});
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'hysteria_masquerade', _('Masquerade'),
			_('HTTP3 server behavior when authentication fails.<br/>A 404 page will be returned if empty.'));
		o.placeholder = 'file:///var/www or http://127.0.0.1:8080'
		o.depends('type', 'hysteria2');
		o.modalonly = true;

		/* Shadowsocks fields */
		o = s.taboption('field_general', form.ListValue, 'shadowsocks_chipher', _('Chipher'));
		o.default = hm.shadowsocks_cipher_methods[1][0];
		hm.shadowsocks_cipher_methods.forEach((res) => {
			o.value.apply(o, res);
		})
		o.depends('type', 'shadowsocks');
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'shadowsocks_password', _('Password'));
		o.password = true;
		o.validate = function(section_id, value) {
			const encmode = this.section.getOption('shadowsocks_chipher').formvalue(section_id);
			return hm.validateShadowsocksPassword.call(this, encmode, section_id, value);
		}
		o.depends({type: 'shadowsocks', shadowsocks_chipher: /.+/});
		o.modalonly = true;

		/* Tuic fields */
		o = s.taboption('field_general', hm.GenValue, 'uuid', _('UUID'));
		o.rmempty = false;
		o.validate = L.bind(hm.validateUUID, o);
		o.depends('type', 'tuic');
		o.modalonly = true;

		o = s.taboption('field_general', form.ListValue, 'tuic_congestion_controller', _('Congestion controller'),
			_('QUIC congestion controller.'));
		o.default = 'cubic';
		o.value('cubic', _('cubic'));
		o.value('new_reno', _('new_reno'));
		o.value('bbr', _('bbr'));
		o.depends('type', 'tuic');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'tuic_max_udp_relay_packet_size', _('Max UDP relay packet size'));
		o.datatype = 'uinteger';
		o.default = '1500';
		o.depends('type', 'tuic');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'tuic_max_idle_time', _('Idle timeout'),
			_('In seconds.'));
		o.default = '15000';
		o.validate = L.bind(hm.validateTimeDuration, o);
		o.depends('type', 'tuic');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'tuic_authentication_timeout', _('Auth timeout'),
			_('In seconds.'));
		o.default = '1000';
		o.validate = L.bind(hm.validateTimeDuration, o);
		o.depends('type', 'tuic');
		o.modalonly = true;

		/* Trojan fields */
		o = s.taboption('field_general', form.Flag, 'trojan_ss_enabled', _('Shadowsocks encrypt'));
		o.default = o.disabled;
		o.depends('type', 'trojan');
		o.modalonly = true;

		o = s.taboption('field_general', form.ListValue, 'trojan_ss_chipher', _('Shadowsocks chipher'));
		o.default = hm.trojan_cipher_methods[0][0];
		hm.trojan_cipher_methods.forEach((res) => {
			o.value.apply(o, res);
		})
		o.depends({type: 'trojan', trojan_ss_enabled: '1'});
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'trojan_ss_password', _('Shadowsocks password'));
		o.password = true;
		o.validate = function(section_id, value) {
			const encmode = this.section.getOption('trojan_ss_chipher').formvalue(section_id);
			return hm.validateShadowsocksPassword.call(this, encmode, section_id, value);
		}
		o.depends({type: 'trojan', trojan_ss_enabled: '1'});
		o.modalonly = true;

		/* AnyTLS fields */
		o = s.taboption('field_general', form.TextValue, 'anytls_padding_scheme', _('Padding scheme'));
		o.depends('type', 'anytls');
		o.modalonly = true;

		/* VMess / VLESS fields */
		o = s.taboption('field_general', hm.GenValue, 'vmess_uuid', _('UUID'));
		o.rmempty = false;
		o.validate = L.bind(hm.validateUUID, o);
		o.depends({type: /^(vmess|vless)$/});
		o.modalonly = true;

		o = s.taboption('field_general', form.ListValue, 'vless_flow', _('Flow'));
		o.default = hm.vless_flow[0][0];
		hm.vless_flow.forEach((res) => {
			o.value.apply(o, res);
		})
		o.depends('type', 'vless');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'vmess_alterid', _('Alter ID'),
			_('Legacy protocol support (VMess MD5 Authentication) is provided for compatibility purposes only, use of alterId > 1 is not recommended.'));
		o.datatype = 'uinteger';
		o.placeholder = '0';
		o.depends('type', 'vmess');
		o.modalonly = true;

		/* Plugin fields */
		o = s.taboption('field_general', form.ListValue, 'plugin', _('Plugin'));
		o.value('', _('none'));
		o.value('shadow-tls', _('shadow-tls'));
		o.depends('type', 'shadowsocks');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'plugin_opts_handshake_dest', _('Plugin: ') + _('Handshake target that supports TLS 1.3'));
		o.datatype = 'hostport';
		o.placeholder = 'cloud.tencent.com:443';
		o.rmempty = false;
		o.depends({plugin: 'shadow-tls'});
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'plugin_opts_thetlspassword', _('Plugin: ') + _('Password'));
		o.password = true;
		o.rmempty = false;
		o.depends({plugin: 'shadow-tls'});
		o.modalonly = true;

		o = s.taboption('field_general', form.ListValue, 'plugin_opts_shadowtls_version', _('Plugin: ') + _('Version'));
		o.value('1', _('v1'));
		o.value('2', _('v2'));
		o.value('3', _('v3'));
		o.default = '3';
		o.depends({plugin: 'shadow-tls'});
		o.modalonly = true;

		/* Extra fields */
		o = s.taboption('field_general', form.Flag, 'udp', _('UDP'));
		o.default = o.disabled;
		o.depends({type: /^(socks|mixed|shadowsocks)$/});
		o.modalonly = true;

		/* TLS fields */
		o = s.taboption('field_general', form.Flag, 'tls', _('TLS'));
		o.default = o.disabled;
		o.validate = function(section_id, value) {
			const type = this.section.getOption('type').formvalue(section_id);
			let tls = this.section.getUIElement(section_id, 'tls').node.querySelector('input');
			let tls_alpn = this.section.getUIElement(section_id, 'tls_alpn');
			let tls_reality = this.section.getUIElement(section_id, 'tls_reality').node.querySelector('input');

			// Force enabled
			if (['vless', 'trojan', 'anytls', 'tuic', 'hysteria2'].includes(type)) {
				tls.checked = true;
				tls.disabled = true;
				if (['tuic', 'hysteria2'].includes(type) && !`${tls_alpn.getValue()}`)
					tls_alpn.setValue('h3');
			} else {
				tls.disabled = null;
			}

			// Force disabled
			if (!['vmess', 'vless', 'trojan'].includes(type)) {
				tls_reality.checked = null;
				tls_reality.disabled = true;
			} else {
				tls_reality.disabled = null;
			}

			return true;
		}
		o.depends({type: /^(http|socks|mixed|vmess|vless|trojan|anytls|tuic|hysteria2)$/});
		o.modalonly = true;

		o = s.taboption('field_tls', form.DynamicList, 'tls_alpn', _('TLS ALPN'),
			_('List of supported application level protocols, in order of preference.'));
		o.depends('tls', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_cert_path', _('Certificate path'),
			_('The server public key, in PEM format.'));
		o.value('/etc/fchomo/certs/server_publickey.pem');
		o.depends({tls: '1', tls_reality: '0'});
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('field_tls', form.Button, '_upload_cert', _('Upload certificate'),
			_('<strong>Save your configuration before uploading files!</strong>'));
		o.inputstyle = 'action';
		o.inputtitle = _('Upload...');
		o.depends({tls: '1', tls_cert_path: '/etc/fchomo/certs/server_publickey.pem'});
		o.onclick = L.bind(hm.uploadCertificate, o, _('certificate'), 'server_publickey');
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_key_path', _('Key path'),
			_('The server private key, in PEM format.'));
		o.value('/etc/fchomo/certs/server_privatekey.pem');
		o.rmempty = false;
		o.depends({tls: '1', tls_cert_path: /.+/});
		o.modalonly = true;

		o = s.taboption('field_tls', form.Button, '_upload_key', _('Upload key'),
			_('<strong>Save your configuration before uploading files!</strong>'));
		o.inputstyle = 'action';
		o.inputtitle = _('Upload...');
		o.depends({tls: '1', tls_key_path: '/etc/fchomo/certs/server_privatekey.pem'});
		o.onclick = L.bind(hm.uploadCertificate, o, _('private key'), 'server_privatekey');
		o.modalonly = true;

		// uTLS fields
		o = s.taboption('field_tls', form.Flag, 'tls_reality', _('REALITY'));
		o.default = o.disabled;
		o.depends('tls', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_reality_dest', _('REALITY handshake server'));
		o.datatype = 'hostport';
		o.placeholder = 'cloud.tencent.com:443';
		o.rmempty = false;
		o.depends('tls_reality', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', hm.GenValue, 'tls_reality_private_key', _('REALITY private key'));
		const tls_reality_public_key = 'tls_reality_public_key';
		o.hm_asymmetric = {
			type: 'reality-keypair',
			result: {
				private_key: o.option,
				public_key: tls_reality_public_key
			}
		};
		o.password = true;
		o.rmempty = false;
		o.depends('tls_reality', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, tls_reality_public_key, _('REALITY public key'));
		o.depends('tls_reality', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.DynamicList, 'tls_reality_short_id', _('REALITY short ID'));
		//o.value('', '""');
		o.rmempty = false;
		o.depends('tls_reality', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.DynamicList, 'tls_reality_server_names', _('REALITY certificate issued to'));
		o.datatype = 'list(hostname)';
		o.placeholder = 'cloud.tencent.com';
		o.rmempty = false;
		o.depends('tls_reality', '1');
		o.modalonly = true;

		/* Transport fields */
		o = s.taboption('field_general', form.Flag, 'transport_enabled', _('Transport'));
		o.default = o.disabled;
		o.depends({type: /^(vmess|vless|trojan)$/});
		o.modalonly = true;

		o = s.taboption('field_transport', form.ListValue, 'transport_type', _('Transport type'));
		o.value('grpc', _('gRPC'));
		o.value('ws', _('WebSocket'));
		o.validate = function(section_id, value) {
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
		o.depends('transport_enabled', '1');
		o.modalonly = true;

		o = s.taboption('field_transport', form.Value, 'transport_path', _('Request path'));
		o.placeholder = '/';
		o.default = '/';
		o.rmempty = false;
		o.depends({transport_enabled: '1', transport_type: 'ws'});
		o.modalonly = true;

		o = s.taboption('field_transport', form.Value, 'transport_grpc_servicename', _('gRPC service name'));
		o.placeholder = 'GunService';
		o.rmempty = false;
		o.depends({transport_enabled: '1', transport_type: 'grpc'});
		o.modalonly = true;
		/* Server settings END */

		return m.render();
	}
});
