// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require baseclass';

function utf8Base64(value) {
	const bytes = new TextEncoder().encode(String(value));
	let binary = '';
	for (let i = 0; i < bytes.length; i++)
		binary += String.fromCharCode(bytes[i]);
	return btoa(binary);
}

function utf8FromBase64(value) {
	const binary = atob(value);
	const bytes = Uint8Array.from(binary, function(ch) { return ch.charCodeAt(0); });
	return new TextDecoder('utf-8').decode(bytes);
}

function base64Url(value) {
	return utf8Base64(value).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function endpoint(server, port) {
	const host = String(server).indexOf(':') >= 0 && String(server)[0] !== '['
		? '[' + server + ']'
		: server;
	return host + ':' + port;
}

function requireFields(node, fields) {
	for (let i = 0; i < fields.length; i++) {
		const key = fields[i];
		if (node[key] === undefined || node[key] === null || node[key] === '')
			throw new Error('Missing required field: ' + key);
	}
}

function setIf(params, key, value) {
	if (value !== undefined && value !== null && value !== '')
		params.set(key, String(value));
}

function arrayValue(value) {
	return Array.isArray(value) ? value.join(',') : value;
}

function addTransport(params, node) {
	const network = node.network || 'tcp';
	params.set('type', network);

	if (network === 'ws') {
		const opts = node['ws-opts'] || {};
		setIf(params, 'path', opts.path);
		setIf(params, 'host', opts.headers && (opts.headers.Host || opts.headers.host));
	} else if (network === 'grpc') {
		const opts = node['grpc-opts'] || {};
		setIf(params, 'serviceName', opts['grpc-service-name'] || opts.serviceName);
	} else if (network === 'http' || network === 'h2') {
		const opts = node['h2-opts'] || node['http-opts'] || {};
		setIf(params, 'path', Array.isArray(opts.path) ? opts.path[0] : opts.path);
		setIf(params, 'host', arrayValue(opts.host));
	}
}

function convertSs(node) {
	requireFields(node, [ 'server', 'port', 'cipher', 'password' ]);
	const auth = base64Url(node.cipher + ':' + node.password);
	let query = '';
	if (node.plugin) {
		const fields = [ String(node.plugin) ];
		const opts = node['plugin-opts'] || {};
		Object.keys(opts).forEach(function(key) {
			const value = opts[key];
			if (value === true)
				fields.push(key);
			else if (value !== false && value !== undefined && value !== null && value !== '')
				fields.push(key + '=' + value);
		});
		const params = new URLSearchParams();
		params.set('plugin', fields.join(';'));
		query = '?' + params.toString();
	}
	return 'ss://' + auth + '@' + endpoint(node.server, node.port) + query + '#' + encodeURIComponent(node.name || 'Node');
}

function convertSsr(node) {
	requireFields(node, [ 'server', 'port', 'cipher', 'password', 'protocol', 'obfs' ]);
	const query = [];
	query.push('remarks=' + base64Url(node.name || 'Node'));
	if (node['protocol-param'])
		query.push('protoparam=' + base64Url(node['protocol-param']));
	if (node['obfs-param'])
		query.push('obfsparam=' + base64Url(node['obfs-param']));

	const payload = [
		node.server,
		node.port,
		node.protocol,
		node.cipher,
		node.obfs,
		base64Url(node.password)
	].join(':') + '/?' + query.join('&');
	return 'ssr://' + base64Url(payload);
}

function convertVmess(node) {
	requireFields(node, [ 'server', 'port', 'uuid' ]);
	const network = node.network || 'tcp';
	const ws = node['ws-opts'] || {};
	const grpc = node['grpc-opts'] || {};
	const h2 = node['h2-opts'] || {};
	const payload = {
		v: '2',
		ps: String(node.name || 'Node'),
		add: String(node.server),
		port: String(node.port),
		id: String(node.uuid),
		aid: Number(node.alterId || node.alter_id || 0),
		scy: String(node.cipher || 'auto'),
		net: network,
		type: 'none',
		host: String((ws.headers && (ws.headers.Host || ws.headers.host)) || arrayValue(h2.host) || ''),
		path: String(ws.path || grpc['grpc-service-name'] || (Array.isArray(h2.path) ? h2.path[0] : h2.path) || ''),
		tls: node.tls ? 'tls' : 'none',
		sni: String(node.servername || node.sni || ''),
		alpn: String(arrayValue(node.alpn) || ''),
		fp: String(node.fingerprint || node['client-fingerprint'] || '')
	};
	return 'vmess://' + utf8Base64(JSON.stringify(payload));
}

function convertVless(node) {
	requireFields(node, [ 'server', 'port', 'uuid' ]);
	const params = new URLSearchParams();
	addTransport(params, node);
	params.set('encryption', String(node.encryption || 'none'));
	setIf(params, 'flow', node.flow);

	const reality = node['reality-opts'];
	if (reality || node.tls) {
		params.set('security', reality ? 'reality' : 'tls');
		setIf(params, 'sni', node.servername || node.sni);
		setIf(params, 'fp', node.fingerprint || node['client-fingerprint']);
		setIf(params, 'alpn', arrayValue(node.alpn));
		if (node['skip-cert-verify'])
			params.set('allowInsecure', '1');
		if (reality) {
			setIf(params, 'pbk', reality['public-key']);
			setIf(params, 'sid', reality['short-id']);
			setIf(params, 'spx', reality['spider-x']);
		}
	}

	return 'vless://' + encodeURIComponent(node.uuid) + '@' + endpoint(node.server, node.port) +
		'?' + params.toString() + '#' + encodeURIComponent(node.name || 'Node');
}

function convertTrojan(node) {
	requireFields(node, [ 'server', 'port', 'password' ]);
	const params = new URLSearchParams();
	addTransport(params, node);
	setIf(params, 'sni', node.sni || node.servername);
	setIf(params, 'fp', node.fingerprint || node['client-fingerprint']);
	setIf(params, 'alpn', arrayValue(node.alpn));
	if (node['skip-cert-verify'])
		params.set('allowInsecure', '1');
	return 'trojan://' + encodeURIComponent(node.password) + '@' + endpoint(node.server, node.port) +
		'?' + params.toString() + '#' + encodeURIComponent(node.name || 'Node');
}

function convertTuic(node) {
	requireFields(node, [ 'server', 'port', 'uuid', 'password' ]);
	const params = new URLSearchParams();
	setIf(params, 'sni', node.sni);
	setIf(params, 'alpn', arrayValue(node.alpn));
	setIf(params, 'congestion_control', node['congestion-controller'] || node['congestion-control']);
	setIf(params, 'udp_relay_mode', node['udp-relay-mode']);
	if (node['skip-cert-verify'])
		params.set('allow_insecure', '1');
	return 'tuic://' + encodeURIComponent(node.uuid) + ':' + encodeURIComponent(node.password) + '@' +
		endpoint(node.server, node.port) + (params.toString() ? '?' + params.toString() : '') +
		'#' + encodeURIComponent(node.name || 'Node');
}

function convertHysteria2(node) {
	requireFields(node, [ 'server', 'port', 'password' ]);
	const params = new URLSearchParams();
	setIf(params, 'sni', node.sni);
	setIf(params, 'alpn', arrayValue(node.alpn));
	setIf(params, 'obfs', node.obfs);
	setIf(params, 'obfs-password', node['obfs-password']);
	if (node['skip-cert-verify'])
		params.set('insecure', '1');
	return 'hysteria2://' + encodeURIComponent(node.password) + '@' + endpoint(node.server, node.port) +
		(params.toString() ? '?' + params.toString() : '') + '#' + encodeURIComponent(node.name || 'Node');
}

function convertAnytls(node) {
	requireFields(node, [ 'server', 'port', 'password' ]);
	const params = new URLSearchParams();
	setIf(params, 'sni', node.sni || node.servername);
	setIf(params, 'alpn', arrayValue(node.alpn));
	setIf(params, 'client-fingerprint', node['client-fingerprint'] || node.fingerprint);
	if (node['skip-cert-verify'])
		params.set('insecure', '1');
	if (node.udp)
		params.set('udp', '1');
	return 'anytls://' + encodeURIComponent(node.password) + '@' + endpoint(node.server, node.port) +
		(params.toString() ? '?' + params.toString() : '') + '#' + encodeURIComponent(node.name || 'Node');
}

function isMetadataProxy(node) {
	const name = String(node && node.name || '').trim();
	if (!name)
		return false;

	return /(?:官网|QQ|流量|续费|应急|重置|到期|过期|剩余|套餐)/i.test(name) ||
		/^(?:traffic|bandwidth|expire|expiry|expiration|subscription(?:\s+info)?|official\s+website|website)\s*[:：|]/i.test(name) ||
		/^(?:(?:剩余|可用|已用|总)?流量|套餐到期|到期时间|到期日|过期时间|有效期|订阅信息)\s*[:：|]/i.test(name) ||
		/^(?:官方网站|官网地址|官方网址|网站地址)\s*[:：|]/i.test(name) ||
		/^(?:加入|联系|客服)?\s*QQ\s*(?:群|交流群|客服|联系)\s*[:：|]/i.test(name);
}

function convertProxy(node) {
	const type = String(node && node.type || '').toLowerCase();
	const converters = {
		ss: convertSs,
		ssr: convertSsr,
		vmess: convertVmess,
		vless: convertVless,
		trojan: convertTrojan,
		tuic: convertTuic,
		hysteria2: convertHysteria2,
		hy2: convertHysteria2,
		anytls: convertAnytls
	};

	try {
		if (!node || typeof node !== 'object')
			throw new Error('Node must be an object');
		if (!converters[type])
			throw new Error('Unsupported protocol: ' + (type || 'unknown'));
		return {
			ok: true,
			name: String(node.name || 'Node'),
			type: type,
			link: converters[type](node),
			error: ''
		};
	} catch (e) {
		return {
			ok: false,
			name: String(node && node.name || 'Node'),
			type: type || 'unknown',
			link: '',
			error: String(e && e.message || e)
		};
	}
}

function convertProxies(proxies) {
	return Array.isArray(proxies) ? proxies.map(convertProxy) : [];
}

// --- Paste-import helpers -------------------------------------------------

const NODE_SCHEMES = /^(ss|ssr|vmess|vless|trojan|tuic|hysteria2?|hy2|anytls|socks5|socks4|juicity|snell):\/\//i;

function looksLikeNodeList(text) {
	const lines = String(text || '').split('\n');
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i].trim();
		if (line && NODE_SCHEMES.test(line))
			return true;
	}
	return false;
}

function looksLikeClashYaml(text) {
	return /\bproxies\s*:/.test(String(text || ''));
}

function looksLikeSurge(text) {
	return /^\s*\[Proxy\]\s*$/m.test(String(text || ''));
}

function tryBase64Decode(text) {
	const compact = String(text || '').replace(/\s+/g, '');
	if (compact.length < 4 || !/^[A-Za-z0-9+/_-]+={0,2}$/.test(compact))
		return '';
	let normalized = compact.replace(/-/g, '+').replace(/_/g, '/');
	while (normalized.length % 4)
		normalized += '=';
	try {
		return utf8FromBase64(normalized);
	} catch (e) {
		return '';
	}
}

function parseUriList(text) {
	const links = [];
	let rejected = 0;
	String(text || '').split('\n').forEach(function(raw) {
		const line = raw.trim();
		if (!line || line[0] === '#' || line[0] === ';' || line.indexOf('//') === 0)
			return;
		if (NODE_SCHEMES.test(line))
			links.push(line);
		else
			rejected++;
	});
	return { links: links, rejected: rejected };
}

function splitSurgeFields(value) {
	const fields = [];
	let current = '';
	let quote = '';
	for (let i = 0; i < value.length; i++) {
		const ch = value[i];
		if (ch === '"' || ch === '\'') {
			if (quote === ch) quote = '';
			else if (quote === '') quote = ch;
			current += ch;
		} else if (ch === ',' && quote === '') {
			fields.push(surgeScalar(current));
			current = '';
		} else {
			current += ch;
		}
	}
	fields.push(surgeScalar(current));
	return fields;
}

function surgeScalar(value) {
	let t = String(value || '').trim();
	if (t.length >= 2 && (t[0] === '"' || t[0] === '\'') && t[0] === t[t.length - 1])
		t = t.slice(1, -1);
	try { return decodeURIComponent(t); } catch (e) { return t; }
}

function firstNonEmpty() {
	for (let i = 0; i < arguments.length; i++)
		if (arguments[i] !== undefined && arguments[i] !== null && arguments[i] !== '')
			return arguments[i];
	return '';
}

// Parse a Surge/Shadowrocket [Proxy] section. Only Shadowsocks lines are
// understood, matching the upstream parser; other protocols are rejected so an
// ordinary URL in the file is never mistaken for a node.
function parseSurgeProxies(text) {
	const links = [];
	let rejected = 0;
	let inside = false;
	String(text || '').split('\n').forEach(function(raw) {
		const line = raw.trim();
		if (!line || line[0] === '#' || line[0] === ';' || line.indexOf('//') === 0)
			return;
		if (line[0] === '[' && line[line.length - 1] === ']' && line.indexOf('=') < 0) {
			inside = line.toLowerCase() === '[proxy]';
			return;
		}
		if (!inside)
			return;
		const sep = line.indexOf('=');
		if (sep < 0)
			return;
		const name = line.slice(0, sep).trim();
		const fields = splitSurgeFields(line.slice(sep + 1));
		if (!name || fields.length < 3 || fields[0].toLowerCase() !== 'ss' || !fields[1]) {
			rejected++;
			return;
		}
		const port = Number(fields[2]);
		if (!Number.isInteger(port) || port <= 0 || port > 65535) {
			rejected++;
			return;
		}
		const options = {};
		for (let i = 3; i < fields.length; i++) {
			const eq = fields[i].indexOf('=');
			if (eq < 0)
				continue;
			options[fields[i].slice(0, eq).trim().toLowerCase()] = fields[i].slice(eq + 1).trim();
		}
		const node = {
			name: name,
			type: 'ss',
			server: fields[1],
			port: port,
			cipher: firstNonEmpty(options['encrypt-method'], options.method, options.cipher),
			password: options.password,
			plugin: options.plugin || options['obfs'],
			'plugin-opts': {}
		};
		if (node.plugin) {
			node['plugin-opts'].mode = options['obfs'] || 'http';
			if (options['obfs-host'])
				node['plugin-opts'].host = options['obfs-host'];
		}
		if (!node.cipher || !node.password) {
			rejected++;
			return;
		}
		const result = convertProxy(node);
		if (result.ok) links.push(result.link);
		else rejected++;
	});
	if (!links.length && !rejected)
		rejected = 1;
	return { links: links, rejected: rejected };
}

// Mihomo/mihomo-format JSON keeps nodes in `outbounds` and names them with
// `tag` instead of `name`, with nested `tls`/`transport` objects. Normalize to
// the Clash shape so the existing convertProxy converters work unchanged.
function looksLikeMihomoJson(text) {
	const t = String(text || '').trim();
	if (!t || t[0] !== '{')
		return false;
	try {
		const doc = JSON.parse(t);
		return !!(doc && Array.isArray(doc.outbounds));
	}
	catch (e) {
		return false;
	}
}

function normalizeMihomoNode(node) {
	const n = Object.assign({}, node);
	if (node.tag !== undefined && node.name === undefined) n.name = node.tag;
	if (node.server_port !== undefined && node.port === undefined) n.port = node.server_port;

	const tls = node.tls;
	if (tls && typeof tls === 'object') {
		if (tls.server_name !== undefined && n.servername === undefined) n.servername = tls.server_name;
		if (tls.insecure && n['skip-cert-verify'] === undefined) n['skip-cert-verify'] = true;
		if (Array.isArray(tls.alpn) && n.alpn === undefined) n.alpn = tls.alpn;
		if (tls.utls && tls.utls.fingerprint !== undefined && n['client-fingerprint'] === undefined)
			n['client-fingerprint'] = tls.utls.fingerprint;
		if (tls.reality && typeof tls.reality === 'object') {
			if (!n['reality-opts']) n['reality-opts'] = {};
			if (tls.reality.public_key !== undefined) n['reality-opts']['public-key'] = tls.reality.public_key;
			if (tls.reality.short_id !== undefined) n['reality-opts']['short-id'] = tls.reality.short_id;
		}
	}

	const transport = node.transport;
	if (transport && typeof transport === 'object') {
		if (transport.type && n.network === undefined) n.network = transport.type;
		if (transport.type === 'ws' && transport.path && !n['ws-opts']) {
			n['ws-opts'] = { path: transport.path };
			if (transport.headers && transport.headers.Host)
				n['ws-opts'].headers = { Host: transport.headers.Host };
		}
	}
	return n;
}

function parseMihomoJson(text) {
	let doc;
	try {
		doc = JSON.parse(String(text || ''));
	}
	catch (e) {
		return { links: [], rejected: 1 };
	}
	const outbounds = (doc && doc.outbounds) || [];
	const links = [];
	let rejected = 0;
	outbounds.forEach(function(node) {
		if (isMetadataProxy(node)) {
			rejected++;
			return;
		}
		const result = convertProxy(normalizeMihomoNode(node));
		if (result.ok) links.push(result.link);
		else rejected++;
	});
	return { links: links, rejected: rejected };
}

return baseclass.extend({
	convertProxy: convertProxy,
	convertProxies: convertProxies,
	isMetadataProxy: isMetadataProxy,
	looksLikeNodeList: looksLikeNodeList,
	looksLikeClashYaml: looksLikeClashYaml,
	looksLikeSurge: looksLikeSurge,
	looksLikeMihomoJson: looksLikeMihomoJson,
	tryBase64Decode: tryBase64Decode,
	parseUriList: parseUriList,
	parseSurgeProxies: parseSurgeProxies,
	parseMihomoJson: parseMihomoJson,
	normalizeMihomoNode: normalizeMihomoNode
});
