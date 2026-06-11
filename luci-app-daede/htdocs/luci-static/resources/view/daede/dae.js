// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';
'require form';
'require fs';
'require uci';
'require ui';
'require view.daede.backend as backend';

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
function renderDaeForms(ctx) {
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
		/* only real subscription links (http/https) are re-fetchable; fixed share
		   links (vless:// ss:// …) are static. Keep the button on every row for a
		   consistent layout, but grey it out (disabled) on the fixed ones. */
		const subUrl = uci.get('dae', section_id, 'url') || '';
		const fetchable = /^https?:\/\//i.test(subUrl);
		const btn = E('button', {
			'class': 'cbi-button cbi-button-action',
			'style': 'margin-right:.25em',
			'disabled': fetchable ? null : '',
			'title': fetchable ? '' : _('Fixed link — nothing to fetch.')
		}, _('Update'));
		const upMsg = E('span', { 'class': 'dd-meta', 'style': 'margin-left:8px;display:none' }, '');
		function setUpMsg(text, kind) {
			upMsg.textContent = text;
			upMsg.style.display = '';
			upMsg.style.color = (kind === 'err') ? 'var(--error-color, #d33)' : (kind === 'ok') ? 'var(--success-color, #2a8)' : '';
			if (kind !== 'err')
				setTimeout(function() { if (upMsg.textContent === text) upMsg.style.display = 'none'; }, 5000);
		}
		if (fetchable) {
			btn.addEventListener('click', function(ev) {
				ev.preventDefault();
				btn.disabled = true;
				setUpMsg(_('Updating…'));
				backend.detectRunning().then(function(r) {
					if (!r || !r.dae)
						return setUpMsg(_('dae is stopped; it fetches subscriptions on start.'), 'warn');
					return fs.exec(backend.BACKENDS.dae.initd, ['hot_reload']).then(function(res) {
						if (res && res.code !== 0)
							setUpMsg(_('Update failed: %s').format(res.stderr || res.stdout || ('exit ' + res.code)), 'err');
						else
							setUpMsg(_('Subscriptions updated (dae reloaded)'), 'ok');
					});
				}).catch(function(e) {
					setUpMsg(_('Update failed: %s').format(e.message || e), 'err');
				}).finally(function() { btn.disabled = false; });
			});
		}
		const firstBtn = cell.querySelector('button, a.cbi-button');
		if (firstBtn && firstBtn.parentNode) firstBtn.parentNode.insertBefore(btn, firstBtn);
		else cell.appendChild(btn);
		if (btn.parentNode) btn.parentNode.insertBefore(upMsg, btn.nextSibling);
		else cell.appendChild(upMsg);
		return cell;
	};

	/* Manual nodes (share links) */
	s = m.section(form.GridSection, 'node', _('Nodes'),
		_('One node share link per line — ss, vmess, vless, trojan, tuic, hysteria2, socks5.'));
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

	/* Subscription / manual-node tags for the group filter dropdowns */
	const subTags = (uci.sections('dae', 'subscription') || [])
		.map(function(x) { return x.tag; }).filter(function(x) { return !!x; });
	const nodeTags = (uci.sections('dae', 'node') || [])
		.map(function(x) { return x.tag; }).filter(function(x) { return !!x; });

	/* Groups (outbound) */
	s = m.section(form.TypedSection, 'group', _('Groups'),
		_('Outbound groups. Leave the source empty to use all nodes. Set the route fallback to one of these.'));
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
	o = s.option(form.DynamicList, 'source', _('Source'),
		_('Subscriptions and nodes that feed this group. Pick from the list or type a name. Leave empty to use all nodes.'));
	subTags.forEach(function(t) { o.value(t, t + ' (' + _('subscription') + ')'); });
	nodeTags.forEach(function(t) { o.value(t, t + ' (' + _('node') + ')'); });
	o = s.option(form.DynamicList, 'name_filter', _('Name filter'),
		_('Optional. Narrows subscriptions in the source to nodes whose name matches — e.g. 香港 or 新加坡|日本. Nodes you picked by name are always kept.'));
	o.placeholder = '新加坡|日本';

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
		_('Raw dae routing lines, evaluated before fallback. Target must be a group name above (or direct/block).'));
	o.placeholder = 'dip(geoip:jp) -> proxy';

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

	/* Logging — folded into the main form so the single Save button covers it
	   too (no separate native save bar) */
	s = m.section(form.NamedSection, 'config', 'dae', _('Logging'));
	s.addremove = false;
	o = s.option(form.Value, 'log_maxsize', _('Max Log Size (MB)'),
		_('Rotate the log file once it grows past this many megabytes.'));
	o.datatype = 'uinteger';
	o.default = '1';
	o = s.option(form.Value, 'log_maxbackups', _('Max Log Backups'),
		_('Number of rotated log files to keep.'));
	o.datatype = 'uinteger';
	o.default = '1';

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
			/* ensure the singleton sections exist before parsing the form —
			   on installs where uci-defaults never seeded them, writing an
			   option to a missing named section fails with ubus NOT_FOUND (4) */
			if (!uci.get('dae', 'routing')) uci.add('dae', 'routing', 'routing');
			if (!uci.get('dae', 'dns'))     uci.add('dae', 'dns', 'dns');
			if (!uci.get('dae', 'config'))  uci.add('dae', 'dae', 'config');
			/* commit dae UCI (apply flushes the rpc session to /etc/config,
			   which a CLI `uci commit` cannot see), then regenerate + hot reload */
			m.save(null, true)
				.then(function() { return uci.save(); })
				.then(function() {
					/* apply flushes the rpc session to /etc/config so the
					   generator (reads /etc/config/dae) sees the form data;
					   skip it when nothing changed — apply on an empty
					   changeset throws ubus NO_DATA (code 5). */
					return uci.changes().then(function(ch) {
						return (ch && Object.keys(ch).length) ? uci.apply() : null;
					});
				})
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

		const cardChildren = [
			E('h4', { 'class': 'dd-card-title' }, _('dae Configuration')),
			E('div', { 'class': 'dd-settings-descr' },
				_('Add a subscription or node, then save — it takes effect automatically.'))
		];
		cardChildren.push(mapNode);
		cardChildren.push(E('div', { 'class': 'dd-editor-actions' }, [ save, status ]));

		return E('div', { 'class': 'dd-card dd-settings-card' }, cardChildren);
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
	const save = E('button', { 'class': 'cbi-button cbi-button-positive' }, _('Save manual config'));
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
		titleEl.textContent = _('⚠ Still needs a subscription link: %d placeholder URL line(s) detected').format(hits.length);
		while (howtoEl.firstChild) howtoEl.removeChild(howtoEl.firstChild);
		/* assemble rich text from DOM nodes so the code spans keep their styling */
		howtoEl.appendChild(document.createTextNode(_('These ')));
		const c1 = document.createElement('code'); c1.textContent = 'example.com'; howtoEl.appendChild(c1);
		howtoEl.appendChild(document.createTextNode(' / '));
		const c2 = document.createElement('code'); c2.textContent = 'relative/path/to'; howtoEl.appendChild(c2);
		howtoEl.appendChild(document.createTextNode(_(' are placeholder addresses from dae\'s template, not real subscriptions. Replace the URL on any one line with your airport subscription link (delete the spare lines) and save.')));
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
		})()
	]);
}

return baseclass.extend({

	renderDaeForms: renderDaeForms,

	renderDaeImportBanner: renderDaeImportBanner,

	renderDaeEditor: renderDaeEditor

});
