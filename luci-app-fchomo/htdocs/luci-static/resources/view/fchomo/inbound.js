'use strict';
'require form';
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
		let m, s, o;

		m = new form.Map('fchomo', _('Edit inbound'));

		/* Inbound settings START */
		s = m.section(hm.GridSection, 'inbound', null);
		s.addremove = true;
		s.rowcolors = true;
		s.sortable = true;
		s.nodescriptions = true;
		s.hm_modaltitle = [ _('Inbound'), _('Add a inbound') ];
		s.hm_prefmt = hm.glossary[s.sectiontype].prefmt;
		s.hm_field  = hm.glossary[s.sectiontype].field;
		s.hm_lowcase_only = false;

		lsnr.renderListeners(s, data[0], true);
		/* Inbound settings END */

		return m.render();
	}
});
