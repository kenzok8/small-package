// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require view';
'require view.honk.rpc as honk';

function detectLogLevel(line) {
	// honk-core tracing output (e.g. "  ERROR honk_core::...")
	if (/\s(?:ERROR|FATAL|PANIC)\s/.test(line)) return 'error';
	if (/\sWARN(?:ING)?\s/.test(line)) return 'warn';
	if (/\sDEBUG\s/.test(line)) return 'debug';
	if (/\sTRACE\s/.test(line)) return 'trace';
	if (/\sINFO\s/.test(line)) return 'info';
	// syslog facility.level (e.g. "daemon.err")
	if (/daemon\.(?:err|crit|alert|emerg)\b/.test(line)) return 'error';
	if (/daemon\.(?:warning|warn|notice)\b/.test(line)) return 'warn';
	if (/daemon\.debug\b/.test(line)) return 'debug';
	if (/daemon\.info\b/.test(line)) return 'info';
	return '';
}

function formatLogTs(raw) {
	// logread timestamp: "Wed Oct  7 18:58:09 2026" -> "2026-10-07 18:58:09"
	const m = String(raw || '').match(/^[A-Z][a-z]{2}\s+([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d{2}:\d{2}:\d{2})\s+(\d{4})$/);
	if (!m) return raw;
	const months = { Jan: 1, Feb: 2, Mar: 3, Apr: 4, May: 5, Jun: 6, Jul: 7, Aug: 8, Sep: 9, Oct: 10, Nov: 11, Dec: 12 };
	const month = months[m[1]];
	if (!month) return raw;
	return m[4] + '-' + String(month).padStart(2, '0') + '-' + String(Number(m[2])).padStart(2, '0') + ' ' + m[3];
}

function lvlShort(level) {
	const u = (level || '').toUpperCase();
	if (u === 'WARNING') return 'WARN';
	return u || '-';
}

function lvlClass(level) {
	const u = (level || '').toUpperCase();
	if (u === 'TRACE') return 'honk-log-lvl-trace';
	if (u === 'DEBUG') return 'honk-log-lvl-debug';
	if (u === 'INFO') return 'honk-log-lvl-info';
	if (u === 'WARN' || u === 'WARNING') return 'honk-log-lvl-warn';
	return 'honk-log-lvl-error';
}

function parseLogLine(line) {
	// "Wed Oct  7 18:58:09 2026 daemon.info honk-core[31377]:  INFO honk_core::..."
	const m = line.match(/^([A-Z][a-z]{2}\s+[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})\s+\S+\s+[^:]+:\s*(.*)$/);
	if (!m) return { ts: '', lvl: '', msg: line };
	let body = m[2] || '';
	const lvlMatch = body.match(/^\s*(TRACE|DEBUG|INFO|WARN(?:ING)?|ERROR|FATAL|PANIC)\s+(.*)$/i);
	let lvl = '';
	if (lvlMatch) {
		lvl = lvlMatch[1].toUpperCase();
		body = lvlMatch[2];
	}
	return { ts: formatLogTs(m[1]), lvl: lvl, msg: body };
}

function buildLogLine(line) {
	const level = detectLogLevel(line);
	const parsed = parseLogLine(line);
	const parts = [];
	if (parsed.ts)
		parts.push(E('span', { 'class': 'honk-log-ts' }, parsed.ts));
	if (parsed.lvl)
		parts.push(E('span', { 'class': 'honk-log-lvl ' + lvlClass(parsed.lvl) }, lvlShort(parsed.lvl)));
	parts.push(E('span', { 'class': 'honk-log-msg' }, parsed.msg));
	return E('span', { 'class': 'honk-log-line' + (level ? ' honk-log-' + level : '') }, parts);
}

return view.extend({
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,
	_timer: null,

	handleUnload: function() {
		if (this._timer != null)
			clearInterval(this._timer);
		this._timer = null;
	},

	render: function() {
		honk.installStyles();
		const source = E('select', { 'class': 'cbi-input-select' }, [
			E('option', { 'value': 'core' }, _('Core')),
			E('option', { 'value': 'service' }, _('Service')),
			E('option', { 'value': 'maintenance' }, _('Maintenance'))
		]);
		const level = E('select', { 'class': 'cbi-input-select' }, [
			E('option', { 'value': 'all' }, _('All levels')),
			E('option', { 'value': 'debug' }, _('Debug and above')),
			E('option', { 'value': 'info' }, _('Info and above')),
			E('option', { 'value': 'warn' }, _('Warnings and errors')),
			E('option', { 'value': 'error' }, _('Errors only'))
		]);
		const output = E('pre', {
			'class': 'honk-log-output',
			'aria-live': 'polite'
		}, _('Loading logs…'));
		const status = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const pause = E('button', { 'class': 'cbi-button', 'type': 'button' }, _('Pause'));
		const refresh = E('button', { 'class': 'cbi-button', 'type': 'button' }, _('Refresh now'));
		const download = E('button', { 'class': 'cbi-button', 'type': 'button' }, _('Download redacted log'));
		let paused = false;
		let pendingRequests = 0;
		let requestSequence = 0;
		let latest = [];
		download.disabled = true;

		function loadLogs(force) {
			if (paused && !force || pendingRequests && !force)
				return Promise.resolve();

			const requestId = ++requestSequence;
			const requestedSource = source.value;
			const requestedLevel = level.value;
			pendingRequests++;
			download.disabled = true;
			return honk.logs(requestedSource, requestedLevel, 200).then(honk.ensureOk).then(function(result) {
				if (requestId !== requestSequence)
					return;
				latest = Array.isArray(result.lines) ? result.lines.map(String) : [];
				output.replaceChildren();
				if (latest.length) {
					latest.forEach(function(line) {
						output.appendChild(buildLogLine(line));
					});
				}
				else {
					output.textContent = _('No matching Honk log entries.');
				}
				status.textContent = result.capped ? _('Output was capped; showing the latest %d entries.').format(latest.length) : _('Showing the latest %d matching entries.').format(latest.length);
			}).catch(function(error) {
				if (requestId === requestSequence)
					status.textContent = honk.errorMessage(error, _('Could not read Honk logs.'));
			}).finally(function() {
				pendingRequests--;
				download.disabled = pendingRequests > 0;
			});
		}

		pause.addEventListener('click', function(ev) {
			ev.preventDefault();
			paused = !paused;
			pause.textContent = paused ? _('Resume') : _('Pause');
			status.textContent = paused ? _('Log polling is paused.') : _('Log polling resumed.');
			if (!paused)
				loadLogs(true);
		});
		refresh.addEventListener('click', function(ev) {
			ev.preventDefault();
			loadLogs(true);
		});
		source.addEventListener('change', function() { loadLogs(true); });
		level.addEventListener('change', function() { loadLogs(true); });
		download.addEventListener('click', function(ev) {
			ev.preventDefault();
			const blob = new Blob([ latest.join('\n') + (latest.length ? '\n' : '') ], { type: 'text/plain;charset=utf-8' });
			const url = URL.createObjectURL(blob);
			const link = E('a', { 'href': url, 'download': 'honk-redacted.log' });
			document.body.appendChild(link);
			link.click();
			link.remove();
			setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
		});

		source.id = 'honk-log-source';
		level.id = 'honk-log-level';
		this._timer = setInterval(function() { loadLogs(false); }, 5000);
		loadLogs(true);

		return E('div', { 'class': 'cbi-map honk-page' }, [
			E('div', { 'class': 'honk-header' }, [
				E('h2', {}, _('Logs')),
				E('p', { 'class': 'honk-header-sub' }, _('Shows up to 200 Honk-specific lines, capped at 32 KiB, and refreshes every 5 seconds while live. Sensitive URLs and credentials are redacted before display.'))
			]),
			E('section', { 'class': 'honk-card' }, [
				E('h3', { 'class': 'honk-card-title' }, _('Live log')),
				E('div', { 'class': 'honk-log-toolbar' }, [
					E('label', { 'for': source.id }, [ _('Log source'), source ]),
					E('label', { 'for': level.id }, [ _('Minimum level'), level ]),
					E('div', { 'class': 'honk-actions' }, [ pause, refresh, download ])
				]),
				status,
				output
			])
		]);
	}
});
