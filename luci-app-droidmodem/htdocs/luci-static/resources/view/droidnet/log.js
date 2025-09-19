/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require fs';
'require ui';
'require poll';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function() {
		var notification = false;
		return Promise.all([
			poll.add(function() {
				fs.read('/var/log/droidnet.log').then(function(result) {
					if (!result || result.trim() === '') {
						ui.addNotification(_('Error: Read log file!'),
							E('p', _('Unable to read the interface info from /var/log/droidnet.log.')), 'danger'
						);
						notification = true;
					} else {
						var data = result.trim();
						var syslog = document.getElementById('syslog');
						var filter = document.getElementById('log-filter').value;
						var direction = document.getElementById('log-direction').value;
						if (filter !== 'all') {
							var value = data.split('\n').filter(function(log) {
								return log.includes(filter);
							}).join('\n');
							data = value;
						};
						if (direction === 'up') {
							var value = data.split('\n').reverse().join('\n');
							syslog.innerHTML = value;
						} else {
							syslog.innerHTML = data;
						};
						notification = false;
					};
				}).catch(function(error) {
					ui.addNotification(_('Error: Read log file!'),
						E('p', _('An error occurred while reading the file') + `: ${error}`), 'danger'
					);
					notification = true;
				});
			})
		]);
	},
	render: function() {
		var header = [
			E('h2', {'class': 'section-title'}, _('DroidNet')),
			E('div', {'class': 'cbi-map-descr'}, _('Manage Android modem and optimize network settings.'))
		];
		var menu = [
			E('label', {'for': 'log-filter', 'style': 'margin-right: 8px;'}, _('Filter by service') + ' : '),
			E('select', {'id': 'log-filter', 'style': 'margin: 8px 8px 8px 0;'}, [
				E('option', {'value': 'all', 'selected': 'selected'}, _('All')),
				E('option', {'value': 'Application' }, _('Application')),
				E('option', {'value': 'Monitoring' }, _('Monitoring')),
				E('option', {'value': 'Network' }, _('Network')),
				E('option', {'value': 'Power' }, _('Power'))
			]),
			E('label', {'for': 'log-direction', 'style': 'margin-right: 8px;'}, _('Log direction') + ' : '),
			E('select', {'id': 'log-direction', 'style': 'margin: 8px 8px 8px 0;'}, [
				E('option', {'value': 'down', 'selected': 'selected'}, _('Down')),
				E('option', {'value': 'up' }, _('Up'))
			]),
			E('div', {'class': 'log-button', 'style': 'display: inline-block; margin: 0 8px 8px 0;'}, [
				E('button', {
					'class': 'btn cbi-button cbi-button-remove',
					'style': 'margin-right: 10px',
					'click': function() {
						fs.read('/var/log/droidnet.log').then(function(result) {
							var message = _('DroidNet logs have been successfully cleared.');
							var date = new Date().toLocaleDateString(undefined, {
								weekday: 'short',
								month: 'short',
								day: '2-digit'
							});
							var time = new Date().toLocaleTimeString(undefined, {
								hour: '2-digit',
								minute: '2-digit'
							});
							var notif = `${date}, ${time} - ${message}\n`;
							fs.write('/var/log/droidnet.log', notif);
						});
					}
				}, _('Clear')),
				E('button', {
					'class': 'btn cbi-button cbi-button-save',
					'click': function() {
						var logs = document.getElementById('syslog').value;
						var blob = new Blob([logs], {type: 'text/plain'});
						var link = document.createElement('a');
						link.href = window.URL.createObjectURL(blob);
						link.download = 'droidnet.log';
						link.click();
					}
				}, _('Download'))
			])
		];
		var body = [
			E('textarea', {
				'id': 'syslog',
				'class': 'cbi-input-textarea',
				'style': 'height: 500px; overflow-y: scroll;',
				'readonly': 'readonly',
				'wrap': 'off',
				'rows': 1
			})
		];
		return E('div', {'class': 'cbi-map'}, [
			E(header),
			E('div', {'class': 'cbi-section'}, [
				E('div', {'class': 'cbi-control'}, menu),
				E('div', {'class': 'cbi-body'}, body)
			])
		]);
	}
});

