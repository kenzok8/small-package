// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';
'require fs';
'require poll';
'require view.daede.backend as backend';

function notifyAction() {}

function execInit(be, action) {
	return fs.exec(be.initd, [action]).then(function(res) {
		notifyAction(action, res);
	}).catch(function() {});
}

function rejectIfOtherRunning(be, running) {
	const other = be.name === 'dae' ? 'daed' : 'dae';
	if (!running || !running[other])
		return Promise.resolve();

	return Promise.reject(new Error(_('%s is already running. Stop %s before starting %s because both backends share the same eBPF/cgroup attachment.').format(other, other, be.name)));
}

function toggleService(be, turnOn, running) {
	const enabled = turnOn ? '1' : '0';
	const action = turnOn ? 'start' : 'stop';

	// Only guard on start: two backends share the eBPF/cgroup attachment, so
	// starting one while the other runs is unsafe. Stopping is always allowed.
	const guard = turnOn ? rejectIfOtherRunning(be, running) : Promise.resolve();

	return guard
		.then(function() { return fs.exec('/sbin/uci', ['set', be.uci + '.config.enabled=' + enabled]); })
		.then(function() { return fs.exec('/sbin/uci', ['commit', be.uci]); })
		.then(function() {
			if (turnOn)
				return fs.exec(be.initd, ['enable']);
			return fs.exec(be.initd, ['disable']);
		})
		.then(function() {
			if (turnOn && be.useNetns)
				return fs.exec('/sbin/ip', ['netns', 'del', 'daens']).catch(function() {});
		})
		.then(function() { return fs.exec(be.initd, [action]); });
}

function renderBackendSwitcher(ctx) {
	if (!ctx.installed.dae && !ctx.installed.daed)
		return null;

	const wrap = E('div', { 'class': 'dd-card dd-backend-card' }, [
		E('h4', { 'class': 'dd-card-title' }, _('Backend')),
		E('div', { 'class': 'dd-backend-row' }, [
			E('span', { 'class': 'dd-backend-label' }, _('Active backend')),
			E('div', { 'class': 'dd-backend-segment' })
		])
	]);
	const segment = wrap.querySelector('.dd-backend-segment');
	const hint = E('div', { 'class': 'dd-backend-help' }, _('Switching backend stops the current service first. Click start when you want the new backend to run.'));
	let busy = false;

	const showHint = function(msg) {
		hint.textContent = msg;
	};

	const stopIfRunning = function(running) {
		const stops = [];

		['dae', 'daed'].forEach(function(name) {
			if (running && running[name])
				stops.push(fs.exec(backend.BACKENDS[name].initd, ['stop']).catch(function() {}));
		});

		if (stops.length)
			showHint(_('Stopping current backend…'));

		return Promise.all(stops);
	};

	['daed', 'dae'].forEach(function(name) {
		const active = ctx.name === name;
		const installed = !!ctx.installed[name];
		const btn = E('button', {
			'class': 'dd-backend-btn' + (active ? ' is-active' : ''),
			'type': 'button',
			'disabled': null,
			'title': installed ? _('Switch to %s').format(name) : _('%s is not installed').format(name)
		}, [
			E('span', {}, name),
			E('span', { 'class': 'dd-backend-state' }, active ? _('Active') : (installed ? '' : _('Not installed')))
		]);
		btn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (busy || active)
				return;
			if (!installed) {
				showHint(_('%s is not installed. Install it first, then switch backend.').format(name));
				return;
			}

			busy = true;
			Array.prototype.forEach.call(segment.querySelectorAll('button'), function(b) { b.disabled = true; });
			showHint(_('Switching to %s…').format(name));

			backend.detectRunning()
				.then(stopIfRunning)
				.then(function() { return backend.setActiveBackend(name); })
				.then(function() {
					showHint(_('Switched to %s. Click start when you want it to run.').format(name));
					setTimeout(function() { window.location.reload(); }, 650);
				})
				.catch(function(e) {
					busy = false;
					Array.prototype.forEach.call(segment.querySelectorAll('button'), function(b) { b.disabled = false; });
					showHint(_('Switch failed.'));
				});
		});
		segment.appendChild(btn);
	});

	wrap.appendChild(hint);
	return wrap;
}

function renderStatusCard(ctx, listenAddr) {
	const be = ctx.backend;
	const body = E('div', { 'id': 'dd-status-body' }, E('em', {}, _('Collecting data…')));
	const card = E('div', { 'class': 'dd-card' }, [
		E('h4', { 'class': 'dd-card-title' }, _('Service Status')),
		body
	]);

	const render = function(state, running) {
		while (body.firstChild) body.removeChild(body.firstChild);

		const badge = state.running
			? E('span', { 'class': 'dd-badge dd-badge-run' }, [ E('span', { 'class': 'dd-badge-dot' }), _('RUNNING') ])
			: E('span', { 'class': 'dd-badge dd-badge-stop' }, [ E('span', { 'class': 'dd-badge-dot' }), _('STOPPED') ]);

		const meta = [
			E('span', { 'class': 'dd-meta' }, [ E('span', { 'class': 'dd-meta-label' }, _('Backend')), be.name ])
		];

		if (state.running && state.pid)
			meta.push(E('span', { 'class': 'dd-meta' }, [ E('span', { 'class': 'dd-meta-label' }, 'PID'), state.pid ]));

		const swErr = E('span', { 'class': 'dd-meta dd-err', 'style': 'display:none' }, '');
		const sw = E('button', { 'class': 'dd-switch' + (state.running ? ' is-on' : ''), 'type': 'button', 'aria-label': _('Toggle service') }, [
			E('span', { 'class': 'dd-switch-knob' })
		]);
		sw.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (sw.disabled) return;
			sw.disabled = true;
			swErr.style.display = 'none';
			const turnOn = !state.running;
			/* instant optimistic feedback — the start/stop chain (esp. dae's eBPF
			   load) takes a few seconds; flip the switch and show a pending label
			   right away instead of looking frozen */
			sw.classList.toggle('is-on', turnOn);
			const lbl = sw.parentNode && sw.parentNode.querySelector('.dd-switch-label');
			if (lbl) lbl.textContent = '…';
			toggleService(be, turnOn, running)
				/* refresh as soon as the command returns, not on the next poll
				   tick — this is what made feedback feel laggy */
				.then(function() { return refresh(); })
				.catch(function(e) {
					/* revert the optimistic flip and show the reason inline */
					sw.classList.toggle('is-on', !turnOn);
					if (lbl) lbl.textContent = state.running ? 'ON' : 'OFF';
					swErr.textContent = _('Toggle failed: %s').format(e.message || e);
					swErr.style.display = '';
				})
				.finally(function() { sw.disabled = false; });
		});

		/* line 1: badge + toggle (always aligned, never wraps); line 2: meta */
		const row = E('div', { 'class': 'dd-status-row' }, [
			badge,
			E('span', { 'class': 'dd-grow' }),
			swErr,
			E('span', { 'class': 'dd-switch-wrap' }, [
				E('span', { 'class': 'dd-switch-label' }, state.running ? 'ON' : 'OFF'),
				sw
			])
		]);
		body.appendChild(row);
		if (meta.length)
			body.appendChild(E('div', { 'class': 'dd-status-meta' }, meta));

		const actions = [];
		if (be.hasWebUI && state.running) {
			const port = (listenAddr || be.defaultListen).split(':').slice(-1)[0];
			actions.push(E('a', {
				'class': 'cbi-button cbi-button-action',
				'href': 'http://%s:%s'.format(window.location.hostname, port),
				'target': '_blank',
				'rel': 'noreferrer noopener'
			}, _('Open WebUI')));
		}
		if (state.running) {
			const restart = E('button', { 'class': 'cbi-button cbi-button-positive' }, _('Restart'));
			restart.addEventListener('click', function(ev) {
				ev.preventDefault();
				restart.disabled = true;
				execInit(be, 'restart').finally(function() { restart.disabled = false; });
			});
			actions.push(restart);
		}
		if (state.running && be.name === 'dae') {
			const hot = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Hot Reload'));
			hot.addEventListener('click', function(ev) {
				ev.preventDefault();
				hot.disabled = true;
				execInit(be, 'hot_reload').finally(function() { hot.disabled = false; });
			});
			actions.push(hot);
		}
		if (state.running && be.name === 'dae') {
			const ckBtn = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Test YouTube'));
			const ckRes = E('span', { 'class': 'dd-meta', style: 'margin-left:8px;display:none' }, '');
			ckBtn.addEventListener('click', function(ev) {
				ev.preventDefault();
				ckBtn.disabled = true;
				ckRes.style.display = 'inline';
				ckRes.classList.remove('dd-ok', 'dd-err');
				ckRes.textContent = _('Testing…');
				/* actually probe YouTube through dae's transparent proxy */
				fs.exec('/usr/share/luci-app-daede/proxy-check.sh', []).then(function(r) {
					const out = (r && r.stdout) || '';
					const ok = /\bok=1\b/.test(out);
					const code = (out.match(/code=(\S+)/) || [])[1] || '000';
					const ms = parseInt((out.match(/ms=(\d+)/) || [])[1] || '0');
					if (ok) {
						ckRes.classList.add('dd-ok');
						ckRes.textContent = _('YouTube reachable · %d ms').format(ms);
					} else {
						ckRes.classList.add('dd-err');
						ckRes.textContent = (code === '000')
							? _('YouTube unreachable (timeout)')
							: _('YouTube unreachable (HTTP %s)').format(code);
					}
				}).catch(function() {
					ckRes.classList.add('dd-err');
					ckRes.textContent = _('YouTube unreachable (timeout)');
				}).finally(function() {
					ckBtn.disabled = false;
					setTimeout(function() { ckRes.style.display = 'none'; }, 8000);
				});
			});
			actions.push(ckBtn);
			actions.push(ckRes);
		}
		if (actions.length)
			body.appendChild(E('div', { 'class': 'dd-actions' }, actions));
	};

	const refresh = function() {
		return Promise.all([
			backend.serviceStatus(be.name),
			backend.detectRunning()
		]).then(function(r) {
			render(r[0], r[1]);
		});
	};

	poll.add(refresh);
	refresh();
	return card;
}

function wrapSettingsCard(title, descr, mapPromise, advTitle, advFields) {
	return mapPromise.then(function(node) {
		const advBody = E('div', { 'class': 'dd-adv-body' });
		const advWrap = E('div', { 'class': 'dd-adv dd-closed' }, [
			E('div', { 'class': 'dd-adv-bar' }, [
				E('span', {}, advTitle),
				E('span', { 'class': 'dd-adv-chevron' }, '›')
			]),
			advBody
		]);
		advWrap.firstChild.addEventListener('click', function() {
			advWrap.classList.toggle('dd-closed');
		});

		(advFields || []).forEach(function(name) {
			const row = node.querySelector('[data-name="' + name + '"]');
			if (row) advBody.appendChild(row);
		});

		const host = node.querySelector('.cbi-section') || node;
		if (advBody.firstChild) host.appendChild(advWrap);

		const children = [ E('h4', { 'class': 'dd-card-title' }, title) ];
		if (descr) children.push(E('div', { 'class': 'dd-settings-descr' }, descr));
		children.push(node);
		return E('div', { 'class': 'dd-card dd-settings-card' }, children);
	});
}

return baseclass.extend({

	renderStatusCard: renderStatusCard,

	renderBackendSwitcher: renderBackendSwitcher,

	wrapSettingsCard: wrapSettingsCard

});
