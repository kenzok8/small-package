#!/usr/bin/ucode

'use strict';

import { cursor } from 'uci';

import {
	isEmpty, strToBool, strToInt, durationToSecond,
	arrToObj, removeBlankAttrs,
	HM_DIR, RUN_DIR, PRESET_OUTBOUND
} from 'fchomo';

/* UCI config START */
const uci = cursor();

const uciconf = 'fchomo';
uci.load(uciconf);

const uciserver = 'server';

/* UCI config END */

/* Config helper START */
function parse_users(cfg) {
	if (isEmpty(cfg))
		return null;

	let uap, arr, users=[];
	for (uap in cfg) {
		arr = split(uap, ':');
		users[arr[0]] = arr[1];
	}

	return users;
}
/* Config helper END */

/* Main */
const config = {};

/* Inbound START */
config.listeners = [];
uci.foreach(uciconf, uciserver, (cfg) => {
	if (cfg.enabled === '0')
		return;

	push(config.listeners, {
		name: cfg['.name'],
		type: cfg.type,

		listen: cfg.listen || '::',
		port: strToInt(cfg.port),
		proxy: 'DIRECT',
		udp: strToBool(cfg.udp),

		/* Hysteria2 */
		up: strToInt(cfg.hysteria_up_mbps),
		down: strToInt(cfg.hysteria_down_mbps),
		"ignore-client-bandwidth": strToBool(cfg.hysteria_ignore_client_bandwidth),
		obfs: cfg.hysteria_obfs_type,
		"obfs-password": cfg.hysteria_obfs_password,
		masquerade: cfg.hysteria_masquerade,

		/* Shadowsocks */
		cipher: cfg.shadowsocks_chipher,
		password: cfg.shadowsocks_password,

		/* Tuic */
		"congestion-controller": cfg.tuic_congestion_controller,
		"max-idle-time": durationToSecond(cfg.tuic_max_idle_time),
		"authentication-timeout": durationToSecond(cfg.tuic_authentication_timeout),
		"max-udp-relay-packet-size": strToInt(cfg.tuic_max_udp_relay_packet_size),

		/* HTTP / SOCKS / VMess / Tuic / Hysteria2 */
		users: (cfg.type in ['http', 'socks', 'mixed', 'vmess']) ? [
			{
				/* HTTP / SOCKS */
				username: cfg.username,
				password: cfg.password,

				/* VMess */
				uuid: cfg.vmess_uuid,
				alterId: strToInt(cfg.vmess_alterid)
			}
			/*{
			}*/
		] : ((cfg.type in ['tuic', 'hysteria2']) ? {
			/* Hysteria2 */
			...arrToObj([[cfg.username, cfg.password]]),

			/* Tuic */
			...arrToObj([[cfg.uuid, cfg.password]])
		} : null),

		/* TLS */
		...(cfg.tls === '1' ? {
			alpn: cfg.tls_alpn,
			certificate: cfg.tls_cert_path,
			"private-key": cfg.tls_key_path
		} : {})
	});
});
/* Inbound END */

printf('%.J\n', removeBlankAttrs(config));
