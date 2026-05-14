#!/usr/bin/ucode

'use strict';

import { readfile, writefile, access, popen } from 'fs';

let path = ARGV[0] || '';
let redir_port = +(ARGV[1] || '7891');
let tproxy_port = +(ARGV[2] || '7982');
let mixed_port = +(ARGV[3] || '7890');
let has_tun_device = (ARGV[4] || '1') == '1';
if (has_tun_device && system('(ip tuntap add mode tun name cotuntest >/dev/null 2>&1 && ip link del cotuntest >/dev/null 2>&1)') != 0)
	has_tun_device = false;

// 默认 6666 必须与 /usr/share/clashoo/net/fw4.sh:CORE_ROUTING_MARK (0x1a0a) 一致；
let routing_mark = +(ARGV[5] || '6666');
let dns_port = +(ARGV[6] || '1053');
let dash_port = +(ARGV[7] || '9090');
let dash_secret = ARGV[8] != null ? (ARGV[8] + '') : '';

if (!path) {
	print("missing path\n");
	exit(1);
}

let raw = readfile(path);
if (!raw) {
	print("read failed\n");
	exit(1);
}

let cfg = json(raw);
if (!cfg) {
	print("json parse failed\n");
	exit(1);
}

function s_len(s) {
	return length(s || '');
}

function s_sub(s, start, count) {
	if (count == null)
		return substr(s || '', start);
	return substr(s || '', start, count);
}

function is_space(ch) {
	return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
}

function trim_s(s) {
	s = (s == null) ? '' : (s + '');
	while (s_len(s) > 0 && is_space(s_sub(s, 0, 1)))
		s = s_sub(s, 1);
	while (s_len(s) > 0 && is_space(s_sub(s, s_len(s) - 1, 1)))
		s = s_sub(s, 0, s_len(s) - 1);
	return s;
}

let default_interface = '';
let _default_if_pipe = popen("ip -4 route show default 2>/dev/null | awk '{print $5; exit}'");
if (_default_if_pipe) {
	default_interface = trim_s(_default_if_pipe.read('all'));
	_default_if_pipe.close();
}

function starts_with(s, prefix) {
	return s_sub(s || '', 0, s_len(prefix)) == prefix;
}

function find_char(s, ch) {
	for (let i = 0; i < s_len(s); i++)
		if (s_sub(s, i, 1) == ch)
			return i;
	return -1;
}

function find_last_char(s, ch) {
	for (let i = s_len(s) - 1; i >= 0; i--)
		if (s_sub(s, i, 1) == ch)
			return i;
	return -1;
}

function split_uci_words(line) {
	let out = [], cur = '', quote = '', esc = false;
	for (let i = 0; i < s_len(line); i++) {
		let ch = s_sub(line, i, 1);
		if (esc) {
			cur += ch;
			esc = false;
			continue;
		}
		if (ch == '\\') {
			esc = true;
			continue;
		}
		if (quote) {
			if (ch == quote)
				quote = '';
			else
				cur += ch;
			continue;
		}
		if (ch == '"' || ch == "'") {
			quote = ch;
			continue;
		}
		if (is_space(ch)) {
			if (s_len(cur) > 0) {
				push(out, cur);
				cur = '';
			}
			continue;
		}
		cur += ch;
	}
	if (s_len(cur) > 0)
		push(out, cur);
	return out;
}

function load_clashoo_uci() {
	let uci_path = ARGV[9] || '/etc/config/clashoo';
	let txt = readfile(uci_path) || '';
	let sections = [], cur = null;
	for (let line in split(txt, '\n')) {
		line = trim_s(line);
		if (!s_len(line) || starts_with(line, '#'))
			continue;
		let words = split_uci_words(line);
		if (!length(words))
			continue;
		if (words[0] == 'config') {
			cur = { type: words[1] || '', name: words[2] || '', options: {}, lists: {} };
			push(sections, cur);
			continue;
		}
		if (!cur || length(words) < 3)
			continue;
		if (words[0] == 'option')
			cur.options[words[1]] = words[2];
		else if (words[0] == 'list') {
			if (cur.lists[words[1]] == null)
				cur.lists[words[1]] = [];
			push(cur.lists[words[1]], words[2]);
		}
	}
	return sections;
}

let clashoo_uci = load_clashoo_uci();

function uci_config_section() {
	for (let s in clashoo_uci)
		if (s.type == 'clashoo' && (s.name == 'config' || s.name == ''))
			return s;
	return {};
}

let uci_cfg = uci_config_section();

function uci_opt(key, def) {
	if (uci_cfg.options && uci_cfg.options[key] != null)
		return uci_cfg.options[key];
	return def;
}

function uci_list(key) {
	if (uci_cfg.lists && uci_cfg.lists[key] != null)
		return uci_cfg.lists[key];
	if (uci_cfg.options && uci_cfg.options[key] != null)
		return [ uci_cfg.options[key] ];
	return [];
}

function uci_sections(type_name) {
	let out = [];
	for (let s in clashoo_uci)
		if (s.type == type_name)
			push(out, s);
	return out;
}

function opt_bool(v, def) {
	if (v == null || v == '')
		return def;
	return v === true || v == '1' || v == 'true' || v == 'yes' || v == 'on';
}

function normalize_dns_uri(address, protocol, port) {
	address = trim_s(address || '');
	protocol = trim_s(protocol || '');
	port = trim_s(port || '');
	if (!s_len(address))
		return '';
	if (find_char(address, ':') >= 0 && find_char(address, '/') >= 0)
		return address;
	if (protocol == 'none')
		protocol = '';
	if (protocol == 'dot')
		protocol = 'tls://';
	else if (protocol == 'doh')
		protocol = 'https://';
	else if (protocol == 'doq')
		protocol = 'quic://';
	if (s_len(protocol) && !starts_with(protocol, 'udp://') && !starts_with(protocol, 'tcp://') &&
	    !starts_with(protocol, 'tls://') && !starts_with(protocol, 'https://') && !starts_with(protocol, 'quic://'))
		protocol += '://';
	return protocol + address + (s_len(port) ? ':' + port : '');
}

function direct_outbound_tag() {
	for (let ob in (cfg.outbounds || []))
		if (ob && ob.type == 'direct' && s_len(ob.tag || ''))
			return ob.tag;
	return 'DIRECT';
}

function dns_server_obj(uri, tag, fallback_type) {
	uri = normalize_dns_uri(uri || '', '', '');
	if (!s_len(uri))
		return null;
	let scheme = fallback_type || 'udp';
	let rest = uri;
	let p = -1;
	for (let i = 0; i < s_len(uri) - 2; i++) {
		if (s_sub(uri, i, 3) == '://') {
			p = i;
			break;
		}
	}
	if (p >= 0) {
		scheme = s_sub(uri, 0, p);
		rest = s_sub(uri, p + 3);
	}
	if (scheme == 'dot')
		scheme = 'tls';
	else if (scheme == 'doh')
		scheme = 'https';
	else if (scheme == 'doq')
		scheme = 'quic';

	let path = '';
	let slash = find_char(rest, '/');
	if (slash >= 0) {
		path = s_sub(rest, slash);
		rest = s_sub(rest, 0, slash);
	}

	let server = rest, server_port = null;
	let colon = find_last_char(rest, ':');
	if (colon > 0 && find_char(rest, ']') < 0) {
		server = s_sub(rest, 0, colon);
		let n = +(s_sub(rest, colon + 1));
		if (n === n)
			server_port = n;
	}

	let obj = { type: scheme, tag: tag, server: server };
	if (server_port != null)
		obj.server_port = server_port;
	if (path && (scheme == 'https' || scheme == 'h3'))
		obj.path = path;
	if ((scheme == 'https' || scheme == 'tls' || scheme == 'quic') && tag != 'dns_resolver')
		obj.domain_resolver = 'dns_resolver';
	/* sing-box 1.12+ DNS server 默认 detour 走 final outbound（机场代理）→
	 * 机场要解析自己 server 域名又走 dns_resolver → 死循环 → "lookup ... deadline exceeded" → 国外全 out。
	 * 直连/解析类 server 一律强制走 DIRECT；只有 dns_proxy 这种"解析国外用"才允许走代理。 */
	if (tag == 'dns_resolver' || tag == 'dns_direct' || tag == 'dns_foreign')
		obj.detour = direct_outbound_tag();
	return obj;
}

function dns_servers_by_role(role) {
	let out = [];
	for (let s in uci_sections('dnsservers')) {
		if (!opt_bool(s.options.enabled, true))
			continue;
		if ((s.options.ser_type || 'nameserver') != role)
			continue;
		let uri = normalize_dns_uri(s.options.ser_address || '', s.options.protocol || '', s.options.ser_port || '');
		if (s_len(uri))
			push(out, uri);
	}
	return out;
}

function first_or(arr, fallback) {
	return length(arr) ? arr[0] : fallback;
}

function local_rule_set_path(tag) {
	if (!s_len(tag))
		return '';
	let path = '/usr/share/clashoo/ruleset/' + tag + '.srs';
	if (access(path, 'r'))
		return path;
	if (tag == 'geolocation-cn' || tag == 'cn') {
		path = '/usr/share/clashoo/ruleset/geosite-cn.srs';
		if (access(path, 'r'))
			return path;
	}
	return '';
}

function keep_remote_rule_set(rs) {
	return false;
}

function normalize_rule_set_url(url) {
	url = url || '';
	url = replace(url, /^https:\/\/gh-proxy\.com\//, '');
	let m = match(url, /^https:\/\/raw\.githubusercontent\.com\/([^\/]+)\/([^\/]+)\/([^\/]+)\/(.+)$/);
	if (m)
		return 'https://cdn.jsdelivr.net/gh/' + m[1] + '/' + m[2] + '@' + m[3] + '/' + m[4];
	m = match(url, /^https:\/\/github\.com\/([^\/]+)\/([^\/]+)\/raw\/refs\/heads\/([^\/]+)\/(.+)$/);
	if (m)
		return 'https://cdn.jsdelivr.net/gh/' + m[1] + '/' + m[2] + '@' + m[3] + '/' + m[4];
	return url;
}

function has_route_rule_set(tag) {
	for (let rs in (cfg.route || {}).rule_set || [])
		if (rs && rs.tag == tag)
			return true;
	return false;
}

function add_remote_rule_set(tag, url) {
	cfg.route = cfg.route || {};
	cfg.route.rule_set = cfg.route.rule_set || [];
	if (has_route_rule_set(tag))
		return;
	push(cfg.route.rule_set, {
		tag: tag,
		type: 'remote',
		format: 'binary',
		url: url
	});
}

function matcher_rule(matcher, server_tag) {
	let r = { server: server_tag };
	if (starts_with(matcher, 'geosite:'))
		r.rule_set = s_sub(matcher, 8);
	else if (starts_with(matcher, 'rule_set:'))
		r.rule_set = s_sub(matcher, 9);
	else if (starts_with(matcher, 'domain:'))
		r.domain = s_sub(matcher, 7);
	else if (starts_with(matcher, 'domain-suffix:'))
		r.domain_suffix = s_sub(matcher, 14);
	else
		r.domain_suffix = matcher;
	return r;
}

function apply_dns_from_uci() {
	cfg.dns = cfg.dns || {};
	/* 清除 mihomo 风格 DNS 字段（如 enable/ipv6/listen/fake-ip-filter/nameserver
	 * 等），这些字段可能从订阅 YAML 转换时混入 JSON，sing-box 不认识会导致 Fatal。 */
	let _mihomo_dns_fields = ['enable', 'ipv6', 'listen', 'fake-ip-filter', 'fake-ip-range',
	                'enhanced-mode', 'nameserver', 'fallback', 'fallback-filter',
	                'use-hosts', 'default-nameserver', 'proxy-server-nameserver',
	                'direct-nameserver', 'nameserver-policy'];
	for (let _i = 0; _i < length(_mihomo_dns_fields); _i++)
		delete cfg.dns[_mihomo_dns_fields[_i]];
	/* 清除 mihomo 风格 experimental 字段 */
	let _mihomo_exp = ['sniff-tls-sni', 'sniff', 'sniffer'];
	for (let _me = 0; _me < length(_mihomo_exp); _me++)
		if (cfg.experimental && cfg.experimental[_mihomo_exp[_me]] != null)
			delete cfg.experimental[_mihomo_exp[_me]];
	/* 清除 root 级别非 sing-box 字段 */
	let _mihomo_root = ['clash-for-android', 'cfw-bypass', 'sniffer', 'profile',
	                'geodata-mode', 'geodata-loader', 'geox-url', 'geo-auto-update',
	                'geo-update-interval', 'tun', 'ipv6', 'interface-name',
	                'port', 'socks-port', 'mixed-port', 'redir-port', 'tproxy-port', 'mode', 'allow-lan', 'log-level', 'external-controller', 'secret', 'bind-address', 'routing-mark', 'find-process-mode', 'tcp-concurrent', 'unified-delay',
	                'keep-alive-interval', 'keep-alive-idle', 'disable-keep-alive'];
	/* 清除 subconverter 产物的附加说明字段及非标准字段 */
	let _subconv_fields = ['_note', '_sub_url', 'hosts', 'script', 'enable', 'fake-ip-filter', 'fake-ip-range'];
	for (let _sf = 0; _sf < length(_subconv_fields); _sf++)
		if (cfg[_subconv_fields[_sf]] != null)
			delete cfg[_subconv_fields[_sf]];
	for (let _mr = 0; _mr < length(_mihomo_root); _mr++)
		if (cfg[_mihomo_root[_mr]] != null)
			delete cfg[_mihomo_root[_mr]];
	let bootstrap = uci_list('default_nameserver');
	if (!length(bootstrap))
		bootstrap = uci_list('defaul_nameserver');
	let resolver_uri = first_or(bootstrap, '223.5.5.5');
	let direct_uri = first_or(dns_servers_by_role('direct-nameserver'), first_or(dns_servers_by_role('nameserver'), 'https://doh.pub/dns-query'));
	let proxy_uri = first_or(dns_servers_by_role('proxy-server-nameserver'), first_or(dns_servers_by_role('fallback'), '1.1.1.1'));

	let servers = [];
	push(servers, dns_server_obj(resolver_uri, 'dns_resolver', 'udp'));
	push(servers, dns_server_obj(direct_uri, 'dns_direct', 'udp'));
	push(servers, dns_server_obj(proxy_uri, 'dns_proxy', 'tls'));

	let enhanced = uci_opt('enhanced_mode', 'fake-ip');
	if (enhanced == 'fake-ip') {
		let fake_range = uci_opt('fake_ip_range', '198.18.0.1/16');
		push(servers, {
			type: 'fakeip',
			tag: 'dns_fakeip',
			inet4_range: fake_range || '198.18.0.1/16',
			inet6_range: 'fc00::/18'
		});
	}

	let rules = [];
	push(servers, { type: 'udp', tag: 'dns_foreign', server: '1.1.1.1' });
		if (enhanced == 'fake-ip') {
			push(rules, {
				rule_set: 'geolocation-!cn',
				server: 'dns_fakeip'
			});
		}

	let clean_servers = [];
	for (let s in servers)
		if (s)
			push(clean_servers, s);
	cfg.dns.servers = clean_servers;
	cfg.dns.rules = rules;
	cfg.dns.final = 'dns_direct';

	/* 防 DNS 泄漏：DNS 流量由 hijack-dns/853 reject 收口；final 仍走直连 DNS，
	 * 避免局域网 PTR、国内域名等未命中规则的查询被兜底送到 DoT 导致启动超时。 */
	if (opt_bool(uci_opt('dns_leak_protect', '0'), false)) {
		unshift(cfg.dns.rules, { query_type: ['AAAA'], action: 'reject', method: 'drop' });
	}

	let ecs = trim_s(uci_opt('dns_ecs', ''));
	if (s_len(ecs))
		cfg.dns.client_subnet = ecs;
	else
		delete cfg.dns.client_subnet;

	if (opt_bool(uci_opt('singbox_independent_cache', '0'), false))
		cfg.dns.independent_cache = true;
	else
		delete cfg.dns.independent_cache;

		/* sing-box 1.14 强制要求：不设则 Fatal；dns_resolver 绑定 DIRECT，首启动节点域名解析走 DIRECT DNS */
		cfg.route.default_domain_resolver = 'dns_resolver';
	}

let inbounds = cfg.inbounds || [];
let normalized = [];
let has_redirect = false;
let has_tproxy = false;
let has_mixed = false;
let has_tun = false;
let has_dns_in = false;
let wants_tun = has_tun_device && (uci_opt('tcp_mode', '') == 'tun' || uci_opt('udp_mode', '') == 'tun');
let tun_stack = uci_opt('stack', 'mixed') || 'mixed';

for (let ib in inbounds) {
	if (!ib)
		continue;

	if (ib.type == 'tun' || ib.tag == 'tun-in') {
		/* Keep tun inbound only when the selected proxy mode actually uses TUN. */
		if (wants_tun && !has_tun) {
			ib.type = 'tun';
			ib.tag = ib.tag || 'tun-in';
			if (!ib.address)
				ib.address = [ '172.19.0.1/30', 'fdfe:dcba:9876::1/126' ];
			ib.auto_route = true;
			ib.auto_redirect = true;
			ib.strict_route = true;
			ib.stack = tun_stack;
			push(normalized, ib);
			has_tun = true;
		}
		continue;
	}

	if (ib.tag == 'redirect-in' || ib.type == 'redirect') {
		if (has_redirect)
			continue;
		ib.type = 'redirect';
		ib.tag = 'redirect-in';
		ib.listen = '0.0.0.0';
		ib.listen_port = redir_port;
		has_redirect = true;
		push(normalized, ib);
		continue;
	}

	if (ib.tag == 'tproxy-in' || ib.type == 'tproxy') {
		if (has_tproxy)
			continue;
		ib.type = 'tproxy';
		ib.tag = 'tproxy-in';
		ib.listen = '0.0.0.0';
		ib.listen_port = tproxy_port;
		ib.network = 'udp';
		has_tproxy = true;
		push(normalized, ib);
		continue;
	}

	if (ib.tag == 'mixed-in' || ib.type == 'mixed') {
		if (has_mixed)
			continue;
		ib.type = 'mixed';
		ib.tag = 'mixed-in';
		ib.listen = '0.0.0.0';
		ib.listen_port = mixed_port;
		has_mixed = true;
		push(normalized, ib);
		continue;
	}

	if (ib.tag == 'dns-in') {
		if (has_dns_in)
			continue;
		ib.type = 'direct';
		ib.tag = 'dns-in';
		ib.listen = '0.0.0.0';
		ib.listen_port = dns_port;
		has_dns_in = true;
		push(normalized, ib);
		continue;
	}

	push(normalized, ib);
}

if (!has_redirect) {
	push(normalized, {
		type: 'redirect',
		tag: 'redirect-in',
		listen: '0.0.0.0',
		listen_port: redir_port
	});
}

if (!has_mixed) {
	push(normalized, {
		type: 'mixed',
		tag: 'mixed-in',
		listen: '0.0.0.0',
		listen_port: mixed_port
	});
}

if (wants_tun && !has_tun) {
	push(normalized, {
		type: 'tun',
		tag: 'tun-in',
		address: [ '172.19.0.1/30', 'fdfe:dcba:9876::1/126' ],
		auto_route: true,
		auto_redirect: true,
		strict_route: true,
		stack: tun_stack
	});
}

if (!has_tproxy) {
	push(normalized, {
		type: 'tproxy',
		tag: 'tproxy-in',
		listen: '0.0.0.0',
		listen_port: tproxy_port,
		network: 'udp'
	});
}

if (!has_dns_in) {
	push(normalized, {
		type: 'direct',
		tag: 'dns-in',
		listen: '0.0.0.0',
		listen_port: dns_port
	});
}

cfg.inbounds = normalized;

for (let ob in (cfg.outbounds || [])) {
	if (!ob || type(ob) != 'object')
		continue;

	let t = ob.type || '';
	if (t == 'selector' || t == 'urltest' || t == 'fallback' || t == 'load_balance' || t == 'dns' || t == 'block')
		continue;

		/* Clash 的 SS obfs 写法是 plugin=obfs + plugin-opts 对象；sing-box 需要
		 * plugin=obfs-local + "obfs=http;obfs-host=..." 字符串。 */
		if (ob.plugin == 'obfs')
			ob.plugin = 'obfs-local';
		if (ob.plugin_opts != null && type(ob.plugin_opts) == 'object') {
			let _parts = [];
			let _map = { mode: 'obfs', host: 'obfs-host', uri: 'obfs-uri' };
			for (let _k in ob.plugin_opts) {
				let _v = ob.plugin_opts[_k];
				if (type(_v) == 'object' || type(_v) == 'array') continue;
				push(_parts, (_map[_k] || _k) + '=' + _v);
			}
			ob.plugin_opts = join(';', _parts);
		}
		if (ob.plugin != null && ob.plugin != 'obfs-local' && ob.plugin != 'v2ray-plugin' && ob.plugin != 'shadow-tls') {
			delete ob.plugin;
			delete ob.plugin_opts;
		}

		if (wants_tun) {
			delete ob.routing_mark;
			if (ob.type == 'direct' && ob.tag == 'DIRECT' && default_interface)
				ob.bind_interface = ob.bind_interface || default_interface;
		} else if (ob.routing_mark == null)
			ob.routing_mark = routing_mark;
	}

/* 把机场塞的"伪节点"（Traffic:/Expire:/剩余流量/官网/QQ/套餐/续费 等）从 selector/urltest 列表中剔除。
 * 它们是真 SS/Vmess 配置（保留让 UI 抽流量到期），但服务端不真转发；放进 selector 后默认选第一个 / urltest 选最快，
 * 国外流量会被吸到伪节点 → 表现为"国内通、国外 out"。 */
let _is_pseudo_tag = function(t) {
	if (!t) return false;
	return match(t, /^Traffic[：:]/) || match(t, /^Expire[：:]/) ||
	       match(t, /剩余流量|剩余[：:]/) || match(t, /距离下次重置/) ||
	       match(t, /到期(时间|日期)?[：:]/) ||
	       match(t, /官网[：:]|网站[：:]|套餐[：:]?|客服[：:]/) ||
	       match(t, /QQ[群]?[：:]/) || match(t, /Telegram|TG群|官方群/) ||
	       match(t, /续费|订阅地址|流量重置/);
};
for (let ob in (cfg.outbounds || [])) {
	if (!ob || type(ob) != 'object') continue;
	let t = ob.type || '';
	if (t != 'selector' && t != 'urltest' && t != 'fallback' && t != 'load_balance') continue;
	if (type(ob.outbounds) != 'array') continue;
	let cleaned = [];
	for (let tag in ob.outbounds) if (!_is_pseudo_tag(tag)) push(cleaned, tag);
	ob.outbounds = cleaned;
}

cfg.route = cfg.route || {};
cfg.route.rules = cfg.route.rules || [];
let has_dns_hijack = false;
for (let rule in cfg.route.rules) {
	if (!rule || type(rule) != 'object')
		continue;
	if (rule.inbound == 'dns-in' && rule.action == 'hijack-dns') {
		has_dns_hijack = true;
		break;
	}
}
if (!has_dns_hijack) {
	unshift(cfg.route.rules, {
		inbound: 'dns-in',
		action: 'hijack-dns'
	});
}
cfg.route.auto_detect_interface = true;
apply_dns_from_uci();

/* 防 DNS 泄漏：阻断 DoT/DoQ（853），强制 DNS 走核心。插在 hijack-dns 之后保证 dns 入站不被误杀 */
if (opt_bool(uci_opt('dns_leak_protect', '0'), false)) {
	let _has_853 = false;
	for (let _r in cfg.route.rules) {
		if (_r && type(_r) == 'object' && _r.action == 'reject' && _r.port) {
			if (type(_r.port) == 'array') {
				for (let _p in _r.port) if (_p == 853) { _has_853 = true; break; }
			} else if (_r.port == 853) {
				_has_853 = true;
			}
		}
		if (_has_853) break;
	}
	if (!_has_853) {
		let _new_rules = [];
		let _inserted = false;
		for (let _ri = 0; _ri < length(cfg.route.rules); _ri++) {
			push(_new_rules, cfg.route.rules[_ri]);
			if (!_inserted && cfg.route.rules[_ri] && cfg.route.rules[_ri].action == 'hijack-dns') {
				push(_new_rules, { port: [853], action: 'reject' });
				_inserted = true;
			}
		}
		if (!_inserted) unshift(_new_rules, { port: [853], action: 'reject' });
		cfg.route.rules = _new_rules;
	}
}

if (uci_opt('enhanced_mode', 'fake-ip') == 'fake-ip') {
	add_remote_rule_set('geolocation-!cn',
		'https://github.com/MetaCubeX/meta-rules-dat/raw/refs/heads/sing/geo/geosite/geolocation-!cn.srs');
}

/* 本地有 .srs 则转 local；剩余的 remote rule_set 必须保留/补 download_detour。
 * 大陆首启动死锁链：没 srs → 拉规则 → 走 ♻️ 自动选择 → urltest 测速要拨机场 →
 *   要解析机场域名 → 又被 DNS rules 卷进未加载的 rule_set → deadline。
 * 模板里 srs URL 都走 https://gh-proxy.com/...（大陆直连可达），所以 download_detour
 * 必须是 DIRECT；用 direct outbound 的真实 tag 优先，没有再退到字符串 'DIRECT'。 */
let _pick_dl_detour = function() {
	if (cfg.outbounds) {
		for (let ob in cfg.outbounds) {
			if (ob && ob.type == 'direct' && ob.tag) return ob.tag;
		}
	}
	return 'DIRECT';
};
let _dl_detour = _pick_dl_detour();
for (let rs in (cfg.route || {}).rule_set || []) {
	if (!rs) continue;
	if (rs.type != 'remote') { delete rs.download_detour; continue; }
	let path = local_rule_set_path(rs.tag || '');
	if (rs.tag && access(path, 'r')) {
		delete rs.url; delete rs.download_detour; rs.type = 'local'; rs.path = path;
		continue;
	}
	if (keep_remote_rule_set(rs) && rs.url) {
		rs.url = normalize_rule_set_url(rs.url);
		rs.download_detour = _dl_detour;
		continue;
	}
	/* 没有本地缓存 → 跳过该远程规则集。防止下载失败阻塞 sing-box 启动。
	 * 规则集在有代理后通过后台脚本下载到 /usr/share/clashoo/ruleset/。 */
	continue;

}
/* 过滤掉 type=remote 且无本地缓存的规则集 */
let _clean_rs = [];
for (let _rsi = 0; _rsi < length(cfg.route.rule_set); _rsi++) {
	let _rs = cfg.route.rule_set[_rsi];
	if (!_rs) continue;
	if (_rs.type == 'remote' && _rs.url != null) {
		let _local_path = local_rule_set_path(_rs.tag || '');
		if (!_rs.tag || !access(_local_path, 'r'))
			if (keep_remote_rule_set(_rs) && _rs.url) {
				_rs.url = normalize_rule_set_url(_rs.url);
				_rs.download_detour = _dl_detour;
				push(_clean_rs, _rs);
				continue;
			} else {
				continue; /* 无本地缓存 → 不加入最终列表 */
			}
		/* 有本地缓存 → 转 local */
		delete _rs.url; delete _rs.download_detour; _rs.type = 'local'; _rs.path = _local_path;
	}
	push(_clean_rs, _rs);
}
cfg.route.rule_set = _clean_rs;

	/* 删除引用了已移除 rule_set 的 DNS/路由规则，否则 sing-box FATAL: rule-set not found */
	let _existing_tags = {};
	for (let _rs in cfg.route.rule_set || []) if (_rs && _rs.tag) _existing_tags[_rs.tag] = true;
	let _rule_has_ref = function(_r) {
		if (!_r || type(_r) != 'object') return false;
		if (_r.rule_set) {
			if (type(_r.rule_set) == 'array') { for (let _t in _r.rule_set) if (!_existing_tags[_t]) return false; }
			else if (!_existing_tags[_r.rule_set]) return false;
		}
		return true;
	};
	/* 清理 dns.rules */
	if (cfg.dns && type(cfg.dns.rules) == 'array') {
		let _clean_dns_rules = [];
		for (let _dr in cfg.dns.rules) if (_rule_has_ref(_dr)) push(_clean_dns_rules, _dr);
		cfg.dns.rules = _clean_dns_rules;
	}
	/* 清理 route.rules */
	if (cfg.route && type(cfg.route.rules) == 'array') {
		let _clean_rt_rules = [];
		for (let _rr in cfg.route.rules) if (_rule_has_ref(_rr)) push(_clean_rt_rules, _rr);
		cfg.route.rules = _clean_rt_rules;
	}
	cfg.experimental = cfg.experimental || {};
cfg.experimental.clash_api = cfg.experimental.clash_api || {};
cfg.experimental.clash_api.external_controller = '0.0.0.0:' + dash_port;
cfg.experimental.clash_api.external_ui = '/etc/clashoo/dashboard';
cfg.experimental.clash_api.secret = dash_secret;

cfg.experimental.cache_file = {
	enabled: true,
	store_fakeip: true
};

/* OpenWrt already owns system time sync. Keep sing-box NTP disabled by
 * default to avoid noisy IPv6 UDP/123 failures on IPv4-only routers. */
cfg.ntp = cfg.ntp || {};
cfg.ntp.enabled = false;

cfg.log = cfg.log || {};
cfg.log.output = '/var/log/clashoo/core.log';
if (!cfg.log.level)
	cfg.log.level = 'info';

if (writefile(path, sprintf('%J', cfg)) === null) {
	print("write failed\n");
	exit(1);
}

print("normalized\n");
