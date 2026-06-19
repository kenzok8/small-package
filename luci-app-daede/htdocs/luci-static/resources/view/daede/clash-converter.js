// SPDX-License-Identifier: Apache-2.0

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
	const binary = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
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

function makeResult(node, link) {
	return {
		ok: true,
		name: String(node.name || 'Node'),
		type: String(node.type || '').toLowerCase(),
		link: link,
		error: ''
	};
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
		params.set('allowInsecure', '1');
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
		return makeResult(node, converters[type](node));
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

function normalizeLink(link) {
	const value = String(link || '').trim();
	if (value.indexOf('vmess://') === 0) {
		try {
			const payload = JSON.parse(utf8FromBase64(value.slice(8)));
			delete payload.ps;
			return 'vmess://' + utf8Base64(JSON.stringify(payload));
		} catch (e) {}
	}
	return value.replace(/#.*$/, '');
}

const api = {
	convertProxy: convertProxy,
	convertProxies: convertProxies,
	isMetadataProxy: isMetadataProxy,
	normalizeLink: normalizeLink
};

if (typeof module !== 'undefined' && module.exports)
	module.exports = api;

if (typeof baseclass !== 'undefined')
	return baseclass.extend(api);

return api;
