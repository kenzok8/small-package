'use strict';
'require view';
'require ui';

'require fchomo as hm';

const isReadonlyView = !L.hasViewPermission() || null;

return view.extend({
	load() {
		return L.resolveDefault(hm.readFile('templates', 'hosts.yaml'), '');
	},

	handleSave(ev) {
		let value = (document.querySelector('textarea').value || '').trim().replace(/\r\n/g, '\n') + '\n';

		return hm.writeFile('templates', 'hosts.yaml', value).then((rc) => {
			document.querySelector('textarea').value = value;
			ui.addNotification(null, E('p', _('Contents have been saved.')), 'info');
		}).catch((e) => {
			ui.addNotification(null, E('p', _('Unable to save contents: %s').format(e)));
		});
	},

	render(content) {
		return E([
			E('h2', _('Hosts')),
			E('p', { 'class': 'cbi-section-descr' }, _('Custom internal hosts. Support <code>yaml</code> or <code>json</code> format.')),
			E('p', {}, E('textarea', {
				'class': 'cbi-input-textarea',
				'placeholder': "hosts:\n  '*.clash.dev': 127.0.0.1\n  'alpha.clash.dev': '::1'\n  test.com: [1.1.1.1, 2.2.2.2]\n  baidu.com: google.com",
				'style': 'width:100%;font-family:' + hm.monospacefonts.join(','),
				'rows': 25,
				'disabled': isReadonlyView
			}, [ content ? content : 'hosts:\n' ]))
		]);
	},

	handleSaveApply: null,
	handleReset: null
});
