/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require uci';
'require fs';
'require ui';

var page = 1;
var filter = '';
var apkFile = '/tmp/upload.apk';
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
function writeLog(message, service, error) {
	var logFile = '/var/log/droidnet.log';
	if (service === 'power') {
		var serviceName = _('Power service');
	} else {
		var serviceName = _('Application service');
	};
	fs.read(logFile).then(function(result) {
		var date = new Date().toLocaleDateString(undefined, {
			weekday: 'short',
			month: 'short',
			day: '2-digit'
		});
		var time = new Date().toLocaleTimeString(undefined, {
			hour: '2-digit',
			minute: '2-digit'
		});
		if (error === false) {
			var notif = `${date}, ${time} - ${serviceName}: ${message}`;
		} else {
			var notif = `${date}, ${time} - ${serviceName}: ${message}: ${error}`;
		};
		var newData = result.trim() + '\n' + notif;
		return fs.write(logFile, newData);
	});
};
function renderTable(data, display) {
	var tableRows, value = data.application;
	var start = (page - 1) * display;
	var packages = value.filter(function(item) {
		return item.toLowerCase().includes(filter.toLowerCase());
	});
	var end = Math.min(start + display, packages.length);
	var current = packages.slice(start, end);
	if (packages.length === 0) {
		tableRows = [
			E('tr', {'class': 'tr cbi-rowstyle-2'}, [
				E('td', {'class': 'td center', 'colspan': '2'}, [
					E('em', _('Application not found'))
				])
			])
		];
	} else {
		tableRows = current.map(function(value, index) {
			var rowClass = index % 2 === 0 ? 'cbi-rowstyle-1' : 'cbi-rowstyle-2';
			return E('tr', {'class': 'tr ' + rowClass }, [
				E('td', {'class': 'td left'}, value),
				E('td', {'class': 'td right'}, [
					E('button', {
						'class': 'btn cbi-button cbi-button-remove',
						'click': function() {
							ui.showModal(_('Remove application') + ` ${value}`, [
								E('p', _('Are you sure want to remove this application?')),
								E('div', {'class': 'right'}, [
									E(closeUi('Cancel')),
									E('button', {
										'class': 'btn cbi-button cbi-button-action',
										'click': function() {
											ui.showModal(_('Removing application'), [
												E('p', {'class': 'spinning'}, _('Waiting for application removal to complete…'))
											]);
											fs.exec('adb', ['-s', data.device, 'shell', 'pm', 'uninstall', '-k', '--user', '0', value]).then(function(result) {
												var stdout = result.stdout;
												if (stdout.trim() !== 'Success') {
													writeLog(_('Failed to remove %s application.').format(value), 'application', stdout);
													ui.showModal(_('Package removal failed'), [
														E('p', _('Failed to remove <em>%s</em> application.').format(value)),
														E('em', {'style': 'color: red;'}, stdout),
														E('div', {'class': 'right'}, [
															E('button', {'class': 'btn', 'click': ui.hideModal}, _('OK'))
														])
													]);
												} else {
													writeLog(_('Removing %s application successfully.').format(value), 'application', false);
													setTimeout(function() {
														ui.showModal(_('Removing application completed'), [
															E('p', _('Application <em>%s</em> has been successfully removed.').format(value)),
															E('div', {'class': 'right'}, [
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															])
														]);
													}, 10000);
												};
											});
										}
									}, _('Yes'))
								])
							]);
						}
					}, _('Remove'))
				])
			]);
		});
	};
	return E('table', {'class': 'table cbi-section-table'}, [
		E('tr', {'class': 'tr table-titles'}, [
			E('th', {'class': 'th left'}, _('Application name')),
			E('th', {'class': 'th'})
		]),
		E(tableRows)
	]);
};
function updateTable(data, display) {
	var value = data.application;
	var container = document.getElementsByClassName('table-container');
	var prev = document.querySelector('.prev');
	var next = document.querySelector('.next');
	for (var i = 0; i < container.length; i++) {
		container[i].innerHTML = '';
		var table = renderTable(data, display);
		container[i].appendChild(table);
	};
	var packages = value.filter(function(item) {
		return item.toLowerCase().includes(filter.toLowerCase());
	});
	var total = packages.length;
	var pages = Math.ceil(total / display);
	if (pages <= 1) {
		prev.disabled = true;
		next.disabled = true;
	} else if (page <= 1) {
		prev.disabled = true;
		next.disabled = false;
	} else if (page >= pages) {
		prev.disabled = false;
		next.disabled = true;
	} else {
		prev.disabled = false;
		next.disabled = false;
	};
	var start = (page - 1) * display + 1;
	var end = Math.min(start + display - 1, total);
	document.getElementById('page-info').innerText = _('Displaying %s - %s of %s').format(start, end, total);
};

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function() {
		return uci.load('droidnet').then(function() {
			var device = uci.get('droidnet', 'device', 'id');
			var display = uci.get('droidnet', 'device', 'display_app');
			return Promise.all([
				fs.exec('adb', ['-s', device, 'shell', 'df', 'sdcard', '-h']).then(function(result) {
					var storage = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					var properties = {
						'Size': 'size',
						'Used': 'use',
						'Avail': 'free',
						'Use%': 'percentage',
						'Mounted': 'mounted'
					};
					if (stderr) {
						storage['storage_section'] = stderr.trim();
					} else {
						var data = [];
						var lines = stdout.split('\n');
						var header = lines[0].split(/\s+/);
						var value = lines[1].split(/\s+/);
						for (var i = 0; i < header.length; i++) {
							var property = properties[header[i]];
							if (property) {
								data[property] = value[i];
							};
						};
						storage['storage'] = data;
					};
					return storage;
				}).catch(function(error) {
					throw new Error(error);
				}),
				fs.exec('adb', ['-s', device, 'shell', 'pm', 'list', 'packages']).then(function(result) {
					var application = {};
					var stderr = result.stderr;
					var stdout = result.stdout;
					if (stderr) {
						application['application_section'] = stderr.trim();
					} else {
						var parts = stdout.trim().split('\n').map(function(line) {
							return line.replace('package:', '');
						});
						application['application'] = parts;
					};
					return application;
				}).catch(function(error) {
					throw new Error(error);
				})
			]).then(function(results) {
				var storage = results[0];
				var application = results[1];
				if (device && display && storage && application) {
					return Object.assign({device: device}, {display: display}, storage, application)
				} else {
					throw new Error(_('Failed to get complete device information.'));
				};
			}).catch(function(error) {
				throw new Error(error);
			});
		});
	},
	render: function(data) {
		var display = parseInt(data.display);
		var application = data.application;
		var header = [
			E('h2', {'class': 'section-title'}, _('DroidNet')),
			E('div', {'class': 'cbi-map-descr'}, _('Manage Android modem and optimize network settings.'))
		];
		if (data.storage_section) {
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
			var powerMenu = [
				E('h3', {'class': 'section-title'}, _('Power Options')),
				E('div', {'class': 'cbi-section-descr'}, _('Let you shutdown, restart, access fastboot mode or recovery mode, all in one place.')),
				E('table', {'class': 'table cbi-section-table'}, [
					E('tr', {'class': 'tr'}, [
						E('td', {'class': 'td center', 'style': 'border: none;'}, [
							E('button', {
								'class': 'btn cbi-button cbi-button-save',
								'style': 'margin: 10px 0!important;',
								'click': function() {
									ui.showModal(_('Fastboot mode'), [
										E('p', _('Are you sure want rebooting device to fastboot mode?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Rebooting to fastboot mode'), [
														E('p', {'class': 'spinning'}, _('Waiting for device to reboot into fastboot mode…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'reboot', 'bootloader']);
													writeLog(_('Device entered fastboot mode.'), 'power', false);
													setTimeout(function() {
														ui.showModal(_('Fastboot mode completed'), [
															E('p', _('Device has been successfully to fastboot mode.')),
															E('div', {'class': 'right'}, [
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															])
														]);
													}, 10000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Fastboot mode'))
						]),
						E('td', {'class': 'td center', 'style': 'border: none;'}, [
							E('button', {
								'class': 'btn cbi-button cbi-button-save',
								'style': 'margin: 10px 0!important;',
								'click': function() {
									ui.showModal(_('Recovery mode'), [
										E('p', _('Are you sure want rebooting device to recovery mode?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Rebooting to recovery mode'), [
														E('p', {'class': 'spinning'}, _('Waiting for device to reboot into recovery mode…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'reboot', 'recovery']);
													writeLog(_('Device entered recovery mode.'), 'power', false);
													setTimeout(function() {
														ui.showModal(_('Recovery mode completed'), [
															E('p', _('Device has been successfully to recovery mode.')),
															E('div', {'class': 'right'}, [
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															])
														]);
													}, 10000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Recovery mode'))
						]),
						E('td', {'class': 'td center', 'style': 'border: none;'}, [
							E('button', {
								'class': 'btn cbi-button cbi-button-remove',
								'style': 'margin: 10px 0!important;',
								'click': function() {
									ui.showModal(_('Restart device'), [
										E('p', _('Are you sure want to restart device?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Restarting device'), [
														E('p', {'class': 'spinning'}, _('Waiting for device restart to complete…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'reboot']);
													writeLog(_('Device restarted successfully.'), 'power', false);
													setTimeout(function() {
														ui.showModal(_('Device restart completed'), [
															E('p', _('Device has been successfully restarted.')),
															E('div', {'class': 'right'}, [
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															])
														]);
													}, 30000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Restart'))
						]),
						E('td', {'class': 'td center', 'style': 'border: none;'}, [
							E('button', {
								'class': 'btn cbi-button cbi-button-remove',
								'style': 'margin: 10px 0!important;',
								'click': function() {
									ui.showModal(_('Shutdown device'), [
										E('p', _('Are you sure want to shutdown device?')),
										E('div', {'class': 'right'}, [
											E(closeUi('Cancel')),
											E('button', {
												'class': 'btn cbi-button cbi-button-action',
												'click': function() {
													ui.showModal(_('Shutting down device'), [
														E('p', {'class': 'spinning'}, _('Waiting for device to shut down…'))
													]);
													fs.exec('adb', ['-s', data.device, 'shell', 'reboot', '-p']);
													writeLog(_('Device powered off successfully.'), 'power', false);
													setTimeout(function() {
														ui.showModal(_('Device shutdown completed'), [
															E('p', _('Device has been successfully shut down.')),
															E('div', {'class': 'right'}, [
																E('div', {'class': 'right'}, [E(closeUi('OK'))])
															])
														]);
													}, 15000);
												}
											}, _('Yes'))
										])
									]);
								}
							}, _('Shutdown'))
						])
					])
				])
			];
			var applicationMenu = [
				E('h3', {'class': 'section-title'}, _('Application Manager')),
				E('div', {'class': 'cbi-section-descr'}, _('Lists installed apps on device.')),
				E('div', {'class': 'controls', 'style': 'display: flex; flex-wrap: wrap;'}, [
					E('div', {'class': 'disk-application', 'style': 'flex-basis: 100%; min-width: 250px; padding: .25em;'}, [
						E('label', _('Disk space') + ' : '),
						E('div', {'class': 'cbi-progressbar', 'title': _('%s used (%s used of %s, %s free)').format(data.storage.percentage, data.storage.use, data.storage.size, data.storage.free)}, [
							E('div', {'style': `width: ${data.storage.percentage};`}, '&nbsp;')
						])
					]),
					E('div', {'class': 'filter-application', 'style': 'padding: .25em;'}, [
						E('label', _('Filter') + ' : '),
						E('span', {'class': 'control-group', 'style': 'display: flex;'}, [
							E('input', {
								'type': 'text',
								'class': 'filter-input',
								'placeholder': 'Type to filter…',
								'keyup': function(event) {
									filter = event.target.value;
									page = 1;
									updateTable(data, display);
								}
							}),
							E('button', {
								'class': 'btn cbi-button',
								'click': function() {
									filter = '';
									page = 1;
									updateTable(data, display);
									document.querySelector('.filter-input').value = '';
								}
							}, _('Clear'))
						])
					]),
					E('div', {'class': 'action-application', 'style': 'padding: .25em;'}, [
						E('label', _('Actions') + ' : '),
						E('span', {'class': 'control-group', 'style': 'display: flex;'}, [
							E('button', {
								'class': 'btn cbi-button cbi-button-save',
								'style': 'margin-right: 10px',
								'click': function() {
									ui.showModal(_('Updating application list'), [
										E('p', {'class': 'spinning'}, _('Waiting for update application list command to complete…'))
									]);
									setTimeout(function() {
										ui.showModal(_('Update application list completed'), [
											E('p', _('Application list has been successfully updated.')),
											E('div', {'class': 'right'}, [
												E('div', {'class': 'right'}, [E(closeUi('OK'))])
											])
										]);
									}, 10000);
								}
							}, _('Update list')),
							E('button', {
								'class': 'btn cbi-button cbi-button-action',
								'click': function() {
									ui.uploadFile(apkFile).then(function(result) {
										var apkName = result.name;
										ui.showModal(_('Install application'), [
											E('p', _('Installing application from untrusted sources is a potential security risk, really attempt to install <em>%s</em>?').format(apkName)),
											E('ul', [
												result.size ? E('li', '%s: %1024.2mB'.format(_('Size'), result.size)) : '',
												result.checksum ? E('li', '%s: %s'.format(_('MD5'), result.checksum)) : '',
												result.sha256sum ? E('li', '%s: %s'.format(_('SHA256'), result.sha256sum)) : ''
											]),
											E('div', {'class': 'right'}, [
												E('button', {
													'class': 'btn cbi-button cbi-button-remove',
													'style': 'margin-right: 10px',
													'click': function() {
														fs.remove(apkFile);
														ui.hideModal();
													}
												}, _('Cancel')),
												E('button', {
													'class': 'btn cbi-button cbi-button-action',
													'click': function() {
														ui.showModal(_('Installing application'), [
															E('p', {'class': 'spinning'}, _('Waiting for application installation to complete…'))
														]);
														fs.exec_direct('adb', ['-s', data.device, 'install', apkFile]).then(function(result) {
															var apk = result.trim();
															if (apk === 'Success') {
																writeLog(_('Application %s has been successfully installed.').format(apkName), 'application', false);
																ui.showModal(_('Application installation completed'), [
																	E('p', _('Application <em>%s</em> has been successfully installed.').format(apkName)),
																	E('div', {'class': 'right'}, [
																		E('div', {'class': 'right'}, [E(closeUi('OK'))])
																	])
																]);
															} else {
																writeLog(_('Failed to install %s application').format(apkName), 'application', apk);
																ui.showModal(_('Application installation failed'), [
																	E('p', _('Failed to install <em>%s</em> application.').format(apkName)),
																	E('em', {'style': 'color: red;'}, apk),
																	E('div', {'class': 'right'}, [
																		E('div', {'class': 'right'}, [E(closeUi('OK'))])
																	])
																]);
															};
															return fs.remove(apkFile);
														});
													}
												}, _('Install'))
											])
										])
									}).catch(function(error) {
										if (error.message === 'Upload has been cancelled') {
											ui.hideModal();
										} else {
											writeLog(_('Failed to upload %s application.').format(apkName), 'application', error);
											ui.showModal(_('Error uploading application'), [
												E('p', _('Failed to upload <em>%s</em> application.').format(apkName)),
												E('em', {'style': 'color: red;'}, error),
												E('div', {'class': 'right'}, [
													E('div', {'class': 'right'}, [E(closeUi('OK'))])
												])
											]);
										};
									});
								}
							}, _('Upload application'))
						])
					])
				]),
				E('div', {'class': 'controls', 'style': 'display: flex; flex-wrap: wrap; justify-content: space-around; padding: 1em 0;'}, [
					E('button', {
						'class': 'btn cbi-button-neutral prev',
						'style': 'flex-basis: 20%; text-align: center;',
						'disabled': true,
						'click': function() {
							page--;
							updateTable(data, display);
						}
					}, '«'),
					E('div', {'class': 'text', 'id': 'page-info', 'style': 'flex-grow: 1; align-self: center; text-align: center;'}, _('Displaying 1 - %s of %s').format(display, application.length)),
					E('button', {
						'class': 'btn cbi-button-neutral next',
						'style': 'flex-basis: 20%; text-align: center;',
						'click': function() {
							page++;
							updateTable(data, display);
						}
					}, '»')
				]),
				E('div', {'class': 'table-container'}, renderTable(data, display))
			];
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, powerMenu),
				E('div', {'class': 'cbi-section'}, applicationMenu)
			]);
		};
	}
});

