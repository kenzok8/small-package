'use strict';
'require honk.common as honk';

return honk.createConfigFileView(
	'/etc/honk/config.d/route.dae',
	_('Routing Settings'),
	_('Configure routing rules for HONK.'),
	_('Route Configuration'),
	_('Routing configuration saved and service reloaded.')
);
