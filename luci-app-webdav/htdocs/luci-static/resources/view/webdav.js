'use strict';
'require form';
'require poll';
'require uci';
'require view';

function renderStatus(isEnable, webport, protocol) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isEnable === '1') {
		var button = String.format('<input class="cbi-button-reload" type="button" style="margin-left: 50px" value="%s" onclick="window.open(\'%s//%s:%s/\')">',
			_('Open Web Interface'), protocol, window.location.hostname, webport);
		renderHTML = spanTemp.format('green', _('WebDAV'), _('RUNNING')) + button;
	} else {
		renderHTML = spanTemp.format('red', _('WebDAV'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('webdav')
		]);
	},

	handleDownloadReg: function (m, section_id, ev) {
		const regContent = `Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\WebClient\\Parameters]
"BasicAuthLevel"=dword:00000002
"FileSizeLimitInBytes"=dword:ffffffff
`;
		const blob = new Blob([regContent], { type: 'text/plain' });
		const link = document.createElement('a');
		link.download = 'allow_http.reg';
		link.href = window.URL.createObjectURL(blob);
		link.click();
	},

	render: function(data) {
		var m, s, o;
		var webport = uci.get(data[0], 'config', 'listen_port');
		var isEnable = uci.get(data[0], 'config', 'enable');
		var ssl = uci.get(data[0], 'config', 'ssl') || '0';
		var protocol;
		if (ssl === '0') {
			protocol = 'http:';
		} else if (ssl === '1') {
			protocol = 'https:';
		}

		m = new form.Map('webdav', _('WebDAV'),
			_('A lightweight, simple, and fast WebDAV server based on NGINX.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			setTimeout(function () {
				poll.add(function () {
				var view = document.getElementById('service_status');
				if (view) {
					view.innerHTML = renderStatus(isEnable, webport, protocol);
				}
			});
			}, 100);

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'webdav');

		o = s.option(form.Flag, 'enable', _('Enable'));
		o.rmempty = false;

		o = s.option(form.Value, 'listen_port', _('Listen Port'));
		o.default = 6086;
		o.rmempty = false;

		o = s.option(form.Value, 'username', _('Username'));

		o = s.option(form.Value, 'password', _('Password'), _("Leave blank to disable auth."));
		o.password = true;

		o = s.option(form.Value, 'root_dir', _('WebDAV Directory'));
		o.default = '/mnt';
		o.rmempty = false;

		o = s.option(form.Flag, 'read_only', _('Read-Only Mode'));
		o.default = false;
		o.rmempty = false;

		o = s.option(form.Flag, 'firewall_accept', _('Open firewall port'));
		o.rmempty = false;

		o = s.option(form.Flag, 'ssl', _('Enable SSL'));
		o.rmempty = false;

		o = s.option(form.Value, 'cert_cer', _('SSL cert'), _('SSL certificate file path.'));
		o.rmempty = false;
		o.depends('ssl', '1');

		o = s.option(form.Value, 'cert_key', _('SSL key'), _('SSL key file path.'));
		o.rmempty = false;
		o.depends('ssl', '1');

		o = s.option(form.Button, '_downloadreg', null,
			_('Windows doesn\'t allow HTTP auth by default, you need to import this reg key to enable it (Reboot needed).'));
		o.title = _('Download Reg File');
		o.inputtitle = _('Click Download');
		o.inputstyle = 'apply';
		o.onclick = L.bind(this.handleDownloadReg, this, m);

		return m.render();
	}
});
