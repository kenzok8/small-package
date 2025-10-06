'use strict';
'require view';
'require fs';
'require poll';
'require ui';

return view.extend({
    render: function(data) {
        // Create container for status
        var container = E('div', { id: 'wifidogx-status' }, [
            E('h2', {}, _('apfree-wifidog Status'))
        ]);

        // Function to update the status information
        function updateStatus() {
            // Get all status information in parallel
            var promises = [
                fs.exec('wdctlx', ['status', 'wifidogx']),
                fs.exec('wdctlx', ['status', 'client']),
                fs.exec('wdctlx', ['status', 'auth'])
            ];

            return Promise.all(promises).then(function(results) {
                var wifidogxRes = results[0];
                var clientRes = results[1];
                var authRes = results[2];
                
                // Clear container
                container.innerHTML = '';
                container.appendChild(E('h2', {}, _('apfree-wifidog Status')));

                // Parse wifidogx status
                var wifidogxData = null;
                var clientData = null;
                var authData = null;

                try {
                    if (wifidogxRes.code === 0 && wifidogxRes.stdout) {
                        wifidogxData = JSON.parse(wifidogxRes.stdout);
                    }
                } catch (e) {
                    console.error('Error parsing wifidogx status:', e);
                }

                try {
                    if (clientRes.code === 0 && clientRes.stdout) {
                        clientData = JSON.parse(clientRes.stdout);
                    }
                } catch (e) {
                    console.error('Error parsing client status:', e);
                }

                try {
                    if (authRes.code === 0 && authRes.stdout) {
                        authData = JSON.parse(authRes.stdout);
                    }
                } catch (e) {
                    console.error('Error parsing auth status:', e);
                }

                // Display wifidogx information
                if (wifidogxData) {
                    createWifidogxStatusTable(wifidogxData);
                } else {
                    container.appendChild(E('p', {}, _('Failed to get wifidogx status')));
                }

                // Display client information
                if (clientData) {
                    createClientStatusTable(clientData);
                } else {
                    container.appendChild(E('p', {}, _('Failed to get client status')));
                }

                // Display auth server information
                if (authData) {
                    createAuthStatusTable(authData);
                } else {
                    container.appendChild(E('p', {}, _('Failed to get auth server status')));
                }
            }).catch(function(error) {
                container.innerHTML = '';
                container.appendChild(E('h2', {}, _('apfree-wifidog Status')));
                container.appendChild(E('p', {}, _('Error getting status information: ') + error.message));
            });
        }

        // Function to create wifidogx status table
        function createWifidogxStatusTable(data) {
            container.appendChild(E('h3', {}, _('apfree-wifidog Status')));
            
            var table = E('table', { 'class': 'table' });
            
            var uptime = formatUptime(data.uptime || 0);
            var authModeText = getAuthModeText(data.auth_server_mode);
            
            var rows = [
                [_('Version'), data.wifidogx_version || '-'],
                [_('Uptime'), uptime],
                [_('Internet Connected'), data.is_internet_connected ? _('Yes') : _('No')],
                [_('Auth Server Connected'), data.is_auth_server_connected ? _('Yes') : _('No')],
                [_('Auth Server Mode'), authModeText]
            ];

            rows.forEach(function(row) {
                table.appendChild(E('tr', {}, [
                    E('td', { 'class': 'td left', 'width': '30%' }, [ row[0] ]),
                    E('td', { 'class': 'td left' }, [ row[1] ])
                ]));
            });

            container.appendChild(table);
        }

        // Function to create client status table
        function createClientStatusTable(data) {
            container.appendChild(E('h3', {}, _('Client Status')));
            
            var summaryTable = E('table', { 'class': 'table' });
            var summaryRows = [
                [_('Online Clients'), data.online_client_count || 0],
                [_('Active Clients'), data.active_client_count || 0]
            ];

            summaryRows.forEach(function(row) {
                summaryTable.appendChild(E('tr', {}, [
                    E('td', { 'class': 'td left', 'width': '30%' }, [ row[0] ]),
                    E('td', { 'class': 'td left' }, [ row[1] ])
                ]));
            });

            container.appendChild(summaryTable);

            // Display client details if available
            if (data.clients && data.clients.length > 0) {
                container.appendChild(E('h4', {}, _('Connected Clients')));
                
                var clientTable = E('table', { 'class': 'table' });
                
                // Add header row
                clientTable.appendChild(E('tr', { 'class': 'tr table-titles' }, [
                    E('th', { 'class': 'th' }, _('IP Address')),
                    E('th', { 'class': 'th' }, _('MAC Address')),
                    E('th', { 'class': 'th' }, _('Status')),
                    E('th', { 'class': 'th' }, _('Online Time')),
                    E('th', { 'class': 'th' }, _('Connection Type')),
                    E('th', { 'class': 'th' }, _('Gateway ID'))
                ]));

                data.clients.forEach(function(client) {
                    var statusText = client.status === 1 ? _('Online') : _('Offline');
                    var onlineTime = formatOnlineTime(client.online_time || 0);
                    var connectionType = client.wired ? _('Wired') : _('Wireless');
                    
                    clientTable.appendChild(E('tr', { 'class': 'tr' }, [
                        E('td', { 'class': 'td' }, client.ip || '-'),
                        E('td', { 'class': 'td' }, client.mac || '-'),
                        E('td', { 'class': 'td' }, statusText),
                        E('td', { 'class': 'td' }, onlineTime),
                        E('td', { 'class': 'td' }, connectionType),
                        E('td', { 'class': 'td' }, client.gw_id || '-')
                    ]));
                });

                container.appendChild(clientTable);
            }
        }

        // Function to create auth server status table
        function createAuthStatusTable(data) {
            container.appendChild(E('h3', {}, _('Authentication Server Status')));
            
            var table = E('table', { 'class': 'table' });
            
            var rows = [
                [_('Auth Server Online'), data.auth_online ? _('Yes') : _('No')]
            ];

            rows.forEach(function(row) {
                table.appendChild(E('tr', {}, [
                    E('td', { 'class': 'td left', 'width': '30%' }, [ row[0] ]),
                    E('td', { 'class': 'td left' }, [ row[1] ])
                ]));
            });

            // Add auth servers if available
            if (data.auth_servers && data.auth_servers.length > 0) {
                table.appendChild(E('tr', {}, [
                    E('td', { 'class': 'td left', 'width': '30%' }, [ _('Authentication Servers') ]),
                    E('td', { 'class': 'td left' }, [
                        E('ul', { 'class': 'clean-list' }, 
                            data.auth_servers.map(function(srv) {
                                return E('li', {}, srv.host + ' (' + srv.ip + ')');
                            })
                        )
                    ])
                ]));
            }

            container.appendChild(table);
        }

        // Helper function to format uptime
        function formatUptime(seconds) {
            var days = Math.floor(seconds / 86400);
            var hours = Math.floor((seconds % 86400) / 3600);
            var minutes = Math.floor((seconds % 3600) / 60);
            var secs = seconds % 60;
            
            var parts = [];
            if (days > 0) parts.push(days + _('d'));
            if (hours > 0) parts.push(hours + _('h'));
            if (minutes > 0) parts.push(minutes + _('m'));
            if (secs > 0 || parts.length === 0) parts.push(secs + _('s'));
            
            return parts.join(' ');
        }

        // Helper function to format online time
        function formatOnlineTime(seconds) {
            var hours = Math.floor(seconds / 3600);
            var minutes = Math.floor((seconds % 3600) / 60);
            var secs = seconds % 60;
            
            var parts = [];
            if (hours > 0) parts.push(hours + _('h'));
            if (minutes > 0) parts.push(minutes + _('m'));
            if (secs > 0 || parts.length === 0) parts.push(secs + _('s'));
            
            return parts.join(' ');
        }

        // Helper function to get auth mode text
        function getAuthModeText(mode) {
            switch(mode) {
                case 0: return _('Cloud Auth');
                case 1: return _('Local Auth');
                case 2: return _('Bypass Auth');
                default: return _('Unknown');
            }
        }

        // Poll status every 5 seconds
        L.Poll.add(function() {
            return updateStatus();
        }, 5);

        // Initial update
        updateStatus();

        return container;
    },

    handleSave: null,
    handleSaveApply: null,
    handleReset: null
});