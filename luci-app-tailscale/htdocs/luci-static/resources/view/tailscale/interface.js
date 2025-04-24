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

function formatBytes(bytes, decimals = 2) {
	if (bytes === 0) return '0 Bytes';
	const k = 1024;
	const dm = decimals < 0 ? 0 : decimals;
	const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
	const i = Math.floor(Math.log(bytes) / Math.log(k));
	return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

return view.extend({
	load: function() {
		return fs.exec('/sbin/ip', ['-s', '-j', 'ad']).then(function(res) {
			if (res.code !== 0 || !res.stdout || res.stdout.trim() === '') {
				ui.addNotification(null, E('p', {}, _('Unable to get interface info: %s.').format(res.message)));
				return [];
			}

			try {
				const interfaces = JSON.parse(res.stdout);
				const tailscaleInterfaces = interfaces.filter(iface => iface.ifname.match(/tailscale[0-9]+/));

				return tailscaleInterfaces.map(iface => {
					const parsedInfo = {
						name: iface.ifname
					};

					const addr_info = iface.addr_info || [];
					addr_info.forEach(addr => {
						if (addr.family === 'inet') {
							parsedInfo.ipv4 = addr.local;
						} else if (addr.family === 'inet6') {
							parsedInfo.ipv6 = addr.local;
						}
					});

					parsedInfo.mtu = iface.mtu;
					parsedInfo.rxBytes = formatBytes(iface.stats64.rx.bytes);
					parsedInfo.txBytes = formatBytes(iface.stats64.tx.bytes);

					return parsedInfo;
				});
			} catch (e) {
				ui.addNotification(null, E('p', {}, _('Error parsing interface info: %s.').format(e.message)));
				return [];
			}
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
		const rows = [
			E('th', { class: 'th', colspan: '2' }, _('Network Interface Information'))
		];
		data.forEach(interfaceData => {
			rows.push(
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('Interface Name')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.name)
				]),
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('IPv4 Address')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.ipv4)
				]),
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('IPv6 Address')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.ipv6)
				]),
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('MTU')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.mtu)
				]),
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('Total Download')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.rxBytes)
				]),
				E('tr', { class: 'tr' }, [
					E('td', { class: 'td left', width: '25%' }, _('Total Upload')),
					E('td', { class: 'td left', width: '25%' }, interfaceData.txBytes)
				])
			);
		});

		return E('table', { 'class': 'table' }, rows);
	},

	render: function(data) {
		const content = E([], [
			E('h2', { class: 'content' }, _('Tailscale')),
			E('div', { class: 'cbi-map-descr' }, _('Tailscale is a cross-platform and easy to use virtual LAN.')),
			E('div')
		]);
		const container = content.lastElementChild;

		dom.content(container, this.renderContent(data));
		this.pollData(container);

		return content;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
