'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require network';
'require poll';
'require tools.widgets as widgets';
'require tools.momo as momo';

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('momo'),
        ]);
    },
    render: function (data) {
        let m, s, o;

        m = new form.Map('momo');

        s = m.section(form.NamedSection, 'mixin', 'mixin', _('Mixin Option'));

        s.tab('log', _('Log Config'));

        o = s.taboption('log', form.ListValue, 'log_disabled', _('Log Disabled'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));
        
        o = s.taboption('log', form.ListValue, 'log_level', _('Log Level'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('panic');
        o.value('fatal');
        o.value('error');
        o.value('warn');
        o.value('info');
        o.value('debug');
        o.value('trace');

        o = s.taboption('log', form.ListValue, 'log_timestamp', _('Log Timestamp'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('log', form.Value, 'log_output', _('Log Output'));
        o.placeholder = _('Unmodified');

        s.tab('dns', _('DNS Config'));

        o = s.taboption('dns', form.ListValue, 'dns_strategy', _('DNS Strategy'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('prefer_ipv4', _('Prefer IPv4'));
        o.value('prefer_ipv6', _('Prefer IPv6'));
        o.value('ipv4_only', _('IPv4 Only'));
        o.value('ipv6_only', _('IPv6 Only'));

        o = s.taboption('dns', form.ListValue, 'dns_disable_cache', _('DNS Disable Cache'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('dns', form.ListValue, 'dns_disable_expire', _('DNS Disable Expire'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('dns', form.ListValue, 'dns_independent_cache', _('DNS Independent Cache'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('dns', form.Value, 'dns_cache_capacity', _('DNS Cache Capacity'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unmodified');

        o = s.taboption('dns', form.ListValue, 'dns_reverse_mapping', _('DNS Reverse Mapping'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        s.tab('ntp', _('NTP Config'));

        o = s.taboption('ntp', form.ListValue, 'ntp_enabled', _('NTP Enabled'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('ntp', form.Value, 'ntp_server', _('NTP Server'));
        o.placeholder = _('Unmodified');

        o = s.taboption('ntp', form.Value, 'ntp_server_port', _('NTP Server Port'));
        o.datatype = 'port';
        o.placeholder = _('Unmodified');

        o = s.taboption('ntp', form.Value, 'ntp_interval', _('NTP Interval'));
        o.placeholder = _('Unmodified');

        s.tab('cache', _('Cache Config'));

        o = s.taboption('cache', form.ListValue, 'cache_enabled', _('Cache Enabled'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('cache', form.Value, 'cache_path', _('Cache Path'));
        o.placeholder = _('Unmodified');

        o = s.taboption('cache', form.ListValue, 'cache_store_fakeip', _('Cache Store FakeIP'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        o = s.taboption('cache', form.ListValue, 'cache_store_rdrc', _('Cache Store RDRC'));
        o.optional = true;
        o.placeholder = _('Unmodified');
        o.value('0', _('Disable'));
        o.value('1', _('Enable'));

        s.tab('external_control', _('External Control Config'));

        o = s.taboption('external_control', form.Value, 'external_control_ui_path', _('UI Path'));
        o.placeholder = _('Unmodified');

        o = s.taboption('external_control', form.Value, 'external_control_ui_download_url', _('UI Download Url'));
        o.placeholder = _('Unmodified');
        o.value('https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip', 'Zashboard (CDN Fonts)');
        o.value('https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip', 'Zashboard');
        o.value('https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip', 'MetaCubeXD');
        o.value('https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip', 'YACD');
        o.value('https://github.com/MetaCubeX/Razord-meta/archive/refs/heads/gh-pages.zip', 'Razord');

        o = s.taboption('external_control', form.Value, 'external_control_api_listen', _('API Listen'));
        o.datatype = 'ipaddrport(1)';
        o.placeholder = _('Unmodified');

        o = s.taboption('external_control', form.Value, 'external_control_api_secret', _('API Secret'));
        o.password = true;
        o.placeholder = _('Unmodified');

        return m.render();
    }
});