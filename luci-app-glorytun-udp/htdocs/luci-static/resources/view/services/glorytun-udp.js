'use strict';
'require rpc';
'require poll';
'require form';
'require fs';
'require uci';
'require tools.widgets as widgets';

var callHostHints;

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: [ 'name' ],
	expect: { '': {} }
});

return L.view.extend({
	callHostHints: rpc.declare({
		object: 'luci-rpc',
		method: 'getHostHints',
		expect: { '': {} }
	}),

	load: function() {
		return  this.callHostHints();
	},

	render: function(hosts) {
		var m, s, o;

		m = new form.Map('glorytun-udp', _('Glorytun UDP'));

		s = m.section(form.GridSection, 'glorytun-udp', _('Instances'));
		s.addremove = true;
		s.anonymous = true;
		s.nodescriptions = true;

		s.tab('general', _('General Settings'));
		s.tab('advanced', _('Advanced Settings'));

		o = s.taboption('general', form.Flag, 'enable', _('Enabled'));
		o.rmempty = false;

		o = s.taboption('general',form.Value, 'label', _('Label'));
		o.rmempty = true;

		o = s.taboption('general', form.ListValue, 'mode', _('Mode'));
		o.value('to',_('Client'));
		o.value('from',_('Server'));
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'host', _('Host'));
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'port', _('Port'));
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'key', _('Key'));
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'dev', _('Interface name'));
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'localip', _('Local IP'));
		o.datatype = 'or(ip4addr,ip6addr)';
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'remoteip', _('Remote IP'));
		o.datatype = 'or(ip4addr,ip6addr)';
		o.rmempty = false;

		o = s.taboption('advanced', form.Flag, 'persist', _('Persist'), _('Keep the tunnel device after exiting'));
		o.modalonly = true;

		o = s.taboption('advanced', form.Flag, 'chacha', _('chacha'), _('Force fallback cipher'));
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'kxtimeout', _('Key rotation timeout'));
		o.default = '7d';
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'timetolerance', _('Clock sync tolerance'));
		o.default = '10m';
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'keepalive', _('Keep alive timeout'));
		o.default = '25s';
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Flag, 'rateauto', _('Dynamic rate detection'));
		o.rmempty = false;
		o.modalonly = true;

		return m.render();
	}
});
