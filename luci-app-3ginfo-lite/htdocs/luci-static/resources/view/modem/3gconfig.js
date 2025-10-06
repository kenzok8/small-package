'use strict';
'require form';
'require fs';
'require view';
'require uci';
'require ui';
'require tools.widgets as widgets'

/*
	Copyright 2021-2023 Rafał Wabik - IceG - From eko.one.pl forum

	Licensed to the GNU General Public License v3.0.
*/

return view.extend({
	load: function() {
		return fs.list('/dev').then(function(devs) {
			return devs.filter(function(dev) {
				return dev.name.match(/^ttyUSB/) || dev.name.match(/^cdc-wdm/) || dev.name.match(/^ttyACM/) || dev.name.match(/^mhi_/);
			});
		});
	},

	render: function(devs) {
		var m, s, o;
		m = new form.Map('3ginfo', _('Configuration 3ginfo-lite'), _('Configuration panel for the 3ginfo-lite application.'));

		s = m.section(form.GridSection, '3ginfo');
		s.addremove = false;
		s.anonymous = false;
		s.nodescriptions = true;

		o = s.option(widgets.NetworkSelect, 'network', _('Network'),
			_('Network interface for Internet access.')
		);
		o.noaliases = false;
		o.default = 'wan';
		o.rmempty = false;

		o = s.option(form.Value, 'device',
			_('IP adress / Port for communication with the modem'),
			_("Select the appropriate settings. <br /> \
				<br />Traditional modem. <br /> \
				Select one of the available ttyUSBX ports.<br /> \
				<br />HiLink modem. <br /> \
				Enter the IP address 192.168.X.X under which the modem is available."));
		devs.sort((a, b) => a.name > b.name);
		devs.forEach(dev => o.value('/dev/' + dev.name));
		o.placeholder = _('Please select a port');
		o.rmempty = false

		return m.render();
	}
});
