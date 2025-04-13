'use strict';
'require view';
'require rpc';
'require ui';
'require uci';

var callPowerOff = rpc.declare({
	object: 'system',
	method: 'poweroffdevice', 
	expect: { result: 0 }
});

return view.extend({
	load: function() {
		return uci.changes();
	},

	render: function(changes) {
		var body = E([
			E('h2', _('PowerOff')),
			E('p', {}, _('Turn off the power to the device you are using'))
		]);

		if (changes && Object.keys(changes).length > 0) {
			body.appendChild(E('p', { 'class': 'alert-message warning' },
				_('WARNING: Power off might result in a reboot on a device which not support power off.')));
		}

		body.appendChild(E('hr'));
		body.appendChild(E('button', {
			'class': 'cbi-button cbi-button-action important',
			'click': ui.createHandlerFn(this, function() {
				ui.showModal(_('Power Off Device'), [
					E('p', {}, _('Turn off the power to the device you are using')),
					E('div', { 'class': 'right' }, [
						E('button', {
							'class': 'btn cbi-button cbi-button-apply',
							'click': ui.hideModal
						}, _('Cancel')),
						' ',
						E('button', {
							'class': 'cbi-button cbi-button-action important',
							'style': 'background-color: red; border-color: red;',
							'click': ui.createHandlerFn(this, this.handlePowerOff)
						}, _('OK'))
					])
				]);
			})
		}, _('Perform Power Off')));

		return body;
	},

	handlePowerOff: function() {
		return callPowerOff().then(function(res) {
			if (res != 0) {
				L.ui.addNotification(null, E('p', _('The PowerOff command failed with code %d').format(res)));
				L.raise('Error', 'PowerOff failed');
			}

			L.ui.showModal(_('PowerOffing…'), [
				E('p', { 'class': 'spinning' }, _('The device is shutting down...'))
			]);

			window.setTimeout(function() {
				L.ui.showModal(_('PowerOffing…'), [
					E('p', { 'class': 'alert-message warning' },
						_('The device may have powered off. If not, check manually.'))
				]);
			}, 15000);

			L.ui.awaitReconnect();
		}).catch(function(e) {
			ui.addNotification(null, E('p', _('Error: %s').format(e.message)));
		});
	},
	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
