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
/* fake-ip-filter-mode: blacklist (default) | whitelist | rule */
let filter_mode = s(a('fake_ip_filter_mode'), 'blacklist');
if (filter_mode != 'blacklist') cfg['dns']['fake-ip-filter-mode'] = filter_mode;

/* map geosite:cn to bundled cn.mrs rule-set so mihomo skips the 10MB geosite.dat */
let need_cn_rs = false;
let push_filter = function(f) {
	if (f == 'geosite:cn') { f = 'rule-set:cn_domain'; need_cn_rs = true; }
	else if (f == 'rule-set:cn_domain') need_cn_rs = true;
	push(cfg['dns']['fake-ip-filter'], f);
};
let filters = a('fake_ip_filter');
if (type(filters) == 'array') { for (let f in filters) push_filter(f); }
else if (filters != null) push_filter(filters);

/* fallback-filter（默认 geoip:false，防止冷启动依赖 MMDB） */
cfg['dns']['fallback-filter'] = { geoip: ab('fallback_filter_geoip') };

let dns_present = {};
for (let f in split(s(getenv('CLASHOO_DNS_PRESENT'), ''), ','))
	if (length(trim(f))) dns_present[trim(f)] = true;
let dns_force = {};
for (let f in split(s(getenv('CLASHOO_DNS_FORCE'), ''), ','))
	if (length(trim(f))) dns_force[trim(f)] = true;
let dns_role_fields = ['nameserver', 'proxy-server-nameserver', 'direct-nameserver',
	'default-nameserver', 'nameserver-policy', 'respect-rules'];
let had_user_dns_roles = false;
for (let f in dns_role_fields)
	if (dns_present[f]) had_user_dns_roles = true;
if (length(keys(dns_force)) || !had_user_dns_roles)
	cfg['dns']['x-clashoo-managed-dns'] = true;

function dns_scheme(protocol) {
	switch (trim(protocol || '')) {
	case '':
	case 'none':                     return '';
	case 'udp': case 'udp://':       return 'udp://';
	case 'tcp': case 'tcp://':       return 'tcp://';
	case 'dot': case 'tls': case 'tls://':     return 'tls://';
	case 'doh': case 'https': case 'https://': return 'https://';
	case 'doq': case 'quic': case 'quic://':   return 'quic://';
	default:                         return protocol;
	}
}

function dns_server(address, protocol, port) {
	let addr = trim(address || '');
	if (!length(addr)) return null;
	if (match(addr, /^[A-Za-z][A-Za-z0-9+.-]*:\/\//)) return addr;
	let prefix = dns_scheme(protocol);
	return length(trim(port || '')) ? prefix + addr + ':' + trim(port) : prefix + addr;
}

let dns_roles = {};
uci.foreach('clashoo', 'dnsservers', function(sec) {
	if (b(sec.enabled) == false) return;
	let role = s(sec.ser_type, 'nameserver');
	if (role == 'fallback' && cfg['dns']['enhanced-mode'] == 'fake-ip') return;
	let srv = dns_server(sec.ser_address, sec.protocol, sec.ser_port);
	if (!srv) return;
	if (!dns_roles[role]) dns_roles[role] = [];
	push(dns_roles[role], srv);
});
for (let role in keys(dns_roles))
	if (!dns_present[role] || dns_force[role]) cfg['dns'][role] = dns_roles[role];

let bootstrap = a('default_nameserver');
if (bootstrap == null) bootstrap = a('defaul_nameserver');
if (type(bootstrap) != 'array') bootstrap = bootstrap != null ? [bootstrap] : [];
if (length(bootstrap) && (!dns_present['default-nameserver'] || dns_force['default-nameserver']))
	cfg['dns']['default-nameserver'] = bootstrap;

let policies = {};
uci.foreach('clashoo', 'dns_policy', function(sec) {
	if (b(sec.enabled) == false) return;
	if (s(sec.policy_type, 'nameserver-policy') != 'nameserver-policy') return;
	let matcher = trim(sec.matcher || '');
	let servers = sec.nameserver;
	if (type(servers) != 'array') servers = servers != null ? [servers] : [];
	if (!length(matcher) || !length(servers)) return;
	if (matcher == 'geosite:cn') { matcher = 'rule-set:cn_domain'; need_cn_rs = true; }
	policies[matcher] = servers;
});
if (length(keys(policies)) && (!dns_present['nameserver-policy'] || dns_force['nameserver-policy']))
	cfg['dns']['nameserver-policy'] = policies;

let respect_rules = a('dns_respect_rules') == null ? true : ab('dns_respect_rules');
if (respect_rules && length(cfg['dns']['proxy-server-nameserver'] || [])
    && (!dns_present['respect-rules'] || dns_force['respect-rules']) && !dns_present['prefer-h3'])
	cfg['dns']['respect-rules'] = true;

/* profile */
let store_selected = ab('selection_cache');
/* fake-ip cache defaults ON to survive restarts; opt out with '0' */
let store_fake     = a('fake_ip_cache') == null ? true : ab('fake_ip_cache');
if (store_selected || store_fake) {
	cfg['profile'] = {};
	if (store_selected) cfg['profile']['store-selected'] = true;
	if (store_fake)     cfg['profile']['store-fake-ip']   = true;
}

/* bundled cn.mrs rule-provider, referenced by fake-ip-filter rule-set:cn_domain */
if (need_cn_rs) {
	if (!cfg['rule-providers']) cfg['rule-providers'] = {};
	cfg['rule-providers']['cn_domain'] = {
		type:     'file',
		path:     './ruleset/cn.mrs',
		format:   'mrs',
		behavior: 'domain',
	};
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
