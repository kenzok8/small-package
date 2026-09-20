'use strict';
'require view';
'require form';
'require ui';
'require honk.common as honk';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('honk', _('Routing Settings'), _('Configure routing rules for HONK.'));

		s = m.section(form.NamedSection, '_status');
		s.render = function() {
			return honk.renderStatusHeader();
		};

		s = m.section(form.TypedSection, 'honk');
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.TextValue, '_routeconf', _('Route Configuration'));
		o.rows = 25;
		o.wrap = 'off';
		o.load = function(section_id) {
			return honk.readFile('/etc/honk/config.d/route.dae');
		};
		o.write = function(section_id, formvalue) {
			return honk.writeFile('/etc/honk/config.d/route.dae', formvalue);
		};

		honk.bindCodeMirrorToMap(m);
		return m.render();
	},

	handleSaveApply: function(ev, mode) {
		return this.handleSave(ev).then(function() {
			return honk.callHonkReload();
		}).then(function() {
			ui.addNotification(null, E('p', _('Routing configuration saved and service reloaded.')), 'info');
		});
	}
});
