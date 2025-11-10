'use strict';
'require form';
'require poll';
'require uci';
'require ui';
'require view';

'require fchomo as hm';

const CBIDummyCopyValue = form.Value.extend({
	__name__: 'CBI.DummyCopyValue',

	readonly: true,

	renderWidget: function(section_id, option_index, cfgvalue) {
		let node = form.Value.prototype.renderWidget.call(this, section_id, option_index, cfgvalue);

		node.classList.add('control-group');
		node.firstChild.style.width = '30em';

		node.appendChild(E('button', {
			class: 'cbi-button cbi-button-add',
			click: ui.createHandlerFn(this, async (section_id) => {
				try {
					await navigator.clipboard.writeText(this.formvalue(section_id));
					console.log('Content copied to clipboard!');
				} catch (e) {
					console.error('Failed to copy: ', e);
				}
				/* Deprecated
				let inputEl = document.getElementById(this.cbid(section_id)).querySelector('input');
				inputEl.select();
				document.execCommand("copy");
				inputEl.blur();
				*/
				return alert(_('Content copied to clipboard!'));
			}, section_id)
		}, [ _('Copy') ]));

		return node;
	},

	write: function() {}
});

class VlessEncryption {
	// origin:
	// https://github.com/XTLS/Xray-core/pull/5067
	// server:
	// https://github.com/muink/mihomo/blob/7917f24f428e40ac20b8b8f953b02cf59d1be334/transport/vless/encryption/factory.go#L64
	// https://github.com/muink/mihomo/blob/7917f24f428e40ac20b8b8f953b02cf59d1be334/transport/vless/encryption/server.go#L42
	// client:
	// https://github.com/muink/mihomo/blob/7917f24f428e40ac20b8b8f953b02cf59d1be334/transport/vless/encryption/factory.go#L12
	// https://github.com/muink/mihomo/blob/7917f24f428e40ac20b8b8f953b02cf59d1be334/transport/vless/encryption/client.go#L45
/*
{
	"method": "mlkem768x25519plus",
	"xormode": "native",
	"ticket": "600s",
	"rtt": "0rtt",
	"paddings": [ // Optional
		"100-111-1111",
		"75-0-111",
		"50-0-3333",
		...
	],
	"keypairs": [
		{
			"type": "vless-x25519",
			"server": "cP5Oy9MOpTaBKKE17Pfd56mbb1CIfp5EMpyBYqr2EG8",
			"client": "khEcQMT8j41xWmGYKpZtQ4vd8_9VWyFVmmCDIhRJ-Uk"
		},
		{
			"type": "vless-mlkem768",
			"server": "UHPx3nf-FVxF95byAw0YG025aQNw9HxKej-MiG5AhTcdW_WFpHlTVYQU5NHmXP6tmljSnB2iPmSQ29fisGxEog",
			"client": "h4sdZgCc5-ZefvQ8mZmReOWQdxYb0mwngMdl7pKhYEZZpGWHUPKAmxug87Bgj3GqSHs195QeVpxfrMLNB5Jm0Ge71Fc-A3aLpaS3C3pARbGQoquUDUEVDNwEWjQTvFpGTUV3Nddw_LlRmWN6Wqhguti9cpS6GhEmkBvBayFeHgZosuaQ1FMoAqIeQzSSSoguCZtGLUmdQjEs3zc5rwG1rNanbhtyI3QnooYvr3A0vggIkbmddjtjwYaVQdMAj9Moavc12EAUajOV91QA73RWVuhelbe7pLumsHiW-emIdBgVhEgDDYdGaLq1E8QjB0WbIfufnJp-CJa3Ieu9gmDASTlQBeEREeA9gfoZcTpYD8elhJIJxaPJKXchvUVkFhZarcivlKoqVuaFPzsJM7KQCBC8zfS0t_oiBka-uzg3_Hl153nMTDaCAbZULPZGE-p2EazI2eFBCDktdHtDffJNo7i7ZYSkWkqN9ysr2QZRvYG_PYCzcYSo34Gf5WNvHKuz0Ye3kFkckfuirCmzr3knw2azrSOmpTOX_RSlMlse7HgFYwxHPMJnzPS19ymiwKZPgrAMvCmAUZmsxZGDoKeusNEDGSSFhLcTQys20qGBGYasIgKYGjAKGjK7SCxSOCGBQSU496XBkXQEeOB7k9Sh8jdB0pQGAZw9Ntwvrts2DjIUcsQBv-XEGfnHQXoBmDgzwzYEWxeHd0oNbPIlz7CqvNseoKu6uPZl85xynum6aWd6BDDAtwobbqYkuMUfOUhXf_cH13kWSnuJ6QrOxah94JzAnda3tWRDQ3RajOOjk-OXhbOqi8QMJRFdA_C-xMwQalM_rTSTKOqyCcaNSTkVmMlmyOt90tptk7jKUizDmGhGbsSU8WMY5mhdZ3eUd5O6gQitiMHI1EqnlaRNsXnKFoJ5yHV82Wp1dhFONCG_dlpqunVJD5bFgpxtdFDD-KmXQTymAalFjxeVl_xdc5xd4XYCYmk5dhEiQBE0J_S3Z6x0tmFORpWG9lESK_OBRSul9oKZh9Vet-UZ8FSOVtNFwbeokRwWpFuFL1dL3UpJeININ2cgUfDNWQlwItkokiFf_Kdy12y2O_hqJtoTpNttNxTOiclDzKM1KHNOjYJgTgydcid3mmJl3eA6ezyrDAw1RLCHBucIvYRfwbkmpYMvnfAaA2DIiaTNaSxX8BUl92V49UVKWlQSp8ijfmmTRHrBMmxKjvBIgHqC6dSMhVUEOMzCKXAO3giCS3eZzdrNQGhhqTxpYYnFf6uLoKOIiaGY-ByI1YoIVXxX8aCTOOpesFvHjwOKBEoj4Hoxd3iFMUJQazR7P2drnfmS11kgipM7pSUgB7POKwxEF0NQCedM41wVIuoathAqD6N6qalwQ6iOKlZOBUwwMVAMRDJ3aomG37ZeLYhv6fB0-pUUJSN1q4knjtkLFIJSUrih9FZ0XnOll_aeEgOICqQkb4aOMrovjcJEWvgdjUqGPdyIGgkurfqBRHih3dukUcYxt6Y__4KLQ7acqMx0FOFv0ZxFRTCIRGj_GAlFWUi6fpuPKebXUnEn1PRE0iNXwUV_4jESWb0"
		},
		...
	]
}
*/
	constructor(payload) {
		this.input = payload || '';
		try {
			let content = JSON.parse(this.input.trim());
			Object.keys(content).forEach(key => this[key] = content[key]);
		} catch {}

		this.method ||= hm.vless_encryption.methods[0][0];
		this.xormode ||= hm.vless_encryption.xormodes[0][0];
		this.ticket ||= hm.vless_encryption.tickets[0][0];
		this.rtt ||= hm.vless_encryption.rtts[0][0];
		this.paddings ||= [];
		this.keypairs ||= [];
	}

	setKey(key, value) {
		this[key] = value;

		return this
	}

	_toMihomo(payload, side) {
		if (!['server', 'client'].includes(side))
			throw new Error('Unknown side: ' + side); // `Unknown side: '${side}'`

		let required = [
			payload.method,
			payload.xormode,
			side === 'server' ? payload.ticket : side === 'client' ? payload.rtt : null
		].join('.');

		return required +
			(hm.isEmpty(payload.paddings) ? '' : '.' + payload.paddings.join('.')) + // Optional
			(hm.isEmpty(payload.keypairs) ? '' : '.' + payload.keypairs.map(e => e[side]).join('.')); // Required
	}

	toString(format, side) {
		format ||= 'json';

		let payload = hm.removeBlankAttrs({
			method: this.method,
			xormode: this.xormode,
			ticket: this.ticket,
			rtt: this.rtt,
			paddings: this.paddings || [],
			keypairs: this.keypairs || []
		});

		if (format === 'json')
			return JSON.stringify(payload);
		else if (format === 'mihomo')
			return this._toMihomo(payload, side);
		else
			throw new Error(`Unknown format: '${format}'`);
	}
}

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
		s.tab('field_vless_encryption', _('Vless Encryption fields'));
		s.tab('field_tls', _('TLS fields'));
		s.tab('field_transport', _('Transport fields'));
		s.tab('field_multiplex', _('Multiplex fields'));
		s.tab('field_listen', _('Listen fields'));

		/* General fields */
		o = s.taboption('field_general', form.Value, 'label', _('Label'));
		o.load = hm.loadDefaultLabel;
		o.validate = hm.validateUniqueValue;
		o.modalonly = true;

		o = s.taboption('field_general', form.Flag, 'enabled', _('Enable'));
		o.default = o.enabled;
		o.editable = true;

		o = s.taboption('field_general', form.Flag, 'auto_firewall', _('Firewall'),
			_('Auto configure firewall'));
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
		//o.placeholder = '1080,2079-2080,3080'; // @fw4 does not support port lists with commas
		o.rmempty = false;
		//o.validate = hm.validateCommonPort; // @fw4 does not support port lists with commas

		// @dev: Features under development
		// @rule
		// @proxy

		/* HTTP / SOCKS fields */
		/* hm.validateAuth */
		o = s.taboption('field_general', form.Value, 'username', _('Username'));
		o.validate = hm.validateAuthUsername;
		o.depends({type: /^(http|socks|mixed|mieru|trojan|anytls|hysteria2)$/});
		o.modalonly = true;

		o = s.taboption('field_general', hm.GenValue, 'password', _('Password'));
		o.password = true;
		o.validate = hm.validateAuthPassword;
		o.rmempty = false;
		o.depends({type: /^(http|socks|mixed|mieru|trojan|anytls|hysteria2)$/, username: /.+/});
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

		/* Mieru fields */
		o = s.taboption('field_general', form.ListValue, 'mieru_transport', _('Transport'));
		o.default = 'TCP';
		o.value('TCP');
		o.value('UDP');
		o.depends('type', 'mieru');
		o.modalonly = true;

		/* Tuic fields */
		o = s.taboption('field_general', hm.GenValue, 'uuid', _('UUID'));
		o.rmempty = false;
		o.validate = hm.validateUUID;
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
		o.validate = hm.validateTimeDuration;
		o.depends('type', 'tuic');
		o.modalonly = true;

		o = s.taboption('field_general', form.Value, 'tuic_authentication_timeout', _('Auth timeout'),
			_('In seconds.'));
		o.default = '1000';
		o.validate = hm.validateTimeDuration;
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
		o.validate = hm.validateUUID;
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
		//o.value('kcp-tun', _('kcp-tun'));
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

		/* Vless Encryption fields */
		o = s.taboption('field_general', form.Flag, 'vless_decryption', _('decryption'));
		o.default = o.disabled;
		o.depends('type', 'vless');
		o.modalonly = true;

		const initVlessEncryptionOption = function(o, key) {
			o.load = function(section_id) {
				return new VlessEncryption(uci.get(data[0], section_id, 'vless_encryption_hmpayload'))[key];
			}
			o.onchange = function(ev, section_id, value) {
				let UIEl = this.section.getUIElement(section_id, 'vless_encryption_hmpayload');
				let newpayload = new VlessEncryption(UIEl.getValue()).setKey(key, value);

				UIEl.setValue(newpayload.toString());

				[
					['server', '_vless_encryption_decryption'],
					['client', '_vless_encryption_encryption']
				].forEach(([side, option]) => {
					UIEl = this.section.getUIElement(section_id, option);
					UIEl.setValue(newpayload.toString('mihomo', side));
				});
			}
			o.write = function() {};
		}

		o = s.taboption('field_vless_encryption', form.Value, 'vless_encryption_hmpayload', _('Payload'));
		o.readonly = true;
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', CBIDummyCopyValue, '_vless_encryption_decryption', _('decryption'));
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', CBIDummyCopyValue, '_vless_encryption_encryption', _('encryption'));
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', form.ListValue, 'vless_encryption_method', _('Encryption method'));
		o.default = hm.vless_encryption.methods[0][0];
		hm.vless_encryption.methods.forEach((res) => {
			o.value.apply(o, res);
		})
		initVlessEncryptionOption(o, 'method');
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', form.RichListValue, 'vless_encryption_xormode', _('XOR mode'));
		o.default = hm.vless_encryption.xormodes[0][0];
		hm.vless_encryption.xormodes.forEach((res) => {
			o.value.apply(o, res);
		})
		initVlessEncryptionOption(o, 'xormode');
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', hm.RichValue, 'vless_encryption_ticket', _('Server') +' '+ _('RTT'));
		o.default = hm.vless_encryption.tickets[0][0];
		hm.vless_encryption.tickets.forEach((res) => {
			o.value.apply(o, res);
		})
		initVlessEncryptionOption(o, 'ticket');
		o.validate = function(section_id, value) {
			if (!value)
				return true;

			if (!value.match(/^(\d+-)?\d+s$/))
				return _('Expecting: %s').format('^(\\d+-)?\\d+s$');

			return true;
		}
		o.rmempty = false;
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', form.ListValue, 'vless_encryption_rtt', _('Client') +' '+ _('RTT'));
		o.default = hm.vless_encryption.rtts[0][0];
		hm.vless_encryption.rtts.forEach((res) => {
			o.value.apply(o, res);
		})
		initVlessEncryptionOption(o, 'rtt');
		o.rmempty = false;
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', !hm.pr7558_merged ? hm.DynamicList : form.DynamicList, 'vless_encryption_paddings', _('Paddings'), // @pr7558_merged
			_('The server and client can set different padding parameters.') + '</br>' +
			_('In the order of one <code>Padding-Length</code> and one <code>Padding-Interval</code>, infinite concatenation.') + '</br>' +
			_('The first padding must have a probability of 100% and at least 35 bytes.'));
		hm.vless_encryption.paddings.forEach((res) => {
			o.value.apply(o, res);
		})
		initVlessEncryptionOption(o, 'paddings');
		o.validate = function(section_id, value) {
			if (!value)
				return true;

			if (!value.match(/^\d+(-\d+){2}$/))
				return _('Expecting: %s').format('^\\d+(-\\d+){2}$');

			return true;
		}
		o.allowduplicates = true;
		o.depends('vless_decryption', '1');
		o.modalonly = true;

		o = s.taboption('field_vless_encryption', hm.GenText, 'vless_encryption_keypairs', _('Keypairs'));
		o.placeholder = '[\n  {\n    "type": "vless-x25519",\n    "server": "cP5Oy9MOpTaBKKE17Pfd56mbb1CIfp5EMpyBYqr2EG8",\n    "client": 	"khEcQMT8j41xWmGYKpZtQ4vd8_9VWyFVmmCDIhRJ-Uk"\n  },\n  {\n    "type": "vless-mlkem768",\n    "server": 	"UHPx3nf-FVxF95byAw0YG025aQNw9HxKej-MiG5AhTcdW_WFpHlTVYQU5NHmXP6tmljSnB2iPmSQ29fisGxEog",\n    "client": 	"h4sdZgCc5-ZefvQ8mZmReOWQdxYb0mwngMdl7pKhYEZZpGWHUPKAmxug87Bgj3GqSHs195QeVpxfrMLNB5J..."\n  },\n  ...\n]';
		o.rows = 10;
		o.hm_options = {
			type: hm.vless_encryption.keypairs.types[0][0],
			params: '',
			callback: function(result) {
				const section_id = this.section.section;
				const key_type = this.hm_options.type;

				let keypair = {"type": key_type, "server": "", "client": ""};
				switch (key_type) {
					case 'vless-x25519':
						keypair.server = result.private_key;
						keypair.client = result.password;
						break;
					case 'vless-mlkem768':
						keypair.server = result.seed;
						keypair.client = result.client;
						break;
					default:
						break;
				}

				let keypairs = [];
				try {
					keypairs = JSON.parse(this.formvalue(section_id).trim());
				} catch {}
				if (!Array.isArray(keypairs))
					keypairs = [];

				keypairs.push(keypair);

				return [
					[this.option, JSON.stringify(keypairs, null, 2)]
				]
			}
		}
		o.renderWidget = function(section_id, option_index, cfgvalue) {
			let node = hm.TextValue.prototype.renderWidget.call(this, section_id, option_index, cfgvalue);
			const cbid = this.cbid(section_id) + '._keytype_select';
			const selected = this.hm_options.type;

			let selectEl = E('select', {
				id: cbid,
				class: 'cbi-input-select',
				style: 'width: 10em',
			});

			hm.vless_encryption.keypairs.types.forEach(([k, v]) => {
				selectEl.appendChild(E('option', {
					'value': k,
					'selected': (k === selected) ? '' : null
				}, [ v ]));
			});

			node.appendChild(E('div',  { 'class': 'control-group' }, [
				selectEl,
				E('button', {
					class: 'cbi-button cbi-button-add',
					click: ui.createHandlerFn(this, () => {
						this.hm_options.type = document.getElementById(cbid).value;

						return hm.handleGenKey.call(this, this.hm_options);
					})
				}, [ _('Generate') ])
			]));

			return node;
		}
		o.load = function(section_id) {
			return JSON.stringify(new VlessEncryption(uci.get(data[0], section_id, 'vless_encryption_hmpayload'))['keypairs'], null, 2);
		}
		o.validate = function(section_id, value) {
			let result = hm.validateJson.call(this, section_id, value);

			if (result === true) {
				let keypairs = JSON.parse(value.trim());

				if (Array.isArray(keypairs) && keypairs.length >= 1) {
					let UIEl = this.section.getUIElement(section_id, 'vless_encryption_hmpayload');
					let newpayload = new VlessEncryption(UIEl.getValue()).setKey('keypairs', keypairs);

					UIEl.setValue(newpayload.toString());

					[
						['server', '_vless_encryption_decryption'],
						['client', '_vless_encryption_encryption']
					].forEach(([side, option]) => {
						UIEl = this.section.getUIElement(section_id, option);
						UIEl.setValue(newpayload.toString('mihomo', side));
					});
				} else
					return _('Expecting: %s').format(_('least one keypair required'));

				return true;
			} else
				return result;
		}
		o.rmempty = false;
		o.depends('vless_decryption', '1');
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
			if (['trojan', 'anytls', 'tuic', 'hysteria2'].includes(type)) {
				tls.checked = true;
				tls.disabled = true;
				if (['tuic', 'hysteria2'].includes(type) && !`${tls_alpn.getValue()}`)
					tls_alpn.setValue('h3');
			} else {
				tls.removeAttribute('disabled');
			}

			// Force disabled
			if (!['vmess', 'vless', 'trojan'].includes(type)) {
				tls_reality.checked = false;
				tls_reality.disabled = true;
			} else {
				tls_reality.removeAttribute('disabled');
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
			_('The %s public key, in PEM format.').format(_('Server')));
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
			_('The %s private key, in PEM format.').format(_('Server')));
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

		o = s.taboption('field_tls', form.ListValue, 'tls_client_auth_type', _('Client Auth type') + _(' (mTLS)'));
		o.default = hm.tls_client_auth_types[0][0];
		hm.tls_client_auth_types.forEach((res) => {
			o.value.apply(o, res);
		})
		o.depends({tls: '1', type: /^(http|socks|mixed|vmess|vless|trojan|anytls|hysteria2|tuic)$/});
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_client_auth_cert_path', _('Client Auth Certificate path') + _(' (mTLS)'),
			_('The %s public key, in PEM format.').format(_('Client')));
		o.value('/etc/fchomo/certs/client_publickey.pem');
		o.validate = function(/* ... */) {
			return hm.validateMTLSClientAuth.call(this, 'tls_client_auth_type', ...arguments);
		}
		o.depends({tls: '1', type: /^(http|socks|mixed|vmess|vless|trojan|anytls|hysteria2|tuic)$/});
		o.modalonly = true;

		o = s.taboption('field_tls', form.Button, '_upload_client_auth_cert', _('Upload certificate') + _(' (mTLS)'),
			_('<strong>Save your configuration before uploading files!</strong>'));
		o.inputstyle = 'action';
		o.inputtitle = _('Upload...');
		o.depends({tls: '1', tls_client_auth_cert_path: '/etc/fchomo/certs/client_publickey.pem'});
		o.onclick = L.bind(hm.uploadCertificate, o, _('certificate'), 'client_publickey');
		o.modalonly = true;

		o = s.taboption('field_tls', hm.GenText, 'tls_ech_key', _('ECH key'));
		o.placeholder = '-----BEGIN ECH KEYS-----\nACATwY30o/RKgD6hgeQxwrSiApLaCgU+HKh7B6SUrAHaDwBD/g0APwAAIAAgHjzK\nmadSJjYQIf9o1N5GXjkW4DEEeb17qMxHdwMdNnwADAABAAEAAQACAAEAAwAIdGVz\ndC5jb20AAA==\n-----END ECH KEYS-----';
		o.hm_placeholder = 'outer-sni.any.domain';
		o.cols = 30;
		o.rows = 2;
		o.hm_options = {
			type: 'ech-keypair',
			params: '',
			callback: function(result) {
				return [
					[this.option, result.ech_key],
					['tls_ech_config', result.ech_cfg]
				]
			}
		}
		o.renderWidget = function(section_id, option_index, cfgvalue) {
			let node = hm.TextValue.prototype.renderWidget.call(this, section_id, option_index, cfgvalue);
			const cbid = this.cbid(section_id) + '._outer_sni';

			node.appendChild(E('div',  { 'class': 'control-group' }, [
				E('input', {
					id: cbid,
					class: 'cbi-input-text',
					style: 'width: 10em',
					placeholder: this.hm_placeholder
				}),
				E('button', {
					class: 'cbi-button cbi-button-add',
					click: ui.createHandlerFn(this, () => {
						this.hm_options.params = document.getElementById(cbid).value;

						return hm.handleGenKey.call(this, this.hm_options);
					})
				}, [ _('Generate') ])
			]));

			return node;
		}
		o.depends({tls: '1', type: /^(http|socks|mixed|vmess|vless|trojan|anytls|hysteria2|tuic)$/});
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_ech_config', _('ECH config'),
			_('This ECH parameter needs to be added to the HTTPS record of the domain.'));
		o.placeholder = 'AEn+DQBFKwAgACABWIHUGj4u+PIggYXcR5JF0gYk3dCRioBW8uJq9H4mKAAIAAEAAQABAANAEnB1YmxpYy50bHMtZWNoLmRldgAA';
		o.depends({tls: '1', type: /^(http|socks|mixed|vmess|vless|trojan|anytls|hysteria2|tuic)$/});
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
		o.hm_options = {
			type: 'reality-keypair',
			callback: function(result) {
				return [
					[this.option, result.private_key],
					['tls_reality_public_key', result.public_key]
				]
			}
		}
		o.password = true;
		o.rmempty = false;
		o.depends('tls_reality', '1');
		o.modalonly = true;

		o = s.taboption('field_tls', form.Value, 'tls_reality_public_key', _('REALITY public key'));
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
