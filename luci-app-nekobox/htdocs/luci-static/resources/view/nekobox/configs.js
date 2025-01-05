'use strict';
'require view';
'require uci';

return view.extend({
	load: function() {
		return uci.load('neko');
	},
	render: function() {
		return E('iframe', {
			src: window.location.protocol + "//" + window.location.hostname + '/nekobox/configs.php',
			style: 'width: 100%; min-height: 95vh; border: none; border-radius: 5px; resize: vertical;'
		});
	},
	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});