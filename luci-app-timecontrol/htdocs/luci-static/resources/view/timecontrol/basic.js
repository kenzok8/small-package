'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require form';
'require poll';
'require rpc';
'require network';

function checkTimeControlProcess() {
    return fs.exec('/bin/ps', ['w']).then(function(res) {
        if (res.code !== 0) {
            return { running: false, pid: null };
        }
        
        var lines = res.stdout.split('\n');
        var running = false;
        var pid = null;
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.includes('timecontrolctrl')) {
                running = true;
                // 提取PID
                var match = line.match(/^\s*(\d+)/);
                if (match) {
                    pid = match[1];
                }
                break;
            }
        }
        
        return { running: running, pid: pid };
    }).catch(function() {
        return { running: false, pid: null };
    });
}

// 渲染服务状态显示
function renderServiceStatus(isRunning, pid) {
    var statusText = isRunning ? _('RUNNING') : _('NOT RUNNING');
    var color = isRunning ? 'green' : 'red';
    var icon = isRunning ? '✓' : '✗'; 
    
    var statusHtml = String.format(
        '<em><span style="color:%s">%s <strong>%s %s</strong></span></em>',
        color, icon, _('TimeControl Service'), statusText
    );
    
    if (isRunning && pid) {
        statusHtml += ' <small>(PID: ' + pid + ')</small>';
    }
    
    return statusHtml;
}

function getHostList() {
    return L.resolveDefault(network.getHostHints(), [])
        .then(function(hosts) {
            var hostList = [];
            if (hosts && hosts.length > 0) {
                hosts.forEach(function(host) {
                    if (host.ipv4 && host.mac) {
                        hostList.push({
                            ipv4: host.ipv4,
                            mac: host.mac,
                            name: host.name || '',
                            ipv6: host.ipv6 || ''
                        });
                    }
                });
            }
            return hostList;
        })
        .catch(function() {
            return [];
        });
}

var cbiRichListValue = form.ListValue.extend({
    renderWidget: function(section_id, option_index, cfgvalue) {
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

    value: function(value, title, description) {
        if (description) {
            form.ListValue.prototype.value.call(this, value, E([], [
                E('span', { 'class': 'hide-open' }, [title]),
                E('div', { 'class': 'hide-close', 'style': 'min-width:25vw' }, [
                    E('strong', [title]),
                    E('br'),
                    E('span', { 'style': 'white-space:normal' }, description)
                ])
            ]));
        } else {
            form.ListValue.prototype.value.call(this, value, title);
        }
    }
});

return view.extend({
    load: function() {
        return Promise.all([
            uci.load('timecontrol'),
            network.getDevices()
        ]);
    },

    render: function(data) {
        var m, s, o;
        var hostList = [];

        m = new form.Map('timecontrol', _('Internet Time Control'),
            _('Users can limit their internet usage time through MAC and IP, with available IP ranges such as 192.168.110.00 to 192.168.10.200') + '<br/>' +
            _('Suggested feedback:') + ' <a href="https://github.com/sirpdboy/luci-app-timecontrol.git" target="_blank">GitHub @timecontrol</a>');

        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.render = function() {
            var statusView = E('p', { id: 'service_status' }, 
                '<span class="spinning"> </span> ' + _('Checking service status...'));
            
            checkTimeControlProcess()
                .then(function(res) {
                    var status = renderServiceStatus(res.running, res.pid);
                    statusView.innerHTML = status;
                })
                .catch(function(err) {
                    statusView.innerHTML = '<span style="color:orange">⚠ ' + 
                        _('Status check failed') + '</span>';
                    console.error('Status check error:', err);
                });
            
            poll.add(function() {
                return checkTimeControlProcess()
                    .then(function(res) {
                        var status = renderServiceStatus(res.running, res.pid);
                        statusView.innerHTML = status;
                    })
                    .catch(function(err) {
                        statusView.innerHTML = '<span style="color:orange">⚠ ' + 
                            _('Status check failed') + '</span>';
                        console.error('Status check error:', err);
                    });
            }, 5); 

            poll.start();
            return E('div', { class: 'cbi-section', id: 'status_bar' }, [ 
                statusView,
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
        };

        s = m.section(form.TypedSection, 'timecontrol');
        s.anonymous = true;
        s.addremove = false;

        o = s.option(cbiRichListValue, 'list_type', _('Control Mode'),
            _('blacklist: Block the networking of the target address, whitelist: Only allow networking for the target address and block all other addresses.'));
        o.rmempty = false;
        o.value('blacklist', _('Blacklist'));
        // o.value('whitelist', _('Whitelist'));
        o.default = 'blacklist';

        o = s.option(cbiRichListValue, 'chain', _('Control Intensity'),
            _('Pay attention to strong control: machines under control will not be able to connect to the software router backend!'));
        o.value('forward', _('Ordinary forward control'));
        o.value('input', _('Strong input control'));
        o.default = 'forward';
        o.rmempty = false;

        var s = m.section(form.TableSection, 'device',  _('Device Rules'));
        s.addremove = true;
        s.anonymous = true;
        s.sortable = false;

        o = s.option(form.Value, 'comment', _('Comment'));
        o.optional = true;
        o.placeholder = _('Description');

        o = s.option(form.Flag, 'enable', _('Enabled'));
        o.rmempty = false;
        o.default = '1';
	
        o = s.option(form.Value, 'mac', _('IP/MAC Address'));
        o.rmempty = false;
        o.placeholder = '192.168.10.100 or 00:11:22:33:44:55';
        
        getHostList().then(function(hosts) {
            hostList = hosts;
            o.value('', _('-- Please select or enter manually --'));
            
            if (hosts.length > 0) {
                hosts.forEach(function(host) {
                    var displayName = '';
                    if (host.name) {
                        displayName = host.name + ' - ';
                    }
                    displayName += host.ipv4 + ' (' + host.mac + ')';
                    
                    // 添加IP选项
                    o.value(host.ipv4, displayName);
                    
                    // 添加MAC选项
                    var macDisplay = host.mac;
                    if (host.name) {
                        macDisplay += ' - ' + host.name;
                    }
                    if (host.ipv4) {
                        macDisplay += ' (' + host.ipv4 + ')';
                    }
                    o.value(host.mac, macDisplay);
                });
            }
        });

        o = s.option(form.Value, 'timestart', _('Start Control Time'));
        o.placeholder = '00:00';
        o.default = '00:00';
        o.rmempty = false;

        o = s.option(form.Value, 'timeend', _('Stop Control Time'));
        o.placeholder = '00:00';
        o.default = '00:00';
        o.rmempty = false;

        o = s.option(form.ListValue, 'week', _('Week Day (1~7)'));
        o.value('0', _('Everyday'));
        o.value('1', _('Monday'));
        o.value('2', _('Tuesday'));
        o.value('3', _('Wednesday'));
        o.value('4', _('Thursday'));
        o.value('5', _('Friday'));
        o.value('6', _('Saturday'));
        o.value('7', _('Sunday'));
        o.value('1,2,3,4,5', _('Workday'));
        o.value('6,7', _('Rest Day'));
        o.default = '0';
        o.rmempty = false;
        return m.render();
    }
});