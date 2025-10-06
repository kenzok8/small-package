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

		m = new form.Map('mlvpn', _('MLVPN'));

		s = m.section(form.GridSection, 'mlvpn', _('Instances'));
		s.addremove = true;
		s.anonymous = true;
		s.nodescriptions = true;

		s.tab('general', _('General Settings'));
		s.tab('advanced', _('Advanced Settings'));

		o = s.taboption('general', form.Flag, 'enable', _('Enabled'));
		o.default = o.enabled;

		o = s.taboption('general',form.Value, 'label', _('Label'));
		o.rmempty = true;

		o = s.taboption('general', form.ListValue, 'mode', _('Mode'));
		o.value('client',_('Client'));
		o.value('server',_('Server'));
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'host', _('Host'));
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'firstport', _('First Port'));
		o.default  = "65201";
		o.datatype = "port";
		o.rmempty  = false;

		o = s.taboption('general', form.Value, 'password', _('Password'));
		o.rmempty   = false;
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'interface_name', _('Interface name'));
		o.default     = "mlvpn0";
		o.placeholder = "mlvpn0";
		o.rmempty     = false;
		o.modalonly   = true;

		o = s.taboption('advanced', form.Value, 'timeout', _('Timeout (s)'));
		o.default   = '30';
		o.datatype  = "uinteger";
		o.rmempty   = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'reorder_buffer_size', _('Reorder buffer size'));
		o.default   = '128';
		o.datatype  = "uinteger";
		o.rmempty   = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Flag, 'cleartext_data', _('Disable encryption'));
		o.default   = o.disabled;
		o.rmempty   = false;

		o = s.taboption('advanced', form.Value, 'loss_tolerance', _('Loss tolerance'));
		o.default   = '50';
		o.datatype  = "uinteger";
		o.rmempty   = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'latency_tolerance', _('Latency tolerance'));
		o.default   = '300';
		o.datatype  = "uinteger";
		o.rmempty   = false;
		o.modalonly = true;

		return m.render();
	}
});
