/*   Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netspeedtest */
'use strict';
'require view';
'require poll';
'require dom';
'require fs';
'require rpc';
'require uci';
'require ui';
'require form';
// 全局变量
var TestTimeout = 240 * 1000; // 4 Minutes
var ResultFile = '/tmp/speedtest_result';
var SpeedtestCli = '/usr/bin/speedtest';
var SpeedtestScript = '/usr/lib/netspeedtest/speedtest';

return view.extend({
    load() {
        return Promise.all([
            L.resolveDefault(fs.stat(SpeedtestCli), {}),
            L.resolveDefault(fs.read(ResultFile), null),
            L.resolveDefault(fs.stat(ResultFile), {}),
            uci.load('netspeedtest')
        ]);
    },

    poll_status(nodes, res) {
        var has_ookla = res[0].path,
            result_content = res[1] ? res[1].trim().split("\n") : [];
        var ookla_stat = nodes.querySelector('#ookla_status'),
            result_stat = nodes.querySelector('#speedtest_result'),
            start_btn = nodes.querySelector('.cbi-button-apply');

        // 更新测试按钮状态
        if (start_btn) {
            if (result_content.length && result_content[0] == 'Testing' && 
                (Date.now() - (nodes.result_mtime || 0)) < TestTimeout) {
                start_btn.disabled = true;
            } else {
                start_btn.disabled = false;
            }
        }

        // 获取版本号
        var version_info = '';
        if (has_ookla) {
            fs.exec(SpeedtestCli, ['--version'])
                .then(function(res) {
                    if (res.stdout) {
                        // 匹配 "Speedtest by Ookla 1.2.0.84" 这样的格式
                        var version_match = res.stdout.match(/Speedtest by Ookla (\d+\.\d+\.\d+\.\d+)/) || 
                                           res.stdout.match(/Speedtest (\d+\.\d+\.\d+\.\d+)/);
                        if (version_match) {
                            version_info = ' ver:' + version_match[1];
                        } else {
                            // 如果上面没匹配到，尝试匹配更简单的版本号格式
                            version_match = res.stdout.match(/(\d+\.\d+\.\d+)/);
                            if (version_match) {
                                version_info = ' ver:' + version_match[1];
                            }
                        }
                    }
                    // 更新状态显示（包含版本号）
                    ookla_stat.style.color = 'green';
                    dom.content(ookla_stat, [_(has_ookla ? 'Installed' + version_info : 'Not Installed')]);
                })
                .catch(function() {
                    // 如果获取版本失败，仍显示基本状态
                    ookla_stat.style.color = has_ookla ? 'green' : 'red';
                    dom.content(ookla_stat, [_(has_ookla ? 'Installed' : 'Not Installed')]);
                });
        } else {
            ookla_stat.style.color = 'red';
            dom.content(ookla_stat, [_('Not Installed')]);
        }

        if (result_content.length) {
            if (result_content[0] == 'Testing') {
                result_stat.innerHTML = "<span style='color:green;font-weight:bold'>" +
                    "<img src='/luci-static/resources/icons/loading.svg' height='17' style='vertical-align:middle ;margin-left:20px'/> " +
                    _('SpeedTesting in progress...') +
                    "</span>";
            } else if (result_content[0].match(/https?:\S+/)) {
                result_stat.innerHTML = "<div style='max-width:500px'><a href='" +
                    result_content[0] + "' target='_blank'><img src='" +
                    result_content[0] + '.png' + "' style='max-width:100%;margin-left:20px'></a></div>";
            } else if (result_content[0] == 'Test failed') {
                result_stat.innerHTML = "<span style='color:red;font-weight:bold;margin-left:20px'>" +
                    _('Test failed.') + "</span>";
            }
        } else {
            result_stat.innerHTML = "<span style='color:gray;margin-left:20px'>" +
                _('No test results yet.') + "</span>";
        }
    },

    render(res) {
        var has_ookla = res[0].path,
            result_content = res[1] ? res[1].trim().split("\n") : [],
            result_mtime = res[2] ? res[2].mtime * 1000 : 0;

        var m, s, o;
        m = new form.Map('netspeedtest', _('Wan Ookla SpeedTest'));

        // Result display section
        s = m.section(form.TypedSection, '_result');
        s.anonymous = true;
        s.render = function (section_id) {
            if (result_content.length) {
                if (result_content[0] == 'Testing') {
                    return E('div', { 'id': 'speedtest_result' }, [ E('span', { 'style': 'color:yellow;font-weight:bold' }, [
                        E('img', { 'src': L.resource(['icons/loading.gif']), 'height': '20', 'style': 'vertical-align:middle' }, []),
                        _('Testing in progress...')
                    ]) ])
                };
                if (result_content[0].match(/https?:\S+/)) {
                    return E('div', { 'id': 'speedtest_result' }, [ E('div', { 'style': 'max-width:500px' }, [
                        E('a', { 'href': result_content[0], 'target': '_blank' }, [
                            E('img', { 'src': result_content[0] + '.png', 'style': 'max-width:100%;max-height:100%;vertical-align:middle' }, [])
                    ]) ]) ])
                };
                if (result_content[0] == 'Test failed') {
                    return E('div', { 'id': 'speedtest_result' }, [ E('span', { 'style': 'color:red;font-weight:bold' }, [ _('Test failed.') ]) ])
                }
            } else {
                return E('div', { 'id': 'speedtest_result' }, [ E('span', { 'style': 'color:red;font-weight:bold;display:none' }, [ _('No result.') ]) ])
            }
        };

        // Configuration section
        s = m.section(form.NamedSection, 'config', 'netspeedtest');
        s.anonymous = true;

        // Start test button
        o = s.option(form.Button, '_start', _('Start Ookla SpeedTest'));
        o.inputtitle = _('Click to execute');
        o.inputstyle = 'apply';
        if (result_content.length && result_content[0] == 'Testing' && (Date.now() - result_mtime) < TestTimeout) {
            o.readonly = true;
        }
        o.onclick = function() {
            return fs.exec_direct(SpeedtestScript)
                .then(function(res) { return window.location = window.location.href.split('#')[0] })
                .catch(function(e) { ui.addNotification(null, E('p', e.message), 'error') });
        };

        o = s.option(form.DummyValue, '_ookla_status', _('Ookla® SpeedTest-CLI'));
        o.rawhtml = true;
        o.cfgvalue = function () {
            return E('span', {
                id: 'ookla_status',
                style: has_ookla ? 'color:green' : 'color:red'
            }, _(has_ookla ? 'Installed' : 'Not Installed'));
        };

        return m.render()
        .then(L.bind(function(m, nodes) {
            nodes.result_mtime = result_mtime; // 保存结果文件修改时间
            poll.add(L.bind(function () {
                return Promise.all([
                    L.resolveDefault(fs.stat(SpeedtestCli), {}),
                    L.resolveDefault(fs.read(ResultFile), null),
                    L.resolveDefault(fs.stat(ResultFile), {})
                ]).then(L.bind(function(res) {
                    nodes.result_mtime = res[2] ? res[2].mtime * 1000 : 0;
                    this.poll_status(nodes, res);
                }, this));
            }, this), 5);
            return nodes;
        }, this, m));
    },
        handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
