// SPDX-License-Identifier: Apache-2.0

'use strict';
'require fs';
'require poll';
'require ui';
'require view';
'require view.daede.backend as backend';

const MAX_LINES = 5000;

const CSS = [
	'.dd-log-wrap{padding:4px 0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
	'.dd-log-card{border:1px solid rgba(0,0,0,.06);border-radius:10px;padding:10px 14px;margin-bottom:10px;box-shadow:0 2px 8px rgba(0,0,0,.03);background:rgba(255,255,255,.02)}',
	'.dd-log-card-title{font-size:11px;font-weight:600;opacity:.55;margin:0 0 8px;letter-spacing:.3px;text-transform:uppercase}',
	'.dd-log-toolbar{display:flex;flex-wrap:wrap;align-items:center;gap:8px;padding:0 0 8px;margin-bottom:8px;border-bottom:1px dashed rgba(128,128,128,.2)}',
	'.dd-log-toolbar label{display:inline-flex;align-items:center;gap:5px;font-size:11.5px;cursor:pointer;margin:0;opacity:.85}',
	'.dd-log-toolbar input[type="checkbox"]{margin:0}',
	'.dd-log-toolbar input[type="text"]{font-size:11.5px;padding:4px 8px;border-radius:5px;border:1px solid rgba(128,128,128,.28);background:transparent;color:inherit;min-width:160px}',
	'.dd-log-toolbar .dd-log-btn{font-size:11.5px;line-height:1.4;min-height:0;height:auto;padding:4px 12px;border-radius:5px;border:1px solid rgba(128,128,128,.28);background:transparent;color:inherit;cursor:pointer}',
	'.dd-log-toolbar .dd-log-btn:hover{background:rgba(128,128,128,.1)}',
	'.dd-log-toolbar .dd-log-meta{margin-left:auto;font-size:10.5px;opacity:.55;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace}',
	'.dd-log-pane{height:60vh;min-height:360px;overflow:auto;padding:8px 10px;border:1px solid rgba(0,0,0,.08);border-radius:7px;background:#1a1d21;color:#d8dde6;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace;font-size:11.5px;line-height:1.55;white-space:pre-wrap;word-break:break-all}',
	'.dd-log-pane .dd-line{padding:1px 4px;border-radius:3px;display:block}',
	'.dd-log-pane .dd-line.dd-info{color:#cfd6df}',
	'.dd-log-pane .dd-line.dd-warn{color:#e8b95a}',
	'.dd-log-pane .dd-line.dd-error{color:#ea7878;background:rgba(234,120,120,.06)}',
	'.dd-log-pane .dd-line.dd-debug{color:#7a8290;opacity:.7}',
	'.dd-log-pane .dd-line.dd-hidden{display:none}',
	'.dd-log-pane .dd-empty{opacity:.5;font-style:italic}',
	/* 简化后的字段视觉 */
	'.dd-log-pane .dd-ts{color:#6b7480;margin-right:8px}',
	'.dd-log-pane .dd-lvl{display:inline-block;min-width:38px;padding:0 5px;margin-right:8px;border-radius:3px;font-size:10px;font-weight:700;letter-spacing:.4px;text-align:center;vertical-align:1px}',
	'.dd-log-pane .dd-lvl-info{color:#7fc7a8;background:rgba(127,199,168,.08)}',
	'.dd-log-pane .dd-lvl-warn{color:#e8b95a;background:rgba(232,185,90,.10)}',
	'.dd-log-pane .dd-lvl-error{color:#ea7878;background:rgba(234,120,120,.10)}',
	'.dd-log-pane .dd-lvl-debug{color:#7a8290;background:rgba(122,130,144,.10)}',
	'.dd-log-pane .dd-msg{color:inherit}',
	'.dd-log-pane .dd-kv{margin-left:6px;color:#6b7480;font-size:11px;opacity:.85}',
	'body.dark .dd-log-card,html[data-theme="dark"] .dd-log-card,html[data-bs-theme="dark"] .dd-log-card{border-color:rgba(255,255,255,.08);background:rgba(255,255,255,.02)}',
	'body.dark .dd-log-pane,html[data-theme="dark"] .dd-log-pane,html[data-bs-theme="dark"] .dd-log-pane{border-color:rgba(255,255,255,.1)}'
].join('');

/* 拆字段：time="May 25 07:04:59" level=info msg="..." key=val key="val with space" ... */
const RE_LINE = /^time="([^"]*)"\s+level=(\w+)\s+msg=(?:"((?:[^"\\]|\\.)*)"|(\S+))\s*(.*)$/;

function detectLevel(line) {
	// daed/dae logs use lvl=info / [INFO] / level=warning style
	const m = line.match(/\b(DEBUG|INFO|WARN(?:ING)?|ERROR|FATAL|PANIC)\b/i);
	if (!m) return '';
	const lvl = m[1].toUpperCase();
	if (lvl === 'DEBUG') return 'dd-debug';
	if (lvl === 'INFO') return 'dd-info';
	if (lvl.startsWith('WARN')) return 'dd-warn';
	return 'dd-error';
}

/* 简化时间戳并按本地时区显示：
 * - daed 默认输出 UTC ISO 8601 (e.g. "2026-05-28T19:07:54Z")，转成本地时间
 * - 旧 logrus 短格式 (e.g. "May 25 07:04:59") 无时区信息，原样提取
 */
function shortTs(raw) {
	if (!raw) return raw;
	if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(raw)) {
		const d = new Date(raw);
		if (!isNaN(d.getTime())) {
			const pad = n => String(n).padStart(2, '0');
			return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
		}
	}
	const m = raw.match(/(\d{2}:\d{2}:\d{2})/);
	return m ? m[1] : raw;
}

function lvlShort(level) {
	const u = (level || '').toUpperCase();
	if (u === 'WARNING') return 'WARN';
	return u || '-';
}

function lvlClass(level) {
	const u = (level || '').toUpperCase();
	if (u === 'DEBUG') return 'dd-lvl-debug';
	if (u === 'INFO') return 'dd-lvl-info';
	if (u === 'WARN' || u === 'WARNING') return 'dd-lvl-warn';
	return 'dd-lvl-error';
}

function buildLine(ln) {
	const cls = detectLevel(ln);
	const m = ln.match(RE_LINE);
	if (!m) {
		return E('div', { 'class': 'dd-line ' + cls }, ln);
	}
	const ts = shortTs(m[1]);
	const lvl = m[2];
	const msg = m[3] !== undefined ? m[3] : (m[4] || '');
	const kv  = (m[5] || '').trim();
	const parts = [
		E('span', { 'class': 'dd-ts' }, ts),
		E('span', { 'class': 'dd-lvl ' + lvlClass(lvl) }, lvlShort(lvl)),
		E('span', { 'class': 'dd-msg' }, msg)
	];
	if (kv) parts.push(E('span', { 'class': 'dd-kv' }, kv));
	return E('div', { 'class': 'dd-line ' + cls }, parts);
}

return view.extend({
	load: function() {
		return backend.detectBackend();
	},

	render(ctx) {
		const self = this;
		const LOG_PATH = ctx.backend.log;
		const state = {
			lastContent: '',
			lastSize: -1,
			paused: false,
			autoScroll: true,
			filter: '',
			userScrolled: false
		};

		const pane = E('div', { 'class': 'dd-log-pane', 'id': 'dd-log-pane' }, [
			E('div', { 'class': 'dd-empty' }, _('Loading…'))
		]);

		// detect manual scroll → auto-pause auto-scroll
		pane.addEventListener('scroll', function() {
			const atBottom = pane.scrollHeight - pane.scrollTop - pane.clientHeight < 4;
			state.userScrolled = !atBottom;
		});

		const meta = E('span', { 'class': 'dd-log-meta' }, '');

		const cbAuto = E('input', { 'type': 'checkbox', 'checked': 'checked' });
		cbAuto.addEventListener('change', function() {
			state.autoScroll = cbAuto.checked;
			if (state.autoScroll) {
				pane.scrollTop = pane.scrollHeight;
				state.userScrolled = false;
			}
		});

		const cbPause = E('input', { 'type': 'checkbox' });
		cbPause.addEventListener('change', function() {
			state.paused = cbPause.checked;
		});

		const selFilter = E('select', { 'class': 'dd-log-btn' }, [
			E('option', { 'value': '' }, _('All')),
			E('option', { 'value': 'info' }, 'INFO'),
			E('option', { 'value': 'warn' }, 'WARN'),
			E('option', { 'value': 'error' }, 'ERROR'),
			E('option', { 'value': 'alive' }, _('Node Status')),
			E('option', { 'value': 'my_group' }, _('Proxy Traffic'))
		]);
		selFilter.addEventListener('change', function() {
			state.filter = selFilter.value;
			applyFilter();
		});

		const btnClear = E('button', { 'class': 'dd-log-btn' }, _('Clear View'));
		btnClear.addEventListener('click', function() {
			while (pane.firstChild) pane.removeChild(pane.firstChild);
			state.lastContent = '';
		});

		const btnDownload = E('button', { 'class': 'dd-log-btn' }, _('Download'));
		btnDownload.addEventListener('click', function() {
			const blob = new Blob([state.lastContent || ''], { type: 'text/plain' });
			const url = URL.createObjectURL(blob);
			const a = document.createElement('a');
			a.href = url;
			a.download = ctx.name + '-' + (new Date()).toISOString().replace(/[:.]/g, '-') + '.log';
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
			URL.revokeObjectURL(url);
		});

		const btnTruncate = E('button', { 'class': 'dd-log-btn' }, _('Clear File'));
		btnTruncate.addEventListener('click', function() {
			if (!confirm(_('Truncate %s log on the router? This cannot be undone.').format(ctx.name)))
				return;
			fs.write(LOG_PATH, '').then(function() {
				state.lastContent = '';
				state.lastSize = 0;
			}).catch(function() {});
		});

		function applyFilter() {
			const f = state.filter;
			pane.querySelectorAll('.dd-line').forEach(function(el) {
				if (!f || el.textContent.toLowerCase().indexOf(f) !== -1)
					el.classList.remove('dd-hidden');
				else
					el.classList.add('dd-hidden');
			});
		}

		function appendLines(text) {
			const lines = text.split('\n');
			const frag = document.createDocumentFragment();
			for (let i = 0; i < lines.length; i++) {
				const ln = lines[i];
				if (!ln) continue;
				const el = buildLine(ln);
				if (state.filter && ln.toLowerCase().indexOf(state.filter) === -1)
					el.classList.add('dd-hidden');
				frag.appendChild(el);
			}
			// drop empty-state placeholder if present
			const empty = pane.querySelector('.dd-empty');
			if (empty) pane.removeChild(empty);
			pane.appendChild(frag);

			// cap rendered rows
			const overflow = pane.children.length - MAX_LINES;
			if (overflow > 0) {
				for (let i = 0; i < overflow; i++) pane.removeChild(pane.firstChild);
			}
		}

		function renderEmpty(msg) {
			while (pane.firstChild) pane.removeChild(pane.firstChild);
			pane.appendChild(E('div', { 'class': 'dd-empty' }, msg));
		}

		function tick() {
			if (state.paused) return Promise.resolve();

			return fs.stat(LOG_PATH).then(function(st) {
				const size = st.size || 0;
				if (size === state.lastSize) {
					meta.textContent = '%d bytes · live'.format(size);
					return;
				}

				// File rotated/truncated → full reload
				const rotated = size < state.lastSize;
				return fs.read_direct(LOG_PATH, 'text').then(function(content) {
					content = content || '';
					let delta;
					if (rotated || state.lastContent === '') {
						// full replace
						while (pane.firstChild) pane.removeChild(pane.firstChild);
						delta = content;
					} else if (content.indexOf(state.lastContent) === 0) {
						// pure append
						delta = content.slice(state.lastContent.length);
					} else {
						// content changed mid-stream → full replace
						while (pane.firstChild) pane.removeChild(pane.firstChild);
						delta = content;
					}

					if (delta) appendLines(delta);
					state.lastContent = content;
					state.lastSize = size;
					meta.textContent = '%d bytes · live'.format(size);

					if (state.autoScroll && !state.userScrolled)
						pane.scrollTop = pane.scrollHeight;
				});
			}).catch(function(e) {
				const msg = String(e);
				if (msg.indexOf('NotFoundError') !== -1 || msg.indexOf('No such') !== -1)
					renderEmpty(_('Log file does not exist yet.'));
				else
					renderEmpty(_('Error reading log: %s').format(msg));
				state.lastSize = -1;
				state.lastContent = '';
				meta.textContent = '';
			});
		}

		poll.add(tick);
		tick();

		const toolbar = E('div', { 'class': 'dd-log-toolbar' }, [
			E('label', {}, [ cbAuto, _('Auto-scroll') ]),
			E('label', {}, [ cbPause, _('Pause') ]),
			selFilter,
			btnClear,
			btnDownload,
			btnTruncate,
			meta
		]);

		return E('div', { 'class': 'dd-log-wrap' }, [
			E('style', {}, CSS),
			E('div', { 'class': 'dd-log-card' }, [
				E('h4', { 'class': 'dd-log-card-title' }, _('%s Realtime Log').format(ctx.name)),
				toolbar,
				pane
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
