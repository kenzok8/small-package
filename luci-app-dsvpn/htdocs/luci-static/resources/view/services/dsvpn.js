'use strict';
'require rpc';
'require form';
'require fs';
'require uci';
'require tools.widgets as widgets';

var callHostHints;

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

		m = new form.Map('dsvpn', _('DSVPN'));

		s = m.section(form.GridSection, 'dsvpn', _('Instances'));
		s.addremove = true;
		s.anonymous = true;
		s.nodescriptions = true;

		o = s.option(form.Flag, 'enable', _('Enabled'));
		o.default = o.enabled;

		o = s.option(form.Value, 'label', _('Label'));
		o.rmempty = true;

		o = s.option(form.ListValue, 'mode', _('Mode'));
		o.value('client',_('Client'));
		o.value('server',_('Server'));
		o.modalonly = true;

		o = s.option(form.Value, 'host', _('Host'));
		o.rmempty = false;

		o = s.option(form.Value, 'port', _('Port'));
		o.rmempty = false;

		o = s.option(form.Value, 'key', _('Key'));
		o.rmempty = false;
		o.modalonly = true;

		o = s.option(form.Value, 'dev', _('Interface name'));
		o.rmempty = false;
		o.modalonly = true;

		o = s.option(form.Value, 'localip', _('Local IP'));
		o.datatype = 'or(ip4addr,ip6addr)';
		o.rmempty = false;

		o = s.option(form.Value, 'remoteip', _('Remote IP'));
		o.datatype = 'or(ip4addr,ip6addr)';
		o.rmempty = false;

		return m.render();
	}
});
