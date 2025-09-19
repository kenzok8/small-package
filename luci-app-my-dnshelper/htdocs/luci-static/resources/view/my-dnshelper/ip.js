'use strict';
'require fs';
'require ui';

return L.view.extend({
	load: function() {
		return fs.trimmed('/etc/my-dnshelper/ip.mdhp').catch(function(err) {
			ui.addNotification(null, E('p', {}, _('Unable to load the customized ip file: ' + err.message)));
			return '';
		});
	},

	render: function(data) {
		return E('div', {'class': 'cbi-map'}, [
			E('h2', {'name': 'content'}, [ _('Block IP List') ]),
			E('div', {'class': 'cbi-map-descr'}, [
				_('Will Always block IP/IPs of here. Can use 10.1.1.0/24')
			]),
			E('div', {'class': 'cbi-section'}, [
				E('textarea', {
					'id': 'ips_list',
					'style': 'width: 99%; margin: 2px;',
					'rows': 15
				}, data)
			])
		]);
	},

	handleSave: function(ev) {
		var map = document.querySelector('#ips_list');
		return fs.write('/etc/my-dnshelper/ip.mdhp', map.value.trim().replace(/\r\n/g, '\n') + '\n');
	},

	addFooter: function() {
		return E('div', { 'class': 'cbi-page-actions' }, [
			E('button', {
				'class': 'cbi-button cbi-button-save',
				'click': L.ui.createHandlerFn(this, 'handleSave')
			}, [ _('Save') ])
		]);
	}
});