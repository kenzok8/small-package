/* thanks for homeproxy */

import { mkstemp, popen } from 'fs';

/* Global variables START */
export const HM_DIR = '/etc/fchomo';
export const EXE_DIR = '/usr/libexec/fchomo';
export const SDL_DIR = '/usr/share/fchomo';
export const RUN_DIR = '/var/run/fchomo';
export const PRESET_OUTBOUND = [
	'DIRECT',
	'REJECT',
	'REJECT-DROP',
	'PASS',
	'COMPATIBLE',
	'GLOBAL'
];
export const RULES_LOGICAL_TYPE = [
	'AND',
	'OR',
	'NOT'
];
/* Global variables END */

/* Utilities start */
/* Kanged from luci-app-commands */
export function shellQuote(s) {
	return `'${replace(s, "'", "'\\''")}'`;
};

export function isBinary(str) {
	for (let off = 0, byte = ord(str); off < length(str); byte = ord(str, ++off))
		if (byte <= 8 || (byte >= 14 && byte <= 31))
			return true;

	return false;
};

export function executeCommand(infd, ...args) {
	let outfd = mkstemp();
	let errfd = mkstemp();

	if (infd)
		push(args, `<&${infd.fileno()}`);

	const exitcode = system(`${join(' ', args)} >&${outfd.fileno()} 2>&${errfd.fileno()}`);

	outfd.seek();
	errfd.seek();

	const stdout = outfd.read(1024 * 1024) ?? '';
	const stderr = errfd.read(1024 * 1024) ?? '';

	outfd.close();
	errfd.close();

	const binary = isBinary(stdout);

	return {
		command: join(' ', args),
		stdout: binary ? null : stdout,
		stderr,
		exitcode,
		binary
	};
};

export function yqRead(flags, command, content) {
	let infd = mkstemp();

	if (content) {
		content = trim(content);
		content = replace(content, /\r\n?/g, '\n');
		if (!match(content, /\n$/))
			content += '\n';
	}
	infd.write(content);

	infd.seek();
	const out = executeCommand(infd, 'yq', flags, shellQuote(command));
	infd.close();

	return out.stdout;
};

export function yqReadFile(flags, command, filepath) {
	const out = executeCommand(null, 'yq', flags, shellQuote(command), filepath);

	return out.stdout;
};
/* Utilities end */

/* String helper start */
export function isEmpty(res) {                                            // no false, 0, NaN
	if (res == null || res in ['']) return true;                          // null, ''
	if (type(res) in ['array', 'object']) return length(res) === 0;       // empty Array/Object
	return false;
};

export function strToBool(str) {
	return (str === '1') || null;
};

export function strToInt(str) {
	if (isEmpty(str))
		return null;

	return !match(str, /^\d+$/) ? str : int(str) ?? null;
};

export function bytesizeToByte(str) {
	if (isEmpty(str))
		return null;

	let bytes = 0;
	let arr = match(str, /^(\d+)(k|m|g)?b?$/);
	if (arr) {
		if (arr[2] === 'k') {
			bytes = strToInt(arr[1]) * 1024;
		} else if (arr[2] === 'm') {
			bytes = strToInt(arr[1]) * 1048576;
		} else if (arr[2] === 'g') {
			bytes = strToInt(arr[1]) * 1073741824;
		} else
			bytes = strToInt(arr[1]);
	}

	return bytes;
};
export function durationToSecond(str) {
	if (isEmpty(str))
		return null;

	let seconds = 0;
	let arr = match(str, /^(\d+)(s|m|h|d)?$/);
	if (arr) {
		if (arr[2] === 's') {
			seconds = strToInt(arr[1]);
		} else if (arr[2] === 'm') {
			seconds = strToInt(arr[1]) * 60;
		} else if (arr[2] === 'h') {
			seconds = strToInt(arr[1]) * 3600;
		} else if (arr[2] === 'd') {
			seconds = strToInt(arr[1]) * 86400;
		} else
			seconds = strToInt(arr[1]);
	}

	return seconds;
};

export function arrToObj(res) {
	if (isEmpty(res))
		return null;

	let object;
	if (type(res) === 'array') {
		object = {};
		map(res, (e) => {
			if (type(e) === 'array')
				object[e[0]] = e[1];
		});
	} else
		return res;

	return object;
};

export function removeBlankAttrs(res) {
	let content;

	if (type(res) === 'object') {
		content = {};
		map(keys(res), (k) => {
			if (type(res[k]) in ['array', 'object'])
				content[k] = removeBlankAttrs(res[k]);
			else if (res[k] !== null && res[k] !== '')
				content[k] = res[k];
		});
	} else if (type(res) === 'array') {
		content = [];
		map(res, (k, i) => {
			if (type(k) in ['array', 'object'])
				push(content, removeBlankAttrs(k));
			else if (k !== null && k !== '')
				push(content, k);
		});
	} else
		return res;

	return content;
};
/* String helper end */

/* String universal start */
export function parseVlessEncryption(payload, side) {
	if (isEmpty(payload))
		return null;

	let content = json(trim(payload));

	let required = join('.', [
		content.method,
		content.xormode,
		side === 'server' ? content.ticket : side === 'client' ? content.rtt : null
	]);

	return required +
		(isEmpty(content.paddings) ? '' : '.' + join('.', content.paddings)) + // Optional
		(isEmpty(content.keypairs) ? '' : '.' + join('.', map(content.keypairs, e => e[side]))); // Required
};

export function parseListener(cfg, isClient, label) {
	return {
		name: cfg['.name'],
		type: cfg.type,

		listen: cfg.listen || '::',
		port: cfg.port,
		...(isClient ? {
			rule: cfg.rule,
			proxy: label,
		} : {}),

		/* HTTP / SOCKS / VMess / VLESS / Trojan / AnyTLS / Tuic / Hysteria2 */
		users: (cfg.type in ['http', 'socks', 'mixed', 'vmess', 'vless', 'trojan', 'trusttunnel']) ? [
			(cfg.username || cfg.vmess_uuid) ? {
				/* HTTP / SOCKS */
				username: cfg.username,
				password: cfg.password,

				/* VMess / VLESS */
				uuid: cfg.vmess_uuid,
				flow: cfg.vless_flow,
				alterId: strToInt(cfg.vmess_alterid)
			} : null
			/*{
			}*/
		] : ((cfg.type in ['mieru', 'anytls', 'tuic', 'hysteria2']) ? {
			/* Mieru / AnyTLS / Hysteria2 */
			...arrToObj([[cfg.username, cfg.password]]),

			/* Tuic */
			...arrToObj([[cfg.uuid, cfg.password]])
		} : null),

		/* Hysteria2 */
		up: strToInt(cfg.hysteria_up_mbps),
		down: strToInt(cfg.hysteria_down_mbps),
		"ignore-client-bandwidth": strToBool(cfg.hysteria_ignore_client_bandwidth),
		obfs: cfg.hysteria_obfs_type,
		"obfs-password": cfg.hysteria_obfs_password,
		masquerade: cfg.hysteria_masquerade,
		"realm-opts": cfg.hysteria2_realm === '1' ? {
			enable: true,
			"server-url": cfg.hysteria2_realm_server_url,
			token: cfg.hysteria2_realm_token,
			"realm-id": cfg.hysteria2_realm_id,
			"stun-servers": cfg.hysteria2_realm_stun_servers,
			// @TLS of server-url
			//sni,
			//alpn,
			//"skip-cert-verify",
			//fingerprint,
			//certificate,
			//"private-key"
		} : null,

		/* Hysteria2 Realmserver */
		token: cfg.hysteria2_realmserver_token,
		"max-realms": strToInt(cfg.hysteria2_realmserver_max_realms),
		"max-realms-per-ip": strToInt(cfg.hysteria2_realmserver_max_realms_per_ip),
		"trusted-proxy-header": cfg.hysteria2_realmserver_trusted_proxy_header,
		"realm-name-pattern": cfg.hysteria2_realmserver_realm_name_pattern,

		/* Shadowsocks */
		cipher: cfg.shadowsocks_chipher,
		password: cfg.shadowsocks_password,

		/* Mieru */
		transport: cfg.mieru_transport,
		"traffic-pattern": cfg.mieru_traffic_pattern,
		"user-hint-is-mandatory": strToBool(cfg.mieru_user_hint_is_mandatory),

		/* Sudoku */
		key: cfg.sudoku_key,
		"aead-method": replace(cfg.sudoku_aead_method || '', 'chacha20-ietf-poly1305', 'chacha20-poly1305') || null,
		"padding-min": strToInt(cfg.sudoku_padding_min),
		"padding-max": strToInt(cfg.sudoku_padding_max),
		"table-type": cfg.sudoku_table_type,
		"custom-tables": cfg.sudoku_custom_tables,
		"handshake-timeout": strToInt(cfg.sudoku_handshake_timeout) ?? null,
		"enable-pure-downlink": (cfg.sudoku_enable_pure_downlink === '0') ? false : null,
		...(cfg.type === 'sudoku' ? {
			httpmask: (cfg.sudoku_http_mask === '0') ? { disable: true } : {
				disable: false,
				mode: cfg.sudoku_http_mask_mode,
				"path-root": cfg.sudoku_path_root,
			}
		} : {}),
		fallback: (cfg.sudoku_http_mask === '0') ? null : cfg.sudoku_fallback,

		/* Tuic */
		"max-idle-time": durationToSecond(cfg.tuic_max_idle_time),
		"authentication-timeout": durationToSecond(cfg.tuic_authentication_timeout),
		"max-udp-relay-packet-size": strToInt(cfg.tuic_max_udp_relay_packet_size),

		/* Trojan */
		"ss-option": cfg.trojan_ss_enabled === '1' ? {
			enabled: true,
			method: cfg.trojan_ss_chipher,
			password: cfg.trojan_ss_password
		} : null,

		/* AnyTLS */
		"padding-scheme": cfg.anytls_padding_scheme,

		/* VMess / VLESS */
		decryption: cfg.vless_decryption === '1' ? parseVlessEncryption(cfg.vless_encryption_hmpayload, 'server') : null,

		/* Tunnel */
		target: cfg.tunnel_target,

		/* Plugin fields */
		...(cfg.plugin ? {
			// obfs-simple
			"simple-obfs": cfg.plugin === 'obfs' ? {
				enable: true,
				mode: cfg.plugin_opts_obfsmode
			} : null,
			// shadow-tls
			"shadow-tls": cfg.plugin === 'shadow-tls' ? {
				enable: true,
				version: strToInt(cfg.plugin_opts_shadowtls_version),
				...(strToInt(cfg.plugin_opts_shadowtls_version) >= 3 ? {
					users: [
						{
							name: 1,
							password: cfg.plugin_opts_thetlspassword
						}
					],
				} : { password: cfg.plugin_opts_thetlspassword }),
				handshake: {
					dest: cfg.plugin_opts_handshake_dest
				},
			} : null
		} : {}),

		/* Extra fields */
		"congestion-controller": cfg.congestion_controller,
		"bbr-profile": cfg.bbr_profile,
		network: cfg.network,
		udp: strToBool(cfg.udp),

		/* TLS fields */
		...(cfg.tls === '1' ? {
			alpn: cfg.tls_alpn,
			...(cfg.tls_reality === '1' ? {
				"reality-config": {
					dest: cfg.tls_reality_dest,
					"private-key": cfg.tls_reality_private_key,
					"short-id": cfg.tls_reality_short_id,
					"server-names": cfg.tls_reality_server_names
				}
			} : {
				certificate: cfg.tls_cert_path,
				"private-key": cfg.tls_key_path
			}),
			"client-auth-type": cfg.tls_client_auth_type,
			"client-auth-cert": cfg.tls_client_auth_cert_path,
			"ech-key": cfg.tls_ech_key,
		} : {}),

		/* Transport fields */
		...(cfg.transport_enabled === '1' ? {
			"grpc-service-name": cfg.transport_type === 'grpc' ? cfg.transport_grpc_servicename : null,
			"ws-path": cfg.transport_type === 'ws' ? cfg.transport_path : null,
			"xhttp-config": cfg.transport_type === 'xhttp' ? {
				path: cfg.transport_path,
				host: cfg.transport_host,
				mode: cfg.transport_xhttp_mode,
				"no-sse-header": strToBool(cfg.transport_xhttp_no_sse_header),
				"sc-max-buffered-posts": strToInt(cfg.transport_xhttp_sc_max_buffered_posts) || null,
				"sc-stream-up-server-secs": cfg.transport_xhttp_sc_stream_up_server_secs,
				"sc-max-each-post-bytes": strToInt(cfg.transport_xhttp_sc_max_each_post_bytes) || null,
				// @其他的配置
			} : null
		} : {})
	}
};
/* String universal end */
