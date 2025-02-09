/* Thanks to homeproxy */
'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require rpc';
'require ui';
'require view';

/* Thanks to luci-app-aria2 */
const css = '				\
#log_textarea {				\
	padding: 10px;			\
	text-align: left;		\
}					\
#log_textarea pre {			\
	padding: .5rem;			\
	word-break: break-all;		\
	margin: 0;			\
}					\
.description {				\
	background-color: #33ccff;	\
}';

const hm_dir = '/var/run/fchomo';

function getRuntimeLog(name, filename) {
	const callLogClean = rpc.declare({
		object: 'luci.fchomo',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	let log_textarea = E('div', { 'id': 'log_textarea' },
		E('pre', {
			'class': 'spinning'
		}, _('Collecting data...'))
	);

	let log;
	poll.add(L.bind(function() {
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
	}));

	return E([
		E('style', [ css ]),
		E('div', {'class': 'cbi-map'}, [
			E('h3', {'name': 'content'}, [
				_('%s log').format(name),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(this, function() {
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
		so.render = L.bind(getRuntimeLog, so, _('FullCombo Shark!'), 'fchomo');
		/* FullCombo Shark! END */

		/* Mihomo client START */
		s.tab('mihomo_c', _('Mihomo client'));
		o = s.taboption('mihomo_c', form.SectionValue, '_mihomo_c', form.NamedSection, 'config', null);
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_mihomo-c_logview');
		so.render = L.bind(getRuntimeLog, so, _('Mihomo client'), 'mihomo-c');
		/* Mihomo client END */

		/* Mihomo server START */
		s.tab('mihomo_s', _('Mihomo server'));
		o = s.taboption('mihomo_s', form.SectionValue, '_mihomo_s', form.NamedSection, 'config', null);
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_mihomo-s_logview');
		so.render = L.bind(getRuntimeLog, so, _('Mihomo server'), 'mihomo-s');
		/* Mihomo server END */

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
