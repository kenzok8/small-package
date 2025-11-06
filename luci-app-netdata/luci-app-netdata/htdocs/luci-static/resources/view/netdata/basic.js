// Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netdata
'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';
'require fs';
const getNetdataVersion = rpc.declare({
    object: 'luci.netdata',
    method: 'get_version',
    expect: { 'version': '' }
});
async function checkProcess() {
    try {
        const pidofRes = await fs.exec('/bin/pidof', ['netdata']);
        if (pidofRes.code === 0) {
            return {
                running: true,
                pid: pidofRes.stdout.trim()
            };
        }
    } catch (err) {
        // Ignore error
    }
    try {
        const psRes = await fs.exec('/bin/ps', ['-C', 'netdata', '-o', 'pid=']);
        const pid = psRes.stdout.trim();
        return {
            running: pid !== '',
            pid: pid || null
        };
    } catch (err) {
        return { running: false, pid: null };
    }
}
function getVersionInfo() {
    return L.resolveDefault(getNetdataVersion(), {}).then(function(result) {
        return result || {};
    }).catch(function(error) {
        console.error('Failed to get version:', error);
        return {};
    });
}

function getServiceStatus() {
    return L.resolveDefault(checkProcess(), {}).then(function(res) {
        let isRunning = false;
        try {
            if (res && res.running) {
                isRunning = true;
            }
        } catch (e) { 
            console.error('Service status error:', e);
        }
        return isRunning;
    }).catch(function(error) {
        console.error('Service status check failed:', error);
        return false;
    });
}

function renderStatus(isRunning, webport, protocol, version) {
    let statusText = isRunning ? _('RUNNING') : _('NOT RUNNING');
    let color = isRunning ? 'green' : 'red';
    let icon = isRunning ? '✓' : '✗';
    let versionText = version ? `${version}` : '';
    let html = String.format(
        '<em><span style="color:%s">%s <strong>%s %s - %s</strong></span></em>',
        color, icon, _('Netdata'),versionText, statusText
    );

    if (isRunning) {
        let buttonUrl = String.format('%s//%s:%s/', protocol, window.location.hostname, webport);

        html += String.format(
            '<input class="cbi-button cbi-button-reload" type="button" style="margin-left: 20px" value="%s" onclick="window.open(\'%s\')">',
            _('Open Web UI'), 
            buttonUrl
        );
    }
    
    return html;
}
return view.extend({
    load: function() {
        return Promise.all([
            uci.load('netdata')
        ]);
    },

    render: function(data) {
        let m, s, o;
        let webport = uci.get_first('netdata', 'netdata', 'port') || '19999';
        let uci_ssl = uci.get_first('netdata', 'netdata', 'enable_ssl') || '0';
        let protocol = uci_ssl === '1' ? 'https:' : 'http:';
        
        m = new form.Map('netdata', _('Netdata'),
            _('An open-source real-time performance monitoring and visualization tool'));

        // 状态显示部分
        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.addremove = false;

        s.render = function() {
            poll.add(function() {
                return Promise.all([
                    getServiceStatus(), 
                    getVersionInfo() 
                ]).then(function(results) {
                    var [isRunning, version] = results;
                    var view = document.getElementById('service_status');
                    if (view) {
                        view.innerHTML = renderStatus(isRunning, webport, protocol, version);
                    }
                }).catch(function(error) {
                    console.error('Poll error:', error);
                });
            }, 5); // 添加轮询间隔5秒
            
            return E('div', { class: 'cbi-section', id: 'status_bar' }, [
                E('div', { id: 'service_status' }, 
                    E('p', {}, _('Collecting data...'))
                ),
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

        // 配置部分
        s = m.section(form.NamedSection, 'netdata', 'netdata');

        o = s.option(form.Flag, 'enabled', _('Enable'));
        o.default = o.disabled;
        o.rmempty = false;

        o = s.option(form.Value, 'port', _('Service port'));
        o.datatype = 'port';
        o.placeholder = '19999';
        o.rmempty = false;
        o.validate = function(section_id, value) {
            if (value < 1 || value > 65535) {
                return _('Port must be between 1 and 65535');
            }
            return true;
        };

        o = s.option(form.Flag, 'enable_ssl', _('Enable SSL'));
        o.rmempty = true;

        o = s.option(form.DummyValue, 'cert_file', _('Cert file'));
        o.default = '/etc/ssl/ezopwrt.crt';
        o.depends('enable_ssl', '1');
        o.cfgvalue = function(section_id) {
            return uci.get('netdata', section_id, 'cert_file') || '/etc/ssl/ezopwrt.crt'; 
        };

        o = s.option(form.DummyValue, 'key_file', _('Cert Key file'));
        o.default = '/etc/ssl/ezopwrt.key';
        o.depends('enable_ssl', '1');
        o.cfgvalue = function(section_id) {
            return uci.get('netdata', section_id, 'key_file') || '/etc/ssl/ezopwrt.key'; 
        };
    
        //  o = s.option(form.DummyValue, 'feedback_info',  _('feedback info'));
        //  o.href = 'https://github.com/sirpdboy';
        //  o.cfgvalue = function() {
        //     return 'https://github.com/sirpdboy';
        //  };
    
        return m.render();
    }
});