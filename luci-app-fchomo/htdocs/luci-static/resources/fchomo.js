'use strict';
'require baseclass';
'require form';
'require fs';
'require rpc';
'require uci';
'require ui';
'require validation';

/* Member */
const rulesetdoc = 'data:text/html;base64,' + 'cmxzdHBsYWNlaG9sZGVy';

const sharkaudio = function() {
	return 'data:audio/x-wav;base64,' +
'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA='
}()

const sharktaikogif = function() {
	return 'data:image/gif;base64,' +
'c2hhcmstdGFpa28uZ2lm'
}()

const less_25_12 = !form.DynamicList.prototype.renderWidget.toString().match('this\.allowduplicates');

const HM_DIR = "/etc/fchomo";

const monospacefonts = [
	'"Cascadia Code"',
	'"Cascadia Mono"',
	'Menlo',
	'Monaco',
	'Consolas',
	'"Liberation Mono"',
	'"Courier New"',
	'monospace'
];

const checkurls = [
	['https://www.baidu.com', _('Baidu')],
	['https://s1.music.126.net/style/favicon.ico', _('163Music')],
	['https://www.google.com/generate_204', _('Google')],
	['https://github.com', _('GitHub')],
	['https://www.youtube.com', _('YouTube')]
];

const stunserver = [
	['stun.fitauto.ru:3478'],
	['stun.hot-chilli.net:3478'],
	['stun.pure-ip.com:3478'],
	['stun.voipgate.com:3478'],
	['stun.voipia.net:3478'],
	['stunserver2024.stunprotocol.org:3478']
];

const dashrepos = [
	['zephyruso/zashboard', _('zashboard')],
	['metacubex/metacubexd', _('metacubexd')],
	['metacubex/yacd-meta', _('yacd-meta')],
	['metacubex/razord-meta', _('razord-meta')]
];

const dashrepos_urlparams = {
	'zephyruso/zashboard':   '#/setup' + '?hostname=%s&port=%s&secret=%s',
	'metacubex/metacubexd':  '#/setup' + '?hostname=%s&port=%s&secret=%s',
	'metacubex/yacd-meta':   '?hostname=%s&port=%s&secret=%s',
	'metacubex/razord-meta': '?host=%s&port=%s&secret=%s'
};

const log_levels = [
	['silent', _('Silent')],
	['error', _('Error')],
	['warning', _('Warning')],
	['info', _('Info')],
	['debug', _('Debug')]
];

const glossary = {
	proxy_group: {
		prefmt: 'group_%s',
		field: 'proxy-groups',
	},
	rules: {
		prefmt: '%s_host',
		field: 'rules',
	},
	subrules: {
		prefmt: '%s_subhost',
		field: 'sub-rules',
	},
	dns_server: {
		prefmt: 'dns_%s',
		field: 'nameserver',
	},
	dns_policy: {
		prefmt: '%s_domain',
		field: 'nameserver-policy',
	},
	node: {
		prefmt: 'node_%s',
		field: 'proxies',
	},
	provider: {
		prefmt: 'sub_%s',
		field: 'proxy-providers',
	},
	dialer_proxy: {
		prefmt: 'chain_%s',
		//field: 'dialer-proxy',
	},
	ruleset: {
		prefmt: 'rule_%s',
		field: 'rule-providers',
	},
	server: {
		prefmt: 'server_%s',
		field: 'listeners',
	},
};

const health_checkurls = [
	['https://cp.cloudflare.com'],
	['https://www.gstatic.com/generate_204']
];

const inbound_type = [
	['http', _('HTTP') + ' - ' + _('TCP')],
	['socks', _('SOCKS') + ' - ' + _('TCP/UDP')],
	['mixed', _('Mixed') + ' - ' + _('TCP/UDP')],
	['shadowsocks', _('Shadowsocks') + ' - ' + _('TCP/UDP')],
	['mieru', _('Mieru') + ' - ' + _('TCP/UDP')],
	['sudoku', _('Sudoku') + ' - ' + _('TCP')],
	['vmess', _('VMess') + ' - ' + _('TCP')],
	['vless', _('VLESS') + ' - ' + _('TCP')],
	['trojan', _('Trojan') + ' - ' + _('TCP')],
	['anytls', _('AnyTLS') + ' - ' + _('TCP')],
	['tuic', _('TUIC') + ' - ' + _('UDP')],
	['hysteria2', _('Hysteria2') + ' - ' + _('UDP')],
	//['tunnel', _('Tunnel') + ' - ' + _('TCP/UDP')]
];

const ip_version = [
	['', _('Keep default')],
	['dual', _('Dual stack')],
	['ipv4', _('IPv4 only')],
	['ipv6', _('IPv6 only')],
	['ipv4-prefer', _('Prefer IPv4')],
	['ipv6-prefer', _('Prefer IPv6')]
];

const load_balance_strategy = [
	['round-robin', _('Simple round-robin all nodes')],
	['consistent-hashing', _('Same dstaddr requests. Same node')],
	['sticky-sessions', _('Same srcaddr and dstaddr requests. Same node')]
];

const outbound_type = [
	['direct', _('DIRECT') + ' - ' + _('TCP/UDP')],
	['http', _('HTTP') + ' - ' + _('TCP')],
	['socks5', _('SOCKS5') + ' - ' + _('TCP/UDP')],
	['ss', _('Shadowsocks') + ' - ' + _('TCP/UDP')],
	//['ssr', _('ShadowsocksR')], // Deprecated
	['mieru', _('Mieru') + ' - ' + _('TCP/UDP')],
	['sudoku', _('Sudoku') + ' - ' + _('TCP')],
	['snell', _('Snell') + ' - ' + _('TCP')],
	['vmess', _('VMess') + ' - ' + _('TCP')],
	['vless', _('VLESS') + ' - ' + _('TCP')],
	['trojan', _('Trojan') + ' - ' + _('TCP')],
	['anytls', _('AnyTLS') + ' - ' + _('TCP')],
	//['hysteria', _('Hysteria') + ' - ' + _('UDP')],
	['hysteria2', _('Hysteria2') + ' - ' + _('UDP')],
	['tuic', _('TUIC') + ' - ' + _('UDP')],
	['wireguard', _('WireGuard') + ' - ' + _('UDP')],
	['ssh', _('SSH') + ' - ' + _('TCP')]
];

const preset_outbound = {
	full: [
		['DIRECT'],
		['REJECT'],
		['REJECT-DROP'],
		['PASS'],
		['COMPATIBLE'],
		['GLOBAL']
	],
	direct: [
		['', _('null')],
		['DIRECT'],
		['GLOBAL']
	],
	dns: [
		['', 'RULES'],
		['DIRECT'],
		['GLOBAL']
	]
};

const proxy_group_type = [
	['select', _('Select')],
	['fallback', _('Fallback')],
	['url-test', _('URL test')],
	['load-balance', _('Load balance')],
	//['relay', _('Relay')], // Deprecated
];

const routing_port_type = [
	['all', _('All ports')],
	['common_tcpport', _('Common ports (bypass P2P traffic)'), uci.get('fchomo', 'config', 'common_tcpport') || '20-21,22,53,80,110,143,443,853,873,993,995,5222,8080,8443,9418'],
	['common_udpport', _('Common ports (bypass P2P traffic)'), uci.get('fchomo', 'config', 'common_udpport') || '20-21,22,53,80,110,143,443,853,993,995,8080,8443,9418'],
	['smtp_tcpport', _('%s ports').format(_('SMTP')), uci.get('fchomo', 'config', 'smtp_tcpport') || '465,587'],
	['stun_port', _('%s ports').format(_('STUN')), uci.get('fchomo', 'config', 'stun_port') || '3478,19302'],
	['turn_port', _('%s ports').format(_('TURN')), uci.get('fchomo', 'config', 'turn_port') || '5349'],
	['google_fcm_port', _('%s ports').format(_('Google FCM')), uci.get('fchomo', 'config', 'google_fcm_port') || '443,5228-5230'],
	['steam_client_port', _('%s ports').format(_('Steam Client')), uci.get('fchomo', 'config', 'steam_client_port') || '27015-27050'],
	['steam_p2p_udpport', _('%s ports').format(_('Steam P2P')), uci.get('fchomo', 'config', 'steam_p2p_udpport') || '3478,4379,4380,27000-27100'],
];

const rules_type = [
	['DOMAIN'],
	['DOMAIN-SUFFIX'],
	['DOMAIN-KEYWORD'],
	['DOMAIN-WILDCARD'],
	['DOMAIN-REGEX'],
	['GEOSITE'],

	['IP-CIDR'],
	['IP-CIDR6'],
	['IP-SUFFIX'],
	['IP-ASN'],
	['GEOIP'],

	['SRC-GEOIP'],
	['SRC-IP-ASN'],
	['SRC-IP-CIDR'],
	['SRC-IP-SUFFIX'],

	['DST-PORT'],
	['SRC-PORT'],

	//['IN-PORT'],
	//['IN-TYPE'],
	//['IN-USER'],
	//['IN-NAME'],

	['PROCESS-PATH'],
	['PROCESS-PATH-REGEX'],
	['PROCESS-NAME'],
	['PROCESS-NAME-REGEX'],
	['UID'],

	['NETWORK'],
	['DSCP'],

	['RULE-SET'],

	['MATCH']
];

const rules_type_allowparms = [
	// params only available for types other than
	// https://github.com/muink/mihomo/blob/300eb8b12a75504c4bd4a6037d2f6503fd3b347f/rules/parser.go#L12
	'GEOIP',
	'IP-ASN',
	'IP-CIDR',
	'IP-CIDR6',
	'IP-SUFFIX',
	'RULE-SET',
];

const rules_logical_type = [
	['AND'],
	['OR'],
	['NOT'],
	//['SUB-RULE'],
];

const rules_logical_payload_count = {
	'AND': { low: 2, high: undefined },
	'OR': { low: 2, high: undefined },
	'NOT': { low: 1, high: 1 },
	//'SUB-RULE': 0,
};

const aead_cipher_length = {
	/* AEAD */
	'aes-128-gcm': 0,
	'aes-192-gcm': 0,
	'aes-256-gcm': 0,
	'chacha20-ietf-poly1305': 0,
	'xchacha20-ietf-poly1305': 0,
	/* AEAD 2022 */
	'2022-blake3-aes-128-gcm': 16,
	'2022-blake3-aes-256-gcm': 32,
	'2022-blake3-chacha20-poly1305': 32
};

const shadowsocks_cipher_methods = [
	/* Stream */
	['none', _('none')],
	/* AEAD */
	['aes-128-gcm', _('aes-128-gcm')],
	['aes-192-gcm', _('aes-192-gcm')],
	['aes-256-gcm', _('aes-256-gcm')],
	['chacha20-ietf-poly1305', _('chacha20-ietf-poly1305')],
	['xchacha20-ietf-poly1305', _('xchacha20-ietf-poly1305')],
	/* AEAD 2022 */
	['2022-blake3-aes-128-gcm', _('2022-blake3-aes-128-gcm')],
	['2022-blake3-aes-256-gcm', _('2022-blake3-aes-256-gcm')],
	['2022-blake3-chacha20-poly1305', _('2022-blake3-chacha20-poly1305')]
];

const sudoku_cipher_methods = [
	['none', _('none')],
	['aes-128-gcm', _('aes-128-gcm')],
	['chacha20-ietf-poly1305', _('chacha20-ietf-poly1305')]
];

const trojan_cipher_methods = [
	['aes-128-gcm', _('aes-128-gcm')],
	['aes-256-gcm', _('aes-256-gcm')],
	['chacha20-ietf-poly1305', _('chacha20-ietf-poly1305')]
];

const tls_client_auth_types = [
	['', _('none')],
	['request', _('Request')],
	['require-any', _('Require any')],
	['verify-if-given', _('Verify if given')],
	['require-and-verify', _('Require and verify')]
];

const tls_client_fingerprints = [
	['chrome'],
	['firefox'],
	['safari'],
	['iOS'],
	['android'],
	['edge'],
	['360'],
	['qq'],
	['random', _('Random')]
];

const vless_encryption = {
	methods: [
		['mlkem768x25519plus', _('mlkem768x25519plus')]
	],
	xormodes: [
		['native', 'native', _('Native appearance')],
		['xorpub', 'xorpub', _('Eliminate encryption header characteristics')],
		['random', 'random', _('Randomized traffic characteristics')]
	],
	tickets: [
		['600s', '600s', _('Send random ticket of 300s-600s duration for client 0-RTT reuse.')],
		['300-600s', '300-600s', _('Send random ticket of 300s-600s duration for client 0-RTT reuse.')],
		['0s', '0s', _('1-RTT only.')]
	],
	rtts: [
		['0rtt', _('0-RTT reuse.') +' '+ _('Requires server support.')],
		['1rtt', _('1-RTT only.')]
	],
	paddings: [
		['100-111-1111', '100-111-1111: ' + _('After the 1-RTT client/server hello, padding randomly 111-1111 bytes with 100% probability.')],
		['75-0-111', '75-0-111: ' + _('Wait a random 0-111 milliseconds with 75% probability.')],
		['50-0-3333', '50-0-3333: ' + _('Send padding randomly 0-3333 bytes with 50% probability.')]
	],
	keypairs: {
		types: [
			['vless-x25519', _('vless-x25519')],
			['vless-mlkem768', _('vless-mlkem768')]
		]
	}
};

const vless_flow = [
	['', _('None')],
	['xtls-rprx-vision']
];

/* Prototype */
const CBIGridSection = form.GridSection.extend({
	modaltitle(/* ... */) {
		return loadModalTitle.call(this, ...this.hm_modaltitle || [null,null], ...arguments);
	},

	sectiontitle(/* ... */) {
		return loadDefaultLabel.apply(this, arguments);
	},

	renderSectionAdd(extra_class) {
		const prefmt = this.hm_prefmt || '%s';
		const LC = this.hm_lowcase_only;

		let el = form.GridSection.prototype.renderSectionAdd.call(this, extra_class),
			nameEl = el.querySelector('.cbi-section-create-name');

		nameEl.placeholder = _('Specify a ID');

		ui.addValidator(nameEl, 'uciname', true, (v) => {
			let button = el.querySelector('.cbi-section-create > .cbi-button-add');

			if (!v) {
				button.disabled = true;
				return true;
			} else if (LC && (v !== v.toLowerCase())) {
				button.disabled = true;
				return _('Expecting: %s').format(_('Lowercase only'));
			} else if (uci.get(this.config, v)) {
				button.disabled = true;
				return _('Expecting: %s').format(_('unique UCI identifier'));
			} else if (uci.get(this.config, prefmt.format(v))) {
				button.disabled = true;
				return _('Expecting: %s').format(_('unique identifier'));
			} else {
				button.removeAttribute('disabled');
				return true;
			}
		}, 'blur', 'keyup');

		return el;
	},

	handleAdd(ev, name) {
		const prefmt = this.hm_prefmt || '%s';

		return form.GridSection.prototype.handleAdd.call(this, ev, prefmt.format(name));
	}
});

const CBIDynamicList = form.DynamicList.extend({ // @less_25_12
	__name__: 'CBI.DynamicList',

	renderWidget(section_id, option_index, cfgvalue) {
		const value = (cfgvalue != null) ? cfgvalue : this.default;
		const choices = this.transformChoices();
		const items = L.toArray(value);

		const widget = new UIDynamicList(items, choices, {
			id: this.cbid(section_id),
			sort: this.keylist,
			allowduplicates: this.allowduplicates,
			optional: this.optional || this.rmempty,
			datatype: this.datatype,
			placeholder: this.placeholder,
			validate: L.bind(this.validate, this, section_id),
			disabled: (this.readonly != null) ? this.readonly : this.map.readonly
		});

		return widget.render();
	}
});

const CBIStaticList = form.DynamicList.extend({
	__name__: 'CBI.StaticList',

	renderWidget(/* ... */) {
		let El = (less_25_12 ? CBIDynamicList : form.DynamicList).prototype.renderWidget.apply(this, arguments); // @less_25_12

		El.querySelector('.add-item ul > li[data-value="-"]')?.remove();

		return El;
	}
});

const CBIListValue = form.ListValue.extend({
	renderWidget(/* ... */) {
		let frameEl = form.ListValue.prototype.renderWidget.apply(this, arguments);

		frameEl.querySelector('select').style["min-width"] = '10em';

		return frameEl;
	}
});

const CBIRichValue = form.Value.extend({
	__name__: 'CBI.RichValue',

	value: form.RichListValue.prototype.value
});

const CBIRichMultiValue = form.MultiValue.extend({
	__name__: 'CBI.RichMultiValue',

	value: form.RichListValue.prototype.value
});

const CBITextValue = form.TextValue.extend({
	renderWidget(/* ... */) {
		let frameEl = form.TextValue.prototype.renderWidget.apply(this, arguments);

		frameEl.querySelector('textarea').style.fontFamily = monospacefonts.join(',');

		return frameEl;
	}
});

const CBIGenValue = form.Value.extend({
	__name__: 'CBI.GenValue',

	renderWidget(/* ... */) {
		let node = form.Value.prototype.renderWidget.apply(this, arguments);

		if (!this.password)
			node.classList.add('control-group');

		(node.querySelector('.control-group') || node).appendChild(E('button', {
			class: 'cbi-button cbi-button-add',
			title: _('Generate'),
			click: ui.createHandlerFn(this, handleGenKey, this.hm_options || this.option)
		}, [ _('Generate') ]));

		return node;
	}
});

const CBIGenText = CBITextValue.extend({
	__name__: 'CBI.GenText',

	renderWidget(/* ... */) {
		let node = CBITextValue.prototype.renderWidget.apply(this, arguments);

		node.appendChild(E('button', {
			class: 'cbi-button cbi-button-add',
			title: _('Generate'),
			click: ui.createHandlerFn(this, handleGenKey, this.hm_options || this.option)
		}, [ _('Generate') ]));

		return node;
	}
});

const CBICopyValue = form.Value.extend({
	__name__: 'CBI.CopyValue',

	readonly: true,

	renderWidget(section_id, option_index, cfgvalue) {
		let node = form.Value.prototype.renderWidget.call(this, section_id, option_index, cfgvalue);

		node.classList.add('control-group');

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
	}
});

const CBIparseYaml = baseclass.extend(/** @lends hm.parseYaml.prototype */ {
	__init__(field, name, cfg) {
		if (isEmpty(cfg))
			return null;

		if (typeof cfg === 'object') {
			this.id = this.calcID(field, name ?? cfg.name);
			this.label = '%s %s'.format(name ?? cfg.name, _('(Imported)'));
		} else {
			this.id = this.calcID(field, name ?? cfg);
			this.label = '%s %s'.format(name ?? cfg, _('(Imported)'));
		}

		this.field = field;
		this.name = name;
		this.cfg = this.key_mapping(cfg);
	},

	key_mapping(cfg) {
		return cfg;
	},

	calcID(field, name) {
		return calcStringMD5(String.format('%s:%s', field, name));
	},

	bool2str(value) {
		if (typeof value !== 'boolean')
			return null;
		return value ? '1' : '0';
	},

	jq(obj, path) {
		return path.split('.').reduce((acc, cur) => acc && acc[cur], obj);
	},

	output() {
		return this.cfg;
	}
});

const CBIHandleImport = baseclass.extend(/** @lends hm.HandleImport.prototype */ {
	__init__(map, section, title, description) {
		this.map = map;
		this.section = section;
		this.title = title ?? '';
		this.description = description ?? '';
		this.placeholder = '';
		this.appendcommand = '';
		this.overridecommand = '';
	},

	handleFn(textarea) {
		const modaltitle = this.section.hm_modaltitle[0];
		const field = this.section.hm_field;

		let content = textarea.getValue().trim();
		let command = this.overridecommand || `.["${field}"]` + this.appendcommand;
		if (['proxy-providers', 'rule-providers'].includes(field))
			content = content.replace(/(\s*payload:)/g, "$1 |-") /* payload to text */

		return yaml2json(content, command).then((res) => {
			let imported_count = 0;
			//let type_file_count = 0;

			//console.info(JSON.stringify(res, null, 2));
			if (!isEmpty(res) && typeof res === 'object') {
				if (Array.isArray(res))
					res.forEach((cfg) => {
						let config = new this.parseYaml(field, null, cfg).output();
						//console.info(JSON.stringify(config, null, 2));
						if (config) {
							this.write(config);
							imported_count++;
						}
					})
				else
					for (let name in res) {
						let config = new this.parseYaml(field, name, res[name]).output();
						//console.info(JSON.stringify(config, null, 2));
						if (config) {
							this.write(config);
							imported_count++;
							//if (config.type === 'file')
							//	type_file_count++;
						}
					}

				if (imported_count === 0)
					ui.addNotification(null, E('p', _('No valid %s found.').format(modaltitle)));
				else
					ui.addNotification(null, E('p', [
						_('Successfully imported %s %s of total %s.')
							.format(imported_count, modaltitle, Object.keys(res).length),
						E('br'),
						//type_file_count ? _("%s rule-set of type '%s' need to be filled in manually.")
						//	.format(type_file_count, 'file') : ''
					]), 'info');
			}

			if (imported_count)
				return this.save();
			else
				return ui.hideModal();
		});
	},

	parseYaml: CBIparseYaml,

	render() {
		const textarea = new ui.Textarea('', {
			placeholder: this.placeholder
		});
		const textareaEl = textarea.render();
		textareaEl.querySelector('textarea').style.fontFamily = monospacefonts.join(',');

		ui.showModal(this.title, [
			E('p', this.description),
			textareaEl,
			E('div', { class: 'right' }, [
				E('button', {
					class: 'btn',
					click: ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					class: 'btn cbi-button-action',
					click: ui.createHandlerFn(this, 'handleFn', textarea)
				}, [ _('Import') ])
			])
		]);
	},

	save() {
		return uci.save()
			.then(L.bind(this.map.load, this.map))
			.then(L.bind(this.map.reset, this.map))
			.then(L.ui.hideModal)
			.catch(() => {});
	},

	write(config) {
		const uciconfig = this.uciconfig || this.section.uciconfig || this.map.config;
		const section_type = this.section.sectiontype;

		let sid = uci.add(uciconfig, section_type, config.id);
		delete config.id;
		for (let k in config)
			uci.set(uciconfig, sid, k, config[k] ?? '');
	}
});

const UIDynamicList = ui.DynamicList.extend({ // @less_25_12
	addItem(dl, value, text, flash) {
		if (this.options.allowduplicates) {
			const new_item = E('div', { class: flash ? 'item flash' : 'item', tabindex: 0, draggable: true }, [
				E('span', {}, [ text ?? value ]),
				E('input', {
					type: 'hidden',
					name: this.options.name,
					value: value })]);

			const ai = dl.querySelector('.add-item');
			ai.parentNode.insertBefore(new_item, ai);
		}

		ui.DynamicList.prototype.addItem.call(this, dl, value, text, flash);
	},

	handleDropdownChange(ev) {
		ui.DynamicList.prototype.handleDropdownChange.call(this, ev);

		if (this.options.allowduplicates) {
			const sbVal = ev.detail.value;
			sbVal?.element.removeAttribute('unselectable');
		}
	}
});

/* Method */
/* thanks to homeproxy */
function calcStringMD5(e) {
	/* Thanks to https://stackoverflow.com/a/41602636 */
	let h = (a, b) => {
		let c, d, e, f, g;
		c = a & 2147483648;
		d = b & 2147483648;
		e = a & 1073741824;
		f = b & 1073741824;
		g = (a & 1073741823) + (b & 1073741823);
		return e & f ? g ^ 2147483648 ^ c ^ d : e | f ? g & 1073741824 ? g ^ 3221225472 ^ c ^ d : g ^ 1073741824 ^ c ^ d : g ^ c ^ d;
	}, k = (a, b, c, d, e, f, g) => h((a = h(a, h(h(b & c | ~b & d, e), g))) << f | a >>> 32 - f, b),
	l = (a, b, c, d, e, f, g) => h((a = h(a, h(h(b & d | c & ~d, e), g))) << f | a >>> 32 - f, b),
	m = (a, b, c, d, e, f, g) => h((a = h(a, h(h(b ^ c ^ d, e), g))) << f | a >>> 32 - f, b),
	n = (a, b, c, d, e, f, g) => h((a = h(a, h(h(c ^ (b | ~d), e), g))) << f | a >>> 32 - f, b),
	p = a => { let b = '', d = ''; for (let c = 0; c <= 3; c++) d = a >>> 8 * c & 255, d = '0' + d.toString(16), b += d.substr(d.length - 2, 2); return b; };

	let f = [], q, r, s, t, a, b, c, d;
	e = (() => {
		e = e.replace(/\r\n/g, '\n');
		let b = '';
		for (let d = 0; d < e.length; d++) {
			let c = e.charCodeAt(d);
			b += c < 128 ? String.fromCharCode(c) : c < 2048 ? String.fromCharCode(c >> 6 | 192) + String.fromCharCode(c & 63 | 128) :
				String.fromCharCode(c >> 12 | 224) + String.fromCharCode(c >> 6 & 63 | 128) + String.fromCharCode(c & 63 | 128);
		}
		return b;
	})();
	f = (() => {
		let c = e.length, a = c + 8, d = 16 * ((a - a % 64) / 64 + 1), b = Array(d - 1), f = 0, g = 0;
		for (; g < c;) a = (g - g % 4) / 4, f = g % 4 * 8, b[a] |= e.charCodeAt(g) << f, g++;
		a = (g - g % 4) / 4, b[a] |= 128 << g % 4 * 8, b[d - 2] = c << 3, b[d - 1] = c >>> 29;
		return b;
	})();

	a = 1732584193, b = 4023233417, c = 2562383102, d = 271733878;
	for (e = 0; e < f.length; e += 16) {
		q = a, r = b, s = c, t = d;
		a = k(a, b, c, d, f[e +  0],  7, 3614090360), d = k(d, a, b, c, f[e +  1], 12, 3905402710),
		c = k(c, d, a, b, f[e +  2], 17,  606105819), b = k(b, c, d, a, f[e +  3], 22, 3250441966),
		a = k(a, b, c, d, f[e +  4],  7, 4118548399), d = k(d, a, b, c, f[e +  5], 12, 1200080426),
		c = k(c, d, a, b, f[e +  6], 17, 2821735955), b = k(b, c, d, a, f[e +  7], 22, 4249261313),
		a = k(a, b, c, d, f[e +  8],  7, 1770035416), d = k(d, a, b, c, f[e +  9], 12, 2336552879),
		c = k(c, d, a, b, f[e + 10], 17, 4294925233), b = k(b, c, d, a, f[e + 11], 22, 2304563134),
		a = k(a, b, c, d, f[e + 12],  7, 1804603682), d = k(d, a, b, c, f[e + 13], 12, 4254626195),
		c = k(c, d, a, b, f[e + 14], 17, 2792965006), b = k(b, c, d, a, f[e + 15], 22, 1236535329),
		a = l(a, b, c, d, f[e +  1],  5, 4129170786), d = l(d, a, b, c, f[e +  6],  9, 3225465664),
		c = l(c, d, a, b, f[e + 11], 14,  643717713), b = l(b, c, d, a, f[e +  0], 20, 3921069994),
		a = l(a, b, c, d, f[e +  5],  5, 3593408605), d = l(d, a, b, c, f[e + 10],  9,   38016083),
		c = l(c, d, a, b, f[e + 15], 14, 3634488961), b = l(b, c, d, a, f[e +  4], 20, 3889429448),
		a = l(a, b, c, d, f[e +  9],  5,  568446438), d = l(d, a, b, c, f[e + 14],  9, 3275163606),
		c = l(c, d, a, b, f[e +  3], 14, 4107603335), b = l(b, c, d, a, f[e +  8], 20, 1163531501),
		a = l(a, b, c, d, f[e + 13],  5, 2850285829), d = l(d, a, b, c, f[e +  2],  9, 4243563512),
		c = l(c, d, a, b, f[e +  7], 14, 1735328473), b = l(b, c, d, a, f[e + 12], 20, 2368359562),
		a = m(a, b, c, d, f[e +  5],  4, 4294588738), d = m(d, a, b, c, f[e +  8], 11, 2272392833),
		c = m(c, d, a, b, f[e + 11], 16, 1839030562), b = m(b, c, d, a, f[e + 14], 23, 4259657740),
		a = m(a, b, c, d, f[e +  1],  4, 2763975236), d = m(d, a, b, c, f[e +  4], 11, 1272893353),
		c = m(c, d, a, b, f[e +  7], 16, 4139469664), b = m(b, c, d, a, f[e + 10], 23, 3200236656),
		a = m(a, b, c, d, f[e + 13],  4,  681279174), d = m(d, a, b, c, f[e +  0], 11, 3936430074),
		c = m(c, d, a, b, f[e +  3], 16, 3572445317), b = m(b, c, d, a, f[e +  6], 23,   76029189),
		a = m(a, b, c, d, f[e +  9],  4, 3654602809), d = m(d, a, b, c, f[e + 12], 11, 3873151461),
		c = m(c, d, a, b, f[e + 15], 16,  530742520), b = m(b, c, d, a, f[e +  2], 23, 3299628645),
		a = n(a, b, c, d, f[e +  0],  6, 4096336452), d = n(d, a, b, c, f[e +  7], 10, 1126891415),
		c = n(c, d, a, b, f[e + 14], 15, 2878612391), b = n(b, c, d, a, f[e +  5], 21, 4237533241),
		a = n(a, b, c, d, f[e + 12],  6, 1700485571), d = n(d, a, b, c, f[e +  3], 10, 2399980690),
		c = n(c, d, a, b, f[e + 10], 15, 4293915773), b = n(b, c, d, a, f[e +  1], 21, 2240044497),
		a = n(a, b, c, d, f[e +  8],  6, 1873313359), d = n(d, a, b, c, f[e + 15], 10, 4264355552),
		c = n(c, d, a, b, f[e +  6], 15, 2734768916), b = n(b, c, d, a, f[e + 13], 21, 1309151649),
		a = n(a, b, c, d, f[e +  4],  6, 4149444226), d = n(d, a, b, c, f[e + 11], 10, 3174756917),
		c = n(c, d, a, b, f[e +  2], 15,  718787259), b = n(b, c, d, a, f[e +  9], 21, 3951481745),
		a = h(a, q), b = h(b, r), c = h(c, s), d = h(d, t);
	}
	return (p(a) + p(b) + p(c) + p(d)).toLowerCase();
}

/* thanks to homeproxy */
function decodeBase64Str(str) {
	if (!str)
		return null;

	/* Thanks to luci-app-ssr-plus */
	str = str.replace(/-/g, '+').replace(/_/g, '/');
	let padding = (4 - (str.length % 4)) % 4;
	if (padding)
		str = str + Array(padding + 1).join('=');

	return decodeURIComponent(Array.prototype.map.call(atob(str), (c) =>
		'%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
	).join(''));
}

function encodeBase64Str(str) {
	if (!str)
		return null;

	let buf = encodeURIComponent(str).split('%').slice(1).map(h => parseInt(h, 16));
	return btoa(String.fromCharCode(...buf));
}

function decodeBase64Bin(str) {
	if (!str)
		return null;

	/* Thanks to luci-app-ssr-plus */
	str = str.replace(/-/g, '+').replace(/_/g, '/');
	let padding = (4 - (str.length % 4)) % 4;
	if (padding)
		str = str + Array(padding + 1).join('=');

	return Array.prototype.map.call(atob(str), c => c.charCodeAt(0)); // OR Uint8Array.fromBase64(str);
}

function encodeBase64Bin(buf) {
	if (isEmpty(buf))
		return null;

	return btoa(String.fromCharCode(...buf)); // OR new Uint8Array(buf).toBase64();
}

function generateRand(type, length) {
	let byteArr;
	if (['base64', 'hex'].includes(type))
		byteArr = crypto.getRandomValues(new Uint8Array(length));
	switch (type) {
		case 'base64':
			/* Thanks to https://stackoverflow.com/questions/9267899 */
			return btoa(String.fromCharCode.apply(null, byteArr));
		case 'hex':
			return Array.from(byteArr, (byte) =>
				(byte & 255).toString(16).padStart(2, '0')
			).join('');
		case 'uuid':
			/* Thanks to https://stackoverflow.com/a/2117523 */
			return (location.protocol === 'https:') ? crypto.randomUUID() :
			([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, (c) =>
				(c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16)
			);
		default:
			return null;
	};
}

function shuffle(StrORArr) {
	let arr;

	if (typeof StrORArr === 'string')
		arr = StrORArr.split('');
	else if (Array.isArray(StrORArr))
		arr = StrORArr;
	else
		throw new Error(`String or Array only`);

    for (let i = arr.length - 1; i > 0; i--) {         // Traverse the array from back to front
        const j = Math.floor(Math.random() * (i + 1)); // Generate a random index between 0 and i

        [arr[i], arr[j]] = [arr[j], arr[i]];           // Swap positions
    }

	if (typeof StrORArr === 'string')
		return arr.join('');
	else if (Array.isArray(StrORArr))
		return arr;
}

function json2yaml(object, command) {
	const callJson2Yaml = rpc.declare({
		object: 'luci.fchomo',
		method: 'json2yaml',
		params: ['content', 'command'],
		expect: { '': {} }
	});

	return callJson2Yaml(typeof object === 'string' ? object : JSON.stringify(object), command).then(res => res.result);
}
function yaml2json(content, command) {
	const callYaml2Json = rpc.declare({
		object: 'luci.fchomo',
		method: 'yaml2json',
		params: ['content', 'command'],
		expect: { '': {} }
	});

	return callYaml2Json(content, command).then(res => res.result);
}

function isEmpty(res) {
	if (res == null) return true;                                                // null, undefined
	if (typeof res === 'string' || Array.isArray(res)) return res.length === 0;  // empty String/Array
	if (typeof res === 'object') {
		if (res instanceof Map || res instanceof Set) return res.size === 0;     // empty Map/Set
		return Object.keys(res).length === 0;                                    // empty Object
	}
	return false;
}

function removeBlankAttrs(res) {
	if (Array.isArray(res)) {
		return res
			.filter(item => !isEmpty(item))
			.map(item => removeBlankAttrs(item));
	}
	if (res !== null && typeof res === 'object') {
		const obj = {};
		for (const key in res) {
			const val = removeBlankAttrs(res[key]);
			if (!isEmpty(val))
				obj[key] = val;
		}
		return obj;
	}
	return res;
}

function toUciname(str) {
	if (isEmpty(str))
		return null;

	const unuciname = new RegExp(/[^a-zA-Z0-9_]+/, "g");

	return str.replace(/[\s\.-]/g, '_').replace(unuciname, '');
}

function getFeatures() {
	const callGetFeatures = rpc.declare({
		object: 'luci.fchomo',
		method: 'get_features',
		expect: { '': {} }
	});

	return L.resolveDefault(callGetFeatures(), {});
}

function getServiceStatus(instance) {
	const conf = 'fchomo';
	const callServiceList = rpc.declare({
		object: 'service',
		method: 'list',
		params: ['name'],
		expect: { '': {} }
	});

	return L.resolveDefault(callServiceList(conf), {})
		.then((res) => {
			let isRunning = false;
			try {
				isRunning = res[conf]['instances'][instance].running;
			} catch (e) {}
			return isRunning;
		});
}

function getClashAPI(instance) {
	const callGetClashAPI = rpc.declare({
		object: 'luci.fchomo',
		method: 'get_clash_api',
		params: ['instance'],
		expect: { '': {} }
	});

	return L.resolveDefault(callGetClashAPI(instance), {});
}

/* thanks to homeproxy */
function loadDefaultLabel(section_id) {
	const label = uci.get(this.config, section_id, 'label');
	if (label) {
		return label;
	} else {
		uci.set(this.config, section_id, 'label', section_id);
		return section_id;
	}
}

/* thanks to homeproxy */
function loadModalTitle(title, addtitle, section_id) {
	const label = uci.get(this.config, section_id, 'label');
	return label ? title + ' » ' + label : addtitle;
}

function loadProxyGroupLabel(preadds, section_id) {
	delete this.keylist;
	delete this.vallist;

	preadds?.forEach((arr) => {
		this.value.apply(this, arr);
	});
	uci.sections(this.config, 'proxy_group', (res) => {
		if (res.enabled !== '0')
			this.value(res['.name'], res.label);
	});

	return this.super('load', section_id);
}

function loadNodeLabel(preadds, section_id) {
	delete this.keylist;
	delete this.vallist;

	preadds?.forEach((arr) => {
		this.value.apply(this, arr);
	});
	uci.sections(this.config, 'node', (res) => {
		if (res.enabled !== '0')
			this.value(res['.name'], res.label);
	});

	return this.super('load', section_id);
}

function loadProviderLabel(preadds, section_id) {
	delete this.keylist;
	delete this.vallist;

	preadds?.forEach((arr) => {
		this.value.apply(this, arr);
	});
	uci.sections(this.config, 'provider', (res) => {
		if (res.enabled !== '0')
			this.value(res['.name'], res.label);
	});

	return this.super('load', section_id);
}

function loadRulesetLabel(preadds, behaviors, section_id) {
	delete this.keylist;
	delete this.vallist;

	preadds?.forEach((arr) => {
		this.value.apply(this, arr);
	});
	uci.sections(this.config, 'ruleset', (res) => {
		if (res.enabled !== '0')
			if (behaviors ? behaviors.includes(res.behavior) : true)
				this.value(res['.name'], res.label);
	});

	return this.super('load', section_id);
}

function loadSubRuleGroup(preadds, section_id) {
	delete this.keylist;
	delete this.vallist;

	preadds?.forEach((arr) => {
		this.value.apply(this, arr);
	});
	let groups = {};
	uci.sections(this.config, 'subrules', (res) => {
		if (res.enabled !== '0')
			groups[res.group] = res.group;
	});
	Object.keys(groups).forEach((group) => {
		this.value(group, group);
	});

	return this.super('load', section_id);
}

function renderStatus(ElId, isRunning, instance, noGlobal) {
	const visible = isRunning && (isRunning.http || isRunning.https);

	return E([
		E('button', {
			class: 'cbi-button cbi-button-apply' + (noGlobal ? ' hidden' : ''),
			click: ui.createHandlerFn(this, handleReload, instance)
		}, [ _('Reload') ]),
		updateStatus(E('span', { id: ElId, style: 'border: unset; font-style: italic; font-weight: bold' }), isRunning ? true : false),
		E('a', {
			class: 'cbi-button cbi-button-apply %s'.format(visible ? '' : 'hidden'),
			href: visible ? getDashURL(isRunning) : '',
			target: '_blank',
			rel: 'noreferrer noopener'
		}, [ _('Open Dashboard') ])
	]);
}
function updateStatus(El, isRunning, instance, noGlobal) {
	if (El) {
		El.style.color = isRunning ? 'green' : 'red';
		El.innerHTML = '&ensp;%s%s&ensp;'.format(noGlobal ? instance + ' ' : '', isRunning ? _('Running') : _('Not Running'));
		/* Dashboard button */
		if (El.nextSibling?.localName === 'a')
			getClashAPI(instance).then((res) => {
				let visible = isRunning && (res.http || res.https);
				if (visible) {
					El.nextSibling.classList.remove('hidden');
				} else
					El.nextSibling.classList.add('hidden');

				El.nextSibling.href = visible ? getDashURL(Object.assign(res, isRunning)) : '';
			});
	}

	return El;
}
function getDashURL(isRunning) {
	const tls = isRunning.https ? 's' : '';
	const host = window.location.hostname;
	const port = isRunning.https ? isRunning.https.split(':').pop() : isRunning.http.split(':').pop();
	const secret = isRunning.secret;
	const repo = isRunning.dashboard_repo;

	return 'http%s://%s:%s/ui/'.format(tls, host, port) +
		String.format(dashrepos_urlparams[repo] || '', host, port, secret)
}

function renderResDownload(section_id) {
	const section_type = this.section.sectiontype;
	const type = uci.get(this.config, section_id, 'type');
	const url = uci.get(this.config, section_id, 'url');
	const header = uci.get(this.config, section_id, 'header');

	let El = E([
		E('button', {
			class: 'cbi-button cbi-button-add',
			disabled: (type !== 'http') || null,
			click: ui.createHandlerFn(this, (section_type, section_id, type, url, header) => {
				if (type === 'http') {
					return downloadFile(section_type, section_id, url, header).then((res) => {
						ui.addNotification(null, E('p', _('Download successful.')), 'info');
					}).catch((e) => {
						ui.addNotification(null, E('p', _('Download failed: %s').format(e)), 'error');
					});
				} else
					return ui.addNotification(null, E('p', _('Unable to download unsupported type: %s').format(type)), 'error');
			}, section_type, section_id, type, url, header)
		}, [ _('🡇') ]) //🗘
	]);

	return El;
}

function handleGenKey(option) {
	const section_id = this.section.section;
	const type = this.section.getOption('type')?.formvalue(section_id);
	const widget = L.bind(function(option) {
		return this.map.findElement('id', 'widget.' + this.cbid(section_id).replace(/\.[^\.]+$/, '.') + option);
	}, this);

	const callMihomoGenerator = rpc.declare({
		object: 'luci.fchomo',
		method: 'mihomo_generator',
		params: ['type', 'params'],
		expect: { '': {} }
	});

	if (typeof option === 'object') {
		return callMihomoGenerator(option.type, option.params).then((res) => {
			if (res.result)
				option.callback.call(this, res.result).forEach(([k, v]) => {
					widget(k).value = v ?? '';
				});
			else
				ui.addNotification(null, E('p', _('Failed to generate %s, error: %s.').format(type, res.error)), 'error');
		});
	} else {
		let password, required_method;

		if (option === 'uuid' || option.match(/_uuid/))
			required_method = 'uuid';
		else if (option.match(/sudoku_custom_table/))
			required_method = 'sudoku_custom_table';
		else if (type === 'shadowsocks' && option === 'shadowsocks_password')
			required_method = this.section.getOption('shadowsocks_chipher')?.formvalue(section_id);
		else if (type === 'trojan' && option === 'trojan_ss_password')
			required_method = this.section.getOption('trojan_ss_chipher')?.formvalue(section_id);

		switch (required_method) {
			/* NONE */
			case 'none':
				password = '';
				break;
			/* UUID */
			case 'uuid':
				password = generateRand('uuid');
				break;
			/* SUDOKU CUSTOM TABLE */
			case 'sudoku_custom_table':
				password = shuffle('xxppvvvv');
				break;
			/* DEFAULT */
			default:
				password = generateRand('hex', 32/2);
				break;
		}
		/* AEAD */
		(function(length) {
			if (length && length > 0)
				password = generateRand('base64', length);
		}(aead_cipher_length[required_method]));

		return widget(option).value = password;
	}
}

function handleReload(instance, ev, section_id) {
	instance = instance || '';
	return fs.exec('/etc/init.d/fchomo', ['reload', instance])
		.then((res) => { /* return window.location = window.location.href.split('#')[0] */ })
		.catch((e) => {
			ui.addNotification(null, E('p', _('Failed to execute "/etc/init.d/fchomo %s %s" reason: %s').format('reload', instance, e)), 'error')
		})
}

function handleRemoveIdles() {
	const section_type = this.sectiontype;

	let loaded = [];
	uci.sections(this.config, section_type, (section, sid) => loaded.push(sid));

	return lsDir(section_type).then((res) => {
		let sectionEl = E('div', { class: 'cbi-section' }, []);

		res.filter(e => !loaded.includes(e)).forEach((filename) => {
			sectionEl.appendChild(E('div', { class: 'cbi-value' }, [
				E('label', {
					class: 'cbi-value-title',
					id: 'rmidles.' + filename + '.label'
				}, [ filename ]),
				E('div', { class: 'cbi-value-field' }, [
					E('button', {
						class: 'cbi-button cbi-button-negative important',
						id: 'rmidles.' + filename + '.button',
						click: ui.createHandlerFn(this, (filename) => {
							return removeFile(section_type, filename).then((res) => {
								let node = document.getElementById('rmidles.' + filename + '.label');
								node.innerHTML = '<s>%s</s>'.format(node.innerHTML);
								node = document.getElementById('rmidles.' + filename + '.button');
								node.classList.add('hidden');
							});
						}, filename)
					}, [ _('Remove') ])
				])
			]));
		});

		ui.showModal(_('Remove idles'), [
			sectionEl,
			E('div', { class: 'right' }, [
				E('button', {
					class: 'btn cbi-button-action',
					click: ui.hideModal
				}, [ _('Complete') ])
			])
		]);
	});
}

function textvalue2Value(section_id) {
	let cval = this.cfgvalue(section_id);
	let i = this.keylist.indexOf(cval);

	return this.vallist[i];
}

function validateAuth(section_id, value) {
	if (!value)
		return true;
	if (!value.match(/^[\w-]{3,}:[^:]+$/))
		return _('Expecting: %s').format('[A-Za-z0-9_-]{3,}:[^:]+');

	return true;
}
function validateAuthUsername(section_id, value) {
	if (!value)
		return true;
	if (!value.match(/^[\w-]{3,}$/))
		return _('Expecting: %s').format('[A-Za-z0-9_-]{3,}');

	return true;
}
function validateAuthPassword(section_id, value) {
	if (!value)
		return true;
	if (!value.match(/^[^:]+$/))
		return _('Expecting: %s').format('[^:]+');

	return true;
}

function validateCommonPort(section_id, value) {
	/* thanks to homeproxy */
	let stubValidator = {
		factory: validation,
		apply(type, value, args) {
			if (value != null)
				this.value = value;

			return validation.types[type].apply(this, args);
		},
		assert(condition) {
			return !!condition;
		}
	};

	const arr = value.trim().split(' ');

	if (arr.length === 0 || arr.includes(''))
		return _('Expecting: %s').format(_('non-empty value'));

	if (arr.length > 1 && arr.includes('all'))
		return _('Expecting: %s').format(_('If All ports is selected, uncheck others'));

	for (let custom of arr) {
		if (!routing_port_type.map(e => e[0]).includes(custom)) {
			let ports = [];
			for (let i of custom.split(',')) {
				if (!stubValidator.apply('port', i) && !stubValidator.apply('portrange', i))
					return _('Expecting: %s').format(_('valid port value'));
				if (ports.includes(i))
					return _('Port %s alrealy exists!').format(i);
				ports = ports.concat(i);
			}
		}
	}

	return true;
}

function validateBytesize(section_id, value) {
	if (!value)
		return true;

	if (!value.match(/^(\d+)(k|m|g)?b?$/))
		return _('Expecting: %s').format('^(\\d+)(k|m|g)?b?$');

	return true;
}
function validateTimeDuration(section_id, value) {
	if (!value)
		return true;

	if (!value.match(/^(\d+)(s|m|h|d)?$/))
		return _('Expecting: %s').format('^(\\d+)(s|m|h|d)?$');

	return true;
}

function validateJson(section_id, value) {
	if (!value)
		return true;

	try {
		let obj = JSON.parse(value.trim());
		if (!obj)
			return _('Expecting: %s').format(_('valid JSON format'));
	}
	catch(e) {
		return _('Expecting: %s').format(_('valid JSON format'));
	}

	return true;
}

function validateUUID(section_id, value) {
	if (!value)
		return true;
	else if (value.match('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') === null)
		return _('Expecting: %s').format(_('valid uuid'));

	return true;
}

function validateUrl(section_id, value) {
	if (!value)
		return true;

	try {
		let url = new URL(value);
		if (!url.hostname)
			return _('Expecting: %s').format(_('valid URL'));
	}
	catch(e) {
		return _('Expecting: %s').format(_('valid URL'));
	}

	return true;
}

function validateBase64Key(length, section_id, value) {
	/* Thanks to luci-proto-wireguard */
	if (value)
		if (value.length !== length || !value.match(/^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/) || value[length-1] !== '=')
			return _('Expecting: %s').format(_('valid base64 key with %d characters').format(length));

	return true;
}

function validateMTLSClientAuth(type_option, section_id, value) {
	// If `client-auth-type` is set to "verify-if-given" or "require-and-verify", `client-auth-cert` must not be empty.
	const auth_type = this.section.getOption(type_option).formvalue(section_id);
					//this.section.getUIElement('tls_client_auth_type').getValue();
	if (!value && ["verify-if-given", "require-and-verify"].includes(auth_type))
		return _('Expecting: %s').format(_('non-empty value'));

	return true;
}

function validatePresetIDs(disoption_list, section_id) {
	let node;
	let hm_prefmt = glossary[this.section.sectiontype].prefmt;
	let preset_ids = [
		'fchomo_direct_list',
		'fchomo_proxy_list',
		'fchomo_china_list',
		'fchomo_gfw_list'
	];

	if (preset_ids.map((v) => hm_prefmt.format(v)).includes(section_id)) {
		disoption_list.forEach(([typ, opt]) => {
			node = this.section.getUIElement(section_id, opt)?.node;
			(typ ? node?.querySelector(typ) : node)?.setAttribute(typ === 'textarea' ? 'readOnly' : 'disabled', '');
		});

		this.map.findElement('id', 'cbi-fchomo-' + section_id)?.lastChild.querySelector('.cbi-button-remove')?.remove();
	}

	return true;
}

function validateShadowsocksPassword(encmode, section_id, value) {
	let length = aead_cipher_length[encmode];
	if (typeof length !== 'undefined') {
		length = Math.ceil(length/3)*4;
		if (encmode.match(/^2022-/)) {
			return validateBase64Key.call(this, length, section_id, value);
		} else {
			if (length === 0 && !value)
				return _('Expecting: %s').format(_('non-empty value'));
			if (length !== 0 && value.length !== length)
				return _('Expecting: %s').format(_('valid key length with %d characters').format(length));
		}
	} else
		return true;

	return true;
}

function validateSudokuCustomTable(section_id, value) {
	if (!value)
		return true;

	if (value.length !== 8)
		return _('Expecting: %s').format(_('valid format: 2x, 2p, 4v'));

	const counts = {};
    for (const c of value)
        counts[c] = (counts[c] || 0) + 1;
    if (!(counts.x === 2 && counts.p === 2 && counts.v === 4))
		return _('Expecting: %s').format(_('valid format: 2x, 2p, 4v'));

	return true;
}

function validateUniqueValue(section_id, value) {
	if (!value)
		return _('Expecting: %s').format(_('non-empty value'));

	let duplicate = false;
	uci.sections(this.config, this.section.sectiontype, (res) => {
		if (res['.name'] !== section_id)
			if (res[this.option] === value)
				duplicate = true;
	});
	if (duplicate)
		return _('Expecting: %s').format(_('unique value'));

	return true;
}

function lsDir(type) {
	const callLsDir = rpc.declare({
		object: 'luci.fchomo',
		method: 'dir_ls',
		params: ['type'],
		expect: { '': {} }
	});

	return L.resolveDefault(callLsDir(type), {}).then((res) => {
		if (res.result) {
			return res.result;
		} else
			throw res.error || 'unknown error';
	});
}

function readFile(type, filename) {
	const callReadFile = rpc.declare({
		object: 'luci.fchomo',
		method: 'file_read',
		params: ['type', 'filename'],
		expect: { '': {} }
	});

	return L.resolveDefault(callReadFile(type, filename), {}).then((res) => {
		if (res.content ?? true) {
			return res.content;
		} else
			throw res.error || 'unknown error';
	});
}

function writeFile(type, filename, content) {
	const callWriteFile = rpc.declare({
		object: 'luci.fchomo',
		method: 'file_write',
		params: ['type', 'filename', 'content'],
		expect: { '': {} }
	});

	return L.resolveDefault(callWriteFile(type, filename, content), {}).then((res) => {
		if (res.result) {
			return res.result;
		} else
			throw res.error || 'unknown error';
	});
}

function downloadFile(type, filename, url, header) {
	const callDownloadFile = rpc.declare({
		object: 'luci.fchomo',
		method: 'file_download',
		params: ['type', 'filename', 'url', 'header'],
		expect: { '': {} }
	});

	return L.resolveDefault(callDownloadFile(type, filename, url, header), {}).then((res) => {
		if (res.result) {
			return res.result;
		} else
			throw res.error || 'unknown error';
	});
}

function removeFile(type, filename) {
	const callRemoveFile = rpc.declare({
		object: 'luci.fchomo',
		method: 'file_remove',
		params: ['type', 'filename'],
		expect: { '': {} }
	});

	return L.resolveDefault(callRemoveFile(type, filename), {}).then((res) => {
		if (res.result) {
			return res.result;
		} else
			throw res.error || 'unknown error';
	});
}

/* thanks to homeproxy */
function uploadCertificate(type, filename, ev) {
	const callWriteCertificate = rpc.declare({
		object: 'luci.fchomo',
		method: 'certificate_write',
		params: ['filename'],
		expect: { '': {} }
	});

	return ui.uploadFile('/tmp/fchomo_certificate.tmp', ev.target)
	.then(L.bind((btn, res) => {
		return L.resolveDefault(callWriteCertificate(filename), {}).then((ret) => {
			if (ret.result === true)
				ui.addNotification(null, E('p', _('Your %s was successfully uploaded. Size: %sB.').format(type, res.size)), 'info');
			else
				ui.addNotification(null, E('p', _('Failed to upload %s, error: %s.').format(type, ret.error)), 'error');
		});
	}, this, ev.target))
	.catch((e) => { ui.addNotification(null, E('p', e.message), 'error') });
}
function uploadInitialPack(ev, section_id) {
	const callWriteInitialPack = rpc.declare({
		object: 'luci.fchomo',
		method: 'initialpack_write',
		expect: { '': {} }
	});

	return ui.uploadFile('/tmp/fchomo_initialpack.tmp', ev.target)
	.then(L.bind((btn, res) => {
		return L.resolveDefault(callWriteInitialPack(), {}).then((ret) => {
			if (ret.result === true) {
				ui.addNotification(null, E('p', _('Successfully uploaded.')), 'info');
				return window.location = window.location.href.split('#')[0];
			} else
				ui.addNotification(null, E('p', _('Failed to upload, error: %s.').format(ret.error)), 'error');
		});
	}, this, ev.target))
	.catch((e) => { ui.addNotification(null, E('p', e.message), 'error') });
}

return baseclass.extend({
	/* Member */
	rulesetdoc,
	sharkaudio,
	sharktaikogif,
	less_25_12,
	HM_DIR,
	monospacefonts,
	checkurls,
	stunserver,
	dashrepos,
	dashrepos_urlparams,
	log_levels,
	glossary,
	health_checkurls,
	inbound_type,
	ip_version,
	load_balance_strategy,
	outbound_type,
	preset_outbound,
	proxy_group_type,
	routing_port_type,
	rules_type,
	rules_type_allowparms,
	rules_logical_type,
	rules_logical_payload_count,
	aead_cipher_length,
	shadowsocks_cipher_methods,
	sudoku_cipher_methods,
	trojan_cipher_methods,
	tls_client_auth_types,
	tls_client_fingerprints,
	vless_encryption,
	vless_flow,

	/* Prototype */
	GridSection: CBIGridSection,
	DynamicList: CBIDynamicList,
	StaticList: CBIStaticList,
	ListValue: CBIListValue,
	RichValue: CBIRichValue,
	RichMultiValue: CBIRichMultiValue,
	TextValue: CBITextValue,
	GenValue: CBIGenValue,
	GenText: CBIGenText,
	CopyValue: CBICopyValue,
	parseYaml: CBIparseYaml,
	HandleImport: CBIHandleImport,

	/* Method */
	calcStringMD5,
	decodeBase64Str,
	encodeBase64Str,
	decodeBase64Bin,
	encodeBase64Bin,
	generateRand,
	shuffle,
	json2yaml,
	yaml2json,
	isEmpty,
	removeBlankAttrs,
	toUciname,
	getFeatures,
	getServiceStatus,
	getClashAPI,
	// load
	loadDefaultLabel,
	loadModalTitle,
	loadProxyGroupLabel,
	loadNodeLabel,
	loadProviderLabel,
	loadRulesetLabel,
	loadSubRuleGroup,
	// render
	renderStatus,
	updateStatus,
	getDashURL,
	renderResDownload,
	handleGenKey,
	handleReload,
	handleRemoveIdles,
	textvalue2Value,
	// validate
	validateAuth,
	validateAuthUsername,
	validateAuthPassword,
	validateCommonPort,
	validateBytesize,
	validateTimeDuration,
	validateJson,
	validateUUID,
	validateUrl,
	// validate with bind this
	validateBase64Key,
	validateMTLSClientAuth,
	validatePresetIDs,
	validateShadowsocksPassword,
	validateSudokuCustomTable,
	validateUniqueValue,
	// file operations
	lsDir,
	readFile,
	writeFile,
	downloadFile,
	removeFile,
	uploadCertificate,
	uploadInitialPack,
});
