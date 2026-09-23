'use strict';
'require network';

return network.registerProtocol('bonding', {
	getI18n: function() {
		return _('Bonding');
	},

	getPackageName: function() {
		return 'luci-proto-bonding';
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
