/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require uci';
'require fs';
'require ui';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function() {
		return uci.load('droidnet').then(function() {
			var device = uci.get('droidnet', 'device', 'id');
			return Promise.all([
				fs.exec('adb', ['-s', device, 'shell', 'getprop']).then(function(result) {
					var deviceInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					var properties = {
						'ro.serialno': 'device_id',
						'ro.product.brand': 'device_brand',
						'ro.product.model': 'device_model',
						'ro.product.device': 'device_code',
						'ro.board.platform': 'device_soc',
						'dalvik.vm.isa.arm.variant': 'device_cpu',
						'ro.build.version.release': 'device_version',
						'ro.build.version.sdk': 'device_sdk',
						'ro.build.version.security_patch': 'device_security'
					};
					if (stderr) {
						deviceInfo['device_section'] = stderr.trim();
					} else {
						var lines = stdout.split('\n');
						for (var i = 0; i < lines.length; i++) {
							for (var property in properties) {
								if (lines[i].includes('[' + property + ']')) {
									var parts = lines[i].split(']: [');
									var value = parts[1].substring(0, parts[1].length - 1);
									if (value.includes(',')) {
										value = value.split(',').map(function(item) {return item.trim();});
									};
									deviceInfo[properties[property]] = value;
									break;
								};
							};
						};
					};
					return deviceInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'uptime']).then(function(result) {
					var uptimeInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						uptimeInfo['uptime_section'] = stderr.trim();
					} else {
						var parts = stdout.trim().split(/\s+/);
						var uptimeParts = parts.slice(0, 4);
						uptimeInfo['device_uptime'] = uptimeParts.join(' ').replace(/,$/, '');
					};
					return uptimeInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'uname', '-a']).then(function(result) {
					var kernelInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						kernelInfo['uname_section'] = stderr.trim();
					} else {
						var parts = stdout.trim().split(/\s+/);
						kernelInfo['device_uname'] = {'kernel': parts[2], 'arch': parts[12]};
					};
					return kernelInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'cat', '/proc/meminfo']).then(function(result) {
					var memmoryInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						memmoryInfo['memory_section'] = stderr.trim();
					} else {
						var parts = stdout.trim().split(/\s+/);
						var kbValue = parseInt(parts[1]) + parseInt(parts[4]);
						var gbValue = kbValue / (1024 * 1024);
						memmoryInfo['device_memory'] = gbValue.toFixed(0) + ' GB';
					};
					return memmoryInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'dumpsys', 'battery']).then(function(result) {
					var batteryInfo = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					var properties = {
						'level': 'battery_level',
						'voltage': 'battery_voltage',
						'technology': 'battery_technology',
						'temperature': 'battery_temperature',
						'Charge counter': 'battery_counter'
					};
					if (stderr) {
						batteryInfo['battery_section'] = stderr.trim();
					} else {
						var lines = stdout.split('\n');
						for (var i = 0; i < lines.length; i++) {
							var line = lines[i].trim();
							for (var property in properties) {
								if (line.startsWith(property + ':')) {
									var parts = line.split(':');
									var value = parts[1].trim();
									if (property === 'level') {
										value = parseInt(value) + ' %';
									} else if (property === 'voltage') {
										value = (parseInt(value) / 1000).toFixed(2) + ' V';
									} else if (property === 'temperature') {
										value = (parseInt(value) / 10) + ' °C';
									} else if (property === 'Charge counter') {
										value = parseInt(value) / 1000 + ' μAh';
									};
									batteryInfo[properties[property]] = value;
								};
							};
						};
					};
					return batteryInfo;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'su', '-v']).then(function(result) {
					var rootInfo = {};
					var stdout = result.stdout ? result.stdout.trim() : '';
					var stderr = result.stderr;
					if (stderr || stdout === '/system/bin/sh: su: not found' || stdout === '/system/bin/sh: su: inaccessible or not found') {
						rootInfo['device_root'] = false;
					} else {
						var parts = stdout.split(':');
						rootInfo['device_root'] = {'version': parts[0], 'name': parts[1]};
					};
					return rootInfo;
				}).catch(function(error) {
					throw new Error(error);
				})
			]).then(function(results) {
				var deviceInfo = results[0];
				var uptimeInfo = results[1];
				var kernelInfo = results[2];
				var memmoryInfo = results[3];
				var batteryInfo = results[4];
				var rootInfo = results[5];
				if (device && deviceInfo && uptimeInfo && kernelInfo && memmoryInfo && batteryInfo && rootInfo) {
					return Object.assign({}, {device: device}, deviceInfo, uptimeInfo, kernelInfo, memmoryInfo, batteryInfo, rootInfo)
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
		if (data.device_section) {
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
			var device = [
				E('h3', {'class': 'section-title'}, _('Device Information')),
				E('table', {'class': 'table cbi-section-table'}, [
					E('tr', {'class': 'tr table-title', 'style': 'display: none;'}),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Device ID')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_id || '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('Processors')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_cpu ? (data.device_cpu.toUpperCase()) : '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Root status')),
						E('td', {'class': 'td left', 'width': '25%'}, 
							data.device_root === false ? _('Non-root') :
							data.device_root ? (_('Root with %s (%s)').format(data.device_root.name, data.device_root.version)) :
							'-'
						),
						E('td', {'class': 'td left', 'width': '25%'}, _('RAM')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_memory || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Brand name')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_brand ? (data.device_brand.charAt(0).toUpperCase() + data.device_brand.slice(1)) : '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('Architecture')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_uname ? (data.device_uname.arch) : '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Code name')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_code || '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('Android version')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_version || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Model number')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_model ? (data.device_model.charAt(0).toUpperCase() + data.device_model.slice(1)) : '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('SDK version')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_sdk || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('Used time')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_uptime || '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('Security patch level')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_security || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '25%'}, _('System on Chip (SoC)')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_soc ? (data.device_soc.toUpperCase()) : '-'),
						E('td', {'class': 'td left', 'width': '25%'}, _('Kernel version')),
						E('td', {'class': 'td left', 'width': '25%'}, data.device_uname ? (data.device_uname.kernel) : '-')
					])
				])
			];
			var battery = [
				E('h3', {'class': 'section-title'}, _('Battery Information')),
				E('table', {'class': 'table cbi-section-table'}, [
					E('tr', {'class': 'tr table-title', 'style': 'display: none;'}),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Level')),
						E('td', {'class': 'td left', 'width': '50%'}, data.battery_level || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Charge counter')),
						E('td', {'class': 'td left', 'width': '50%'}, data.battery_counter || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Voltage')),
						E('td', {'class': 'td left', 'width': '50%'}, data.battery_voltage || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-2'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Temperature')),
						E('td', {'class': 'td left', 'width': '50%'}, data.battery_temperature || '-')
					]),
					E('tr', {'class': 'tr cbi-rowstyle-1'}, [
						E('td', {'class': 'td left', 'width': '50%'}, _('Technology')),
						E('td', {'class': 'td left', 'width': '50%'}, data.battery_technology || '-')
					]),
				])
			];
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, device),
				E('div', {'class': 'cbi-section'}, battery)
			]);
		};
	}
});
