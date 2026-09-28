'use strict';
'require honk.common as honk';

return honk.createConfigFileView(
	'/etc/honk/config.d/api.dae',
	_('API Settings'),
	_('Configure API settings for HONK.'),
	_('API Configuration'),
	_('API configuration saved and service restarted.'),
	true
);
