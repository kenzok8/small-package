'use strict';
'require view';
'require dom';
'require poll';
'require uci';
'require rpc';
'require form';

return view.extend({
	load: function() {
		return Promise.all([
			uci.changes(),
			uci.load('wireless'),
			uci.load('wizard')
		]);
	},

	render: function(data) {

		var m, s, o;
		var has_wifi = false;

		if (uci.sections('wireless', 'wifi-device').length > 0) {
			has_wifi = true;
		}

		m = new form.Map('wizard', [_('Inital Router Setup')],
			_('If you are using this router for the first time, please configure it here.'));

		s = m.section(form.NamedSection, 'default', 'wizard');
		s.addremove = false;
		s.tab('wansetup', _('Wan Settings'), _('Three different ways to access the Internet, please choose according to your own situation.'));
		if (has_wifi) {
			s.tab('wifisetup', _('Wireless Settings'), _('Set the router\'s wireless name and password. For more advanced settings, please go to the Network-Wireless page.'));
		}
		s.tab('lansetup', _('Lan Settings'));

		o = s.taboption('wansetup', form.ListValue, 'wan_proto', _('Protocol'));
		o.rmempty = false;
		o.value('dhcp', _('DHCP client'));
		o.value('static', _('Static address'));
		o.value('pppoe', _('PPPoE'));

		o = s.taboption('wansetup', form.Value, 'wan_pppoe_user', _('PAP/CHAP username'));
		o.depends('wan_proto', 'pppoe');

		o = s.taboption('wansetup', form.Value, 'wan_pppoe_pass', _('PAP/CHAP password'));
		o.depends('wan_proto', 'pppoe');
		o.password = true;

		o = s.taboption('wansetup', form.Value, 'wan_ipaddr', _('IPv4 address'));
		o.depends('wan_proto', 'static');
		o.datatype = 'ip4addr';

		o = s.taboption('wansetup', form.Value, 'wan_netmask', _('IPv4 netmask'));
		o.depends('wan_proto', 'static');
		o.datatype = 'ip4addr';
		o.value('255.255.255.0');
		o.value('255.255.0.0');
		o.value('255.0.0.0');

		o = s.taboption('wansetup', form.Value, 'wan_gateway', _('IPv4 gateway'));
		o.depends('wan_proto', 'static');
		o.datatype = 'ip4addr';

		o = s.taboption('wansetup', form.DynamicList, 'wan_dns', _('Use custom DNS servers'));
		o.depends('wan_proto', 'static');
		o.datatype = 'ip4addr';
		o.cast = 'string';

		if (has_wifi) {
			o = s.taboption('wifisetup', form.Value, 'wifi_ssid', _('<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>'));
			o.datatype = 'maxlength(32)';

			o = s.taboption("wifisetup", form.Value, "wifi_key", _("Key"));
			o.datatype = 'wpakey';
			o.password = true;
		}

		o = s.taboption('lansetup', form.Value, 'lan_ipaddr', _('IPv4 address'));
		o.datatype = 'ip4addr';

		o = s.taboption('lansetup', form.Value, 'lan_netmask', _('IPv4 netmask'));
		o.datatype = 'ip4addr';
		o.value('255.255.255.0');
		o.value('255.255.0.0');
		o.value('255.0.0.0');

		o = s.taboption('lansetup', form.DynamicList, 'lan_dns', _('Use custom DNS servers'), _('留空则使用运营商DNS, 推荐: 223.5.5.5'));
		o.datatype = 'ip4addr';
		o.cast = 'string';

		o = s.taboption('lansetup', form.Flag, 'siderouter', _('Siderouter'));
		
		o = s.taboption('lansetup', form.Value, 'lan_gateway', _('IPv4 gateway'));
		o.depends('siderouter', '1');
		o.datatype = 'ip4addr';
		o.placeholder = '请输入主路由IP';
		o.rmempty = false;
		
		o = s.taboption('lansetup', form.Flag, 'dhcp', _('DHCP Server'), _('开启此DHCP则需要关闭主路由的DHCP, 关闭此DHCP则需要手动将所有上网设备的网关和DNS改为此旁路由的IP'));
		o.depends('siderouter', '1');
		o.default = o.enabled;
		
		s.tab('firmware', _('Firmware Settings'));

		o = s.taboption('firmware', form.Flag, 'autoupgrade_pkg', _('Packages Auto Upgrade'));
		o.default = o.enabled;

		o = s.taboption('firmware', form.Flag, 'autoupgrade_fm', _('Firmware Upgrade Notice'));
		o.default = o.enabled;
		
		o = s.taboption('firmware', form.Flag, 'ipv6', _('Enable IPv6'), _('Enable/Disable IPv6'));
		o.default = o.enabled;

		return m.render();
	}
});
