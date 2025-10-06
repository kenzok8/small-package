'use strict';
'require view';
'require fs';
'require ui';
'require poll';
'require rpc';
'require dom';
'require uci';

// Global variables from original display.js
var chartRegistry = {};
var hostNames = {}; // mac => hostname
var hostInfo = {}; // ip => mac
var hostNameMacSectionId = "";
var isPaused = false;
var lastUpdated = null;

// Line chart variables (from l7.js)
var downloadLineChart = {}, uploadLineChart = {};
var lineCategories = { ipv4: [], ipv6: [], mac: [] };
var downloadSeriesData = { ipv4: {}, ipv6: {}, mac: {} };
var uploadSeriesData = { ipv4: {}, ipv6: {}, mac: {} };

// Color palette for chart series
var colorPalette = ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#3ba272', '#fc8452', '#9a60b4', '#ea7ccc'];

var resizeListenerAdded = false;

// Pre-fill with 60 empty points for a smooth start
['ipv4', 'ipv6', 'mac'].forEach(function(type) {
	for (var i = 0; i < 60; i++) {
		lineCategories[type].push('');
	}
});

// Helper to convert hex to rgba (from l7.js)
function hexToRgba(hex, opacity) {
	var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
	return result ? 
		'rgba(' + parseInt(result[1], 16) + ', ' + parseInt(result[2], 16) + ', ' + parseInt(result[3], 16) + ', ' + opacity + ')' :
		null;
};

return view.extend({
	// --- Core Data Logic from display.js ---

	loadHostNames: async function() {
		try {
			await uci.sections('hostnames', "hostname", function (params) {
				hostNameMacSectionId = params['.name'];
				for (var key in params) {
					if (key.startsWith('.')) continue;
					var macAddr = key.split('_').join(':');
					hostNames[macAddr] = params[key];
				}
			});

			const dhcpLeases = await fs.exec_direct('/usr/bin/awk', ['-F', ' ', '{print $2, $3, $4}', '/tmp/dhcp.leases'], 'text');
			dhcpLeases.split('\n').forEach(function(line) {
				if (line === '') return;
				const [mac, ip, hostname] = line.split(' ');
				if (!hostNames.hasOwnProperty(mac)) {
					hostNames[mac] = hostname;
				}
			});

			const arp = await fs.exec_direct('/usr/bin/awk', ['-F', ' ', '{print $1, $4}', '/proc/net/arp'], 'text');
			arp.split('\n').forEach(function(line, i) {
				if (i === 0 || line === '') return;
				const [ip, mac] = line.split(' ');
				hostInfo[ip] = mac;
			});

		} catch (e) {
			console.error('Error getting host names:', e);
		}
	},

	loadHostSpeedData: async function() {
		var self = this;
		try {
			const results = await Promise.all([
				fs.exec_direct('/usr/bin/aw-bpfctl', ['ipv4', 'json'], 'json'),
				fs.exec_direct('/usr/bin/aw-bpfctl', ['ipv6', 'json'], 'json'),
				fs.exec_direct('/usr/bin/aw-bpfctl', ['mac',  'json'], 'json')
			]);

			const defaultData = {status: "success", data: []};
			const ipv4Data = results[0] || defaultData;
			const ipv6Data = results[1] || defaultData;
			const macData  = results[2] || defaultData;
			
			ipv4Data.data.forEach(function(item) {
				const mac = hostInfo[item.ip];
				if (mac) {
					item.mac = mac;
					item.hostname = hostNames[mac];
				}
			});
			macData.data.forEach(function(item) {
				const mac = item.mac;
				if (mac) {
					item.hostname = hostNames[mac];
				}
			});

			self.renderHostSpeed(ipv4Data, "ipv4");
			self.renderHostSpeed(ipv6Data, "ipv6");
			self.renderHostSpeed(macData, "mac");

			lastUpdated = new Date();
			var timestampEl = document.getElementById('display-last-updated');
			if (timestampEl) {
				timestampEl.textContent = _('Last updated: %s').format(lastUpdated.toLocaleTimeString());
			}

		} catch (e) {
			console.error('Error polling data:', e);
		}
	},

	pollData: function() {
		poll.add(L.bind(async function() {
			if (isPaused) return;
			await this.loadHostNames();
			await this.loadHostSpeedData();
		}, this), 5);
	},

	// --- UI Rendering and Interaction (New structure based on l7.js) ---

	pie: function(id, data, valueFormatter) {
		var total = data.reduce(function(n, d) { return n + d.value; }, 0);
		data.sort(function(a, b) { return b.value - a.value; });

		if (total === 0) {
			data = [{ value: 1, color: '#cccccc', name: _('no traffic') }];
		}

		data.forEach(function(d, i) {
			if (!d.color) {
				var hue = (i * 137.508) % 360;
				d.color = 'hsl(' + hue + ', 75%, 55%)';
			}
		});

		var option = {
			tooltip: {
				trigger: 'item',
				formatter: function(params) {
					if (valueFormatter) {
						// 将 ECharts params 对象转换为自定义格式
						return valueFormatter({
							name: params.name,
							value: params.value,
							percent: params.percent.toFixed(2)
						});
					}
					return params.name + ': ' + params.value + ' (' + params.percent.toFixed(2) + '%)';
				}
			},
			series: [{
				type: 'pie',
				radius: ['25%', '80%'],
				avoidLabelOverlap: false,
				padAngle: 10,
				itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
				label: { show: false, position: 'center' },
				emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
				labelLine: { show: false },
				data: data.map(function(d) {
					return { value: d.value, name: d.label || d.name, itemStyle: { color: d.color } };
				})
			}]
		};

		var dom = typeof id === 'string' ? document.getElementById(id) : id;
		if (!chartRegistry[id]) {
			chartRegistry[id] = echarts.init(dom);
		}
		chartRegistry[id].setOption(option, true);
		return chartRegistry[id];
	},

	updateStackedLineCharts: function(type, perHostDownload, perHostUpload) {
		var now = new Date().toLocaleTimeString();
		lineCategories[type].push(now);
		lineCategories[type].shift();

		var processChartData = function(seriesData, perHostData) {
			var allHosts = Object.keys(seriesData);
			Object.keys(perHostData).forEach(function(host) {
				if (allHosts.indexOf(host) === -1) {
					allHosts.push(host);
				}
			});

			allHosts.forEach(function(host) {
				if (!seriesData[host]) {
					seriesData[host] = Array(59).fill(0);
				}
				var rate = perHostData[host] || 0;
				seriesData[host].push(rate);
				seriesData[host].shift();
			});

			return Object.keys(seriesData).map(function(host, index) {
				var color = colorPalette[index % colorPalette.length];
				return {
					name: host,
					type: 'line',
					stack: 'Total',
					smooth: true,
					lineStyle: { width: 1, color: color },
					showSymbol: false,
					itemStyle: { color: color },
					areaStyle: {
						color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
							{ offset: 0, color: hexToRgba(color, 0.5) },
							{ offset: 1, color: hexToRgba(color, 0) }
						])
					},
					data: seriesData[host]
				};
			});
		};

		var downloadChartSeries = processChartData(downloadSeriesData[type], perHostDownload);
		var uploadChartSeries = processChartData(uploadSeriesData[type], perHostUpload);

		var legendData = downloadChartSeries.map(function(s) { return s.name; });

		if (downloadLineChart[type]) {
			downloadLineChart[type].setOption({
				legend: { data: legendData, type: 'scroll', top: 0, left: 'center' },
				series: downloadChartSeries,
				xAxis: { data: lineCategories[type] }
			});
		}

		if (uploadLineChart[type]) {
			uploadLineChart[type].setOption({
				legend: { data: legendData, type: 'scroll', top: 0, left: 'center' },
				series: uploadChartSeries,
				xAxis: { data: lineCategories[type] }
			});
		}
	},

	renderHostSpeed: function(data, type) {
		if (!data || data.status !== "success" || !Array.isArray(data.data)) return;

		var rows = [];
		var txRateData = [], rxRateData = [];
		var txVolumeData = [], rxVolumeData = [];
		var tx_rate_total = 0, rx_rate_total = 0;
		var tx_bytes_total = 0, rx_bytes_total = 0;
		var perHostTxRate = {};
		var perHostRxRate = {};

		data.data.forEach(item => {
			if (!item || !item.incoming || !item.outgoing) return;

			var host = item.ip || item.mac || '';
			var hostname = item.hostname || hostNames[item.mac] || '';
			var displayName = hostname || host;
			
			// 判断连接是否活跃
			var isActive = item.incoming.rate > 0 || item.outgoing.rate > 0;
			var activityIcon = isActive ? '🟢' : '⚪';

			rows.push([
				E('span', { 'class': 'host-cell' }, [
					E('span', { 'class': 'activity-indicator', 'title': isActive ? _('Active') : _('Inactive') }, activityIcon),
					E('span', {}, ' ' + host)
				]),
				E('span', { 'class': 'hostname-cell' }, [
					E('span', { 'class': 'icon' }, hostname ? '👤' : '❓'),
					E('span', {}, ' ' + (hostname || _('Unknown')))
				]),
				E('span', { 'class': 'speed-cell download' }, [
					E('span', { 'class': 'data-value' }, '%1024.2mBps'.format(item.incoming.rate))
				]),
				E('span', { 'class': 'volume-cell download' }, [
					E('span', { 'class': 'data-value' }, '%1024.2mB'.format(item.incoming.total_bytes))
				]),
				E('span', { 'class': 'packet-cell download' }, [
					E('span', { 'class': 'data-value' }, '%1000.2mP'.format(item.incoming.total_packets))
				]),
				E('span', { 'class': 'speed-cell upload' }, [
					E('span', { 'class': 'data-value' }, '%1024.2mBps'.format(item.outgoing.rate))
				]),
				E('span', { 'class': 'volume-cell upload' }, [
					E('span', { 'class': 'data-value' }, '%1024.2mB'.format(item.outgoing.total_bytes))
				]),
				E('span', { 'class': 'packet-cell upload' }, [
					E('span', { 'class': 'data-value' }, '%1000.2mP'.format(item.outgoing.total_packets))
				]),
				E('div', { 'class': 'button-container' }, [
					E('button', {
						'class': 'btn cbi-button cbi-button-edit',
						'style': 'margin-right: 5px;',
						'click': ui.createHandlerFn(this, () => this.handleEditSpeed(host, item.mac, hostname, type))
					}, [
						E('span', { 'class': 'btn-icon' }, '✏️'),
						E('span', {}, ' ' + _('Edit'))
					]),
					E('button', {
						'class': 'btn cbi-button cbi-button-remove',
						'click': ui.createHandlerFn(this, () => this.handleDeleteHost(host, type))
					}, [
						E('span', { 'class': 'btn-icon' }, '🗑️'),
						E('span', {}, ' ' + _('Delete'))
					])
				])
			]);
			rx_rate_total += item.outgoing.rate;
			tx_rate_total += item.incoming.rate;
			rx_bytes_total += item.outgoing.total_bytes;
			tx_bytes_total += item.incoming.total_bytes;

			rxRateData.push({ value: item.outgoing.rate, label: displayName });
			txRateData.push({ value: item.incoming.rate, label: displayName });
			rxVolumeData.push({ value: item.outgoing.total_bytes, label: displayName });
			txVolumeData.push({ value: item.incoming.total_bytes, label: displayName });

			perHostTxRate[displayName] = (perHostTxRate[displayName] || 0) + item.incoming.rate;
			perHostRxRate[displayName] = (perHostRxRate[displayName] || 0) + item.outgoing.rate;
		});

		this.updateStackedLineCharts(type, perHostTxRate, perHostRxRate);

		var table = document.getElementById(type + '-speed-data');
		cbi_update_table(table, rows, E('em', _('No data recorded yet.')));

		this.pie(type + '-tx-rate-pie', txRateData, (p) => `${p.name}: ${'%1024.2mBps'.format(p.value)} (${p.percent}%)`);
		this.pie(type + '-rx-rate-pie', rxRateData, (p) => `${p.name}: ${'%1024.2mBps'.format(p.value)} (${p.percent}%)`);
		this.pie(type + '-tx-volume-pie', txVolumeData, (p) => `${p.name}: ${'%1024.2mB'.format(p.value)} (${p.percent}%)`);
		this.pie(type + '-rx-volume-pie', rxVolumeData, (p) => `${p.name}: ${'%1024.2mB'.format(p.value)} (${p.percent}%)`);

		var hostEl = document.getElementById(type + '-host-val');
		if (hostEl) hostEl.textContent = data.data.length;

		var txRateEl = document.getElementById(type + '-tx-rate-val');
		if (txRateEl) txRateEl.textContent = '%1024.2mBps'.format(tx_rate_total);

		var rxRateEl = document.getElementById(type + '-rx-rate-val');
		if (rxRateEl) rxRateEl.textContent = '%1024.2mBps'.format(rx_rate_total);

		var txVolEl = document.getElementById(type + '-tx-volume-val');
		if (txVolEl) txVolEl.textContent = '%1024.2mB'.format(tx_bytes_total);

		var rxVolEl = document.getElementById(type + '-rx-volume-val');
		if (rxVolEl) rxVolEl.textContent = '%1024.2mB'.format(rx_bytes_total);
	},

	// --- Interaction Handlers from display.js ---

	handleDeleteHost: function(host, type) {
		ui.showModal(_('Delete Host'), [
			E('p', _('Are you sure you want to delete this host?')),
			E('div', { 'class': 'right' }, [
				E('button', { 'class': 'btn', 'click': ui.hideModal }, _('Cancel')),
				E('button', { 'class': 'btn cbi-button-negative', 'click': ui.createHandlerFn(this, async () => {
					try {
						await fs.exec_direct('/usr/bin/aw-bpfctl', [type, 'del', host], 'text');
						this.loadHostSpeedData();
						ui.hideModal();
					} catch (e) {
						ui.addNotification(null, E('p', _('Error: ') + e.message));
						ui.hideModal();
					}
				})}, _('Delete'))
			])
		]);
	},

	handleEditSpeed: function(host, mac, hostname, type) {
		fs.exec_direct('/usr/bin/aw-bpfctl', [type, 'json'], 'json').then(L.bind(res => {
			let rate_limit_dl = 0, rate_limit_ul = 0;
			if (res && res.status === 'success' && Array.isArray(res.data)) {
				const item = res.data.find(d => (d.ip === host || d.mac === host));
				if (item) {
					rate_limit_dl = (item.incoming.incoming_rate_limit || 0) / 1024 / 1024;
					rate_limit_ul = (item.outgoing.outgoing_rate_limit || 0) / 1024 / 1024;
				}
			}
			this.displaySpeedLimitDialog(host, mac, hostname, type, rate_limit_dl, rate_limit_ul);
		}, this)).catch(e => {
			console.error('Error getting speed limit:', e);
			this.displaySpeedLimitDialog(host, mac, hostname, type, 0, 0);
		});
	},
	
	displaySpeedLimitDialog: function(host, mac, hostname, type, dl, ul) {
		const inputDom = E('input', { type: 'text', id: 'host-name', class: 'cbi-input-text', value: hostname, disabled: !mac });

		ui.showModal(_('Edit Speed Limit'), [
			E('div', { 'class': 'form-group' }, [ E('label', { 'class': 'form-label' }, _('Host')), E('span',{}, host) ]),
			E('div', { 'class': 'form-group' }, [ E('label', { 'class': 'form-label' }, _('Hostname')), inputDom ]),
			E('div', { 'class': 'form-group' }, [
				E('label', { 'class': 'form-label' }, _('Download Limit')),
				E('input', { type: 'number', id: 'dl-rate', class: 'cbi-input-number', min: '0', value: dl }),
				E('span',{}, " Mbps")
			]),
			E('div', { 'class': 'form-group' }, [
				E('label', { 'class': 'form-label' }, _('Upload Limit')),
				E('input', { type: 'number', id: 'ul-rate', class: 'cbi-input-number', min: '0', value: ul }),
				E('span',{}, " Mbps")
			]),
			E('div', { 'class': 'cbi-page-actions right' }, [
				E('button', { 'class': 'btn cbi-button cbi-button-neutral', 'click': ui.hideModal }, _('Cancel')),
				E('button', { 'class': 'btn cbi-button cbi-button-positive', 'click': ui.createHandlerFn(this, async ev => {
					const dl_val = document.getElementById('dl-rate').value;
					const ul_val = document.getElementById('ul-rate').value;
					const newName = document.getElementById('host-name').value;
					try {
						if (mac && newName !== hostname) {
							hostNames[mac] = newName;
							await uci.set('hostnames', hostNameMacSectionId, mac.split(':').join('_'), newName);
							await uci.save('hostnames');
							await uci.apply('hostnames');
						}
						await fs.exec_direct('/usr/bin/aw-bpfctl', [type, 'update', host, "downrate", dl_val*1024*1024 || '0', "uprate", ul_val*1024*1024 || '0']);
						this.loadHostSpeedData();
						ui.addNotification(null, E('p',_('Speed limit updated')));
						ui.hideModal();
					} catch (e) {
						ui.addNotification(null, E('p', _('Error: ') + e.message));
					}
				})}, _('Save'))
			])
		]);
	},

	validateData: function(value, type) {
		if (typeof value !== 'string') return false;
		const ipv4Regex = /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$/;
		const ipv6Regex = /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^(([0-9a-fA-F]{1,4}:){0,6}::([0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4})$/i;
		const macRegex = /^([0-9A-Fa-f]{2}([-:]))([0-9A-Fa-f]{2}\2){4}[0-9A-Fa-f]{2}$|^([0-9A-Fa-f]{12})$/i;
		return (type === 'ipv4') ? ipv4Regex.test(value) : (type === 'ipv6') ? ipv6Regex.test(value) : macRegex.test(value);
	},

	createAddControls: function(type, placeholder) {
		const input = E('input', { 
			type: 'text', 
			class: 'cbi-input-text control-input', 
			style: (type === 'ipv6') ? 'width:320px' : 'width:180px', 
			placeholder: _(placeholder) 
		});
		const addBtn = E('button', { 
			class: 'btn cbi-button cbi-button-add', 
			disabled: true 
		}, [
			E('span', { 'class': 'btn-icon' }, '➕'),
			E('span', {}, ' ' + _('Add'))
		]);
		const refreshBtn = E('button', { 
			class: 'btn cbi-button cbi-button-action', 
			click: () => this.loadHostSpeedData() 
		}, [
			E('span', { 'class': 'btn-icon' }, '🔄'),
			E('span', {}, ' ' + _('Refresh'))
		]);

		input.addEventListener('input', () => { addBtn.disabled = (input.value.trim() === ''); });
		addBtn.addEventListener('click', ui.createHandlerFn(this, async () => {
			const value = input.value.trim();
			if (!this.validateData(value, type)) {
				return ui.addNotification(null, E('p', _('Data format error')));
			}
			try {
				await fs.exec_direct('/usr/bin/aw-bpfctl', [type, 'add', value]);
				this.loadHostSpeedData();
				ui.addNotification(null, E('p',_('Updated successfully!')));
				input.value = '';
				addBtn.disabled = true;
			} catch (e) {
				ui.addNotification(null, E('p', _('Error: ') + e.message));
			}
		}));

		return E('div', { 'class': 'display-controls' }, [
			E('div', { 'class': 'control-group' }, [
				E('span', { 'class': 'control-icon' }, '🖥️'),
				E('label', { 'class': 'control-label' }, _('Add Host:')),
				input
			]),
			E('div', { 'class': 'control-buttons' }, [
				addBtn,
				refreshBtn,
				E('div', { 'class': 'control-group status-group' }, [
					E('span', { 'class': 'control-icon' }, '🕐'),
					E('span', { 'id': 'display-last-updated', 'class': 'last-updated-text' }, _('Ready'))
				])
			])
		]);
	},

	initializeUI: function() {
		if (window.echarts) {
			var self = this;
			['ipv4', 'ipv6', 'mac'].forEach(function(type) {
				var dlChartEl = document.getElementById(type + '-download-speed-line-chart');
				var ulChartEl = document.getElementById(type + '-upload-speed-line-chart');
				if (!dlChartEl || !ulChartEl) return;

				var baseChartOption = {
					tooltip: {
						trigger: 'axis',
						formatter: function (params) {
							if (!params || params.length === 0) {
								return null;
							}
							var tooltipContent = params[0].axisValueLabel + '<br/>';
							params.sort(function(a, b) { return b.value - a.value; });
							params.forEach(function(item) {
								if (item.value > 0) {
									tooltipContent += item.marker + ' ' + item.seriesName + ': ' + '%1024.2mBps'.format(item.value) + '<br/>';
								}
							});
							return tooltipContent;
						}
					},
					grid: { left: '3%', right: '4%', bottom: '10%', top: '50px', containLabel: true },
					xAxis: { type: 'category', boundaryGap: false, data: lineCategories[type] },
					yAxis: { type: 'value', axisLabel: { formatter: function(val) { return '%1024.2mBps'.format(val); } } },
					series: []
				};

				downloadLineChart[type] = echarts.init(dlChartEl);
				downloadLineChart[type].setOption(baseChartOption);

				uploadLineChart[type] = echarts.init(ulChartEl);
				uploadLineChart[type].setOption(baseChartOption);
			});

			// 添加窗口大小变化监听器，使图表能够响应式调整
			if (!resizeListenerAdded) {
				var resizeTimer = null;
				var resizeHandler = function() {
					// 使用防抖，避免频繁触发 resize
					if (resizeTimer) {
						clearTimeout(resizeTimer);
					}
					resizeTimer = setTimeout(function() {
						// 调整折线图大小
						['ipv4', 'ipv6', 'mac'].forEach(function(type) {
							if (downloadLineChart[type]) {
								downloadLineChart[type].resize();
							}
							if (uploadLineChart[type]) {
								uploadLineChart[type].resize();
							}
						});
						// 调整饼图大小
						Object.keys(chartRegistry).forEach(function(chartId) {
							if (chartRegistry[chartId]) {
								chartRegistry[chartId].resize();
							}
						});
					}, 200);
				};
				
				window.addEventListener('resize', resizeHandler);
				resizeListenerAdded = true;
			}

			this.pollData();
		} else {
			setTimeout(this.initializeUI.bind(this), 50);
		}
	},

	// --- Main Render Function (New) ---

	render: function() {
		var self = this;

		const createTab = (type, title, placeholder) => {
			return E('div', { 'class': 'cbi-section', 'data-tab': type, 'data-tab-title': _(title) }, [
				E('div', { 'class': 'dashboard-container' }, [
					E('div', { 'class': 'line-chart-row' }, [
						E('div', { 'class': 'chart-card' }, [
							E('h4', [_('Real-time Download Speed')]),
							E('div', { id: type + '-download-speed-line-chart', style: 'width: 100%; height: 350px;' })
						]),
						E('div', { 'class': 'chart-card' }, [
							E('h4', [_('Real-time Upload Speed')]),
							E('div', { id: type + '-upload-speed-line-chart', style: 'width: 100%; height: 350px;' })
						])
					]),
					E('div', { 'class': 'kpi-row' }, [
						E('div', { 'class': 'kpi-card' }, [ E('big', { id: type + '-host-val' }, '0'), E('span', { 'class': 'kpi-card-label' }, _('Hosts')) ]),
						E('div', { 'class': 'kpi-card' }, [ E('big', { id: type + '-tx-rate-val' }, '0'), E('span', { 'class': 'kpi-card-label' }, _('Download Speed')) ]),
						E('div', { 'class': 'kpi-card' }, [ E('big', { id: type + '-rx-rate-val' }, '0'), E('span', { 'class': 'kpi-card-label' }, _('Upload Speed')) ]),
						E('div', { 'class': 'kpi-card' }, [ E('big', { id: type + '-tx-volume-val' }, '0'), E('span', { 'class': 'kpi-card-label' }, _('Download Total')) ]),
						E('div', { 'class': 'kpi-card' }, [ E('big', { id: type + '-rx-volume-val' }, '0'), E('span', { 'class': 'kpi-card-label' }, _('Upload Total')) ])
					]),
					E('div', { 'class': 'chart-grid' }, [
						E('div', { 'class': 'chart-card' }, [ E('h4', [_('Download Speed / Host')]), E('div', { id: type + '-tx-rate-pie', style: 'width:100%; height:300px;' }) ]),
						E('div', { 'class': 'chart-card' }, [ E('h4', [_('Upload Speed / Host')]), E('div', { id: type + '-rx-rate-pie', style: 'width:100%; height:300px;' }) ]),
						E('div', { 'class': 'chart-card' }, [ E('h4', [_('Download Total')]), E('div', { id: type + '-tx-volume-pie', style: 'width:100%; height:300px;' }) ]),
						E('div', { 'class': 'chart-card' }, [ E('h4', [_('Upload Total')]), E('div', { id: type + '-rx-volume-pie', style: 'width:100%; height:300px;' }) ])
					])
				]),
				E('table', { 'class': 'table', 'id': type + '-speed-data' }, [
					E('tr', { 'class': 'tr table-titles' }, [
						E('th', { 'class': 'th left' }, [ E('span', { 'class': 'th-icon' }, '🖥️'), ' ', _('Host') ]),
						E('th', { 'class': 'th left' }, [ E('span', { 'class': 'th-icon' }, '👤'), ' ', _('Hostname') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '⬇️'), ' ', _('Download Speed') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '📦'), ' ', _('Download Total') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '📨'), ' ', _('Download Packets') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '⬆️'), ' ', _('Upload Speed') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '📦'), ' ', _('Upload Total') ]),
						E('th', { 'class': 'th right' }, [ E('span', { 'class': 'th-icon' }, '📨'), ' ', _('Upload Packets') ]),
						E('th', { 'class': 'th center' }, [ E('span', { 'class': 'th-icon' }, '⚙️'), ' ', _('Actions') ])
					]),
					E('tr', { 'class': 'tr placeholder' }, [ E('td', { 'class': 'td', 'colspan': '9' }, [ E('em', { 'class': 'spinning' }, [ _('Collecting data...') ]) ]) ])
				]),
				self.createAddControls(type, placeholder)
			]);
		};

		var tabContainer = E('div', {}, [
			createTab('ipv4', 'IPv4', 'Please enter a valid IPv4 address'),
			createTab('ipv6', 'IPv6', 'Please enter a valid IPv6 address'),
			createTab('mac', 'MAC', 'Please enter a valid MAC address')
		]);

		var node = E([], [
		    E('link', { 'rel': 'stylesheet', 'href': L.resource('view/wifidogx.css') }),
		    E('script', { 'type': 'text/javascript', 'src': L.resource('echarts.min.js') }),
		    E('div', { 'class': 'l7-view-container' }, [
		        E('h2', [ _('Auth User Speed Monitor') ]),
		        tabContainer
		    ])
		]);

		ui.tabs.initTabGroup(tabContainer.childNodes);

		setTimeout(() => this.initializeUI(), 0);

		return node;
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
