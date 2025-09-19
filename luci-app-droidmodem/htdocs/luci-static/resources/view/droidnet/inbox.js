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
function renderTable(data, display) {
	var startIndex = (page - 1) * display;
	var endIndex = Math.min(startIndex + display, data.length);
	var currentPageData = data.slice(startIndex, endIndex);
	var tableRows = currentPageData.map(function(inbox, index) {
		var rowClass = index % 2 === 0 ? 'cbi-rowstyle-1' : 'cbi-rowstyle-2';
		var message = inbox.message.replace(/\n/g, '<br>');
		return E('tr', {'class': 'tr ' + rowClass }, [
			E('td', {'class': 'td'}, inbox.received.date),
			E('td', {'class': 'td'}, inbox.address),
			E('td', {'class': 'td'}, [
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': function() {
						ui.showModal(inbox.address, [
							E('p', [
								E('em', `${inbox.received.date} - ${inbox.received.time}`)
							]),
							E('p', message),
							E('div', {'class': 'right'}, [
								E('button', {
									'class': 'btn',
									'click': ui.hideModal
								}, _('OK'))
							])
						]);
					}
				}, _('View'))
			])
		]);
	});
	return E('table', {'class': 'table cbi-section-table'}, [
		E('tr', {'class': 'tr table-titles'}, [
			E('th', {'class': 'th'}, _('Date')),
			E('th', {'class': 'th'}, _('Address')),
			E('th', {'class': 'th'})
		]),
		E(tableRows)
	]);
};
function updateTable(data, display) {
	var container = document.getElementsByClassName('table-container');
	var prev = document.querySelector('.prev');
	var next = document.querySelector('.next');
	for (var i = 0; i < container.length; i++) {
		container[i].innerHTML = '';
		var table = renderTable(data, display);
		container[i].appendChild(table);
	};
	var total = data.length;
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
			var display = uci.get('droidnet', 'device', 'display_msg');
			return Promise.all([
				fs.exec('adb', ['-s', device, 'shell', 'content', 'query', '--uri', 'content://sms', '--projection', 'date_sent,date,address,body']).then(function(result) {
					var messages = [];
					var stdout = result.stdout;
					var stderr = result.stderr;
					if (stderr) {
						messages['messages_section'] = stderr.trim();
					} else if (stdout.includes('Error')) {
						messages['messages_info'] = stdout.trim();
					} else {
						var lines = stdout.trim().split('Row: ');
						lines.shift();
						var properties = {
							'body': 'message',
							'address': 'address',
							'date': 'received'
						};
						lines.forEach(function(line) {
							var pairs = line.split(',');
							var inbox = [];
							pairs.forEach(function(pair) {
								var keyValue = pair.split('=');
								if (keyValue.length === 2) {
									var key = keyValue[0].trim();
									var value = keyValue[1].trim();
									if (properties.hasOwnProperty(key)) {
										if (key === 'body') {
											var start = line.indexOf('body=') + 5;
											var message = line.substring(start);
											inbox[properties[key]] = message;
										} else if (key === 'date') {
											var timestamp = parseInt(value);
											var date = new Date(timestamp).toLocaleDateString(undefined, {
												weekday: 'short',
												month: 'short',
												day: '2-digit'
											});
											var time = new Date(timestamp).toLocaleTimeString(undefined, {
												hour: '2-digit',
												minute: '2-digit'
											});
											inbox[properties[key]] = {'date': date, 'time': time}
										} else {
											inbox[properties[key]] = value;
										};
									};
								};
							});
							messages.push(inbox);
						});
					};
					return messages;
				}).catch(function(error) {
					throw new Error(error);
				})
			]).then(function(result) {
				var messages = result[0];
				if (device && display && messages) {
					return Object.assign({device: device}, {display: display}, messages);
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
		if (data.messages_section) {
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
		} else if (data.messages_info) {
			ui.addNotification(_('Error: Device not supported!'),
				E('p', _('Unable to read message because the device version cannot execute the command. Please ensure the device is rooted or has Android version 10 or above.')), 'danger'
			);
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, [
					E('h3', {'class': 'section-title'}, _('Error Information')),
					E('textarea', {
						'id': 'syslog',
						'class': 'cbi-input-textarea',
						'style': 'height: 500px; overflow-y: scroll;',
						'readonly': 'readonly',
						'wrap': 'off',
						'rows': 1
					}, data.messages_info)
				])
			]);
		} else {
			var value = Object.values(data).filter(function(obj) {
				return typeof obj === 'object' && !('device' in obj);
			});
			var display = parseInt(data.display);
			return E('div', {'class': 'cbi-map'}, [
				E(header),
				E('div', {'class': 'cbi-section'}, [
					E('h3', {'class': 'section-title'}, _('Inbox Messages')),
					E('div', {'class': 'cbi-section-descr'}, _('Displays incoming messages with sender, subject, content, and date and time of receipt.')),
					E('div', {'class': 'controls', 'style': 'display: flex; flex-wrap: wrap; justify-content: space-around; padding: 1em 0;'}, [
						E('button', {
							'class': 'btn cbi-button-neutral prev',
							'style': 'flex-basis: 20%; text-align: center;',
							'disabled': true,
							'click': function() {
								page--;
								updateTable(value, display);
							}
						}, '«'),
						E('div', {'class': 'text', 'id': 'page-info', 'style': 'flex-grow: 1; align-self: center; text-align: center;'}, _('Displaying 1-%s of %s').format(display, value.length)),
						E('button', {
							'class': 'btn cbi-button-neutral next',
							'style': 'flex-basis: 20%; text-align: center;',
							'click': function() {
								page++;
								updateTable(value, display);
							}
						}, '»')
					]),
					E('div', {'class': 'table-container'}, renderTable(value, display))
				])
			]);
		};
	}
});

