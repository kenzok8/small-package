'use strict';
'require view';
'require ui';
'require form';
'require rpc';
'require uci';
'require tools.widgets as widgets';
'require tools.github as github';

var methods = [
	// aead
	'aes-128-gcm',
	'aes-192-gcm',
	'aes-256-gcm',
	'chacha20-ietf-poly1305',
	'xchacha20-ietf-poly1305',
	// stream
	'table',
	'rc4',
	'rc4-md5',
	'aes-128-cfb',
	'aes-192-cfb',
	'aes-256-cfb',
	'aes-128-ctr',
	'aes-192-ctr',
	'aes-256-ctr',
	'bf-cfb',
	'camellia-128-cfb',
	'camellia-192-cfb',
	'camellia-256-cfb',
	'salsa20',
	'chacha20',
	'chacha20-ietf',
];

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});	

function getServiceStatus() {
	return L.resolveDefault(callServiceList('ss-redir'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['ss-redir']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var renderHTML = "";
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';

	if (isRunning) {
		renderHTML += String.format(spanTemp, 'green', _("ss-redir "), _("running..."));
	} else {
		renderHTML += String.format(spanTemp, 'red', _("ss-redir "), _("not running..."));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return uci.load('kcptun');
	},
	render: function() {
		var m, s, o;

		m = new form.Map('ss-redir', _('ss-redir'));
		m.description = github.luci_desc('ss-redir redirect tcp service to kcptun client process.', 'liudf0716', 'ss-redir');

		// add kcptun-client status section and option 
		s = m.section(form.NamedSection, '_status');
		s.anonymous = true;
		s.render = function (section_id) {
			L.Poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function(res) {
					var view = document.getElementById("service_status");
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-map' },
				E('fieldset', { class: 'cbi-section'}, [
					E('p', { id: 'service_status' },
						_('Collecting data ...'))
				])
			);
		}

        s = m.section(form.NamedSection, 'server', 'ss_redir');
		s.dynamic = true;

        // add two tabs 
		s.tab('ss-redir', _('ss-redir Settings'));
        s.tab('server', _('Shadowsocks Server Settings'));
        
		// ss-redir settings
        o = s.taboption('ss-redir', form.Flag, "enabled", _("Enable"),
            _("Enable ss-redir service"));
        o.rmempty = false;

        // server settings
        o = s.taboption('ss-redir', form.Value, "server", _("Server Address"),
            _("The address of kcptun client listening on. default: 127.0.0.1"));
        o.datatype = "host";
        o.rmempty = false;
		o.titleref = L.url('admin', 'vpn', 'kcptun');

        o = s.taboption('ss-redir', form.Value, "server_port", _("Server Port"),
            _("The port of kcptun client listening on. default: 12948"));
        o.datatype = "port";
        o.rmempty = false;

        o = s.taboption('ss-redir', form.Value, "password", _("Password"),
            _("The password of shadowsocks server"));
        o.password = true;
        o.rmempty = false;

        o = s.taboption('ss-redir', form.ListValue, "encrypt", _("Encryption Method"),
            _("The encryption method of shadowsocks server"));
		methods.forEach(function (method) {
			o.value(method, method);
		});
        o.rmempty = false;

        // add a textarea to show the config file content
		o = s.taboption('server', form.DummyValue, "_config", _("Server Command"), 
			_("Copy the command to run ss-server on the server side"));
		o.rawhtml = true;
		o.cfgvalue = function(section_id) {
			var server = uci.get('ss-redir', section_id, 'server');
			var password = uci.get('ss-redir', section_id, 'password');
			var encrypt = uci.get('ss-redir', section_id, 'encrypt');
			var kcp_port = uci.get('ss-redir', section_id, 'kcp_port') || 6441;
			
			var config = "ss-server -s " + server + " -p " + kcp_port + " -k " + password + " -m " + encrypt;
			return "<textarea style='width:100%;height:50px;'>" + config + "</textarea>";
		}
		// add a button to copy the command
		o = s.taboption('server', form.Button, "_copy", _("Copy Command"));
		o.inputstyle = 'apply';
		o.inputtitle = _("Copy the command to clipboard");
		o.onclick = function(ev) {
			var textarea = document.querySelector('textarea');
			textarea.select();
			document.execCommand('copy');
			ui.addNotification(null, E('p', _('Copied to clipboard')), 'info');
		};

		return m.render();
	}
});
