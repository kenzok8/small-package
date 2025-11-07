/*   Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netspeedtest */
'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require form';
'require poll';
return view.extend({
    render: function() {
        var state = { 
            running: false,
            port: 3300
        };
        var container = E('div');
        var statusSection = E('div', { 'class': 'cbi-section' });
        var statusIcon = E('span', { 'style': 'margin-right: 5px;' });
        var statusText = E('span');
        var toggleBtn = E('button', { 'class': 'btn cbi-button' });
        
        var statusMessage = E('div', { style: 'text-align: center; padding: 2em;' }, [
            E('img', {
                src: 'data:image/svg+xml;base64,PHN2ZyB2ZXJzaW9uPSIxLjEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMjQiIGhlaWdodD0iMTAyNCIgdmlld0JveD0iMCAwIDEwMjQgMTAyNCI+PHBhdGggZmlsbD0iI2RmMDAwMCIgZD0iTTk0Mi40MjEgMjM0LjYyNGw4MC44MTEtODAuODExLTE1My4wNDUtMTUzLjA0NS04MC44MTEgODAuODExYy03OS45NTctNTEuNjI3LTE3NS4xNDctODEuNTc5LTI3Ny4zNzYtODEuNTc5LTI4Mi43NTIgMC01MTIgMjI5LjI0OC01MTIgNTEyIDAgMTAyLjIyOSAyOS45NTIgMTk3LjQxOSA4MS41NzkgMjc3LjM3NmwtODAuODExIDgwLjgxMSAxNTMuMDQ1IDE1My4wNDUgODAuODExLTgwLjgxMWM3OS45NTcgNTEuNjI3IDE3NS4xNDcgODEuNTc5IDI3Ny4zNzYgODEuNTc5IDI4Mi43NTIgMCA1MTItMjI5LjI0OCA1MTItNTEyIDAtMTAyLjIyOS0yOS45NTItMTk3LjQxOS04MS41NzktMjc3LjM3NnpNMTk0Ljk0NCA1MTJjMC0xNzUuMTA0IDE0MS45NTItMzE3LjA1NiAzMTcuMDU2LTMxNy4wNTYgNDggMCA5My40ODMgMTAuNjY3IDEzNC4yMjkgMjkuNzgxbC00MjEuNTQ3IDQyMS41NDdjLTE5LjA3Mi00MC43ODktMjkuNzM5LTg2LjI3Mi0yOS43MzktMTM0LjI3MnpNNTEyIDgyOS4wNTZjLTQ4IDAtOTMuNDgzLTEwLjY2Ny0xMzQuMjI5LTI5Ljc4MWw0MjEuNTQ3LTQyMS41NDdjMTkuMDcyIDQwLjc4OSAyOS43ODEgODYuMjcyIDI5Ljc4MSAxMzQuMjI5LTAuMDQzIDE3NS4xNDctMTQxLjk5NSAzMTcuMDk5LTMxNy4wOTkgMzE3LjA5OXoiLz48L3N2Zz4=',
                style: 'width: 100px; height: 100px; margin-bottom: 1em;'
            }),
            E('h2', {}, _('Homebox Service Not Running')),
            E('p', {}, _('Please enable the Homebox service'))
        ]);
        
        var isHttps = window.location.protocol === 'https:';
        var iframe;
        
        if (!isHttps) {
            iframe = E('iframe', {
                src: window.location.origin + ':' + state.port,
                style: 'border:none;width: 100%; min-height: 80vh; border: none; border-radius: 3px;overflow:hidden !important;'
            });
        }

        function createHttpsButton() {
            return E('div', {
                style: 'text-align: center; padding: 2em;'
            }, [
                E('h2', {}, _('Homebox Control panel')),
                E('p', {}, _('Due to browser security policies, the Homebox interface https cannot be embedded directly.')),
                E('a', {
                    href: 'http://' + window.location.hostname + ':' + state.port,
                    target: '_blank',
                    class: 'cbi-button cbi-button-apply',
                    style: 'display: inline-block; margin-top: 1em; padding: 10px 20px; font-size: 16px; text-decoration: none; color: white;'
                }, _('Open Web Interface'))
                
            ]);
        }

        async function checkProcess() {
            try {
                // 尝试使用pgrep 
                const res = await fs.exec('/usr/bin/pgrep', ['homebox']);
                return {
                    running: res.code === 0,
                    pid: res.stdout.trim() || null
                };
            } catch (err) {
                // 回退到ps方法
                try {
                    const psRes = await fs.exec('/bin/ps', ['-w', '-C', 'homebox', '-o', 'pid=']);
                    const pid = psRes.stdout.trim();
                    return {
                        running: pid !== '',
                        pid: pid || null
                    };
                } catch (err) {
                    return { running: false, pid: null };
                }
            }
        }

        function controlService(action) {
            var command = action === 'start' 
                ? 'nohup /usr/bin/homebox >> /tmp/netspeedtest.log 2>&1 &' 
                : '/usr/bin/killall homebox';
            return fs.exec('/bin/sh', ['-c', command]);
        }

        function updateStatus() {
            statusIcon.textContent = state.running ? '✓' : '✗';
            statusIcon.style.color = state.running ? 'green' : 'red';
            statusText.textContent = _('Homebox Server') + (state.running ? _('RUNNING') : _('NOT RUNNING'));
            statusText.style.color = state.running ? 'green' : 'red';
            statusText.style.fontWeight = 'bold'; 
            statusText.style.fontSize = '0.92rem'; 
            
            toggleBtn.textContent = state.running ? _('Stop Server') : _('Start Server');
            toggleBtn.className = `btn cbi-button cbi-button-${state.running ? 'reset' : 'apply'}`;
            
            // Update container content based on state and protocol
            container.textContent = '';
            if (state.running) {
                if (isHttps) {
                    container.appendChild(createHttpsButton());
                } else {
                    container.appendChild(iframe);
                }
            } else {
                container.appendChild(statusMessage);
            }
        }

        toggleBtn.addEventListener('click', ui.createHandlerFn(this, function() {
            var action = state.running ? 'stop' : 'start';
            return controlService(action)
                .then(checkProcess)
                .then(res => {
                    state.running = res.running;
                    updateStatus();
                });
        }));

        statusSection.appendChild(E('div', { 'style': 'margin: 15px' }, [
            E('h3', {}, _('Lan Speedtest Homebox')),
            E('div', { 'class': 'cbi-map-descr' }, [statusIcon, statusText]),
            E('div', {'class': 'cbi-value', 'style': 'margin-top: 20px'}, [
                E('div', {'class': 'cbi-value-title'}, _('Homebox service control')),
                E('div', {'class': 'cbi-value-field'}, toggleBtn),
                E('div', { 'style': 'text-align: right; font-style: italic; margin-top: 20px;' }, [
                    _('© github '),
                    E('a', { 
                        'href': 'https://github.com/sirpdboy', 
                        'target': '_blank',
                        'style': 'text-decoration: none;'
                    }, 'by sirpdboy')
                ])
            ])
        ]));

        // Initial status check
        checkProcess().then(res => {
            state.running = res.running;
            updateStatus();
            toggleBtn.disabled = false;
            // Start polling
            poll.add(() => {
                return checkProcess().then(res => {
                    if (res.running !== state.running) {
                        state.running = res.running;
                        updateStatus();
                        toggleBtn.disabled = false;
                    }
                });
            }, 5);
            
            poll.start();
        });

        return E('div', {}, [
            statusSection,
            container
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});