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
var css = '				\
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

var hm_dir = '/var/run/fchomo';

function getRuntimeLog(name, filename) {
	var callLogClean = rpc.declare({
		object: 'luci.fchomo',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	var log_textarea = E('div', { 'id': 'log_textarea' },
		E('pre', {
			'class': 'spinning'
		}, _('Collecting data...'))
	);

	var log;
	poll.add(L.bind(function() {
		return fs.read_direct(String.format('%s/%s.log', hm_dir, filename), 'text')
		.then(function(res) {
			log = E('pre', { 'wrap': 'pre' }, [
				res.trim() || _('Log is empty.')
			]);

			dom.content(log_textarea, log);
		}).catch(function(err) {
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
	render: function(data) {
		var m, s, o;

		m = new form.Map('fchomo');

		s = m.section(form.NamedSection, 'config', 'fchomo');

		o = s.option(form.DummyValue, '_fchomo_logview');
		o.render = L.bind(getRuntimeLog, o, _('FullCombo Mihomo'), 'fchomo');

		o = s.option(form.DummyValue, '_mihomo-c_logview');
		o.render = L.bind(getRuntimeLog, o, _('Mihomo client'), 'mihomo-c');

		o = s.option(form.DummyValue, '_mihomo-s_logview');
		o.render = L.bind(getRuntimeLog, o, _('Mihomo server'), 'mihomo-s');

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
