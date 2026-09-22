'use strict';
'require honk.common as honk';

return honk.createConfigFileView(
	'/etc/honk/config.d/dns.dae',
	_('DNS Settings'),
	_('Configure DNS settings for HONK.'),
	_('DNS Configuration'),
	_('DNS configuration saved and service reloaded.')
);
