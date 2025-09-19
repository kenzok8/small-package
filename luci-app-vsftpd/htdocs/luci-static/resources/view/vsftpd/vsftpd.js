/*
 * Copyright (c) 2020 Tano Systems. All Rights Reserved.
 * Author: Anton Kikin <a.kikin@tano-systems.com>
 */

'use strict';
'require rpc';
'require form';
'require uci';

var callInitList = rpc.declare({
	object: 'luci',
	method: 'getInitList',
	params: [ 'name' ],
	expect: { '': {} },
	filter: function(res) {
		for (var k in res)
			return +res[k].enabled;
		return null;
	}
});

var callInitAction = rpc.declare({
	object: 'luci',
	method: 'setInitAction',
	params: [ 'name', 'action' ],
	expect: { result: false }
});

return L.view.extend({
	load: function() {
		return Promise.all([
			callInitList('vsftpd'),
			uci.load('vsftpd')
		]);
	},

	populateServiceSettings: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Service Settings
		//
		// ------------------------------------------------------
		var serviceEnabled = data[0];

		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_service',
			form.NamedSection, 'listen', 'listen');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enable FTP server'),
			_('Run FTP server on system\'s startup'));
		o.rmempty = false;

		o.cfgvalue = function() {
			return serviceEnabled ? this.enabled : this.disabled;
		};

		o.write = function(section_id, value) {
			uci.set('vsftpd', section_id, 'enabled', value);

			if (value == '1') {
				// Enable and start
				return callInitAction('vsftpd', 'enable').then(function() {
					return callInitAction('vsftpd', 'start');
				});
			}
			else {
				// Stop and disable
				return callInitAction('vsftpd', 'stop').then(function() {
					return callInitAction('vsftpd', 'disable');
				});
			}
		};

		o = s.option(form.Flag, 'enable4', _('Enable IPv4'));
		o.rmempty = false;
		o.default = true;

		o = s.option(form.Value, 'ipv4', _('IPv4 Address'));
		o.datatype = 'ip4addr';
		o.default = '0.0.0.0';
		o.depends('enable4', '1');

		o = s.option(form.Flag, 'enable6', _('Enable IPv6'));
		o.rmempty = false;

		o = s.option(form.Value, 'ipv6', _('IPv6 Address'));
		o.datatype = 'ip6addr';
		o.default = '::';
		o.depends('enable6', '1');

		o = s.option(form.Value, 'port', _('Listen Port'));
		o.datatype = 'uinteger';
		o.default = '21';

		o = s.option(form.Value, 'dataport', _('Data Port'));
		o.datatype = 'uinteger';
		o.default = '20';
	},

	populateGlobalSettings: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Global Settings
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_global',
			form.NamedSection, 'global', 'global');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'write',
			_('Enable write'),
			_('When disabled, all write request will give permission denied'));
		o.default = true;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Flag, 'download',
			_('Enable download'),
			_('When disabled, all download request will give permission denied'));
		o.default = true;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Flag, 'dirlist',
			_('Enable directory list'),
			_('When disabled, list commands will give permission denied'));
		o.default = true;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Flag, 'lsrecurse',
			_('Allow directory recursely list'));

		o = s.option(form.Flag, 'dotfile',
			_('Show dot files'),
			_('If activated, files and directories starting with \'.\' will be shown in ' +
			  'directory listings even if the \'a\' flag was not used by the client. ' +
			  'This override excludes the \'.\' and \'..\' entries'));
		o.default = true;

		o = s.option(form.Value, 'umask',
			_('File mode umask'),
			_('Uploaded file mode will be 666&thinsp;&minus;&thinsp;umask, directory ' +
			  'mode will be 777&thinsp;&minus;&thinsp;umask'));
		o.default = '022';

		o = s.option(form.Value, 'banner', _('FTP banner'));

		o = s.option(form.Flag, 'dirmessage',
			_('Enable directory message'),
			_('A message will be displayed when entering a directory'));

		o = s.option(form.Value, 'dirmsgfile',
			_('Directory message filename'));
		o.default = '.message';
	},

	populateLocalUsers: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Local Users
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_local',
			form.NamedSection, 'local', 'local');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled',
			_('Enable local users'));
		o.rmempty = false;

		o = s.option(form.Value, 'root',
			_('Root directory'),
			_('Leave empty will use user\'s home directory'));
		o.default = '';
	},

	populateConnectionSettings: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Connection Settings
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_connection',
			form.NamedSection, 'connection', 'connection');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'portmode', _('Enable PORT mode'));
		o = s.option(form.Flag, 'pasvmode', _('Enable PASV mode'));

		o = s.option(form.Value, 'pasvminport',
			_('The minimum port to allocate for PASV style data connections'));
		o.depends('pasvmode', '1');
		o.datatype = 'range(1024,65535)';
		o.default = '10050';

		o = s.option(form.Value, 'pasvmaxport',
			_('The maximum port to allocate for PASV style data connections'));
		o.depends('pasvmode', '1');
		o.datatype = 'range(1024,65535)';
		o.default = '10100';

		o = s.option(form.ListValue, 'ascii', _('ASCII mode'));
		o.value('disabled', _('Disabled'));
		o.value('download', _('Download only'));
		o.value('upload', _('Upload only'));
		o.value('both', _('Both download and upload'));
		o.default = 'both';

		o = s.option(form.Value, 'idletimeout',
			_('Idle session timeout'),
			_('In seconds'));
		o.datatype = 'uinteger';
		o.default = '1800';

		o = s.option(form.Value, 'conntimeout',
			_('Connection timeout'),
			_('In seconds'));
		o.datatype = 'uinteger';
		o.default = '120';

		o = s.option(form.Value, 'dataconntimeout',
			_('Data connection timeout'),
			_('In seconds'));
		o.datatype = 'uinteger';
		o.default = '120';

		o = s.option(form.Value, 'maxclient',
			_('Max clients'),
			_('0 means no limitation'));
		o.datatype = 'uinteger';
		o.default = '0';

		o = s.option(form.Value, 'maxperip',
			_('Max clients per IP'),
			_('0 means no limitation'));
		o.datatype = 'uinteger';
		o.default = '0';

		o = s.option(form.Value, 'maxrate',
			_('Max transmit rate'),
			_('Bytes/s, 0 means no limitation'));
		o.datatype = 'uinteger';
		o.default = '0';

		o = s.option(form.Value, 'maxretry',
			_('Max login fail count'),
			_('Can not be zero, default is 3'));
		o.datatype = 'uinteger';
		o.default = '3';
	},

	populateCommonUserOptions: function(s) {
		var o;

		o = s.option(form.Value, 'umask', _('File mode umask'));
		o.modalonly = true;
		o.default = '022';

		o = s.option(form.Value, 'maxrate',
			_('Max transmit rate'),
			_('Bytes/s, 0 means no limitation'));
		o.default = '0';
		o.modalonly = true;

		o = s.option(form.Flag, 'writemkdir',
			_('Enable write/mkdir'));
		o.default = false;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Flag, 'upload',
			_('Enable upload'));
		o.default = false;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Flag, 'others',
			_('Enable other rights'),
			_('Include rename, deletion, ...'));
		o.default = false;
		o.rmempty = false;
		o.optional = false;
	},

	populateVirtualUsers: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Virtual User Settings
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_vuser',
			form.NamedSection, 'vuser', 'vuser');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled',
			_('Enable virtual users'));
		o.default = false;

		o = s.option(form.Value, 'username', _('Username'),
			_('An actual local user to handle virtual users'));
		o.default = 'ftp';

		o = _s.taboption(tab, form.SectionValue, '_user',
			form.GridSection, 'user');
		s = o.subsection;
		s.addremove = true;
		s.anonymous = true;
		s.nodescriptions = true;
		s.modaltitle = function(section_id) {
			var username = uci.get('vsftpd', section_id, 'username');

			if (username)
				return _('Virtual Users') + ' » ' + username;
			else
				return _('Add New Virtual User');
		};

		o = s.option(form.Value, 'username', _('Username'));
		o.rmempty = false;
		o.validate = function(section_id, value) {
			if (value == '')
				return _('Username cannot be empty');
			return true;
		};

		o = s.option(form.Value, 'password', _('Password'));
		o.password = true;
		o.modalonly = true;
		o.rmempty = false;

		o = s.option(form.Value, 'home', _('Home directory'));
		o.rmempty = false;
		o.default = '/home/ftp';
		o.validate = function(section_id, value) {
			if (value == '')
				return _('Home directroy cannot be empty');
			return true;
		};

		this.populateCommonUserOptions(s);
	},

	populateAnonymousSettings: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Anonymous User Settings
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_anonymous',
			form.NamedSection, 'anonymous', 'anonymous');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enable anonymous user'));
		o.default = false;
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Value, 'username',
			_('Username'),
			_('An actual local user to handle anonymous user'));
		o.default = 'ftp';

		o = s.option(form.Value, 'root',
			_('Root directory'));
		o.default = '/home/ftp';

		this.populateCommonUserOptions(s);
	},

	populateLogSettings: function(tab, _s, data) {
		// ------------------------------------------------------
		//
		// Log Settings
		//
		// ------------------------------------------------------
		var o, s;
		o = _s.taboption(tab, form.SectionValue, '_log',
			form.NamedSection, 'log', 'log');

		s = o.subsection;
		s.addremove = false;
		s.anonymous = true;

		o = s.option(form.ListValue, 'mode',
			_('Enable logging'));

		o.value('disabled', _('disable'));
		o.value('file',     _('to file'));
		o.value('syslog',   _('to syslog'));
		o.default = 'file';

		o.cfgvalue = function(section_id) {
			var syslog = uci.get('vsftpd', section_id, 'syslog');
			var file   = uci.get('vsftpd', section_id, 'file');

			if (syslog == '1')
				return 'syslog';
			else if (file && (file != ''))
				return 'file';
			else
				return 'disabled';
		};

		o.write = function(section_id, value) {
			if (value == 'file') {
				uci.set('vsftpd', section_id, 'syslog',  '0');
				uci.set('vsftpd', section_id, 'xferlog', '1');
			}
			else if (value == 'syslog') {
				uci.set('vsftpd', section_id, 'syslog',  '1');
				uci.set('vsftpd', section_id, 'xferlog', '1');
			}
			else {
				uci.set('vsftpd', section_id, 'syslog',  '0');
				uci.set('vsftpd', section_id, 'xferlog', '0');
				uci.set('vsftpd', section_id, 'file',    '');
			}
		};

		o = s.option(form.Value, 'file', _('Log file'));
		o.default = '/var/log/vsftpd.log';
		o.rmempty = true;
		o.depends('mode', 'file');
	},

	render: function(data) {
		var m, s;

		m = new form.Map('vsftpd', _('FTP Server Settings'),
			_('On this page you may configure FTP server settings'));

		s = m.section(form.NamedSection, 'global', 'global');

		s.addremove = false;
		s.anonymous = true;

		s.tab('service',       _('Service Settings'));
		s.tab('connection',    _('Connection Settings'));
		s.tab('global',        _('Global Settings'));
		s.tab('local',         _('Local Users'));
		s.tab('virtual',       _('Virtual Users'));
		s.tab('anonymous',     _('Anonymous User'));
		s.tab('log',           _('Log Settings'));

		this.populateServiceSettings    ('service',    s, data);
		this.populateConnectionSettings ('connection', s, data);
		this.populateGlobalSettings     ('global',     s, data);
		this.populateLocalUsers         ('local',      s, data);
		this.populateVirtualUsers       ('virtual',    s, data);
		this.populateAnonymousSettings  ('anonymous',  s, data);
		this.populateLogSettings        ('log',        s, data);

		return m.render();
	}
});
