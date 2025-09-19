/*   Copyright (C) 2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-watchdog */

'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require form';
'require poll';

function checkProcess() {
    return fs.exec('/bin/pidof', ['watchdog']).then(function(res) {
        return {
            running: res.code === 0,
            pid: res.code === 0 ? res.stdout.trim() : null
        };
    }).catch(function() {
        return { running: false, pid: null };
    });
}

function renderStatus(isRunning) {
    var statusText = isRunning ? _('RUNNING') : _('NOT RUNNING');
    var color = isRunning ? 'green' : 'red';
    var icon = isRunning ? '✓' : '✗'; 
    
    return String.format(
        '<em><span style="color:%s">%s <strong>%s %s</strong></span></em>',
        color, icon, _('watchdog'), statusText
    );
}
var cbiRichListValue = form.ListValue.extend({
	renderWidget: function (section_id, option_index, cfgvalue) {
		var choices = this.transformChoices();
		var widget = new ui.Dropdown((cfgvalue != null) ? cfgvalue : this.default, choices, {
			id: this.cbid(section_id),
			sort: this.keylist,
			optional: true,
			select_placeholder: this.select_placeholder || this.placeholder,
			custom_placeholder: this.custom_placeholder || this.placeholder,
			validate: L.bind(this.validate, this, section_id),
			disabled: (this.readonly != null) ? this.readonly : this.map.readonly
		});

		return widget.render();
	},

	value: function (value, title, description) {
		if (description) {
			form.ListValue.prototype.value.call(this, value, E([], [
				E('span', { 'class': 'hide-open' }, [title]),
				E('div', { 'class': 'hide-close', 'style': 'min-width:25vw' }, [
					E('strong', [title]),
					E('br'),
					E('span', { 'style': 'white-space:normal' }, description)
				])
			]));
		}
		else {
			form.ListValue.prototype.value.call(this, value, title);
		}
	}
});

return view.extend({

    render: function() {

        var  m, s, o;
	m = new form.Map('watchdog', _('watchdog'), _('This is the security watchdog plugin for OpenWRT, which monitors and guards web login, SSH connections, and other situations.<br /><br />If you encounter any issues while using it, please submit them here:') + '<a href="https://github.com/sirpdboy/luci-app-watchdog" target="_blank">' + _('GitHub Project Address') + '</a>');
        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.render = function() {
            var statusView = E('p', { id: 'control_status' }, 
                '<span class="spinning"> </span> ' + _('Checking status...'));
            
            poll.add(function() {
                return checkProcess()
                    .then(function(res) {
                        var status = renderStatus(res.running);
                        if (res.running && res.pid) {
                            status += ' <small>(PID: ' + res.pid + ')</small>';
                        }
                        statusView.innerHTML = status;
                    })
                    .catch(function(err) {
                        statusView.innerHTML = '<span style="color:orange">⚠ ' + 
                            _('Status check failed') + '</span>';
                        console.error('Status check error:', err);
                    });
            });

            poll.start();
            return E('div', { class: 'cbi-section', id: 'status_bar' }, [ statusView ,
	       E('div', { 'style': 'text-align: right; font-style: italic;' }, [
                    E('span', {}, [
                    _('© github '),
                    E('a', { 
                        'href': 'https://github.com/sirpdboy', 
                        'target': '_blank',
                        'style': 'text-decoration: none;'
                    }, 'by sirpdboy')
                ])
            ])
]);
        }

		s = m.section(form.NamedSection, 'config', 'watchdog', _(''));
		s.tab('basic', _('Basic Settings'));
		s.tab('blacklist', _('Black list'));
		s.addremove = false;
		s.anonymous = true;

		o = s.taboption('basic', form.Flag, 'enable', _('Enabled'));
		o = s.taboption('basic', form.Value, 'sleeptime', _('Check Interval (s)'));
		o.rmempty = false;
		o.placeholder = '60';
		o.datatype = 'and(uinteger,min(10))';
		o.description = _('Shorter intervals provide quicker response but consume more system resources.');

		o = s.taboption('basic', form.MultiValue, 'login_control', _('Login control'));
		o.value('web_logged', _('Web Login'));
		o.value('ssh_logged', _('SSH Login'));
		o.value('web_login_failed', _('Frequent Web Login Errors'));
		o.value('ssh_login_failed', _('Frequent SSH Login Errors'));
		o.modalonly = true;

		o = s.taboption('basic', form.Value, 'login_max_num', _('Login failure count'));
		o.default = '3';
		o.rmempty = false;
		o.datatype = 'and(uinteger,min(1))';
		o.depends({ login_control: "web_login_failed", '!contains': true });
		o.depends({ login_control: "ssh_login_failed", '!contains': true });
		o.description = _('Reminder and optional automatic IP ban after exceeding the number of times');

		o = s.taboption('blacklist', form.Flag, 'login_web_black', _('Auto-ban unauthorized login devices'));
		o.default = '0';
		o.depends({ login_control: "web_login_failed", '!contains': true });
		o.depends({ login_control: "ssh_login_failed", '!contains': true });
		
		o = s.taboption('blacklist', form.Value, 'login_ip_black_timeout', _('Blacklisting time (s)'));
		o.default = '86400';
		o.rmempty = false;
		o.datatype = 'and(uinteger,min(0))';
		o.depends('login_web_black', '1');
		o.description = _('\"0\" in ipset means permanent blacklist, use with caution. If misconfigured, change the device IP and clear rules in LUCI.');

		o = s.taboption('blacklist', form.TextValue, 'ip_black_list', _('IP blacklist'));
		o.rows = 8;
		o.wrap = 'soft';
		o.cfgvalue = function (section_id) {
			return fs.trimmed('/usr/share/watchdog/api/ip_blacklist');
		};
		o.write = function (section_id, formvalue) {
			return this.cfgvalue(section_id).then(function (value) {
				if (value == formvalue) {
					return
				}
				return fs.write('/usr/share/watchdog/api/ip_blacklist', formvalue.trim().replace(/\r\n/g, '\n') + '\n');
			});
		};
		o.depends('login_web_black', '1');
		o.description = _('Automatic ban blacklist list, with the ban time following the IP address');

		o = s.taboption('blacklist', form.Value, 'login_port_white', _('Port'));
		o.default = '';
		o.description = _('Open port after successful login<br/>example：\"22\"、\"21:25\"、\"21:25,135:139\"');
		o.depends('port_release_enable', '1');

		o = s.taboption('blacklist', form.DynamicList, 'login_port_forward_list', _('Port Forwards'));
		o.default = '';
		o.description = _('Example: Forward port 13389 of this device (IPv4:10.0.0.1 / IPv6:fe80::10:0:0:2) to port 3389 of (IPv4:10.0.0.2 / IPv6:fe80::10:0:0:8)<br/>\"10.0.0.1,13389,10.0.0.2,3389\"<br/>\"fe80::10:0:0:1,13389,fe80::10:0:0:2,3389\"');
		o.depends('port_release_enable', '1');

		o = s.taboption('blacklist', form.Value, 'login_ip_white_timeout', _('Release time (s)'));
		o.default = '86400';
		o.datatype = 'and(uinteger,min(0))';
		o.description = _('\"0\" in ipset means permanent release, use with caution');
		o.depends('port_release_enable', '1');

	        
		return m.render();

	}
});
