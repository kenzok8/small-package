'use strict';
'require honk.common as honk';

return honk.createConfigFileView(
	'/etc/honk/config.d/node.dae',
	_('Node Settings'),
	_('Configure nodes and groups for HONK.'),
	_('Node Configuration'),
	_('Node configuration saved and service reloaded.')
);
