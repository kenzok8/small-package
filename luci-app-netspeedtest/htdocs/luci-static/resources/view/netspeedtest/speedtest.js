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
//	handleSaveApply: null,
//	handleSave: null,
//	handleReset: null,
    load: function () {
        return Promise.all([
            L.resolveDefault(fs.stat(SpeedtestCli), {}),
                L.resolveDefault(fs.read(ResultFile), null),
                L.resolveDefault(fs.stat(ResultFile), {}),
                uci.load('netspeedtest')
        ]);
    },

    poll_status: function (nodes, res) {
        var has_ookla = res[0].path,
        result_content = res[1] ? res[1].trim().split("\n") : [];
        var ookla_stat = nodes.querySelector('#ookla_status'),
        result_stat = nodes.querySelector('#speedtest_result');

        // Update status indicators
        ookla_stat.style.color = has_ookla ? 'green' : 'red';
        dom.content(ookla_stat, [_(has_ookla ? 'Installed' : 'Not Installed')]);

        // Update result display
        if (result_content.length) {
            if (result_content[0] == 'Testing') {
                result_stat.innerHTML = "<span style='color:green;font-weight:bold'>" +
                    "<img src='/luci-static/resources/icons/loading.gif' height='17' style='vertical-align:middle'/> " +
                    _('Testing in progress...') +
                    "</span>";
            } else if (result_content[0].match(/https?:\S+/)) {
                result_stat.innerHTML = "<div style='max-width:500px'><a href='" +
                    result_content[0] + "' target='_blank'><img src='" +
                    result_content[0] + '.png' + "' style='max-width:100%'></a></div>";
            } else if (result_content[0] == 'Test failed') {
                result_stat.innerHTML = "<span style='color:red;font-weight:bold'>" +
                    _('Test failed.') + "</span>";
            }
        } else {
            result_stat.innerHTML = "<span style='color:gray'>" +
                _('No test results yet.') + "</span>";
        }
    },

    render: function (res) {
	var has_ookla = res[0].path,
			result_content = res[1] ? res[1].trim().split("\n") : [],
			result_mtime = res[2] ? res[2].mtime * 1000 : 0,
			date = new Date();

	var m, s, o;
        m = new form.Map('netspeedtest', _('WAN Ookla SpeedTest'));

        // Result display section
        s = m.section(form.TypedSection, '_result');
        s.anonymous = true;
        s.render = function () {
            var content;
            if (result_content.length) {
                if (result_content[0] == 'Testing') {
                    content = E('span', { style: 'color:green;font-weight:bold' }, [
                        E('img', { src: '/luci-static/resources/icons/loading.gif', height: '20' }),
                        ' ', _('Testing in progress...')
                    ]);
                } else if (result_content[0].match(/https?:\S+/)) {
                    content = E('div', { style: 'max-width:500px' }, [
                        E('a', { href: result_content[0], target: '_blank' }, [
                            E('img', { src: result_content[0] + '.png', style: 'max-width:100%' })
                        ])
                    ]);
                } else {
                    content = E('span', { style: 'color:red;font-weight:bold' },
                        _('Test failed.'));
                }
            } else {
                content = E('span', { style: 'color:gray' },
                    _('No test results yet.'));
            }
            return E('div', { id: 'speedtest_result' }, content);
        };

        // Configuration section
        s = m.section(form.NamedSection, 'config', 'netspeedtest');

        // Start test button
        o = s.option(form.Button, '_start', _('Start Ookla SpeedTest'));
        o.inputtitle = _('Click to execute');
        o.inputstyle = 'apply';
		if (result_content.length && result_content[0] == 'Testing' && (date.getTime() - result_mtime) < TestTimeout)
			o.readonly = true;
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
            poll.add(L.bind(function () {
                return Promise.all([
					L.resolveDefault(fs.stat(SpeedtestCli), {}),
					L.resolveDefault(fs.read(ResultFile), null)
                ]).then(L.bind(this.poll_status, this, nodes));
            }, this), 5);
            return nodes;
        }, this, m));
    }
});
