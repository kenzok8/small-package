'use strict';
'require baseclass';
'require form';
'require fs';
'require rpc';
'require uci';
'require ui';
'require validation';

var rulesetdoc = 'data:text/html;base64,' + 'cmxzdHBsYWNlaG9sZGVy';

var sharktaikogif = function() {
	return 'data:image/gif;base64,' +
'c2hhcmstdGFpa28uZ2lm'
}()

return baseclass.extend({
	rulesetdoc: rulesetdoc,
	sharktaikogif: sharktaikogif,

	monospacefonts: [
		'"Cascadia Code"',
		'"Cascadia Mono"',
		'Menlo',
		'Monaco',
		'Consolas',
		'"Liberation Mono"',
		'"Courier New"',
		'monospace'
	],

	dashrepos: [
		['zephyruso/zashboard', _('zashboard')],
		['metacubex/metacubexd', _('metacubexd')],
		['metacubex/yacd-meta', _('yacd-meta')],
		['metacubex/razord-meta', _('razord-meta')]
	],

	dashrepos_urlparams: {
		'zephyruso/zashboard':   '#/setup' + '?hostname=%s&port=%s&secret=%s',
		'metacubex/metacubexd':  '#/setup' + '?hostname=%s&port=%s&secret=%s',
		'metacubex/yacd-meta':   '?hostname=%s&port=%s&secret=%s',
		'metacubex/razord-meta': '?host=%s&port=%s&secret=%s'
	},

	checkurls: [
		['https://www.baidu.com', _('Baidu')],
		['https://s1.music.126.net/style/favicon.ico', _('163Music')],
		['https://www.google.com/generate_204', _('Google')],
		['https://github.com', _('GitHub')],
		['https://www.youtube.com', _('YouTube')]
	],

	health_checkurls: [
		['https://cp.cloudflare.com'],
		['https://www.gstatic.com/generate_204']
	],

	inbound_type: [
		['http', _('HTTP')],
		['socks', _('SOCKS')],
		['mixed', _('Mixed')],
		['shadowsocks', _('Shadowsocks')],
		['vmess', _('VMess')],
		['tuic', _('TUIC')],
		['hysteria2', _('Hysteria2')],
		//['tunnel', _('Tunnel')]
	],

	ip_version: [
		['', _('Keep default')],
		['dual', _('Dual stack')],
		['ipv4', _('IPv4 only')],
		['ipv6', _('IPv6 only')],
		['ipv4-prefer', _('Prefer IPv4')],
		['ipv6-prefer', _('Prefer IPv6')]
	],

	load_balance_strategy: [
		['round-robin', _('Simple round-robin all nodes')],
		['consistent-hashing', _('Same dstaddr requests. Same node')],
		['sticky-sessions', _('Same srcaddr and dstaddr requests. Same node')]
	],

	outbound_type: [
		['direct', _('DIRECT')],
		['http', _('HTTP')],
		['socks5', _('SOCKS5')],
		['ss', _('Shadowsocks')],
		//['ssr', _('ShadowsocksR')], // Deprecated
		['mieru', _('Mieru')],
		['snell', _('Snell')],
		['vmess', _('VMess')],
		['vless', _('VLESS')],
		['trojan', _('Trojan')],
		//['hysteria', _('Hysteria')],
		['hysteria2', _('Hysteria2')],
		['tuic', _('TUIC')],
		['wireguard', _('WireGuard')],
		['ssh', _('SSH')]
	],

	preset_outbound: {
		full: [
			['DIRECT'],
			['REJECT'],
			['REJECT-DROP'],
			['PASS'],
			['COMPATIBLE']
		],
		direct: [
			['', _('null')],
			['DIRECT']
		],
		dns: [
			['', 'RULES'],
			['DIRECT']
		]
	},

	proxy_group_type: [
		['select', _('Select')],
		['fallback', _('Fallback')],
		['url-test', _('URL test')],
		['load-balance', _('Load balance')],
		//['relay', _('Relay')], // Deprecated
	],

	rules_type: [
		['DOMAIN'],
		['DOMAIN-SUFFIX'],
		['DOMAIN-KEYWORD'],
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
		//['UID'],

		['NETWORK'],
		['DSCP'],

		['RULE-SET'],

		['MATCH']
	],

	rules_logical_type: [
		['AND'],
		['OR'],
		['NOT'],
		//['SUB-RULE'],
	],

	rules_logical_payload_count: {
		'AND': { low: 2, high: undefined },
		'OR': { low: 2, high: undefined },
		'NOT': { low: 1, high: 1 },
		//'SUB-RULE': 0,
	},

	shadowsocks_cipher_methods: [
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
	],

	shadowsocks_cipher_length: {
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
	},

	stunserver: [
		['stun.fitauto.ru:3478'],
		['stun.hot-chilli.net:3478'],
		['stun.pure-ip.com:3478'],
		['stun.voipgate.com:3478'],
		['stun.voipia.net:3478'],
		['stunserver2024.stunprotocol.org:3478']
	],

	tls_client_fingerprints: [
		['chrome'],
		['firefox'],
		['safari'],
		['iOS'],
		['android'],
		['edge'],
		['360'],
		['qq'],
		['random']
	],

	// thanks to homeproxy
	CBIStaticList: form.DynamicList.extend({
		__name__: 'CBI.StaticList',

		renderWidget: function(/* ... */) {
			var dl = form.DynamicList.prototype.renderWidget.apply(this, arguments);
			dl.querySelector('.add-item ul > li[data-value="-"]').remove();
			return dl;
		}
	}),

	// thanks to homeproxy
	calcStringMD5: function(e) {
		/* Thanks to https://stackoverflow.com/a/41602636 */
		function h(a, b) {
			var c, d, e, f, g;
			e = a & 2147483648;
			f = b & 2147483648;
			c = a & 1073741824;
			d = b & 1073741824;
			g = (a & 1073741823) + (b & 1073741823);
			return c & d ? g ^ 2147483648 ^ e ^ f : c | d ? g & 1073741824 ? g ^ 3221225472 ^ e ^ f : g ^ 1073741824 ^ e ^ f : g ^ e ^ f;
		}
		function k(a, b, c, d, e, f, g) { a = h(a, h(h(b & c | ~b & d, e), g)); return h(a << f | a >>> 32 - f, b); }
		function l(a, b, c, d, e, f, g) { a = h(a, h(h(b & d | c & ~d, e), g)); return h(a << f | a >>> 32 - f, b); }
		function m(a, b, d, c, e, f, g) { a = h(a, h(h(b ^ d ^ c, e), g)); return h(a << f | a >>> 32 - f, b); }
		function n(a, b, d, c, e, f, g) { a = h(a, h(h(d ^ (b | ~c), e), g)); return h(a << f | a >>> 32 - f, b); }
		function p(a) {
			var b = '', d = '';
			for (var c = 0; 3 >= c; c++) d = a >>> 8 * c & 255, d = '0' + d.toString(16), b += d.substr(d.length - 2, 2);
			return b;
		}

		var f = [], q, r, s, t, a, b, c, d;
		e = function(a) {
			a = a.replace(/\r\n/g, '\n');
			for (var b = '', d = 0; d < a.length; d++) {
				var c = a.charCodeAt(d);
				128 > c ? b += String.fromCharCode(c) : (127 < c && 2048 > c ? b += String.fromCharCode(c >> 6 | 192) :
					(b += String.fromCharCode(c >> 12 | 224), b += String.fromCharCode(c >> 6 & 63 | 128)),
						b += String.fromCharCode(c & 63 | 128))
			}
			return b;
		}(e);
		f = function(b) {
			var c = b.length, a = c + 8;
			for (var d = 16 * ((a - a % 64) / 64 + 1), e = Array(d - 1), f = 0, g = 0; g < c;)
				a = (g - g % 4) / 4, f = g % 4 * 8, e[a] |= b.charCodeAt(g) << f, g++;
			a = (g - g % 4) / 4; e[a] |= 128 << g % 4 * 8; e[d - 2] = c << 3; e[d - 1] = c >>> 29;
			return e;
		}(e);
		a = 1732584193;
		b = 4023233417;
		c = 2562383102;
		d = 271733878;

		for (e = 0; e < f.length; e += 16) q = a, r = b, s = c, t = d,
			a = k(a, b, c, d, f[e +  0],  7, 3614090360), d = k(d, a, b, c, f[e +  1], 12, 3905402710),
			c = k(c, d, a, b, f[e +  2], 17,  606105819), b = k(b, c, d, a, f[e +  3], 22, 3250441966),
			a = k(a, b, c, d, f[e +  4], 7,  4118548399), d = k(d, a, b, c, f[e +  5], 12, 1200080426),
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
		return (p(a) + p(b) + p(c) + p(d)).toLowerCase();
	},

	// thanks to homeproxy
	decodeBase64Str: function(str) {
		if (!str)
			return null;

		/* Thanks to luci-app-ssr-plus */
		str = str.replace(/-/g, '+').replace(/_/g, '/');
		var padding = (4 - (str.length % 4)) % 4;
		if (padding)
			str = str + Array(padding + 1).join('=');

		return decodeURIComponent(Array.prototype.map.call(atob(str), (c) =>
			'%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
		).join(''));
	},

	generateRand: function(type, length) {
		var byteArr;
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
	},

	removeBlankAttrs: function(self, res) {
		let content;

		if (res?.constructor === Object) {
			content = {};
			Object.keys(res).map((k) => {
				if ([Array, Object].includes(res[k]?.constructor))
					content[k] = self.removeBlankAttrs(self, res[k]);
				else if (res[k] !== null && res[k] !== '')
					content[k] = res[k];
			});
		} else if (res?.constructor === Array) {
			content = [];
			res.map((k, i) => {
				if ([Array, Object].includes(k?.constructor))
					content.push(self.removeBlankAttrs(self, k));
				else if (k !== null && k !== '')
					content.push(k);
			});
		} else
			return res;

		return content;
	},

	getFeatures: function() {
		const callGetFeatures = rpc.declare({
			object: 'luci.fchomo',
			method: 'get_features',
			expect: { '': {} }
		});

		return L.resolveDefault(callGetFeatures(), {});
	},

	getServiceStatus: function(instance) {
		var conf = 'fchomo';
		const callServiceList = rpc.declare({
			object: 'service',
			method: 'list',
			params: ['name'],
			expect: { '': {} }
		});

		return L.resolveDefault(callServiceList(conf), {})
			.then((res) => {
				var isRunning = false;
				try {
					isRunning = res[conf]['instances'][instance].running;
				} catch (e) {}
				return isRunning;
			});
	},

	getClashAPI: function(instance) {
		const callGetClashAPI = rpc.declare({
			object: 'luci.fchomo',
			method: 'get_clash_api',
			params: ['instance'],
			expect: { '': {} }
		});

		return L.resolveDefault(callGetClashAPI(instance), {});
	},

	// thanks to homeproxy
	loadDefaultLabel: function(section_id) {
		var label = uci.get(this.config, section_id, 'label');
		if (label) {
			return label;
		} else {
			uci.set(this.config, section_id, 'label', section_id);
			return section_id;
		}
	},

	// thanks to homeproxy
	loadModalTitle: function(title, addtitle, section_id) {
		var label = uci.get(this.config, section_id, 'label');
		return label ? title + ' » ' + label : addtitle;
	},

	loadProxyGroupLabel: function(preadds, section_id) {
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
	},

	loadNodeLabel: function(section_id) {
		delete this.keylist;
		delete this.vallist;

		this.value('', _('-- Please choose --'));
		uci.sections(this.config, 'node', (res) => {
			if (res.enabled !== '0')
				this.value(res['.name'], res.label);
		});

		return this.super('load', section_id);
	},

	loadProviderLabel: function(section_id) {
		delete this.keylist;
		delete this.vallist;

		this.value('', _('-- Please choose --'));
		uci.sections(this.config, 'provider', (res) => {
			if (res.enabled !== '0')
				this.value(res['.name'], res.label);
		});

		return this.super('load', section_id);
	},

	loadRulesetLabel: function(behaviors, section_id) {
		delete this.keylist;
		delete this.vallist;

		this.value('', _('-- Please choose --'));
		uci.sections(this.config, 'ruleset', (res) => {
			if (res.enabled !== '0')
				if (behaviors ? behaviors.includes(res.behavior) : true)
					this.value(res['.name'], res.label);
		});

		return this.super('load', section_id);
	},

	loadSubRuleGroup: function(section_id) {
		delete this.keylist;
		delete this.vallist;

		this.value('', _('-- Please choose --'));
		let groups = {};
		uci.sections(this.config, 'subrules', (res) => {
			if (res.enabled !== '0')
				groups[res.group] = res.group;
		});
		Object.keys(groups).forEach((group) => {
			this.value(group, group);
		});

		return this.super('load', section_id);
	},

	renderStatus: function(self, ElId, isRunning, instance, noGlobal) {
		var visible = isRunning && (isRunning.http || isRunning.https);

		return E([
			E('button', {
				'class': 'cbi-button cbi-button-apply' + (noGlobal ? ' hidden' : ''),
				'click': ui.createHandlerFn(this, self.handleReload, instance)
			}, [ _('Reload') ]),
			self.updateStatus(self, E('span', { id: ElId, style: 'border: unset; font-style: italic; font-weight: bold' }), isRunning ? true : false),
			E('a', {
				'class': 'cbi-button cbi-button-apply %s'.format(visible ? '' : 'hidden'),
				'href': visible ? self.getDashURL(self, isRunning) : '',
				'target': '_blank',
				'rel': 'noreferrer noopener'
			}, [ _('Open Dashboard') ])
		]);
	},
	updateStatus: function(self, El, isRunning, instance, noGlobal) {
		if (El) {
			El.style.color = isRunning ? 'green' : 'red';
			El.innerHTML = '&ensp;%s%s&ensp;'.format(noGlobal ? instance + ' ' : '', isRunning ? _('Running') : _('Not Running'));
			/* Dashboard button */
			if (El.nextSibling?.localName === 'a')
				self.getClashAPI(instance).then((res) => {
					let visible = isRunning && (res.http || res.https);
					if (visible) {
						El.nextSibling.classList.remove('hidden');
					} else
						El.nextSibling.classList.add('hidden');

					El.nextSibling.href = visible ? self.getDashURL(self, Object.assign(res, isRunning)) : '';
				});
		}

		return El;
	},
	getDashURL: function(self, isRunning) {
		var tls = isRunning.https ? 's' : '',
			host = window.location.hostname,
			port = isRunning.https ? isRunning.https.split(':').pop() : isRunning.http.split(':').pop(),
			secret = isRunning.secret,
			repo = isRunning.dashboard_repo;

		return 'http%s://%s:%s/ui/'.format(tls, host, port) +
			String.format(self.dashrepos_urlparams[repo] || '', host, port, secret)
	},

	renderResDownload: function(self, section_id) {
		var section_type = this.section.sectiontype;
		var type = uci.get(this.config, section_id, 'type'),
			url = uci.get(this.config, section_id, 'url'),
			header = uci.get(this.config, section_id, 'header');

		var El = E([
			E('button', {
				class: 'cbi-button cbi-button-add',
				disabled: (type !== 'http') || null,
				click: ui.createHandlerFn(this, function(section_type, section_id, type, url, header) {
					if (type === 'http') {
						return self.downloadFile(section_type, section_id, url, header).then((res) => {
							ui.addNotification(null, E('p', _('Download successful.')));
						}).catch((e) => {
							ui.addNotification(null, E('p', _('Download failed: %s').format(e)));
						});
					} else
						return ui.addNotification(null, E('p', _('Unable to download unsupported type: %s').format(type)));
				}, section_type, section_id, type, url, header)
			}, [ _('🡇') ]) //🗘
		]);

		return El;
	},

	renderSectionAdd: function(prefmt, LC, extra_class) {
		var el = form.GridSection.prototype.renderSectionAdd.apply(this, [ extra_class ]),
			nameEl = el.querySelector('.cbi-section-create-name');
		ui.addValidator(nameEl, 'uciname', true, (v) => {
			var button = el.querySelector('.cbi-section-create > .cbi-button-add');
			var prefix = prefmt?.prefix ? prefmt.prefix : '',
				suffix = prefmt?.suffix ? prefmt.suffix : '';

			if (!v) {
				button.disabled = true;
				return true;
			} else if (LC && (v !== v.toLowerCase())) {
				button.disabled = true;
				return _('Expecting: %s').format(_('Lowercase only'));
			} else if (uci.get(this.config, v)) {
				button.disabled = true;
				return _('Expecting: %s').format(_('unique UCI identifier'));
			} else if (uci.get(this.config, prefix + v + suffix)) {
				button.disabled = true;
				return _('Expecting: %s').format(_('unique identifier'));
			} else {
				button.disabled = null;
				return true;
			}
		}, 'blur', 'keyup');

		return el;
	},

	handleAdd: function(prefmt, ev, name) {
		var prefix = prefmt?.prefix ? prefmt.prefix : '',
			suffix = prefmt?.suffix ? prefmt.suffix : '';

		return form.GridSection.prototype.handleAdd.apply(this, [ ev, prefix + name + suffix ]);
	},

	handleReload: function(instance, ev, section_id) {
		var instance = instance || '';
		return fs.exec('/etc/init.d/fchomo', ['reload', instance])
			.then((res) => { /* return window.location = window.location.href.split('#')[0] */ })
			.catch((e) => {
				ui.addNotification(null, E('p', _('Failed to execute "/etc/init.d/fchomo %s %s" reason: %s').format('reload', instance, e)))
			})
	},

	handleRemoveIdles: function(self) {
		var section_type = this.sectiontype;

		let loaded = [];
		uci.sections(this.config, section_type, (section, sid) => loaded.push(sid));

		return self.lsDir(section_type).then((res) => {
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
							click: ui.createHandlerFn(this, function(filename) {
								return self.removeFile(section_type, filename).then((res) => {
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
	},

	textvalue2Value: function(section_id) {
		var cval = this.cfgvalue(section_id);
		var i = this.keylist.indexOf(cval);

		return this.vallist[i];
	},

	validateAuth: function(section_id, value) {
		if (!value)
			return true;
		if (!value.match(/^[\w-]{3,}:[^:]+$/))
			return _('Expecting: %s').format('[A-Za-z0-9_-]{3,}:[^:]+');

		return true;
	},
	validateAuthUsername: function(section_id, value) {
		if (!value)
			return true;
		if (!value.match(/^[\w-]{3,}$/))
			return _('Expecting: %s').format('[A-Za-z0-9_-]{3,}');

		return true;
	},
	validateAuthPassword: function(section_id, value) {
		if (!value)
			return true;
		if (!value.match(/^[^:]+$/))
			return _('Expecting: %s').format('[^:]+');

		return true;
	},

	validateCommonPort: function(section_id, value) {
		// thanks to homeproxy
		var stubValidator = {
			factory: validation,
			apply: function(type, value, args) {
				if (value != null)
					this.value = value;

				return validation.types[type].apply(this, args);
			},
			assert: function(condition) {
				return !!condition;
			}
		};

		if (value && !value.match(/common(_stun)?/)) {
			var ports = [];
			for (var i of value.split(',')) {
				if (!stubValidator.apply('port', i) && !stubValidator.apply('portrange', i))
					return _('Expecting: %s').format(_('valid port value'));
				if (ports.includes(i))
					return _('Port %s alrealy exists!').format(i);
				ports = ports.concat(i);
			}
		}

		return true;
	},

	validateJson: function(section_id, value) {
		if (!value)
			return true;

		try {
			var obj = JSON.parse(value.trim());
			if (!obj)
				return _('Expecting: %s').format(_('valid JSON format'));
		}
		catch(e) {
			return _('Expecting: %s').format(_('valid JSON format'));
		}

		return true;
	},

	validateBase64Key: function(length, section_id, value) {
		/* Thanks to luci-proto-wireguard */
		if (value)
			if (value.length !== length || !value.match(/^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/) || value[length-1] !== '=')
				return _('Expecting: %s').format(_('valid base64 key with %d characters').format(length));

		return true;
	},

	validateShadowsocksPassword: function(self, encmode, section_id, value) {
		var length = self.shadowsocks_cipher_length[encmode];
		if (typeof length !== 'undefined') {
			length = Math.ceil(length/3)*4;
			if (encmode.match(/^2022-/)) {
				return self.validateBase64Key(length, section_id, value);
			} else {
				if (length === 0 && !value)
					return _('Expecting: %s').format(_('non-empty value'));
				if (length !== 0 && value.length !== length)
					return _('Expecting: %s').format(_('valid key length with %d characters').format(length));
			}
		} else
			return true;

		return true;
	},

	validateBytesize: function(section_id, value) {
		if (!value)
			return true;

		if (!value.match(/^(\d+)(k|m|g)?b?$/))
			return _('Expecting: %s').format('^(\\d+)(k|m|g)?b?$');

		return true;
	},
	validateTimeDuration: function(section_id, value) {
		if (!value)
			return true;

		if (!value.match(/^(\d+)(s|m|h|d)?$/))
			return _('Expecting: %s').format('^(\\d+)(s|m|h|d)?$');

		return true;
	},

	validateUniqueValue: function(section_id, value) {
		if (!value)
			return _('Expecting: %s').format(_('non-empty value'));

		var duplicate = false;
		uci.sections(this.config, this.section.sectiontype, (res) => {
			if (res['.name'] !== section_id)
				if (res[this.option] === value)
					duplicate = true;
		});
		if (duplicate)
			return _('Expecting: %s').format(_('unique value'));

		return true;
	},

	validateUrl: function(section_id, value) {
		if (!value)
			return true;

		try {
			var url = new URL(value);
			if (!url.hostname)
				return _('Expecting: %s').format(_('valid URL'));
		}
		catch(e) {
			return _('Expecting: %s').format(_('valid URL'));
		}

		return true;
	},

	validateUUID: function(section_id, value) {
		if (!value)
			return true;
		else if (value.match('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') === null)
			return _('Expecting: %s').format(_('valid uuid'));

		return true;
	},

	lsDir: function(type) {
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
	},

	readFile: function(type, filename) {
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
	},

	writeFile: function(type, filename, content) {
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
	},

	downloadFile: function(type, filename, url, header) {
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
	},

	removeFile: function(type, filename) {
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
	},

	// thanks to homeproxy
	uploadCertificate: function(type, filename, ev) {
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
					ui.addNotification(null, E('p', _('Your %s was successfully uploaded. Size: %sB.').format(type, res.size)));
				else
					ui.addNotification(null, E('p', _('Failed to upload %s, error: %s.').format(type, ret.error)));
			});
		}, this, ev.target))
		.catch((e) => { ui.addNotification(null, E('p', e.message)) });
	},
	uploadInitialPack: function(ev, section_id) {
		const callWriteInitialPack = rpc.declare({
			object: 'luci.fchomo',
			method: 'initialpack_write',
			expect: { '': {} }
		});

		return ui.uploadFile('/tmp/fchomo_initialpack.tmp', ev.target)
		.then(L.bind((btn, res) => {
			return L.resolveDefault(callWriteInitialPack(), {}).then((ret) => {
				if (ret.result === true) {
					ui.addNotification(null, E('p', _('Successfully uploaded.')));
					return window.location = window.location.href.split('#')[0];
				} else
					ui.addNotification(null, E('p', _('Failed to upload, error: %s.').format(ret.error)));
			});
		}, this, ev.target))
		.catch((e) => { ui.addNotification(null, E('p', e.message)) });
	}
});
