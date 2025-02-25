#!/usr/bin/ucode

'use strict';

import { cursor } from 'uci';
import { connect } from 'ubus';
import { uci_bool, uci_array, trim_all } from '/etc/nikki/ucode/include.uc';

const uci = cursor();
const ubus = connect();

const config = {};

const mixin = uci_bool(uci.get('nikki', 'config', 'mixin'));

config['log-level'] = uci.get('nikki', 'mixin', 'log_level') ?? 'info';
config['mode'] = uci.get('nikki', 'mixin', 'mode') ?? 'rule';
config['find-process-mode'] = uci.get('nikki', 'mixin', 'match_process') ?? 'off';
config['interface-name'] = ubus.call('network.interface', 'status', {'interface': uci.get('nikki', 'mixin', 'outbound_interface')})?.l3_device ?? '';
config['ipv6'] = uci_bool(uci.get('nikki', 'mixin', 'ipv6'));
if (mixin) {
	config['unified-delay'] = uci_bool(uci.get('nikki', 'mixin', 'unify_delay'));
	config['tcp-concurrent'] = uci_bool(uci.get('nikki', 'mixin', 'tcp_concurrent'));
	config['keep-alive-idle'] = int(uci.get('nikki', 'mixin', 'tcp_keep_alive_idle') ?? '600');
	config['keep-alive-interval'] = int(uci.get('nikki', 'mixin', 'tcp_keep_alive_interval') ?? '15');
}

config['external-ui'] = uci.get('nikki', 'mixin', 'ui_path') ?? 'ui';
config['external-ui-name'] = uci.get('nikki', 'mixin', 'ui_name') ?? '';
config['external-ui-url'] = uci.get('nikki', 'mixin', 'ui_url');
config['external-controller'] = '0.0.0.0' + ':' + (uci.get('nikki', 'mixin', 'api_port') ?? '9090');
config['secret'] = uci.get('nikki', 'mixin', 'api_secret') ?? '666666';

config['allow-lan'] = uci_bool(uci.get('nikki', 'mixin', 'allow_lan'));
config['port'] = int(uci.get('nikki', 'mixin', 'http_port') ?? '8080');
config['socks-port'] = int(uci.get('nikki', 'mixin', 'socks_port') ?? '1080');
config['mixed-port'] = int(uci.get('nikki', 'mixin', 'mixed_port') ?? '7890');
config['redir-port'] = int(uci.get('nikki', 'mixin', 'redir_port') ?? '7891');
config['tproxy-port'] = int(uci.get('nikki', 'mixin', 'tproxy_port') ?? '7892');

if (uci_bool(uci.get('nikki', 'mixin', 'authentication'))) {
	config['authentication'] = [];
	uci.foreach('nikki', 'authentication', (section) => {
		if (!uci_bool(section.enabled)) {
			return;
		}
		push(config['authentication'], `${section.username}:${section.password}`);
	});
}

config['tun'] = {};
if (uci.get('nikki', 'proxy', 'tcp_transparent_proxy_mode') == 'tun' || uci.get('nikki', 'proxy', 'udp_transparent_proxy_mode') == 'tun') {
	config['tun']['enable'] = true;
	config['tun']['auto-route'] = false;
	config['tun']['auto-redirect'] = false;
	config['tun']['auto-detect-interface'] = false;
	config['tun']['device'] = uci.get('nikki', 'mixin', 'tun_device') ?? 'nikki';
	config['tun']['stack'] = uci.get('nikki', 'mixin', 'tun_stack') ?? 'system';
	config['tun']['mtu'] = int(uci.get('nikki', 'mixin', 'tun_mtu') ?? '9000');
	config['tun']['gso'] = uci_bool(uci.get('nikki', 'mixin', 'tun_gso'));
	config['tun']['gso-max-size'] = int(uci.get('nikki', 'mixin', 'tun_gso_max_size') ?? '65536');
	config['tun']['endpoint-independent-nat'] = uci_bool(uci.get('nikki', 'mixin', 'tun_endpoint_independent_nat'));
	if (uci_bool(uci.get('nikki', 'mixin', 'tun_dns_hijack'))) {
		config['tun']['dns-hijack'] = uci_array(uci.get('nikki', 'mixin', 'tun_dns_hijacks'));
	}
} else {
	config['tun']['enable'] = false;
}

config['dns'] = {};
config['dns']['enable'] = true;
config['dns']['listen'] = '0.0.0.0' + ':' + (uci.get('nikki', 'mixin', 'dns_port') ?? '1053');
config['dns']['ipv6'] = uci_bool(uci.get('nikki', 'mixin', 'dns_ipv6'));
config['dns']['enhanced-mode'] = uci.get('nikki', 'mixin', 'dns_mode') ?? 'redir-host';
config['dns']['fake-ip-range'] = uci.get('nikki', 'mixin', 'fake_ip_range') ?? '198.18.0.1/16';
if (uci_bool(uci.get('nikki', 'mixin', 'fake_ip_filter'))) {
	config['dns']['fake-ip-filter'] = uci_array(uci.get('nikki', 'mixin', 'fake_ip_filters'));
	config['dns']['fake-ip-filter-mode'] = uci.get('nikki', 'mixin', 'fake_ip_filter_mode') ?? 'blacklist';
}
if (mixin) {
	config['dns']['respect-rules'] = uci_bool(uci.get('nikki', 'mixin', 'dns_respect_rules'));
	config['dns']['prefer-h3'] = uci_bool(uci.get('nikki', 'mixin', 'dns_doh_prefer_http3'));
	config['dns']['use-system-hosts'] = uci_bool(uci.get('nikki', 'mixin', 'dns_system_hosts'));
	config['dns']['use-hosts'] = uci_bool(uci.get('nikki', 'mixin', 'dns_hosts'));
	if (uci_bool(uci.get('nikki', 'mixin', 'hosts'))) {
		config['hosts'] = {};
		uci.foreach('nikki', 'hosts', (section) => {
			if (!uci_bool(section.enabled)) {
				return;
			}
			config['hosts'][section.domain_name] = uci_array(section.ip);
		});
	}
	if (uci_bool(uci.get('nikki', 'mixin', 'dns_nameserver'))) {
		config['dns']['default-nameserver'] = [];
		config['dns']['proxy-server-nameserver'] = [];
		config['dns']['direct-nameserver'] = [];
		config['dns']['nameserver'] = [];
		config['dns']['fallback'] = [];
		uci.foreach('nikki', 'nameserver', (section) => {
			if (!uci_bool(section.enabled)) {
				return;
			}
			push(config['dns'][section.type], ...uci_array(section.nameserver));
		})
	}
	if (uci_bool(uci.get('nikki', 'mixin', 'dns_nameserver_policy'))) {
		config['dns']['nameserver-policy'] = {};
		uci.foreach('nikki', 'nameserver_policy', (section) => {
			if (!uci_bool(section.enabled)) {
				return;
			}
			config['dns']['nameserver-policy'][section.matcher] = uci_array(section.nameserver);
		});
	}
}

if (mixin) {
	config['sniffer'] = {};
	config['sniffer']['enable'] = uci_bool(uci.get('nikki', 'mixin', 'sniffer'));
	config['sniffer']['force-dns-mapping'] = uci_bool(uci.get('nikki', 'mixin', 'sniffer_sniff_dns_mapping'));
	config['sniffer']['parse-pure-ip'] = uci_bool(uci.get('nikki', 'mixin', 'sniffer_sniff_pure_ip'));
	config['sniffer']['override-destination'] = uci_bool(uci.get('nikki', 'mixin', 'sniffer_overwrite_destination'));
	if (uci_bool(uci.get('nikki', 'mixin', 'sniffer_force_domain_name'))) {
		config['sniffer']['force-domain'] = uci_array(uci.get('nikki', 'mixin', 'sniffer_force_domain_names'));
	}
	if (uci_bool(uci.get('nikki', 'mixin', 'sniffer_ignore_domain_name'))) {
		config['sniffer']['skip-domain'] = uci_array(uci.get('nikki', 'mixin', 'sniffer_ignore_domain_names'));
	}
	if (uci_bool(uci.get('nikki', 'mixin', 'sniffer_sniff'))) {
		config['sniffer']['sniff'] = {};
		config['sniffer']['sniff']['HTTP'] = {};
		config['sniffer']['sniff']['TLS'] = {};
		config['sniffer']['sniff']['QUIC'] = {};
		uci.foreach('nikki', 'sniff', (section) => {
			if (!uci_bool(section.enabled)) {
				return;
			}
			config['sniffer']['sniff'][section.protocol]['port'] = uci_array(section.port);
			config['sniffer']['sniff'][section.protocol]['override-destination'] = uci_bool(section.overwrite_destination);
		});
	}
}

config['profile'] = {};
config['profile']['store-selected'] = uci_bool(uci.get('nikki', 'mixin', 'selection_cache'));
config['profile']['store-fake-ip'] = uci_bool(uci.get('nikki', 'mixin', 'fake_ip_cache'));

if (uci_bool(uci.get('nikki', 'mixin', 'rule_provider'))) {
	config['rule-providers'] = {};
	uci.foreach('nikki', 'rule_provider', (section) => {
		if (!uci_bool(section.enabled)) {
			return;
		}
		if (section.type == 'http') {
			config['rule-providers'][section.name] = {
				type: section.type,
				url: section.url,
				proxy: section.node,
				size_limit: section.file_size_limit,
				format: section.file_format,
				behavior: section.behavior,
				interval: section.update_interval,
			}
		} else if (section.type == 'file') {
			config['rule-providers'][section.name] = {
				type: section.type,
				path: section.file_path,
				format: section.file_format,
				behavior: section.behavior,
			}
		}
	})
}
if (uci_bool(uci.get('nikki', 'mixin', 'rule'))) {
	config['nikki-rules'] = [];
	uci.foreach('nikki', 'rule', (section) => {
		if (!uci_bool(section.enabled)) {
			return;
		}
		let rule;
		if (length(section.type) > 0) {
			rule = `${section.type},${section.matcher},${section.node}`;
		} else {
			rule = `${section.matcher},${section.node}`;
		}
		if (uci_bool(section.no_resolve)) {
			rule += ',no_resolve';
		}
		push(config['nikki-rules'], rule);
	})
}

if (mixin) {
	config['geodata-mode'] = uci.get('nikki', 'mixin', 'geoip_format') == 'dat';
	config['geodata-loader'] = uci.get('nikki', 'mixin', 'geodata_loader') ?? 'memconservative';
	config['geox-url'] = {};
	config['geox-url']['geosite'] = uci.get('nikki', 'mixin', 'geosite_url');
	config['geox-url']['mmdb'] = uci.get('nikki', 'mixin', 'geoip_mmdb_url');
	config['geox-url']['geoip'] = uci.get('nikki', 'mixin', 'geoip_dat_url');
	config['geox-url']['asn'] = uci.get('nikki', 'mixin', 'geoip_asn_url');
	config['geo-auto-update'] = uci_bool(uci.get('nikki', 'mixin', 'geox_auto_update'));
	config['geo-update-interval'] = int(uci.get('nikki', 'mixin', 'geox_update_interval') ?? '24');
}

print(trim_all(config));