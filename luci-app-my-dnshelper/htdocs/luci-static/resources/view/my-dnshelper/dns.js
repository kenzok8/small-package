'use strict';
'require form';
'require view';
'require fs';
'require uci';

return view.extend({
	load: function(){
		return Promise.all([
			L.resolveDefault(fs.exec('/usr/share/my-dnshelper/waiter',['-d']),null),
			uci.load("dhcp")
		]);
	},

	render: function(stats){
		var m, s, o, v, csize;
		v = '';
		csize = uci.get("dhcp","@dnsmasq[0]","cachesize");
		csize = csize?csize:'150';

		if (stats[0] && stats[0].code == 0) {
			v = stats[0].stdout.trim();
		}

		m = new form.Map('my-dnshelper', _('Set your DNS'),
		_('You can set your dns service here. It supports DNS over HTTPS.')
		);

		s = m.section(form.TypedSection, 'my-dnshelper',  _('DNS Server'));
		s.anonymous = true;

		o = s.option(form.TextValue, 'dns_list',"",
		_('It supports Do53 as 10.1.1.1, and DoH as https://dns.xub')
		+'<br/><br/>'
		);
		o.rows = 10;
		o.wrap = "off";
		o.cfgvalue = function () {
			return fs.trimmed('/etc/my-dnshelper/dns.mdhp');
		};
		o.write = function (self, formvalue) {
			return fs.write('/etc/my-dnshelper/dns.mdhp', formvalue.trim().replace(/\r\n/g, '\n') + '\n');
		};

		s = m.section(form.TypedSection, 'my-dnshelper',  _('Bootstrap DNS'));
		s.anonymous = true;
		o = s.option(form.TextValue, 'bootstrap_list', "", _('It only supports dns 53. eg: 10.1.1.1. This is used by DoH.')+'<br/><br/>');
		o.rows = 10;
		o.wrap = "off";
		o.cfgvalue = function () {
			return fs.trimmed('/etc/my-dnshelper/bootstrap.mdhp');
		};
		o.write = function (self, formvalue) {
			return fs.write('/etc/my-dnshelper/bootstrap.mdhp', formvalue.trim().replace(/\r\n/g, '\n') + '\n');
		};

		s = m.section(form.TypedSection, 'my-dnshelper',  _('DNS Server Settings'));
		s.anonymous = true;

		o = s.option(form.Value, 'dns_cache', _('DNS Cache'));
		o.rmempty = true;
		o.description = '<b><span style=\"color:green\">' + _('DNS Cache Now:') + csize + '</span></b><br />';
		o.datatype = 'range(0,10000)';
		o.default = '600';

		o = s.option(form.Flag, "use_doh", _("Use DoH"), v);
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "force_doh", _("Force to DoH"));
		o.rmempty = false;
		o.default = 'false';
		o.depends("use_doh","1")

		o = s.option(form.Flag, "doh_http", _("Use HTTP/1.1 for DoH"), _("If your libcurl is not good or hang up frequently, it's will very useful for you."));
		o.rmempty = false;
		o.default = 'false';
		o.depends("use_doh","1")

		o = s.option(form.ListValue, "force_ip46", _("Force IPv4/6 for DoH"));
		o.rmempty = false;
		o.default = '1';
		o.depends("use_doh","1")
		o.value('0', _('None'));o.value('1', _('Force to IPv4'));o.value('2', _('Force to IPv6'));
		o.description = _("IPv4 best! It will make your network be easy to play. Default.")+"<br/>"+_("IPv6 first! But your ipv6 and dns address must to be ok.")

		o = s.option(form.Value, "doh_port", _("DoH port"));
		o.rmempty = false;
		o.depends("use_doh","1")
		o.datatype = 'range(1024,49151)'
		o.default = '5053';
		o.placeholder = '5053';
		o.description = _("Increase automatically from this number");

		o = s.option(form.Flag, "filter_aaaa", _("Filter AAAA"));
		o.rmempty = false;
		o.default = 'false';
		o.description = _("Do not resolve IPV6 addresses. Need dnsmasq 2.87");

		o = s.option(form.Flag, "use_mul", _("Multithreaded Query"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "use_strict", _("Query in order"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "use_sec", _("DNSSEC"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "dnsmasq_log", _("Open DNS Log"));
		o.description=_("Open this, you can let helper manage the dnsmasq log. It can separate logs from syslog.")
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Value, "dnslog_path", _("Set Patch of Dnsmasq Log"));
		o.rmempty = true;
		o.depends("dnsmasq_log","1")
		o.datatype = 'directory'
		o.default = '/var/log/dnsmasq.log';
		o.placeholder = '/var/log/dnsmasq.log';

		o = s.option(form.Flag, "dns_log", _("Open DNS Query Log"));
		o.depends("dnsmasq_log","1")
		o.rmempty = true;
		o.default = 'false';
		o.description=_("Close by default. Help youself. Warning, it is a large file.");

		o = s.option(form.Value, "dnslog_size", _("Size of Query Log(MB)"));
		o.rmempty = false;
		o.depends("dnsmasq_log","1")
		o.datatype = 'range(1,200)'
		o.default = '5';
		o.placeholder = '5';

		o = s.option(form.Flag, "rev_log", _("Reverse text"), _("Useful for page dns query log."));
		o.depends("dnsmasq_log","1")
		o.rmempty = false;
		o.default = 'true';

		return m.render();

	}

});
