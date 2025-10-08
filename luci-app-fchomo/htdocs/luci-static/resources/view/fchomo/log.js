/* Thanks to homeproxy */
'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

'require fchomo as hm';

document.querySelector('head').appendChild(E('style', [
	'\
	#log_textarea {\
		padding: 10px;\
		text-align: left;\
	}\
	#log_textarea pre {\
		padding: .5rem;\
		word-break: break-all;\
		margin: 0;\
	}\
	'
]));

const hm_dir = '/var/run/fchomo';

function getRuntimeLog(name, option_index, section_id, in_table) {
	const filename = this.option.split('_')[1];

	let section, option, log_level_el;
	switch (filename) {
		case 'fchomo':
			section = null;
			option = null;
			break;
		case 'mihomo-c':
			section = 'global';
			option = 'log_level';
			break;
		case 'mihomo-s':
			section = 'global';
			option = 'server_log_level';
			break;
	}

	if (section) {
		const selected = uci.get('fchomo', section, option) || 'warning';

		log_level_el = E('select', {
			'id': this.cbid(section_id),
			'class': 'cbi-input-select',
			'style': 'margin-left: 4px; width: 6em;',
			'change': ui.createHandlerFn(this, (ev) => {
				uci.set('fchomo', section, option, ev.target.value);
				return this.map.save(null, true).then(() => {
					ui.changes.apply(true);
				});
			})
		});

		hm.log_levels.forEach(([k, v]) => {
			log_level_el.appendChild(E('option', {
				'value': k,
				'selected': (k === selected) ? '' : null
			}, [ v ]));
		});
	}

	const callLogClean = rpc.declare({
		object: 'luci.fchomo',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	const log_textarea = E('div', { 'id': 'log_textarea' },
		E('pre', {
			'class': 'spinning'
		}, _('Collecting data...'))
	);

	let log;
	poll.add(function() {
		return fs.read_direct(String.format('%s/%s.log', hm_dir, filename), 'text')
		.then((res) => {
			log = E('pre', { 'wrap': 'pre' }, [
				res.trim() || _('Log is empty.')
			]);

			dom.content(log_textarea, log);
		}).catch((err) => {
			if (err.toString().includes('NotFoundError'))
				log = E('pre', { 'wrap': 'pre' }, [
					_('Log file does not exist.')
				]);
			else
				log = E('pre', { 'wrap': 'pre' }, [
					_('Unknown error: %s').format(err)
				]);

			dom.content(log_textarea, log);
		});
	});

	return E([
		E('div', {'class': 'cbi-map'}, [
			E('h3', {'name': 'content', 'style': 'align-items: center; display: flex;'}, [
				_('%s log').format(name),
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
	render(data) {
		let m, s, o, ss, so;

		m = new form.Map('fchomo');

		s = m.section(form.NamedSection, 'config', 'fchomo');

		/* FullCombo Shark! START */
		s.tab('fchomo', _('FullCombo Shark!'));
		o = s.taboption('fchomo', form.SectionValue, '_fchomo', form.NamedSection, 'config', null);
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_fchomo_logview');
		so.render = L.bind(getRuntimeLog, so, _('FullCombo Shark!'));
		/* FullCombo Shark! END */

		/* Mihomo client START */
		s.tab('mihomo_c', _('Mihomo client'));
		o = s.taboption('mihomo_c', form.SectionValue, '_mihomo_c', form.NamedSection, 'config', null);
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_mihomo-c_logview');
		so.render = L.bind(getRuntimeLog, so, _('Mihomo client'));
		/* Mihomo client END */

		/* Mihomo server START */
		s.tab('mihomo_s', _('Mihomo server'));
		o = s.taboption('mihomo_s', form.SectionValue, '_mihomo_s', form.NamedSection, 'config', null);
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_mihomo-s_logview');
		so.render = L.bind(getRuntimeLog, so, _('Mihomo server'));
		/* Mihomo server END */

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
