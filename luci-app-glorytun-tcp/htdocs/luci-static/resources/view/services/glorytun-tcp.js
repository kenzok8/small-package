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

		m = new form.Map('glorytun', _('Glorytun TCP'));

		s = m.section(form.GridSection, 'glorytun', _('Instances'));
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
		o.value('',_('Client'));
		o.value('listener',_('Server'));
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

		o = s.taboption('advanced', form.Flag, 'mptcp', _('MPTCP'));
		o.modalonly = true;

		o = s.taboption('advanced', form.Flag, 'chacha20', _('chacha'), _('Force fallback cipher'));
		o.modalonly = true;

		o = s.taboption('advanced', form.Value, 'timeout', _('Timeout'));
		o.default = '10000';
		o.rmempty = false;
		o.modalonly = true;

		o = s.taboption('advanced', form.Flag, 'multiqueue', _('Multiqueue'));
		o.rmempty = false;
		o.modalonly = true;

		return m.render();
	}
});
