'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require honk.common as honk';

return view.extend({
	load: function() {
		return uci.load('honk');
	},

	render: function() {
		var m, s, o;

		m = new form.Map('honk', _('Global Settings'), _('Configure global settings for HONK.'));

		s = m.section(form.NamedSection, '_status');
		s.render = function() {
			return honk.renderStatusHeader();
		};

		s = m.section(form.TypedSection, 'honk');
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enabled'));
		o.rmempty = false;

		o = s.option(form.Flag, 'advanced', _('Advanced Settings'), _('Enable to display full configuration editor and advanced routing/DNS/node tabs.'));
		o.rmempty = false;
		o.default = '0';

		o = s.option(form.ListValue, 'dashboard', _('Dashboard Type'), _('Select the active web dashboard.'));
		o.value('zashboard', 'Zashboard');
		o.value('doona', _('Doona'));
		o.default = 'doona';

		o = s.option(form.TextValue, '_config', _('Global Configuration'), _('Correctly configure the include field for separate-config to work, or enter complete configuration here.'));
		o.depends('advanced', '1');
		o.rows = 25;
		o.wrap = 'off';
		o.load = function(section_id) {
			return honk.readFile('/etc/honk/config.dae');
		};
		o.write = function(section_id, formvalue) {
			if (!this.isActive(section_id) || formvalue == null) return;
			return honk.writeFile('/etc/honk/config.dae', formvalue);
		};

		honk.bindCodeMirrorToMap(m);
		return m.render();
	},

	handleSaveApply: function(ev, mode) {
		var sections = uci.sections('honk', 'honk');
		var sid = (sections && sections[0]) ? sections[0]['.name'] : '@honk[0]';
		var oldDash = uci.get('honk', sid, 'dashboard') || 'doona';

		return this.handleSave(ev).then(function() {
			var newDash = uci.get('honk', sid, 'dashboard') || 'doona';
			var isAdv = uci.get('honk', sid, 'advanced') === '1';
			if (!isAdv && newDash !== oldDash) {
				return honk.callHonkSwitchDashboardApi(newDash);
			}
		}).then(function() {
			return ui.changes.apply(mode == '0');
		});
	}
});
