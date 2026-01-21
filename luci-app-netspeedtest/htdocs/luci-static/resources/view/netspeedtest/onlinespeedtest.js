/*   Copyright (C) 2021-2026 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netspeedtest */
'use strict';
'require view';
'require uci';
'require form';

return view.extend({

    load() {
        return Promise.all([
            uci.load('netspeedtest')
        ]);
    },

    render(res) {
        let m, s, o;

        m = new form.Map('netspeedtest', _('Online SpeedTest'));
        
        let currentSpeedTestUrl = uci.get('netspeedtest', 'config', 'speedtest_site') || 'https://plugin.speedtest.cn/taste#/?t=1767018285493';
        if (!currentSpeedTestUrl) {
            currentSpeedTestUrl = 'https://plugin.speedtest.cn/taste#/?t=1767018285493';
            uci.set('netspeedtest', 'config', 'speedtest_site', currentSpeedTestUrl);
            uci.save();
        }

        s = m.section(form.NamedSection, 'config', 'netspeedtest');
        s.anonymous = true;
        
        // 下拉选择
        o = s.option(form.DummyValue, '_speedtest_select');
        o.textvalue = function() {
            return '';
        };
        o.render = function(section_id) {
            const sites = [
                {url: 'https://plugin.speedtest.cn/taste#/?t=1767018285493', name: 'speedtest.cn'},
                {url: 'https://static.hdslb.com/', name: 'hdslb.com'},
                {url: 'https://test.ustc.edu.cn/', name: 'ustc.edu.cn'},
                {url: 'https://www1.szu.edu.cn/nc/speedtest/', name: 'szu.edu.cn'},
                {url: 'https://10000.gd.cn/#/speed', name: 'gd.cn'},
                {url: 'https://speed.cloudflare.com/', name: 'cloudflare.com'},
                {url: 'https://fast.com/', name: 'Netflix fast.com'},
                {url: '//openspeedtest.com/speedtest', name: 'openspeedtest.com'}
            ];
            
            const container = E('div', {
                class: 'cbi-value'
            });
            
            const label = E('label', {
                class: 'cbi-value-title',
                for: 'speedtest-site-select'
            }, _('Select speed measurement station'));
            
            const field = E('div', {
                class: 'cbi-value-field',
            });
            
            const select = E('select', {
                id: 'speedtest-site-select',
                class: 'cbi-input-select'
            });
            
            sites.forEach(site => {
                const option = E('option', {
                    value: site.url,
                    selected: currentSpeedTestUrl === site.url ? 'selected' : null
                }, site.name);
                select.appendChild(option);
            });
            
            function saveConfig(url) {
                try {
                    uci.set('netspeedtest', 'config', 'speedtest_site', url);
                    uci.save();
                } catch (e) {
                }
            }
            
            select.addEventListener('change', function() {
                const iframe = document.getElementById('speedtest-iframe');
                if (iframe && this.value) {
                    currentSpeedTestUrl = this.value;
                    iframe.src = this.value;
                    saveConfig(this.value);
                }
            });
            
            field.appendChild(select);
            container.appendChild(label);
            container.appendChild(field);
            
            const saveStatus = E('small', {
                id: 'save-status',
                style: 'display: block; margin-top: 5px; color: #28a745; opacity: 0; transition: opacity 0.3s;'
            });
            
            field.appendChild(saveStatus);
            
            return container;
        };

        s = m.section(form.NamedSection, '_iframe');
        s.anonymous = true;
        
        s.render = function(section_id) {
            const container = E('div', { 
                class: 'speedtest-wrapper mobiliframe',
                style: 'width:100%;height:550px;position:relative;overflow:hidden;margin-top:20px;' 
            });
            const header = E('div', {
                style: 'display:flex;justify-content:space-between;align-items:center;padding: 0.5rem 1rem;'
            }, [
                E('span', {
                    style: 'font-weight:bold;'
                }, _('NetSpeedtest')),
            ]);
            
            const iframeContainer = E('div', {
                style: 'height: calc(100% - 33px);'
            });
            
            const iframe = E('iframe', {
                id: 'speedtest-iframe',
                src: currentSpeedTestUrl,
                style: 'width:100%;height:100%;border:none;background: #fff'
            });
            
            iframeContainer.appendChild(iframe);
            
            const style = E('style', {}, `
                .speedtest-wrapper {
                    transition: all 0.3s ease;
                }
                
                .speedtest-wrapper:hover {
                    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
                }
                
                #save-status {
                    transition: opacity 0.3s ease;
                }
                
                @media (prefers-color-scheme: dark) {
                    .speedtest-wrapper {
                        background: #2d2d2d;
                    }
                    
                    .speedtest-wrapper > div:first-child {
                        background: #3d3d3d;
                        border-color: #555;
                    }
                    
                    .speedtest-wrapper > div:first-child span {
                        color: #e0e0e0;
                    }
                }
                
                @media (max-width: 768px) {
                    .speedtest-wrapper {
                        height: 500px;
                    }
                    
                    .cbi-value-title {
                        width: 100% !important;
                        margin-bottom: 5px;
                    }
                    
                    .cbi-value-field {
                        width: 100% !important;
                    }
                    
                    #speedtest-site-select {
                        max-width: 100%;
                    }
                }
            `);
            
            container.appendChild(header);
            container.appendChild(iframeContainer);
            container.appendChild(style);
            
            return container;
        };

        return m.render();
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});