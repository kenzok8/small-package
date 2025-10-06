'use strict';
'require view';
'require dom';
'require fs';
'require ui';
'require uci';
'require network';

return view.extend({
	handleCommand: function(exec, args) {
		var buttons = document.querySelectorAll('.diag-action > .cbi-button');

		for (var i = 0; i < buttons.length; i++)
			buttons[i].setAttribute('disabled', 'true');

		return fs.exec(exec, args).then(function(res) {
			var out = document.querySelector('textarea');

			dom.content(out, [res.stdout || '', res.stderr || '']);
		}).catch(function(err) {
			ui.addNotification(null, E('p', [err]))
		}).finally(function() {
			for (var i = 0; i < buttons.length; i++)
				buttons[i].removeAttribute('disabled');
		});
	},

	handleAT: function(ev, path) {
		var exec = 'sms_tool',
			atcmd = ev.currentTarget.parentNode.previousSibling.value,
			args = ['-d', path, 'at', atcmd];

		console.log("path=" + path);
		console.log("atcmd=" + atcmd);
		return this.handleCommand(exec, args);
	},

	load: function() {
		return fs.list('/dev').then(function(devs) {
			return devs.filter(function(dev) {
				return dev.name.match(/^ttyUSB/) || dev.name.match(/^cdc-wdm/) || dev.name.match(/^ttyACM/) || dev.name.match(/^mhi_/);
			});
		});
	},

	render: function(devs) {
		var text = 'Check signal strength > AT+CSQ\nGet the temperature of MT > AT+QTEMP\nCurrent band in use > AT+QNWINFO\nCarrier Agregation Info > AT+QCAINFO\nSIM Preferred Message Storage  >  AT+CPMS="SM","SM","SM"\nSave SMS Settings  >  AT+CSAS\nReboot the modem  >  AT+CFUN=1,1\nReset the modem  >  AT+CFUN=1\nQMI/PPP/Default > AT+QCFG="usbnet",0\nECM > AT+QCFG="usbnet",1\nMBIM > AT+QCFG="usbnet",2\n4G-LTE only > AT+QCFG="nwscanmode",3,1\nWCDMA only > AT+QCFG="nwscanmode",2,1\nGSM only > AT+QCFG="nwscanmode",1,1\nScan all modes > AT+QCFG="nwscanmode",0,1';
		var devs_arr = {};
		var devs_cla = {};
		devs.sort((a, b) => a.name > b.name);
		devs.forEach(dev => devs_arr['/dev/' + dev.name] = 'Send AT command to ' + '/dev/' + dev.name);
		devs.forEach(dev => devs_cla['/dev/' + dev.name] = 'btn cbi-button cbi-button-action');
		//console.log(devs_arr);
		var table = E('table', {
			'class': 'table'
		}, [
			E('tr', {
				'class': 'tr'
			}, [
				E('td', {
					'class': 'td left',
					'style': 'overflow:initial'
				}, [
					E('input', {
						'style': 'margin:5px 0',
						'type': 'text',
						'value': 'ATI'
					}),
					E('span', {
						'class': 'diag-action'
					}, [
						new ui.ComboButton('/dev/ttyUSB2', devs_arr, {
							'click': ui.createHandlerFn(this, 'handleAT'),
							'classes': devs_cla,
						}).render()
					])
				]),
			])
		]);

		var view = E('div', {
			'class': 'cbi-map'
		}, [
			E('h2', {}, [_('Send AT command:')]),
			E('div', {
				'class': 'cbi-map-descr'
			}, _('Sending AT command to selected device com port.')),
			table,
			E('div', {
				'class': 'cbi-section'
			}, [
				E('div', {
						'id': 'command-output'
					},
					E('textarea', {
						'id': 'widget.command-output',
						'style': 'width: 100%; font-family:monospace; white-space:pre',
						'readonly': true,
						'wrap': 'off',
						'rows': '20',
						'placeholder': text,
					})
				)
			])
		]);

		return view;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});