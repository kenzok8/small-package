/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2022 ImmortalWrt.org
 * Copyright (C) 2024 asvow
 */

'use strict';
'require dom';
'require fs';
'require poll';
'require ui';
'require view';

return view.extend({
	load: function() {
		return fs.exec('/sbin/ifconfig').then(function(res) {
			if (res.code !== 0 || !res.stdout || res.stdout.trim() === '') {
				ui.addNotification(null, E('p', {}, _('Unable to get interface info: %s.').format(res.message)));
				return '';
			}

			var interfaces = res.stdout.match(/tailscale[0-9]+/g);
			if (!interfaces || interfaces.length === 0)
				return 'No interface online.';

			var promises = interfaces.map(function(name) {
				return fs.exec('/sbin/ifconfig', [name]);
			});

			return Promise.all(promises).then(function(results) {
				var data = results.map(function(res, index) {
					if (res.code !== 0 || !res.stdout || res.stdout.trim() === '') {
						ui.addNotification(null, E('p', {}, _('Unable to get interface %s info: %s.').format(interfaces[index], res.message)));
						return null;
					}
					return {
						name: interfaces[index],
						stdout: res.stdout.trim()
					};
				}).filter(Boolean);

				return data.map(function(info) {
					var lines = info.stdout.split('\n');
					var parsedInfo = {
						name: info.name
					};

					lines.forEach(function(line) {
						if (line.includes('inet addr:')) {
							parsedInfo.ipv4 = line.split('inet addr:')[1].trim().split(' ')[0];
						} else if (line.includes('inet6 addr:')) {
							parsedInfo.ipv6 = line.split('inet6 addr:')[1].trim().split('/')[0];
						} else if (line.includes('MTU:')) {
							parsedInfo.mtu = line.split('MTU:')[1].trim().split(' ')[0];
						} else if (line.includes('RX bytes:')) {
							var rxMatch = line.match(/RX bytes:\d+ \(([\d.]+\s*[a-zA-Z]+)\)/);
							if (rxMatch && rxMatch[1]) {
								parsedInfo.rxBytes = rxMatch[1];
							}
							var txMatch = line.match(/TX bytes:\d+ \(([\d.]+\s*[a-zA-Z]+)\)/);
							if (txMatch && txMatch[1]) {
								parsedInfo.txBytes = txMatch[1];
							}
						}
					});

					return parsedInfo;
				});
			});
		});
	},

	pollData: function (container) {
		poll.add(L.bind(function () {
			return this.load().then(L.bind(function (data) {
				dom.content(container, this.renderContent(data));
			}, this));
		}, this));
	},

	renderContent: function (data) {
		if (!Array.isArray(data)) {
			return E('div', {}, _('No interface online.'));
		}
		var rows = data.flatMap(function(interfaceData) {
			return [
				E('th', {class: 'th', colspan: '2'}, _('Network Interface Information')),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('Interface Name')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.name)
				]),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('IPv4 Address')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.ipv4)
				]),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('IPv6 Address')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.ipv6)
				]),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('MTU')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.mtu)
				]),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('Total Download')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.rxBytes)
				]),
				E('tr', {class: 'tr'}, [
					E('td', {class: 'td left', width: '25%'}, _('Total Upload')),
					E('td', {class: 'td left', width: '25%'}, interfaceData.txBytes)
				])
			];
		});

		return E('table', { 'class': 'table' }, rows);
	},

	render: function(data) {
		var content = E([], [
			E('h2', {class: 'content'}, _('Tailscale')),
			E('div', {class: 'cbi-map-descr'}, _('Tailscale is a cross-platform and easy to use virtual LAN.')),
			E('div')
		]);
		var container = content.lastElementChild;

		dom.content(container, this.renderContent(data));
		this.pollData(container);

		return content;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
