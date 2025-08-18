'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require tools.momo as momo'

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('momo'),
            momo.getPaths(),
            momo.listProfiles(),
        ]);
    },
    render: function (data) {
        const subscriptions = uci.sections('momo', 'subscription');
        const paths = data[1];
        const profiles = data[2];

        let m, s, o;

        m = new form.Map('momo');

        s = m.section(form.NamedSection, 'placeholder', 'placeholder', _('Editor'));

        o = s.option(form.ListValue, '_file', _('Choose File'));
        o.optional = true;

        for (const profile of profiles) {
            o.value(paths.profiles_dir + '/' + profile.name, _('File:') + profile.name);
        };

        for (const subscription of subscriptions) {
            o.value(paths.subscriptions_dir + '/' + subscription['.name'] + '.json', _('Subscription:') + subscription.name);
        };

        o.value(paths.run_profile_path, _('Profile for Startup'));

        o.write = function (section_id, formvalue) {
            return true;
        };
        o.onchange = function (event, section_id, value) {
            return L.resolveDefault(fs.read_direct(value), '').then(function (content) {
                m.lookupOption('_file_content', section_id)[0].getUIElement(section_id).setValue(content);
            });
        };

        o = s.option(form.TextValue, '_file_content',);
        o.rows = 25;
        o.wrap = false;
        o.write = function (section_id, formvalue) {
            const path = m.lookupOption('_file', section_id)[0].formvalue(section_id);
            return fs.write(path, formvalue);
        };
        o.remove = function (section_id) {
            const path = m.lookupOption('_file', section_id)[0].formvalue(section_id);
            return fs.write(path);
        };

        return m.render();
    },
    handleSaveApply: function (ev, mode) {
        return this.handleSave(ev).finally(function () {
            return mode === '0' ? momo.reload() : momo.restart();
        });
    },
    handleReset: null
});
