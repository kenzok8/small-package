// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require fs';
'require poll';
'require uci';
'require ui';
'require view';
'require view.honk.rpc as honk';

const BACKUP_PATH = '/tmp/honk-backup.tar.gz';
const RESTORE_PATH = '/tmp/honk-maintenance/restore.tar.gz';
const PKG_INFO = '/usr/share/luci-app-honk/pkg-info.sh';
const UPDATE_PKG = '/usr/share/luci-app-honk/update-pkg.sh';
const REFRESH_INDEX = '/usr/share/luci-app-honk/refresh-index.sh';
const UPDATE_GEO = '/usr/share/luci-app-honk/update-geo.sh';
const GEO_CRON = '/usr/share/luci-app-honk/geo-cron.sh';
const PKGS = [ 'honk', 'luci-app-honk' ];
const PKG_NAMES = { honk: 'Honk', 'luci-app-honk': 'luci-app-honk' };

const DATA_PATHS = {
	geoip: '/usr/share/v2ray/geoip.dat',
	geosite: '/usr/share/v2ray/geosite.dat'
};

// Geo data source presets. `loyalsoldier` keeps both URLs empty so the actual
// default lives in one place — update-geo.sh — avoiding UI/script drift.
const GEO_PRESETS = {
	loyalsoldier: { geoip: '', geosite: '' },
	v2fly: {
		geoip: 'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
		geosite: 'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
	}
};

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

// Compare two version strings like `sort -V`. Returns <0 / 0 / >0.
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

return view.extend({
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,

	load: function() {
		return uci.load('honk').catch(function() {});
	},

	render: function() {
		honk.installStyles();
		const page = E('div', { 'class': 'cbi-map honk-page' });
		const recoveryMessage = E('p', { 'class': 'alert-message', 'role': 'status' }, '');
		recoveryMessage.hidden = true;
		const writeControls = [];
		let recoveryRequired = false;

		function phaseMessage(job, fallback) {
			const messages = {
				preparing: _('Preparing maintenance…'),
				stopping: _('Stopping Honk…'),
				applying: _('Applying the staged data…'),
				validating: _('Validating the new state…'),
				starting: _('Starting Honk…'),
				rolling_back: _('Restoring the previous state…'),
				committing: _('Finishing the transaction…'),
				recovery: _('Recovery is required before another write operation.')
			};
			return messages[job.phase] || fallback;
		}

		function blockWrites() {
			recoveryRequired = true;
			writeControls.forEach(function(button) { button.disabled = true; });
		}

		/* Shared log pane and row helper for both data and package updates. */
		const updateLog = E('pre', { 'class': 'honk-up-log', 'hidden': true }, '');

		function mkPkgRow(icon, iconCls, name, meta, btn) {
			return E('div', { 'class': 'honk-pkg-row' }, [
				E('span', { 'class': 'honk-pkg-icon ' + iconCls }, icon),
				E('span', { 'class': 'honk-pkg-name' }, name),
				E('span', { 'class': 'honk-pkg-meta', 'title': meta }, meta),
				E('span', {}, ''),
				btn || E('span', {}, '')
			]);
		}

		function probeFile(path) {
			return fs.stat(path).then(function(st) {
				return { exists: true, size: st.size, mtime: st.mtime };
			}).catch(function() {
				return { exists: false, size: 0, mtime: 0 };
			});
		}

		/* --- Geo data card --- */
		const dataSection = E('section', { 'class': 'honk-card' });
		const dataBody = E('div', { 'id': 'honk-geo' }, E('em', {}, _('Probing…')));

		function updateGeo(kind, btn) {
			const orig = btn.textContent;
			btn.disabled = true;
			btn.textContent = '…';
			let tries = 0;
			const pollLog = function() {
				return fs.read_direct('/tmp/luci-app-honk.' + kind + '.log', 'text').then(function(c) {
					if (c) {
						updateLog.textContent = c;
						updateLog.hidden = false;
					}
					if (/[✓✗]/.test(c)) { refreshData(); return; }
					if (tries++ > 90) return;
					return new Promise(function(r) { setTimeout(r, 2000); }).then(pollLog);
				}).catch(function() {});
			};
			return fs.exec(UPDATE_GEO, [ kind ]).then(function(res) {
				if (res.code === 0) return pollLog();
			}).catch(function() {}).finally(function() {
				btn.disabled = false;
				btn.textContent = orig;
			});
		}

		function refreshData() {
			return Promise.all([ probeFile(DATA_PATHS.geoip), probeFile(DATA_PATHS.geosite) ]).then(function(r) {
				while (dataBody.firstChild)
					dataBody.removeChild(dataBody.firstChild);
				[
					{ k: 'geoip', name: 'GeoIP', r: r[0] },
					{ k: 'geosite', name: 'GeoSite', r: r[1] }
				].forEach(function(entry) {
					const btn = E('button', { 'class': 'cbi-button cbi-button-action', 'type': 'button' }, _('Update'));
					btn.addEventListener('click', function(ev) { ev.preventDefault(); updateGeo(entry.k, btn); });
					const meta = entry.r.exists
						? fmtBytes(entry.r.size) + (entry.r.mtime ? ' · ' + fmtMtime(entry.r.mtime) : '')
						: _('missing — click Update to fetch');
					dataBody.appendChild(mkPkgRow(
						entry.r.exists ? '✓' : '✗',
						entry.r.exists ? 'honk-pkg-ok' : 'honk-pkg-err',
						entry.name,
						meta,
						btn
					));
				});
			});
		}

		function geoField(label, input) {
			return E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title', 'for': input.id }, label),
				E('div', { 'class': 'cbi-value-field' }, input)
			]);
		}

		const geoSettings = (function() {
			const gi0 = uci.get('honk', 'main', 'geoip_url') || '';
			const gs0 = uci.get('honk', 'main', 'geosite_url') || '';
			const auto0 = uci.get('honk', 'main', 'geo_auto') === '1';
			const freq0 = uci.get('honk', 'main', 'geo_auto_freq') || 'daily';
			const preset0 = (!gi0 && !gs0) ? 'loyalsoldier' :
				(gi0 === GEO_PRESETS.v2fly.geoip && gs0 === GEO_PRESETS.v2fly.geosite) ? 'v2fly' : 'custom';

			const presetSel = E('select', { 'class': 'cbi-input-select', 'id': 'honk-geo-preset' }, [
				E('option', { 'value': 'loyalsoldier' }, 'Loyalsoldier'),
				E('option', { 'value': 'v2fly' }, 'v2fly'),
				E('option', { 'value': 'custom' }, _('Custom'))
			]);
			presetSel.value = preset0;

			const giInput = E('input', { 'class': 'cbi-input-text', 'type': 'text', 'id': 'honk-geo-ip', 'placeholder': 'https://…/geoip.dat' });
			const gsInput = E('input', { 'class': 'cbi-input-text', 'type': 'text', 'id': 'honk-geo-site', 'placeholder': 'https://…/geosite.dat' });
			giInput.value = preset0 === 'custom' ? gi0 : '';
			gsInput.value = preset0 === 'custom' ? gs0 : '';

			const customRows = E('div', {}, [
				geoField(_('GeoIP URL'), giInput),
				geoField(_('GeoSite URL'), gsInput)
			]);
			const syncCustom = function() { customRows.style.display = presetSel.value === 'custom' ? '' : 'none'; };
			presetSel.addEventListener('change', syncCustom);
			syncCustom();

			const autoSel = E('select', { 'class': 'cbi-input-select', 'id': 'honk-geo-auto' }, [
				E('option', { 'value': 'off' }, _('Disabled')),
				E('option', { 'value': 'daily' }, _('Daily')),
				E('option', { 'value': 'weekly' }, _('Weekly'))
			]);
			autoSel.value = auto0 ? freq0 : 'off';

			const saveBtn = E('button', { 'class': 'cbi-button cbi-button-action', 'type': 'button' }, _('Save'));
			saveBtn.addEventListener('click', function() {
				const p = presetSel.value;
				let gi = '', gs = '';
				const geoAuto = autoSel.value !== 'off';
				const geoFreq = autoSel.value === 'weekly' ? 'weekly' : 'daily';
				if (p === 'v2fly') { gi = GEO_PRESETS.v2fly.geoip; gs = GEO_PRESETS.v2fly.geosite; }
				else if (p === 'custom') {
					gi = giInput.value.trim(); gs = gsInput.value.trim();
					for (const [label, url] of [['GeoIP URL', gi], ['GeoSite URL', gs]]) {
						if (url) {
							try {
								const u = new URL(url);
								if (u.protocol !== 'http:' && u.protocol !== 'https:') throw new Error('bad protocol');
							} catch (e) {
								document.getElementById('honk-geo-msg').textContent = _('Invalid %s: must be an http(s) URL.').format(label);
								return;
							}
						}
					}
				}
				uci.set('honk', 'main', 'geoip_url', gi);
				uci.set('honk', 'main', 'geosite_url', gs);
				uci.set('honk', 'main', 'geo_auto', geoAuto ? '1' : '0');
				uci.set('honk', 'main', 'geo_auto_freq', geoFreq);
				const orig = saveBtn.textContent;
				saveBtn.disabled = true; saveBtn.textContent = '…';
				uci.save().then(function() {
					return uci.changes();
				}).then(function(changes) {
					if (changes && Object.keys(changes).length)
						return uci.apply();
				}).then(function() {
					return fs.exec(GEO_CRON, [ geoAuto ? 'enable' : 'disable' ]);
				}).then(function() {
					updateLog.textContent = _('Geo data source saved.');
					updateLog.hidden = false;
					ui.changes.init();
				}).catch(function(e) {
					updateLog.textContent = _('Save failed') + ': ' + (e && e.message ? e.message : e);
					updateLog.hidden = false;
				}).finally(function() {
					saveBtn.disabled = false; saveBtn.textContent = orig;
				});
			});

			return E('details', {}, [
				E('summary', {}, _('Data source and auto-update')),
				E('div', {}, [
					geoField(_('Source'), presetSel),
					customRows,
					geoField(_('Auto-update'), autoSel),
					E('div', { 'class': 'honk-actions' }, [ saveBtn ]),
					E('p', { 'class': 'honk-note', 'id': 'honk-geo-msg' })
				])
			]);
		})();

		dataSection.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Geo data')));
		dataSection.appendChild(E('p', { 'class': 'honk-note' }, _('GeoIP and GeoSite routing data can be updated here. Updates run in the background and reload Honk when done.')));
		dataSection.appendChild(dataBody);
		dataSection.appendChild(geoSettings);

		/* --- Software package updates card --- */
		const updateSection = E('section', { 'class': 'honk-card' });
		const pkgBody = E('div', { 'id': 'honk-pkg' }, E('em', {}, _('Probing…')));

		function probePkg(pkg) {
			return fs.exec(PKG_INFO, [ pkg ]).then(function(res) {
				const out = (res.stdout || '').trim().split('\t');
				return { installed: out[0] || '', latest: out[1] || '' };
			}).catch(function() {
				return { installed: '', latest: '' };
			});
		}

		function upgradePkg(pkg, btn) {
			const orig = btn.textContent;
			btn.disabled = true;
			btn.textContent = '…';
			let tries = 0;
			const pollLog = function() {
				return fs.read_direct('/tmp/luci-app-honk.pkg-' + pkg + '.log', 'text').then(function(c) {
					if (c) {
						updateLog.textContent = c;
						updateLog.hidden = false;
					}
					if (/[✓✗]/.test(c)) { refreshPkgs(); return; }
					if (tries++ > 90) return;
					return new Promise(function(r) { setTimeout(r, 2000); }).then(pollLog);
				}).catch(function() {});
			};
			return fs.exec(UPDATE_PKG, [ pkg ]).then(function(res) {
				if (res.code === 0) return pollLog();
			}).catch(function() {}).finally(function() {
				btn.disabled = false;
				btn.textContent = orig;
			});
		}

		function refreshPkgs() {
			const probes = PKGS.map(probePkg);
			return Promise.all(probes).then(function(infos) {
				while (pkgBody.firstChild)
					pkgBody.removeChild(pkgBody.firstChild);
				PKGS.forEach(function(pkg, i) {
					const r = infos[i];
					const btn = E('button', { 'class': 'cbi-button cbi-button-action', 'type': 'button' }, _('Upgrade'));
					btn.addEventListener('click', function(ev) { ev.preventDefault(); upgradePkg(pkg, btn); });
					const cmp = (r.installed && r.latest) ? cmpVer(r.latest, r.installed) : null;
					const updatable = cmp !== null && cmp > 0;
					let meta;
					if (!r.installed) {
						meta = _('not installed via package manager');
						btn.disabled = true;
						btn.textContent = _('Unavailable');
					} else if (!r.latest) {
						meta = _('installed') + ': ' + r.installed + ' · ' + _('latest version unknown');
						btn.disabled = true;
					} else if (updatable) {
						meta = _('installed') + ': ' + r.installed + ' → ' + _('latest') + ': ' + r.latest;
					} else {
						meta = _('installed') + ': ' + r.installed + ' · ' + _('up to date');
						btn.disabled = true;
					}
					pkgBody.appendChild(mkPkgRow(
						updatable ? '↑' : (r.installed ? '✓' : '✗'),
						updatable ? 'honk-pkg-new' : (r.installed ? 'honk-pkg-ok' : 'honk-pkg-err'),
						PKG_NAMES[pkg],
						meta,
						btn
					));
				});
			});
		}

		updateSection.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Package updates')));
		updateSection.appendChild(E('p', { 'class': 'honk-note' }, _('Honk core and LuCI can be upgraded here without leaving the management page. The package index refreshes in the background.')));
		updateSection.appendChild(pkgBody);

		/* --- Config backup card --- */
		const backupSection = E('section', { 'class': 'honk-card' });
		const backupMessage = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const exportBtn = E('button', { 'class': 'cbi-button cbi-button-action', 'type': 'button' }, _('Export'));
		const importBtn = E('button', { 'class': 'cbi-button', 'type': 'button' }, _('Import'));
		const restoreCfgBtn = E('button', { 'class': 'cbi-button cbi-button-negative', 'type': 'button' }, _('Restore config'));
		const fileInput = E('input', { 'type': 'file', 'accept': '.tar.gz,.gz,application/gzip', 'style': 'display:none' });
		let backupBusy = false;
		writeControls.push(exportBtn, importBtn, restoreCfgBtn);

		function setBackupBusy(busy) {
			backupBusy = busy;
			[exportBtn, importBtn, restoreCfgBtn].forEach(function(b) {
				b.disabled = busy || recoveryRequired;
			});
		}

		exportBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (backupBusy) return;
			setBackupBusy(true);
			backupMessage.textContent = _('Preparing backup…');
			honk.backup().then(honk.ensureOk).then(function(result) {
				return honk.waitJob(result.job_id, function(job) {
					backupMessage.textContent = job.state === 'running' ? _('Creating backup…') : _('Preparing download…');
				});
			}).then(function() {
				return fs.read_direct(BACKUP_PATH, 'blob');
			}).then(function(blob) {
				const url = URL.createObjectURL(blob);
				const link = E('a', { 'href': url, 'download': 'honk-backup.tar.gz' });
				document.body.appendChild(link);
				link.click();
				link.remove();
				setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
				backupMessage.textContent = _('Backup downloaded.');
			}).catch(function(error) {
				if (error && error.recoveryRequired)
					blockWrites();
				backupMessage.textContent = honk.errorMessage(error, _('Backup failed.'));
			}).finally(function() { setBackupBusy(false); });
		});

		importBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (backupBusy) return;
			fileInput.click();
		});
		fileInput.addEventListener('change', function(ev) {
			const file = ev.target.files && ev.target.files[0];
			if (!file) return;
			if (!confirm(_('Stop Honk before restoring. Restoring replaces Honk user data. Continue?'))) {
				fileInput.value = '';
				return;
			}
			setBackupBusy(true);
			backupMessage.textContent = _('Restoring…');
			honk.restorePrepare().then(honk.ensureOk).then(function() {
				return ui.uploadFile(RESTORE_PATH);
			}).then(function() {
				return honk.restore();
			}).then(honk.ensureOk).then(function(result) {
				return honk.waitJob(result.job_id, function(job) {
					backupMessage.textContent = phaseMessage(job, _('Restoring Honk data…'));
				});
			}).then(function(result) {
				backupMessage.textContent = honk.resultMessage(result, _('Backup restored.'));
			}).catch(function(error) {
				if (error && error.recoveryRequired)
					blockWrites();
				backupMessage.textContent = honk.errorMessage(error, _('Restore failed.'));
			}).finally(function() {
				setBackupBusy(false);
				fileInput.value = '';
			});
		});

		restoreCfgBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (!confirm(_('This permanently clears Honk subscriptions, nodes, policies, DNS data, history, and cache, then restores the default configuration. The administrator account is kept, and Honk will be stopped. Continue?')))
				return;
			setBackupBusy(true);
			backupMessage.textContent = _('Restoring default config…');
			honk.reset().then(honk.ensureOk).then(function(result) {
				return honk.waitJob(result.job_id, function(job) {
					backupMessage.textContent = phaseMessage(job, _('Restoring default config…'));
				});
			}).then(function(result) {
				backupMessage.textContent = honk.resultMessage(result, _('Honk data reset. The service is stopped.'));
			}).catch(function(error) {
				if (error && error.recoveryRequired)
					blockWrites();
				backupMessage.textContent = honk.errorMessage(error, _('Reset failed.'));
			}).finally(function() { setBackupBusy(false); });
		});

		backupSection.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Config backup')));
		backupSection.appendChild(E('p', { 'class': 'honk-note' }, _('Export a backup archive, import one from your computer, or restore Honk to its default configuration.')));
		backupSection.appendChild(E('div', { 'class': 'honk-actions' }, [ exportBtn, importBtn, restoreCfgBtn ]));
		backupSection.appendChild(fileInput);
		backupSection.appendChild(backupMessage);

		/* --- System check and repair card --- */
		const health = E('section', { 'class': 'honk-card' });
		const healthMessage = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const check = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Run system check'));
		check.addEventListener('click', function(ev) {
			ev.preventDefault();
			check.disabled = true;
			healthMessage.textContent = _('Checking…');
			honk.check().then(function(result) {
				if (result && result.ok === true) {
					healthMessage.textContent = _('System check passed.');
				}
				else if (Array.isArray(result && result.errors) && result.errors.length) {
					healthMessage.textContent = result.errors.map(honk.statusIssue).join('；');
				}
				else {
					healthMessage.textContent = _('The backend did not confirm the check.');
				}
			}).catch(function(error) {
				healthMessage.textContent = _('System check failed.');
			}).finally(function() { check.disabled = false; });
		});
		const repairMessage = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const repair = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Repair'));
		writeControls.push(repair);
		repair.addEventListener('click', function(ev) {
			ev.preventDefault();
			repair.disabled = true;
			repairMessage.textContent = _('Repairing…');
			honk.repair().then(honk.ensureOk).then(function(result) {
				repairMessage.textContent = honk.resultMessage(result, _('Repair completed.'));
			}).catch(function(error) {
				if (error && error.recoveryRequired)
					blockWrites();
				repairMessage.textContent = honk.errorMessage(error, _('Repair failed.'));
			}).finally(function() { repair.disabled = recoveryRequired; });
		});
		health.appendChild(E('h3', { 'class': 'honk-card-title' }, _('System check and repair')));
		health.appendChild(E('p', { 'class': 'honk-note' }, _('Checks Honk system components and reports detected issues.')));
		health.appendChild(E('div', { 'class': 'honk-actions' }, [ check, repair ]));
		health.appendChild(healthMessage);
		health.appendChild(repairMessage);
		health.appendChild(E('p', { 'class': 'honk-note' }, _('Repair replaces missing or damaged Honk system files and does not overwrite user configuration.')));

		page.appendChild(E('div', { 'class': 'honk-header' }, [
			E('h2', {}, _('Maintenance')),
			E('p', { 'class': 'honk-header-sub' }, _('Package updates, config backup and system recovery for the Honk installation.'))
		]));
		page.appendChild(recoveryMessage);
		page.appendChild(dataSection);
		page.appendChild(updateSection);
		page.appendChild(backupSection);
		page.appendChild(health);
		page.appendChild(updateLog);

		// Background index refresh so new versions show on the next poll.
		fs.exec(REFRESH_INDEX, []).catch(function() {});
		refreshData();
		refreshPkgs();
		poll.add(refreshData, 15);
		poll.add(refreshPkgs, 15);

		honk.status().then(function(result) {
			const errors = Array.isArray(result && result.errors) ? result.errors : [];
			const recoveryToken = errors.indexOf('update_recovery_required') >= 0 ? 'update_recovery_required' :
				errors.indexOf('maintenance_recovery_required') >= 0 ? 'maintenance_recovery_required' : null;
			if (recoveryToken) {
				blockWrites();
				recoveryMessage.textContent = honk.statusIssue(recoveryToken);
				recoveryMessage.hidden = false;
			}
		}).catch(function() {});
		return page;
	}
});
