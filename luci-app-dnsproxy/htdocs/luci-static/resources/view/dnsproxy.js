'use strict';
'require form';
'require fs';
'require uci';
'require rpc';
'require poll';
'require view';
'require tools.widgets as widgets';

const conf = 'dnsproxy';
const instance = 'dnsproxy';

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

const callHostHints = rpc.declare({
	object: 'luci-rpc',
	method: 'getHostHints',
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList(conf), {})
		.then((res) => {
			let isrunning = false;
			try {
				isrunning = res[conf]['instances'][instance]['running'];
			} catch (e) { }
			return isrunning;
		});
}

return view.extend({

	load() {
	return Promise.all([
		getServiceStatus(),
		callHostHints(),
		uci.load('dnsproxy')
	]);
	},

	poll_status(nodes, stat) {
		const isRunning = stat[0];
		let view = nodes.querySelector('#service_status');

		if (isRunning) {
			view.innerHTML = "<span style=\"color:green;font-weight:bold\">" + instance + " - " + _("SERVER RUNNING") + "</span>";
		} else {
			view.innerHTML = "<span style=\"color:red;font-weight:bold\">" + instance + " - " + _("SERVER NOT RUNNING") + "</span>";
		}
		return;
	},

	render(res) {
		const isRunning = res[0];
		const hosts = res[1];

		let m, s, o, ss, so;

		m = new form.Map('dnsproxy', _('DNS Proxy'));

		s = m.section(form.NamedSection, '_status');
		s.render = function (section_id) {
			return E('div', { class: 'cbi-section' }, [
				E('div', { id: 'service_status' }, _('Collecting data ...'))
			]);
		};

		s = m.section(form.NamedSection, 'global', 'dnsproxy');

		s.tab('main', _('Main'));

		o = s.taboption('main', form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;

		o = s.taboption('main', form.Flag, 'verbose', _('Verbose'));

		o = s.taboption('main', form.Value, 'log_file', _('Log file path'));
		o.datatype = 'file';

		o = s.taboption('main', form.DynamicList, 'listen_addr', _('Listen address'));
		o.datatype = "list(ipaddr(1))";
		o.value('127.0.0.1');
		o.value('::1');

		let ipaddrs = {}, ip6addrs = {};
		for (let mac in hosts) {
			let addrs = L.toArray(hosts[mac].ipaddrs || hosts[mac].ipv4);
			let addrs6 = L.toArray(hosts[mac].ip6addrs || hosts[mac].ipv6);

			for (let i = 0; i < addrs.length; i++)
				ipaddrs[addrs[i]] = hosts[mac].name || mac;
			for (let i = 0; i < addrs6.length; i++)
				ip6addrs[addrs6[i]] = hosts[mac].name || mac;
		};
		L.sortedKeys(ipaddrs, null, 'addr').forEach((ipv4) => {
			o.value(ipv4, ipaddrs[ipv4] ? '%s (%s)'.format(ipv4, ipaddrs[ipv4]) : ipv4);
		});
		L.sortedKeys(ip6addrs, null, 'addr').forEach((ipv6) => {
			o.value(ipv6, ip6addrs[ipv6] ? '%s (%s)'.format(ipv6, ip6addrs[ipv6]) : ipv6);
		});

		o = s.taboption('main', form.DynamicList, 'listen_port', _('Listen ports'));
		o.datatype = "list(and(port, min(1)))";
		o.default = '5353';
		o.rmempty = false;

		o = s.taboption('main', form.Flag, 'ipv6_disabled', _('Disable IPv6'));

		o = s.taboption('main', form.Flag, 'refuse_any', _('Refuse <code>ANY</code> requests'));

		o = s.taboption('main', form.Flag, 'insecure', _('Disable secure TLS cert validation'));

		o = s.taboption('main', form.Flag, 'http3', _('DoH uses H3 first'));

		o = s.taboption('main', form.Value, 'timeout', _('Timeout for queries to remote upstream (default: 10s)'));
		o.datatype = 'string';

		o = s.taboption('main', form.Value, 'rate_limit', _('Ratelimit (requests per second)'));
		o.datatype = "and(uinteger, min(1))";

		o = s.taboption('main', form.Value, 'udp_buf_size', _('Size of the UDP buffer in bytes. Set 0 use the system default'));
		o.datatype = 'uinteger';

		o = s.taboption('main', form.Flag, 'all_servers', _('Parallel queries all upstream'));

		o = s.taboption('main', form.Flag, 'fastest_addr', _('Respond to A or AAAA requests only with the fastest IP address'));
		o.depends('all_servers', '1');

		s.tab('cache', _('Cache'));

		o = s.taboption('cache', form.SectionValue, '_cache', form.NamedSection, 'cache', 'homeproxy');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable Cache'));

		so = ss.option(form.Flag, 'cache_optimistic', _('Optimistic Cache'));
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.Value, 'size', _('Cache size (in bytes)'));
		so.datatype = "and(uinteger, min(512))";
		so.default = '65535';
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.Value, 'min_ttl', _('Min TTL value for DNS entries, in seconds'));
		so.datatype = "and(uinteger, range(1,3600))";
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.Value, 'max_ttl', _('Max TTL value for DNS entries, in seconds'));
		so.datatype = "and(uinteger, min(60))";
		so.retain = true;
		so.depends('enabled', '1');

		s.tab('dns64', _('DNS64'));

		o = s.taboption('dns64', form.SectionValue, '_dns64', form.NamedSection, 'dns64', 'homeproxy');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable DNS64'));

		so = ss.option(form.Value, 'dns64_prefix', _('DNS64 Prefix'));
		so.datatype = "ip6addr(1)";
		so.default = '64:ff9b::';
		so.retain = true;
		so.depends('enabled', '1');

		s.tab('edns', _('EDNS'));

		o = s.taboption('edns', form.SectionValue, '_edns', form.NamedSection, 'edns', 'homeproxy');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable EDNS'));

		so = ss.option(form.Value, 'edns_addr', _('EDNS Client Address'));
		so.datatype = "ipaddr(1)";
		so.retain = true;
		so.depends('enabled', '1');

		s.tab('bogus_nxdomain', _('Bogus-NXDOMAIN'));

		o = s.taboption('bogus_nxdomain', form.SectionValue, '_bogus_nxdomain', form.NamedSection, 'bogus_nxdomain', 'homeproxy');
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'ip_addr', _('Convert matching single IP responses to NXDOMAIN'));
		so.datatype = "list(ipaddr)";

		s.tab('servers', _('Upstreams'));

		o = s.taboption('servers', form.SectionValue, '_servers', form.NamedSection, 'servers', 'homeproxy');
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'bootstrap', _('Bootstrap DNS Server'));

		so = ss.option(form.DynamicList, 'upstream', _('Upstream DNS Server'));
		so.rmempty = false;

		so = ss.option(form.DynamicList, 'fallback', _('Fallback DNS Server'));

		return m.render()
		.then(L.bind(function(m, nodes) {
			poll.add(L.bind(function() {
				return Promise.all([
					getServiceStatus()
				]).then(L.bind(this.poll_status, this, nodes));
			}, this), 3);
			return nodes;
		}, this, m));
	}
});
