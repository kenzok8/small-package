#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2023 ImmortalWrt.org
 */

'use strict';

import { writefile } from 'fs';
import { cursor } from 'uci';

import {
	isEmpty, strToBool, strToInt, strToTime,
	removeBlankAttrs, renderV2RayTransport, HP_DIR, RUN_DIR
} from 'homeproxy';

/* UCI config start */
const uci = cursor();

const uciconfig = 'homeproxy';
uci.load(uciconfig);

const uciserver = 'server';

const log_level = uci.get(uciconfig, uciserver, 'log_level') || 'warn';
/* UCI config end */

const config = {};

config.http_clients = [
	{
		tag: 'direct-http'
	}
];

/* Log */
config.log = {
	disabled: false,
	level: log_level,
	output: RUN_DIR + '/sing-box-s.log',
	timestamp: true
};

config.inbounds = [];

function render_server_tls(cfg) {
	if (cfg.tls !== '1' || !(cfg.type in [
		'anytls', 'http', 'hysteria', 'hysteria2', 'naive',
		'trojan', 'tuic', 'vless', 'vmess'
	]))
		return null;

	const use_acme = cfg.tls_acme === '1';
	const use_reality = !use_acme && cfg.tls_reality === '1';
	return {
		enabled: true,
		server_name: cfg.tls_sni,
		alpn: cfg.tls_alpn,
		min_version: cfg.tls_min_version,
		max_version: cfg.tls_max_version,
		cipher_suites: cfg.tls_cipher_suites,
		certificate_path: (!use_acme && !use_reality) ? cfg.tls_cert_path : null,
		key_path: (!use_acme && !use_reality) ? cfg.tls_key_path : null,
		certificate_provider: use_acme ? {
			type: 'acme',
			domain: cfg.tls_acme_domain,
			data_directory: HP_DIR + '/certs',
			default_server_name: cfg.tls_acme_dsn,
			email: cfg.tls_acme_email,
			provider: cfg.tls_acme_provider,
			disable_http_challenge: strToBool(cfg.tls_acme_dhc),
			disable_tls_alpn_challenge: strToBool(cfg.tls_acme_dtac),
			alternative_http_port: strToInt(cfg.tls_acme_ahp),
			alternative_tls_port: strToInt(cfg.tls_acme_atp),
			http_client: 'direct-http',
			external_account: (cfg.tls_acme_external_account === '1') ? {
				key_id: cfg.tls_acme_ea_keyid,
				mac_key: cfg.tls_acme_ea_mackey
			} : null,
			dns01_challenge: (cfg.tls_dns01_challenge === '1') ? {
				provider: cfg.tls_dns01_provider,
				access_key_id: cfg.tls_dns01_ali_akid,
				access_key_secret: cfg.tls_dns01_ali_aksec,
				region_id: cfg.tls_dns01_ali_rid,
				api_token: cfg.tls_dns01_cf_api_token
			} : null
		} : null,
		ech: (!use_reality && cfg.tls_ech_key) ? {
			enabled: true,
			key: split(cfg.tls_ech_key, '\n')
		} : null,
		reality: use_reality ? {
			enabled: true,
			private_key: cfg.tls_reality_private_key,
			short_id: cfg.tls_reality_short_id,
			max_time_difference: strToTime(cfg.tls_reality_max_time_difference),
			handshake: {
				server: cfg.tls_reality_server_addr,
				server_port: strToInt(cfg.tls_reality_server_port)
			}
		} : null
	};
}

function render_server_multiplex(cfg) {
	if (cfg.multiplex !== '1' || !(cfg.type in ['shadowsocks', 'trojan', 'vless', 'vmess']))
		return null;
	return {
		enabled: true,
		padding: strToBool(cfg.multiplex_padding),
		brutal: (cfg.multiplex_brutal === '1') ? {
			enabled: true,
			up_mbps: strToInt(cfg.multiplex_brutal_up),
			down_mbps: strToInt(cfg.multiplex_brutal_down)
		} : null
	};
}

uci.foreach(uciconfig, uciserver, (cfg) => {
	if (cfg.enabled !== '1')
		return;

	const inbound = {
		type: cfg.type,
		tag: 'cfg-' + cfg['.name'] + '-in',
		listen: cfg.address || '::',
		listen_port: strToInt(cfg.port),
		bind_interface: cfg.bind_interface,
		reuse_addr: strToBool(cfg.reuse_addr),
		tcp_fast_open: strToBool(cfg.tcp_fast_open),
		tcp_multi_path: strToBool(cfg.tcp_multi_path),
		udp_fragment: strToBool(cfg.udp_fragment),
		udp_timeout: strToTime(cfg.udp_timeout),
		network: (cfg.type in ['naive', 'shadowsocks']) ? cfg.network : null
	};

	let user = { name: 'cfg-' + cfg['.name'] + '-server' };
	switch (cfg.type) {
	case 'anytls':
		inbound.padding_scheme = cfg.anytls_padding_scheme;
		user.password = cfg.password;
		break;
	case 'http':
	case 'mixed':
	case 'naive':
	case 'socks':
		user = { username: cfg.username, password: cfg.password };
		break;
	case 'hysteria':
	case 'hysteria2':
		inbound.up_mbps = strToInt(cfg.hysteria_up_mbps);
		inbound.down_mbps = strToInt(cfg.hysteria_down_mbps);
		inbound.stream_receive_window = !isEmpty(cfg.hysteria_stream_receive_window) ? `${cfg.hysteria_stream_receive_window} B` : null;
		inbound.connection_receive_window = !isEmpty(cfg.hysteria_connection_receive_window) ? `${cfg.hysteria_connection_receive_window} B` : null;
		inbound.max_concurrent_streams = strToInt(cfg.hysteria_max_concurrent_streams);
		inbound.disable_path_mtu_discovery = strToBool(cfg.hysteria_disable_path_mtu_discovery);
		inbound.obfs = (cfg.type === 'hysteria2' && cfg.hysteria_obfs_type) ? {
			type: cfg.hysteria_obfs_type,
			password: cfg.hysteria_obfs_password
		} : cfg.hysteria_obfs_password;
		inbound.masquerade = cfg.hysteria_masquerade;
		if (cfg.type === 'hysteria') {
			user.auth = (cfg.hysteria_auth_type === 'base64') ? cfg.hysteria_auth_payload : null;
			user.auth_str = (cfg.hysteria_auth_type === 'string') ? cfg.hysteria_auth_payload : null;
		} else {
			inbound.ignore_client_bandwidth = strToBool(cfg.hysteria_ignore_client_bandwidth);
			user.password = cfg.password;
		}
		break;
	case 'shadowsocks':
		inbound.method = cfg.shadowsocks_encrypt_method;
		inbound.password = cfg.password;
		user = null;
		break;
	case 'trojan':
		user.password = cfg.password;
		inbound.transport = renderV2RayTransport(cfg, true);
		break;
	case 'tuic':
		inbound.congestion_control = cfg.tuic_congestion_control;
		inbound.auth_timeout = strToTime(cfg.tuic_auth_timeout);
		inbound.zero_rtt_handshake = strToBool(cfg.tuic_enable_zero_rtt);
		inbound.heartbeat = strToTime(cfg.tuic_heartbeat);
		user.uuid = cfg.uuid;
		user.password = cfg.password;
		break;
	case 'vless':
		user.uuid = cfg.uuid;
		user.flow = cfg.vless_flow;
		inbound.transport = renderV2RayTransport(cfg, true);
		break;
	case 'vmess':
		user.uuid = cfg.uuid;
		user.alterId = strToInt(cfg.vmess_alterid);
		inbound.transport = renderV2RayTransport(cfg, true);
		break;
	default:
		user = null;
	}

	inbound.users = user ? [user] : null;
	inbound.multiplex = render_server_multiplex(cfg);
	inbound.tls = render_server_tls(cfg);
	push(config.inbounds, inbound);
});

if (length(config.inbounds) === 0)
	exit(1);

system('mkdir -p ' + RUN_DIR);
if (!writefile(RUN_DIR + '/sing-box-s.json.new', sprintf('%.J\n', removeBlankAttrs(config))))
	exit(1);
