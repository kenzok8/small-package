'use strict';
'require view';
'require dom';
'require poll';
'require rpc';
'require ui';

var callGetTopology = rpc.declare({
	object: 'luci.fakemesh',
	method: 'get_topology',
	expect: { }
});

function formatSpeed(bytesPerSec) {
	var b = parseFloat(bytesPerSec) || 0;
	if (b >= 1048576)
		return (b / 1048576).toFixed(2) + ' MB/s';
	if (b >= 1024)
		return (b / 1024).toFixed(1) + ' KB/s';
	return b.toFixed(0) + ' B/s';
}

function formatBytes(bytes) {
	var b = parseFloat(bytes) || 0;
	if (b >= 1073741824)
		return (b / 1073741824).toFixed(2) + ' GB';
	if (b >= 1048576)
		return (b / 1048576).toFixed(1) + ' MB';
	if (b >= 1024)
		return (b / 1024).toFixed(1) + ' KB';
	return b.toFixed(0) + ' B';
}

function formatUptime(sec) {
	sec = parseInt(sec, 10) || 0;
	var d = Math.floor(sec / 86400);
	var h = Math.floor((sec % 86400) / 3600);
	var m = Math.floor((sec % 3600) / 60);
	var s = sec % 60;
	if (d > 0) return '%dd %dh %dm'.format(d, h, m);
	if (h > 0) return '%dh %dm %ds'.format(h, m, s);
	return '%dm %ds'.format(m, s);
}

function getIconSvg(type) {
	switch (type) {
		case 'phone':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>';
		case 'tablet':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>';
		case 'laptop':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="2" y1="20" x2="22" y2="20"/></svg>';
		case 'pc':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>';
		case 'tv':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="15" rx="2" ry="2"/><polyline points="17 2 12 7 7 2"/></svg>';
		case 'iot':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/><circle cx="12" cy="12" r="4"/></svg>';
		case 'router':
		case 'ap':
			return '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="14" width="20" height="8" rx="2"/><path d="M6 18h.01M10 18h.01"/><path d="M6 14V5M18 14V5M12 14V3"/></svg>';
		case 'cloud':
			return '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/></svg>';
		case 'vpn':
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>';
		case 'wifi':
			return '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/></svg>';
		case 'ethernet':
			return '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="7" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="17" cy="12" r="1.5"/></svg>';
		default:
			return '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>';
	}
}

return view.extend({
	data: null,
	filterBand: 'all',
	searchQuery: '',
	viewMode: 'minimap',
	selectedNodeId: 'ac',

	load: function() {
		return callGetTopology();
	},

	renderSummaryBar: function(summary, meshId) {
		summary = summary || {};

		var linkBadges = [];
		if (!summary.node_count || summary.node_count <= 1) {
			linkBadges.push(E('span', { 'class': 'badge badge-secondary' }, _('Single Gateway')));
		} else {
			if (summary.wireless_nodes && summary.wireless_nodes > 0) {
				linkBadges.push(E('span', { 'class': 'badge badge-5g' }, summary.wireless_nodes + ' ' + _('Wireless Mesh')));
			}
			if (summary.wired_nodes && summary.wired_nodes > 0) {
				linkBadges.push(E('span', { 'class': 'badge badge-wired' }, summary.wired_nodes + ' ' + _('Wired AP')));
			}
			if (summary.max_hops && summary.max_hops > 1) {
				linkBadges.push(E('span', { 'class': 'badge badge-hop' }, summary.max_hops + ' ' + _('Cascade Hops')));
			}
			if (linkBadges.length === 0) {
				linkBadges.push(E('span', { 'class': 'badge badge-primary' }, _('Mesh Connected')));
			}
		}

		return E('div', { 'class': 'fm-summary-bar' }, [
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('FakeMesh ID')),
				E('div', { 'class': 'fm-stat-val text-primary' }, meshId || _('Not Configured'))
			]),
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('Backhaul Links')),
				E('div', { 'class': 'fm-stat-val' }, linkBadges)
			]),
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('Mesh Nodes')),
				E('div', { 'class': 'fm-stat-val' }, [
					E('span', { 'class': 'text-success' }, String(summary.node_count || 1)),
					E('small', { 'class': 'fm-stat-sub' }, ' (' + (summary.online_agents || 0) + ' ' + _('Agents') + ')')
				])
			]),
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('Total Clients')),
				E('div', { 'class': 'fm-stat-val text-info' }, String(summary.client_count || 0))
			]),
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('5G / 2.4G / Wired / VPN')),
				E('div', { 'class': 'fm-stat-val' }, [
					E('span', { 'class': 'badge badge-5g' }, (summary.wifi_5g || 0) + ' 5G'),
					' ',
					E('span', { 'class': 'badge badge-2g' }, (summary.wifi_2g || 0) + ' 2.4G'),
					' ',
					E('span', { 'class': 'badge badge-wired' }, (summary.wired || 0) + ' ' + _('Wired')),
					(summary.vpn ? ' ' : ''),
					(summary.vpn ? E('span', { 'class': 'badge badge-vpn' }, summary.vpn + ' VPN') : E([]))
				])
			]),
			E('div', { 'class': 'fm-stat-box' }, [
				E('div', { 'class': 'fm-stat-title' }, _('Realtime Traffic')),
				E('div', { 'class': 'fm-stat-val' }, [
					E('span', { 'style': 'color:#28a745' }, '↓ ' + formatSpeed(summary.total_rx_speed || 0)),
					'  ',
					E('span', { 'style': 'color:#007bff' }, '↑ ' + formatSpeed(summary.total_tx_speed || 0))
				])
			])
		]);
	},

	renderToolbar: function() {
		var self = this;

		var viewButtons = [
			{ id: 'minimap', label: '🗺️ ' + _('Minimap View') },
			{ id: 'expanded', label: '🌲 ' + _('Expanded View') }
		].map(function(item) {
			return E('button', {
				'class': 'btn btn-sm ' + (self.viewMode === item.id ? 'btn-primary' : 'btn-secondary'),
				'click': function(ev) {
					self.viewMode = item.id;
					var p = ev.target.parentElement;
					p.querySelectorAll('button').forEach(function(b) { b.classList.remove('btn-primary'); b.classList.add('btn-secondary'); });
					ev.target.classList.remove('btn-secondary');
					ev.target.classList.add('btn-primary');
					self.updateCanvas();
				}
			}, item.label);
		});

		var searchInput = E('input', {
			'type': 'text',
			'class': 'cbi-input-text fm-search-input',
			'placeholder': _('Search by Hostname, IP, MAC...'),
			'value': self.searchQuery,
			'input': function(ev) {
				self.searchQuery = ev.target.value.toLowerCase().trim();
				self.updateCanvas();
			}
		});

		var bandButtons = [
			{ id: 'all', label: _('All Clients') },
			{ id: '5g', label: '5G' },
			{ id: '2g', label: '2.4G' },
			{ id: 'wired', label: _('Wired') },
			{ id: 'vpn', label: 'VPN' }
		].map(function(item) {
			return E('button', {
				'class': 'btn btn-sm ' + (self.filterBand === item.id ? 'btn-primary' : 'btn-secondary'),
				'click': function(ev) {
					self.filterBand = item.id;
					var p = ev.target.parentElement;
					p.querySelectorAll('button').forEach(function(b) { b.classList.remove('btn-primary'); b.classList.add('btn-secondary'); });
					ev.target.classList.remove('btn-secondary');
					ev.target.classList.add('btn-primary');
					self.updateCanvas();
				}
			}, item.label);
		});

		return E('div', { 'class': 'fm-toolbar' }, [
			E('div', { 'class': 'fm-toolbar-left' }, [
				E('div', { 'class': 'btn-group', 'style': 'margin-right: 12px;' }, viewButtons),
				searchInput
			]),
			E('div', { 'class': 'fm-toolbar-right btn-group' }, bandButtons)
		]);
	},

	showDetailModal: function(title, content) {
		ui.showModal(title, [
			content,
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn btn-primary',
					'click': ui.hideModal
				}, _('Close'))
			])
		]);
	},

	showNodeModal: function(node) {
		var isController = (node.role === 'controller') || (!node.role && node.id === 'ac');
		var isLocal = (this.data && this.data.current_node_id) ? (node.id === this.data.current_node_id) : false;
		var uplinkText = _('Root Gateway');
		if (node.uplink && node.uplink.type === 'wireless') {
			uplinkText = (node.uplink.band || '5G') + ' Mesh (' + (node.uplink.signal || 0) + ' dBm, ' + (node.uplink.rx_bitrate || 0) + ' Mbps)';
		} else if (node.uplink && node.uplink.type === 'wired') {
			uplinkText = _('Wired Ethernet') + ' (' + (node.uplink.port || 'LAN') + (node.uplink.speed ? (', ' + node.uplink.speed) : '') + ')';
		}

		var upstreamNodeName = isController ? (node.parent_name || _('Internet Gateway')) : (node.parent_name || node.parent_hostname || 'X-WRT');

		var body = E('div', { 'class': 'fm-modal-body' }, [
			E('table', { 'class': 'table' }, [
				isLocal ? E('tr', {}, [ E('td', { 'class': 'font-weight-bold text-success' }, _('Local Device')), E('td', {}, E('span', { 'class': 'badge badge-local' }, '📍 ' + _('Current Device (This Node)'))) ]) : E([]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Hostname')), E('td', {}, node.hostname || '-') ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Role')), E('td', {}, isController ? _('Controller (AC)') : (node.uplink && node.uplink.type === 'wired' ? _('Wired AP') : _('Agent Node'))) ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Upstream Node')), E('td', {}, upstreamNodeName) ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Cascade Hop')), E('td', {}, node.hop_count !== undefined ? (node.hop_count === 0 ? _('Root Node') : _('Hop %d').format(node.hop_count)) : '-') ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('IP Address')), E('td', {}, node.ip || '-') ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('MAC Address')), E('td', {}, node.mac || '-') ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Hardware Model')), E('td', {}, node.model || '-') ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Uptime')), E('td', {}, formatUptime(node.uptime)) ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Backhaul Link')), E('td', {}, uplinkText) ]),
				node.mesh_bssid ? E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Mesh BSSID')), E('td', {}, node.mesh_bssid) ]) : E([])
			]),
			(!isLocal && node.ip) ? E('div', { 'style': 'margin-top:15px; text-align:right;' }, [
				E('a', {
					'class': 'btn btn-success',
					'href': 'http://' + node.ip + '/',
					'target': '_blank'
				}, _('Open Web Admin') + ' ↗')
			]) : (isLocal ? E('div', { 'style': 'margin-top:15px; text-align:right;' }, [
				E('span', { 'class': 'badge badge-local', 'style': 'font-size:12px; padding:6px 12px;' }, '📍 ' + _('Current Device (This Node)'))
			]) : E([]))
		]);
		this.showDetailModal(_('Node Details: ') + (node.hostname || node.ip), body);
	},

	showClientModal: function(client, node) {
		var ipContent = [];
		if (client.ips && client.ips.length > 0) {
			client.ips.forEach(function(ip, idx) {
				ipContent.push(E('span', {
					'class': 'fm-ip-badge',
					'style': 'margin-right: 4px; font-size: 12px;'
				}, ip + (idx === 0 && client.ips.length > 1 ? ' (' + _('Primary') + ')' : '')));
			});
		} else {
			ipContent = [ E('span', { 'class': 'fm-ip-badge' }, client.ip || '-') ];
		}

		var mainRows = [
			E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Device Name')), E('td', {}, client.hostname || _('Unknown')) ]),
			E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('IPv4 Addresses')), E('td', {}, ipContent) ])
		];

		if (client.ip6 && client.ip6.length > 0) {
			var ip6Rows = client.ip6.map(function(ip6) {
				return E('div', { 'class': 'fm-ip6-badge', 'style': 'margin-bottom:3px; display:inline-block; font-size:11px;' }, ip6);
			});
			mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('IPv6 Addresses')), E('td', {}, ip6Rows) ]));
		}

		mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('MAC Address')), E('td', {}, E('span', { 'class': 'fm-ip-badge' }, client.mac || '-')) ]));
		mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Connected Node')), E('td', {}, (node ? (node.hostname || node.ip) : '-') + ' (' + (node ? node.ip : '-') + ')') ]));
		mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Access Mode')), E('td', {}, client.access_type === 'wireless' ? ((client.band || 'Wi-Fi') + ' (' + (client.ssid || '') + ')') : (client.access_type === 'vpn' ? ('VPN (' + (client.ifname || 'remote') + ')') : (_('Wired') + ' ' + (client.port || client.ifname || '')))) ]));

		if (client.access_type === 'wireless') {
			mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Wi-Fi Signal')), E('td', {}, (client.signal || 0) + ' dBm') ]));
		}
		if (client.idle_time !== undefined && client.idle_time !== null) {
			mainRows.push(E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Idle Time')), E('td', {}, client.idle_time + ' s') ]));
		}

		var body = E('div', { 'class': 'fm-modal-body' }, [
			E('table', { 'class': 'table' }, mainRows),
			E('table', { 'class': 'table', 'style': 'margin-top:10px;' }, [
				client.rate_rx ? E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('PHY Rate')), E('td', {}, 'RX: ' + client.rate_rx + ' Mbps / TX: ' + client.rate_tx + ' Mbps') ]) : E([]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Realtime Speed')), E('td', {}, '↓ ' + formatSpeed(client.rx_speed || 0) + '  ↑ ' + formatSpeed(client.tx_speed || 0)) ]),
				E('tr', {}, [ E('td', { 'class': 'font-weight-bold' }, _('Total Traffic')), E('td', {}, '↓ ' + formatBytes(client.rx_bytes || 0) + '  ↑ ' + formatBytes(client.tx_bytes || 0)) ])
			])
		]);
		this.showDetailModal(_('Client Details: ') + (client.hostname || client.mac), body);
	},

	renderClientCard: function(client, node) {
		var self = this;
		var q = self.searchQuery;
		if (q && q !== '') {
			var match = false;
			if (client.hostname && client.hostname.toLowerCase().indexOf(q) !== -1) match = true;
			if (client.mac && client.mac.toLowerCase().indexOf(q) !== -1) match = true;
			if (client.ip && client.ip.indexOf(q) !== -1) match = true;
			if (client.ips) {
				for (var i = 0; i < client.ips.length; i++) {
					if (client.ips[i].indexOf(q) !== -1) { match = true; break; }
				}
			}
			if (client.ip6) {
				for (var j = 0; j < client.ip6.length; j++) {
					if (client.ip6[j].toLowerCase().indexOf(q) !== -1) { match = true; break; }
				}
			}
			if (!match) return null;
		}

		if (self.filterBand === '5g' && (client.access_type !== 'wireless' || client.band !== '5G')) return null;
		if (self.filterBand === '2g' && (client.access_type !== 'wireless' || client.band !== '2.4G')) return null;
		if (self.filterBand === 'wired' && client.access_type !== 'wired') return null;
		if (self.filterBand === 'vpn' && client.access_type !== 'vpn') return null;

		var badgeClass = 'badge-wired';
		var badgeText = client.port || _('LAN');
		if (client.access_type === 'wireless') {
			badgeClass = client.band === '5G' ? 'badge-5g' : 'badge-2g';
			badgeText = client.band || 'Wi-Fi';
		} else if (client.access_type === 'vpn') {
			badgeClass = 'badge-vpn';
			badgeText = client.ifname ? ('VPN: ' + client.ifname) : 'VPN';
		}

		var ipsList = (client.ips && client.ips.length > 0) ? client.ips : (client.ip ? [client.ip] : []);
		var ipBadges = ipsList.map(function(ip) {
			return E('span', { 'class': 'fm-ip-badge' }, ip);
		});

		var ip6Badges = [];
		if (client.ip6 && client.ip6.length > 0) {
			client.ip6.forEach(function(ip6) {
				ip6Badges.push(E('span', { 'class': 'fm-ip6-badge', 'title': ip6 }, ip6));
			});
		}

		var subMeta = [
			E('span', { 'class': 'fm-client-mac' }, client.mac || '')
		];
		if (client.access_type === 'wireless' && client.signal) {
			subMeta.push(E('span', { 'class': 'fm-client-sig' }, client.signal + ' dBm'));
		}
		if (client.rx_speed > 0 || client.tx_speed > 0) {
			subMeta.push(E('span', { 'class': 'fm-client-speed' }, [
				E('span', { 'style': 'color:#28a745;' }, '↓ ' + formatSpeed(client.rx_speed)),
				' ',
				E('span', { 'style': 'color:#007bff;' }, '↑ ' + formatSpeed(client.tx_speed))
			]));
		}

		var card = E('div', {
			'class': 'fm-client-card',
			'click': function(ev) {
				ev.stopPropagation();
				self.showClientModal(client, node);
			}
		}, [
			E('div', { 'class': 'fm-client-icon', 'innerHTML': getIconSvg(client.icon || 'device') }),
			E('div', { 'class': 'fm-client-info' }, [
				E('div', { 'class': 'fm-client-top' }, [
					E('div', { 'class': 'fm-client-name', 'title': client.hostname || client.mac }, client.hostname || client.mac),
					E('span', { 'class': 'badge ' + badgeClass }, badgeText)
				]),
				ipBadges.length > 0 ? E('div', { 'class': 'fm-client-ip-row' }, ipBadges) : E([]),
				ip6Badges.length > 0 ? E('div', { 'class': 'fm-client-ip6-row' }, [
					E('span', { 'class': 'ip6-prefix' }, 'IPv6:'),
					E('div', { 'class': 'fm-ip6-list' }, ip6Badges)
				]) : E([]),
				E('div', { 'class': 'fm-client-sub' }, subMeta)
			])
		]);

		return card;
	},

	renderUplinkBadge: function(uplink) {
		if (!uplink || uplink.type === 'root') return E([]);

		if (uplink.type === 'wireless') {
			var sig = uplink.signal || 0;
			var sigClass = 'link-good';
			if (sig < -72) sigClass = 'link-poor';
			else if (sig < -62) sigClass = 'link-fair';

			return E('div', { 'class': 'fm-uplink-badge ' + sigClass }, [
				E('span', { 'class': 'fm-uplink-icon', 'innerHTML': getIconSvg('wifi') }),
				E('span', {}, [
					E('strong', {}, (uplink.band || '5G') + ' Mesh'),
					sig ? (' · ' + sig + ' dBm') : '',
					uplink.rx_bitrate ? (' · ' + uplink.rx_bitrate + ' Mbps') : ''
				])
			]);
		}

		// Wired uplink
		return E('div', { 'class': 'fm-uplink-badge link-wired' }, [
			E('span', { 'class': 'fm-uplink-icon', 'innerHTML': getIconSvg('ethernet') }),
			E('span', {}, [
				E('strong', {}, _('Wired Ethernet')),
				uplink.port ? (' · ' + uplink.port) : ' · LAN',
				uplink.speed ? (' · ' + uplink.speed) : ''
			])
		]);
	},

	renderNodeCard: function(node, isRoot, nodeClients) {
		var self = this;
		var isController = (node.role === 'controller') || (!node.role && node.id === 'ac');
		var isLocal = (self.data && self.data.current_node_id) ? (node.id === self.data.current_node_id) : false;
		var isWired = node.uplink && node.uplink.type === 'wired';
		var roleBadge = isController ? _('Controller (AC)') : (isWired ? _('Wired AP') : _('Agent Node'));

		var header = E('div', { 'class': 'fm-node-header' }, [
			E('div', { 'class': 'fm-node-icon ' + (isController ? 'icon-ac' : 'icon-agent'), 'innerHTML': getIconSvg(isController ? 'router' : (isWired ? 'router' : 'ap')) }),
			E('div', { 'class': 'fm-node-titles' }, [
				E('div', { 'class': 'fm-node-name', 'title': node.hostname }, node.hostname || node.ip),
				E('div', { 'class': 'fm-node-role' }, [
					E('span', { 'class': 'badge ' + (isController ? 'badge-controller' : (isWired ? 'badge-wired' : 'badge-agent')) }, roleBadge),
					(node.hop_count && node.hop_count > 0) ? E('span', { 'class': 'badge badge-hop' }, _('Hop %d').format(node.hop_count)) : E([]),
					isLocal ? E('span', { 'class': 'badge badge-local' }, '📍 ' + _('This Device')) : E([]),
					E('span', { 'class': 'fm-status-dot ' + (node.online ? 'online' : 'offline') })
				])
			])
		]);

		var upstreamLine = E('div', {}, [
			E('span', { 'class': 'text-muted' }, _('Upstream: ')),
			E('strong', {}, isRoot ? (node.parent_name || _('Internet Gateway')) : (node.parent_name || node.parent_hostname || 'X-WRT'))
		]);

		var meta = E('div', { 'class': 'fm-node-meta' }, [
			upstreamLine,
			E('div', {}, [ E('span', { 'class': 'text-muted' }, _('IP: ')), E('strong', {}, node.ip || '-') ]),
			E('div', {}, [ E('span', { 'class': 'text-muted' }, _('Model: ')), node.model || '-' ]),
			node.uptime ? E('div', {}, [ E('span', { 'class': 'text-muted' }, _('Uptime: ')), formatUptime(node.uptime) ]) : E([])
		]);

		var clientsContainer = E('div', { 'class': 'fm-clients-container' });
		var clientCount = 0;

		(nodeClients || []).forEach(function(c) {
			var card = self.renderClientCard(c, node);
			if (card) {
				clientsContainer.appendChild(card);
				clientCount++;
			}
		});

		var footer = E('div', { 'class': 'fm-node-footer' }, [
			E('span', { 'class': 'badge badge-secondary' }, clientCount + ' ' + _('Devices')),
			(!isLocal && node.ip) ? E('a', {
				'class': 'btn btn-xs btn-outline-primary',
				'href': 'http://' + node.ip + '/',
				'target': '_blank',
				'click': function(ev) { ev.stopPropagation(); }
			}, _('Manage') + ' ↗') : (isLocal ? E('span', { 'class': 'badge badge-local' }, '📍 ' + _('This Device')) : E([]))
		]);

		return E('div', {
			'class': 'fm-node-card ' + (isController ? 'controller-card' : 'agent-card') + (isLocal ? ' local-node' : ''),
			'click': function() {
				self.showNodeModal(node);
			}
		}, [
			header,
			meta,
			clientsContainer.children.length > 0 ? clientsContainer : E('div', { 'class': 'fm-clients-empty text-muted' }, _('No matching devices')),
			footer
		]);
	},

	renderNodeBranch: function(node, depth, clientsByNode) {
		var self = this;
		var isRoot = (depth === 0) || (node.role === 'controller') || (!node.role && node.id === 'ac');
		var nodeClients = clientsByNode[node.id] || [];
		var children = node.children || [];

		var uplinkElem = !isRoot ? E('div', { 'class': 'fm-uplink-connector-wrap' }, [
			E('div', { 'class': 'fm-connector-line' }),
			self.renderUplinkBadge(node.uplink),
			E('div', { 'class': 'fm-connector-line' })
		]) : E([]);

		var nodeCard = self.renderNodeCard(node, isRoot, nodeClients);

		var childrenElem = E([]);
		if (children.length > 0) {
			var childrenGrid = E('div', { 'class': 'fm-children-grid' });
			children.forEach(function(child) {
				childrenGrid.appendChild(self.renderNodeBranch(child, depth + 1, clientsByNode));
			});

			childrenElem = E('div', { 'class': 'fm-cascade-container' }, [
				E('div', { 'class': 'fm-cascade-header text-muted' }, [
					E('span', { 'class': 'badge badge-info' }, (depth + 1) + ' ' + _('Hop Cascade Nodes')),
					' ',
					E('small', {}, '(' + children.length + ' ' + _('Sub-nodes') + ')')
				]),
				childrenGrid
			]);
		}

		return E('div', { 'class': 'fm-node-branch depth-' + depth }, [
			uplinkElem,
			nodeCard,
			children.length > 0 ? E('div', { 'class': 'fm-connector-line' }) : E([]),
			childrenElem
		]);
	},

	renderMinimapNodeChip: function(node, isRoot, nodeClients, hasChildren) {
		var self = this;
		var isController = (node.role === 'controller') || (!node.role && node.id === 'ac');
		var isLocal = (self.data && self.data.current_node_id) ? (node.id === self.data.current_node_id) : false;
		var isWired = node.uplink && node.uplink.type === 'wired';
		var isSelected = (node.id === self.selectedNodeId);
		var roleBadge = isController ? _('Controller (AC)') : (isWired ? _('Wired AP') : _('Agent Node'));

		var header = E('div', { 'class': 'fm-mini-header' }, [
			E('div', { 'class': 'fm-mini-icon ' + (isController ? 'icon-ac' : 'icon-agent'), 'innerHTML': getIconSvg(isController ? 'router' : (isWired ? 'router' : 'ap')) }),
			E('div', { 'class': 'fm-mini-titles' }, [
				E('div', { 'class': 'fm-mini-name', 'title': node.hostname || node.ip }, node.hostname || node.ip),
				E('div', { 'class': 'fm-mini-ip-row' }, [
					E('span', { 'class': 'fm-ip-badge' }, node.ip || '-'),
					node.model ? E('span', { 'class': 'fm-mini-model', 'title': node.model }, node.model) : E([])
				])
			])
		]);

		var subBadges = E('div', { 'class': 'fm-mini-sub-badge' }, [
			E('span', { 'class': 'badge ' + (isController ? 'badge-controller' : (isWired ? 'badge-wired' : 'badge-agent')) }, roleBadge),
			(node.hop_count && node.hop_count > 0) ? E('span', { 'class': 'badge badge-hop' }, _('Hop %d').format(node.hop_count)) : E([]),
			isLocal ? E('span', { 'class': 'badge badge-local' }, '📍 ' + _('This Device')) : E([]),
			isSelected ? E('span', { 'class': 'badge badge-selected' }, _('Currently Selected')) : E([]),
			E('span', { 'class': 'fm-status-dot ' + (node.online ? 'online' : 'offline') })
		]);

		var upstreamText = isRoot ? (node.parent_name || _('Internet Gateway')) : (node.parent_name || node.parent_hostname || 'X-WRT');
		var upstreamLine = E('div', { 'class': 'fm-mini-upstream' }, [
			E('span', { 'class': 'text-muted' }, _('Upstream: ')),
			E('strong', { 'class': isRoot ? 'text-secondary' : 'text-primary' }, upstreamText)
		]);

		var footer = E('div', { 'class': 'fm-mini-footer' }, [
			E('span', { 'class': 'badge badge-info' }, (nodeClients ? nodeClients.length : 0) + ' ' + _('Devices')),
			E('span', { 'class': 'fm-mini-click-hint' }, _('Click to Inspect') + ' 🔍')
		]);

		var chipClasses = ['fm-minimap-node'];
		if (isLocal) chipClasses.push('local-node');
		if (isSelected) chipClasses.push('selected');
		if (isController) chipClasses.push('controller-chip');
		else chipClasses.push('agent-chip');
		if (hasChildren) chipClasses.push('has-children');

		return E('div', {
			'class': chipClasses.join(' '),
			'click': function(ev) {
				ev.stopPropagation();
				self.selectedNodeId = node.id;
				self.updateCanvas();
			}
		}, [
			header,
			subBadges,
			upstreamLine,
			footer
		]);
	},

	renderMinimapBranch: function(node, depth, clientsByNode) {
		var self = this;
		var isRoot = (depth === 0) || (node.role === 'controller') || (!node.role && node.id === 'ac');
		var nodeClients = clientsByNode[node.id] || [];
		var children = node.children || [];
		var hasChildren = children.length > 0;

		var nodeChip = self.renderMinimapNodeChip(node, isRoot, nodeClients, hasChildren);

		var childrenElem = E([]);
		if (hasChildren) {
			var stemDown = E('div', { 'class': 'fm-tree-stem-v stem-parent-down' });

			if (children.length === 1) {
				var child = children[0];
				var singleBranch = E('div', { 'class': 'fm-tree-single-branch' }, [
					self.renderUplinkBadge(child.uplink),
					E('div', { 'class': 'fm-tree-stem-v stem-child-in' }),
					self.renderMinimapBranch(child, depth + 1, clientsByNode)
				]);
				childrenElem = E('div', { 'class': 'fm-tree-children-container single-child' }, [
					stemDown,
					singleBranch
				]);
			} else {
				var forkCols = children.map(function(child) {
					return E('div', { 'class': 'fm-tree-fork-col' }, [
						E('div', { 'class': 'fm-tree-stem-v stem-fork-drop' }),
						self.renderUplinkBadge(child.uplink),
						E('div', { 'class': 'fm-tree-stem-v stem-child-in' }),
						self.renderMinimapBranch(child, depth + 1, clientsByNode)
					]);
				});

				var forkBar = E('div', { 'class': 'fm-tree-children-fork' }, forkCols);
				childrenElem = E('div', { 'class': 'fm-tree-children-container multi-child' }, [
					stemDown,
					forkBar
				]);
			}
		}

		return E('div', { 'class': 'fm-tree-node-wrapper depth-' + depth }, [
			nodeChip,
			childrenElem
		]);
	},

	renderFocusedNodePanel: function(data, clientsByNode) {
		var self = this;
		var nodes = data.nodes || [];
		var selectedNode = nodes.find(function(n) { return n.id === self.selectedNodeId; });
		if (!selectedNode && nodes.length > 0) {
			selectedNode = nodes[0];
			self.selectedNodeId = selectedNode.id;
		}
		if (!selectedNode) return E([]);

		var isController = (selectedNode.role === 'controller') || (!selectedNode.role && selectedNode.id === 'ac');
		var isLocal = (data && data.current_node_id) ? (selectedNode.id === data.current_node_id) : false;
		var isWired = selectedNode.uplink && selectedNode.uplink.type === 'wired';
		var roleBadge = isController ? _('Controller (AC)') : (isWired ? _('Wired AP') : _('Agent Node'));
		var allNodeClients = clientsByNode[selectedNode.id] || [];

		var filteredClients = allNodeClients.filter(function(c) {
			if (self.searchQuery && self.searchQuery !== '') {
				var q = self.searchQuery;
				var match = false;
				if (c.hostname && c.hostname.toLowerCase().indexOf(q) !== -1) match = true;
				if (c.mac && c.mac.toLowerCase().indexOf(q) !== -1) match = true;
				if (c.ip && c.ip.indexOf(q) !== -1) match = true;
				if (c.ips) {
					for (var i = 0; i < c.ips.length; i++) {
						if (c.ips[i].indexOf(q) !== -1) { match = true; break; }
					}
				}
				if (c.ip6) {
					for (var j = 0; j < c.ip6.length; j++) {
						if (c.ip6[j].toLowerCase().indexOf(q) !== -1) { match = true; break; }
					}
				}
				if (!match) return false;
			}
			if (self.filterBand === '5g' && (c.access_type !== 'wireless' || c.band !== '5G')) return false;
			if (self.filterBand === '2g' && (c.access_type !== 'wireless' || c.band !== '2.4G')) return false;
			if (self.filterBand === 'wired' && c.access_type !== 'wired') return false;
			if (self.filterBand === 'vpn' && c.access_type !== 'vpn') return false;
			return true;
		});

		var titleBar = E('div', { 'class': 'fm-focused-title-bar' }, [
			E('div', { 'class': 'fm-focused-title-left' }, [
				E('h3', { 'style': 'margin:0;' }, [
					_('Node Details & Connected Devices'),
					' : ',
					E('span', { 'class': 'text-primary' }, selectedNode.hostname || selectedNode.ip)
				]),
				E('small', { 'class': 'text-muted' }, _('Click any node in minimap above to switch inspection'))
			]),
			E('div', { 'class': 'fm-focused-actions btn-group' }, [
				E('button', {
					'class': 'btn btn-sm btn-info',
					'click': function() { self.showNodeModal(selectedNode); }
				}, _('View Full Node Specs') + ' 🔍'),
				isLocal ? E('span', {
					'class': 'badge badge-local',
					'style': 'align-self: center; font-size: 12px; padding: 6px 12px; margin-left: 6px;'
				}, '📍 ' + _('Current Device (This Node)')) :
				(selectedNode.ip ? E('a', {
					'class': 'btn btn-sm btn-success',
					'href': 'http://' + selectedNode.ip + '/',
					'target': '_blank'
				}, _('Open Web Admin') + ' ↗') : E([]))
			])
		]);

		var upstreamDisplay = E([]);
		if (isController) {
			upstreamDisplay = E('span', { 'class': 'badge badge-secondary' }, selectedNode.parent_name || _('Internet Gateway'));
		} else {
			upstreamDisplay = E('span', {
				'class': 'badge badge-primary',
				'style': 'cursor:pointer; font-size:12px;',
				'title': _('Click to inspect upstream node'),
				'click': function(ev) {
					ev.stopPropagation();
					if (selectedNode.parent_id) {
						self.selectedNodeId = selectedNode.parent_id;
						self.updateCanvas();
					}
				}
			}, (selectedNode.parent_name || selectedNode.parent_hostname || 'X-WRT') + ' ↗');
		}

		var heroGrid = E('div', { 'class': 'fm-focused-hero' }, [
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Role & Status')),
				E('div', { 'class': 'fm-hero-val' }, [
					E('span', { 'class': 'badge ' + (isController ? 'badge-controller' : (isWired ? 'badge-wired' : 'badge-agent')) }, roleBadge),
					' ',
					(selectedNode.hop_count && selectedNode.hop_count > 0) ? E('span', { 'class': 'badge badge-hop' }, _('Hop %d').format(selectedNode.hop_count)) : E([]),
					' ',
					isLocal ? E('span', { 'class': 'badge badge-local' }, '📍 ' + _('This Device')) : E([]),
					(isLocal ? ' ' : ''),
					E('span', { 'class': 'fm-status-dot ' + (selectedNode.online ? 'online' : 'offline') })
				])
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Upstream Node')),
				E('div', { 'class': 'fm-hero-val' }, [ upstreamDisplay ])
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Backhaul Link')),
				E('div', { 'class': 'fm-hero-val' }, [ self.renderUplinkBadge(selectedNode.uplink) ])
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('IP Address')),
				E('div', { 'class': 'fm-hero-val' }, selectedNode.ip || '-')
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('MAC Address')),
				E('div', { 'class': 'fm-hero-val' }, selectedNode.mac || '-')
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Hardware Model')),
				E('div', { 'class': 'fm-hero-val' }, selectedNode.model || '-')
			]),
			E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Uptime')),
				E('div', { 'class': 'fm-hero-val' }, formatUptime(selectedNode.uptime))
			]),
			selectedNode.mesh_bssid ? E('div', { 'class': 'fm-hero-item' }, [
				E('div', { 'class': 'fm-hero-label' }, _('Mesh BSSID')),
				E('div', { 'class': 'fm-hero-val' }, selectedNode.mesh_bssid)
			]) : E([])
		]);

		var terminalsHdr = E('div', { 'class': 'fm-focused-terminals-hdr' }, [
			E('h4', { 'style': 'margin:0;' }, [
				_('Connected Devices on this Node'),
				' ',
				E('span', { 'class': 'badge badge-info' }, filteredClients.length + ' / ' + allNodeClients.length)
			]),
			E('small', { 'class': 'text-muted' }, _('Click any client to view deep details'))
		]);

		var terminalsBody = E([]);
		if (filteredClients.length === 0) {
			var emptyMsg = (allNodeClients.length === 0) ? _('No terminal devices currently connected to this node.') : _('No matching devices');
			terminalsBody = E('div', { 'class': 'alert-message info' }, emptyMsg);
		} else {
			var clientCards = [];
			filteredClients.forEach(function(c) {
				var card = self.renderClientCard(c, selectedNode);
				if (card) clientCards.push(card);
			});
			terminalsBody = E('div', { 'class': 'fm-focused-clients-grid' }, clientCards);
		}

		return E('div', { 'class': 'fm-focused-panel' }, [
			titleBar,
			heroGrid,
			terminalsHdr,
			terminalsBody
		]);
	},

	buildNodeTree: function(nodes) {
		var nodeMap = Object.create(null);
		var root = null;
		nodes.forEach(function(n) {
			nodeMap[n.id] = n;
			n.children = [];
			if (n.role === 'controller' || (!n.role && n.id === 'ac')) root = n;
		});
		if (!root && nodes.length > 0) root = nodes[0];
		var parents = Object.create(null);
		nodes.forEach(function(n) {
			if (n !== root) parents[n.id] = nodeMap[n.parent_id] || root;
		});
		nodes.forEach(function(n) {
			if (n === root) return;
			var visited = Object.create(null);
			var current = n;
			while (current && current !== root) {
				if (visited[current.id]) {
					parents[n.id] = root;
					break;
				}
				visited[current.id] = true;
				current = parents[current.id];
			}
		});
		nodes.forEach(function(n) {
			if (parents[n.id]) parents[n.id].children.push(n);
		});
		return root;
	},

	updateCanvas: function() {
		var summaryEl = document.getElementById('fm-topology-summary');
		if (summaryEl && this.data) {
			dom.content(summaryEl, this.renderSummaryBar(this.data.summary, this.data.mesh_id));
		}
		var canvas = document.getElementById('fm-topology-canvas');
		if (!canvas || !this.data) return;
		dom.content(canvas, this.renderTree(this.data));
	},

	renderTree: function(data) {
		var self = this;
		var nodes = data.nodes || [];
		var clients = data.clients || [];

		var clientsByNode = {};
		clients.forEach(function(c) {
			var nid = c.node_id || 'ac';
			if (!clientsByNode[nid]) clientsByNode[nid] = [];
			clientsByNode[nid].push(c);
		});

		var root = self.buildNodeTree(nodes);
		if (!root) {
			return E('div', { 'class': 'alert-message warning' }, _('No FakeMesh nodes detected. Please verify FakeMesh configuration.'));
		}

		var upInfo = root.upstream || root.backhaul || {};
		var wanLabel = _('Internet Gateway');
		if (upInfo.wan_ip && upInfo.wan_ip !== '') {
			wanLabel += ' (' + upInfo.wan_ip + ')';
		}
		var wanBox = E('div', { 'class': 'fm-wan-box' }, [
			E('div', { 'class': 'fm-wan-icon', 'innerHTML': getIconSvg('cloud') }),
			E('div', { 'class': 'fm-wan-title' }, wanLabel)
		]);

		var wanLink = E('div', { 'class': 'fm-tree-link-v' });

		if (self.viewMode === 'expanded') {
			var rootBranch = self.renderNodeBranch(root, 0, clientsByNode);
			return E('div', { 'class': 'fm-topology-tree' }, [
				wanBox,
				wanLink,
				rootBranch
			]);
		}

		// Minimap View (Default)
		var minimapHint = E('div', { 'class': 'fm-minimap-hint text-muted' }, [
			E('span', {}, '💡'),
			' ',
			_('Click any node to zoom in and inspect connected terminals')
		]);

		var minimapBranch = self.renderMinimapBranch(root, 0, clientsByNode);

		var minimapContainer = E('div', { 'class': 'fm-minimap-container' }, [
			minimapHint,
			wanBox,
			wanLink,
			minimapBranch
		]);

		var focusedPanel = self.renderFocusedNodePanel(data, clientsByNode);

		return E('div', { 'class': 'fm-topology-minimap-view' }, [
			minimapContainer,
			focusedPanel
		]);
	},

	injectStyles: function() {
		if (document.getElementById('fakemesh-topology-styles')) return;
		var style = E('style', { 'id': 'fakemesh-topology-styles' }, `
			.fm-summary-bar {
				display: grid;
				grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
				gap: 12px;
				margin-bottom: 16px;
			}
			.fm-stat-box {
				background: var(--card-bg, #fff);
				border: 1px solid var(--border-color, rgba(0,0,0,0.08));
				border-radius: 8px;
				padding: 12px 16px;
				box-shadow: 0 2px 6px rgba(0,0,0,0.03);
			}
			.fm-stat-title {
				font-size: 12px;
				color: #6c757d;
				margin-bottom: 4px;
				text-transform: uppercase;
				letter-spacing: 0.5px;
			}
			.fm-stat-val {
				font-size: 16px;
				font-weight: 600;
				color: var(--text-color, #333);
				display: flex;
				align-items: center;
				flex-wrap: wrap;
				gap: 4px;
			}
			.fm-stat-sub {
				font-size: 12px;
				font-weight: normal;
				color: #6c757d;
			}
			.fm-toolbar {
				display: flex;
				flex-wrap: wrap;
				justify-content: space-between;
				align-items: center;
				gap: 12px;
				margin-bottom: 20px;
			}
			.fm-toolbar-left {
				display: flex;
				align-items: center;
				flex-wrap: wrap;
				gap: 10px;
			}
			.fm-search-input {
				min-width: 260px;
				border-radius: 6px;
			}
			.fm-topology-tree {
				display: flex;
				flex-direction: column;
				align-items: center;
				width: 100%;
				padding: 20px 0;
			}
			.fm-wan-box {
				display: flex;
				align-items: center;
				gap: 8px;
				background: #e9ecef;
				border: 1px solid #ced4da;
				padding: 8px 18px;
				border-radius: 20px;
				color: #495057;
				font-weight: 500;
			}
			.fm-tree-link-v {
				width: 2px;
				height: 22px;
				background: #0284c7;
				margin: 0 auto;
				flex-shrink: 0;
			}
			.fm-uplink-connector-wrap {
				display: flex;
				flex-direction: column;
				align-items: center;
				margin: 0;
				width: 100%;
			}
			.fm-connector-line {
				width: 2px;
				height: 16px;
				background: #0284c7;
				margin: 0 auto;
				flex-shrink: 0;
			}
			.fm-uplink-badge {
				display: inline-flex;
				align-items: center;
				gap: 6px;
				padding: 4px 14px;
				border-radius: 16px;
				font-size: 11px;
				font-weight: 600;
				background: #fff;
				border: 1.5px solid #0284c7;
				box-shadow: 0 2px 8px rgba(0,0,0,0.06);
				z-index: 2;
				flex-shrink: 0;
				margin: 0;
				transition: all 0.2s ease;
			}
			.fm-uplink-badge:hover {
				transform: scale(1.04);
				box-shadow: 0 4px 12px rgba(2,132,199,0.18);
			}
			.link-good {
				background: #e8f5e9;
				border: 1px solid #81c784;
				color: #2e7d32;
			}
			.link-fair {
				background: #fff8e1;
				border: 1px solid #ffd54f;
				color: #f57f17;
			}
			.link-poor {
				background: #ffebee;
				border: 1px solid #e57373;
				color: #c62828;
			}
			.link-wired {
				background: #e3f2fd;
				border: 1px solid #64b5f6;
				color: #1565c0;
			}
			.fm-node-branch {
				display: flex;
				flex-direction: column;
				align-items: center;
				width: 100%;
			}
			.fm-node-branch.depth-0 {
				max-width: 1100px;
			}
			.fm-cascade-container {
				margin-top: 16px;
				padding: 16px;
				border-top: 1px dashed rgba(0,0,0,0.15);
				border-left: 2px dashed rgba(0,123,255,0.25);
				background: rgba(0,0,0,0.01);
				border-radius: 12px;
				width: 100%;
			}
			.fm-cascade-header {
				font-size: 13px;
				font-weight: 600;
				margin-bottom: 12px;
				display: flex;
				align-items: center;
				gap: 6px;
			}
			.fm-children-grid {
				display: grid;
				grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
				gap: 20px;
				width: 100%;
			}
			.fm-node-card {
				background: var(--card-bg, #fff);
				border: 1px solid var(--border-color, rgba(0,0,0,0.12));
				border-radius: 12px;
				padding: 16px;
				cursor: pointer;
				transition: transform 0.2s ease, box-shadow 0.2s ease;
				box-shadow: 0 4px 12px rgba(0,0,0,0.04);
				width: 100%;
				max-width: 500px;
			}
			.fm-node-card:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 16px rgba(0,123,255,0.12);
			}
			.controller-card {
				border-color: #007bff !important;
				background: rgba(0, 123, 255, 0.03) !important;
			}
			.fm-node-header {
				display: flex;
				align-items: center;
				gap: 12px;
				margin-bottom: 10px;
			}
			.fm-node-icon {
				width: 44px;
				height: 44px;
				border-radius: 50%;
				display: flex;
				align-items: center;
				justify-content: center;
			}
			.icon-ac { background: #e7f1ff; color: #007bff; }
			.icon-agent { background: #e8f5e9; color: #28a745; }
			.fm-node-titles { flex: 1; }
			.fm-node-name {
				font-size: 16px;
				font-weight: 600;
				color: var(--text-color, #212529);
			}
			.fm-node-role {
				display: flex;
				align-items: center;
				gap: 6px;
				margin-top: 2px;
			}
			.fm-status-dot {
				width: 8px;
				height: 8px;
				border-radius: 50%;
				display: inline-block;
			}
			.fm-status-dot.online { background: #28a745; box-shadow: 0 0 6px #28a745; }
			.fm-status-dot.offline { background: #dc3545; }
			.fm-node-meta {
				font-size: 13px;
				line-height: 1.6;
				color: #495057;
				margin-bottom: 10px;
				padding-bottom: 8px;
				border-bottom: 1px solid rgba(0,0,0,0.05);
			}
			.fm-node-footer {
				display: flex;
				justify-content: space-between;
				align-items: center;
				margin-top: 10px;
			}
			.fm-clients-container {
				display: flex;
				flex-direction: column;
				gap: 8px;
				max-height: 380px;
				overflow-y: auto;
				padding-right: 4px;
			}
			.fm-clients-empty {
				font-size: 12px;
				text-align: center;
				padding: 10px 0;
			}
			.fm-client-card {
				display: flex;
				align-items: flex-start;
				gap: 10px;
				background: var(--item-bg, #f8f9fa);
				border: 1px solid var(--border-color, rgba(0,0,0,0.08));
				border-radius: 8px;
				padding: 10px;
				cursor: pointer;
				transition: background 0.15s ease, box-shadow 0.15s ease;
			}
			.fm-client-card:hover {
				background: #f0f7ff;
				border-color: #93c5fd;
				box-shadow: 0 2px 8px rgba(0,123,255,0.08);
			}
			.fm-client-icon {
				width: 36px;
				height: 36px;
				border-radius: 8px;
				background: #fff;
				color: #495057;
				display: flex;
				align-items: center;
				justify-content: center;
				border: 1px solid rgba(0,0,0,0.06);
				flex-shrink: 0;
				margin-top: 2px;
			}
			.fm-client-info {
				flex: 1;
				min-width: 0;
			}
			.fm-client-top {
				display: flex;
				align-items: center;
				justify-content: space-between;
				gap: 6px;
				margin-bottom: 2px;
			}
			.fm-client-name {
				font-size: 13px;
				font-weight: 600;
				color: var(--text-color, #1e293b);
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
			}
			.fm-client-ip-row {
				display: flex;
				flex-wrap: wrap;
				gap: 4px;
				margin-top: 3px;
			}
			.fm-ip-badge {
				background: #f1f5f9;
				color: #0f172a;
				font-family: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
				font-size: 11px;
				font-weight: 500;
				padding: 1px 6px;
				border-radius: 4px;
				border: 1px solid #cbd5e1;
				line-height: 1.3;
				display: inline-block;
			}
			.fm-client-ip6-row {
				display: flex;
				align-items: flex-start;
				gap: 4px;
				margin-top: 3px;
			}
			.ip6-prefix {
				font-size: 10px;
				color: #7c3aed;
				font-weight: 600;
				line-height: 1.5;
				flex-shrink: 0;
			}
			.fm-ip6-list {
				display: flex;
				flex-wrap: wrap;
				gap: 4px;
				min-width: 0;
			}
			.fm-ip6-badge {
				background: #f5f3ff;
				color: #6b21a8;
				font-family: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
				font-size: 10px;
				padding: 1px 5px;
				border-radius: 4px;
				border: 1px solid #ddd6fe;
				line-height: 1.3;
				max-width: 100%;
				overflow: hidden;
				text-overflow: ellipsis;
				white-space: nowrap;
				display: inline-block;
			}
			.fm-client-sub {
				display: flex;
				align-items: center;
				justify-content: space-between;
				gap: 6px;
				font-size: 11px;
				color: #64748b;
				margin-top: 4px;
				flex-wrap: wrap;
			}
			.fm-client-mac {
				font-family: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
				font-size: 10px;
				color: #94a3b8;
			}
			.fm-client-sig {
				font-size: 10px;
				color: #059669;
				font-weight: 600;
			}
			.fm-client-speed {
				font-size: 11px;
			}
			.badge-5g { background: #e0f2fe; color: #0369a1; font-weight: 600; font-size: 11px; }
			.badge-2g { background: #fef3c7; color: #b45309; font-weight: 600; font-size: 11px; }
			.badge-wired { background: #e5e7eb; color: #374151; font-weight: 600; font-size: 11px; }
			.badge-vpn { background: #f3e8ff; color: #7e22ce; font-weight: 600; font-size: 11px; }
			.badge-controller { background: #007bff; color: #fff; font-size: 11px; }
			.badge-agent { background: #28a745; color: #fff; font-size: 11px; }
			.badge-local { background: #10b981; color: #fff; font-size: 10px; font-weight: 600; }
			.badge-hop { background: #6c757d; color: #fff; font-size: 10px; padding: 2px 6px; border-radius: 4px; }
			.btn-xs { padding: 2px 6px; font-size: 11px; border-radius: 4px; }

			/* Minimap & Focused Panel Styles */
			.fm-topology-minimap-view {
				width: 100%;
				display: flex;
				flex-direction: column;
				align-items: center;
			}
			.fm-minimap-container {
				width: 100%;
				display: flex;
				flex-direction: column;
				align-items: center;
				padding: 24px 16px;
				background: var(--card-bg, #fff);
				border: 1px solid var(--border-color, rgba(0,0,0,0.08));
				border-radius: 12px;
				box-shadow: 0 2px 8px rgba(0,0,0,0.03);
				overflow-x: auto;
			}
			.fm-minimap-hint {
				font-size: 13px;
				color: #475569;
				margin-bottom: 16px;
				display: flex;
				align-items: center;
				gap: 6px;
				background: #f8fafc;
				padding: 6px 14px;
				border-radius: 20px;
				border: 1px solid #e2e8f0;
			}

			/* Connected Tree Structure */
			.fm-tree-node-wrapper {
				display: flex;
				flex-direction: column;
				align-items: center;
				position: relative;
			}
			.fm-tree-stem-v {
				width: 2px;
				background: #0284c7;
				margin: 0 auto;
				flex-shrink: 0;
			}
			.stem-parent-down {
				height: 20px;
			}
			.stem-fork-drop {
				height: 16px;
			}
			.stem-child-in {
				height: 16px;
			}

			.fm-tree-children-container {
				display: flex;
				flex-direction: column;
				align-items: center;
				width: 100%;
			}
			.fm-tree-children-container.single-child {
				width: auto;
			}
			.fm-tree-single-branch {
				display: flex;
				flex-direction: column;
				align-items: center;
			}

			.fm-tree-children-fork {
				display: flex;
				justify-content: center;
				align-items: flex-start;
				position: relative;
				width: auto;
				margin: 0 auto;
			}
			.fm-tree-fork-col {
				display: flex;
				flex-direction: column;
				align-items: center;
				position: relative;
				padding: 0 16px;
				box-sizing: border-box;
			}
			.fm-tree-fork-col::before {
				content: '';
				position: absolute;
				top: 0;
				left: 0;
				width: 50%;
				height: 2px;
				background: #0284c7;
			}
			.fm-tree-fork-col::after {
				content: '';
				position: absolute;
				top: 0;
				right: 0;
				width: 50%;
				height: 2px;
				background: #0284c7;
			}
			.fm-tree-fork-col:first-child::before {
				display: none;
			}
			.fm-tree-fork-col:last-child::after {
				display: none;
			}

			/* Minimap Node Chip */
			.fm-minimap-node {
				position: relative;
				background: var(--card-bg, #fff);
				border: 2px solid var(--border-color, rgba(0,0,0,0.12));
				border-radius: 12px;
				padding: 12px 14px;
				cursor: pointer;
				transition: all 0.2s ease;
				box-shadow: 0 2px 8px rgba(0,0,0,0.04);
				width: 280px;
				box-sizing: border-box;
				user-select: none;
				z-index: 2;
			}
			.fm-minimap-node:hover {
				transform: translateY(-2px);
				border-color: #0284c7;
				box-shadow: 0 6px 16px rgba(2,132,199,0.18);
			}
			.fm-minimap-node.selected {
				border-color: #0284c7 !important;
				background: #f0f9ff !important;
				box-shadow: 0 0 0 3px rgba(2,132,199,0.25), 0 6px 16px rgba(2,132,199,0.15) !important;
			}
			.fm-minimap-node.local-node {
				border-color: #10b981;
			}
			.fm-minimap-node.local-node:not(.selected) {
				border-color: #10b981;
				box-shadow: 0 0 0 2px rgba(16,185,129,0.3), 0 4px 12px rgba(0,0,0,0.06);
			}
			.fm-node-card.local-node {
				border: 2px solid #10b981;
				box-shadow: 0 0 0 2px rgba(16,185,129,0.25), 0 4px 12px rgba(0,0,0,0.05);
			}
			.fm-minimap-node::before {
				content: '';
				position: absolute;
				top: -5px;
				left: 50%;
				transform: translateX(-50%);
				width: 8px;
				height: 8px;
				border-radius: 50%;
				background: #0284c7;
				border: 2px solid #fff;
				box-shadow: 0 0 0 1px rgba(2,132,199,0.4);
				z-index: 3;
			}
			.fm-minimap-node.has-children::after {
				content: '';
				position: absolute;
				bottom: -5px;
				left: 50%;
				transform: translateX(-50%);
				width: 8px;
				height: 8px;
				border-radius: 50%;
				background: #0284c7;
				border: 2px solid #fff;
				box-shadow: 0 0 0 1px rgba(2,132,199,0.4);
				z-index: 3;
			}
			.badge-selected {
				background: #0284c7;
				color: #fff;
				font-size: 10px;
			}
			.fm-mini-header {
				display: flex;
				align-items: center;
				gap: 10px;
				margin-bottom: 6px;
			}
			.fm-mini-icon {
				width: 36px;
				height: 36px;
				border-radius: 8px;
				display: flex;
				align-items: center;
				justify-content: center;
				flex-shrink: 0;
			}
			.fm-mini-titles {
				flex: 1;
				min-width: 0;
			}
			.fm-mini-name {
				font-size: 14px;
				font-weight: 600;
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
			}
			.fm-mini-ip-row {
				display: flex;
				align-items: center;
				gap: 6px;
				margin-top: 3px;
			}
			.fm-mini-model {
				font-size: 11px;
				color: #64748b;
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
				max-width: 140px;
			}
			.fm-mini-sub-badge {
				display: flex;
				align-items: center;
				gap: 4px;
				margin-top: 4px;
				flex-wrap: wrap;
			}
			.fm-mini-upstream {
				font-size: 11px;
				color: #475569;
				margin: 6px 0;
				padding: 3px 8px;
				background: rgba(0,0,0,0.03);
				border-radius: 4px;
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
			}
			.fm-mini-footer {
				display: flex;
				align-items: center;
				justify-content: space-between;
				margin-top: 6px;
			}
			.fm-mini-click-hint {
				font-size: 11px;
				color: #0284c7;
				font-weight: 500;
			}
			.fm-focused-panel {
				width: 100%;
				background: var(--card-bg, #fff);
				border: 1px solid var(--border-color, rgba(0,0,0,0.12));
				border-radius: 12px;
				padding: 20px;
				box-shadow: 0 4px 16px rgba(0,0,0,0.05);
				margin-top: 20px;
			}
			.fm-focused-title-bar {
				display: flex;
				align-items: center;
				justify-content: space-between;
				margin-bottom: 16px;
				padding-bottom: 12px;
				border-bottom: 1px solid rgba(0,0,0,0.08);
				flex-wrap: wrap;
				gap: 10px;
			}
			.fm-focused-hero {
				display: grid;
				grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
				gap: 12px;
				background: #f8fafc;
				border: 1px solid #e2e8f0;
				border-radius: 8px;
				padding: 14px 18px;
				margin-bottom: 20px;
			}
			.fm-hero-item {
				font-size: 13px;
				color: #334155;
			}
			.fm-hero-label {
				font-size: 11px;
				color: #64748b;
				text-transform: uppercase;
				letter-spacing: 0.5px;
				margin-bottom: 2px;
			}
			.fm-hero-val {
				font-weight: 600;
				color: #0f172a;
			}
			.fm-focused-terminals-hdr {
				display: flex;
				align-items: center;
				justify-content: space-between;
				margin-bottom: 14px;
				padding-bottom: 8px;
				border-bottom: 1px solid rgba(0,0,0,0.05);
			}
			.fm-focused-clients-grid {
				display: grid;
				grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
				gap: 14px;
				width: 100%;
			}
		`);
		document.head.appendChild(style);
	},

	pollData: function() {
		var self = this;
		poll.add(function() {
			return callGetTopology().then(function(topo) {
				self.data = topo || {};
				self.updateCanvas();
			});
		}, 5);
	},

	render: function(topoData) {
		this.injectStyles();
		this.data = topoData || {};
		if (this.data.current_node_id) {
			this.selectedNodeId = this.data.current_node_id;
		}
		this.pollData();

		var summaryBar = E('div', { 'id': 'fm-topology-summary' }, [
			this.renderSummaryBar(this.data.summary, this.data.mesh_id)
		]);
		var toolbar = this.renderToolbar();
		var canvas = E('div', { 'id': 'fm-topology-canvas' }, [
			this.renderTree(this.data)
		]);

		return E('div', { 'class': 'cbi-map' }, [
			E('h2', {}, _('FakeMesh Network Topology')),
			E('div', { 'class': 'cbi-map-descr' }, _('Visual hierarchy of FakeMesh controller, agent nodes, and connected terminal devices.')),
			summaryBar,
			toolbar,
			canvas
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
