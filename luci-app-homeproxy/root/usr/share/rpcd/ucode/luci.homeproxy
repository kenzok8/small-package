#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2023-2024 ImmortalWrt.org
 */

'use strict';

import { access, error, lstat, popen, readfile, writefile } from 'fs';

/* Kanged from ucode/luci */
function shellquote(s) {
	return `'${replace(s, "'", "'\\''")}'`;
}

function hasKernelModule(kmod) {
	return (system(sprintf('[ -e "/lib/modules/$(uname -r)"/%s ]', shellquote(kmod))) === 0);
}

const HP_DIR = '/etc/homeproxy';
const RUN_DIR = '/var/run/homeproxy';

const methods = {
	acllist_read: {
		args: { type: 'type' },
		call: function(req) {
			if (index(['direct_list', 'proxy_list'], req.args?.type) === -1)
				return { content: null, error: 'illegal type' };

			const filecontent = readfile(`${HP_DIR}/resources/${req.args?.type}.txt`);
			return { content: filecontent };
		}
	},
	acllist_write: {
		args: { type: 'type', content: 'content' },
		call: function(req) {
			if (index(['direct_list', 'proxy_list'], req.args?.type) === -1)
				return { result: false, error: 'illegal type' };

			const file = `${HP_DIR}/resources/${req.args?.type}.txt`;
			let content = req.args?.content;

			/* Sanitize content */
			if (content) {
				content = trim(content);
				content = replace(content, /\r\n?/g, '\n');
				if (!match(content, /\n$/))
					content += '\n';
			}

			system(`mkdir -p ${HP_DIR}/resources`);
			writefile(file, content);

			return { result: true };
		}
	},

	certificate_write: {
		args: { filename: 'filename' },
		call: function(req) {
			const writeCertificate = (filename, priv) => {
				const tmpcert = '/tmp/homeproxy_certificate.tmp';
				const filestat = lstat(tmpcert);

				if (!filestat || filestat.type !== 'file' || filestat.size <= 0) {
					system(`rm -f ${tmpcert}`);
					return { result: false, error: 'empty certificate file' };
				}

				let filecontent = readfile(tmpcert);
				if (is_binary(filecontent)) {
					system(`rm -f ${tmpcert}`);
					return { result: false, error: 'illegal file type: binary' };
				}

				/* Kanged from luci-proto-openconnect */
				const beg = priv ? /^-----BEGIN (RSA|EC) PRIVATE KEY-----$/ : /^-----BEGIN CERTIFICATE-----$/,
				      end = priv ? /^-----END (RSA|EC) PRIVATE KEY-----$/ : /^-----END CERTIFICATE-----$/,
				      lines = split(trim(filecontent), /[\r\n]/);
				let start = false, i;

				for (i = 0; i < length(lines); i++) {
					if (match(lines[i], beg))
						start = true;
					else if (start && !b64dec(lines[i]) && length(lines[i]) !== 64)
						break;
				}

				if (!start || i < length(lines) - 1 || !match(lines[i], end)) {
					system(`rm -f ${tmpcert}`);
					return { result: false, error: 'this does not look like a correct PEM file' };
				}

				/* Sanitize certificate */
				filecontent = trim(filecontent);
				filecontent = replace(filecontent, /\r\n?/g, '\n');
				if (!match(filecontent, /\n$/))
					filecontent += '\n';

				system(`mkdir -p ${HP_DIR}/certs`);
				writefile(`${HP_DIR}/certs/${filename}.pem`, filecontent);
				system(`rm -f ${tmpcert}`);

				return { result: true };
			};

			const filename = req.args?.filename;
			switch (filename) {
			case 'client_ca':
			case 'server_publickey':
				return writeCertificate(filename, false);
				break;
			case 'server_privatekey':
				return writeCertificate(filename, true);
				break;
			default:
				return { result: false, error: 'illegal cerificate filename' };
				break;
			}
		}
	},

	connection_check: {
		args: { site: 'site' },
		call: function(req) {
			let url;
			switch(req.args?.site) {
			case 'baidu':
				url = 'https://www.baidu.com';
				break;
			case 'google':
				url = 'https://www.google.com';
				break;
			default:
				return { result: false, error: 'illegal site' };
				break;
			}

			return { result: (system(`/usr/bin/wget --spider -qT3 ${url} 2>"/dev/null"`, 3100) === 0) };
		}
	},

	log_clean: {
		args: { type: 'type' },
		call: function(req) {
			if (!(req.args?.type in ['homeproxy', 'sing-box-c', 'sing-box-s']))
				return { result: false, error: 'illegal type' };

			const filestat = lstat(`${RUN_DIR}/${req.args?.type}.log`);
			if (filestat)
				writefile(`${RUN_DIR}/${req.args?.type}.log`, '');
			return { result: true };
		}
	},

	singbox_generator: {
		args: { type: 'type', params: 'params' },
		call: function(req) {
			if (!(req.args?.type in ['ech-keypair', 'uuid', 'reality-keypair', 'vapid-keypair', 'wg-keypair']))
				return { result: false, error: 'illegal type' };

			const type = req.args?.type;
			let result = {};

			const fd = popen('/usr/bin/sing-box generate ' + type + ` ${req.args?.params || ''}`);
			if (fd) {
				let ech_cfg_set = false;
				let ech_key_set = false;

				for (let line = fd.read('line'); length(line); line = fd.read('line')) {
					if (type === 'uuid')
						result.uuid = trim(line);
					else if (type in ['reality-keypair', 'vapid-keypair', 'wg-keypair']) {
						let priv = match(trim(line), /PrivateKey: (.*)/);
						if (priv)
							result.private_key = priv[1];
						let pub = match(trim(line), /PublicKey: (.*)/);
						if (pub)
							result.public_key = pub[1];
					} else if (type in ['ech-keypair']) {
						if (trim(line) === '-----BEGIN ECH CONFIGS-----')
							ech_cfg_set = true;
						else if (trim(line) === '-----BEGIN ECH KEYS-----')
							ech_key_set = true;

						if (ech_cfg_set)
							result.ech_cfg = result.ech_cfg ? result.ech_cfg + '\n' + trim(line) : trim(line) ;
						if (ech_key_set)
							result.ech_key = result.ech_key ? result.ech_key + '\n' + trim(line) : trim(line) ;

						if (trim(line) === '-----END ECH CONFIGS-----')
							ech_cfg_set = false;
						else if (trim(line) === '-----END ECH KEYS-----')
							ech_key_set = false;
					}
				}

				fd.close();
			}

			return { result };
		}
	},

	singbox_get_features: {
		call: function() {
			let features = {};

			const fd = popen('/usr/bin/sing-box version');
			if (fd) {
				for (let line = fd.read('line'); length(line); line = fd.read('line')) {
					if (match(trim(line), /^sing-box version (.*)/))
						features.version = match(trim(line), /^sing-box version (.*)/)[1];

					let tags = match(trim(line), /^Tags: (.*)/);
					if (tags)
						for (let i in split(tags[1], ','))
							features[i] = true;
				}

				fd.close();
			}

			features.hp_has_ip_full = access('/usr/libexec/ip-full');
			features.hp_has_tcp_brutal = hasKernelModule('brutal.ko');
			features.hp_has_tproxy = hasKernelModule('nft_tproxy.ko') || access('/etc/modules.d/nft-tproxy');
			features.hp_has_tun = hasKernelModule('tun.ko') || access('/etc/modules.d/30-tun');

			return features;
		}
	},

	resources_get_version: {
		args: { type: 'type' },
		call: function(req) {
			const version = trim(readfile(`${HP_DIR}/resources/${req.args?.type}.ver`));
			return { version: version, error: error() };
		}
	},
	resources_update: {
		args: { type: 'type' },
		call: function(req) {
			if (req.args?.type) {
				const type = shellquote(req.args?.type);
				const exit_code = system(`${HP_DIR}/scripts/update_resources.sh ${type}`);
				return { status: exit_code };
			} else
				return { status: 255, error: 'illegal type' };
		}
	}
};

return { 'luci.homeproxy': methods };
