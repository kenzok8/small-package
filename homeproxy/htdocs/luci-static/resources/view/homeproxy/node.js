/*
 * SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2022 ImmortalWrt.org
 */

'use strict';
'require form';
'require fs';
'require uci';
'require ui';
'require view';

'require homeproxy as hp';
'require tools.widgets as widgets';

function allowInsecureConfirm(ev, section_id, value) {
	if (value === '1' && !confirm(_('Are you sure to allow insecure?')))
		ev.target.firstElementChild.checked = null;
}

function parseShareLink(uri, features) {
	var config;

	uri = uri.split('://');
	if (uri[0] && uri[1]) {
		switch (uri[0]) {
		case 'hysteria':
			/* https://github.com/HyNetwork/hysteria/wiki/URI-Scheme */
			var url = new URL('http://' + uri[1]);
			var params = url.searchParams;

			/* WeChat-Video / FakeTCP are unsupported by sing-box currently */
			if (!features.with_quic || (params.get('protocol') && params.get('protocol') !== 'udp'))
				return null;

			config = {
				label: url.hash ? decodeURIComponent(url.hash.slice(1)) : null,
				type: 'hysteria',
				address: url.hostname,
				port: url.port || '80',
				hysteria_protocol: params.get('protocol') || 'udp',
				hysteria_auth_type: params.get('auth') ? 'string' : null,
				hysteria_auth_payload: params.get('auth'),
				hysteria_obfs_password: params.get('obfsParam'),
				hysteria_down_mbps: params.get('downmbps'),
				hysteria_up_mbps: params.get('upmbps'),
				tls: '1',
				tls_sni: params.get('peer'),
				tls_alpn: params.get('alpn'),
				tls_insecure: params.get('insecure') ? '1' : '0'
			}

			break;
		case 'ss':
			try {
				/* "Lovely" Shadowrocket format */
				try {
					var suri = uri[1].split('#'), slabel = '';
					if (suri.length <= 2) {
						if (suri.length === 2)
							slabel = '#' + suri[1];
						uri[1] = hp.decodeBase64Str(suri[0]) + slabel;
					}
				} catch(e) { }

				/* SIP002 format https://shadowsocks.org/guide/sip002.html */
				var url = new URL('http://' + uri[1]);

				var userinfo;
				if (url.username && url.password)
					/* User info encoded with URIComponent */
					userinfo = [url.username, decodeURIComponent(url.password)];
				else if (url.username)
					/* User info encoded with base64 */
					userinfo = hp.decodeBase64Str(decodeURIComponent(url.username)).split(':');

				if (!hp.shadowsocks_encrypt_methods.includes(userinfo[0]))
					return null;

				var plugin, plugin_opts;
				if (url.search && url.searchParams.get('plugin')) {
					var plugin_info = url.searchParams.get('plugin').split(';');
					plugin = plugin_info[0];
					plugin_opts = plugin_info.slice(1) ? plugin_info.slice(1).join(';') : null;
				}

				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : null,
					type: 'shadowsocks',
					address: url.hostname,
					port: url.port || '80',
					shadowsocks_encrypt_method: userinfo[0],
					password: userinfo[1],
					shadowsocks_plugin: plugin,
					shadowsocks_plugin_opts: plugin_opts
				};
			} catch(e) {
				/* Legacy format https://github.com/shadowsocks/shadowsocks-org/commit/78ca46cd6859a4e9475953ed34a2d301454f579e */
				uri = uri[1].split('@');
				if (uri.length < 2)
					return null;
				else if (uri.length > 2)
					uri = [ uri.slice(0, -1).join('@'), uri.slice(-1).toString() ];

				config = {
					type: 'shadowsocks',
					address: uri[1].split(':')[0],
					port: uri[1].split(':')[1],
					shadowsocks_encrypt_method: uri[0].split(':')[0],
					password: uri[0].split(':').slice(1).join(':')
				};
			}

			break;
		case 'ssr':
			/* https://coderschool.cn/2498.html */
			uri = hp.decodeBase64Str(uri[1]).split('/');
			var userinfo = uri[0].split(':')

			/* Check if method and password exist */
			if (!features.with_shadowsocksr || !userinfo[3] || !userinfo[5])
				return null;

			var params = new URLSearchParams(uri[1]);
			var protoparam = hp.decodeBase64Str(params.get('protoparam'));
			var obfsparam = hp.decodeBase64Str(params.get('obfsparam'));
			var remarks = hp.decodeBase64Str(params.get('remarks'));

			config = {
				label: remarks,
				type: 'shadowsocksr',
				address: userinfo[0],
				port: userinfo[1],
				shadowsocksr_encrypt_method: userinfo[3],
				password: hp.decodeBase64Str(userinfo[5]),
				shadowsocksr_protocol: userinfo[2],
				shadowsocksr_protocol_param: protoparam,
				shadowsocksr_obfs: userinfo[4],
				shadowsocksr_obfs_param: obfsparam
			};

			break;
		case 'trojan':
			/* https://p4gefau1t.github.io/trojan-go/developer/url/ */
			var url = new URL('http://' + uri[1]);

			/* Check if password exists */
			if (!url.username)
				return null;

			config = {
				label: url.hash ? decodeURIComponent(url.hash.slice(1)) : null,
				type: 'trojan',
				address: url.hostname,
				port: url.port || '80',
				password: decodeURIComponent(url.username),
				tls: '1',
				tls_sni: url.searchParams.get('sni')
			};

			break;
		case 'vless':
			/* https://github.com/XTLS/Xray-core/discussions/716 */
			var url = new URL('http://' + uri[1]);
			var params = url.searchParams;

			/* Unsupported protocol */
			if (params.get('type') === 'kcp')
				return null;
			else if (params.get('type') === 'quic' && ((params.get('quicSecurity') && params.get('quicSecurity') !== 'none' || !features.with_quic)))
				return null;
			/* Check if uuid and type exist */
			if (!url.username || !params.get('type'))
				return null;

			config = {
				label: url.hash ? decodeURIComponent(url.hash.slice(1)) : null,
				type: 'vless',
				address: url.hostname,
				port: url.port || '80',
				uuid: url.username,
				transport: params.get('type') !== 'tcp' ? params.get('type') : null,
				tls: params.get('security') ? '1' : '0',
				tls_sni: params.get('sni'),
				tls_alpn: params.get('alpn') ? decodeURIComponent(params.get('alpn')).split(',') : null,
				tls_utls: features.with_utls ? params.get('fp') : null
			};
			switch (params.get('type')) {
			case 'grpc':
				config.grpc_servicename = params.get('serviceName');
				break;
			case 'http':
			case 'tcp':
				if (config.transport === 'http' || params.get('headerType') === 'http') {
					config.http_host = params.get('host') ? decodeURIComponent(params.get('host')).split(',') : null;
					config.http_path = params.get('path') ? decodeURIComponent(params.get('path')) : null;
				}
				break;
			case 'ws':
				config.ws_host = (config.tls !== '1' && params.get('host')) ? decodeURIComponent(params.get('host')) : null;
				config.ws_path = params.get('path') ? decodeURIComponent(params.get('path')) : null;
				if (config.ws_path && config.ws_path.includes('?ed=')) {
					config.websocket_early_data_header = 'Sec-WebSocket-Protocol';
					config.websocket_early_data = config.ws_path.split('?ed=')[1];
					config.ws_path = config.ws_path.split('?ed=')[0];
				}
				break;
			}

			break;
		case 'vmess':
			/* "Lovely" shadowrocket format */
			if (uri.includes('&'))
				return null;

			/* https://github.com/2dust/v2rayN/wiki/%E5%88%86%E4%BA%AB%E9%93%BE%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AF%B4%E6%98%8E(ver-2) */
			uri = JSON.parse(hp.decodeBase64Str(uri[1]));

			if (uri.v !== '2')
				return null;
			/* Unsupported protocols */
			else if (uri.net === 'kcp')
				return null;
			else if (uri.net === 'quic' && ((uri.type && uri.type !== 'none') || !features.with_quic))
				return null;
			/* https://www.v2fly.org/config/protocols/vmess.html#vmess-md5-%E8%AE%A4%E8%AF%81%E4%BF%A1%E6%81%AF-%E6%B7%98%E6%B1%B0%E6%9C%BA%E5%88%B6
			 * else if (uri.aid && parseInt(uri.aid) !== 0)
			 * 	return null;
			 */

			config = {
				label: uri.ps,
				type: 'vmess',
				address: uri.add,
				port: uri.port,
				uuid: uri.id,
				vmess_alterid: uri.aid,
				vmess_encrypt: uri.scy || 'auto',
				transport: (uri.net !== 'tcp') ? uri.net : null,
				tls: uri.tls === 'tls' ? '1' : '0',
				tls_sni: uri.sni || uri.host,
				tls_alpn: uri.alpn ? uri.alpn.split(',') : null
			};
			switch (uri.net) {
			case 'grpc':
				config.grpc_servicename = uri.path;
				break;
			case 'h2':
			case 'tcp':
				if (uri.net === 'h2' || uri.type === 'http') {
					config.transport = 'http';
					config.http_host = uri.host ? uri.host.split(',') : null;
					config.http_path = uri.path;
				}
				break;
			case 'ws':
				config.ws_host = (config.tls !== '1') ? uri.host : null;
				config.ws_path = uri.path;
				if (config.ws_path && config.ws_path.includes('?ed=')) {
					config.websocket_early_data_header = 'Sec-WebSocket-Protocol';
					config.websocket_early_data = config.ws_path.split('?ed=')[1];
					config.ws_path = config.ws_path.split('?ed=')[0];
				}
				break;
			}

			break;
		}
	}

	if (config) {
		if (!config.address || !config.port)
			return null;
		else if (!config.label)
			config.label = config.address + ':' + config.port;

		config.address = config.address.replace(/\[|\]/g, '');
	}

	return config;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('homeproxy'),
			hp.getBuiltinFeatures()
		]);
	},

	render: function(data) {
		var m, s, o, ss, so;
		var main_node = uci.get(data[0], 'config', 'main_node');
		var routing_mode = uci.get(data[0], 'config', 'routing_mode');
		var features = data[1];

		m = new form.Map('homeproxy', _('Edit nodes'));

		s = m.section(form.NamedSection, 'subscription', 'homeproxy');

		/* Nodes settings start */
		s.tab('node', _('Nodes'));

		o = s.taboption('node', form.SectionValue, '_node', form.GridSection, 'node');
		ss = o.subsection;
		ss.addremove = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hp.loadModalTitle, this, _('Node'), _('Add a node'), data[0]);
		ss.sectiontitle = L.bind(hp.loadDefaultLabel, this, data[0]);
		/* Import subscription links start */
		/* Thanks to luci-app-shadowsocks-libev */
		ss.handleLinkImport = function() {
			var textarea = new ui.Textarea();
			ui.showModal(_('Import share links'), [
				E('p', _('Support Hysteria, Shadowsocks(R), Trojan, v2rayN (VMess), and XTLS (VLESS) online configuration delivery standard.')),
				textarea.render(),
				E('div', { class: 'right' }, [
					E('button', {
						class: 'btn',
						click: ui.hideModal
					}, [ _('Cancel') ]),
					'',
					E('button', {
						class: 'btn cbi-button-action',
						click: ui.createHandlerFn(this, function() {
							var input_links = textarea.getValue().trim().split('\n');
							if (input_links && input_links[0]) {
								/* Remove duplicate lines */
								input_links = input_links.reduce((pre, cur) =>
									(!pre.includes(cur) && pre.push(cur), pre), []);

								var allow_insecure = uci.get(data[0], 'subscription', 'allow_insecure');
								var packet_encoding = uci.get(data[0], 'subscription', 'packet_encoding');
								var imported_node = 0;
								input_links.forEach((l) => {
									var config = parseShareLink(l, features);
									if (config) {
										if (config.tls === '1' && allow_insecure === '1')
											config.tls_insecure = '1'
										if (['vless', 'vmess'].includes(config.type))
											config.packet_encoding = packet_encoding

										var nameHash = hp.calcStringMD5(config.label);
										var sid = uci.add(data[0], 'node', nameHash);
										Object.keys(config).forEach((k) => {
											uci.set(data[0], sid, k, config[k]);
										});
										imported_node++;
									}
								});

								if (imported_node === 0)
									ui.addNotification(null, E('p', _('No valid share link found.')));
								else
									ui.addNotification(null, E('p', _('Successfully imported %s nodes of total %s.').format(
										imported_node, input_links.length)));

								return uci.save()
									.then(L.bind(this.map.load, this.map))
									.then(L.bind(this.map.reset, this.map))
									.then(L.ui.hideModal)
									.catch(function() {});
							} else
								return ui.hideModal();
						})
					}, [ _('Import') ])
				])
			])
		}
		ss.renderSectionAdd = function(extra_class) {
			var el = form.GridSection.prototype.renderSectionAdd.apply(this, arguments),
				nameEl = el.querySelector('.cbi-section-create-name');

			ui.addValidator(nameEl, 'uciname', true, (v) => {
				var button = el.querySelector('.cbi-section-create > .cbi-button-add');
				var uciconfig = this.uciconfig || this.map.config;

				if (!v) {
					button.disabled = true;
					return true;
				} else if (uci.get(uciconfig, v)) {
					button.disabled = true;
					return _('Expecting: %s').format(_('unique UCI identifier'));
				} else {
					button.disabled = null;
					return true;
				}
			}, 'blur', 'keyup');

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Import share links'),
				'click': ui.createHandlerFn(this, 'handleLinkImport')
			}, [ _('Import share links') ]));

			return el;
		}
		/* Import subscription links end */

		if (routing_mode !== 'custom') {
			so = ss.option(form.Button, '_apply', _('Apply'));
			so.editable = true;
			so.modalonly = false;
			so.inputstyle = 'apply';
			so.inputtitle = function(section_id) {
				if (main_node == section_id) {
					this.readonly = true;
					return _('Applied');
				} else {
					this.readonly = false;
					return _('Apply');
				}
			}
			so.onclick = function(ev, section_id) {
				uci.set(data[0], 'config', 'main_node', section_id);
				ui.changes.apply(true);

				return this.map.save(null, true);
			}
		}

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hp.loadDefaultLabel, this, data[0]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'node', 'label');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'type', _('Type'));
		so.value('direct', _('Direct'));
		so.value('http', _('HTTP'));
		if (features.with_quic)
			so.value('hysteria', _('Hysteria'));
		so.value('shadowsocks', _('Shadowsocks'));
		if (features.with_shadowsocksr)
			so.value('shadowsocksr', _('ShadowsocksR'));
		so.value('shadowtls', _('ShadowTLS'));
		so.value('socks', _('Socks'));
		so.value('trojan', _('Trojan'));
		if (features.with_wireguard)
			so.value('wireguard', _('WireGuard'));
		so.value('vless', _('VLESS'));
		so.value('vmess', _('VMess'));
		so.rmempty = false;

		so = ss.option(form.Value, 'address', _('Address'));
		so.datatype = 'host';
		so.rmempty = false;

		so = ss.option(form.Value, 'port', _('Port'));
		so.datatype = 'port';
		so.rmempty = false;

		so = ss.option(form.Value, 'username', _('Username'));
		so.depends('type', 'http');
		so.depends('type', 'socks');
		so.modalonly = true;

		so = ss.option(form.Value, 'password', _('Password'));
		so.password = true;
		so.depends('type', 'http');
		so.depends('type', 'shadowsocks');
		so.depends('type', 'shadowsocksr');
		so.depends('type', 'trojan');
		so.depends({'type': 'shadowtls', 'shadowtls_version': '2'});
		so.depends({'type': 'shadowtls', 'shadowtls_version': '3'});
		so.depends({'type': 'socks', 'socks_version': '5'});
		so.validate = function(section_id, value) {
			if (section_id) {
				var type = this.map.lookupOption('type', section_id)[0].formvalue(section_id);
				var required_type = [ 'shadowsocks', 'shadowsocksr', 'shadowtls', 'trojan' ];

				if (required_type.includes(type)) {
					if (type === 'shadowsocks') {
						var encmode = this.map.lookupOption('shadowsocks_encrypt_method', section_id)[0].formvalue(section_id);
						if (encmode === 'none')
							return true;
						else if (encmode === '2022-blake3-aes-128-gcm')
							return hp.validateBase64Key(24, section_id, value);
						else if (['2022-blake3-aes-256-gcm', '2022-blake3-chacha20-poly1305'].includes(encmode))
							return hp.validateBase64Key(44, section_id, value);
					}
					if (!value)
						return _('Expecting: %s').format(_('non-empty value'));
				}
			}

			return true;
		}
		so.modalonly = true;

		/* Direct config */
		so = ss.option(form.ListValue, 'proxy_protocol', _('Proxy protocol'),
			_('Write Proxy Protocol in the connection header.'));
		so.value('', _('Disable'));
		so.value('1');
		so.value('2');
		so.depends('type', 'direct');
		so.modalonly = true;

		/* Hysteria config start */
		so = ss.option(form.ListValue, 'hysteria_protocol', _('Protocol'));
		so.value('udp');
		/* WeChat-Video / FakeTCP are unsupported by sing-box currently
		 * so.value('wechat-video');
		 * so.value('faketcp');
		 */
		so.default = 'udp';
		so.depends('type', 'hysteria');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'hysteria_auth_type', _('Authentication type'));
		so.value('disabled', _('Disable'));
		so.value('base64', _('Base64'));
		so.value('string', _('String'));
		so.default = 'disabled';
		so.depends('type', 'hysteria');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_auth_payload', _('Authentication payload'));
		so.depends({'type': 'hysteria', 'hysteria_auth_type': 'base64'});
		so.depends({'type': 'hysteria', 'hysteria_auth_type': 'string'});
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_obfs_password', _('Obfuscate password'));
		so.depends('type', 'hysteria');
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_down_mbps', _('Max download speed'),
			_('Max download speed in Mbps.'));
		so.datatype = 'uinteger';
		so.depends('type', 'hysteria');
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_up_mbps', _('Max upload speed'),
			_('Max upload speed in Mbps.'));
		so.datatype = 'uinteger';
		so.depends('type', 'hysteria');
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_recv_window_conn', _('QUIC stream receive window'),
			_('The QUIC stream-level flow control window for receiving data.'));
		so.datatype = 'uinteger';
		so.depends('type', 'hysteria');
		so.modalonly = true;

		so = ss.option(form.Value, 'hysteria_revc_window', _('QUIC connection receive window'),
			_('The QUIC connection-level flow control window for receiving data.'));
		so.datatype = 'uinteger';
		so.depends('type', 'hysteria');
		so.modalonly = true;

		so = ss.option(form.Flag, 'hysteria_disable_mtu_discovery', _('Disable Path MTU discovery'),
			_('Disables Path MTU Discovery (RFC 8899). Packets will then be at most 1252 (IPv4) / 1232 (IPv6) bytes in size.'));
		so.default = so.disabled;
		so.depends('type', 'hysteria');
		so.modalonly = true;
		/* Hysteria config end */

		/* Shadowsocks config start */
		so = ss.option(form.ListValue, 'shadowsocks_encrypt_method', _('Encrypt method'));
		for (var i of hp.shadowsocks_encrypt_methods)
			so.value(i);
		/* Stream ciphers */
		so.value('aes-128-ctr');
		so.value('aes-192-ctr');
		so.value('aes-256-ctr');
		so.value('aes-128-cfb');
		so.value('aes-192-cfb');
		so.value('aes-256-cfb');
		so.value('chacha20');
		so.value('chacha20-ietf');
		so.value('rc4-md5');
		so.default = 'aes-128-gcm';
		so.depends('type', 'shadowsocks');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'shadowsocks_plugin', _('Plugin'));
		so.value('', _('none'));
		so.value('obfs-local');
		so.value('v2ray-plugin');
		so.depends('type', 'shadowsocks');
		so.modalonly = true;

		so = ss.option(form.Value, 'shadowsocks_plugin_opts', _('Plugin opts'));
		so.depends('shadowsocks_plugin', 'obfs-local');
		so.depends('shadowsocks_plugin', 'v2ray-plugin');
		so.modalonly = true;
		/* Shadowsocks config end */

		/* ShadowsocksR config start */
		so = ss.option(form.ListValue, 'shadowsocksr_encrypt_method', _('Encrypt method'));
		so.value('none');
		so.value('table');
		so.value('rc4');
		so.value('rc4-md5-6');
		so.value('rc4-md5');
		so.value('aes-128-cfb');
		so.value('aes-192-cfb');
		so.value('aes-256-cfb');
		so.value('aes-128-ctr');
		so.value('aes-192-ctr');
		so.value('aes-256-ctr');
		so.value('bf-cfb');
		so.value('camellia-128-cfb');
		so.value('camellia-192-cfb');
		so.value('camellia-256-cfb');
		so.value('cast5-cfb');
		so.value('des-cfb');
		so.value('idea-cfb');
		so.value('rc2-cfb');
		so.value('seed-cfb');
		so.value('salsa20');
		so.value('chacha20');
		so.value('chacha20-ietf');
		so.depends('type', 'shadowsocksr');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'shadowsocksr_protocol', _('Protocol'));
		so.value('origin');
		so.value('verify_deflate');
		so.value('auth_sha1_v4');
		so.value('auth_aes128_sha1');
		so.value('auth_aes128_md5');
		so.value('auth_chain_a');
		so.value('auth_chain_b');
		so.value('auth_chain_c');
		so.value('auth_chain_d');
		so.value('auth_chain_e');
		so.value('auth_chain_f');
		so.depends('type', 'shadowsocksr');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'shadowsocksr_protocol_param', _('Protocol param'));
		so.depends('type', 'shadowsocksr');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'shadowsocksr_obfs', _('Obfs'));
		so.value('plain');
		so.value('http_simple');
		so.value('http_post');
		so.value('random_head');
		so.value('tls1.2_ticket_auth');
		so.depends('type', 'shadowsocksr');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'shadowsocksr_obfs_param', _('Obfs param'));
		so.depends('type', 'shadowsocksr');
		so.modalonly = true;
		/* ShadowsocksR config end */

		/* ShadowTLS config */
		so = ss.option(form.ListValue, 'shadowtls_version', _('ShadowTLS version'));
		so.value('1', _('v1'));
		so.value('2', _('v2'));
		so.value('3', _('v3'));
		so.default = '1';
		so.depends('type', 'shadowtls');
		so.rmempty = false;
		so.modalonly = true;

		/* Socks config */
		so = ss.option(form.ListValue, 'socks_version', _('Socks version'));
		so.value('4', _('Socks4'));
		so.value('4a', _('Socks4A'));
		so.value('5', _('Socks5'));
		so.default = '5';
		so.depends('type', 'socks');
		so.rmempty = false;
		so.modalonly = true;

		/* VMess / VLESS config start */
		so = ss.option(form.Value, 'uuid', _('UUID'));
		so.depends('type', 'vless');
		so.depends('type', 'vmess');
		so.validate = hp.validateUUID;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'vless_flow', _('Flow'));
		so.value('', _('None'));
		so.value('xtls-rprx-vision');
		so.depends('type', 'vless');
		so.modalonly = true;

		so = ss.option(form.Value, 'vmess_alterid', _('Alter ID'),
			_('Legacy protocol support (VMess MD5 Authentication) is provided for compatibility purposes only, use of alterId > 1 is not recommended.'));
		so.datatype = 'uinteger';
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'vmess_encrypt', _('Encrypt method'));
		so.value('auto');
		so.value('none');
		so.value('zero');
		so.value('aes-128-gcm');
		so.value('chacha20-poly1305');
		so.default = 'auto';
		so.depends('type', 'vmess');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Flag, 'vmess_global_padding', 'Global padding',
			_('Protocol parameter. Will waste traffic randomly if enabled (enabled by default in v2ray and cannot be disabled).'));
		so.default = so.enabled;
		so.depends('type', 'vmess');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Flag, 'vmess_authenticated_length', _('Authenticated length'),
			_('Protocol parameter. Enable length block encryption.'));
		so.default = so.enabled;
		so.depends('type', 'vmess');
		so.rmempty = false;
		so.modalonly = true;
		/* VMess config end */

		/* Transport config start */
		so = ss.option(form.ListValue, 'transport', _('Transport'),
			_('No TCP transport, plain HTTP is merged into the HTTP transport.'));
		so.value('', _('None'));
		so.value('grpc', _('gRPC'));
		so.value('http', _('HTTP'));
		so.value('quic', _('QUIC'));
		so.value('ws', _('WebSocket'));
		so.depends('type', 'trojan');
		so.depends('type', 'vless');
		so.depends('type', 'vmess');
		so.onchange = function(ev, section_id, value) {
			var desc = this.map.findElement('id', 'cbid.homeproxy.%s.transport'.format(section_id)).nextElementSibling;
			if (value === 'http')
				desc.innerHTML = _('TLS is not enforced. If TLS is not configured, plain HTTP 1.1 is used.');
			else if (value === 'quic')
				desc.innerHTML = _('No additional encryption support: It\'s basically duplicate encryption.');
			else
				desc.innerHTML = _('No TCP transport, plain HTTP is merged into the HTTP transport.');

			var tls = this.map.findElement('id', 'cbid.homeproxy.%s.tls'.format(section_id)).firstElementChild;
			if ((value === 'http' && tls.checked) || (value === 'grpc' && !features.with_grpc)) {
				this.map.findElement('id', 'cbid.homeproxy.%s.http_idle_timeout'.format(section_id)).nextElementSibling.innerHTML =
					_('Specifies the period of time after which a health check will be performed using a ping frame if no frames have been received on the connection.<br/>' +
						'Please note that a ping response is considered a received frame, so if there is no other traffic on the connection, the health check will be executed every interval.');

				this.map.findElement('id', 'cbid.homeproxy.%s.http_ping_timeout'.format(section_id)).nextElementSibling.innerHTML =
					_('Specifies the timeout duration after sending a PING frame, within which a response must be received.<br/>' +
						'If a response to the PING frame is not received within the specified timeout duration, the connection will be closed.');
			} else if (value === 'grpc' && features.with_grpc) {
				this.map.findElement('id', 'cbid.homeproxy.%s.http_idle_timeout'.format(section_id)).nextElementSibling.innerHTML =
					_('If the transport doesn\'t see any activity after a duration of this time, it pings the client to check if the connection is still active.');

				this.map.findElement('id', 'cbid.homeproxy.%s.http_ping_timeout'.format(section_id)).nextElementSibling.innerHTML =
					_('The timeout that after performing a keepalive check, the client will wait for activity. If no activity is detected, the connection will be closed.');
			}
		}
		so.modalonly = true;

		/* gRPC config start */
		so = ss.option(form.Value, 'grpc_servicename', _('gRPC service name'));
		so.depends('transport', 'grpc');
		so.modalonly = true;

		if (features.with_grpc) {
			so = ss.option(form.Flag, 'grpc_permit_without_stream', _('gRPC permit without stream'),
				_('If enabled, the client transport sends keepalive pings even with no active connections.'));
			so.default = so.disabled;
			so.depends('transport', 'grpc');
			so.modalonly = true;
		}
		/* gRPC config end */

		/* HTTP config start */
		so = ss.option(form.DynamicList, 'http_host', _('Host'));
		so.datatype = 'hostname';
		so.depends('transport', 'http');
		so.modalonly = true;

		so = ss.option(form.Value, 'http_path', _('Path'));
		so.depends('transport', 'http');
		so.modalonly = true;

		so = ss.option(form.Value, 'http_method', _('Method'));
		so.value('get', _('GET'));
		so.value('put', _('PUT'));
		so.depends('transport', 'http');
		so.modalonly = true;

		so = ss.option(form.Value, 'http_idle_timeout', _('Idle timeout'),
			_('Specifies the period of time after which a health check will be performed using a ping frame if no frames have been received on the connection.<br/>' +
				'Please note that a ping response is considered a received frame, so if there is no other traffic on the connection, the health check will be executed every interval.'));
		so.datatype = 'uinteger';
		so.depends('transport', 'grpc');
		so.depends({'transport': 'http', 'tls': '1'});
		so.modalonly = true;

		so = ss.option(form.Value, 'http_ping_timeout', _('Ping timeout'),
			_('Specifies the timeout duration after sending a PING frame, within which a response must be received.<br/>' +
				'If a response to the PING frame is not received within the specified timeout duration, the connection will be closed.'));
		so.datatype = 'uinteger';
		so.depends('transport', 'grpc');
		so.depends({'transport': 'http', 'tls': '1'});
		so.modalonly = true;
		/* HTTP config end */

		/* WebSocket config start */
		so = ss.option(form.Value, 'ws_host', _('Host'));
		so.depends('transport', 'ws');
		so.modalonly = true;

		so = ss.option(form.Value, 'ws_path', _('Path'));
		so.depends('transport', 'ws');
		so.modalonly = true;

		so = ss.option(form.Value, 'websocket_early_data', _('Early data'),
			_('Allowed payload size is in the request.'));
		so.datatype = 'uinteger';
		so.value('2048');
		so.depends('transport', 'ws');
		so.modalonly = true;

		so = ss.option(form.Value, 'websocket_early_data_header', _('Early data header name'));
		so.value('Sec-WebSocket-Protocol');
		so.depends('transport', 'ws');
		so.modalonly = true;
		/* WebSocket config end */

		so = ss.option(form.ListValue, 'packet_encoding', _('Packet encoding'));
		so.value('', _('none'));
		so.value('packetaddr', _('packet addr (v2ray-core v5+)'));
		so.value('xudp', _('Xudp (Xray-core)'));
		so.depends('type', 'vless');
		so.depends('type', 'vmess');
		so.modalonly = true;
		/* Transport config end */

		/* Wireguard config start */
		so = ss.option(form.DynamicList, 'wireguard_local_address', _('Local address'),
			_('List of IP (v4 or v6) addresses prefixes to be assigned to the interface.'));
		so.datatype = 'cidr';
		so.depends('type', 'wireguard');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'wireguard_private_key', _('Private key'),
			_('WireGuard requires base64-encoded private keys.'));
		so.password = true;
		so.depends('type', 'wireguard');
		so.validate = L.bind(hp.validateBase64Key, this, 44);
		so.modalonly = true;

		so = ss.option(form.Value, 'wireguard_peer_public_key', _('Peer pubkic key'),
			_('WireGuard peer public key.'));
		so.depends('type', 'wireguard');
		so.validate = L.bind(hp.validateBase64Key, this, 44);
		so.modalonly = true;

		so = ss.option(form.Value, 'wireguard_pre_shared_key', _('Pre-shared key'),
			_('WireGuard pre-shared key.'));
		so.password = true;
		so.depends('type', 'wireguard');
		so.validate = L.bind(hp.validateBase64Key, this, 44);
		so.modalonly = true;

		so = ss.option(form.Value, 'wireguard_mtu', _('MTU'));
		so.datatype = 'range(0,9000)';
		so.default = '1408';
		so.depends('type', 'wireguard');
		so.rmempty = false;
		so.modalonly = true;
		/* Wireguard config end */

		/* Mux config start */
		so = ss.option(form.Flag, 'multiplex', _('Multiplex'));
		so.default = so.disabled;
		so.depends('type', 'shadowsocks');
		so.depends('type', 'trojan');
		so.depends('type', 'vmess');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'multiplex_protocol', _('Protocol'),
			_('Multiplex protocol.'));
		so.value('smux');
		so.value('yamux');
		so.default = 'smux';
		so.depends({'type': 'shadowsocks', 'multiplex': '1'});
		so.depends({'type': 'trojan', 'multiplex': '1'});
		so.depends({'type': 'vmess', 'multiplex': '1'});
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Value, 'multiplex_max_connections', _('Maximum connections'));
		so.datatype = 'uinteger';
		so.depends({'type': 'shadowsocks', 'multiplex': '1'});
		so.depends({'type': 'trojan', 'multiplex': '1'});
		so.depends({'type': 'vmess', 'multiplex': '1'});
		so.modalonly = true;

		so = ss.option(form.Value, 'multiplex_min_streams', _('Minimum streams'),
			_('Minimum multiplexed streams in a connection before opening a new connection.'));
		so.datatype = 'uinteger';
		so.depends({'type': 'shadowsocks', 'multiplex': '1'});
		so.depends({'type': 'trojan', 'multiplex': '1'});
		so.depends({'type': 'vmess', 'multiplex': '1'});
		so.modalonly = true;

		so = ss.option(form.Value, 'multiplex_max_streams', _('Maximum streams'),
			_('Maximum multiplexed streams in a connection before opening a new connection.<br/>' +
				'Conflict with <code>Maximum connections</code> and <code>Minimum streams</code>.'));
		so.datatype = 'uinteger';
		so.depends({'type': /^(shadowsocks|trojan|vmess)$/, 'multiplex': '1', 'multiplex_max_connections': '', 'multiplex_min_streams': ''});
		so.modalonly = true;
		/* Mux config end */

		/* TLS config start */
		so = ss.option(form.Flag, 'tls', _('TLS'));
		so.default = so.disabled;
		so.depends('type', 'http');
		so.depends('type', 'hysteria');
		so.depends('type', 'shadowtls');
		so.depends('type', 'trojan');
		so.depends('type', 'vless');
		so.depends('type', 'vmess');
		so.validate = function(section_id, value) {
			if (section_id) {
				var type = this.map.lookupOption('type', section_id)[0].formvalue(section_id);
				var tls = this.map.findElement('id', 'cbid.homeproxy.%s.tls'.format(section_id)).firstElementChild;

				if (['hysteria', 'shadowtls'].includes(type)) {
					tls.checked = true;
					tls.disabled = true;
				} else
					tls.disabled = null;
			}

			return true;
		}
		so.modalonly = true;

		so = ss.option(form.Value, 'tls_sni', _('TLS SNI'),
			_('Used to verify the hostname on the returned certificates unless insecure is given.'));
		so.depends('tls', '1');
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'tls_alpn', _('TLS ALPN'),
			_('List of supported application level protocols, in order of preference.'));
		so.depends('tls', '1');
		so.modalonly = true;

		so = ss.option(form.Flag, 'tls_insecure', _('Allow insecure'),
			_('Allow insecure connection at TLS client.') +
			'<br/>' +
			_('This is <strong>DANGEROUS</strong>, your traffic is almost like <strong>PLAIN TEXT</strong>! Use at your own risk!'));
		so.default = so.disabled;
		so.depends('tls', '1');
		so.onchange = allowInsecureConfirm;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'tls_min_version', _('Minimum TLS version'),
			_('The minimum TLS version that is acceptable.'));
		so.value('', _('default'));
		for (var i of hp.tls_versions)
			so.value(i);
		so.depends('tls', '1');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'tls_max_version', _('Maximum TLS version'),
			_('The maximum TLS version that is acceptable.'));
		so.value('', _('default'));
		for (var i of hp.tls_versions)
			so.value(i);
		so.depends('tls', '1');
		so.modalonly = true;

		so = ss.option(form.MultiValue, 'tls_cipher_suites', _('Cipher suites'),
			_('The elliptic curves that will be used in an ECDHE handshake, in preference order. If empty, the default will be used.'));
		for (var i of hp.tls_cipher_suites)
			so.value(i);
		so.depends('tls', '1');
		so.optional = true;
		so.modalonly = true;

		so = ss.option(form.Flag, 'tls_self_sign', _('Append self-signed certificate'),
			_('If you have the root certificate, use this option instead of allowing insecure.'));
		so.default = so.disabled;
		so.depends('tls_insecure', '0');
		so.modalonly = true;

		so = ss.option(form.Value, 'tls_cert_path', _('Certificate path'),
			_('The path to the server certificate, in PEM format.'));
		so.value('/etc/homeproxy/certs/client_ca.pem');
		so.depends('tls_self_sign', '1');
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(form.Button, '_upload_cert', _('Upload certificate'),
			_('<strong>Save your configuration before uploading files!</strong>'));
		so.inputstyle = 'action';
		so.inputtitle = _('Upload...');
		so.depends({'tls_self_sign': '1', 'tls_cert_path': '/etc/homeproxy/certs/client_ca.pem'});
		so.onclick = L.bind(hp.uploadCertificate, this, _('certificate'), 'client_ca');
		so.modalonly = true;

		if (features.with_ech) {
			so = ss.option(form.Flag, 'tls_ech', _('Enable ECH'),
				_('ECH (Encrypted Client Hello) is a TLS extension that allows a client to encrypt the first part of its ClientHello message.'));
			so.depends('tls', '1');
			so.default = so.disabled;
			so.modalonly = true;

			so = ss.option(form.Flag, 'tls_ech_tls_disable_drs', _('Disable dynamic record sizing'));
			so.depends('tls_ech', '1');
			so.default = so.disabled;
			so.modalonly = true;

			so = ss.option(form.Flag, 'tls_ech_enable_pqss', _('Enable PQ signature schemes'));
			so.depends('tls_ech', '1');
			so.default = so.disabled;
			so.modalonly = true;

			so = ss.option(form.Value, 'tls_ech_config', _('ECH config'));
			so.depends('tls_ech', '1');
			so.modalonly = true;
		}

		if (features.with_utls) {
			so = ss.option(form.ListValue, 'tls_utls', _('uTLS fingerprint'),
				_('uTLS is a fork of "crypto/tls", which provides ClientHello fingerprinting resistance.'));
			so.value('', _('Disable'));
			so.value('360', _('360'));
			so.value('android', _('Android'));
			so.value('chrome', _('Chrome'));
			so.value('edge', _('Edge'));
			so.value('firefox', _('Firefox'));
			so.value('ios', _('iOS'));
			so.value('qq', _('QQ'));
			so.value('random', _('Random'));
			so.value('randomized', _('Randomized'));
			so.value('safari', _('Safari'));
			so.depends({'tls': '1', 'type': /^((?!hysteria$).)+$/});
			so.validate = function(section_id, value) {
				if (section_id) {
					let tls_reality = this.map.lookupOption('tls_reality', section_id)[0].formvalue(section_id);
					if (tls_reality.checked && !value)
						return _('Expecting: %s').format(_('non-empty value'));
				}

				return true;
			}
			so.modalonly = true;

			so = ss.option(form.Flag, 'tls_reality', _('REALITY'));
			so.default = so.disabled;
			so.depends('tls', '1');
			so.modalonly = true;

			so = ss.option(form.Value, 'tls_reality_public_key', _('REALITY public key'));
			so.depends('tls_reality', '1');
			so.rmempty = false;
			so.modalonly = true;

			so = ss.option(form.Value, 'tls_reality_short_id', _('REALITY short ID'));
			so.depends('tls_reality', '1');
			so.rmempty = false;
			so.modalonly = true;
		}
		/* TLS config end */

		/* Extra settings start */
		so = ss.option(form.Flag, 'tcp_fast_open', _('TCP fast open'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.option(form.Flag, 'udp_fragment', _('UDP Fragment'),
			_('Enable UDP fragmentation.'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.option(form.Flag, 'udp_over_tcp', _('UDP over TCP'),
			_('Enable the SUoT protocol, requires server support. Conflict with multiplex.'));
		so.default = so.disabled;
		so.depends('type', 'socks');
		so.depends({'type': 'shadowsocks', 'multiplex': '0'});
		so.modalonly = true;

		so = ss.option(form.ListValue, 'udp_over_tcp_version', _('SUoT version'));
		so.value('1', _('v1'));
		so.value('2', _('v2'));
		so.default = '2';
		so.depends('udp_over_tcp', '1');
		so.modalonly = true;
		/* Extra settings end */
		/* Nodes settings end */

		/* Subscriptions settings start */
		s.tab('subscription', _('Subscriptions'));

		o = s.taboption('subscription', form.Flag, 'auto_update', _('Auto update'),
			_('Auto update subscriptions, GeoIP and GeoSite.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.taboption('subscription', form.ListValue, 'auto_update_time', 'Update time');
		for (var i = 0; i < 24; i++)
			o.value(i, i + ':00');
		o.default = '2';
		o.depends('auto_update', '1');

		o = s.taboption('subscription', form.Flag, 'update_via_proxy', _('Update via proxy'),
			_('Update subscriptions via proxy.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.taboption('subscription', form.DynamicList, 'subscription_url', _('Subscription URL-s'),
			_('Support Hysteria, Shadowsocks(R), Trojan, v2rayN (VMess), and XTLS (VLESS) online configuration delivery standard.'));
		o.validate = function(section_id, value) {
			if (section_id && value) {
				try {
					var url = new URL(value);
					if (!url.hostname)
						return _('Expecting: %s').format(_('valid URL'));
				}
				catch(e) {
					return _('Expecting: %s').format(_('valid URL'));
				}
			}

			return true;
		}

		o = s.taboption('subscription', form.ListValue, 'filter_nodes', _('Filter nodes'),
			_('Drop/keep specific nodes from subscriptions.'));
		o.value('disabled', _('Disable'));
		o.value('blacklist', _('Blacklist mode'));
		o.value('whitelist', _('Whitelist mode'));
		o.default = 'disabled';
		o.rmempty = false;

		o = s.taboption('subscription', form.DynamicList, 'filter_keywords', _('Filter keywords'),
			_('Drop/keep nodes that contain the specific keywords. <a target="_blank" href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions">Regex</a> is supported.'));
		o.depends({'filter_nodes': 'disabled', '!reverse': true});
		o.rmempty = false;

		o = s.taboption('subscription', form.Flag, 'allow_insecure', _('Allow insecure'),
			_('Allow insecure connection by default when add nodes from subscriptions.') +
			'<br/>' +
			_('This is <strong>DANGEROUS</strong>, your traffic is almost like <strong>PLAIN TEXT</strong>! Use at your own risk!'));
		o.default = o.disabled;
		o.rmempty = false;
		o.onchange = allowInsecureConfirm;

		o = s.taboption('subscription', form.ListValue, 'packet_encoding', _('Default packet encoding'));
		o.value('', _('none'));
		o.value('packetaddr', _('packet addr (v2ray-core v5+)'));
		o.value('xudp', _('Xudp (Xray-core)'));

		o = s.taboption('subscription', form.Button, '_save_subscriptions', _('Save subscriptions settings'),
			_('NOTE: Save current settings before updating subscriptions.'));
		o.inputstyle = 'apply';
		o.inputtitle = _('Save current settings');
		o.onclick = function() {
			ui.changes.apply(true);
			return this.map.save(null, true);
		}

		o = s.taboption('subscription', form.Button, '_update_subscriptions', _('Update nodes from subscriptions'));
		o.inputstyle = 'apply';
		o.inputtitle = function(section_id) {
			var sublist = uci.get(data[0], section_id, 'subscription_url') || [];
			if (sublist.length > 0)
				return _('Update %s subscriptions').format(sublist.length);
			else {
				this.readonly = true;
				return _('No subscription available')
			}
		}
		o.onclick = function() {
			return fs.exec('/etc/homeproxy/scripts/update_subscriptions.uc').then((res) => {
				return location.reload();
			}).catch((err) => {
				ui.addNotification(null, E('p', _('An error occurred during updating subscriptions: %s').format(err)));
				return this.map.reset();
			});
		}

		o = s.taboption('subscription', form.Button, '_remove_subscriptions', _('Remove all nodes from subscriptions'));
		o.inputstyle = 'reset';
		o.inputtitle = function() {
			var subnodes = [];
			uci.sections(data[0], 'node', (res) => {
				if (res.grouphash)
					subnodes = subnodes.concat(res['.name'])
			});

			if (subnodes.length > 0) {
				return _('Remove %s nodes').format(subnodes.length);
			} else {
				this.readonly = true;
				return _('No subscription node');
			}
		}
		o.onclick = function() {
			var subnodes = [];
			uci.sections(data[0], 'node', (res) => {
				if (res.grouphash)
					subnodes = subnodes.concat(res['.name'])
			});

			for (var i in subnodes)
				uci.remove(data[0], subnodes[i]);

			if (subnodes.includes(uci.get(data[0], 'config', 'main_node')))
				uci.set(data[0], 'config', 'main_node', 'nil');

			if (subnodes.includes(uci.get(data[0], 'config', 'main_udp_node')))
				uci.set(data[0], 'config', 'main_udp_node', 'nil');

			this.inputtitle = _('%s nodes removed').format(subnodes.length);
			this.readonly = true;

			return this.map.save(null, true);
		}
		/* Subscriptions settings end */

		return m.render();
	}
});
