'use strict';
'require fs';
'require ui';

return L.view.extend({
	getLog: function() {
		return L.resolveDefault(fs.exec('/usr/share/my-dnshelper/waiter',['--dnslog']), '').then(function(s) {
			try{
				s = s.stdout.trim();
			} catch(err){ return '';}
			return s;
		});
	},
	load: function() {
		return this.getLog().catch(function(err) {
			return '';
		});
	},

	render: function(data) {
		var l = data.split(/\n/);
		return E('div', {'class': 'cbi-map'}, [
			E('h2', {'name': 'content'}, [ _('DNS Query Log') ]),
			E('div', {'class': 'cbi-map-descr'}, [ _('Display the latest query log here.') ]),
			E('div', {'class': 'cbi-section'}, [
				E('textarea', {
					'id': 'dnslogs',
					'readonly': 'true',
					'style': 'width: 99%; margin: 2px;',
					'wrap': 'off',
					'rows': l.length+1
				}, data)
			])
		]);
	},

	handleClear: function(ev) {
		return fs.write('/var/log/dnsmasq.log', '\n').then(function(s){
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