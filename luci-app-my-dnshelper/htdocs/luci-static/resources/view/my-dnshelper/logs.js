'use strict';
'require fs';
'require ui';

return L.view.extend({
	load: function() {
		return fs.trimmed('/tmp/my-dnshelper.log').catch(function(err) {
			return '';
		});
	},

	render: function(data) {
		return E('div', {'class': 'cbi-map'}, [
			E('h2', {'name': 'content'}, [ _('Helper Log') ]),
			E('div', {'class': 'cbi-section'}, [
				E('textarea', {
					'id': 'logs',
					'readonly': 'true',
					'style': 'width: 99%; margin: 2px;',
					'wrap': 'off',
					'rows': 16
				}, data)
			])
		]);
	},

	handleClear: function(ev) {
		return fs.write('/tmp/my-dnshelper.log', '\n').then(function(s){
				try{
					window.location=location;
				}catch(e){}
			});
	},

	addFooter: function() {
		return E('div', { 'class': 'cbi-page-actions' }, [
			E('button', {
				'class': 'cbi-button cbi-button-reload',
				'click': L.ui.createHandlerFn(this, 'handleClear')
			}, [ _('Clear') ])
		]);
	}
});