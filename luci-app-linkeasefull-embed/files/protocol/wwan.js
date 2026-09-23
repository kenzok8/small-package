'use strict';
'require network';

return network.registerProtocol('wwan', {
	getI18n: function() {
		return _('WWAN');
	},

	getPackageName: function() {
		return 'wwan';
	},

	isFloating: function() {
		return true;
	},

	isVirtual: function() {
		return true;
	},

	getDevices: function() {
		return null;
	}
});
