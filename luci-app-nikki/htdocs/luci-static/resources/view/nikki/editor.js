'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require tools.nikki as nikki'

function loadJS(url) {
    return new Promise(function (resolve, reject) {
        const script = document.createElement('script');
        script.src = url;
        script.onload = resolve;
        script.onerror = reject;
        document.body.appendChild(script);
    });
}

function loadCSS(url) {
    return new Promise(function (resolve, reject) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = url;
        link.onload = resolve;
        link.onerror = reject;
        document.head.appendChild(link);
    });
}

async function loadCodeMirror() {
    try{
        await loadJS('https://unpkg.com/codemirror@5/lib/codemirror.js');
        await loadJS('https://unpkg.com/codemirror@5/mode/yaml/yaml.js');
        await loadCSS('https://unpkg.com/codemirror@5/lib/codemirror.css');
        await loadCSS('https://unpkg.com/codemirror@5/theme/dracula.css');
    } catch (e) {
        
    }
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('nikki'),
            nikki.listProfiles(),
            nikki.listRuleProviders(),
            nikki.listProxyProviders(),
            loadCodeMirror(),
        ]);
    },
    render: function (data) {
        const subscriptions = uci.sections('nikki', 'subscription');
        const profiles = data[1];
        const ruleProviders = data[2];
        const proxyProviders = data[3];

        let m, s, o;

        m = new form.Map('nikki');

        s = m.section(form.NamedSection, 'editor', 'editor', _('Editor'));

        o = s.option(form.ListValue, '_file', _('Choose File'));
        o.optional = true;

        for (const profile of profiles) {
            o.value(nikki.profilesDir + '/' + profile.name, _('File:') + profile.name);
        };

        for (const subscription of subscriptions) {
            o.value(nikki.subscriptionsDir + '/' + subscription['.name'] + '.yaml', _('Subscription:') + subscription.name);
        };

        for (const ruleProvider of ruleProviders) {
            o.value(nikki.ruleProvidersDir + '/' + ruleProvider.name, _('Rule Provider:') + ruleProvider.name);
        };

        for (const proxyProvider of proxyProviders) {
            o.value(nikki.proxyProvidersDir + '/' + proxyProvider.name, _('Proxy Provider:') + proxyProvider.name);
        };

        o.value(nikki.mixinFilePath, _('File for Mixin'));
        o.value(nikki.runProfilePath, _('Profile for Startup'));
        o.value(nikki.reservedIPNFT, _('File for Reserved IP'));
        o.value(nikki.reservedIP6NFT, _('File for Reserved IP6'));

        o.write = function (section_id, formvalue) {
            return true;
        };
        o.onchange = L.bind(function (event, section_id, value) {
            const uiElement = this.getUIElement(section_id, '_file_content');
            const editor = uiElement.node.firstChild.editor;
            fs.read_direct(value).then(function (content) {
                const mode = value.endsWith('.yml') || value.endsWith('.yaml') ? 'yaml' : null;
                uiElement.setValue(content);
                if (editor) {
                    editor.setValue(content);
                    editor.setOption('mode', mode);
                    editor.getDoc().clearHistory();
                }
            }).catch(function (e) {
                uiElement.setValue('');
                if (editor) {
                    editor.setValue('');
                    editor.setOption('mode', null);
                    editor.getDoc().clearHistory();
                }
            })
        }, s);

        o = s.option(form.TextValue, '_file_content',);
        o.rows = 25;
        o.wrap = false;
        o.write = L.bind(function (section_id, formvalue) {
            const path = this.getOption('_file').formvalue(section_id);
            return fs.write(path, formvalue);
        }, s);
        o.remove = L.bind(function (section_id) {
            const path = this.getOption('_file').formvalue(section_id);
            return fs.write(path);
        }, s);
        o.render = function () {
            return this.super('render', arguments).then(function (widget) {
                const textarea = widget.firstChild.firstChild;
                if (CodeMirror) {
                    const editor = CodeMirror.fromTextArea(textarea, { lineNumbers: true, theme: 'dracula' });
                    editor.on('change', function () {
                        editor.save();
                    });
                    editor.getWrapperElement().style.height = '420px';
                    textarea.editor = editor;
                }
                return widget;
            });
        };

        return m.render();
    },
    handleSaveApply: function (ev, mode) {
        return this.handleSave(ev).finally(function () {
            return mode === '0' ? nikki.reload() : nikki.restart();
        });
    },
    handleReset: null
});
