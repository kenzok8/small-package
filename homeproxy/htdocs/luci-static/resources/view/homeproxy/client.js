/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2022-2023 ImmortalWrt.org
 */

'use strict';
'require form';
'require network';
'require poll';
'require rpc';
'require uci';
'require validation';
'require view';

'require homeproxy as hp';
'require tools.widgets as widgets';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

var callReadDomainList = rpc.declare({
	object: 'luci.homeproxy',
	method: 'acllist_read',
	params: ['type'],
	expect: { '': {} }
});

var callWriteDomainList = rpc.declare({
	object: 'luci.homeproxy',
	method: 'acllist_write',
	params: ['type', 'content'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('homeproxy'), {}).then((res) => {
		var isRunning = false;
		try {
			isRunning = res['homeproxy']['instances']['sing-box']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		renderHTML = spanTemp.format('green', _('HomeProxy'), _('RUNNING'));
	} else {
		renderHTML = spanTemp.format('red', _('HomeProxy'), _('NOT RUNNING'));
	}

	return renderHTML;
}

function validatePortRange(section_id, value) {
	if (section_id && value) {
		value = value.match(/^(\d+)?\:(\d+)?$/);
		if (value && (value[1] || value[2])) {
			if (!value[1])
				value[1] = 0;
			else if (!value[2])
				value[2] = 65535;

			if (value[1] < value[2] && value[2] <= 65535)
				return true;
		}

		return _('Expecting: %s').format( _('valid port range (port1:port2)'));
	}

	return true;
}

var stubValidator = {
	factory: validation,
	apply: function(type, value, args) {
		if (value != null)
			this.value = value;

		return validation.types[type].apply(this, args);
	},
	assert: function(condition) {
		return !!condition;
	}
};

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('homeproxy'),
			hp.getBuiltinFeatures(),
			network.getHostHints()
		]);
	},

	render: function(data) {
		var m, s, o, ss, so;

		var features = data[1],
		    hosts = data[2]?.hosts;

		m = new form.Map('homeproxy', _('HomeProxy'),
			_('The modern ImmortalWrt proxy platform for ARM64/AMD64.'));

		s = m.section(form.TypedSection);
		s.render = function () {
			poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then((res) => {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		/* Cache all configured proxy nodes, they will be called multiple times */
		var proxy_nodes = {};
		uci.sections(data[0], 'node', (res) => {
			proxy_nodes[res['.name']] =
				String.format('[%s] %s', res.type, res.label || (stubValidator.apply('ip6addr', res.address || '') ?
					String.format('[%s]', res.address) : res.address) + ':' + res.port);
		});

		s = m.section(form.NamedSection, 'config', 'homeproxy');

		s.tab('routing', _('Routing Settings'));

		o = s.taboption('routing', form.ListValue, 'main_node', _('Main node'));
		o.value('nil', _('Disable'));
		for (var i in proxy_nodes)
			o.value(i, proxy_nodes[i]);
		o.default = 'nil';
		o.depends({'routing_mode': 'custom', '!reverse': true});
		o.rmempty = false;

		o = s.taboption('routing', form.ListValue, 'main_udp_node', _('Main UDP node'));
		o.value('nil', _('Disable'));
		o.value('same', _('Same as main node'));
		for (var i in proxy_nodes)
			o.value(i, proxy_nodes[i]);
		o.default = 'nil';
		o.depends({'routing_mode': /^((?!custom).)+$/, 'proxy_mode': /^((?!redirect$).)+$/});
		o.rmempty = false;

		o = s.taboption('routing', form.Value, 'dns_server', _('DNS server'),
			_('You can only have one server set. It MUST support TCP query.'));
		o.value('wan', _('Use DNS server from WAN'));
		o.value('1.1.1.1', _('CloudFlare Public DNS (1.1.1.1)'));
		o.value('208.67.222.222', _('Cisco Public DNS (208.67.222.222)'));
		o.value('8.8.8.8', _('Google Public DNS (8.8.8.8)'));
		o.value('', '---');
		o.value('223.5.5.5', _('Aliyun Public DNS (223.5.5.5)'));
		o.value('119.29.29.29', _('Tencent Public DNS (119.29.29.29)'));
		o.value('114.114.114.114', _('Xinfeng Public DNS (114.114.114.114)'));
		o.default = '208.67.222.222';
		o.rmempty = false;
		o.depends({'routing_mode': 'custom', '!reverse': true});
		o.validate = function(section_id, value) {
			if (section_id && !['local', 'wan'].includes(value)) {
				let ipv6_support = this.map.lookupOption('ipv6_support', section_id)[0].formvalue(section_id);

				if (!value)
					return _('Expecting: %s').format(_('non-empty value'));
				else if (!stubValidator.apply((ipv6_support === '1') ? 'ipaddr' : 'ip4addr', value))
					return _('Expecting: %s').format(_('valid IP address'));
			}

			return true;
		}

		o = s.taboption('routing', form.ListValue, 'routing_mode', _('Routing mode'));
		o.value('gfwlist', _('GFWList'));
		o.value('bypass_mainland_china', _('Bypass mainland China'));
		o.value('proxy_mainland_china', _('Only proxy mainland China'));
		o.value('custom', _('Custom routing'));
		o.value('global', _('Global'));
		o.default = 'bypass_mainland_china';
		o.rmempty = false;
		o.onchange = function(ev, section_id, value) {
			if (section_id && value === 'custom')
				this.map.save(null, true);
		}

		o = s.taboption('routing', form.Value, 'routing_port', _('Routing ports'),
			_('Specify target port(s) that get proxied. Multiple ports must be separated by commas.'));
		o.value('all', _('All ports'));
		o.value('common', _('Common ports only (bypass P2P traffic)'));
		o.default = 'common';
		o.rmempty = false;
		o.validate = function(section_id, value) {
			if (section_id && value !== 'all' && value !== 'common') {
				if (!value)
					return _('Expecting: %s').format(_('valid port value'));

				var ports = [];
				for (var i of value.split(',')) {
					if (!stubValidator.apply('port', i) && !stubValidator.apply('portrange', i))
						return _('Expecting: %s').format(_('valid port value'));
					if (ports.includes(i))
						return _('Port %s alrealy exists!').format(i);
					ports = ports.concat(i);
				}
			}

			return true;
		}

		o = s.taboption('routing', form.ListValue, 'proxy_mode', _('Proxy mode'));
		o.value('redirect', _('Redirect TCP'));
		o.value('redirect_tproxy', _('Redirect TCP + TProxy UDP'));
		if (features.hp_has_tun) {
			o.value('redirect_tun', _('Redirect TCP + Tun UDP'));
			o.value('tun', _('Tun TCP/UDP'));
		}
		o.default = 'redirect_tproxy';
		o.rmempty = false;

		o = s.taboption('routing', form.Flag, 'ipv6_support', _('IPv6 support'));
		o.default = o.enabled;
		o.rmempty = false;

		/* Custom routing settings start */
		/* Routing settings start */
		o = s.taboption('routing', form.SectionValue, '_routing', form.NamedSection, 'routing', 'homeproxy');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		so = ss.option(form.ListValue, 'tcpip_stack', _('TCP/IP stack'),
			_('TCP/IP stack.'));
		if (features.with_gvisor)
			so.value('gvisor', _('gVisor'));
		if (features.with_lwip)
			so.value('lwip', _('LWIP'));
		so.value('system', _('System'));
		so.default = 'system';
		so.depends('homeproxy.config.proxy_mode', 'redirect_tun');
		so.depends('homeproxy.config.proxy_mode', 'tun');
		so.rmempty = false;
		so.onchange = function(ev, section_id, value) {
			var desc = ev.target.nextElementSibling;
			if (value === 'gvisor')
				desc.innerHTML = _('Based on google/gvisor (recommended).');
			else if (value === 'lwip')
				desc.innerHTML = _('Upstream archived. Not recommended.');
			else if (value === 'system')
				desc.innerHTML = _('Less compatibility and sometimes better performance.');
		}

		so = ss.option(form.Flag, 'endpoint_independent_nat', _('Enable endpoint-independent NAT'),
			_('Performance may degrade slightly, so it is not recommended to enable on when it is not needed.'));
		so.default = so.enabled;
		so.depends('tcpip_stack', 'gvisor');
		so.rmempty = false;

		so = ss.option(form.Flag, 'bypass_cn_traffic', _('Bypass CN traffic'),
			_('Bypass mainland China traffic via firewall rules by default.'));
		so.default = so.disabled;
		so.rmempty = false;

		so = ss.option(form.Flag, 'sniff_override', _('Override destination'),
			_('Override the connection destination address with the sniffed domain.'));
		so.default = so.enabled;
		so.rmempty = false;

		so = ss.option(form.ListValue, 'default_outbound', _('Default outbound'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('nil', _('Disable'));
			this.value('direct-out', _('Direct'));
			this.value('block-out', _('Block'));
			uci.sections(data[0], 'routing_node', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.default = 'nil';
		so.rmempty = false;
		/* Routing settings end */

		/* Routing nodes start */
		s.tab('routing_node', _('Routing Nodes'));
		o = s.taboption('routing_node', form.SectionValue, '_routing_node', form.GridSection, 'routing_node');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hp.loadModalTitle, this, _('Routing node'), _('Add a routing node'), data[0]);
		ss.sectiontitle = L.bind(hp.loadDefaultLabel, this, data[0]);
		ss.renderSectionAdd = L.bind(hp.renderSectionAdd, this, ss);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hp.loadDefaultLabel, this, data[0]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'routing_node', 'label');
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.rmempty = false;
		so.editable = true;

		so = ss.option(form.ListValue, 'node', _('Node'),
			_('Outbound node'));
		for (var i in proxy_nodes)
			so.value(i, proxy_nodes[i]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'routing_node', 'node');
		so.editable = true;

		so = ss.option(form.ListValue, 'domain_strategy', _('Domain strategy'),
			_('If set, the server domain name will be resolved to IP before connecting.<br/>dns.strategy will be used if empty.'));
		for (var i in hp.dns_strategy)
			so.value(i, hp.dns_strategy[i]);
		so.modalonly = true;

		so = ss.option(widgets.DeviceSelect, 'bind_interface', _('Bind interface'),
			_('The network interface to bind to.'));
		so.multiple = false;
		so.noaliases = true;
		so.depends('outbound', '');
		so.modalonly = true;

		so = ss.option(form.ListValue, 'outbound', _('Outbound'),
			_('The tag of the upstream outbound.<br/>Other dial fields will be ignored when enabled.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('', _('Direct'));
			uci.sections(data[0], 'routing_node', (res) => {
				if (res['.name'] !== section_id && res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.validate = function(section_id, value) {
			if (section_id && value) {
				var node = this.map.lookupOption('node', section_id)[0].formvalue(section_id);

				var conflict = false;
				uci.sections(data[0], 'routing_node', (res) => {
					if (res['.name'] !== section_id)
						if (res.outbound === section_id && res['.name'] == value)
							conflict = true;
				});
				if (conflict)
					return _('Recursive outbound detected!');
			}

			return true;
		}
		/* Routing nodes end */

		/* Routing rules start */
		s.tab('routing_rule', _('Routing Rules'));
		o = s.taboption('routing_rule', form.SectionValue, '_routing_rule', form.GridSection, 'routing_rule');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hp.loadModalTitle, this, _('Routing rule'), _('Add a routing rule'), data[0]);
		ss.sectiontitle = L.bind(hp.loadDefaultLabel, this, data[0]);
		ss.renderSectionAdd = L.bind(hp.renderSectionAdd, this, ss);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hp.loadDefaultLabel, this, data[0]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'routing_rule', 'label');
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.rmempty = false;
		so.editable = true;

		so = ss.option(form.ListValue, 'ip_version', _('IP version'),
			_('4 or 6. Not limited if empty.'));
		so.value('4', _('IPv4'));
		so.value('6', _('IPv6'));
		so.value('', _('Both'));
		so.modalonly = true;

		so = ss.option(form.ListValue, 'mode', _('Mode'),
			_('The default rule uses the following matching logic:<br/>' +
			'<code>(domain || domain_suffix || domain_keyword || domain_regex || geosite || geoip || ip_cidr)</code> &&<br/>' +
			'<code>(source_geoip || source_ip_cidr)</code> &&<br/>' +
			'<code>other fields</code>.'));
		so.value('default', _('Default'));
		so.default = 'default';
		so.rmempty = false;
		so.readonly = true;

		so = ss.option(form.Flag, 'invert', _('Invert'),
			_('Invert match result.'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'network', _('Network'));
		so.value('tcp', _('TCP'));
		so.value('udp', _('UDP'));
		so.value('', _('Both'));

		so = ss.option(form.MultiValue, 'protocol', _('Protocol'),
			_('Sniffed protocol, see <a target="_blank" href="https://sing-box.sagernet.org/configuration/route/sniff/">Sniff</a> for details.'));
		so.value('http', _('HTTP'));
		so.value('tls', _('TLS'));
		so.value('quic', _('QUIC'));
		so.value('stun', _('STUN'));

		so = ss.option(form.DynamicList, 'domain', _('Domain name'),
			_('Match full domain.'));
		so.datatype = 'hostname';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_suffix', _('Domain suffix'),
			_('Match domain suffix.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_keyword', _('Domain keyword'),
			_('Match domain using keyword.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_regex', _('Domain regex'),
			_('Match domain using regular expression.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'geosite', _('Geosite'),
			_('Match geosite.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_geoip', _('Source GeoIP'),
			_('Match source GeoIP.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'geoip', _('GeoIP'),
			_('Match GeoIP.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_ip_cidr', _('Source IP CIDR'),
			_('Match source IP CIDR.'));
		so.datatype = 'or(cidr, ipaddr)';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'ip_cidr', _('IP CIDR'),
			_('Match IP CIDR.'));
		so.datatype = 'or(cidr, ipaddr)';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_port', _('Source port'),
			_('Match source port.'));
		so.datatype = 'port';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_port_range', _('Source port range'),
			_('Match source port range. Format as START:/:END/START:END.'));
		so.validate = validatePortRange;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'port', _('Port'),
			_('Match port.'));
		so.datatype = 'port';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'port_range', _('Port range'),
			_('Match port range. Format as START:/:END/START:END.'));
		so.validate = validatePortRange;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'process_name', _('Process name'),
			_('Match process name.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'process_path', _('Process path'),
			_('Match process path.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'user', _('User'),
			_('Match user name.'));
		so.modalonly = true;

		so = ss.option(form.ListValue, 'outbound', _('Outbound'),
			_('Tag of the target outbound.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('direct-out', _('Direct'));
			this.value('block-out', _('Block'));
			uci.sections(data[0], 'routing_node', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.rmempty = false;
		so.editable = true;
		/* Routing rules end */

		/* DNS settings start */
		s.tab('dns', _('DNS Settings'));
		o = s.taboption('dns', form.SectionValue, '_dns', form.NamedSection, 'dns', 'homeproxy');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		so = ss.option(form.ListValue, 'default_strategy', _('Default DNS strategy'),
			_('The DNS strategy for resolving the domain name in the address.'));
		for (var i in hp.dns_strategy)
			so.value(i, hp.dns_strategy[i]);

		so = ss.option(form.ListValue, 'default_server', _('Default DNS server'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('default-dns', _('Default DNS (issued by WAN)'));
			this.value('block-dns', _('Block DNS queries'));
			uci.sections(data[0], 'dns_server', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.default = 'default-dns';
		so.rmempty = false;

		so = ss.option(form.Flag, 'disable_cache', _('Disable DNS cache'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'disable_cache_expire', _('Disable cache expire'));
		so.default = so.disabled;
		so.depends('disable_cache', '0');
		/* DNS settings end */

		/* DNS servers start */
		s.tab('dns_server', _('DNS Servers'));
		o = s.taboption('dns_server', form.SectionValue, '_dns_server', form.GridSection, 'dns_server');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hp.loadModalTitle, this, _('DNS server'), _('Add a DNS server'), data[0]);
		ss.sectiontitle = L.bind(hp.loadDefaultLabel, this, data[0]);
		ss.renderSectionAdd = L.bind(hp.renderSectionAdd, this, ss);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hp.loadDefaultLabel, this, data[0]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'dns_server', 'label');
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.rmempty = false;
		so.editable = true;

		so = ss.option(form.Value, 'address', _('Address'),
			_('The address of the dns server. Support UDP, TCP, DoT, DoH and RCode.'));
		so.rmempty = false;

		so = ss.option(form.ListValue, 'address_resolver', _('Address resolver'),
			_('Tag of a another server to resolve the domain name in the address. Required if address contains domain.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('', _('None'));
			this.value('default-dns', _('Default DNS (issued by WAN)'));
			uci.sections(data[0], 'dns_server', (res) => {
				if (res['.name'] !== section_id && res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.validate = function(section_id, value) {
			if (section_id && value) {
				var conflict = false;
				uci.sections(data[0], 'dns_server', (res) => {
					if (res['.name'] !== section_id)
						if (res.address_resolver === section_id && res['.name'] == value)
							conflict = true;
				});
				if (conflict)
					return _('Recursive resolver detected!');
			}

			return true;
		}
		so.modalonly = true;

		so = ss.option(form.ListValue, 'address_strategy', _('Address strategy'),
			_('The domain strategy for resolving the domain name in the address. dns.strategy will be used if empty.'));
		for (var i in hp.dns_strategy)
			so.value(i, hp.dns_strategy[i]);
		so.modalonly = true;

		so = ss.option(form.ListValue, 'resolve_strategy', _('Resolve strategy'),
			_('Default domain strategy for resolving the domain names.'));
		for (var i in hp.dns_strategy)
			so.value(i, hp.dns_strategy[i]);

		so = ss.option(form.ListValue, 'outbound', _('Outbound'),
			_('Tag of an outbound for connecting to the dns server.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('direct-out', _('Direct'));
			uci.sections(data[0], 'routing_node', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.default = 'direct-out';
		so.rmempty = false;
		so.editable = true;
		/* DNS servers end */

		/* DNS rules start */
		s.tab('dns_rule', _('DNS Rules'));
		o = s.taboption('dns_rule', form.SectionValue, '_dns_rule', form.GridSection, 'dns_rule');
		o.depends('routing_mode', 'custom');

		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hp.loadModalTitle, this, _('DNS rule'), _('Add a DNS rule'), data[0]);
		ss.sectiontitle = L.bind(hp.loadDefaultLabel, this, data[0]);
		ss.renderSectionAdd = L.bind(hp.renderSectionAdd, this, ss);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hp.loadDefaultLabel, this, data[0]);
		so.validate = L.bind(hp.validateUniqueValue, this, data[0], 'dns_rule', 'label');
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.rmempty = false;
		so.editable = true;

		so = ss.option(form.ListValue, 'mode', _('Mode'),
			_('The default rule uses the following matching logic:<br/>' +
			'<code>(domain || domain_suffix || domain_keyword || domain_regex || geosite || ip_cidr)</code> &&<br/>' +
			'<code>(source_geoip || source_ip_cidr)</code> &&<br/>' +
			'<code>other fields</code>.'));
		so.value('default', _('Default'));
		so.default = 'default';
		so.rmempty = false;
		so.readonly = true;

		so = ss.option(form.Flag, 'invert', _('Invert'),
			_('Invert match result.'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.option(form.ListValue, 'network', _('Network'));
		so.value('tcp', _('TCP'));
		so.value('udp', _('UDP'));
		so.value('', _('Both'));

		so = ss.option(form.MultiValue, 'protocol', _('Protocol'),
			_('Sniffed protocol, see <a target="_blank" href="https://sing-box.sagernet.org/configuration/route/sniff/">Sniff</a> for details.'));
		so.value('http', _('HTTP'));
		so.value('tls', _('TLS'));
		so.value('quic', _('QUIC'));
		so.value('dns', _('DNS'));
		so.value('stun', _('STUN'));

		so = ss.option(form.DynamicList, 'domain', _('Domain name'),
			_('Match full domain.'));
		so.datatype = 'hostname';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_suffix', _('Domain suffix'),
			_('Match domain suffix.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_keyword', _('Domain keyword'),
			_('Match domain using keyword.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'domain_regex', _('Domain regex'),
			_('Match domain using regular expression.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'geosite', _('Geosite'),
			_('Match geosite.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_geoip', _('Source GeoIP'),
			_('Match source GeoIP.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_ip_cidr', _('Source IP CIDR'),
			_('Match source IP CIDR.'));
		so.datatype = 'or(cidr, ipaddr)';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'ip_cidr', _('IP CIDR'),
			_('Match IP CIDR.'));
		so.datatype = 'or(cidr, ipaddr)';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_port', _('Source port'),
			_('Match source port.'));
		so.datatype = 'port';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'source_port_range', _('Source port range'),
			_('Match source port range. Format as START:/:END/START:END.'));
		so.validate = validatePortRange;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'port', _('Port'),
			_('Match port.'));
		so.datatype = 'port';
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'port_range', _('Port range'),
			_('Match port range. Format as START:/:END/START:END.'));
		so.validate = validatePortRange;
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'process_name', _('Process name'),
			_('Match process name.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'process_path', _('Process path'),
			_('Match process path.'));
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'user', _('User'),
			_('Match user name.'));
		so.modalonly = true;

		so = ss.option(form.MultiValue, 'outbound', _('Outbound'),
			_('Match outbound.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('direct-out', _('Direct'));
			this.value('block-out', _('Block'));
			uci.sections(data[0], 'routing_node', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.modalonly = true;

		so = ss.option(form.ListValue, 'server', _('Server'),
			_('Tag of the target dns server.'));
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('default-dns', _('Default DNS (issued by WAN)'));
			this.value('block-dns', _('Block DNS queries'));
			uci.sections(data[0], 'dns_server', (res) => {
				if (res.enabled === '1')
					this.value(res['.name'], res.label);
			});

			return this.super('load', section_id);
		}
		so.rmempty = false;
		so.editable = true;

		so = ss.option(form.Flag, 'dns_disable_cache', _('Disable dns cache'),
			_('Disable cache and save cache in this query.'));
		so.default = so.disabled;
		so.modalonly = true;
		/* DNS rules end */
		/* Custom routing settings end */

		/* ACL settings start */
		s.tab('control', _('Access Control'));

		o = s.taboption('control', form.SectionValue, '_control', form.NamedSection, 'control', 'homeproxy');
		ss = o.subsection;

		/* Interface control start */
		ss.tab('interface', _('Interface Control'));

		so = ss.taboption('interface', widgets.DeviceSelect, 'listen_interfaces', _('Listen interfaces'),
			_('Only process traffic from specific interfaces. Leave empty for all.'));
		so.multiple = true;
		so.noaliases = true;

		so = ss.taboption('interface', widgets.DeviceSelect, 'bind_interface', _('Bind interface'),
			_('Bind outbound traffic to specific interface. Leave empty to auto detect.'));
		so.multiple = false;
		so.noaliases = true;
		/* Interface control end */

		/* LAN IP policy start */
		ss.tab('lan_ip_policy', _('LAN IP Policy'));

		var ipaddrs = {}, ip6addrs = {};
		Object.keys(hosts).forEach(function(mac) {
			var addrs = L.toArray(hosts[mac].ipaddrs || hosts[mac].ipv4);

			for (var i = 0; i < addrs.length; i++)
				ipaddrs[addrs[i]] = hosts[mac].name || mac;
		});
		Object.keys(hosts).forEach(function(mac) {
			var addrs = L.toArray(hosts[mac].ip6addrs || hosts[mac].ipv6);

			for (var i = 0; i < addrs.length; i++)
				ip6addrs[addrs[i]] = hosts[mac].name || mac;
		});

		so = ss.taboption('lan_ip_policy', form.ListValue, 'lan_proxy_mode', _('Proxy filter mode'));
		so.value('disabled', _('Disable'));
		so.value('listed_only', _('Proxy listed only'));
		so.value('except_listed', _('Proxy all except listed'));
		so.default = 'disabled';
		so.rmempty = false;

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_direct_ipv4_ips', _('Direct IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';
		so.depends('lan_proxy_mode', 'except_listed');
		L.sortedKeys(ipaddrs, null, 'addr').forEach(function(ipv4) {
			so.value(ipv4, '%s (%s)'.format(ipv4, ipaddrs[ipv4]));
		});

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_direct_ipv6_ips', _('Direct IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.depends('lan_proxy_mode', 'except_listed');
		L.sortedKeys(ip6addrs, null, 'addr').forEach(function(ipv6) {
			so.value(ipv6, '%s (%s)'.format(ipv6, ip6addrs[ipv6]));
		});
		so.depends('homeproxy.config.ipv6_support', '1');

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_proxy_ipv4_ips', _('Proxy IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';
		so.depends('lan_proxy_mode', 'listed_only');
		L.sortedKeys(ipaddrs, null, 'addr').forEach(function(ipv4) {
			so.value(ipv4, '%s (%s)'.format(ipv4, ipaddrs[ipv4]));
		});

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_proxy_ipv6_ips', _('Proxy IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.depends('lan_proxy_mode', 'listed_only');
		L.sortedKeys(ip6addrs, null, 'addr').forEach(function(ipv6) {
			so.value(ipv6, '%s (%s)'.format(ipv6, ip6addrs[ipv6]));
		});
		so.depends('homeproxy.config.ipv6_support', '1');

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_gaming_mode_ipv4_ips', _('Gaming mode IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';
		L.sortedKeys(ipaddrs, null, 'addr').forEach(function(ipv4) {
			so.value(ipv4, '%s (%s)'.format(ipv4, ipaddrs[ipv4]));
		});

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_gaming_mode_ipv6_ips', _('Gaming mode IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		L.sortedKeys(ip6addrs, null, 'addr').forEach(function(ipv6) {
			so.value(ipv6, '%s (%s)'.format(ipv6, ip6addrs[ipv6]));
		});
		so.depends('homeproxy.config.ipv6_support', '1');

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_global_proxy_ipv4_ips', _('Global proxy IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';
		L.sortedKeys(ipaddrs, null, 'addr').forEach(function(ipv4) {
			so.value(ipv4, '%s (%s)'.format(ipv4, ipaddrs[ipv4]));
		});
		so.depends({'homeproxy.config.routing_mode': 'custom', '!reverse': true});

		so = ss.taboption('lan_ip_policy', form.DynamicList, 'lan_global_proxy_ipv6_ips', _('Global proxy IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		L.sortedKeys(ip6addrs, null, 'addr').forEach(function(ipv6) {
			so.value(ipv6, '%s (%s)'.format(ipv6, ip6addrs[ipv6]));
		});
		so.depends({'homeproxy.config.routing_mode': /^((?!custom).)+$/, 'homeproxy.config.ipv6_support': '1'});
		/* LAN IP policy end */

		/* WAN IP policy start */
		ss.tab('wan_ip_policy', _('WAN IP Policy'));

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_proxy_ipv4_ips', _('Proxy IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_proxy_ipv6_ips', _('Proxy IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.depends('homeproxy.config.ipv6_support', '1');

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_direct_ipv4_ips', _('Direct IPv4 IP-s'));
		so.datatype = 'or(ip4addr, cidr4)';

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_direct_ipv6_ips', _('Direct IPv6 IP-s'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.depends('homeproxy.config.ipv6_support', '1');
		/* WAN IP policy end */

		/* Proxy domain list start */
		ss.tab('proxy_domain_list', _('Proxy Domain List'));

		so = ss.taboption('proxy_domain_list', form.TextValue, '_proxy_domain_list');
		so.rows = 10;
		so.monospace = true;
		so.datatype = 'hostname';
		so.depends({'homeproxy.config.routing_mode': 'custom', '!reverse': true});
		so.load = function(section_id) {
			return L.resolveDefault(callReadDomainList('proxy_list')).then((res) => {
				return res.content;
			}, {});
		}
		so.write = function(section_id, value) {
			return callWriteDomainList('proxy_list', value);
		}
		so.remove = function(section_id, value) {
			return callWriteDomainList('proxy_list', '');
		}
		so.validate = function(section_id, value) {
			if (section_id && value)
				for (var i of value.split('\n'))
					if (i && !stubValidator.apply('hostname', i))
						return _('Expecting: %s').format(_('valid hostname'));

			return true;
		}
		/* Proxy domain list end */

		/* Direct domain list start */
		ss.tab('direct_domain_list', _('Direct Domain List'));

		so = ss.taboption('direct_domain_list', form.TextValue, '_direct_domain_list');
		so.rows = 10;
		so.monospace = true;
		so.datatype = 'hostname';
		so.depends({'homeproxy.config.routing_mode': 'custom', '!reverse': true});
		so.load = function(section_id) {
			return L.resolveDefault(callReadDomainList('direct_list')).then((res) => {
				return res.content;
			}, {});
		}
		so.write = function(section_id, value) {
			return callWriteDomainList('direct_list', value);
		}
		so.remove = function(section_id, value) {
			return callWriteDomainList('direct_list', '');
		}
		so.validate = function(section_id, value) {
			if (section_id && value)
				for (var i of value.split('\n'))
					if (i && !stubValidator.apply('hostname', i))
						return _('Expecting: %s').format(_('valid hostname'));

			return true;
		}
		/* Direct domain list end */
		/* ACL settings end */

		return m.render();
	}
});
