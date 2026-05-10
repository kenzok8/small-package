#!/usr/bin/ucode
'use strict';

import { cursor } from 'uci';
const uci = cursor();

function b(v) {
	if (v == null || v == '' || v == '0' || v == 'false') return false;
	if (v == '1' || v == 'true') return true;
	return v;
}
function i(v, d) { let n = v != null ? int(v) : null; return n != null ? n : d; }
function s(v, d) { let t = trim(v || ''); return length(t) ? t : d; }
function a(k)    { return uci.get('clashoo', 'config', k); }
function ab(k)   { return b(a(k)); }

const cfg = {};

/* ── 端口与基本设置 ─────────────────────────────────────── */
let v;
v = i(a('http_port'));        if (v != null) cfg['port'] = v;
v = i(a('socks_port'));       if (v != null) cfg['socks-port'] = v;
v = i(a('redir_port'));       if (v != null) cfg['redir-port'] = v;
v = i(a('mixed_port'));       if (v != null) cfg['mixed-port'] = v;
v = i(a('tproxy_port'));      if (v != null) cfg['tproxy-port'] = v;

v = a('bind_addr');
if (!v || v == '*') v = null;
if (v) cfg['bind-address'] = v;

v = a('p_mode');
if (v == 'script') v = 'rule';
if (v) cfg['mode'] = v;

cfg['log-level']   = s(a('level'), 'info');
cfg['allow-lan']   = ab('allow_lan');
cfg['ipv6']        = ab('enable_ipv6');
cfg['routing-mark'] = 6666;
cfg['external-controller'] = '0.0.0.0:' + i(a('dash_port'), 9090);
cfg['external-ui'] = './dashboard';
cfg['secret']      = s(a('dash_pass'), '');

v = a('interf');
if (v && v != '0') cfg['interface-name'] = v;

/* ── TUN ───────────────────────────────────────────────── */
let tun_mode = i(a('tun_mode'), 0);
let tcp_mode = s(a('tcp_mode'), 'redirect');
let udp_mode = s(a('udp_mode'), 'tproxy');
let tun_enabled = (tun_mode == 1 || tcp_mode == 'tun' || udp_mode == 'tun');

cfg['tun'] = {
	enable:                tun_enabled,
	stack:                 s(a('stack'), 'gvisor'),
	'auto-route':          true,
	'auto-redirect':       true,
	'auto-detect-interface': true,
};
let tun_mtu = a('tun_mtu');
if (tun_mtu != null) cfg['tun']['mtu'] = int(tun_mtu);
if (ab('tun_gso')) {
	cfg['tun']['gso'] = true;
	cfg['tun']['gso-max-size'] = i(a('tun_gso_max_size'), 65536);
}
if (ab('tun_dns_hijack')) {
	cfg['tun']['dns-hijack'] = ['any:53', 'tcp://any:53'];
}
if (!tun_enabled) {
	cfg['tun']['enable'] = false;
}

/* ── DNS ───────────────────────────────────────────────── */
let dns_port = i(a('listen_port'), 1053);
cfg['dns'] = {
	enable:         b(a('enable_dns')) != false,
	listen:         '0.0.0.0:' + dns_port,
	'enhanced-mode': s(a('enhanced_mode'), 'fake-ip'),
	'fake-ip-range': s(a('fake_ip_range'), '198.18.0.1/16'),
	'fake-ip-filter': [],
	ipv6:           ab('enable_ipv6'),
};
/* fake-ip-filter */
let filters = a('fake_ip_filter');
if (type(filters) == 'array') { for (let f in filters) push(cfg['dns']['fake-ip-filter'], f); }
else if (filters != null) push(cfg['dns']['fake-ip-filter'], filters);

/* fallback-filter（默认 geoip:false，防止冷启动依赖 MMDB） */
cfg['dns']['fallback-filter'] = { geoip: ab('fallback_filter_geoip') };

/* profile */
let store_selected = ab('selection_cache');
let store_fake     = ab('fake_ip_cache');
if (store_selected || store_fake) {
	cfg['profile'] = {};
	if (store_selected) cfg['profile']['store-selected'] = true;
	if (store_fake)     cfg['profile']['store-fake-ip']   = true;
}



/* ── authentication ────────────────────────────────── */
if (ab('authentication')) {
	cfg['authentication'] = [];
	uci.foreach('clashoo', 'authentication', function(sec) {
		if (b(sec.enabled) == false) return;
		let user = trim(sec.username || '');
		let pass = trim(sec.password || '');
		if (user) push(cfg['authentication'], user + ':' + pass);
	});
}

/* ── hosts ────────────────────────────────────────── */
cfg['hosts'] = {};
uci.foreach('clashoo', 'hosts', function(sec) {
	if (b(sec.enabled) == false) return;
	let domain = trim(sec.adress || '');
	let ip     = trim(sec.ip || '');
	if (domain && ip) cfg['hosts'][domain] = ip;
});
if (length(keys(cfg['hosts'])) == 0) delete cfg['hosts'];

/* ── sniffer ──────────────────────────────────────── */
if (ab('sniffer_streaming')) {
	cfg['sniffer'] = {
		enable:              true,
		'force-dns-mapping': true,
		'parse-pure-ip':     true,
		sniff: {
			HTTP: { ports: [80, 8080], 'override-destination': true },
			TLS:  { ports: [443, 8443], 'override-destination': true },
			QUIC: { ports: [443, 8443], 'override-destination': true },
		},
		'force-domain': [
			'+.youtube.com',
			'+.googlevideo.com',
			'+.netflix.com',
			'+.nflxvideo.net',
			'+.disneyplus.com',
			'+.hulu.com',
			'+.hbomax.com',
		],
	};
}

/* ── Smart kernel injection ───────────────────────── */
if (ab('smart_auto_switch')) {
	/* Smart 策略注入：通过 proxy-groups 覆盖实现 */
}

/* ── ECS ──────────────────────────────────────────── */
let ecs = s(a('dns_ecs'));
if (ecs) cfg['dns']['edns-client-subnet'] = ecs;

/* ── cache_file / experimental ──────────────────── */
cfg['experimental'] = {
	'cache_file': { enabled: true },
	'clash_api': {
		'external-controller': '0.0.0.0:' + i(a('dash_port'), 9090),
		'external-ui':         './dashboard',
		'secret':              s(a('dash_pass'), ''),
	},
};

/* ── 输出 JSON (不含 null/空对象) ─────────────────── */
function clean(obj) {
	if (type(obj) == 'array') {
		let r = [];
		for (let e in obj) {
			e = clean(e);
			if (e != null) push(r, e);
		}
		return length(r) ? r : null;
	}
	if (type(obj) == 'object') {
		let r = {};
		for (let k in keys(obj)) {
			let v = clean(obj[k]);
			if (v != null) r[k] = v;
		}
		return length(keys(r)) ? r : null;
	}
	return obj;
}
print(clean(cfg));
