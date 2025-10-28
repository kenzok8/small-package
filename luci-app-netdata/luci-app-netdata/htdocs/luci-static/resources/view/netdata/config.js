// Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netdata
'use strict';
'require view';
'require fs';
'require ui';

const isReadonlyView = !L.hasViewPermission() || null;

return view.extend({
handleSaveApply: null,
handleReset: null,

	load() {
		return L.resolveDefault(fs.read('/etc/netdata/netdata.conf'), '');
	},

	handleSave(ev) {
		let value = (document.querySelector('textarea').value || '').trim().replace(/\r\n/g, '\n') + '\n';

		return fs.write('/etc/netdata/netdata.conf', value).then((rc) => {
			document.querySelector('textarea').value = value;
			ui.addNotification(null, E('p', _('Contents have been saved.')), 'info');

			return fs.exec('/etc/init.d/netdata', [ 'restart' ]);
		}).catch((e) => {
			ui.addNotification(null, E('p', _('Unable to save contents: %s').format(e.message)));
		});
	},

	render(conf) {
		return E([
			E('h4', _('Edit Netdata main config: <code>/etc/netdata/netdata.conf</code>')),
			E('p', {}, E('textarea', { 'style': 'width:100%', 'rows': 25, 'disabled': isReadonlyView }, [ conf != null ? conf : '' ]))
		]);
	}
});
