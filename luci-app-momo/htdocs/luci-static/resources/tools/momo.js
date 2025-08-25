'use strict';
'require baseclass';
'require uci';
'require fs';
'require rpc';
'require request';

const callRCList = rpc.declare({
    object: 'rc',
    method: 'list',
    params: ['name'],
    expect: { '': {} }
});

const callRCInit = rpc.declare({
    object: 'rc',
    method: 'init',
    params: ['name', 'action'],
    expect: { '': {} }
});

const callMomoGetPaths = rpc.declare({
    object: 'luci.momo',
    method: 'get_paths',
    expect: { '': {} }
});

const callMomoVersion = rpc.declare({
    object: 'luci.momo',
    method: 'version',
    expect: { '': {} }
});

const callMomoProfile = rpc.declare({
    object: 'luci.momo',
    method: 'profile',
    params: ['defaults'],
    expect: { '': {} }
});

const callMomoUpdateSubscription = rpc.declare({
    object: 'luci.momo',
    method: 'update_subscription',
    params: ['section_id'],
    expect: { '': {} }
});

const callMomoAPI = rpc.declare({
    object: 'luci.momo',
    method: 'api',
    params: ['method', 'path', 'query', 'body'],
    expect: { '': {} }
});

const callMomoGetIdentifiers = rpc.declare({
    object: 'luci.momo',
    method: 'get_identifiers',
    expect: { '': {} }
});

const callMomoDebug = rpc.declare({
    object: 'luci.momo',
    method: 'debug',
    expect: { '': {} }
});

return baseclass.extend({
    getPaths: async function () {
        return callMomoGetPaths();
    },

    status: async function () {
        return (await callRCList('momo'))?.momo?.running;
    },

    reload: function () {
        return callRCInit('momo', 'reload');
    },

    restart: function () {
        return callRCInit('momo', 'restart');
    },

    version: function () {
        return callMomoVersion();
    },

    profile: function (defaults) {
        return callMomoProfile(defaults);
    },

    updateSubscription: function (section_id) {
        return callMomoUpdateSubscription(section_id);
    },

    updateDashboard: function () {
        return callMomoAPI('POST', '/upgrade/ui');
    },

    openDashboard: async function () {
        const profile = await callMomoProfile({ 'experimental': { 'clash_api': { 'external_controller': null, 'secret': null } } });
        const apiListen = profile?.['experimental']?.['clash_api']?.['external_controller'];
        const apiSecret = profile?.['experimental']?.['clash_api']?.['secret'] ?? '';
        if (!apiListen) {
            return Promise.reject('Clash API has not been configured');
        }
        const apiPort = apiListen.substring(apiListen.lastIndexOf(':') + 1);
        const params = {
            host: window.location.hostname,
            hostname: window.location.hostname,
            port: apiPort,
            secret: apiSecret
        };
        const query = new URLSearchParams(params).toString();
        const url = `http://${window.location.hostname}:${apiPort}/ui/?${query}`;
        setTimeout(function () { window.open(url, '_blank') }, 0);
        return Promise.resolve();
    },

    getIdentifiers: function () {
        return callMomoGetIdentifiers();
    },

    listProfiles: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(fs.list(paths.profiles_dir), []);
    },

    getAppLog: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(fs.read_direct(paths.app_log_path));
    },

    getCoreLog: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(fs.read_direct(paths.core_log_path));
    },

    clearAppLog: async function () {
        const paths = await this.getPaths();
        return fs.write(paths.app_log_path);
    },

    clearCoreLog: async function () {
        const paths = await this.getPaths();
        return fs.write(paths.core_log_path);
    },

    debug: function () {
        return callMomoDebug();
    },
})
