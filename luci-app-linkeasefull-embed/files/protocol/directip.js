'use strict';
'require network';

return network.registerProtocol('directip', {
	getI18n: function() {
		return _('Direct-IP');
	},

	getPackageName: function() {
		return 'comgt-directip';
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
