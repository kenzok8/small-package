'use strict';
'require view';
'require uci';

return view.extend({
	load: function() {
		return uci.load('neko');
	},
	render: async function() {
		
		const url_data = await fetch('/nekobox/lib/log.php?data=url_dash').then(function (response) {
			return response.json();
		}).then(function (data){
			return data;
		}).catch(function (error) {
			console.log(error);
		});
		return E('iframe', {
			src: url_data.yacd,
			style: 'width: 100%; min-height: 95vh; border: none; border-radius: 5px; resize: vertical;'
		});
	},
	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});