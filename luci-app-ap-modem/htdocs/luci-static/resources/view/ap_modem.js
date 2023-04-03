'use strict';
'require view';
'require uci';
'require form';

return view.extend({
    load: function() {
        return Promise.all([
            uci.load('ap_modem')
        ]);
    },

    render: function() {

        var m, s, o, ss;

        m = new form.Map('ap_modem', _('Access AP / Modem'),
            _('Allows clients in the local network to access AP or modem on different subnet.'));

        s = m.section(form.NamedSection, 'config', 'ap_modem', _('Global Settings'));
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Flag, 'enabled', _('Enable'));
        o.rmempty  = false;

        s = m.section(form.NamedSection, 'config', 'ap_modem', _('Interface Settings'));
        s.anonymous = true;
        s.addremove = false;

        [
            {id:"lan", title:_("LAN"), subtitle:_("AP on LAN side"), placeholder:"192.168.31.254"},
            {id:"wan", title:_("WAN"), subtitle:_("AP / Modem on WAN side"), placeholder:"192.168.1.254"},
        ].forEach(function(vif) {
            s.tab(vif.id, vif.title);

            o = s.taboption(vif.id, form.SectionValue, '__'+vif.id+'__', form.NamedSection, vif.id, null,
                vif.subtitle, _('Here add the IP address of the same subnet as the target device, but not the same as the target device. <br>Do not add IPs already used by other devices. <br>For example, the address of the AP is 192.168.31.1, then you can add 192.168.31.254'));

            ss = o.subsection;
            ss.anonymous = true;

            o = ss.option(form.DynamicList, 'ipaddr', _('Virtual IP'), _('Supports "IP/MASK", "IP/PREFIX", and pure "IP" format, pure "IP" assumes a prefix of 24 bits'))
            o.datatype    = 'ipmask4'
            o.placeholder = vif.placeholder
        });

        return m.render();
    }
});
