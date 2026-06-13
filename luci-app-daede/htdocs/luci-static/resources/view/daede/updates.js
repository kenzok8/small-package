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

const HEALTH_PATHS = {
	btf: '/sys/kernel/btf/vmlinux',
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
	'.dd-up-err{color:#d96d6d}',
	'.dd-up-name{font-weight:600;opacity:.85}',
	'.dd-up-meta{opacity:.7;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}',
	'.dd-up-version{font-size:11px;opacity:.55;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;white-space:nowrap}',
	'.dd-up-btn{font-size:11px;line-height:1.4;min-height:0;height:auto;padding:4px 12px;border-radius:5px;border:1px solid rgba(128,128,128,.35);background:transparent;color:inherit;cursor:pointer;white-space:nowrap}',
	'.dd-up-btn:hover{background:rgba(128,128,128,.12)}',
	'.dd-up-btn:disabled{opacity:.45;cursor:not-allowed}',
	'.dd-up-btn-primary{border-color:#4aa065;color:#4aa065}',
	'.dd-up-log{margin-top:10px;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:11px;padding:10px;border:1px solid rgba(128,128,128,.14);border-radius:8px;max-height:200px;overflow:auto;white-space:pre-wrap;word-break:break-all;display:none;background:inherit;color:#4a8c63}',
	'.dd-up-log.show{display:block}',
		'body.dark .dd-up-log,html[data-theme="dark"] .dd-up-log,html[data-bs-theme="dark"] .dd-up-log{color:#a3d9ad}',
	/* 手风琴折叠组 —— 与 config.js dd-adv 同构 */
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

function tailLog(path, into) {
	return L.resolveDefault(fs.read_direct(path, 'text'), '').then(function(content) {
		if (content) {
			into.textContent = content;
			into.classList.add('show');
		}
	});
}

return view.extend({
	load: function() {
		return Promise.all([
			backend.detectBackend(),
			uci.load('daed').catch(function() {})
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

		// === Data updates (GeoIP / GeoSite) ===
		const updateGeo = function(kind, btn) {
			const label = kind === 'geoip' ? 'GeoIP' : 'GeoSite';
			btn.disabled = true;
			btn.textContent = '...';
			return fs.exec('/usr/share/luci-app-daede/update-geo.sh', [kind]).then(function(res) {
				if (res.code === 0) {
					setTimeout(function() { tailLog('/tmp/luci-app-daede.' + kind + '.log', logPane); }, 2000);
				}
			}).catch(function() {}).finally(function() {
				btn.disabled = false;
				btn.textContent = _('Update');
			});
		};

		// === Package updates (dae|daed / luci-app-daede) ===
		const upgradePkg = function(pkg, btn) {
			if (!confirm(_('Run "apk upgrade %s" now? This may restart the active backend.').format(pkg)))
				return;
			btn.disabled = true;
			btn.textContent = '...';
			return fs.exec('/usr/share/luci-app-daede/update-pkg.sh', [pkg]).then(function(res) {
				if (res.code === 0) {
					setTimeout(function() { tailLog('/tmp/luci-app-daede.pkg-' + pkg + '.log', logPane); }, 3000);
				}
			}).catch(function() {}).finally(function() {
				btn.disabled = false;
				btn.textContent = _('Upgrade');
			});
		};

		const refresh = function() {
			const probes = [
				probeFile(DATA_PATHS.geoip),
				probeFile(DATA_PATHS.geosite),
				probeFile(HEALTH_PATHS.btf),
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
				const geoip = r[0], geosite = r[1], btf = r[2], running = r[3], service = r[4];
				const pkgOffset = 5;
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
					const sameVersion = entry.r.installed && entry.r.latest && entry.r.installed === entry.r.latest;
					const updatable = entry.r.installed && entry.r.latest && entry.r.installed !== entry.r.latest;
					let meta;
					if (!entry.r.installed) {
						meta = _('not installed via package manager');
						btn.disabled = true;
						btn.textContent = _('Unavailable');
					} else if (sameVersion) {
						meta = _('installed') + ': ' + entry.r.installed + ' · ' + _('up to date');
						btn.disabled = true;
					} else if (!entry.r.latest) {
						// latest unknown (registry unreachable) - nothing to upgrade to
						meta = _('installed') + ': ' + entry.r.installed + ' · ' + _('latest version unknown');
						btn.disabled = true;
					} else if (updatable) {
						meta = _('installed') + ': ' + entry.r.installed + ' → ' + _('latest') + ': ' + entry.r.latest;
						} else {
						meta = _('installed') + ': ' + entry.r.installed + (entry.r.latest ? ' · ' + _('latest') + ': ' + entry.r.latest : '');
					}
					pkgBody.appendChild(mkRow(
						updatable ? '⚠' : (entry.r.installed ? '✓' : '✗'),
						updatable ? 'dd-up-warn' : (entry.r.installed ? 'dd-up-ok' : 'dd-up-err'),
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

		return E('div', { 'class': 'dd-up-wrap' }, [
			E('style', {}, CSS),
			E('div', { 'class': 'dd-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('Data Updates')),
				dataBody
			]),
			E('div', { 'class': 'dd-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('Package Updates')),
				pkgBody
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
