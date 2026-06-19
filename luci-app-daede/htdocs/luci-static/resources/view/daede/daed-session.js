// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';

const TOKEN_KEY = 'luci-app-daede.daed-token';

function clear(storage) {
	try { storage.removeItem(TOKEN_KEY); } catch (e) {}
}

function tokenExpiry(token) {
	try {
		const part = String(token || '').split('.')[1];
		if (!part)
			return 0;
		const normalized = part.replace(/-/g, '+').replace(/_/g, '/');
		const payload = JSON.parse(atob(normalized));
		return Number(payload.exp) || 0;
	} catch (e) {
		return 0;
	}
}

function load(storage, now) {
	let token = '';
	try { token = storage.getItem(TOKEN_KEY) || ''; } catch (e) { return ''; }
	const current = now == null ? Date.now() / 1000 : Number(now);
	if (!token || tokenExpiry(token) <= current + 30) {
		clear(storage);
		return '';
	}
	return token;
}

function save(storage, token) {
	try { storage.setItem(TOKEN_KEY, String(token || '')); } catch (e) {}
}

function isAccessDenied(error) {
	return /access denied|unauthori[sz]ed|invalid token/i.test(String(error && error.message || error || ''));
}

const api = {
	TOKEN_KEY: TOKEN_KEY,
	load: load,
	save: save,
	clear: clear,
	isAccessDenied: isAccessDenied
};

if (typeof module !== 'undefined' && module.exports)
	module.exports = api;

if (typeof baseclass !== 'undefined')
	return baseclass.extend(api);

return api;
