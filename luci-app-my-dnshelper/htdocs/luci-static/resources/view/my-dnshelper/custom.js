'use strict';
'require fs';
'require ui';

return L.view.extend({
	load: function() {
		return fs.trimmed('/etc/my-dnshelper/user.mdhp').catch(function(err) {
			ui.addNotification(null, E('p', {}, _('Unable to load the customized user file: ' + err.message)));
			return '';
		});
	},

	render: function(data) {
		return E('div', {'class': 'cbi-map'}, [
			E('h2', {'name': 'content'}, [ _('User Rules') ]),
			E('div', {'class': 'cbi-section'}, [
				E('textarea', {
					'id': 'user_rules',
					'style': 'width: 99%; margin: 2px;',
					'rows': 20
				}, data)
			]),
			E('div', [
				E('div',[E('strong', {}, E('span', {'style': 'color: red;'}, '||example.mal^ : ')),
				_('Block example.mal and all its subdomains.')]),
				E('br'),
				E('div',[E('strong', {}, E('span', {'style': 'color: red;'}, '@@||example.hao^ : ')),
				_('Do not block example.hao and its subdomains.')]),
				E('br'),
				E('div',[E('strong', {}, E('span', {'style': 'color: red;'}, '127.0.0.1 hostname.ex : ')),
				_('Responds hostname.ex with 127.0.0.1,but excluding its subdomains.')]),
				E('br'),
				E('div',[E('strong', {}, E('span', {'style': 'color: red;'}, 'server=/dns.ex/1.1.1.1 : ')),
				_('Search dns for dns.ex from 1.1.1.1')]),
				E('br'),
				E('div',[E('strong', {}, E('span', {'style': 'color: red;'}, '# xxx : ')),
				_('# a one line comment.')]),
				E('br')
			])
		]);
	},

	handleSave: function(ev) {
		var map = document.querySelector('#user_rules');
		return fs.write('/etc/my-dnshelper/user.mdhp', map.value.trim().replace(/\r\n/g, '\n') + '\n');
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
