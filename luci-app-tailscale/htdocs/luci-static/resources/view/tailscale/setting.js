/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2024 asvow
 */

'use strict';
'require form';
'require fs';
'require network';
'require poll';
'require rpc';
'require uci';
'require view';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getInterfaceSubnets(interfaces = ['lan', 'wan']) {
    return network.getNetworks().then(networks => {
        return [...new Set(
            networks
               .filter(ifc => interfaces.includes(ifc.getName()))
               .flatMap(ifc => ifc.getIPAddrs())
               .filter(addr => addr.includes('/'))
               .map(addr => {
                    const [ip, cidr] = addr.split('/');
                    const ipParts = ip.split('.').map(Number);
                    const mask = ~((1 << (32 - parseInt(cidr))) - 1);
                    const subnetParts = ipParts.map((part, i) => (part & (mask >> (24 - i * 8))) & 255);
                    return `${subnetParts.join('.')}/${cidr}`;
                })
        )];
    });
}

function getStatus() {
	var status = {
		isRunning: false,
		backendState: undefined,
		authURL: undefined,
		displayName: undefined,
		onlineExitNodes: [],
		subnetRoutes: []
	};
	return Promise.resolve(callServiceList('tailscale')).then(res => {
		try {
			status.isRunning = res['tailscale']['instances']['instance1']['running'];
		} catch (e) {
			return status;
		}
		return fs.exec("/usr/sbin/tailscale", ["status", "--json"]).then(res => {
			const tailscaleStatus = JSON.parse(res.stdout.replace(/("\w+"):\s*(\d+)/g, '$1:"$2"'));
			if (!tailscaleStatus.AuthURL && tailscaleStatus.BackendState === "NeedsLogin") {
				fs.exec("/usr/sbin/tailscale", ["login"]);
			}
			status.backendState = tailscaleStatus.BackendState;
			status.authURL = tailscaleStatus.AuthURL;
			status.displayName = (status.backendState === "Running") ? 	tailscaleStatus.User[tailscaleStatus.Self.UserID].DisplayName : undefined;
			status.onlineExitNodes = Object.values(tailscaleStatus.Peer)
				.flatMap(peer => (peer.ExitNodeOption && peer.Online) ? [peer.HostName] : []);
			status.subnetRoutes = Object.values(tailscaleStatus.Peer)
				.flatMap(peer => peer.PrimaryRoutes || []);
			return status;
		});
	}).catch(() => status);
}

function renderStatus(isRunning) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		renderHTML = String.format(spanTemp, 'green', _('Tailscale'), _('RUNNING'));
	} else {
		renderHTML = String.format(spanTemp, 'red', _('Tailscale'), _('NOT RUNNING'));
	}

	return renderHTML;
}

function renderLogin(loginStatus, authURL, displayName) {
	var spanTemp = '<span style="color:%s">%s</span>';
	var renderHTML;
	if (loginStatus == "NeedsLogin") {
		renderHTML = String.format('<a href="%s" target="_blank">%s</a>', authURL, _('Need to log in'));
	} else if (loginStatus == "Running") {
		renderHTML = String.format('<a href="%s" target="_blank">%s</a>', 'https://login.tailscale.com/admin/machines', displayName);
		renderHTML += String.format('<br><a style="color:green" id="logout_button">%s</a>', _('Log out and Unbind'));
	} else {
		renderHTML = String.format(spanTemp, 'orange', _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('tailscale'),
			getStatus(),
			getInterfaceSubnets()
		]);
	},

	render: function(data) {
		var m, s, o;
		var statusData = data[1];
		var interfaceSubnets = data[2];
		var onlineExitNodes = statusData.onlineExitNodes;
		var subnetRoutes = statusData.subnetRoutes;

		m = new form.Map('tailscale', _('Tailscale'), _('Tailscale is a cross-platform and easy to use virtual LAN.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function() {
				return Promise.resolve(getStatus()).then(function(res) {
					var service_view = document.getElementById("service_status");
					var login_view = document.getElementById("login_status_div");
					service_view.innerHTML = renderStatus(res.isRunning);
					login_view.innerHTML = renderLogin(res.backendState, res.authURL, res.displayName);
					var logoutButton = document.getElementById('logout_button');
					if (logoutButton) {
						logoutButton.onclick = function() {
							if (confirm(_('Are you sure you want to log out and unbind the current device?'))) {
								fs.exec("/usr/sbin/tailscale", ["logout"]);
							}
						}
					}
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
				E('p', { id: 'service_status' }, _('Collecting data ...'))
			]);
		}

		s = m.section(form.NamedSection, 'settings', 'config');
		s.tab('basic', _('Basic Settings'));

		o = s.taboption('basic', form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.taboption('basic', form.DummyValue, 'login_status', _('Login Status'));
		o.depends('enabled', '1');
		o.renderWidget = function(section_id, option_id) {
			return E('div', { 'id': 'login_status_div' }, _('Collecting data ...'));
		};

		o = s.taboption('basic', form.Value, 'port', _('Port'), _('Set the Tailscale port number.'));
		o.datatype = 'port';
		o.default = '41641';
		o.rmempty = false;

		o = s.taboption('basic', form.Value, 'config_path', _('Workdir'), _('The working directory contains config files, audit logs, and runtime info.'));
		o.default = '/etc/tailscale';
		o.rmempty = false;

		o = s.taboption('basic', form.ListValue, 'fw_mode', _('Firewall Mode'));
		o.value('nftables', 'nftables');
		o.value('iptables', 'iptables');
		o.default = 'nftables';
		o.rmempty = false;

		o = s.taboption('basic', form.Flag, 'log_stdout', _('StdOut Log'), _('Logging program activities.'));
		o.default = o.enabled;
		o.rmempty = false;

		o = s.taboption('basic', form.Flag, 'log_stderr', _('StdErr Log'), _('Logging program errors and exceptions.'));
		o.default = o.enabled;
		o.rmempty = false;

		s.tab('advance', _('Advanced Settings'));

		o = s.taboption('advance', form.Flag, 'acceptRoutes', _('Accept Routes'), _('Accept subnet routes that other nodes advertise.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.taboption('advance', form.Value, 'hostname', _('Device Name'), _("Leave blank to use the device's hostname."));
		o.default = '';
		o.rmempty = true;

		o = s.taboption('advance', form.Flag, 'acceptDNS', _('Accept DNS'), _('Accept DNS configuration from the Tailscale admin console.'));
		o.default = o.enabled;
		o.rmempty = false;

		o = s.taboption('advance', form.Flag, 'advertiseExitNode', _('Exit Node'), _('Offer to be an exit node for outbound internet traffic from the Tailscale network.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.taboption('advance', form.ListValue, 'exitNode', _('Online Exit Nodes'), _('Select an online machine name to use as an exit node.'));
		if (onlineExitNodes.length > 0) {
			o.optional = false;
			onlineExitNodes.forEach(function(node) {
				o.value(node, node);
			});
		} else {
			o.value('', _('No Available Exit Nodes'));
			o.readonly = true;
		}
		o.default = '';
		o.depends('advertiseExitNode', '0');
		o.rmempty = true;

		o = s.taboption('advance', form.DynamicList, 'advertiseRoutes', _('Expose Subnets'), _('Expose physical network routes into Tailscale, e.g. <code>10.0.0.0/24</code>.'));
		if (interfaceSubnets.length > 0) {
			interfaceSubnets.forEach(function(subnet) {
				o.value(subnet, subnet);
			});
		}
		o.default = '';
		o.rmempty = true;

		o = s.taboption('advance', form.Flag, 's2s', _('Site To Site'), _('Use site-to-site layer 3 networking to connect subnets on the Tailscale network.'));
		o.default = o.disabled;
		o.depends('acceptRoutes', '1');
		o.rmempty = false;

		o = s.taboption('advance', form.DynamicList, 'subnetRoutes', _('Subnet Routes'), _('Select subnet routes advertised by other nodes in Tailscale network.'));
		if (subnetRoutes.length > 0) {
			subnetRoutes.forEach(function(route) {
				o.value(route, route);
			});
		} else {
			o.value('', _('No Available Subnet Routes'));
			o.readonly = true;
		}
		o.default = '';
		o.depends('s2s', '1');
		o.rmempty = true;

		o = s.taboption('advance', form.MultiValue, 'access', _('Access Control'));
		o.value('tsfwlan', _('Tailscale access LAN'));
		o.value('tsfwwan', _('Tailscale access WAN'));
		o.value('lanfwts', _('LAN access Tailscale'));
		o.value('wanfwts', _('WAN access Tailscale'));
		o.default = "tsfwlan tsfwwan lanfwts";
		o.rmempty = true;

		s.tab('extra', _('Extra Settings'));

		o = s.taboption('extra', form.DynamicList, 'flags', _('Additional Flags'), String.format(_('List of extra flags. Format: --flags=value, e.g. <code>--exit-node=10.0.0.1</code>. <br> %s for enabling settings upon the initiation of Tailscale.'), '<a href="https://tailscale.com/kb/1241/tailscale-up" target="_blank">' + _('Available flags') + '</a>'));
		o.default = '';
		o.rmempty = true;

		s = m.section(form.NamedSection, 'settings', 'config');
		s.title = _('Custom Server Settings');
		s.description = String.format(_('Use %s to deploy a private server.'), '<a href="https://github.com/juanfont/headscale" target="_blank">headscale</a>');

		o = s.option(form.Value, 'loginServer', _('Server Address'));
		o.default = '';
		o.rmempty = true;

		o = s.option(form.Value, 'authKey', _('Auth Key'));
		o.default = '';
		o.rmempty = true;

		return m.render();
	}
});
