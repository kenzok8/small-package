'use strict';
'require view';
'require dom';
'require poll';
'require uci';
'require rpc';
'require form';
'require network';

return view.extend({
	load: function() {
		return Promise.all([
			uci.changes(),
			uci.load('fakemesh'),
			uci.load('fakemeshac')
		]);
	},

	render: function(data) {

		var m, s, o;

		m = new form.Map('fakemesh', [_('FakeMesh Settings')],
			_('Configure the FakeMesh overlay network.'));

		s = m.section(form.NamedSection, 'default', 'fakemesh');
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.enabled = '1';
		o.disabled = '0';
		o.default = o.disabled;

		o = s.option(form.Value, 'id', _('Mesh ID'));
		o.datatype = 'maxlength(32)';

		o = s.option(form.Value, 'key', _('Key'), _('Leave empty if encryption is not required.'));
		o.rmempty = true;
		o.password = true;
		o.datatype = 'wpakey';

		o = s.option(form.ListValue, 'band', _('Band'));
		o.value('5g', _('5G'));
		o.value('2g', _('2G'));
		o.default = '5g';

		o = s.option(form.ListValue, 'role', _('Role'), _('Use the gateway router as the controller and all other nodes as agents.'));
		o.value('wap', _('Wired AP (Ethernet backhaul)'));
		o.value('agent', _('Agent (Wi-Fi backhaul)'));
		o.value('controller', _('Controller (AC)'));
		o.default = 'agent';

		o = s.option(form.Value, 'access_ip', _('Controller Access IP'), _('IP address used to access the controller.'));
		o.depends('role', 'controller');
		o.placeholder = '10.10.10.1'
		o.rmempty = true;
		o.datatype = 'ip4addr';

		o = s.option(form.Flag, 'sync_ac', _('Sync Configuration'), _('Sync configuration from the controller.'));
		o.enabled = '1';
		o.disabled = '0';
		o.default = o.enabled;

		o = s.option(form.ListValue, 'band_steer_helper', _('Band Steering Helper'));
		o.value('none', _('None'));
		o.value('usteer', _('usteer'));
		o.value('dawn', _('DAWN'));
		o.default = 'none';

		o = s.option(form.Flag, 'fronthaul_disabled', _('Disable Fronthaul'), _('Disable this node\'s fronthaul Wi-Fi so other AP nodes cannot connect through it.'));
		o.enabled = '1';
		o.disabled = '0';
		o.default = o.disabled;

		var current_role = uci.get('fakemesh', 'default', 'role');

		s = m.section(form.GridSection, 'wifim', _('Wireless Management'), current_role != 'controller' ? _('Managed by the controller; read-only on AP nodes.') : '');
		s.addremove = true;
		s.anonymous = true;
		s.nodescriptions = true;
		s.sortable = false;
		if (current_role != 'controller') {
			s.addremove = false;
			s.uciconfig = 'fakemeshac';
			s.renderRowActions = function (section_id) {
				return E('td', { 'class': 'td middle cbi-section-actions' }, E('div', ''));
			};
		}

		o = s.option(form.Value, 'ssid', _('<abbr title="Extended Service Set Identifier">ESSID</abbr>'));
		o.datatype = 'maxlength(32)';
		o.rmempty = false;
		if (current_role != 'controller') o.readonly = true;

		o = s.option(form.ListValue, 'encryption', _('Encryption'));
		o.value('none', _('No Encryption'));
		o.value('psk', _('WPA-PSK'));
		o.value('psk2', _('WPA2-PSK'));
		o.value('psk-mixed', _('WPA-PSK/WPA2-PSK Mixed Mode'));
		o.value('sae', _('WPA3-SAE'));
		o.value('sae-mixed', _('WPA2-PSK/WPA3-SAE Mixed Mode'));
		if (current_role != 'controller') o.readonly = true;

		o = s.option(form.Value, 'key', _('Key'));
		o.depends('encryption', 'psk');
		o.depends('encryption', 'psk2');
		o.depends('encryption', 'psk-mixed');
		o.depends('encryption', 'sae');
		o.depends('encryption', 'sae-mixed');
		o.rmempty = false;
		o.password = true;
		o.datatype = 'wpakey';
		if (current_role != 'controller') o.readonly = true;

		o = s.option(form.ListValue, 'band', _('Band'));
		o.value('2g5g', _('2G+5G'));
		o.value('5g', _('5G'));
		o.value('2g', _('2G'));
		o.default = '2g5g';
		if (current_role != 'controller') o.readonly = true;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.enabled;
		if (current_role != 'controller') o.readonly = true;

		return m.render();
	}
});
