// SPDX-License-Identifier: Apache-2.0

'use strict';
'require form';
'require fs';
'require poll';
'require uci';
'require ui';
'require view';
'require view.daede.backend as backend';

const CSS = [
	'.dd-wrap{padding:4px 0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
	'.dd-card{border:1px solid rgba(0,0,0,.06);border-radius:10px;padding:10px 14px;margin-bottom:10px;box-shadow:0 2px 8px rgba(0,0,0,.03);background:rgba(255,255,255,.02)}',
	'.dd-card-title{font-size:11px;font-weight:600;opacity:.55;margin:0 0 8px;letter-spacing:.3px;text-transform:uppercase}',
	'.dd-status-row{display:flex;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:0}',
	'.dd-status-row .dd-grow{flex:1 1 auto}',
	'.dd-badge{display:inline-flex;align-items:center;gap:5px;padding:2px 10px;border-radius:999px;font-size:10.5px;font-weight:700;letter-spacing:.3px;border:1px solid transparent;line-height:1.3}',
	'.dd-badge-run{color:#3da66a;border-color:rgba(61,166,106,.5)}',
	'.dd-badge-stop{color:#d96d6d;border-color:rgba(217,109,109,.55)}',
	'.dd-badge-dot{width:6px;height:6px;border-radius:50%;background:currentColor;display:inline-block}',
	'.dd-meta{font-size:11.5px;opacity:.7;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace}',
	'.dd-meta-label{opacity:.55;margin-right:4px}',
	'.dd-actions{display:flex;flex-wrap:wrap;gap:6px;margin:8px 0 0}',
	'.dd-actions .cbi-button{font-size:11.5px;padding:4px 12px;border-radius:5px}',
	'.dd-actions a.cbi-button{display:inline-flex;align-items:center;gap:4px}',
	'.dd-switch{position:relative;width:42px;height:22px;border:0;border-radius:999px;background:rgba(128,128,128,.28);padding:0;cursor:pointer;transition:background .18s ease,opacity .18s ease;flex-shrink:0}',
	'.dd-switch .dd-switch-knob{position:absolute;top:3px;left:3px;width:16px;height:16px;border-radius:50%;background:rgba(255,255,255,.96);box-shadow:0 1px 4px rgba(0,0,0,.2);transition:transform .18s ease}',
	'.dd-switch.is-on{background:rgba(74,160,101,.65)}',
	'.dd-switch.is-on .dd-switch-knob{transform:translateX(20px)}',
	'.dd-switch:disabled{opacity:.45;cursor:not-allowed}',
	'.dd-switch-label{font-size:10.5px;font-weight:600;opacity:.62;letter-spacing:.3px}',
	'.dd-switch-wrap{display:inline-flex;align-items:center;gap:6px;white-space:nowrap}',
	'.dd-backend-card{padding:10px 14px}',
	'.dd-backend-row{display:flex;align-items:center;gap:10px;flex-wrap:wrap}',
	'.dd-backend-label{min-width:100px;font-size:12px;font-weight:600;opacity:.72}',
	'.dd-backend-segment{display:inline-flex;align-items:center;gap:2px;padding:2px;border-radius:7px;background:rgba(128,128,128,.10)}',
	'.dd-backend-btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;min-width:78px;height:24px;padding:0 10px;border:0;border-radius:5px;background:transparent;color:inherit;font-size:11px;font-weight:500;opacity:.65;cursor:pointer;transition:background .18s ease,color .18s ease,opacity .18s ease}',
	'.dd-backend-btn:hover{background:rgba(128,128,128,.10)}',
	'.dd-backend-btn.is-active{background:linear-gradient(#3886a1,#2f7288);color:#fff;opacity:1;font-weight:600;box-shadow:0 1px 2px rgba(0,0,0,.12)}',
	'.dd-backend-btn:disabled{opacity:.55;cursor:not-allowed}',
	'.dd-backend-state{font-size:10.5px;font-weight:500;opacity:.70;margin-left:2px}',
	'.dd-backend-btn.is-active .dd-backend-state{opacity:.85}',
	'.dd-backend-help{margin:6px 0 0 110px;font-size:11.5px;line-height:1.45;opacity:.66}',
	'@media (max-width:640px){.dd-backend-label{min-width:0;width:100%}.dd-backend-segment{width:100%}.dd-backend-btn{flex:1;min-width:0}.dd-backend-help{margin-left:0}}',
	/* daed/dae settings card —— LuCI form.Map 字体/边框对齐 dd 卡片体系 */
	'.dd-settings-card{padding:10px 14px}',
	'.dd-settings-card>h2,.dd-settings-card .cbi-map>h2,.dd-settings-card .cbi-section>h3{display:none}',
	'.dd-settings-card .cbi-map>.cbi-map-descr,.dd-settings-card .cbi-section-descr{font-size:11.5px;opacity:.62;margin:0 0 8px;line-height:1.45}',
	'.dd-settings-descr{font-size:11.5px;opacity:.62;margin:0 0 8px;line-height:1.45}',
	'.dd-settings-card .cbi-section{margin:0;padding:0;background:transparent;border:0;box-shadow:none}',
	'.dd-settings-card .cbi-value{padding:6px 0;border:0;min-height:0}',
	'.dd-settings-card .cbi-value-title{font-size:12.5px !important;font-weight:500;opacity:.85;padding:6px 12px 6px 0;min-width:140px}',
	'.dd-settings-card .cbi-value-field input,.dd-settings-card .cbi-value-field select,.dd-settings-card .cbi-value-field textarea{font-size:12.5px !important;padding:5px 8px;border-radius:5px;border:1px solid rgba(128,128,128,.28);background:transparent;color:inherit}',
	'.dd-settings-card .cbi-value-field input:focus,.dd-settings-card .cbi-value-field select:focus,.dd-settings-card .cbi-value-field textarea:focus{border-color:rgba(56,134,161,.7);outline:0;box-shadow:0 0 0 2px rgba(56,134,161,.15)}',
	'.dd-settings-card .cbi-value-description,.dd-settings-card .cbi-value-helptext{font-size:11.5px !important;opacity:.6;line-height:1.45;padding-top:3px}',
	/* 手风琴折叠组 —— 视觉与 clashoo cl-component-adv 一致 */
	'.dd-adv{margin-top:10px}',
	'.dd-adv-bar{display:flex;align-items:center;justify-content:space-between;padding:8px 12px;cursor:pointer;user-select:none;font-size:12px;font-weight:600;background:rgba(128,128,128,.06);border:1px solid rgba(128,128,128,.16);border-radius:7px;color:inherit;opacity:.55}',
	'.dd-adv-bar:hover{background:rgba(56,134,161,.08);opacity:1}',
	'.dd-adv-chevron{font-size:14px;font-weight:700;opacity:.55;transition:transform .2s}',
	'.dd-adv:not(.dd-closed) .dd-adv-chevron{transform:rotate(90deg)}',
	'.dd-adv-body{margin-top:8px;padding:2px 4px 4px}',
	'.dd-adv.dd-closed .dd-adv-body{display:none}',
	'.dd-editor{width:100%;min-height:460px;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace;font-size:12px;line-height:1.5;box-sizing:border-box;resize:vertical;border-radius:6px 6px 0 0}',
	'.dd-editor-footer{display:flex;flex-wrap:wrap;align-items:center;gap:14px;padding:5px 10px;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:10.5px;background:rgba(128,128,128,.06);border:1px solid rgba(0,0,0,.06);border-top:0;border-radius:0 0 6px 6px;color:inherit;opacity:.78}',
	'.dd-editor-footer .dd-fb-item{display:inline-flex;align-items:center;gap:5px}',
	'.dd-editor-footer .dd-fb-key{opacity:.55}',
	'.dd-editor-footer .dd-fb-warn{color:#b07d00;font-weight:600}',
	'.dd-editor-footer .dd-fb-ok{color:#3da66a;font-weight:600}',
	'body.dark .dd-editor-footer,html[data-theme="dark"] .dd-editor-footer,html[data-bs-theme="dark"] .dd-editor-footer{border-color:rgba(255,255,255,.1);background:rgba(255,255,255,.04)}',
	'body.dark .dd-editor-footer .dd-fb-warn,html[data-theme="dark"] .dd-editor-footer .dd-fb-warn,html[data-bs-theme="dark"] .dd-editor-footer .dd-fb-warn{color:#e0b34a}',
	'.dd-insert-select{font-size:11.5px;padding:4px 8px;border-radius:5px;border:1px solid rgba(128,128,128,.35);background:transparent;color:inherit;cursor:pointer}',
	'.dd-insert-select:hover{border-color:rgba(56,134,161,.55)}',
	'.dd-editor-actions{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-top:10px}',
	'.dd-editor-status{margin-left:auto;font-size:11.5px;opacity:0;transition:opacity .25s ease;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace}',
	'.dd-editor-status.show{opacity:1}',
	'.dd-editor-status.ok{color:#3da66a}',
	'.dd-editor-status.err{color:#d96d6d}',
	'.dd-editor-hint{font-size:11.5px;opacity:.62;line-height:1.5;margin:0 0 8px;padding:7px 10px;border-radius:6px;background:rgba(56,134,161,.06)}',
	'.dd-editor-hint b{font-weight:600;opacity:.85}',
		'.dd-sub-card{margin:0 0 10px;padding:10px 14px;border:0;border-radius:8px;background:transparent}',
		'.dd-sub-card-title{font-size:11px;font-weight:600;opacity:.55;margin:0 0 8px;letter-spacing:.3px;text-transform:uppercase}',
		'.dd-sub-row{display:flex;gap:8px;align-items:center;flex-wrap:wrap}',
		'.dd-sub-row input{flex:1;min-width:200px;font-size:12px;padding:6px 10px;border-radius:5px;border:1px solid rgba(128,128,128,.28);background:transparent;color:var(--text-color,inherit)}',
		'.dd-sub-row input:focus{border-color:rgba(74,160,101,.55);outline:0;box-shadow:0 0 0 2px rgba(74,160,101,.12)}.dd-sub-row input::placeholder{opacity:.45;color:rgba(92,102,120,.8)}',
		'.dd-sub-apply{font-size:11px;padding:5px 14px;border-radius:5px;border:1px solid #4aa065;color:#4aa065;background:transparent;cursor:pointer;white-space:nowrap;font-weight:600}',
		'.dd-sub-apply:hover{background:rgba(74,160,101,.12)}',
		'.dd-sub-apply:disabled{opacity:.45;cursor:not-allowed}',
		'.dd-sub-status{font-size:11px;margin-left:8px;opacity:0;transition:opacity .2s;white-space:nowrap}',
		'.dd-sub-status.show{opacity:1}',
	'.dd-ph-warn{display:none;font-size:12px;line-height:1.6;margin:0 0 8px;padding:10px 12px;border-radius:6px;background:rgba(217,158,0,.08);color:inherit}',
	'.dd-ph-warn.show{display:block}',
	'.dd-ph-warn-title{font-weight:600;margin-bottom:6px;color:#b07d00;font-size:12.5px}',
	'body.dark .dd-ph-warn-title,html[data-theme="dark"] .dd-ph-warn-title,html[data-bs-theme="dark"] .dd-ph-warn-title{color:#e0b34a}',
	'.dd-ph-howto{margin:4px 0 8px;opacity:.85}',
	'.dd-ph-howto code{padding:1px 5px;border-radius:3px;background:rgba(128,128,128,.18);font-size:11px;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace}',
	'.dd-ph-list{margin:6px 0 0;padding:6px 0 0;list-style:none;border-top:1px dashed rgba(217,158,0,.3)}',
	'.dd-ph-list-label{font-size:11px;opacity:.6;margin:0 0 4px}',
	'.dd-ph-list li{padding:2px 0;display:flex;gap:8px;align-items:baseline;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:11px}',
	'.dd-ph-list .dd-ph-ln{display:inline-block;min-width:38px;text-align:center;padding:1px 4px;border-radius:3px;background:rgba(217,158,0,.18);color:#8a6300;opacity:.95;cursor:pointer;font-weight:600;text-decoration:none}',
	'.dd-ph-list .dd-ph-ln:hover{background:rgba(217,158,0,.32)}',
	'body.dark .dd-ph-list .dd-ph-ln,html[data-theme="dark"] .dd-ph-list .dd-ph-ln,html[data-bs-theme="dark"] .dd-ph-list .dd-ph-ln{color:#f0c763;background:rgba(217,158,0,.22)}',
	'.dd-ph-list .dd-ph-txt{opacity:.7;word-break:break-all}',
	'body.dark .dd-card,html[data-theme="dark"] .dd-card,html[data-bs-theme="dark"] .dd-card{border-color:rgba(255,255,255,.08);background:rgba(255,255,255,.02)}',
	'body.dark .dd-adv-bar,html[data-theme="dark"] .dd-adv-bar,html[data-bs-theme="dark"] .dd-adv-bar{background:rgba(255,255,255,.04);border-color:rgba(255,255,255,.10)}',
	'body.dark .dd-settings-card .cbi-value-field input,body.dark .dd-settings-card .cbi-value-field select,body.dark .dd-settings-card .cbi-value-field textarea,html[data-theme="dark"] .dd-settings-card .cbi-value-field input,html[data-theme="dark"] .dd-settings-card .cbi-value-field select,html[data-theme="dark"] .dd-settings-card .cbi-value-field textarea,html[data-bs-theme="dark"] .dd-settings-card .cbi-value-field input,html[data-bs-theme="dark"] .dd-settings-card .cbi-value-field select,html[data-bs-theme="dark"] .dd-settings-card .cbi-value-field textarea{border-color:rgba(255,255,255,.18)}'
].join('');

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

	return rejectIfOtherRunning(be, running)
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
		.then(function() { return fs.exec(be.initd, [action]); })
		.then(function(res) { notifyAction(action, res); })
		.catch(function(e) {
			ui.addNotification(null, E('p', _('Toggle failed: %s').format(e.message || e)), 'danger');
		});
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
		if (be.hasWebUI)
			meta.push(E('span', { 'class': 'dd-meta' }, [ E('span', { 'class': 'dd-meta-label' }, _('Listen')), listenAddr || be.defaultListen ]));

		const sw = E('button', { 'class': 'dd-switch' + (state.running ? ' is-on' : ''), 'type': 'button', 'aria-label': _('Toggle service') }, [
			E('span', { 'class': 'dd-switch-knob' })
		]);
		sw.addEventListener('click', function(ev) {
			ev.preventDefault();
			sw.disabled = true;
			toggleService(be, !state.running, running).finally(function() { sw.disabled = false; });
		});

		const row = E('div', { 'class': 'dd-status-row' }, [ badge ].concat(meta).concat([
			E('span', { 'class': 'dd-grow' }),
			E('span', { 'class': 'dd-switch-wrap' }, [
				E('span', { 'class': 'dd-switch-label' }, state.running ? 'ON' : 'OFF'),
				sw
			])
		]));
		body.appendChild(row);

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
		if (be.name === 'dae') {
			const hot = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Hot Reload'));
			hot.addEventListener('click', function(ev) {
				ev.preventDefault();
				hot.disabled = true;
				execInit(be, 'hot_reload').finally(function() { hot.disabled = false; });
			});
			actions.push(hot);
		}
		if (state.running && be.name === 'dae') {
			const ckBtn = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Check Proxy Status'));
			const ckRes = E('span', { 'class': 'dd-meta', style: 'margin-left:8px;display:none' }, '');
			ckBtn.addEventListener('click', function(ev) {
				ev.preventDefault();
				ckBtn.disabled = true;
				ckRes.style.display = 'inline';
				ckRes.textContent = '...';
				fs.exec('/bin/grep', ['-c', 'my_group', '/var/log/dae/dae.log']).then(function(r) {
					var n = parseInt((r && r.stdout) || '0');
					if (n > 0)
						ckRes.textContent = _('OK, %d flows through proxy').format(n);
					else
						ckRes.textContent = _('No proxy traffic');
				}).catch(function() {
					ckRes.textContent = _('No proxy traffic');
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

function renderDaedSettings() {
	let m, s, o;
	m = new form.Map('daed', null, null);

	s = m.section(form.NamedSection, 'config', 'daed');
	s.addremove = false;
	s.anonymous = true;

	o = s.option(form.Value, 'listen_addr', _('Listen Address'),
		_('Host:port that the daed WebUI and GraphQL API listen on.'));
	o.datatype = 'ipaddrport(1)';
	o.default = '0.0.0.0:2023';
	o.rmempty = false;

	o = s.option(form.Value, 'log_maxsize', _('Max Log Size (MB)'),
		_('Rotate the log file once it grows past this many megabytes.'));
	o.datatype = 'uinteger';
	o.default = '5';

	o = s.option(form.Value, 'log_maxbackups', _('Max Log Backups'),
		_('Number of rotated log files to keep.'));
	o.datatype = 'uinteger';
	o.default = '1';

	return wrapSettingsCard(
		_('daede Settings'),
		_('A modern dashboard for dae. Subscriptions, nodes, routing and DNS are managed in the daed WebUI.'),
		m.render(),
		_('Log Advanced Settings'),
		['log_maxsize', 'log_maxbackups']
	);
}

function renderDaeSettings() {
	var m = new form.Map('dae', null, null);
	var s = m.section(form.NamedSection, 'config', 'dae');
	s.addremove = false;
	s.anonymous = true;
	var o = s.option(form.Value, 'config_file', _('Configuration File'));
	o.default = '/etc/dae/config.dae';
	o.rmempty = false;
	o.readonly = true;
	o = s.option(form.Value, 'log_maxsize', _('Max Log Size (MB)'), _('Rotate the log file once it grows past this many megabytes.'));
	o.datatype = 'uinteger';
	o.default = '1';
	o = s.option(form.Value, 'log_maxbackups', _('Max Log Backups'), _('Number of rotated log files to keep.'));
	o.datatype = 'uinteger';
	o.default = '1';
	return m.render().then(function(node) {
		var css = document.createElement('style');
		css.textContent = '.cbi-section>h3{display:none}.cbi-map>h2{display:none}.cbi-value-title{font-size:12px!important;opacity:.75;min-width:130px}.cbi-value-field input{font-size:12px!important;padding:5px 8px;border-radius:5px;border:1px solid rgba(128,128,128,.28);background:transparent;color:inherit}';
		node.insertBefore(css, node.firstChild);
		return node;
	});
}

/* dae 示例里的占位订阅特征 —— example.com、relative/path/to 或中文占位文本 */
const RE_PLACEHOLDER_URL = /(['"])(?:(?:https?|https-file|file):\/\/[^'"]*?(?:example\.com|relative\/path\/to)[^'"]*|你的订阅链接或者机场链接)\1/;

/* 常用块片段 —— 给文本模式用户一键插入官方推荐结构 */
const SNIPPETS = {
	subscription:
		'\nsubscription {\n' +
		'    # 把下面这行换成你的机场订阅链接\n' +
		"    my_sub: '你的订阅链接或者机场链接'\n" +
		'}\n',
	node:
		'\nnode {\n' +
		'    # 单条节点链接（ss/vmess/trojan/vless 等 share link）\n' +
		"    # 'ss://...'\n" +
		'}\n',
	group:
		'\ngroup {\n' +
		'    my_group {\n' +
		'        # 节点选择策略：min_moving_avg / min / random / fixed(0)\n' +
		'        policy: min_moving_avg\n' +
		'    }\n' +
		'}\n',
	routing:
		'\nrouting {\n' +
		'    # 私网直连\n' +
		'    dip(geoip:private) -> direct\n' +
		'    # 国内直连\n' +
		'    dip(geoip:cn) -> direct\n' +
		'    domain(geosite:cn) -> direct\n' +
		'    # 兜底：走代理组\n' +
		'    fallback: my_group\n' +
		'}\n',
	dns:
		'\ndns {\n' +
		'    upstream {\n' +
		"        alidns: 'udp://dns.alidns.com:53'\n" +
		"        googledns: 'tcp+udp://dns.google:53'\n" +
		'    }\n' +
		'    routing {\n' +
		'        request {\n' +
		'            qname(geosite:cn) -> alidns\n' +
		'            fallback: googledns\n' +
		'        }\n' +
		'    }\n' +
		'}\n',
	include:
		'\ninclude {\n' +
		'    # 相对路径：相对于 dae -c 指定的入口配置目录\n' +
		'    config.d/*.dae\n' +
		'}\n'
};

/* 把 example.dae 的 subscription 块瘦身成「只保留 1 行占位 + 中文引导注释」，
   降低用户认知负担。其他块（global/node/group/routing/dns）原样保留。 */
function simplifySubscriptionBlock(text) {
	if (!text) return text;
	const lines = text.split('\n');
	let start = -1, end = -1, depth = 0;
	for (let i = 0; i < lines.length; i++) {
		if (start < 0) {
			if (/^\s*subscription\s*\{/.test(lines[i])) {
				start = i;
				depth = 1;
				continue;
			}
		} else {
			depth += (lines[i].match(/\{/g) || []).length;
			depth -= (lines[i].match(/\}/g) || []).length;
			if (depth <= 0) { end = i; break; }
		}
	}
	if (start < 0 || end < 0) return text;
	/* 整块替换：保留原有 block 缩进风格（4 空格） */
	const replacement = [
		'subscription {',
		'    # ⚠ 把下面这行的 URL 换成你机场的订阅链接，然后保存。',
		"    my_sub: '你的订阅链接或者机场链接'",
		'}'
	];
	return lines.slice(0, start).concat(replacement).concat(lines.slice(end + 1)).join('\n');
}

function detectPlaceholders(text) {
	if (!text) return [];
	const lines = text.split('\n');
	const out = [];
	for (let i = 0; i < lines.length; i++) {
		const ln = lines[i];
		const stripped = ln.replace(/^\s*#.*$/, '');
		if (!stripped) continue;
		const m = stripped.match(RE_PLACEHOLDER_URL);
		if (m) out.push({ line: i + 1, url: m[2], raw: ln.trim() });
	}
	return out;
}

const GEN = '/usr/share/luci-app-daede/gen-dae-config.sh';

/* Table cell renderer: truncate long links so rows stay compact; full value
   stays visible in the edit dialog and on hover. */
function ellipsisCell(section_id) {
	const v = this.cfgvalue(section_id) || '';
	const short = v.length > 52 ? v.slice(0, 52) + '…' : v;
	return E('span', { 'title': v, 'style': 'font-family:ui-monospace,Menlo,monospace;font-size:12px' }, short);
}

/* Wrap every form section in a collapsible accordion. openTitles lists the
   section titles that should start expanded; the rest start collapsed. */
function accordionizeSections(mapNode, openTitles) {
	const secs = mapNode.querySelectorAll('.cbi-section');
	for (let i = 0; i < secs.length; i++) {
		const sec = secs[i];
		const h = sec.querySelector('h3');
		const title = h ? h.textContent.trim() : _('Section');
		const open = (openTitles || []).indexOf(title) >= 0;

		const body = E('div', { 'class': 'dd-adv-body' });
		while (sec.firstChild) body.appendChild(sec.firstChild);
		/* drop the moved <h3> so it doesn't duplicate the accordion bar title */
		const dupTitle = body.querySelector('h3');
		if (dupTitle) dupTitle.parentNode.removeChild(dupTitle);

		const wrap = E('div', { 'class': 'dd-adv' + (open ? '' : ' dd-closed') }, [
			E('div', { 'class': 'dd-adv-bar' }, [
				E('span', {}, title),
				E('span', { 'class': 'dd-adv-chevron' }, '›')
			]),
			body
		]);
		wrap.firstChild.addEventListener('click', function() { wrap.classList.toggle('dd-closed'); });
		sec.appendChild(wrap);
	}
}

/* Friendly form UI for the dae backend. Form is the source of truth: on save we
   commit the `dae` UCI package, then gen-dae-config.sh renders config.dae,
   validates it and hot-reloads. */
function renderDaeForms() {
	let m, s, o;
	m = new form.Map('dae', null, null);

	/* Subscriptions */
	s = m.section(form.GridSection, 'subscription', _('Subscriptions'),
		_('Airport / subscription links. dae resolves them into the node pool.'));
	s.addremove = true;
	s.anonymous = true;
	s.sortable = false;
	o = s.option(form.Value, 'tag', _('Tag'));
	o.placeholder = 'my_sub';
	o = s.option(form.Value, 'url', _('Subscription URL'));
	o.rmempty = false;
	o.placeholder = 'https://example.com/sub';
	o.textvalue = ellipsisCell;  /* keep long links from blowing up the row */
	o.validate = function(sid, v) {
		if (!v) return _('URL is required');
		if (!/^(https?|https-file|file):\/\//.test(v)) return _('Must start with http(s):// or file://');
		return true;
	};
	o = s.option(form.Flag, 'enabled', _('Enabled'));
	o.default = '1';
	o.editable = true;
	/* add an Update button next to Edit/Delete in each row; dae re-pulls all
	   subscriptions on reload, so the action is global regardless of the row */
	const origRowActions = s.renderRowActions;
	s.renderRowActions = function(section_id, more_label) {
		const cell = origRowActions.call(this, section_id, more_label);
		const btn = E('button', { 'class': 'cbi-button cbi-button-action', 'style': 'margin-right:.25em' }, _('Update'));
		btn.addEventListener('click', function(ev) {
			ev.preventDefault();
			btn.disabled = true;
			backend.detectRunning().then(function(r) {
				if (!r || !r.dae)
					return ui.addNotification(null, E('p', _('dae is stopped; it fetches subscriptions on start.')), 'warning');
				return fs.exec(backend.BACKENDS.dae.initd, ['hot_reload']).then(function(res) {
					if (res && res.code !== 0)
						ui.addNotification(null, E('p', _('Update failed: %s').format(res.stderr || res.stdout || ('exit ' + res.code))), 'danger');
					else
						ui.addNotification(null, E('p', _('Subscriptions updated (dae reloaded)')), 'info');
				});
			}).catch(function(e) {
				ui.addNotification(null, E('p', _('Update failed: %s').format(e.message || e)), 'danger');
			}).finally(function() { btn.disabled = false; });
		});
		const firstBtn = cell.querySelector('button, a.cbi-button');
		if (firstBtn && firstBtn.parentNode) firstBtn.parentNode.insertBefore(btn, firstBtn);
		else cell.appendChild(btn);
		return cell;
	};

	/* Manual nodes (share links) */
	s = m.section(form.GridSection, 'node', _('Nodes'),
		_('Single share links (ss / vmess / vless / trojan / tuic / hysteria2 / socks5 …).'));
	s.addremove = true;
	s.anonymous = true;
	s.sortable = false;
	o = s.option(form.Value, 'tag', _('Tag'));
	o.placeholder = 'node1';
	o = s.option(form.Value, 'link', _('Share Link'));
	o.rmempty = false;
	o.placeholder = 'vmess://...';
	o.textvalue = ellipsisCell;
	o = s.option(form.Flag, 'enabled', _('Enabled'));
	o.default = '1';
	o.editable = true;

	/* Subscription tags for group filter dropdowns */
	const subTags = (uci.sections('dae', 'subscription') || [])
		.map(function(x) { return x.tag; }).filter(function(x) { return !!x; });

	/* Groups (outbound) */
	s = m.section(form.TypedSection, 'group', _('Groups'),
		_('Outbound groups. Leave filters empty to use all nodes. Set the route fallback to one of these.'));
	s.addremove = true;
	s.anonymous = true;
	o = s.option(form.Value, 'name', _('Name'));
	o.rmempty = false;
	o.placeholder = 'proxy';
	o = s.option(form.ListValue, 'policy', _('Policy'));
	o.value('min_moving_avg', _('Min moving average latency'));
	o.value('min', _('Min last latency'));
	o.value('min_avg10', _('Min average of last 10'));
	o.value('random', _('Random'));
	o.value('fixed(0)', _('Fixed (first node)'));
	o.default = 'min_moving_avg';
	o = s.option(form.DynamicList, 'filter_sub', _('Filter: subscriptions'),
		_('Only use nodes from these subscription tags (empty = all).'));
	subTags.forEach(function(t) { o.value(t, t); });
	o = s.option(form.DynamicList, 'filter_node', _('Filter: node tags'),
		_('Only use nodes with these tags (empty = all).'));

	/* Routing presets */
	const groupNames = (uci.sections('dae', 'group') || [])
		.map(function(x) { return x.name; }).filter(function(x) { return !!x; });
	s = m.section(form.NamedSection, 'routing', 'routing', _('Routing'));
	s.addremove = false;
	o = s.option(form.Flag, 'private_direct', _('Private IPs direct'),
		_('LAN / private addresses bypass the proxy.'));
	o.default = '1';
	o = s.option(form.Flag, 'cn_direct', _('China direct'),
		_('China mainland IPs and domains bypass the proxy.'));
	o.default = '1';
	o = s.option(form.Flag, 'block_ads', _('Block ads'),
		_('Drop traffic matching the ad domain list.'));
	o.default = '0';
	o = s.option(form.Value, 'fallback', _('Fallback group'),
		_('Default outbound for everything else.'));
	if (groupNames.length)
		groupNames.forEach(function(n) { o.value(n, n); });
	else
		o.value('proxy', 'proxy');
	o = s.option(form.DynamicList, 'custom', _('Custom rules'),
		_('Raw dae routing lines, evaluated before fallback, e.g. dip(geoip:jp) -> proxy'));

	/* DNS presets */
	s = m.section(form.NamedSection, 'dns', 'dns', _('DNS'));
	s.addremove = false;
	o = s.option(form.Value, 'cn_upstream', _('China upstream'),
		_('Resolves China-mainland domains.'));
	o.default = 'udp://dns.alidns.com:53';
	o.placeholder = 'udp://dns.alidns.com:53';
	o = s.option(form.Value, 'fallback_upstream', _('Fallback upstream'),
		_('Resolves everything else.'));
	o.default = 'tcp+udp://dns.google:53';
	o.placeholder = 'tcp+udp://dns.google:53';

	const status = E('span', { 'class': 'dd-editor-status' }, '');
	let statusTimer = null;
	function flash(text, kind, hold) {
		status.textContent = text;
		status.classList.remove('ok', 'err');
		if (kind) status.classList.add(kind);
		status.classList.add('show');
		if (statusTimer) clearTimeout(statusTimer);
		statusTimer = setTimeout(function() { status.classList.remove('show'); }, hold || 3000);
	}

	const save = E('button', { 'class': 'cbi-button cbi-button-positive' }, _('Save and Hot Reload'));

	return m.render().then(function(mapNode) {
		save.addEventListener('click', function(ev) {
			ev.preventDefault();
			save.disabled = true;
			flash(_('Saving…'));
			/* commit dae UCI (apply flushes the rpc session to /etc/config,
			   which a CLI `uci commit` cannot see), then regenerate + hot reload */
			m.save(null, true)
				.then(function() { return uci.save(); })
				.then(function() { return uci.apply(); })
				.then(function() { return fs.exec(GEN, ['generate']); })
				.then(function(res) {
					if (res && res.code !== 0) {
						const err = (res.stderr || res.stdout || ('exit ' + res.code)).trim().split('\n')[0];
						flash(_('Apply failed: %s').format(err), 'err', 9000);
						return;
					}
					/* reload to reflect committed state and clear the change badge */
					flash(_('Saved · validated · hot-reloaded'), 'ok');
					setTimeout(function() { window.location.reload(); }, 900);
				})
				.catch(function(e) {
					if (e && e.name === 'CBIValidationError') {
						flash(_('Please fix the highlighted fields.'), 'err', 6000);
						return;
					}
					flash(_('Save failed: %s').format(e.message || e), 'err', 9000);
				})
				.finally(function() { save.disabled = false; });
		});

		/* make each form section collapsible; keep the two everyday ones open */
		accordionizeSections(mapNode, [ _('Subscriptions'), _('Nodes') ]);

		return E('div', { 'class': 'dd-card dd-settings-card' }, [
			E('h4', { 'class': 'dd-card-title' }, _('dae Configuration')),
			E('div', { 'class': 'dd-settings-descr' },
				_('Fill in subscriptions or nodes and save — the config file is generated, validated and hot-reloaded for you.')),
			mapNode,
			E('div', { 'class': 'dd-editor-actions' }, [ save, status ])
		]);
	});
}

/* Import banner: offer to pull subscription/node from an existing hand-written
   config.dae into the form when the form is still empty. */
function renderDaeImportBanner() {
	const hasForms = (uci.sections('dae', 'subscription') || []).length
		|| (uci.sections('dae', 'node') || []).length;
	if (hasForms)
		return Promise.resolve(null);

	return fs.read_direct(backend.BACKENDS.dae.config, 'text').then(function(content) {
		if (!content || !/\b(subscription|node)\s*\{/.test(content))
			return null;

		const btn = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Import from existing config'));
		const note = E('span', { 'class': 'dd-meta', style: 'margin-left:8px' }, '');
		btn.addEventListener('click', function(ev) {
			ev.preventDefault();
			btn.disabled = true;
			note.textContent = _('Importing…');
			fs.exec(GEN, ['import']).then(function(res) {
				if (res && res.code === 0) {
					note.textContent = _('Imported, reloading…');
					setTimeout(function() { window.location.reload(); }, 600);
				} else {
					note.textContent = _('Import failed');
					btn.disabled = false;
				}
			}).catch(function() { note.textContent = _('Import failed'); btn.disabled = false; });
		});

		return E('div', { 'class': 'dd-card', style: 'border-color:rgba(217,158,0,.4)' }, [
			E('div', { 'class': 'dd-ph-warn-title' }, _('Existing config detected')),
			E('div', { 'class': 'dd-settings-descr', style: 'margin:4px 0 8px' },
				_('You have a hand-written config.dae. Import its subscriptions and nodes into the form, or keep editing manually below. Saving the form overwrites config.dae.')),
			E('div', { 'class': 'dd-actions' }, [ btn, note ])
		]);
	}).catch(function() { return null; });
}

function renderDaeEditor() {
	const textarea = E('textarea', {
		'class': 'dd-editor',
		'spellcheck': 'false',
		'placeholder': _('dae config file is empty. Click "Initialize from example" to start, or paste your config here.')
	}, '');
	const save = E('button', { 'class': 'cbi-button cbi-button-positive' }, _('Save and Hot Reload'));
	const init = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Initialize from example'));
	const status = E('span', { 'class': 'dd-editor-status' }, '');

	const phWarn = E('div', { 'class': 'dd-ph-warn' }, [
		E('div', { 'class': 'dd-ph-warn-title' }, ''),
		E('div', { 'class': 'dd-ph-howto' }, ''),
		E('div', { 'class': 'dd-ph-list-label' }, _('Placeholder lines (click line number to jump):')),
		E('ul', { 'class': 'dd-ph-list' })
	]);

	/* Insert Block 下拉：选完后自动复位到首项 */
	const insertSelect = E('select', { 'class': 'dd-insert-select', 'title': _('Insert config block at cursor') }, [
		E('option', { 'value': '' }, _('+ Insert Block…')),
		E('option', { 'value': 'subscription' }, 'subscription'),
		E('option', { 'value': 'node' }, 'node'),
		E('option', { 'value': 'group' }, 'group'),
		E('option', { 'value': 'routing' }, 'routing'),
		E('option', { 'value': 'dns' }, 'dns'),
		E('option', { 'value': 'include' }, 'include')
	]);

	/* Footer：dae version · 行数 · 占位剩余 */
	const fbVer  = E('span', { 'class': 'dd-fb-item' }, [ E('span', { 'class': 'dd-fb-key' }, 'dae'), E('span', {}, '—') ]);
	const fbLine = E('span', { 'class': 'dd-fb-item' }, [ E('span', { 'class': 'dd-fb-key' }, _('lines')), E('span', {}, '0') ]);
	const fbStat = E('span', { 'class': 'dd-fb-item dd-fb-ok' }, '✓ ready');
	const footer = E('div', { 'class': 'dd-editor-footer' }, [ fbVer, fbLine, fbStat ]);

	function insertAtCursor(text) {
		const start = textarea.selectionStart;
		const end   = textarea.selectionEnd;
		const v     = textarea.value;
		textarea.value = v.slice(0, start) + text + v.slice(end);
		const pos = start + text.length;
		textarea.focus();
		textarea.setSelectionRange(pos, pos);
		refreshPlaceholders();
	}

	insertSelect.addEventListener('change', function() {
		const key = insertSelect.value;
		insertSelect.value = '';
		if (key && SNIPPETS[key]) insertAtCursor(SNIPPETS[key]);
	});

	let statusTimer = null;
	function flashStatus(text, kind, holdMs) {
		status.textContent = text;
		status.classList.remove('ok', 'err');
		if (kind) status.classList.add(kind);
		status.classList.add('show');
		if (statusTimer) clearTimeout(statusTimer);
		statusTimer = setTimeout(function() {
			status.classList.remove('show');
		}, holdMs || 3000);
	}

	function jumpToLine(lineNo) {
		const lines = textarea.value.split('\n');
		let offset = 0;
		for (let i = 0; i < lineNo - 1 && i < lines.length; i++)
			offset += lines[i].length + 1;
		textarea.focus();
		textarea.setSelectionRange(offset, offset + (lines[lineNo - 1] || '').length);
		const lineHeight = 18;
		textarea.scrollTop = Math.max(0, (lineNo - 4) * lineHeight);
	}

	function refreshFooter(phCount) {
		const lines = textarea.value ? textarea.value.split('\n').length : 0;
		fbLine.lastChild.textContent = String(lines);
		while (fbStat.firstChild) fbStat.removeChild(fbStat.firstChild);
		fbStat.classList.remove('dd-fb-ok', 'dd-fb-warn');
		if (phCount > 0) {
			fbStat.classList.add('dd-fb-warn');
			fbStat.textContent = _('⚠ %d placeholder').format(phCount);
		} else {
			fbStat.classList.add('dd-fb-ok');
			fbStat.textContent = lines > 0 ? '✓ ready' : '— empty';
		}
	}

	function refreshPlaceholders() {
		const hits = detectPlaceholders(textarea.value);
		const titleEl = phWarn.querySelector('.dd-ph-warn-title');
		const howtoEl = phWarn.querySelector('.dd-ph-howto');
		const listEl = phWarn.querySelector('.dd-ph-list');
		while (listEl.firstChild) listEl.removeChild(listEl.firstChild);
		refreshFooter(hits.length);
		if (!hits.length) {
			phWarn.classList.remove('show');
			return;
		}
		titleEl.textContent = _('⚠ 还差订阅链接才能跑：检测到 %d 行占位 URL').format(hits.length);
		while (howtoEl.firstChild) howtoEl.removeChild(howtoEl.firstChild);
		/* 用 DOM 拼成富文本说明 —— 比单条字符串可读 */
		howtoEl.appendChild(document.createTextNode(_('这些 ')));
		const c1 = document.createElement('code'); c1.textContent = 'example.com'; howtoEl.appendChild(c1);
		howtoEl.appendChild(document.createTextNode(_(' / ')));
		const c2 = document.createElement('code'); c2.textContent = 'relative/path/to'; howtoEl.appendChild(c2);
		howtoEl.appendChild(document.createTextNode(_(' 都是 dae 官方模板留的假地址，不是真订阅。把其中任意一行的 URL 换成你机场的订阅链接（删掉多余行），保存即可跑通。')));
		hits.forEach(function(h) {
			const lnSpan = E('span', { 'class': 'dd-ph-ln', 'title': _('Jump to line') }, 'L' + h.line);
			lnSpan.addEventListener('click', function() { jumpToLine(h.line); });
			const txt = E('span', { 'class': 'dd-ph-txt' }, h.url);
			listEl.appendChild(E('li', {}, [ lnSpan, txt ]));
		});
		phWarn.classList.add('show');
	}

	textarea.addEventListener('input', refreshPlaceholders);

	function loadConfig() {
		return fs.read_direct(backend.BACKENDS.dae.config, 'text').then(function(content) {
			textarea.value = content || '';
		}).catch(function() {
			textarea.value = '';
		}).finally(refreshPlaceholders);
	}

	/* 校验流程：先写到 /tmp/dae-validate.dae 干测 → dae validate 通过才覆盖正式 config */
	const VALIDATE_PATH = '/tmp/dae-validate.dae';

	save.addEventListener('click', function(ev) {
		ev.preventDefault();
		save.disabled = true;
		flashStatus(_('Validating…'));
		fs.write(VALIDATE_PATH, textarea.value, 384)
			.then(function() { return fs.exec('/usr/bin/dae', ['validate', '-c', VALIDATE_PATH]); })
			.then(function(res) {
				if (res && res.code !== 0) {
					const err = (res.stderr || res.stdout || ('exit ' + res.code)).trim().split('\n')[0];
					flashStatus(_('Validate failed: %s').format(err), 'err', 8000);
					throw new Error('validate-failed');
				}
				flashStatus(_('Saving…'));
				return fs.write(backend.BACKENDS.dae.config, textarea.value, 384);
			})
			.then(function() { return backend.detectRunning(); })
			.then(function(running) {
				if (running && running.dae)
					return fs.exec(backend.BACKENDS.dae.initd, ['hot_reload']).then(function(res) {
						if (res && res.code !== 0)
							flashStatus(_('Reload failed: %s').format(res.stderr || res.stdout || ('exit ' + res.code)), 'err', 8000);
						else
							flashStatus(_('Validated · saved · hot-reloaded'), 'ok');
					});
				flashStatus(_('Saved OK (start dae to apply)'), 'ok');
			})
			.catch(function(e) {
				if (e && e.message === 'validate-failed') return;
				flashStatus(_('Save failed: %s').format(e.message || e), 'err', 8000);
			})
			.finally(function() {
				save.disabled = false;
				fs.exec('/bin/rm', ['-f', VALIDATE_PATH]).catch(function() {});
			});
	});

	init.addEventListener('click', function(ev) {
		ev.preventDefault();
		if (textarea.value.trim() && !confirm(_('This will replace your current config. Continue?')))
			return;
		init.disabled = true;
		flashStatus(_('Loading example…'));
		fs.read_direct(backend.BACKENDS.dae.example, 'text')
			.then(function(content) {
				textarea.value = simplifySubscriptionBlock(content || '');
				refreshPlaceholders();
				flashStatus(_('Example loaded — save to apply'), 'ok');
			})
			.catch(function(e) { flashStatus(_('Init failed: %s').format(e.message || e), 'err'); })
			.finally(function() { init.disabled = false; });
	});

	/* 一次性探测 dae --version；失败就显示 unknown，不影响主流程 */
	fs.exec('/usr/bin/dae', ['--version']).then(function(res) {
		const out = (res && res.stdout || '').trim();
		const m = out.match(/dae\s+version\s+(\S+)/);
		fbVer.lastChild.textContent = m ? m[1].split('-')[0] : 'unknown';
	}).catch(function() {
		fbVer.lastChild.textContent = 'unknown';
	});

	loadConfig();

	return E('div', { 'class': 'dd-card' }, [
		E('h4', { 'class': 'dd-card-title' }, _('Advanced / Manual Mode')),
		E('div', { 'class': 'dd-settings-descr' },
			_('Edit config.dae directly. Saving the form above regenerates the file and overwrites changes made here.')),
		(function() {
			var adv = E('div', { 'class': 'dd-adv dd-closed', style: 'margin-top:8px' }, [
				E('div', { 'class': 'dd-adv-bar' }, [
					E('span', {}, _('Configuration Editor')),
					E('span', { 'class': 'dd-adv-chevron' }, '›')
				]),
				E('div', { 'class': 'dd-adv-body' }, [
					E('div', { 'class': 'dd-editor-hint', style: 'margin:0 0 10px' }, [
						E('b', {}, _('Text-only mode.')),
						' ',
						_('Edit config DSL — subscriptions, nodes, routing, DNS. Load template via Initialize. Replace placeholder URL before saving. Switch to daed for GUI.')
					]),
					phWarn,
					textarea,
					footer,
					E('div', { 'class': 'dd-editor-actions' }, [ save, init, insertSelect, status ])
				])
			]);
			adv.firstChild.addEventListener('click', function() { adv.classList.toggle('dd-closed'); });
			return adv;
		})(),
		(function() {
			var body = E('div', { 'class': 'dd-adv-body' }, E('em', {}, _('Loading…')));
			var adv2 = E('div', { 'class': 'dd-adv dd-closed', style: 'margin-top:4px' }, [
				E('div', { 'class': 'dd-adv-bar' }, [
					E('span', {}, _('dae Parameters')),
					E('span', { 'class': 'dd-adv-chevron' }, '›')
				]),
				body
			]);
			adv2.firstChild.addEventListener('click', function() { adv2.classList.toggle('dd-closed'); });
			renderDaeSettings().then(function(node) {
				while (body.firstChild) body.removeChild(body.firstChild);
				body.appendChild(node);
			});
			return adv2;
		})()
	]);
}

return view.extend({
	load: function() {
		return backend.detectBackend().then(function(ctx) {
			return uci.load(ctx.backend.uci).catch(function() {}).then(function() {
				return ctx;
			});
		});
	},

	render: function(ctx) {
		const listenAddr = uci.get('daed', 'config', 'listen_addr') || backend.BACKENDS.daed.defaultListen;
		const children = [
			E('style', {}, CSS),
			renderStatusCard(ctx, listenAddr),
			renderBackendSwitcher(ctx)
		].filter(function(node) { return !!node; });

		if (!ctx.installed[ctx.name]) {
			children.push(E('div', { 'class': 'dd-card dd-warning' }, _('Selected backend is not installed. Install dae or daed from the package feed first.')));
		} else if (ctx.name === 'dae') {
			children.push(renderDaeImportBanner());
			children.push(renderDaeForms());
			children.push(renderDaeEditor());
		} else {
			children.push(renderDaedSettings());
		}

		return Promise.all(children.map(function(child) {
			return child && child.then ? child : Promise.resolve(child);
		})).then(function(nodes) {
			return E('div', { 'class': 'dd-wrap' }, nodes.filter(function(n) { return !!n; }));
		});
	}
});
