/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2023 ImmortalWrt.org
 */

import { mkstemp } from 'fs';
import { urldecode, urldecode_params } from 'luci.http';

/* Global variables start */
export const HP_DIR = '/etc/homeproxy';
export const RUN_DIR = '/var/run/homeproxy';
/* Global variables end */

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

export function executeCommand(...args) {
	let outfd = mkstemp();
	let errfd = mkstemp();

	const exitcode = system(`${join(' ', args)} >&${outfd.fileno()} 2>&${errfd.fileno()}`);

	outfd.seek(0);
	errfd.seek(0);

	const stdout = outfd.read(1024 * 512) ?? '';
	const stderr = errfd.read(1024 * 512) ?? '';

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

export function hexencArray(str) {
	if (!str || type(str) !== 'string')
		return null;

	const hexstr = hexenc(str);
	let arr = [];

	for (let i = 0; i < length(hexstr) / 2; i++)
		push(arr, hex('0x' + substr(hexstr, i * 2, 2)));
	return arr;
};

export function calcStringCRC8(str) {
	if (!str || type(str) !== 'string')
		return null;

	const crc8Table = [
		  0,   7,  14,   9,  28,  27,  18,  21,  56,  63,  54,  49,  36,  35,  42,  45,
		112, 119, 126, 121, 108, 107,  98, 101,  72,  79,  70,  65,  84,  83,  90,  93,
		224, 231, 238, 233, 252, 251, 242, 245, 216, 223, 214, 209, 196, 195, 202, 205,
		144, 151, 158, 153, 140, 139, 130, 133, 168, 175, 166, 161, 180, 179, 186, 189,
		199, 192, 201, 206, 219, 220, 213, 210, 255, 248, 241, 246, 227, 228, 237, 234,
		183, 176, 185, 190, 171, 172, 165, 162, 143, 136, 129, 134, 147, 148, 157, 154,
		 39,  32,  41,  46,  59,  60,  53,  50,  31,  24,  17,  22,   3,   4,  13,  10,
		 87,  80,  89,  94,  75,  76,  69,  66, 111, 104,  97, 102, 115, 116, 125, 122,
		137, 142, 135, 128, 149, 146, 155, 156, 177, 182, 191, 184, 173, 170, 163, 164,
		249, 254, 247, 240, 229, 226, 235, 236, 193, 198, 207, 200, 221, 218, 211, 212,
		105, 110, 103,  96, 117, 114, 123, 124,  81,  86,  95,  88,  77,  74,  67,  68,
		 25,  30,  23,  16,   5,   2,  11,  12,  33,  38,  47,  40,  61,  58,  51,  52,
		 78,  73,  64,  71,  82,  85,  92,  91, 118, 113, 120, 127, 106, 109, 100,  99,
		 62,  57,  48,  55,  34,  37,  44,  43,   6,   1,   8,  15,  26,  29,  20,  19,
		174, 169, 160, 167, 178, 181, 188, 187, 150, 145, 152, 159, 138, 141, 132, 131,
		222, 217, 208, 215, 194, 197, 204, 203, 230, 225, 232, 239, 250, 253, 244, 243
	];
	const strArray = hexencArray(str);
	let crc8 = 0;

	for (let i = 0; i < length(strArray); i++)
		crc8 = crc8Table[(crc8 ^ strArray[i]) & 255];
	return substr('00' + sprintf("%X", crc8), -2);
};

export function calcStringMD5(str) {
	if (!str || type(str) !== 'string')
		return null;

	const output = executeCommand(`/bin/echo -n ${shellQuote(str)} | /usr/bin/md5sum | /usr/bin/awk '{print $1}'`) || {};
	return trim(output.stdout);
};

export function getTime(epoch) {
	const local_time = localtime(epoch);
	return replace(replace(sprintf(
		'%d-%2d-%2d@%2d:%2d:%2d',
		local_time.year,
		local_time.mon,
		local_time.mday,
		local_time.hour,
		local_time.min,
		local_time.sec
	), ' ', '0'), '@', ' ');

};

export function wGET(url) {
	if (!url || type(url) !== 'string')
		return null;

	const output = executeCommand(`/usr/bin/wget -qO- --user-agent 'Wget/1.21 (HomeProxy, like v2rayN)' --timeout=10 ${shellQuote(url)}`) || {};
	return trim(output.stdout);
};
/* Utilities end */

/* String helper start */
export function isEmpty(res) {
	return !res || res === 'nil' || (type(res) in ['array', 'object'] && length(res) === 0);
};

export function strToBool(str) {
	return (str === '1') || null;
};

export function strToInt(str) {
	return !isEmpty(str) ? (int(str) || null) : null;
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

export function validateHostname(hostname) {
	return (match(hostname, /^[a-zA-Z0-9_]+$/) != null ||
		(match(hostname, /^[a-zA-Z0-9_][a-zA-Z0-9_%-.]*[a-zA-Z0-9]$/) &&
			match(hostname, /[^0-9.]/)));
};

export function validation(datatype, data) {
	if (!datatype || !data)
		return null;

	const ret = system(`/sbin/validate_data ${shellQuote(datatype)} ${shellQuote(data)} 2>/dev/null`);
	return (ret === 0);
};

export function filterCheck(name, filter_mode, filter_keywords) {
	if (isEmpty(name) || isEmpty(filter_mode) || isEmpty(filter_keywords))
		return false;

	let ret = false;
	for (let i in filter_keywords) {
		const patten = regexp(i);
		if (match(name, patten))
			ret = true;
	}
	if (filter_mode === 'whitelist')
		ret = !ret;

	return ret;
};
/* String helper end */

/* String parser start */
export function decodeBase64Str(str) {
	if (isEmpty(str))
		return null;

	str = trim(str);
	str = replace(str, '_', '/');
	str = replace(str, '-', '+');

	const padding = length(str) % 4;
	if (padding)
		str = str + substr('====', padding);

	return b64dec(str);
};

export function parseURL(url) {
	if (type(url) !== 'string')
		return null;

	const services = {
		http: '80',
		https: '443'
	};

	const objurl = {};

	objurl.href = url;

	url = replace(url, /#(.+)$/, (_, val) => {
		objurl.hash = val;
		return '';
	});

	url = replace(url, /^(\w[A-Za-z0-9\+\-\.]+):/, (_, val) => {
		objurl.protocol = val;
		return '';
	});

	url = replace(url, /\?(.+)/, (_, val) => {
		objurl.search = val;
		objurl.searchParams = urldecode_params(val);
		return '';
	});

	url = replace(url, /^\/\/([^\/]+)/, (_, val) => {
		val = replace(val, /^([^@]+)@/, (_, val) => {
			objurl.userinfo = val;
			return '';
		});

		val = replace(val, /:(\d+)$/, (_, val) => {
			objurl.port = val;
			return '';
		});

		if (validation('ip4addr', val) ||
		    validation('ip6addr', replace(val, /\[|\]/g, '')) ||
		    validation('hostname', val))
			objurl.hostname = val;

		return '';
	});

	objurl.pathname = url || '/';

	if (!objurl.protocol || !objurl.hostname)
		return null;

	if (objurl.userinfo) {
		objurl.userinfo = replace(objurl.userinfo, /:([^:]+)$/, (_, val) => {
			objurl.password = val;
			return '';
		});

		if (match(objurl.userinfo, /^[A-Za-z0-9\+\-\_\.]+$/)) {
			objurl.username = objurl.userinfo;
			delete objurl.userinfo;
		} else {
			delete objurl.userinfo;
			delete objurl.password;
		}
	};

	if (!objurl.port)
		objurl.port = services[objurl.protocol];

	objurl.host = objurl.hostname + (objurl.port ? `:${objurl.port}` : '');
	objurl.origin = `${objurl.protocol}://${objurl.host}`;

	return objurl;
};
/* String parser end */
