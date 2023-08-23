#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2023 ImmortalWrt.org
 */

'use strict';

import { readfile, writefile } from 'fs';
import { cursor } from 'uci';

import {
	executeCommand, isEmpty, strToInt,
	removeBlankAttrs, validateHostname, validation,
	HP_DIR, RUN_DIR
} from 'homeproxy';

/* UCI config start */
const uci = cursor();

const uciconfig = 'homeproxy';
uci.load(uciconfig);

const uciserver = 'server';

const config = {};

/* Log */
config.log = {
	disabled: false,
	level: 'warn',
	output: RUN_DIR + '/sing-box-s.log',
	timestamp: true
};

config.inbounds = [];

uci.foreach(uciconfig, uciserver, (cfg) => {
	if (cfg.enabled !== '1')
		return;

	push(config.inbounds, {
		type: cfg.type,
		tag: 'cfg-' + cfg['.name'] + '-in',

		listen: '::',
		listen_port: strToInt(cfg.port),
		tcp_fast_open: (cfg.tcp_fast_open === '1') || null,
		udp_fragment: (cfg.udp_fragment === '1') || null,
		sniff: true,
		sniff_override_destination: (cfg.sniff_override === '1'),
		domain_strategy: cfg.domain_strategy,
		proxy_protocol: (cfg.proxy_protocol === '1') || null,
		proxy_protocol_accept_no_header: (cfg.proxy_protocol_accept_no_header === '1') || null,
		network: cfg.network,

		/* Hysteria */
		up_mbps: strToInt(cfg.hysteria_up_mbps),
		down_mbps: strToInt(cfg.hysteria_down_mbps),
		obfs: cfg.hysteria_obfs_password,
		recv_window_conn: strToInt(cfg.hysteria_recv_window_conn),
		recv_window_client: strToInt(cfg.hysteria_revc_window_client),
		max_conn_client: strToInt(cfg.hysteria_max_conn_client),
		disable_mtu_discovery: (cfg.hysteria_disable_mtu_discovery === '1') || null,

		/* Shadowsocks */
		method: (cfg.type === 'shadowsocks') ? cfg.shadowsocks_encrypt_method : null,
		password: (cfg.type in ['shadowsocks', 'shadowtls']) ? cfg.password : null,

		/* Tuic */
		congestion_control: cfg.tuic_congestion_control,
		auth_timeout: cfg.tuic_auth_timeout ? (cfg.tuic_auth_timeout + 's') : null,
		zero_rtt_handshake: (cfg.tuic_enable_zero_rtt === '1') || null,
		heartbeat: cfg.tuic_heartbeat ? (cfg.tuic_heartbeat + 's') : null,

		/* HTTP / Hysteria / Socks / Trojan / Tuic / VLESS / VMess */
		users: (cfg.type !== 'shadowsocks') ? [
			{
				name: !(cfg.type in ['http', 'socks']) ? 'cfg-' + cfg['.name'] + '-server' : null,
				username: cfg.username,
				password: cfg.password,

				/* Hysteria */
				auth: (cfg.hysteria_auth_type === 'base64') ? cfg.hysteria_auth_payload : null,
				auth_str: (cfg.hysteria_auth_type === 'string') ? cfg.hysteria_auth_payload : null,

				/* Tuic */
				uuid: cfg.uuid,

				/* VLESS / VMess */
				flow: cfg.vless_flow,
				alterId: strToInt(cfg.vmess_alterid)
			}
		] : null,

		tls: (cfg.tls === '1') ? {
			enabled: true,
			server_name: cfg.tls_sni,
			alpn: cfg.tls_alpn,
			min_version: cfg.tls_min_version,
			max_version: cfg.tls_max_version,
			cipher_suites: cfg.tls_cipher_suites,
			certificate_path: cfg.tls_cert_path,
			key_path: cfg.tls_key_path,
			acme: (cfg.tls_acme === '1') ? {
				domain: cfg.tls_acme_domains,
				data_directory: HP_DIR + '/certs',
				default_server_name: cfg.tls_acme_dsn,
				email: cfg.tls_acme_email,
				provider: cfg.tls_acme_provider,
				disable_http_challenge: (cfg.tls_acme_dhc === '1'),
				disable_tls_alpn_challenge: (cfg.tls_acme_dtac === '1'),
				alternative_http_port: strToInt(cfg.tls_acme_ahp),
				alternative_tls_port: strToInt(cfg.tls_acme_atp),
				external_account: (cfg.tls_acme_external_account === '1') ? {
					key_id: cfg.tls_acme_ea_keyid,
					mac_key: cfg.tls_acme_ea_mackey
				} : null
			} : null,
			reality: (cfg.tls_reality === '1') ? {
				enabled: true,
				private_key: cfg.tls_reality_private_key,
				short_id: cfg.tls_reality_short_id,
				max_time_difference: cfg.tls_reality_max_time_difference ? (cfg.max_time_difference + 's') : null,
				handshake: {
					server: cfg.tls_reality_server_addr,
					server_port: cfg.tls_reality_server_port
					}
			} : null
		} : null,

		transport: !isEmpty(cfg.transport) ? {
			type: cfg.transport,
			host: cfg.http_host,
			path: cfg.http_path || cfg.ws_path,
			headers: cfg.ws_host ? {
				Host: cfg.ws_host
			} : null,
			method: cfg.http_method,
			max_early_data: strToInt(cfg.websocket_early_data),
			early_data_header_name: cfg.websocket_early_data_header,
			service_name: cfg.grpc_servicename,
			idle_timeout: cfg.http_idle_timeout ? (cfg.http_idle_timeout + 's') : null,
			ping_timeout: cfg.http_ping_timeout ? (cfg.http_ping_timeout + 's') : null
		} : null
	});
});

if (length(config.inbounds) === 0)
	exit(1);

system('mkdir -p ' + RUN_DIR);
writefile(RUN_DIR + '/sing-box-s.json', sprintf('%.J\n', removeBlankAttrs(config)));
