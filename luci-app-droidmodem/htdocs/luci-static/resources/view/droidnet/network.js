/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>, Anas Fanani <anas@anasfanani.com>
 */

'use strict';
'require view';
'require uci';
'require fs';
'require ui';

function closeUi(type) {
	if (type === 'OK') {
		return E('button', {
			'class': 'btn',
			'click': function() {
				return window.location.reload();
			}
		}, _('OK'));
	} else {
		return E('button', {
			'class': 'btn cbi-button cbi-button-remove',
			'style': 'margin-right: 10px',
			'click': ui.hideModal
		}, _('Cancel'));
	};
};
function writeLog(message) {
	var logFile = '/var/log/droidnet.log';
	fs.read(logFile).then(function(result) {
		var service = _('Network service');
		var date = new Date().toLocaleDateString(undefined, {
			weekday: 'short',
			month: 'short',
			day: '2-digit'
		});
		var time = new Date().toLocaleTimeString(undefined, {
			hour: '2-digit',
			minute: '2-digit'
		});
		var notif = `${date}, ${time} - ${service}: ${message}`;
		var newData = result.trim() + '\n' + notif;
		return fs.write(logFile, newData);
	});
};
function renderTableCell(data, id) {
	if (id === 'sim-1') {
		var tab = 1;
		var sim = 0;
		var display = 'table';
		var imei = data.imei_sim01;
	} else {
		var tab = 2;
		var sim = 1;
		var display = 'none';
		var imei = data.imei_sim02;
	};
	return E('table', {'class': 'table cbi-section-table', 'id': `sim-${tab}`, 'style': `display: ${display}`}, [
		E('tr', {'class': 'tr table-titles', 'style': 'display: none;'}),
		E('tr', {'class': 'tr cbi-rowstyle-1'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('Operator name')),
			E('td', {'class': 'td left', 'width': '50%'}, data.operator[sim] || '-')
		]),
		E('tr', {'class': 'tr cbi-rowstyle-2'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('Network type')),
			E('td', {'class': 'td left', 'width': '50%'}, data.signal[sim] || '-')
		]),
		E('tr', {'class': 'tr cbi-rowstyle-1'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('Roaming mode')),
			E('td', {'class': 'td left', 'width': '50%'}, data.roaming[sim] === 'true' ? _('On') :
				_('Off')
			)
		]),
		E('tr', {'class': 'tr cbi-rowstyle-2'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('MCC')),
			E('td', {'class': 'td left', 'width': '50%'}, data.mcc[sim] || '-')
		]),
		E('tr', {'class': 'tr cbi-rowstyle-1'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('IMEI')),
			E('td', {'class': 'td left', 'width': '50%'}, imei || '-')
		]),
		E('tr', {'class': 'tr cbi-rowstyle-2'}, [
			E('td', {'class': 'td left', 'width': '50%'}, _('Driver')),
			E('td', {'class': 'td left', 'width': '50%'}, data.driver || '-')
		])
	]);
};
function renderTableWiFi(device) {
	fs.exec('adb', ['-s', device, 'shell', 'dumpsys', 'wifi', '|', 'grep', 'mWifiInfo SSID']).then(function(result) {
		var table, wifiInfo = {};
		var stderr = result.stderr;
		var stdout = result.stdout;
		var properties = {
			'mWifiInfo SSID': 'ssid',
			'BSSID': 'bssid',
			'MAC': 'mac',
			'RSSI': 'rssi',
			'Link speed': 'speed',
			'Frequency': 'frequency'
		};
		if (stderr) {
			table = E('p', stderr);
		} else {
			var lines = stdout.trim().split('\n')[0];
			var parts = lines.split(', ');
			parts.forEach(function(part) {
				var keyValue = part.split(': ');
				var key = keyValue[0].trim();
				var value = keyValue[1].replace(/"/g, '');
				if (properties[key]) {
					if (key === 'Frequency' || key === 'Link speed') {
						value = value.replace(/(\d+)([A-Za-z]+)/g, '$1 $2');
					};
					if (key === 'RSSI') {
						value += ' dBm';
					};
					wifiInfo[properties[key]] = value;
				};
			});
		};
		table = [
			E('h3', {'class': 'section-title'}, _('Wireless Information')),
			E('table', {'class': 'table cbi-section-table'}, [
				E('tr', {'class': 'tr table-titles', 'style': 'display: none;'}),
				E('tr', {'class': 'tr cbi-rowstyle-1'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('SSID')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.ssid)
				]),
				E('tr', {'class': 'tr cbi-rowstyle-2'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('BSSID')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.bssid)
				]),
				E('tr', {'class': 'tr cbi-rowstyle-1'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('MAC address')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.mac)
				]),
				E('tr', {'class': 'tr cbi-rowstyle-2'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('RSSI')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.rssi)
				]),
				E('tr', {'class': 'tr cbi-rowstyle-1'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('Link speed')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.speed)
				]),
				E('tr', {'class': 'tr cbi-rowstyle-2'}, [
					E('td', {'class': 'td left', 'width': '50%'}, _('Frequency')),
					E('td', {'class': 'td left', 'width': '50%'}, wifiInfo.frequency)
				])
			])
		];
		return document.getElementById('wirelessMenu').append(...table);
	}).catch(function(error) {
		var message = E('p', error);
		return document.getElementById('wirelessMenu').append(...message); 
	});
};

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function() {
		return uci.load('droidnet').then(function() {
			var device = uci.get('droidnet', 'device', 'id');
			return Promise.all([
				fs.exec('adb', ['-s', device, 'shell', 'getprop']).then(function(result) {
					var networkInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					var properties = {
						'gsm.operator.alpha': 'operator',
						'gsm.network.type': 'signal',
						'gsm.version.ril-impl': 'driver',
						'gsm.operator.isroaming': 'roaming',
						'gsm.sim.operator.numeric': 'mcc'
					};
					if (stderr) {
						networkInfo['network_section'] = stderr.trim();
					} else {
						var lines = stdout.split('\n');
						for (var i = 0; i < lines.length; i++) {
							for (var property in properties) {
								if (lines[i].includes('[' + property + ']')) {
									var parts = lines[i].split(']: [');
									var value = parts[1].substring(0, parts[1].length - 1);
									if (value.includes(',')) {
										value = value.split(',').map(function(item) {
											return item.trim();
										});
									}else {
										value = [value.trim(), ''];
									};
									networkInfo[properties[property]] = value;
									break;
								};
								if (!networkInfo.hasOwnProperty(properties[property])) {
									networkInfo[properties[property]] = false;
								};
							};
						};
					};
					return networkInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'service', 'call', 'iphonesubinfo', '1', 's16', 'com.android.shell']).then(function(result) {
					var imeisim01Info = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						imeisim01Info['imei_sim01_section'] = stderr.trim();
					} else {
						var matches = stdout.match(/'([^']+)'/g);
						var value = matches.map(function(match) {
							return match.slice(1, -1);
						});
						var combined = value.join('');
						var imei = combined.replace(/[.\s]/g, '');
						imeisim01Info['imei_sim01'] = imei;
					};
					return imeisim01Info;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'ip', 'route']).then(function(result) {
					var ipInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (result && stderr) {
						ipInfo['ip_section'] = stderr.trim();
					} else if (result && stdout) {
						var parts = stdout.trim().split(/\s+/);
						var value = parts.slice(-1)[0];
						ipInfo['ip'] = value;
					} else {
						ipInfo['ip'] = false;
					};
					return ipInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'dumpsys', 'wifi', '|', 'grep', 'Wi-Fi is']).then(function(result) {
					var wifiInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						wifiInfo['wifi_section'] = stderr.trim();
					} else {
						var status = stdout.trim() === 'Wi-Fi is enabled' ? true : false;
						wifiInfo['wifi'] = status;
					};
					return wifiInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'dumpsys', 'telephony.registry', '|', 'grep', 'mDataConnectionState=']).then(function(result) {
					var dataInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						dataInfo['data_section'] = stderr.trim();
					} else {
						if (stdout.includes('mDataConnectionState=2')) {
							var dataStatus = true;
						} else {
							var dataStatus = false;
						};
						dataInfo['data'] = dataStatus;
					};
					return dataInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'settings', 'get', 'global', 'airplane_mode_on']).then(function(result) {
					var airplaneInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						airplaneInfo['airplane_section'] = stderr.trim();
					} else {
						var status = stdout.trim() === '1' ? true : false;
						airplaneInfo['airplane'] = status;
					};
					return airplaneInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
			]).then(function(results) {
				var networkInfo = results[0];
				var imeisim01Info = results[1];
				var ipInfo = results[2];
				var wifiInfo = results[3];
				var dataInfo = results[4];
				var airplaneInfo = results[5];
				if (device && networkInfo && imeisim01Info && ipInfo && wifiInfo && dataInfo && airplaneInfo) {
					return Object.assign({device: device}, networkInfo, imeisim01Info, ipInfo, wifiInfo, dataInfo, airplaneInfo);
				} else {
					throw new Error(_('Failed to get complete device information.'));
				};
			}).catch(function(error) {
				throw new Error(error);
			});
		});
	},
	render: function(data) {
		var header = [
			E('h2', {'class': 'section-title'}, _('DroidNet')),
			E('div', {'class': 'cbi-map-descr'}, _('Manage Android modem and optimize network settings.'))
		];
		if (data.network_section) {
			ui.addNotification(_('Error: Device conflict!'),
				E('p', _('Please check your settings, the configured device and ADB devices are conflicting.')), 'danger'
			);
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, [
					E('div', {'class': 'cbi-value', 'style': 'text-align: center; display: block;'}, [
						E('em', _('No device detected or connected.'))
					])
				])
			]);
		} else {
			var networkMenu = [
				E('h3', {'class': 'section-title'}, _('Mobile Network')),
				E('table', {'class': 'table cbi-section-table'}, [
					E('tr', {'class': 'tr table-titles', 'style': 'display: none;'}),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('IP address')),
						E('td', {'class': 'td left'}, data.ip || '-'),
						E('td', {'class': 'td'})
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2', 'style': 'display: table-row;'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Wireless connection')),
						E('td', {'class': 'td left', 'width': '25%'}, data.wifi === true ? _('On') :
							_('Off')
						),
						E('td', {'class': 'td center', 'width': '25%'}, [
							data.wifi === false ? E('button', {
								'class': 'btn cbi-button cbi-button-action',
								'click': function() {
									ui.showModal(_('Wireless network'), [
										E('p', _('Are you sure want to switched on wireless connection?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Turning on wireless connection '), [
														E('p', {'class': 'spinning'}, _('Waiting for wireless connection to be turned on…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'svc', 'wifi', 'enable']);
													writeLog(_('Wireless connection has been switched on.'));
													setTimeout(function() {
														ui.showModal(_('Wireless connection has been switched on'), [
															E('p', _('Wireless connection has been successfully switched on.')),
															E('div', {'class': 'right'}, [E(closeUi('OK'))])
														]);
													}, 5000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Enable')) :
							E('button', {
								'class': 'btn cbi-button cbi-button-remove',
								'click': function() {
									ui.showModal(_('Wireless network'), [
										E('p', _('Are you sure want to switched off wireless connection?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Turning off wireless connection '), [
														E('p', {'class': 'spinning'}, _('Waiting for wireless connection to be turned off…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'svc', 'wifi', 'disable']);
													writeLog(_('Wireless connection has been switched off.'));
													setTimeout(function() {
														ui.showModal(_('Wireless connection has been switched off'), [
															E('p', _('Wireless connection has been successfully switched off.')),
															E('div', {'class': 'right'}, [E(closeUi('OK'))])
														]);
													}, 5000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Disable'))
						])
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1', 'style': 'display: table-row;'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Mobile data')),
						E('td', {'class': 'td left', 'width': '25%'}, data.data === true ? _('On') :
							_('Off')
						),
						E('td', {'class': 'td center', 'width': '25%'}, [
							data.data === false ? E('button', {
								'class': 'btn cbi-button cbi-button-action',
								'click': function() {
									ui.showModal(_('Mobile network'), [
										E('p', _('Are you sure want to switched on mobile data?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													if (data.airplane === true) {
														ui.showModal(_('Failed to switch on mobile data'), [
															E('p', _('Failed to switch on mobile data because the airplane mode is active.')),
															E('div', {'class': 'right'}, [E(closeUi('OK'))])
														]);
														writeLog(_('Failed to swich on mobile data because the airplane mode is active.'));
													} else {
														ui.showModal(_('Turning on mobile data'), [
															E('p', {'class': 'spinning'}, _('Waiting for mobile data to be turned on…'))
														]);
														fs.exec('adb', ['-s', data.device, 'shell', 'svc', 'data', 'enable']);
														writeLog(_('Mobile data has been switched on.'));
														setTimeout(function() {
															ui.showModal(_('Mobile data has been switched on'), [
																E('p', _('Mobile data has been successfully switched on.')),
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															]);
														}, 5000);
													};
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Enable')) :
							E('button', {
								'class': 'btn cbi-button cbi-button-remove',
								'click': function() {
									ui.showModal(_('Mobile network'), [
										E('p', _('Are you sure want to switched off mobile data?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Turning off mobile data'), [
														E('p', {'class': 'spinning'}, _('Waiting for mobile data to be turned off…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'svc', 'data', 'disable']);
													writeLog(_('Mobile data has been switched off.'));
													setTimeout(function() {
														ui.showModal(_('Mobile data has been switched off'), [
															E('p', _('Mobile data has been successfully switched off.')),
															E('div', {'class': 'right'}, [E(closeUi('OK'))])
														]);
													}, 5000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Disable'))
						])
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2', 'style': 'display: table-row;'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Airplane mode')),
						E('td', {'class': 'td left', 'width': '25%'}, data.airplane === true ? _('On') :
							_('Off')
						),
						E('td', {'class': 'td center', 'width': '25%'}, [
							data.airplane === false ? E('button', {
								'class': 'btn cbi-button cbi-button-action',
								'click': function() {
									ui.showModal(_('Airplane mode'), [
										E('p', _('Are you sure want to switched on airplane mode?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													fs.exec('adb', ['-s', data.device, 'shell', 'cmd', 'connectivity', 'airplane-mode', 'enable']).then(function(result) {
														if (result.stdout) {
															ui.showModal(_('Failed to switch on aiplane mode'), [
																E('p', _('Failed to switch on airplane mode because device version cannot execute the command, make sure device is rooted or android version is 10 or above.')),
																E('em', {'style': 'color: red;'}, result.stdout),
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															]);
															writeLog(_('Failed to switch on airplane mode because android version is below 10.'));
														} else {
															ui.showModal(_('Turning on airplane mode'), [
																E('p', {'class': 'spinning'}, _('Waiting for airplane mode to be turned on…'))
															]);
															writeLog(_('Airplane mode has been switched on.'));
															setTimeout(function() {
																ui.showModal(_('Airplane mode has been switched on'), [
																	E('p', _('Airplane mode has been successfully switched on.')),
																	E('div', {'class': 'right'}, [E(closeUi('OK'))])
																]);
															}, 5000);
														};
													});
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Enable')) :
							E('button', {
								'class': 'btn cbi-button cbi-button-remove',
								'click': function() {
									ui.showModal(_('Airplane mode'), [
										E('p', _('Are you sure want to switched off airplane mode?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													fs.exec('adb', ['-s', data.device, 'shell', 'cmd', 'connectivity', 'airplane-mode', 'disable']).then(function(result) {
														if (result.stdout) {
															ui.showModal(_('Failed to switch off aiplane mode'), [
																E('p', _('Failed to switch off airplane mode because device version cannot execute the command, make sure device is rooted or android version is 10 or above.')),
																E('em', {'style': 'color: red;'}, result.stdout),
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															]);
															writeLog(_('Failed to switch off airplane mode because android version is below 10.'));
														} else {
															ui.showModal(_('Turning off Airplane mode'), [
																E('p', {'class': 'spinning'}, _('Waiting for airplane mode to be turned off…'))
															]);
															writeLog(_('Airplane mode has been switched off.'));
															setTimeout(function() {
																ui.showModal(_('Airplane mode has been switched off'), [
																	E('p', _('Airplane mode has been successfully switched off.')),
																	E('div', {'class': 'right'}, [E(closeUi('OK'))])
																]);
															}, 5000);
														};
													});
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Disable'))
						])
					])
				])
			];
			var cellularMenu = [
				E('h3', {'class': 'section-title'}, _('Cellular Information')),
				E('ul', {'class': 'cbi-tabmenu'}, [
					data.operator && data.operator[0] ? E('li', {'class': 'cbi-tab', 'id': 'tab-1'}, [
						E('a', {
							'href': '#',
							'click': function() {
								document.getElementById('tab-1').className = 'cbi-tab';
								document.getElementById('tab-2').className = 'cbi-tab-disabled';
								document.getElementById('sim-1').style.display = 'table';
								document.getElementById('sim-2').style.display = 'none';
							}
						}, _('SIM 1'))
					]) : '',
					data.operator && data.operator[1] ? E('li', {'class': 'cbi-tab-disabled', 'id': 'tab-2'}, [
						E('a', {
							'href': '#',
							'click': function() {
								document.getElementById('tab-1').className = 'cbi-tab-disabled';
								document.getElementById('tab-2').className = 'cbi-tab';
								document.getElementById('sim-1').style.display = 'none';
								document.getElementById('sim-2').style.display = 'table';
							}
						}, _('SIM 2'))
					]) : ''
				]),
				E(renderTableCell(data, 'sim-1')),
				E(renderTableCell(data, 'sim-2'))
			];
			var wirelessMenu = [
				data.wifi === true ? E('div', {'id': 'wirelessMenu'}, renderTableWiFi(data.device)) : ''
			];
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, networkMenu),
				E('div', {'class': 'cbi-section'}, wirelessMenu),
				E('div', {'class': 'cbi-section'}, cellularMenu)
			]);
		};
	}
});

