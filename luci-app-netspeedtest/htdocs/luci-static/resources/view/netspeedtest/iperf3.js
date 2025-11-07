/*   Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netspeedtest */
'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require form';
'require poll';

var state = { 
    running: false,
    port: null
};

const logPath = '/tmp/netspeedtest.log';

async function checkProcess() {
    try {
        const res = await fs.exec('/usr/bin/pgrep', ['iperf3']);
        if (res.code === 0 && res.stdout.trim()) {
            return { running: true, pid: res.stdout.trim() };
        }
        
        // 回退检查
        const psRes = await fs.exec('/bin/ps', ['-w', '-C', 'iperf3', '-o', 'pid=']);
        const pid = psRes.stdout.trim();
        return {
            running: !!pid,
            pid: pid || null
        };
    } catch (err) {
        console.error('Process check error:', err);
        return { running: false, pid: null };
    }
}


function controlService(action) {
    const commands = {
        start: `/usr/bin/iperf3 -s -D -p 5201 --logfile ${logPath} 2>&1`,
        stop: '/usr/bin/killall -q iperf3'
    };

    return (action === 'start' 
        ? fs.exec('/bin/sh', ['-c', `mkdir -p /tmp/netspeedtest && touch ${logPath} && chmod 644 ${logPath}`])
        : Promise.resolve()
    ).then(() => fs.exec('/bin/sh', ['-c', commands[action]]))
    .catch(err => {
        console.error('Service control error:', err);
        throw err;
    });
}


return view.extend({
    handleSaveApply: null,
    handleSave: null,
    handleReset: null,
    load: function() {
	return Promise.all([
		uci.load('netspeedtest')
	]);
    },

    render: function() {

        // 创建状态元素
        const statusIcon = E('span', { 'style': 'margin-right: 5px;' });
        const btnGroup = E('div', { 'class': 'cbi-value-field', 'style': 'display: flex; gap: 10px;' });
        const statusText = E('span');
        const toggleBtn = E('button', {
            'class': 'btn cbi-button',
            'click': ui.createHandlerFn(this, function() {
            const action = state.running ? 'stop' : 'start';
            toggleBtn.disabled = true; // 禁用按钮
            
            return controlService(action)
                .then(() => checkProcess())
                .then(res => {
                    state.running = res.running;
                    updateStatus();
                    toggleBtn.disabled = false; // 恢复按钮
                })
                .catch(err => {
                    ui.addNotification(null, E('p', _('Error: ') + err.message), 'error');
                    toggleBtn.disabled = false; // 出错时也要恢复按钮
                });

            })
        });

        function updateStatus() {
            statusIcon.textContent = state.running ? '✓' : '✗';
            statusIcon.style.color = state.running ? 'green' : 'red';
            statusText.textContent = _('Iperf3 Server ') + (state.running ? _('RUNNING') : _('NOT RUNNING'));
            statusText.style.color = state.running ? 'green' : 'red';
            statusText.style['font-weight'] = 'bold'; 
            statusText.style['font-size'] = '0.92rem'; 
            toggleBtn.textContent = state.running ? _('Stop Server') : _('Start Server');
            toggleBtn.className = `btn cbi-button cbi-button-${state.running ? 'reset' : 'apply'}`;
        }

        // 初始化状态
        statusIcon.textContent = '...';
        statusText.textContent = _('Checking status...');
        toggleBtn.textContent = _('Loading...');
        toggleBtn.disabled = true;


// 构建UI
const statusSection = E('div', { 'class': 'cbi-section' }, [
    E('div', { 'style': 'margin: 15px' }, [
        E('h3', {}, _('Lan Speedtest Iperf3')),
        E('div', { 'class': 'cbi-map-descr' }, [statusIcon, statusText]),
        E('div', {'class': 'cbi-value', 'style': 'margin-top: 20px'}, [
            E('div', {'class': 'cbi-value-title'}, _('Iperf3 service control')),
            E('div', {'class': 'cbi-value-field'}, toggleBtn),

            E('div', {'class': 'cbi-value-title'}, _('Download iperf3 client')),
            E('div', {'class': 'cbi-value-field'}, [ 
                E('div', { 
                    'class': 'cbi-value-field', 
                    'style': 'display: flex;' 
                }, [
                    E('button', {
                        'class': 'btn cbi-button cbi-button-save',
                        'click': ui.createHandlerFn(this, () => window.open('https://iperf.fr/iperf-download.php', '_blank'))
                    }, _('Official Website')),
                    E('button', {
                        'class': 'btn cbi-button cbi-button-save',
                        'click': ui.createHandlerFn(this, () => window.open('https://github.com/sirpdboy/luci-app-netspeedtest/releases', '_blank'))
                    }, _('GitHub'))
                ])
            ])
        ]),
        E('div', { 'style': 'text-align: right; font-style: italic; margin-top: 20px;' }, [
            _('© github '),
            E('a', { 
                'href': 'https://github.com/sirpdboy/luci-app-netspeedtest', 
                'target': '_blank',
                'style': 'text-decoration: none;'
            }, 'by sirpdboy')
        ])
    ])
]);

        // 初始化状态检查
        checkProcess().then(res => {
            state.running = res.running;
            updateStatus();
            toggleBtn.disabled = false;
            
            // 启动轮询
            poll.add(() => {
                return checkProcess().then(res => {
                    if (res.running !== state.running) {
                        state.running = res.running;
                        updateStatus();
                    }
                });
            }, 5);
        });

 
        return statusSection;
	}

});
