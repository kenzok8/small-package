const assert = require('node:assert/strict');
const vm = require('node:vm');
function page(installed, hostname = '192.168.30.7') {
    const elements = Object.fromEntries(['classic-kai-status', 'classic-kai-install', 'classic-kai-update', 'classic-kai-update-hint', 'classic-kai-open']
        .map(id => [id, { style: {}, disabled: false }]));
    const state = { elements, alerts: [], logs: [], reloads: 0 };
    function XHR() {}
    XHR.poll = (_, url, data, callback) => { state.poll = callback; };
    XHR.prototype.post = (url, data, callback) => { state.post = { url, data, callback }; };
    const context = {
        XHR, document: { getElementById: id => elements[id] },
        window: {
            confirm: () => true, alert: message => state.alerts.push(message),
            location: { hostname, reload: () => state.reloads++ },
            taskd: { csrfToken: 'test-token', show_log: id => state.logs.push(id) }
        }
    };
    vm.createContext(context);
    vm.runInContext(source.replace('PAGE_INSTALLED', String(installed)), context);
    state.context = context;
    return state;
}
let state = page(false);
state.poll(null, { installed: false, running: false });
assert.equal(state.elements['classic-kai-install'].style.display, '');
assert.equal(state.elements['classic-kai-open'].style.display, 'none');
assert.equal(state.elements['classic-kai-update'].style.display, 'none');
state.context.installClassicKai();
assert.equal(state.post.data.token, 'test-token');
assert.equal(state.post.url, '/cgi-bin/luci/admin/services/kaiplus/install_kai');
assert.equal(state.elements['classic-kai-install'].disabled, true);
state.post.callback({ responseText: '{"ok":true,"task_id":"kaiplus-kai-install"}' });
assert.deepEqual(state.logs, ['kaiplus-kai-install']);
assert.equal(state.elements['classic-kai-install'].disabled, false);
state.poll(null, { installed: true, running: false });
assert.equal(state.reloads, 1);
state = page(false);
state.context.installClassicKai();
state.post.callback({ responseText: 'invalid response' });
assert.equal(state.alerts.length, 1);
assert.equal(state.elements['classic-kai-install'].disabled, false);
state.context.installClassicKai();
state.post.callback({ responseText: '{"ok":false,"error":"installer unavailable"}' });
assert.equal(state.alerts.at(-1), 'installer unavailable');
state.context.installClassicKai();
state.post.callback({ responseText: '{"ok":true,"installed":true}' });
assert.equal(state.reloads, 1);
state = page(true);
state.poll(null, { installed: true, running: true, port: 8197 });
assert.equal(state.elements['classic-kai-install'].style.display, 'none');
assert.equal(state.elements['classic-kai-update'].style.display, '');
assert.equal(state.elements['classic-kai-open'].style.display, '');
assert.equal(state.elements['classic-kai-status'].style.color, 'green');
assert.equal(state.reloads, 0);
assert.equal(state.context.classicOpenUrl, '/cgi-bin/luci/admin/services/linkease_auth/auth?return=' + encodeURIComponent('http://192.168.30.7:8197/apps/kai/'));
const ipv6 = page(true, '[fd00::7]');
ipv6.poll(null, { installed: true, running: true, port: 8201 });
assert.equal(ipv6.context.classicOpenUrl, '/cgi-bin/luci/admin/services/linkease_auth/auth?return=' + encodeURIComponent('http://[fd00::7]:8201/apps/kai/'));
for (const port of [0, 65536, 1.5, 'invalid', undefined]) {
    ipv6.poll(null, { installed: true, running: true, port });
    assert.equal(ipv6.context.classicOpenUrl, '');
    assert.equal(ipv6.elements['classic-kai-open'].style.display, 'none');
}
state.poll(null, { installed: true, running: false });
assert.equal(state.elements['classic-kai-open'].style.display, 'none');
assert.equal(state.elements['classic-kai-update'].style.display, '');
state.context.updateClassicKai();
assert.equal(state.post.url, '/cgi-bin/luci/admin/services/kaiplus/update_kai');
assert.equal(state.post.data.token, 'test-token');
assert.equal(state.elements['classic-kai-update'].disabled, true);
state.post.callback({ responseText: '{"ok":true,"busy":true,"task_id":"kaiplus-kai-install"}' });
assert.deepEqual(state.logs, ['kaiplus-kai-install']);
assert.equal(state.elements['classic-kai-update'].disabled, false);
assert.equal(state.reloads, 0);
state.context.updateClassicKai();
state.post.callback({ responseText: 'invalid response' });
assert.equal(state.alerts.length, 1);
assert.equal(state.elements['classic-kai-update'].disabled, false);
state.context.window.confirm = () => false;
state.post = undefined;
state.context.updateClassicKai();
assert.equal(state.post, undefined);
