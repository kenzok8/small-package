// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';
'require fs';
'require rpc';
'require uci';

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

const BACKENDS = {
	daed: {
		name: 'daed',
		label: 'daed',
		uci: 'daed',
		initd: '/etc/init.d/daed',
		log: '/var/log/daed/daed.log',
		pkg: 'daed',
		hasWebUI: true,
		useNetns: true,
		defaultListen: '0.0.0.0:2023'
	},
	dae: {
		name: 'dae',
		label: 'dae',
		uci: 'dae',
		initd: '/etc/init.d/dae',
		log: '/var/log/dae/dae.log',
		pkg: 'dae',
		config: '/etc/dae/config.dae',
		example: '/etc/dae/example.dae',
		hasWebUI: false,
		useNetns: false
	}
};

function execOk(cmd, args) {
	return L.resolveDefault(fs.exec(cmd, args || []), { code: 1 }).then(function(res) {
		return res && res.code === 0;
	});
}

function exists(path) {
	return L.resolveDefault(fs.stat(path), null).then(function(st) {
		return !!st;
	});
}

function serviceStatus(name) {
	return L.resolveDefault(callServiceList(name), {}).then(function(svc) {
		let pid = 0, running = false;

		try {
			const inst = svc[name].instances[name];
			running = !!inst.running;
			pid = inst.pid || 0;
		} catch (e) {}

		return { running: running, pid: pid };
	});
}

function detectInstalledBackends() {
	return Promise.all([
		exists(BACKENDS.dae.initd),
		exists(BACKENDS.daed.initd)
	]).then(function(r) {
		return { dae: r[0], daed: r[1] };
	});
}

function detectRunning() {
	/* pidof matches the program name exactly and, unlike busybox `pgrep -x`
	   (which compares the full cmdline `/usr/bin/dae run …` and never hits),
	   reliably tells dae from daed without substring false positives. */
	return Promise.all([
		execOk('/bin/pidof', ['dae']),
		execOk('/bin/pidof', ['daed'])
	]).then(function(r) {
		return { dae: r[0], daed: r[1] };
	});
}

function loadActiveBackend() {
	return L.resolveDefault(uci.load('daede'), null).then(function() {
		const active = uci.get('daede', 'config', 'active_backend');
		return BACKENDS[active] ? active : '';
	});
}

function setActiveBackend(name) {
	if (!BACKENDS[name])
		return Promise.reject(new Error('invalid backend: ' + name));

	return exists('/etc/config/daede').then(function(ok) {
		if (!ok)
			return fs.write('/etc/config/daede', '');
	}).then(function() { return fs.exec('/sbin/uci', ['set', 'daede.config=daede']); })
		.then(function() { return fs.exec('/sbin/uci', ['set', 'daede.config.active_backend=' + name]); })
		.then(function() { return fs.exec('/sbin/uci', ['commit', 'daede']); });
}

function detectBackend() {
	return Promise.all([
		detectInstalledBackends(),
		detectRunning(),
		loadActiveBackend()
	]).then(function(r) {
		const installed = r[0];
		const running = r[1];
		const preferred = r[2];
		let name = preferred;

		if (!name || !installed[name])
			name = installed.daed ? 'daed' : (installed.dae ? 'dae' : 'daed');

		return {
			name: name,
			backend: BACKENDS[name],
			installed: installed,
			running: running,
			preferred: preferred,
			bothInstalled: !!(installed.dae && installed.daed)
		};
	});
}

return baseclass.extend({
	BACKENDS: BACKENDS,
	detectInstalledBackends: detectInstalledBackends,
	detectRunning: detectRunning,
	detectBackend: detectBackend,
	setActiveBackend: setActiveBackend,
	serviceStatus: serviceStatus
});
