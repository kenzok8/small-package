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
	if (res == null || res in ['', 'nil']) return true;                   // null, '', 'nil'
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
