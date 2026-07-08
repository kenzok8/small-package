// SPDX-License-Identifier: Apache-2.0

'use strict';
'require fs';
'require poll';
'require uci';
'require ui';
'require view';
'require view.daede.backend as backend';

const DATA_PATHS = {
	geoip:   '/usr/share/v2ray/geoip.dat',
	geosite: '/usr/share/v2ray/geosite.dat'
};

// Geo data source presets. `loyalsoldier` keeps both URLs empty so the actual
// default lives in one place — update-geo.sh — avoiding UI/script drift.
const GEO_PRESETS = {
	loyalsoldier: { geoip: '', geosite: '' },
	v2fly: {
		geoip:   'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
		geosite: 'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
	}
};

function currentPreset(gi, gs) {
	if (!gi && !gs) return 'loyalsoldier';
	if (gi === GEO_PRESETS.v2fly.geoip && gs === GEO_PRESETS.v2fly.geosite) return 'v2fly';
	return 'custom';
}

const HEALTH_PATHS = {
	btf: '/sys/kernel/btf/vmlinux',
	btfDetached: '/usr/lib/debug/boot/vmlinux',
	netns: '/run/netns/daens'
};

const CSS = [
	'.dd-up-wrap{padding:6px 0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
	'.dd-card{border:1px solid rgba(0,0,0,.06);border-radius:10px;padding:14px 16px;margin-bottom:14px;box-shadow:0 2px 8px rgba(0,0,0,.03);background:rgba(255,255,255,.02)}',
	'.dd-card-title{font-size:12px;font-weight:600;opacity:.55;margin:0 0 10px;letter-spacing:.3px;text-transform:uppercase}',
	'.dd-up-row{display:grid;grid-template-columns:24px 130px 1fr auto auto;gap:10px;align-items:center;font-size:12px;padding:7px 0;border-top:1px dashed rgba(128,128,128,.18)}',
	'.dd-up-row:first-of-type{border-top:0}',
	'.dd-up-icon{font-size:14px;text-align:center;line-height:1}',
	'.dd-up-ok{color:#3da66a}',
	'.dd-up-warn{color:#d39e00}',
	'.dd-up-new{color:#4a8cff}',
	'.dd-up-err{color:#d96d6d}',
	'.dd-up-name{font-weight:600;opacity:.85}',
	'.dd-up-meta{opacity:.7;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}',
	'.dd-up-version{font-size:11px;opacity:.55;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;white-space:nowrap}',
	'.dd-up-btn{font-size:11px;line-height:1.4;min-height:0;height:auto;padding:4px 12px;border-radius:5px;border:1px solid rgba(128,128,128,.35);background:transparent;color:inherit;cursor:pointer;white-space:nowrap}',
	'.dd-up-btn:hover{background:rgba(128,128,128,.12)}',
	'.dd-up-btn:disabled{opacity:.45;cursor:not-allowed}',
	'.dd-up-btn-primary{border-color:#4aa065;color:#4aa065}',
	'.dd-geo-row{display:grid;grid-template-columns:96px 1fr;gap:10px;align-items:center;font-size:12px;padding:6px 0}',
	'.dd-geo-row label{opacity:.75;font-weight:600}',
	'.dd-geo-row input[type=text],.dd-geo-row select{font-size:12px;padding:4px 8px;border:1px solid rgba(128,128,128,.35);border-radius:5px;background:transparent;color:inherit;width:100%}',
	/* selects cap at 200px on wide screens, shrink to the column on mobile (no overflow) */
	'.dd-geo-row select{width:100%!important;max-width:200px;box-sizing:border-box}',
	'.dd-geo-actions{margin-top:10px;display:flex;gap:10px;align-items:center}',
	'.dd-up-log{margin-top:10px;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:11px;padding:10px;border:1px solid rgba(128,128,128,.14);border-radius:8px;max-height:200px;overflow:auto;white-space:pre-wrap;word-break:break-all;display:none;background:inherit;color:#4a8c63}',
	'.dd-up-log.show{display:block}',
		'body.dark .dd-up-log,html[data-theme="dark"] .dd-up-log,html[data-bs-theme="dark"] .dd-up-log{color:#a3d9ad}',
	/* accordion — same structure as config.js dd-adv */
	'.dd-adv{margin-bottom:14px}',
	'.dd-adv-bar{display:flex;align-items:center;justify-content:space-between;padding:8px 14px;cursor:pointer;user-select:none;font-size:11.5px;font-weight:600;background:rgba(128,128,128,.04);border:1px solid rgba(0,0,0,.06);border-radius:10px;color:inherit;letter-spacing:.3px;text-transform:uppercase;opacity:.7;box-shadow:0 2px 8px rgba(0,0,0,.03)}',
	'.dd-adv-bar:hover{background:rgba(56,134,161,.06);opacity:.95}',
	'.dd-adv-chevron{font-size:14px;font-weight:700;opacity:.55;transition:transform .2s;text-transform:none}',
	'.dd-adv:not(.dd-closed) .dd-adv-chevron{transform:rotate(90deg)}',
	'.dd-adv-body{margin-top:8px;padding:10px 14px;border:1px solid rgba(0,0,0,.06);border-radius:10px;background:rgba(255,255,255,.02);box-shadow:0 2px 8px rgba(0,0,0,.03)}',
	'.dd-adv.dd-closed{margin-bottom:14px}',
	'.dd-adv.dd-closed .dd-adv-body{display:none}',
	'body.dark .dd-card,html[data-theme="dark"] .dd-card,html[data-bs-theme="dark"] .dd-card,body.dark .dd-adv-bar,body.dark .dd-adv-body,html[data-theme="dark"] .dd-adv-bar,html[data-theme="dark"] .dd-adv-body,html[data-bs-theme="dark"] .dd-adv-bar,html[data-bs-theme="dark"] .dd-adv-body{border-color:rgba(255,255,255,.08);background:rgba(255,255,255,.02)}'
].join('');

function fmtBytes(n) {
	if (!n && n !== 0) return '-';
	if (n < 1024) return n + ' B';
	if (n < 1024 * 1024) return (n / 1024).toFixed(1) + ' KB';
	return (n / 1024 / 1024).toFixed(1) + ' MB';
}

function fmtMtime(epoch) {
	if (!epoch) return '';
	const d = new Date(epoch * 1000);
	return d.toISOString().slice(0, 10);
}

// Compare two version strings like `sort -V`: split into numeric / non-numeric
// chunks and compare chunk by chunk (numeric chunks numerically). Returns
// <0 if a<b, 0 if equal, >0 if a>b. Used so a stale third-party feed that
// happens to provide an OLDER build (e.g. compile-jell) is never offered as an
// "upgrade" over a newer locally installed package.
function cmpVer(a, b) {
	const ax = String(a).match(/(\d+|\D+)/g) || [];
	const bx = String(b).match(/(\d+|\D+)/g) || [];
	const n = Math.max(ax.length, bx.length);
	for (let i = 0; i < n; i++) {
		const as = ax[i], bs = bx[i];
		if (as === undefined) return -1;
		if (bs === undefined) return 1;
		if (/^\d+$/.test(as) && /^\d+$/.test(bs)) {
			const d = parseInt(as, 10) - parseInt(bs, 10);
			if (d !== 0) return d < 0 ? -1 : 1;
		} else if (as !== bs) {
			return as < bs ? -1 : 1;
		}
	}
	return 0;
}

function probeFile(path) {
	return L.resolveDefault(fs.stat(path), null).then(function(st) {
		return { exists: !!st, size: st ? st.size : 0, mtime: st ? st.mtime : 0 };
	});
}

function probePkg(pkg) {
	return fs.exec('/usr/share/luci-app-daede/pkg-info.sh', [pkg]).then(function(res) {
		const out = (res.stdout || '').trim().split('\t');
		return { installed: out[0] || '', latest: out[1] || '' };
	}).catch(function() {
		return { installed: '', latest: '' };
	});
}

// YYYYMMDD-HHMM stamp for backup filenames
function stamp() {
	const d = new Date(), p = n => (n < 10 ? '0' : '') + n;
	return '' + d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + '-' + p(d.getHours()) + p(d.getMinutes());
}

return view.extend({
	load: function() {
		// background apk update so new versions show on next poll
		fs.exec('/usr/share/luci-app-daede/refresh-index.sh', []).catch(function() {});
		return Promise.all([
			backend.detectBackend(),
			uci.load('daed').catch(function() {}),
			uci.load('daede').catch(function() {})
		]).then(function(r) {
			return r[0];
		});
	},

	render: function(ctx) {
		const logPane = E('pre', { 'class': 'dd-up-log', 'id': 'dd-up-log' }, '');
		const corePkgs = [];
		const addCorePkg = function(name) {
			if (corePkgs.indexOf(name) === -1)
				corePkgs.push(name);
		};
		addCorePkg(ctx.name);
		addCorePkg('daed');
		addCorePkg('dae');

		const dataBody = E('div', { 'id': 'dd-up-data' }, E('em', {}, _('Probing…')));
		const pkgBody  = E('div', { 'id': 'dd-up-pkg'  }, E('em', {}, _('Probing…')));
		const healthBody = E('div', { 'id': 'dd-up-health' }, E('em', {}, _('Probing…')));

		const mkRow = function(icon, iconCls, name, meta, btn) {
			return E('div', { 'class': 'dd-up-row' }, [
				E('span', { 'class': 'dd-up-icon ' + iconCls }, icon),
				E('span', { 'class': 'dd-up-name' }, name),
				E('span', { 'class': 'dd-up-meta', 'title': meta }, meta),
				E('span', {}, ''),
				btn || E('span', {}, '')
			]);
		};

		// run a backgrounded script and stream its log into the log pane until it
		// logs a final ✓/✗ status line; then refresh the badges. Inline, no popup.
		const runJob = function(script, arg, btn, logPath) {
			const orig = btn.textContent;
			btn.disabled = true;
			btn.textContent = '...';
			let tries = 0;
			const poll = function() {
				return L.resolveDefault(fs.read_direct(logPath, 'text'), '').then(function(c) {
					if (c) { logPane.textContent = c; logPane.classList.add('show'); }
					if (/[✓✗]/.test(c)) { refresh(); return; }
					if (tries++ > 90) return;
					return new Promise(function(r) { setTimeout(r, 2000); }).then(poll);
				});
			};
			return fs.exec('/usr/share/luci-app-daede/' + script, [arg]).then(function(res) {
				if (res.code === 0) return poll();
			}).catch(function() {}).finally(function() {
				btn.disabled = false;
				btn.textContent = orig;
			});
		};

		// === Data updates (GeoIP / GeoSite) ===
		const updateGeo = function(kind, btn) {
			return runJob('update-geo.sh', kind, btn, '/tmp/luci-app-daede.' + kind + '.log');
		};

		// === Package updates (dae|daed / luci-app-daede) ===
		const upgradePkg = function(pkg, btn) {
			return runJob('update-pkg.sh', pkg, btn, '/tmp/luci-app-daede.pkg-' + pkg + '.log');
		};

		// === Config backup (export / import the whole daede config) ===
		const exportBtn = E('button', { 'class': 'dd-up-btn' }, _('Export'));
		const importBtn = E('button', { 'class': 'dd-up-btn' }, _('Import'));
		const fileInput = E('input', { 'type': 'file', 'accept': '.tar.gz,.gz,application/gzip', 'style': 'display:none' });

		exportBtn.addEventListener('click', function() {
			const orig = exportBtn.textContent;
			exportBtn.disabled = true; exportBtn.textContent = '...';
			fs.exec('/usr/share/luci-app-daede/config-backup.sh', ['export']).then(function(res) {
				if (res.code !== 0 || !res.stdout) {
					logPane.textContent = String(res.stderr || res.stdout || 'export failed').trim();
					logPane.classList.add('show');
					return;
				}
				let bin;
				try {
					bin = atob(res.stdout.trim());
				} catch (e) {
					logPane.textContent = _('Export failed: invalid base64 data from server');
					logPane.classList.add('show');
					return;
				}
				if (!bin || bin.length === 0) {
					logPane.textContent = _('Export failed: empty archive');
					logPane.classList.add('show');
					return;
				}
				const arr = new Uint8Array(bin.length);
				for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
				const url = URL.createObjectURL(new Blob([arr], { 'type': 'application/gzip' }));
				const a = E('a', { 'href': url, 'download': 'daede-config-' + stamp() + '.tar.gz' });
				document.body.appendChild(a); a.click(); document.body.removeChild(a);
				setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
			}).catch(function(e) {
				logPane.textContent = _('Export failed') + ': ' + (e ? (e.message || String(e)) : _('script not found'));
				logPane.classList.add('show');
			}).finally(function() {
				exportBtn.disabled = false; exportBtn.textContent = orig;
			});
		});

		importBtn.addEventListener('click', function() { fileInput.click(); });
		fileInput.addEventListener('change', function(ev) {
			const file = ev.target.files && ev.target.files[0];
			if (!file) return;
			if (!confirm(_('Import overwrites the current daede config and restarts the backend. Continue?'))) {
				fileInput.value = ''; return;
			}
			const reader = new FileReader();
			reader.onload = function(e) {
				const b64 = String(e.target.result).split(',')[1] || '';
				fs.write('/tmp/daede-import.b64', b64).then(function() {
					return runJob('config-backup.sh', 'import', importBtn, '/tmp/luci-app-daede.backup.log');
				}).catch(function(e) {
					logPane.textContent = _('Import failed') + ': ' + (e ? (e.message || String(e)) : _('unknown error'));
					logPane.classList.add('show');
				}).finally(function() { fileInput.value = ''; });
			};
			reader.readAsDataURL(file);
		});

		const refresh = function() {
			const probes = [
				probeFile(DATA_PATHS.geoip),
				probeFile(DATA_PATHS.geosite),
				probeFile(HEALTH_PATHS.btf),
				probeFile(HEALTH_PATHS.btfDetached),
				backend.detectRunning(),
				backend.serviceStatus(ctx.name)
			];

			corePkgs.forEach(function(pkg) {
				probes.push(probePkg(pkg));
			});
			probes.push(probePkg('luci-app-daede'));

			if (ctx.backend.useNetns)
				probes.push(probeFile(HEALTH_PATHS.netns));

			return Promise.all(probes).then(function(r) {
				const geoip = r[0], geosite = r[1], btf = r[2], btfDetached = r[3], running = r[4], service = r[5];
				const pkgOffset = 6;
				const coreInfo = {};
				corePkgs.forEach(function(pkg, i) {
					coreInfo[pkg] = r[pkgOffset + i];
				});
				const luci = r[pkgOffset + corePkgs.length];
				const ns = r[pkgOffset + corePkgs.length + 1];

				// data rows
				while (dataBody.firstChild) dataBody.removeChild(dataBody.firstChild);
				[
					{ k: 'geoip',   name: 'GeoIP',   r: geoip },
					{ k: 'geosite', name: 'GeoSite', r: geosite }
				].forEach(function(entry) {
					const btn = E('button', { 'class': 'dd-up-btn dd-up-btn-primary' }, _('Update'));
					btn.addEventListener('click', function() { updateGeo(entry.k, btn); });
					const meta = entry.r.exists
						? fmtBytes(entry.r.size) + (entry.r.mtime ? ' · ' + fmtMtime(entry.r.mtime) : '')
						: _('missing — click Update to fetch');
					dataBody.appendChild(mkRow(
						entry.r.exists ? '✓' : '✗',
						entry.r.exists ? 'dd-up-ok' : 'dd-up-err',
						entry.name,
						meta,
						btn
					));
				});

				// pkg rows
				while (pkgBody.firstChild) pkgBody.removeChild(pkgBody.firstChild);
				corePkgs.map(function(pkg) {
					const label = _('%s binary').format(pkg) + (ctx.name === pkg ? ' · ' + _('active') : '');
					return { k: pkg, name: label, r: coreInfo[pkg] };
				}).concat([
					{ k: 'luci-app-daede', name: 'luci-app-daede', r: luci }
				]).forEach(function(entry) {
					const btn = E('button', { 'class': 'dd-up-btn dd-up-btn-primary' }, _('Upgrade'));
					btn.addEventListener('click', function() { upgradePkg(entry.k, btn); });
					// Only treat it as upgradable when the feed version is STRICTLY
					// higher than what's installed. A lower/equal feed version (e.g.
					// a stale compile-jell build) must never be offered as an upgrade.
					const cmp = (entry.r.installed && entry.r.latest)
						? cmpVer(entry.r.latest, entry.r.installed) : null;
					const updatable = cmp !== null && cmp > 0;
					let meta;
					if (!entry.r.installed) {
						meta = _('not installed via package manager');
						btn.disabled = true;
						btn.textContent = _('Unavailable');
					} else if (!entry.r.latest) {
						// latest unknown (registry unreachable) - nothing to upgrade to
						meta = _('installed') + ': ' + entry.r.installed + ' · ' + _('latest version unknown');
						btn.disabled = true;
					} else if (updatable) {
						meta = _('installed') + ': ' + entry.r.installed + ' → ' + _('latest') + ': ' + entry.r.latest;
					} else {
						// installed >= feed: already up to date (feed may even be older)
						meta = _('installed') + ': ' + entry.r.installed + ' · ' + _('up to date');
						btn.disabled = true;
					}
					pkgBody.appendChild(mkRow(
						updatable ? '↑' : (entry.r.installed ? '✓' : '✗'),
						updatable ? 'dd-up-new' : (entry.r.installed ? 'dd-up-ok' : 'dd-up-err'),
						entry.name,
						meta,
						btn
					));
				});

				// health rows
				while (healthBody.firstChild) healthBody.removeChild(healthBody.firstChild);
				healthBody.appendChild(mkRow(
					running[ctx.name] ? '✓' : '✗',
					running[ctx.name] ? 'dd-up-ok' : 'dd-up-err',
					_('%s process').format(ctx.name),
					running[ctx.name] ? _('pgrep reports the backend is running') : _('backend process is not running')
				));

				if (btf.exists)
					healthBody.appendChild(mkRow('✓', 'dd-up-ok', _('Kernel BTF'), HEALTH_PATHS.btf + ' · ' + fmtBytes(btf.size)));
				else if (btfDetached.exists)
					healthBody.appendChild(mkRow('✓', 'dd-up-ok', _('Kernel BTF'), HEALTH_PATHS.btfDetached + ' · ' + fmtBytes(btfDetached.size)));
				else
					healthBody.appendChild(mkRow('✗', 'dd-up-err', _('Kernel BTF'), _('not available — eBPF needs CONFIG_DEBUG_INFO_BTF or vmlinux-btf')));

				if (ctx.backend.hasWebUI) {
					const listenAddr = uci.get('daed', 'config', 'listen_addr') || ctx.backend.defaultListen;
					const port = listenAddr.split(':').slice(-1)[0];
					healthBody.appendChild(mkRow(
						service.running ? '✓' : '✗',
						service.running ? 'dd-up-ok' : 'dd-up-err',
						_('WebUI/API'),
						service.running ? _('service is running, expected on port %s').format(port) : _('service is stopped')
					));
				} else {
					healthBody.appendChild(mkRow('✓', 'dd-up-ok', _('Hot reload'), _('/etc/init.d/dae hot_reload is available')));
				}

				if (ctx.backend.useNetns && ns && ns.exists) {
					const btn = E('button', { 'class': 'dd-up-btn' }, _('Clean'));
					btn.addEventListener('click', function() {
						const daedRunning = !!(running && running[ctx.name]);
						const msg = daedRunning
							? _('%s is running. Deleting the daens netns now will break its networking until you restart it. Continue?').format(ctx.name)
							: _('Delete the daens netns?');
						if (!confirm(msg))
							return;
						btn.disabled = true;
						fs.exec('/sbin/ip', ['netns', 'del', 'daens']).finally(function() { btn.disabled = false; });
					});
					healthBody.appendChild(mkRow('⚠', 'dd-up-warn', _('netns daens'), HEALTH_PATHS.netns + ' · ' + _('exists, may block daed start'), btn));
				} else if (ctx.backend.useNetns) {
					healthBody.appendChild(mkRow('✓', 'dd-up-ok', _('netns daens'), HEALTH_PATHS.netns + ' · ' + _('clean')));
				}
			});
		};

		poll.add(refresh);
		refresh();

		// === Geo data source (preset / custom URL + auto-update) ===
		const geoSettings = (function() {
			const gi0 = uci.get('daede', 'config', 'geoip_url') || '';
			const gs0 = uci.get('daede', 'config', 'geosite_url') || '';
			const auto0 = uci.get('daede', 'config', 'geo_auto') === '1';
			const freq0 = uci.get('daede', 'config', 'geo_auto_freq') || 'daily';
			const preset0 = currentPreset(gi0, gs0);

			const presetSel = E('select', {}, [
				E('option', { 'value': 'loyalsoldier' }, 'Loyalsoldier'),
				E('option', { 'value': 'v2fly' }, 'v2fly'),
				E('option', { 'value': 'custom' }, _('Custom'))
			]);
			presetSel.value = preset0;

			const giInput = E('input', { 'type': 'text', 'placeholder': 'https://…/geoip.dat' });
			const gsInput = E('input', { 'type': 'text', 'placeholder': 'https://…/geosite.dat' });
			giInput.value = preset0 === 'custom' ? gi0 : '';
			gsInput.value = preset0 === 'custom' ? gs0 : '';

			const customRows = E('div', {}, [
				E('div', { 'class': 'dd-geo-row' }, [ E('label', {}, 'GeoIP URL'), giInput ]),
				E('div', { 'class': 'dd-geo-row' }, [ E('label', {}, 'GeoSite URL'), gsInput ])
			]);
			const syncCustom = function() {
				customRows.style.display = presetSel.value === 'custom' ? '' : 'none';
			};
			presetSel.addEventListener('change', syncCustom);
			syncCustom();

			const autoSel = E('select', {}, [
				E('option', { 'value': 'off' }, _('Disabled')),
				E('option', { 'value': 'daily' }, _('Daily')),
				E('option', { 'value': 'weekly' }, _('Weekly'))
			]);
			autoSel.value = auto0 ? freq0 : 'off';

			const saveBtn = E('button', { 'class': 'dd-up-btn dd-up-btn-primary' }, _('Save'));
			saveBtn.addEventListener('click', function() {
				const p = presetSel.value;
				let gi = '', gs = '';
				const geoAuto = autoSel.value !== 'off';
				const geoFreq = autoSel.value === 'weekly' ? 'weekly' : 'daily';
				if (p === 'v2fly') { gi = GEO_PRESETS.v2fly.geoip; gs = GEO_PRESETS.v2fly.geosite; }
				else if (p === 'custom') { gi = giInput.value.trim(); gs = gsInput.value.trim(); }
				uci.set('daede', 'config', 'geoip_url', gi);
				uci.set('daede', 'config', 'geosite_url', gs);
				uci.set('daede', 'config', 'geo_auto', geoAuto ? '1' : '0');
				uci.set('daede', 'config', 'geo_auto_freq', geoFreq);
				const orig = saveBtn.textContent;
				saveBtn.disabled = true; saveBtn.textContent = '...';
				uci.save().then(function() {
					return uci.changes();
				}).then(function(changes) {
					// apply only when changed; empty changeset fails apply (#16)
					if (changes && Object.keys(changes).length)
						return uci.apply();
				}).then(function() {
					return fs.exec('/usr/share/luci-app-daede/geo-cron.sh', [geoAuto ? 'enable' : 'disable']);
				}).then(function() {
					logPane.textContent = _('Geo data source saved.');
					logPane.classList.add('show');
					ui.changes.init();
				}).catch(function(e) {
					logPane.textContent = _('Save failed') + ': ' + (e && e.message ? e.message : e);
					logPane.classList.add('show');
				}).finally(function() {
					saveBtn.disabled = false; saveBtn.textContent = orig;
				});
			});

			const adv = E('div', { 'class': 'dd-adv dd-closed' }, [
				E('div', { 'class': 'dd-adv-bar' }, [
					E('span', {}, _('Data Source')),
					E('span', { 'class': 'dd-adv-chevron' }, '›')
				]),
				E('div', { 'class': 'dd-adv-body' }, [
					E('div', { 'class': 'dd-geo-row' }, [ E('label', {}, _('Source')), presetSel ]),
					customRows,
					E('div', { 'class': 'dd-geo-row' }, [
						E('label', {}, _('Auto-update')),
						autoSel
					]),
					E('div', { 'class': 'dd-geo-actions' }, [ saveBtn ])
				])
			]);
			adv.firstChild.addEventListener('click', function() {
				adv.classList.toggle('dd-closed');
			});
			return adv;
		})();

		return E('div', { 'class': 'dd-up-wrap' }, [
			E('style', {}, CSS),
			E('div', { 'class': 'dd-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('Data Updates')),
				dataBody,
				geoSettings
			]),
			E('div', { 'class': 'dd-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('Package Updates')),
				pkgBody
			]),
			E('div', { 'class': 'dd-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('Config Backup')),
				E('div', { 'class': 'dd-up-row' }, [
					E('span', { 'class': 'dd-up-icon dd-up-new' }, '⤓'),
					E('span', { 'class': 'dd-up-name' }, _('dae + daed')),
					E('span', { 'class': 'dd-up-meta' }, _('Back up / restore the whole daede config (kernels excluded)')),
					exportBtn,
					importBtn
				]),
				fileInput
			]),
			(function() {
				const adv = E('div', { 'class': 'dd-adv dd-closed' }, [
					E('div', { 'class': 'dd-adv-bar' }, [
						E('span', {}, _('System Health')),
						E('span', { 'class': 'dd-adv-chevron' }, '›')
					]),
					E('div', { 'class': 'dd-adv-body' }, [ healthBody ])
				]);
				adv.firstChild.addEventListener('click', function() {
					adv.classList.toggle('dd-closed');
				});
				return adv;
			})(),
			logPane
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
