'use strict';
'require form';
'require poll';
'require uci';
'require ui';
'require view';

'require fchomo as hm';
'require fchomo.listeners as lsnr'

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo')
		]);
	},

	render(data) {
		const dashboard_repo = uci.get(data[0], 'api', 'dashboard_repo');

		let m, s, o;

		m = new form.Map('fchomo', _('Mihomo server'),
			_('When used as a server, HomeProxy is a better choice.'));

		s = m.section(form.TypedSection);
		s.render = function () {
			poll.add(function() {
				return hm.getServiceStatus('mihomo-s').then((isRunning) => {
					hm.updateStatus(document.getElementById('_server_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-s', true);
				});
			});

			return E('div', { class: 'cbi-section' }, [
				E('p', [
					hm.renderStatus('_server_bar', false, 'mihomo-s', true)
				])
			]);
		}

		s = m.section(form.NamedSection, 'routing', 'fchomo', null);

		/* Server switch */
		o = s.option(form.Button, '_reload_server', _('Quick Reload'));
		o.inputtitle = _('Reload');
		o.inputstyle = 'apply';
		o.onclick = L.bind(hm.handleReload, o, 'mihomo-s');

		o = s.option(form.Flag, 'server_enabled', _('Enable'));
		o.default = o.disabled;

		/* Server settings START */
		s = m.section(hm.GridSection, 'server', null);
		s.addremove = true;
		s.rowcolors = true;
		s.sortable = true;
		s.nodescriptions = true;
		s.hm_modaltitle = [ _('Server'), _('Add a server') ];
		s.hm_prefmt = hm.glossary[s.sectiontype].prefmt;
		s.hm_field  = hm.glossary[s.sectiontype].field;
		s.hm_lowcase_only = false;

		lsnr.renderListeners(s, data[0], false);
		/* Server settings END */

		return m.render();
	}
});
