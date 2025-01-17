'use strict';
'require view';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	load() {
	},

	render() {
		return E('iframe', {
			src: window.location.protocol + '//' + window.location.hostname + '/tinyfilemanager/',
			style: 'width: 100%; min-height: 100vh; border: none; border-radius: 3px;'
		});
	}
});
