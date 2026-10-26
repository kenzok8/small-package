/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2022-2025 ImmortalWrt.org
 */

'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

const hp_dir = '/var/run/homeproxy';

const connectionSites = [
	{ type: 'baidu', name: _('Baidu'), url: 'https://www.baidu.com/' },
	{ type: 'bilibili', name: _('Bilibili'), url: 'https://www.bilibili.com/' },
	{ type: 'jd', name: _('JD'), url: 'https://www.jd.com/' },
	{ type: 'google', name: _('Google'), url: 'https://www.google.com/' },
	{ type: 'github', name: _('GitHub'), url: 'https://github.com/' },
	{ type: 'youtube', name: _('YouTube'), url: 'https://www.youtube.com/' }
];

const connectionTestTimeout = 10000;

function getConnectionStatus() {
	const callConnStat = rpc.declare({
		object: 'luci.homeproxy',
		method: 'connection_check',
		params: ['site'],
		expect: { '': {} }
	});

	const table = E('table', { 'class': 'table' }, [
		E('tr', { 'class': 'tr table-titles' }, [
			E('th', { 'class': 'th' }, _('Website')),
			E('th', { 'class': 'th' }, _('URL')),
			E('th', { 'class': 'th' }, _('Connectivity')),
			E('th', { 'class': 'th' }, _('Latency'))
		])
	]);
	const statusElements = {};
	const rows = connectionSites.map((site) => {
		const state = E('strong', { 'style': 'color:gray' }, '-');
		const latency = E('span', {}, '-');
		statusElements[site.type] = { state, latency };

		return [
			site.name,
			E('a', {
				'href': site.url,
				'target': '_blank',
				'rel': 'noreferrer noopener',
				'style': 'word-break:break-all'
			}, site.url),
			state,
			latency
		];
	});
	cbi_update_table(table, rows);

	let running = false;
	let generation = 0;
	let testButton;

	const updateResult = (site, result) => {
		const elements = statusElements[site];
		if (!elements)
			return;

		if (result?.result) {
			elements.state.style.setProperty('color', 'green');
			dom.content(elements.state, _('Success'));
			dom.content(elements.latency, _('%s ms').format(result.latency_ms));
		} else {
			elements.state.style.setProperty('color', 'red');
			dom.content(elements.state, result?.timed_out ? _('Timed out') : _('Failed'));
			dom.content(elements.latency, '-');
		}
	};

	const runAllTests = () => {
		if (running)
			return Promise.resolve();

		running = true;
		testButton.disabled = true;
		const currentGeneration = ++generation;
		connectionSites.forEach((site) => {
			const elements = statusElements[site.type];
			elements.state.style.setProperty('color', 'gray');
			dom.content(elements.state, _('Testing...'));
			dom.content(elements.latency, '-');
		});

		return new Promise((resolve) => {
			let settled = false;
			const finish = (result) => {
				if (settled)
					return;

				settled = true;
				resolve(result);
			};
			const timer = window.setTimeout(() => finish({ timed_out: true }), connectionTestTimeout);

			L.resolveDefault(callConnStat('all'), { results: [] }).then((result) => {
				window.clearTimeout(timer);
				finish(result);
			});
		}).then((result) => {
			if (currentGeneration !== generation)
				return;

			const results = {};
			(result.results || []).forEach((siteResult) => {
				results[siteResult.site] = siteResult;
			});
			connectionSites.forEach((site) => {
				updateResult(site.type, results[site.type] || {
					result: false,
					timed_out: !!result.timed_out
				});
			});
		}).finally(() => {
			if (currentGeneration === generation) {
				running = false;
				testButton.disabled = false;
			}
		});
	};

	testButton = E('button', {
		'class': 'btn cbi-button cbi-button-action',
		'style': 'margin-left:4px',
		'click': ui.createHandlerFn(this, runAllTests)
	}, [ _('Test all') ]);

	const view = E('div', { 'class': 'cbi-map' }, [
		E('h3', { 'name': 'content', 'style': 'align-items:center;display:flex' }, [
			_('Connection Status'),
			testButton
		]),
		E('div', { 'class': 'cbi-section' }, [ table ])
	]);

	return view;
}

const resources = [
	{
		type: 'geoip_cn',
		name: _('China IP rule set')
	},
	{
		type: 'geosite_cn',
		name: _('China domain rule set')
	},
	{
		type: 'dashboard',
		name: _('Dashboard')
	}
];

function getResources(o) {
	const callResStatus = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_get',
		expect: { '': {} }
	});

	const callResUpdate = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_update',
		expect: { '': {} }
	});

	return L.resolveDefault(callResStatus(), { resources: [] }).then((result) => {
		const status = {};
		(result.resources || []).forEach((resource) => {
			status[resource.type] = resource;
		});
		const table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th' }, _('Name')),
				E('th', { 'class': 'th' }, _('Version')),
				E('th', { 'class': 'th' }, _('Source'))
			])
		]);
		const rows = resources.map((resource) => {
			const resourceStatus = status[resource.type] || {};
			const available = resourceStatus.version;
			const source = resourceStatus.source;

			return [
				resource.name,
				E('span', { 'style': available ? 'color:green' : 'color:red' },
					available || '-'),
				source ? E('a', {
					'href': source,
					'target': '_blank',
					'rel': 'noreferrer noopener',
					'style': 'word-break:break-all'
				}, source) : '-'
			];
		});
		cbi_update_table(table, rows);

		return E('div', { 'class': 'cbi-map' }, [
			E('h3', { 'name': 'content', 'style': 'align-items:center;display:flex' }, [
				_('Resource Management'),
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'style': 'margin-left:4px',
					'click': ui.createHandlerFn(this, () => {
						return L.resolveDefault(callResUpdate(), {}).then((res) => {
							let message, severity = 'info';

							if (res.apply_failed) {
								message = _('Resources were updated, but HomeProxy failed to reload. Check the log for details.');
								severity = 'error';
							} else {
								switch (res.status) {
								case 0:
									message = _('Successfully updated.');
									break;
								case 1:
									message = _('Update failed.');
									severity = 'error';
									break;
								case 2:
									message = _('Update already in progress.');
									break;
								case 3:
									message = _('Already at the latest version.');
									break;
								case 4:
									message = _('Some resources failed to update. Check the log for details.');
									severity = 'warning';
									break;
								default:
									message = _('Unknown error.');
									severity = 'error';
									break;
								}
							}

							ui.addNotification(null, E('p', message), severity);
							return o.map.reset();
						});
					})
				}, [ _('Update all') ])
			]),
			E('div', { 'class': 'cbi-section' }, [ table ])
		]);
	});
}

function getRuntimeLog(o, name, _option_index, section_id, _in_table) {
	const filename = o.option.split('_')[1];

	let section, log_level_el;
	switch (filename) {
	case 'homeproxy':
		section = null;
		break;
	case 'sing-box-c':
		section = 'config';
		break;
	case 'sing-box-s':
		section = 'server';
		break;
	}

	if (section) {
		const selected = uci.get('homeproxy', section, 'log_level') || 'warn';
		const choices = {
			trace: _('Trace'),
			debug: _('Debug'),
			info: _('Info'),
			warn: _('Warn'),
			error: _('Error'),
			fatal: _('Fatal'),
			panic: _('Panic')
		};

		log_level_el = E('select', {
			'id': o.cbid(section_id),
			'class': 'cbi-input-select',
			'style': 'margin-left: 4px; width: 6em;',
			'change': ui.createHandlerFn(this, (ev) => {
				uci.set('homeproxy', section, 'log_level', ev.target.value);
				return o.map.save(null, true).then(() => {
					ui.changes.apply(true);
				});
			})
		});

		Object.keys(choices).forEach((v) => {
			log_level_el.appendChild(E('option', {
				'value': v,
				'selected': (v === selected) ? '' : null
			}, [ choices[v] ]));
		});
	}

	const callLogClean = rpc.declare({
		object: 'luci.homeproxy',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	const log_textarea = E('textarea', {
		'id': filename + '-log',
		'class': 'cbi-input-textarea',
		'aria-label': _('%s Log').format(name),
		'readonly': true,
		'wrap': 'off',
		'spellcheck': 'false',
		'rows': 20,
		'style': 'width:100%; font-family:monospace; white-space:pre; overflow:auto;'
	}, [ _('Collecting data...') ]);

	function updateLog(content) {
		if (log_textarea.value === content)
			return;
		const focused = document.activeElement === log_textarea;
		const start = log_textarea.selectionStart, end = log_textarea.selectionEnd;
		const direction = log_textarea.selectionDirection;
		const top = log_textarea.scrollTop, left = log_textarea.scrollLeft;
		log_textarea.value = content;
		if (focused)
			log_textarea.setSelectionRange(start, end, direction);
		log_textarea.scrollTop = top;
		log_textarea.scrollLeft = left;
	}

	poll.add(L.bind(() => {
		return fs.read_direct(String.format('%s/%s.log', hp_dir, filename), 'text')
		.then((res) => {
			updateLog(res || _('Log is empty.'));
		}).catch((err) => {
			if (err.toString().includes('NotFoundError'))
				updateLog(_('Log file does not exist.'));
			else
				updateLog(_('Unknown error: %s.').format(err));
		});
	}));

	return E([
		E('div', {'class': 'cbi-map'}, [
			E('h3', {'name': 'content', 'style': 'align-items: center; display: flex;'}, [
				_('%s Log').format(name),
				log_level_el || '',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'style': 'margin-left: 4px;',
					'click': ui.createHandlerFn(this, () => {
						return L.resolveDefault(callLogClean(filename), {});
					})
				}, [ _('Clean log') ])
			]),
			E('div', {'class': 'cbi-section'}, [
				log_textarea,
				E('div', {'style': 'text-align:right'},
					E('small', {}, _('Refresh every %s seconds.').format(L.env.pollinterval))
				)
			])
		])
	]);
}

return view.extend({
	render() {
		let m, s, o;

		m = new form.Map('homeproxy');

		s = m.section(form.NamedSection, 'config', 'homeproxy');
		s.anonymous = true;

		o = s.option(form.DummyValue, '_connection_status');
		o.render = L.bind(getConnectionStatus, this);

		o = s.option(form.DummyValue, '_resources');
		o.render = L.bind(getResources, this, o);

		s = m.section(form.NamedSection, 'config', 'homeproxy');
		s.anonymous = true;

		o = s.option(form.DummyValue, '_homeproxy_logview');
		o.render = L.bind(getRuntimeLog, this, o, _('HomeProxy'));

		o = s.option(form.DummyValue, '_sing-box-c_logview');
		o.render = L.bind(getRuntimeLog, this, o, _('sing-box Client'));

		o = s.option(form.DummyValue, '_sing-box-s_logview');
		o.render = L.bind(getRuntimeLog, this, o, _('sing-box Server'));

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
