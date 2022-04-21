'use strict';
'require uci';
'require form';
'require network';

network.registerPatternVirtual(/^netkeeper-.+$/);

function write_keepalive(section_id, value) {
	var f_opt = this.map.lookupOption('_keepalive_failure', section_id),
	    i_opt = this.map.lookupOption('_keepalive_interval', section_id),
	    f = (f_opt != null) ? +f_opt[0].formvalue(section_id) : null,
	    i = (i_opt != null) ? +i_opt[0].formvalue(section_id) : null;

	if (f == null || f == '' || isNaN(f))
		f = 0;

	if (i == null || i == '' || isNaN(i) || i < 1)
		i = 1;

	if (f > 0)
		uci.set('network', section_id, 'keepalive', '%d %d'.format(f, i));
	else
		uci.unset('network', section_id, 'keepalive');
}

return network.registerProtocol('netkeeper', {
	getI18n: function() {
		return _('Netkeeper');
	},

	getIfname: function() {
		return this._ubus('l3_device') || 'netkeeper-%s'.format(this.sid);
	},

	getOpkgPackage: function() {
		return 'netkeeper';
	},

	renderFormOptions: function(s) {
		var dev = this.getL3Device() || this.getDevice(), o;

		s.taboption('general', form.Value, 'username', _('PAP/CHAP username'));

		o = s.taboption('general', form.Value, 'password', _('PAP/CHAP password'));
		o.password = true;

		o = s.taboption('general', form.Value, 'ac', _('Access Concentrator'), _('Leave empty to autodetect'));
		o.placeholder = _('auto');

		o = s.taboption('general', form.Value, 'service', _('Service Name'), _('Leave empty to autodetect'));
		o.placeholder = _('auto');

		o = s.taboption('general', form.ListValue, 'pppd_options', _('Netkeeper plugin'), _('Choice Netkeeper plugin'));
		o.value('plugin chongqing0094_sxplugin.so', _('Netkeeper Chongqing 0094'));
		o.value('plugin chongqing_sxplugin.so', _('Netkeeper Chongqing'));
		o.value('plugin gansu_telecom_sxplugin.so', _('Netkeeper Gansu'));
		o.value('plugin hainan_sxplugin.so', _('Netkeeper Hainan'));
		o.value('plugin hebei_sxplugin.so', _('Netkeeper Hebei'));
		o.value('plugin hubei_sxplugin.so', _('Netkeeper Hubei'));
		o.value('plugin qinghai_sxplugin.so', _('Netkeeper Qinghai'));
		o.value('plugin shandongmobile_4_9_sxplugin.so', _('Netkeeper Shandong Mobile 4.9'));
		o.value('plugin shandongmobile_sxplugin.so', _('Netkeeper Shandong Mobile'));
		o.value('plugin shanxi_yixun_sxplugin.so', _('Yixun Shanxi'));
		o.value('plugin xinjiang_sxplugin.so', _('Netkeeper Xinjiang'));
		o.value('plugin zhejiang_qiye_sxplugin.so', _('Netkeeper Enterprise Zhejiang'));
		o.value('plugin zhejiang_xiaoyuan_sxplugin.so', _('Netkeeper School Zhejiang'));
		o.value('plugin netkeeper-interception-c.so', _('Netkeeper Interception'));
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'macaddr', _('MAC-Address'), _('If Leave empty, no default MAC-Address is configured'));
		o.rmempty     = true;
		o.datatype    = 'macaddr';
		o.placeholder = _('unspecified');

		if (L.hasSystemFeature('ipv6')) {
			o = s.taboption('advanced', form.ListValue, 'ipv6', _('Obtain IPv6-Address'), _('Enable IPv6 negotiation on the PPP link'));
			o.value('auto', _('Automatic'));
			o.value('0', _('Disabled'));
			o.value('1', _('Manual'));
			o.default = 'auto';
		}

		o = s.taboption('advanced', form.Flag, 'defaultroute', _('Use default gateway'), _('If unchecked, no default route is configured'));
		o.default = o.enabled;

		o = s.taboption('advanced', form.Flag, 'peerdns', _('Use DNS servers advertised by peer'), _('If unchecked, the advertised DNS server addresses are ignored'));
		o.default = o.enabled;

		o = s.taboption('advanced', form.DynamicList, 'dns', _('Use custom DNS servers'));
		o.depends('peerdns', '0');
		o.datatype = 'ipaddr';
		o.cast     = 'string';

		o = s.taboption('advanced', form.Value, 'metric', _('Use gateway metric'));
		o.placeholder = '0';
		o.datatype    = 'uinteger';

		o = s.taboption('advanced', form.Value, '_keepalive_failure', _('LCP echo failure threshold'), _('Presume peer to be dead after given amount of LCP echo failures, use 0 to ignore failures'));
		o.placeholder = '0';
		o.datatype    = 'uinteger';
		o.write       = write_keepalive;
		o.remove      = write_keepalive;
		o.cfgvalue = function(section_id) {
			var v = uci.get('network', section_id, 'keepalive');
			if (typeof(v) == 'string' && v != '') {
				var m = v.match(/^(\d+)[ ,]\d+$/);
				return m ? m[1] : v;
			}
		};

		o = s.taboption('advanced', form.Value, '_keepalive_interval', _('LCP echo interval'), _('Send LCP echo requests at the given interval in seconds, only effective in conjunction with failure threshold'));
		o.placeholder = '5';
		o.datatype    = 'min(1)';
		o.write       = write_keepalive;
		o.remove      = write_keepalive;
		o.cfgvalue = function(section_id) {
			var v = uci.get('network', section_id, 'keepalive');
			if (typeof(v) == 'string' && v != '') {
				var m = v.match(/^\d+[ ,](\d+)$/);
				return m ? m[1] : v;
			}
		};

		o = s.taboption('advanced', form.Value, 'host_uniq', _('Host-Uniq tag content'), _('Raw hex-encoded bytes. Leave empty unless your ISP require this'));
		o.placeholder = _('auto');
		o.datatype    = 'hexstring';

		o = s.taboption('advanced', form.Value, 'demand', _('Inactivity timeout'), _('Close inactive connection after the given amount of seconds, use 0 to persist connection'));
		o.placeholder = '0';
		o.datatype    = 'uinteger';

		o = s.taboption('advanced', form.Value, 'mtu', _('Override MTU'));
		o.placeholder = dev ? (dev.getMTU() || '1500') : '1500';
		o.datatype    = 'max(9200)';
	}
});'use strict';