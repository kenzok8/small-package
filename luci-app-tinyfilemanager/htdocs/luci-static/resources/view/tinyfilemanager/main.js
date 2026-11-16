'use strict';
'require view';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	load() {
	},

	render() {
		const sid = L.env.sessionid || '';
		const url = window.location.protocol + '//' + window.location.hostname + '/tinyfilemanager/' + `?luci_sid=${sid}`;
		return E('iframe', {
			src: url,
			style: 'width: 100%; min-height: 100vh; border: none; border-radius: 3px;'
		});
	}
});
