/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2022-2025 ImmortalWrt.org
 */

'use strict';
'require form';
'require dom';
'require network';
'require poll';
'require rpc';
'require uci';
'require ui';
'require validation';
'require view';

'require homeproxy as hp';
'require tools.firewall as fwtool';
'require tools.widgets as widgets';

const callReadDomainList = rpc.declare({
	object: 'luci.homeproxy',
	method: 'domainlist_read',
	params: ['id'],
	expect: { '': {} }
});

const callWriteDomainLists = rpc.declare({
	object: 'luci.homeproxy',
	method: 'domainlist_write',
	params: ['lists', 'routing_mode', 'group_states'],
	expect: { '': {} }
});

const callRemoveDomainList = rpc.declare({
	object: 'luci.homeproxy',
	method: 'domainlist_remove',
	params: ['id'],
	expect: { '': {} }
});

function parseDomainList(value) {
	let suffixes = [], keywords = [], normalized = [], seen = Object.create(null);
	for (let item of (value || '').replace(/\r\n?/g, '\n').split('\n')) {
		item = item.trim().toLowerCase();
		if (!item)
			continue;
		item = item.replace(/^\.+|\.+$/g, '');
		if (!item)
			return { error: _('Expecting: %s').format(_('valid hostname')) };
		if (!stubValidator.apply('hostname', item))
			return { error: _('Expecting: %s').format(_('valid hostname')) };
		if (seen[item])
			continue;

		seen[item] = true;
		normalized.push(item);
		(item.includes('.') ? suffixes : keywords).push(item);
	}

	return {
		content: normalized.length ? normalized.join('\n') + '\n' : '',
		suffixes,
		keywords
	};
}

function domainSuffixOverlap(left, right) {
	const endsWithDomain = (value, suffix) =>
		value === suffix || value.endsWith('.' + suffix);
	return endsWithDomain(left, right) || endsWithDomain(right, left);
}

function findDomainListConflict(groups) {
	let entries = [];
	for (let group of groups) {
		for (let value of group.suffixes)
			entries.push({ group, type: 'suffix', value });
		for (let value of group.keywords)
			entries.push({ group, type: 'keyword', value });
	}

	for (let i = 0; i < entries.length; i++) {
		for (let j = 0; j < i; j++) {
			const left = entries[i], right = entries[j];
			if (left.group.id === right.group.id)
				continue;

			let overlap;
			if (left.type === 'keyword' || right.type === 'keyword') {
				const keyword = left.type === 'keyword' ? left.value : right.value;
				const other = left.type === 'keyword' ? right.value : left.value;
				overlap = other.includes(keyword) ||
					(right.type === 'keyword' && keyword.includes(other));
			} else {
				overlap = domainSuffixOverlap(left.value, right.value);
			}

			if (overlap)
				return { left, right };
		}
	}

	return null;
}

const callCurrentNode = rpc.declare({
	object: 'luci.homeproxy',
	method: 'current_node_get',
	expect: { '': {} }
});

const callTailscaleStatus = rpc.declare({
	object: 'luci.homeproxy',
	method: 'tailscale_status',
	expect: { '': {} }
});

function renderTailscaleStatus(status) {
	if (status?.state === 'Running')
		return E('span', { 'class': 'label success' }, _('Connected'));
	if (status?.state === 'disabled')
		return E('span', {}, _('Save and apply to enable Tailscale.'));
	if (status?.auth_url) {
		try {
			const url = new URL(status.auth_url);
			if (['http:', 'https:'].includes(url.protocol) && url.hostname && !url.username && !url.password)
				return E('a', { 'class': 'cbi-button cbi-button-action', href: url.href,
					target: '_blank', rel: 'noopener noreferrer' }, _('Log in to Tailscale'));
		} catch (e) {}
	}
	if (status?.state === 'NeedsMachineAuth')
		return E('span', {}, _('Approve this device in the Tailscale admin console.'));
	if (status?.state === 'NeedsLogin' || status?.state === 'NoState')
		return E('span', {}, _('Waiting for the login link. Check the control server connection if it does not appear.'));
	return E('span', {}, _('Tailscale status is unavailable. Save and apply, then check that the client is running.'));
}

function renderStatus(isRunning, version, currentNode) {
	let spanTemp = '<em><span style="color:%s"><strong>%s (sing-box v%s) %s</strong></span></em>';
	let renderHTML;
	let statusColor = isRunning ? 'green' : 'red';
	let nodeColor = '#1e90ff';
	if (isRunning)
		renderHTML = spanTemp.format(statusColor, _('HomeProxy'), version, _('RUNNING'));
	else
		renderHTML = spanTemp.format(statusColor, _('HomeProxy'), version, _('NOT RUNNING'));

	if (currentNode)
		renderHTML += '<div><em><span style="color:%s"><strong>%s</strong></span></em></div>'.format(nodeColor, '%h'.format(currentNode));

	return renderHTML;
}

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

return view.extend({
	load() {
		return Promise.all([
			uci.load('homeproxy'),
			hp.getBuiltinFeatures(),
			network.getHostHints()
		]);
	},

	render(data) {
		let m, s, o, ss, so;

		let features = data[1],
		    hosts = data[2]?.hosts;

		/* Cache all configured proxy nodes, they will be called multiple times */
		const subscription_groups = Object.fromEntries(
			hp.getSubscriptionGroups(data[0]).map((group) => [ group.hash, group.title ])
		);
		let proxy_nodes = {};
		uci.sections(data[0], 'node', (res) => {
			let nodeaddr = res.address || '',
			    nodeport = res.port || '',
			    endpoint = nodeaddr && nodeport ? ((stubValidator.apply('ip6addr', nodeaddr) ?
				String.format('[%s]', nodeaddr) : nodeaddr) + ':' + nodeport) : res['.name'];

			const group = subscription_groups[res.grouphash];
			proxy_nodes[res['.name']] = (group ? '<' + group + '> ' : '') +
				String.format('[%s] %s', res.type, res.label || endpoint);
		});

		m = new form.Map('homeproxy', _('HomeProxy'),
			_('The modern ImmortalWRT proxy platform for ARM64/AMD64. Powered by Sing-Box/TUN/AI Edition'));

		let domainListCache = Object.create(null),
		    pendingDomainLists = Object.create(null);

		function loadDomainList(id) {
			if (Object.prototype.hasOwnProperty.call(pendingDomainLists, id))
				return Promise.resolve(pendingDomainLists[id]);

			return callReadDomainList(id).then((res) => {
				if (res.error)
					throw new Error(res.error);
				domainListCache[id] = res.content || '';
				return domainListCache[id];
			});
		}

		function stageDomainList(id, value) {
			const parsed = parseDomainList(value);
			if (parsed.error)
				throw new TypeError(parsed.error);

			pendingDomainLists[id] = parsed.content;
			domainListCache[id] = parsed.content;
		}

		function domainListContent(id) {
			return Object.prototype.hasOwnProperty.call(pendingDomainLists, id) ?
				pendingDomainLists[id] : (domainListCache[id] || '');
		}

		function validateDomainLists() {
			const routingMode = uci.get('homeproxy', 'config', 'routing_mode') || 'bypass_mainland_china';
			let groups = [ { id: 'direct', label: _('Direct List') } ];
			if (routingMode === 'bypass_mainland_china')
				groups.push({ id: 'proxy', label: _('Proxy List') });
			uci.sections('homeproxy', 'domain_route', (section) => {
				if (section.enabled === '0')
					return;
				groups.push({
					id: section['.name'],
					label: section.label || section['.name']
				});
			});

			for (let group of groups) {
				const parsed = parseDomainList(domainListContent(group.id));
				if (parsed.error)
					throw new TypeError(_('%s contains an invalid domain.').format(group.label));
				Object.assign(group, parsed);
			}

			const conflict = findDomainListConflict(groups);
			if (conflict)
				throw new TypeError(
					_('Domain %s in %s conflicts with %s in %s.').format(
						conflict.left.value, conflict.left.group.label,
						conflict.right.value, conflict.right.group.label
					)
				);

			return routingMode;
		}

		function configureDomainListSave(map) {
			const saveMap = map.save;
			map.save = function(cb, silent) {
				return saveMap.call(this, () => Promise.resolve(
					typeof cb === 'function' ? cb() : null
				).then(() => {
					/* Include unopened group editors in cross-list validation. */
					const ids = ['direct', 'proxy'];
					uci.sections('homeproxy', 'domain_route', (section) => {
						ids.push(section['.name']);
					});
					return Promise.all(ids.map(loadDomainList));
				}).then(() => {
					const routingMode = validateDomainLists();
					const ids = Object.keys(pendingDomainLists);
					if (!ids.length)
						return null;

					const lists = Object.assign({}, pendingDomainLists);
					const groupStates = {};
					uci.sections('homeproxy', 'domain_route', (section) => {
						groupStates[section['.name']] = section.enabled === '0' ? '0' : '1';
					});
					return callWriteDomainLists(lists, routingMode, groupStates).then((result) => {
						if (!result.result)
							throw new Error(result.error || _('Failed to save domain lists.'));
						if (result.warning)
							ui.addNotification(null, E('p', {}, _('Domain lists were saved, but temporary backup cleanup failed.')), 'warning');
						for (let id of ids) {
							const builtin = id === 'direct' || id === 'proxy';
							const section = builtin ? 'diversion' : id;
							const option = builtin ? id + '_list_checksum' : 'list_checksum';
							const checksum = hp.calcStringMD5(lists[id]);
							if (uci.get('homeproxy', section, option) !== checksum)
								uci.set('homeproxy', section, option, checksum);
						}
						pendingDomainLists = Object.create(null);
					});
				}), silent).catch((error) => {
					if (silent)
						ui.addNotification(null, E('p', {}, error.message), 'error');
					throw error;
				});
			};
		}
		configureDomainListSave(m);

		s = m.section(form.TypedSection);
		s.render = function () {
			poll.add(function () {
				return Promise.all([
					L.resolveDefault(hp.getServiceStatus('sing-box-c'), false),
					L.resolveDefault(callCurrentNode(), null)
				]).then((res) => {
					let isRunning = res[0],
					    current = res[1],
					    current_label = null;

					if (current?.mode === 'urltest') {
						let active = current.active || {};
						let nodeName = (active?.id && active.id !== 'urltest') ? (proxy_nodes[active.id] || active.label || active.id) : _('Invalid node');

						current_label = _('URLTest: %s').format(nodeName);
					}
					let view = document.getElementById('service_status');
					view.innerHTML = renderStatus(isRunning, features.version, current_label);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
				E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'homeproxy');

		s.tab('routing', _('Routing Settings'));
		s.tab('dashboard', _('Dashboard'));

		o = s.taboption('routing', form.ListValue, 'main_node', _('Main node'));
		o.value('nil', _('Disable'));
		o.value('urltest', _('URLTest'));
		for (let i in proxy_nodes)
			o.value(i, E('span', {}, [proxy_nodes[i]]));
		o.default = 'nil';
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
		o.rmempty = false;
		o.retain = true;

		o = s.taboption('routing', hp.CBIStaticList, 'main_urltest_nodes', _('URLTest nodes'),
			_('List of nodes to test.'));
		for (let i in proxy_nodes)
			o.value(i, E('span', {}, [proxy_nodes[i]]));
		o.depends({ routing_mode: 'bypass_mainland_china', main_node: 'urltest' });
		o.depends({ routing_mode: 'global', main_node: 'urltest' });
		o.rmempty = false;
		o.retain = true;

		o = s.taboption('routing', form.Flag, 'main_urltest_interrupt_exist_connections', _('Interrupt existing connections'),
			_('Interrupt existing connections when the selected outbound has changed.'));
		o.default = o.disabled;
		o.rmempty = false;
		o.depends({ routing_mode: 'bypass_mainland_china', main_node: 'urltest' });
		o.depends({ routing_mode: 'global', main_node: 'urltest' });
		o.retain = true;

		o = s.taboption('routing', form.Value, 'dns_server', _('DNS server'),
			_('Support UDP, TCP, DoH, DoQ, DoT. TCP protocol will be used if not specified.'));
		o.value('wan', _('WAN DNS (read from interface)'));
		o.value('https://dns.cloudflare.com/dns-query', _('Cloudflare Public DNS (DoH)'));
		o.value('https://dns.google/dns-query', _('Google Public DNS (DoH)'));
		o.value('https://dns.quad9.net/dns-query', _('Quad9 Public DNS (DoH)'));
		o.value('https://dns.adguard-dns.com/dns-query', _('AdGuard Public DNS (DoH)'));
		o.value('https://dns.sb/dns-query', _('DNS.SB Public DNS (DoH)'));
		o.value('https://dns.opendns.com/dns-query', _('Cisco Public DNS (DoH)'));
		o.default = 'https://dns.quad9.net/dns-query';
		o.rmempty = false;
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
		o.retain = true;
		o.validate = function(section_id, value) {
			if (section_id && !['wan'].includes(value)) {
				if (!value)
					return _('Expecting: %s').format(_('non-empty value'));

				try {
					let url = new URL(value.replace(/^.*:\/\//, 'http://'));
					if (stubValidator.apply('hostname', url.hostname))
						return true;
					else if (stubValidator.apply('ip4addr', url.hostname))
						return true;
					else if (stubValidator.apply('ip6addr', url.hostname.match(/^\[(.+)\]$/)?.[1]))
						return true;
					else
						return _('Expecting: %s').format(_('valid DNS server address'));
				} catch(e) {}

				if (!stubValidator.apply('ipaddr', value))
					return _('Expecting: %s').format(_('valid DNS server address'));
			}

			return true;
		}

		o = s.taboption('routing', form.Value, 'china_dns_server', _('China DNS server'),
			_('The dns server for resolving China domains. Support UDP, TCP, DoH, DoQ, DoT.'));
		o.value('wan', _('WAN DNS (read from interface)'));
		o.value('https://doh-pure.onedns.net/dns-query', _('ThreatBook Public DNS (DoH)'));
		o.value('https://doh.pub/dns-query', _('Tencent Public DNS (DoH)'));
		o.value('https://dns.alidns.com/dns-query', _('AliDNS Public DNS (DoH)'));
		o.depends('routing_mode', 'bypass_mainland_china');
		o.default = 'https://dns.alidns.com/dns-query';
		o.rmempty = false;
		o.retain = true;
		o.validate = function(section_id, value) {
			if (section_id && !['wan'].includes(value)) {
				if (!value)
					return _('Expecting: %s').format(_('non-empty value'));

				try {
					let url = new URL(value.replace(/^.*:\/\//, 'http://'));
					if (stubValidator.apply('hostname', url.hostname))
						return true;
					else if (stubValidator.apply('ip4addr', url.hostname))
						return true;
					else if (stubValidator.apply('ip6addr', url.hostname.match(/^\[(.+)\]$/)?.[1]))
						return true;
					else
						return _('Expecting: %s').format(_('valid DNS server address'));
				} catch(e) {}

				if (!stubValidator.apply('ipaddr', value))
					return _('Expecting: %s').format(_('valid DNS server address'));
			}

			return true;
		}

		o = s.taboption('routing', form.ListValue, 'routing_mode', _('Routing mode'));
		o.value('bypass_mainland_china', _('Bypass mainland China'));
		o.value('global', _('Global'));
		o.default = 'bypass_mainland_china';
		o.rmempty = false;

		o = s.taboption('routing', form.Value, 'routing_port', _('Routing ports'),
			_('Specify target ports to be proxied. Multiple ports must be separated by commas.'));
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
		o.value('', _('All ports'));
		o.value('common', _('Common ports only (bypass P2P traffic)'));
		o.validate = function(section_id, value) {
			if (section_id && value && value !== 'common') {

				let ports = [];
				for (let i of value.split(',')) {
					if (!stubValidator.apply('port', i) && !stubValidator.apply('portrange', i))
						return _('Expecting: %s').format(_('valid port value'));
					if (ports.includes(i))
						return _('Port %s already exists!').format(i);
					ports = ports.concat(i);
				}
			}

			return true;
		}

		o = s.taboption('routing', form.Flag, 'ipv6_support', _('IPv6 support'));
		o.default = o.enabled;
		o.rmempty = false;
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');

		o = s.taboption('dashboard', form.Flag, 'dashboard_enabled', _('Enable dashboard'));
		o.default = '0';
		o.rmempty = false;
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');

		o = s.taboption('dashboard', form.Value, 'dashboard_port', _('Listen port'),
			_('A random available port is assigned on first installation.'));
		o.default = '9095';
		o.datatype = 'port';
		o.rmempty = false;
		o.retain = true;
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');

		o = s.taboption('dashboard', form.Value, 'dashboard_secret', _('API secret'));
		o.password = true;
		o.rmempty = true;
		o.retain = true;
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');

		o = s.taboption('dashboard', form.Button, '_open_dashboard', _('sing-box dashboard'));
		o.inputtitle = _('Open dashboard');
		o.inputstyle = 'apply';
		o.depends({ routing_mode: 'bypass_mainland_china', dashboard_enabled: '1' });
		o.depends({ routing_mode: 'global', dashboard_enabled: '1' });
		o.onclick = function() {
			let host = window.location.hostname,
			    port = uci.get('homeproxy', 'config', 'dashboard_port') || '9095';
			if (host.includes(':') && !host.startsWith('['))
				host = '[' + host + ']';
			window.open('http://' + host + ':' + port + '/dashboard/', '_blank', 'noopener,noreferrer');
		};

		/* ACL settings start */
		s.tab('control', _('Access Control'));

		o = s.taboption('control', form.SectionValue, '_control', form.NamedSection, 'control', 'homeproxy');
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
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

		so = ss.taboption('lan_ip_policy', form.Flag, 'lan_whitelist_mode', _('List mode'),
			_('Only devices in the lists below are processed. All other devices use direct routing.'));
		so.default = '0';
		so.rmempty = false;
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		so.retain = true;

		so = fwtool.addIPOption(ss, 'lan_ip_policy', 'lan_direct_ipv4_ips', _('Global Direct IPv4 addresses'),
			_('IPv4 addresses in this option are forced to use global direct routing.'), 'ipv4', hosts, true);
		so.depends({
			'lan_whitelist_mode': '0',
			'homeproxy.config.routing_mode': 'bypass_mainland_china'
		});
		so.depends('homeproxy.config.routing_mode', 'global');
		so.retain = true;

		so = fwtool.addMACOption(ss, 'lan_ip_policy', 'lan_direct_mac_addrs', _('Global Direct MAC addresses'),
			_('MAC addresses in this option are forced to use global direct routing.'), hosts);
		so.depends({
			'lan_whitelist_mode': '0',
			'homeproxy.config.routing_mode': 'bypass_mainland_china'
		});
		so.depends('homeproxy.config.routing_mode', 'global');
		so.retain = true;

		so = fwtool.addIPOption(ss, 'lan_ip_policy', 'lan_auto_proxy_ipv4_ips', _('Rule Proxy IPv4 addresses'),
			_('IPv4 addresses in this option automatically use rule-based proxy routing.'), 'ipv4', hosts, true);
		so.depends({
			'lan_whitelist_mode': '1',
			'homeproxy.config.routing_mode': 'bypass_mainland_china'
		});
		so.retain = true;

		so = fwtool.addMACOption(ss, 'lan_ip_policy', 'lan_auto_proxy_mac_addrs', _('Rule Proxy MAC addresses'),
			_('MAC addresses in this option automatically use rule-based proxy routing.'), hosts);
		so.depends({
			'lan_whitelist_mode': '1',
			'homeproxy.config.routing_mode': 'bypass_mainland_china'
		});
		so.retain = true;

		so = fwtool.addIPOption(ss, 'lan_ip_policy', 'lan_proxy_ipv4_ips', _('Global Proxy IPv4 addresses'),
			_('IPv4 addresses in this option are forced to use global proxy routing.'), 'ipv4', hosts, true);
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		so.retain = true;

		so = fwtool.addMACOption(ss, 'lan_ip_policy', 'lan_proxy_mac_addrs', _('Global Proxy MAC addresses'),
			_('MAC addresses in this option are forced to use global proxy routing.'), hosts);
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		so.retain = true;
		/* LAN IP policy end */

		/* WAN IP policy start */
		ss.tab('wan_ip_policy', _('WAN IP Policy'));

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_proxy_ipv4_ips', _('Global Proxy IPv4 addresses'),
			_('IPv4 addresses in this option are forced to use global proxy routing.'));
		so.datatype = 'or(ip4addr, cidr4)';
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		so.retain = true;

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_proxy_ipv6_ips', _('Global Proxy IPv6 addresses'),
			_('IPv6 addresses in this option are forced to use global proxy routing.'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		so.retain = true;

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_direct_ipv4_ips', _('Global Direct IPv4 addresses'),
			_('IPv4 addresses in this option are forced to use global direct routing.'));
		so.datatype = 'or(ip4addr, cidr4)';

		so = ss.taboption('wan_ip_policy', form.DynamicList, 'wan_direct_ipv6_ips', _('Global Direct IPv6 addresses'),
			_('IPv6 addresses in this option are forced to use global direct routing.'));
		so.datatype = 'or(ip6addr, cidr6)';
		so.retain = true;
		/* WAN IP policy end */

		/* ACL settings end */

		/* Diversion settings start */
		s.tab('diversion', _('Diversion Control'));

		o = s.taboption('diversion', form.SectionValue, '_diversion', form.NamedSection, 'diversion', 'homeproxy');
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
		ss = o.subsection;

		function configureDomainList(option, id) {
			option.rows = 12;
			option.monospace = true;
			option.rmempty = true;
			option.retain = true;
			option.load = function(/* ... */) {
				return loadDomainList(id);
			};
			option.write = function(_section_id, value) {
				stageDomainList(id, value);
			};
			option.remove = function(/* ... */) {
				stageDomainList(id, '');
			};
			option.validate = function(_section_id, value) {
				return parseDomainList(value).error || true;
			};
		}

		ss.tab('direct_list', _('Direct List'));
		so = ss.taboption('direct_list', form.TextValue, '_direct_list', null,
			_('Domains in this list always use direct routing.'));
		configureDomainList(so, 'direct');

		ss.tab('proxy_list', _('Proxy List'));
		so = ss.taboption('proxy_list', form.TextValue, '_proxy_list', null,
			_('Domains in this list always use the main node.'));
		so.depends('homeproxy.config.routing_mode', 'bypass_mainland_china');
		configureDomainList(so, 'proxy');

		ss.tab('diversion_list', _('Diversion List'));
		so = ss.taboption('diversion_list', form.SectionValue, '_domain_routes',
			form.GridSection, 'domain_route', null);
		let domainRoutes = so.subsection;
		domainRoutes.anonymous = true;
		domainRoutes.addremove = true;
		domainRoutes.addbtntitle = _('Add diversion group');
		domainRoutes.nodescriptions = true;
		domainRoutes.addModalOptions = function(section) {
			configureDomainListSave(section.map);
		};
		let domainRouteSerial = 0;
		function newDomainRouteId() {
			let id;
			do {
				id = 'route_' + Date.now().toString(36) + (domainRouteSerial++).toString(36);
			} while (uci.get('homeproxy', id) != null);
			return id;
		}

		/* Keep diversion group IDs stable across UCI reloads so their files remain addressable. */
		domainRoutes.handleAdd = function(/* ev */) {
			const config_name = this.uciconfig ?? this.map.config;
			const section_id = this.map.data.add(config_name, this.sectiontype, newDomainRouteId());
			const mapNode = this.getPreviousModalMap();
			const prevMap = mapNode ? dom.findClassInstance(mapNode) : this.map;

			prevMap.addedSection = section_id;
			return this.renderMoreOptionsModal(section_id);
		};

		let dro = domainRoutes.option(form.Flag, 'enabled', _('Enable'));
		dro.default = dro.enabled;
		dro.rmempty = false;
		dro.editable = true;

		dro = domainRoutes.option(form.Value, 'label', _('Name'));
		dro.rmempty = false;

		dro = domainRoutes.option(form.ListValue, 'node', _('Node'));
		for (let i in proxy_nodes)
			dro.value(i, E('span', {}, [proxy_nodes[i]]));
		dro.value('tailscale', _('[Tailscale] Tailscale'));
		dro.rmempty = false;
		dro.textvalue = function(section_id) {
			const value = this.cfgvalue(section_id);
			return value === 'tailscale' ? _('[Tailscale] Tailscale') :
				(value != null ? E('span', {}, [proxy_nodes[value] || value]) : null);
		};

		dro = domainRoutes.option(form.TextValue, '_domain_list', _('Domain List'),
			_('Entries containing a dot use domain suffix matching; other entries use keyword matching.'));
		dro.modalonly = true;
		dro.rows = 12;
		dro.monospace = true;
		dro.rmempty = true;
		dro.load = function(section_id) {
			return loadDomainList(section_id);
		};
		dro.write = function(section_id, value) {
			stageDomainList(section_id, value);
		};
		dro.remove = function(section_id) {
			stageDomainList(section_id, '');
		};
		dro.validate = function(_section_id, value) {
			return parseDomainList(value).error || true;
		};

		const removeDomainRoute = domainRoutes.handleRemove;
		domainRoutes.handleRemove = function(section_id, ev) {
			delete pendingDomainLists[section_id];
			return removeDomainRoute.call(this, section_id, ev).then(() => {
				return callRemoveDomainList(section_id);
			}).then((result) => {
				if (!result.result)
					throw new Error(result.error || _('Failed to save domain lists.'));
				domainListCache[section_id] = '';
			});
		};
		/* Diversion settings end */

		/* Tailscale settings start */
		s.tab('tailscale', _('Tailscale'));

		o = s.taboption('tailscale', form.SectionValue, '_tailscale', form.NamedSection, 'tailscale', 'homeproxy');
		o.depends('routing_mode', 'bypass_mainland_china');
		o.depends('routing_mode', 'global');
		ss = o.subsection;

		so = ss.option(form.Flag, 'enabled', _('Enable Tailscale'),
			_('Enable the sing-box Tailscale endpoint. A main node must also be enabled.'));
		so.default = so.disabled;
		so.rmempty = false;

		so = ss.option(form.Value, 'auth_key', _('Authentication key'),
			_('Used only when creating the node. Leave empty to sign in using the login button below.'));
		so.password = true;
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.DummyValue, '_tailscale_status', _('Login status'));
		so.depends('enabled', '1');
		so.renderWidget = function() {
			const container = E('div', {}, _('Collecting data...'));
			const refresh = () => L.resolveDefault(callTailscaleStatus(), {}).then((status) => {
				dom.content(container, renderTailscaleStatus(status));
			});
			poll.add(refresh, 5);
			refresh();
			return container;
		};

		so = ss.option(form.Value, 'control_url', _('Control server'),
			_('Coordination server URL. Leave empty to use the official Tailscale service.'));
		so.placeholder = 'https://controlplane.tailscale.com';
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');
		so.validate = function(_section_id, value) {
			if (!value)
				return true;
			try {
				const url = new URL(value);
				return (url.hostname && ['http:', 'https:'].includes(url.protocol)) ||
					_('Expecting: %s').format(_('valid URL'));
			} catch (e) {
				return _('Expecting: %s').format(_('valid URL'));
			}
		};

		so = ss.option(form.Value, 'hostname', _('Hostname'),
			_('Device name shown in the Tailscale network. The system hostname is used when empty.'));
		so.datatype = 'hostname';
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.Flag, 'accept_routes', _('Accept routes'),
			_('Accept subnet routes advertised by other Tailscale nodes.'));
		so.default = so.disabled;
		so.rmempty = false;
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.Value, 'exit_node', _('Exit node'),
			_('Exit node name or IP address. Public domains can use Tailscale diversion only when an exit node is available.'));
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');
		so.validate = function(section_id, value) {
			if (!value)
				return true;
			if (this.section.formvalue(section_id, 'advertise_exit_node') === '1')
				return _('An exit node cannot be used and advertised at the same time.');
			return stubValidator.apply('hostname', value) ||
				stubValidator.apply('ip4addr', value) ||
				stubValidator.apply('ip6addr', value) ||
				_('Expecting: %s').format(_('valid hostname or IP address'));
		};

		so = ss.option(form.Flag, 'exit_node_allow_lan_access', _('Allow LAN access with exit node'),
			_('Keep locally accessible subnets outside the selected exit node.'));
		so.default = so.disabled;
		so.rmempty = false;
		so.retain = true;
		so.depends('enabled', '1');

		so = ss.option(form.DynamicList, 'advertise_routes', _('Advertised routes'),
			_('LAN subnets advertised as reachable through this router. Routes must also be approved by the coordination server.'));
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');
		so.validate = function(_section_id, value) {
			/* Validate here: LuCI's CIDR datatype replaces value with the prefix length. */
			if (value && !stubValidator.apply('cidr', value))
				return _('Expecting: %s').format(_('valid network in CIDR notation'));
			if (value === '0.0.0.0/0' || value === '::/0')
				return _('Use "Advertise as exit node" instead of a default route.');
			return true;
		};

		so = ss.option(form.Flag, 'advertise_exit_node', _('Advertise as exit node'),
			_('Advertise this router as an exit node. Approval is still required on the coordination server.'));
		so.default = so.disabled;
		so.rmempty = false;
		so.retain = true;
		so.depends('enabled', '1');
		so.validate = function(section_id, value) {
			if (value === '1' && this.section.formvalue(section_id, 'exit_node'))
				return _('An exit node cannot be used and advertised at the same time.');
			return true;
		};

		so = ss.option(form.Value, 'listen_port', _('Listen port'),
			_('UDP port for WireGuard and peer-to-peer traffic. A port is selected automatically when empty.'));
		so.datatype = 'port';
		so.rmempty = true;
		so.retain = true;
		so.depends('enabled', '1');
		/* Tailscale settings end */

		return m.render();
	}
});
