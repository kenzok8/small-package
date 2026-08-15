'use strict';
'require form';
'require fs';
'require uci';
'require dom';
'require rpc';
'require poll';
'require ui';
'require view';
'require validation';
'require tools.widgets as widgets';

const conf = 'dnsproxy';
const instance = 'dnsproxy';
const profileListOptions = ['bootstrap', 'upstream', 'fallback'];
const upstream_mode = [
	['load_balance', _('Load balance'), _('one upstream per request.')],
	['parallel', _('Parallel'), _('first DNS response wins.')],
	['fastest_addr', _('Fastest address'), _('tests returned IP addresses.')]
];

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

function profileTitle(profile) {
	return profile.label || profile['.name'];
}

function applyProfile(select) {
	const profile = uci.sections(conf, 'profile').find((item) => item['.name'] === select.value);

	if (!profile)
		return ui.addNotification(null, E('p', _('The selected DNS profile no longer exists. Reload the page and try again.')), 'error');

	const upstreams = L.toArray(profile.upstream).filter(Boolean);
	if (!upstreams.length)
		return ui.addNotification(null, E('p', _('The selected DNS profile has no upstream servers.')), 'error');

	profileListOptions.forEach((option) => {
		const values = L.toArray(profile[option]).filter(Boolean);
		uci.set(conf, 'servers', option, values.length ? values : null);
	});

	if (profile.upstream_mode)
		uci.set(conf, 'global', 'upstream_mode', profile.upstream_mode);

	return uci.save()
		.then(L.bind(this.map.load, this.map))
		.then(L.bind(this.map.reset, this.map))
		.then(() => {
			ui.addNotification(null, E('p', _('DNS profile “%s” has been applied.').format(profileTitle(profile))), 'info');
		})
		.catch((err) => {
			ui.addNotification(null, E('p', _('Failed to apply DNS profile: %s').format(err.message || err)), 'error');
		});
}

function validateUniqueValue(section_id, value) {
	if (!value)
		return _('Expecting: %s').format(_('non-empty value'));

	let duplicate = false;
	uci.sections(this.config, this.section.sectiontype, (res) => {
		if (res['.name'] !== section_id)
			if (res[this.option] === value)
				duplicate = true;
	});
	if (duplicate)
		return _('Expecting: %s').format(_('unique value'));

	return true;
}

function validateServerValue(section_id, value) {
	if (!value)
		return true;

	if (!value.includes('://')) {
		let stubValidator = {
			factory: validation,
			apply(type, value, args) {
				if (value != null)
					this.value = value;

				return validation.types[type].apply(this, args);
			},
			assert(condition) {
				return !!condition;
			}
		};

		if (!stubValidator.apply('host', value) && !stubValidator.apply('hostport', value))
			return _('Expecting: %s').format(_('valid host or hostport'));

		return true;
	}

	try {
		const url = new URL(value);
		if (!url.hostname)
			return _('Expecting: %s').format(_('valid URL'));

		return true;
	}
	catch (e) {
		return _('Invalid URI');
	}
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

		o = s.taboption('main', form.Flag, 'http3', _('Enable HTTP/3 for DoH'));
		o.description = _('Use HTTP/3 when it is faster. HTTPS fallback remains available.');

		o = s.taboption('main', form.Value, 'timeout', _('Timeout for queries to remote upstream (default: 10s)'));
		o.datatype = 'string';

		o = s.taboption('main', form.Value, 'rate_limit', _('Ratelimit (requests per second)'));
		o.datatype = "and(uinteger, min(1))";

		o = s.taboption('main', form.Value, 'udp_buf_size', _('Size of the UDP buffer in bytes. Set 0 use the system default'));
		o.datatype = 'uinteger';

		o = s.taboption('main', form.RichListValue, 'upstream_mode', _('Upstream selection mode'),
			_('For the lowest DNS response time choose Parallel.') + '</br>' +
			_('Fastest address performs additional IP reachability tests and is a different, slower operation.'));
		upstream_mode.forEach((res) => {
			o.value.apply(o, res);
		})
		o.rmempty = false;

		s.tab('cache', _('Cache'));

		o = s.taboption('cache', form.SectionValue, '_cache', form.NamedSection, 'cache', 'dnsproxy');
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

		o = s.taboption('dns64', form.SectionValue, '_dns64', form.NamedSection, 'dns64', 'dnsproxy');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable DNS64'));

		so = ss.option(form.Value, 'dns64_prefix', _('DNS64 Prefix'));
		so.datatype = "ip6addr(1)";
		so.default = '64:ff9b::';
		so.retain = true;
		so.depends('enabled', '1');

		s.tab('edns', _('EDNS'));

		o = s.taboption('edns', form.SectionValue, '_edns', form.NamedSection, 'edns', 'dnsproxy');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable EDNS'));

		so = ss.option(form.Value, 'edns_addr', _('EDNS Client Address'));
		so.datatype = "ipaddr(1)";
		so.retain = true;
		so.depends('enabled', '1');

		s.tab('bogus_nxdomain', _('Bogus-NXDOMAIN'));

		o = s.taboption('bogus_nxdomain', form.SectionValue, '_bogus_nxdomain', form.NamedSection, 'bogus_nxdomain', 'dnsproxy');
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'ip_addr', _('Convert matching single IP responses to NXDOMAIN'));
		so.datatype = "list(ipaddr)";

		s.tab('servers', _('Upstreams'));

		o = s.taboption('servers', form.DummyValue, '_profile_switcher', _('DNS profiles'),
			_('A profile replaces Bootstrap, Upstream and Fallback lists together. Unsaved changes elsewhere on this page are not included.'));
		o.renderWidget = function () {
			const profiles = uci.sections(conf, 'profile');
			const select = E('select', {
				'id': 'dnsproxy-profile-select',
				'class': 'cbi-input-select',
				'disabled': profiles.length ? null : ''
			}, profiles.map((profile) => E('option', {
				'value': profile['.name']
			}, profileTitle(profile))));

			return E('div', {}, [
				E('div', { 'style': 'display:flex;gap:.75em;align-items:center;flex-wrap:wrap' }, [
					select,
					E('button', {
						'class': 'cbi-button cbi-button-positive important',
						'disabled': profiles.length ? null : '',
						'click': ui.createHandlerFn(this, applyProfile, select)
					}, _('Use selected profile'))
				]),
				profiles.length ? '' : E('p', {}, _('Create and save a profile in the “DNS profile templates” section below first.'))
			]);
		};

		o = s.taboption('servers', form.SectionValue, '_servers', form.NamedSection, 'servers', 'dnsproxy');
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'bootstrap', _('Bootstrap DNS Server'));
		so.readonly = true

		so = ss.option(form.DynamicList, 'upstream', _('Upstream DNS Server'));
		so.readonly = true
		so.rmempty = false;

		so = ss.option(form.DynamicList, 'fallback', _('Fallback DNS Server'));
		so.readonly = true

		o = s.taboption('servers', form.SectionValue, '_profiles', form.GridSection, 'profile', _('DNS profile templates'),
			_('Create reusable templates here. Applying a template does not modify the template itself.'));
		ss = o.subsection;
		ss.anonymous = true;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.addbtntitle = _('Add DNS profile');
		ss.renderRowActions = function(section_id, more_label, trEl) {
			trEl = form.GridSection.prototype.renderRowActions.apply(this, arguments);
			const preset_ids = [
				'default'
			];

			if (preset_ids.includes(section_id))
				trEl?.lastChild.querySelector('.cbi-button-remove')?.remove();

			return trEl;
		}

		so = ss.option(form.Value, 'label', _('Profile name'));
		so.rmempty = false;
		so.validate = validateUniqueValue;

		so = ss.option(form.RichListValue, 'upstream_mode', _('Upstream selection mode'));
		so.value(' ', _('Keep current mode'));
		upstream_mode.forEach((res) => {
			so.value.apply(so, res);
		})
		so.load = function(section_id) {
			let value = this.super('load', section_id);
			if (!value)
				return ' ';

			return value;
		}
		so.write = function(section_id, value) {
			if (!value.trim())
				return this.super('remove', section_id);

			return form.RichListValue.prototype.write.call(this, section_id, value);
		}
		so.textvalue = function(section_id) {
			let cval = this.cfgvalue(section_id);
			let i = this.keylist.indexOf(cval);
			let val = this.vallist[i];

			return dom.elem(val) ? val.firstChild.textContent : val ?? cval;
		}

		so = ss.option(form.DynamicList, 'bootstrap', _('Bootstrap DNS'));
		so.validate = validateServerValue;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'upstream', _('Upstream DNS'));
		so.rmempty = false;
		so.validate = validateServerValue;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'fallback', _('Fallback DNS'));
		so.validate = validateServerValue;
		so.modalonly = true;

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
