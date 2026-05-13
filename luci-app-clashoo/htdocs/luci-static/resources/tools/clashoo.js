'use strict';
'require baseclass';
'require rpc';
'require ui';

(function () {
    if (document.getElementById('clashoo-toast-style')) return;
    var css = [
        '#clashoo-toast-stack{position:fixed;top:20px;right:20px;z-index:99999;display:flex;flex-direction:column;gap:8px;max-width:380px;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
        '.clashoo-toast{background:rgba(33,37,41,.92);color:#fff;font-size:13px;line-height:1.5;padding:10px 14px;border-radius:8px;box-shadow:0 4px 14px rgba(0,0,0,.18);opacity:0;transform:translateX(24px);transition:opacity .25s ease,transform .25s ease;pointer-events:auto;cursor:pointer;word-break:break-word}',
        '.clashoo-toast.show{opacity:1;transform:translateX(0)}',
        '.clashoo-toast.err{background:rgba(198,40,40,.94)}',
        '.clashoo-toast.ok{background:rgba(46,125,50,.94)}',
        '.clashoo-toast a{color:#8ec5ff;text-decoration:underline}',
        '.clashoo-toast a:hover{color:#b3d7ff}'
    ].join('');
    var s = document.createElement('style');
    s.id = 'clashoo-toast-style';
    s.textContent = css;
    document.head.appendChild(s);
})();

function _clashooToastStack() {
    var el = document.getElementById('clashoo-toast-stack');
    if (!el) {
        el = document.createElement('div');
        el.id = 'clashoo-toast-stack';
        document.body.appendChild(el);
    }
    return el;
}

function _clashooLinkify(safeText) {
    var logUrl = L.url('admin/services/clashoo/system');
    return safeText.replace(/(进度|日志)/g,
        '<a href="' + logUrl + '">$1</a>');
}

function _clashooToast(msg, opts) {
    opts = opts || {};
    var stack = _clashooToastStack();
    var el = document.createElement('div');
    el.className = 'clashoo-toast' + (opts.kind ? ' ' + opts.kind : '');
    var text;
    if (msg && msg.nodeType === 1) text = msg.textContent || '';
    else if (typeof msg === 'string') text = msg;
    else text = String(msg || '');
    var safe = text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    el.innerHTML = _clashooLinkify(safe);
    stack.appendChild(el);
    requestAnimationFrame(function () { el.classList.add('show'); });

    var dur = opts.duration || 3500;
    var timer = null, remain = dur, start = 0;
    function close() {
        if (timer) { clearTimeout(timer); timer = null; }
        el.classList.remove('show');
        setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 280);
    }
    function arm() { start = Date.now(); timer = setTimeout(close, remain); }
    el.addEventListener('mouseenter', function () {
        if (timer) { clearTimeout(timer); timer = null; remain = Math.max(800, remain - (Date.now() - start)); }
    });
    el.addEventListener('mouseleave', arm);
    el.addEventListener('click', function (ev) {
        if (ev.target && ev.target.tagName === 'A') return;
        close();
    });
    arm();
    return { close: close };
}

(function () {
    if (!ui || ui._clashooPatched) return;
    ui._clashooPatched = true;
    var orig = ui.addNotification.bind(ui);
    ui.addNotification = function (title, children, classes) {
        try {
            var text = '';
            var collect = function (c) {
                if (c == null) return;
                if (Array.isArray(c)) { c.forEach(collect); return; }
                if (c.nodeType === 1) { text += (c.textContent || '') + ' '; return; }
                text += String(c) + ' ';
            };
            if (title) text += title + ' ';
            collect(children);
            text = text.trim();

            var kind = '';
            var cls = classes ? String(classes) : '';
            if (/error|danger/i.test(cls) || /失败|错误/.test(text)) kind = 'err';
            else if (/success/i.test(cls) || /成功/.test(text)) kind = 'ok';

            _clashooToast(text, { kind: kind });
            return null;
        } catch (e) {
            return orig(title, children, classes);
        }
    };
})();

const callStatus        = rpc.declare({ object: 'luci.clashoo', method: 'status',           expect: {} });
const callStart         = rpc.declare({ object: 'luci.clashoo', method: 'start',            expect: {} });
const callStop          = rpc.declare({ object: 'luci.clashoo', method: 'stop',             expect: {} });
const callReload        = rpc.declare({ object: 'luci.clashoo', method: 'reload',           expect: {} });
const callRestart       = rpc.declare({ object: 'luci.clashoo', method: 'restart',          expect: {} });
const callVersion       = rpc.declare({ object: 'luci.clashoo', method: 'version',          expect: {} });
const callListProf      = rpc.declare({ object: 'luci.clashoo', method: 'list_profiles',    expect: {} });
const callListConfigs   = rpc.declare({ object: 'luci.clashoo', method: 'list_configs',     expect: {} });
const callSetConfig     = rpc.declare({ object: 'luci.clashoo', method: 'set_config',       params: ['name'], expect: {} });
const callSetMode       = rpc.declare({ object: 'luci.clashoo', method: 'set_mode',         params: ['mode'], expect: {} });
const callSetProxyMode  = rpc.declare({ object: 'luci.clashoo', method: 'set_proxy_mode',   params: ['mode'], expect: {} });
const callSetCore       = rpc.declare({ object: 'luci.clashoo', method: 'set_core',         params: ['core', 'dcore'], expect: {} });
const callSetPanel      = rpc.declare({ object: 'luci.clashoo', method: 'set_panel',        params: ['name'], expect: {} });
const callUpdatePanel   = rpc.declare({ object: 'luci.clashoo', method: 'update_panel',     params: ['name'], expect: {} });
const callReadLog       = rpc.declare({ object: 'luci.clashoo', method: 'read_log',         expect: {} });
const callReadRealLog   = rpc.declare({ object: 'luci.clashoo', method: 'read_real_log',    expect: {} });
const callClearLog      = rpc.declare({ object: 'luci.clashoo', method: 'clear_log',        expect: {} });
const callReadUpdateLog = rpc.declare({ object: 'luci.clashoo', method: 'read_update_log',  expect: {} });
const callClearUpdateLog= rpc.declare({ object: 'luci.clashoo', method: 'clear_update_log', expect: {} });
const callReadGeoipLog         = rpc.declare({ object: 'luci.clashoo', method: 'read_geoip_log',          expect: {} });
const callClearGeoipLog        = rpc.declare({ object: 'luci.clashoo', method: 'clear_geoip_log',         expect: {} });
const callReadCoreLog          = rpc.declare({ object: 'luci.clashoo', method: 'read_core_log',           expect: {} });
const callClearCoreLog         = rpc.declare({ object: 'luci.clashoo', method: 'clear_core_log',          expect: {} });
const callReadUpdateMergedLog  = rpc.declare({ object: 'luci.clashoo', method: 'read_update_merged_log',  expect: {} });
const callClearUpdateMergedLog = rpc.declare({ object: 'luci.clashoo', method: 'clear_update_merged_log', expect: {} });
const callGetCpuArch    = rpc.declare({ object: 'luci.clashoo', method: 'get_cpu_arch',     expect: {} });
const callDownloadCore  = rpc.declare({ object: 'luci.clashoo', method: 'download_core',    expect: {} });
const callUpdateGeoip      = rpc.declare({ object: 'luci.clashoo', method: 'update_geoip',      expect: {} });
const callGetGeoipVersion  = rpc.declare({ object: 'luci.clashoo', method: 'get_geoip_version', expect: {} });
const callUpdateChinaIp = rpc.declare({ object: 'luci.clashoo', method: 'update_china_ip',  expect: {} });
const callGetLogStatus  = rpc.declare({ object: 'luci.clashoo', method: 'get_log_status',   expect: {} });
const callAccessCheck       = rpc.declare({ object: 'luci.clashoo', method: 'access_check',       expect: {} });
const callAccessCheckRefresh= rpc.declare({ object: 'luci.clashoo', method: 'access_check_refresh',expect: {} });
const callOverviewStats     = rpc.declare({ object: 'luci.clashoo', method: 'overview_stats',     expect: {} });
const callOverview          = rpc.declare({ object: 'luci.clashoo', method: 'overview',           expect: {} });
const callSmartFlushCache       = rpc.declare({ object: 'luci.clashoo', method: 'smart_flush_cache',       expect: {} });
const callSmartUpgradeLgbm      = rpc.declare({ object: 'luci.clashoo', method: 'smart_upgrade_lgbm',      expect: {} });
const callSmartUpgradeLgbmStatus= rpc.declare({ object: 'luci.clashoo', method: 'smart_upgrade_lgbm_status', expect: {} });
const callSmartModelStatus      = rpc.declare({ object: 'luci.clashoo', method: 'smart_model_status',      expect: {} });
const callListSingboxProfiles   = rpc.declare({ object: 'luci.clashoo', method: 'list_singbox_profiles',   expect: {} });
const callGetSingboxProfile     = rpc.declare({ object: 'luci.clashoo', method: 'get_singbox_profile',     params: ['name'],                   expect: {} });
const callSaveSingboxProfile    = rpc.declare({ object: 'luci.clashoo', method: 'save_singbox_profile',    params: ['name', 'content'],         expect: {} });
const callSetSingboxProfile     = rpc.declare({ object: 'luci.clashoo', method: 'set_singbox_profile',     params: ['name'],                   expect: {} });
const callDeleteSingboxProfile  = rpc.declare({ object: 'luci.clashoo', method: 'delete_singbox_profile',  params: ['name'],                   expect: {} });
const callCreateSingboxConfig   = rpc.declare({ object: 'luci.clashoo', method: 'create_singbox_config',   params: ['sub_url', 'name'], expect: {} });
const callCommitConfig          = rpc.declare({ object: 'luci.clashoo', method: 'commit_config',            expect: {} });
const callDnsAutoSetup          = rpc.declare({ object: 'luci.clashoo', method: 'dns_auto_setup',           expect: {} });
const callFetchSingboxNative    = rpc.declare({ object: 'luci.clashoo', method: 'fetch_singbox_native',    params: ['url', 'name'],  expect: {} });
const callUpdateSingboxNative   = rpc.declare({ object: 'luci.clashoo', method: 'update_singbox_native',   params: ['name'],         expect: {} });

// 把脚本输出的英文 log 行翻成中文（去掉前导时间戳）
function localizeLogLine(line) {
    var msg = String(line || '').replace(/^\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s*-?\s*/, '');
    var rules = [
        // LightGBM 模型更新
        [/^Start downloading LightGBM model from:?\s*(.*)$/i, '开始下载 LightGBM 模型：$1'],
        [/^Model unchanged, no update needed$/i,              '模型已是最新版本，无需更新'],
        [/^LightGBM model updated successfully$/i,            'LightGBM 模型更新成功'],
        [/^Download failed \(rc=(\d+)\)$/i,                   '下载失败（错误码 $1）'],
        [/^Failed to install model to (.*)$/i,                '模型安装失败：$1'],
        [/^No curl or wget found$/i,                          '未找到 curl 或 wget'],
        // GeoIP / GeoSite 更新
        [/^Updating (.+)$/i,                                  '正在更新 $1'],
        [/^(.+) updated$/i,                                   '$1 已更新'],
        [/^GeoIP update completed, apply on next Clashoo restart$/i, 'GeoIP 更新完成，重启 Clashoo 后生效'],
        [/^GeoIP update completed$/i,                         'GeoIP 更新完成'],
        [/^GeoIP update failed$/i,                            'GeoIP 更新失败'],
        // 通用
        [/^Download succeeded$/i,                             '下载成功'],
        [/^Already up to date$/i,                             '已是最新版本']
    ];
    for (var i = 0; i < rules.length; i++) {
        if (rules[i][0].test(msg)) return msg.replace(rules[i][0], rules[i][1]);
    }
    return msg;
}

return baseclass.extend({
    localizeLogLine: localizeLogLine,
    status: function () { return L.resolveDefault(callStatus(), {}); },
    start: function () { return L.resolveDefault(callStart(), {}); },
    stop: function () { return L.resolveDefault(callStop(), {}); },
    reload: function () { return L.resolveDefault(callReload(), {}); },
    restart: function () { return L.resolveDefault(callRestart(), {}); },
    version: function () { return L.resolveDefault(callVersion(), {}); },

    listProfiles: function () { return L.resolveDefault(callListProf(), { profiles: [] }).then(r => r.profiles || []); },
    listConfigs: function () { return L.resolveDefault(callListConfigs(), { configs: [], current: '' }); },
    setConfig: function (name) { return L.resolveDefault(callSetConfig(name), {}); },
    setMode: function (mode) { return L.resolveDefault(callSetMode(mode), {}); },
    setProxyMode: function (mode) { return L.resolveDefault(callSetProxyMode(mode), {}); },
    setCore: function (core, dcore) { return L.resolveDefault(callSetCore(core, dcore), {}); },
    setPanel: function (name) { return L.resolveDefault(callSetPanel(name), {}); },
    updatePanel: function (name) { return L.resolveDefault(callUpdatePanel(name || 'metacubexd'), {}); },

    readLog: function () { return L.resolveDefault(callReadLog(), { content: '' }).then(r => r.content || ''); },
    readRealLog: function () { return L.resolveDefault(callReadRealLog(), { content: '' }).then(r => r.content || ''); },
    clearLog: function () { return L.resolveDefault(callClearLog(), {}); },
    readUpdateLog: function () { return L.resolveDefault(callReadUpdateLog(), { content: '' }).then(r => r.content || ''); },
    clearUpdateLog: function () { return L.resolveDefault(callClearUpdateLog(), {}); },
	    readGeoipLog: function () { return L.resolveDefault(callReadGeoipLog(), { content: '' }).then(r => r.content || ''); },
	    clearGeoipLog: function () { return L.resolveDefault(callClearGeoipLog(), {}); },
	    readCoreLog: function () { return L.resolveDefault(callReadCoreLog(), { content: '' }).then(r => r.content || ''); },
	    clearCoreLog: function () { return L.resolveDefault(callClearCoreLog(), {}); },
	    readUpdateMergedLog: function () { return L.resolveDefault(callReadUpdateMergedLog(), { content: '' }).then(r => r.content || ''); },
    clearUpdateMergedLog: function () { return L.resolveDefault(callClearUpdateMergedLog(), {}); },

    getCpuArch: function () { return L.resolveDefault(callGetCpuArch(), { arch: '' }).then(r => r.arch || ''); },
    downloadCore: function (dcore, arch) { return L.resolveDefault(callDownloadCore({ dcore: dcore, arch: arch }), {}); },
    updateGeoip:      function () { return L.resolveDefault(callUpdateGeoip(),     {}); },
    getGeoipVersion:  function () { return L.resolveDefault(callGetGeoipVersion(), { version: '' }); },
    updateChinaIp: function () { return L.resolveDefault(callUpdateChinaIp(), {}); },
    getLogStatus: function () { return L.resolveDefault(callGetLogStatus(), {}); },
    accessCheck:        function () { return L.resolveDefault(callAccessCheck(),      {}); },
    accessCheckRefresh: function () { return L.resolveDefault(callAccessCheckRefresh(), { success: false }); },
    overviewStats:      function () { return L.resolveDefault(callOverviewStats(),    {}); },
    overview:           function () {
        return L.resolveDefault(callOverview(), {
            status: {},
            stats: {},
            configs: { configs: [], current: '', core_type: '' },
            access: {}
        });
    },
    smartFlushCache:    function () { return L.resolveDefault(callSmartFlushCache(),  { success: false }); },
    smartUpgradeLgbm:       function () { return L.resolveDefault(callSmartUpgradeLgbm(), { success: false }); },
    smartUpgradeLgbmStatus: function () { return L.resolveDefault(callSmartUpgradeLgbmStatus(), { running: false }); },
    smartModelStatus:   function () { return L.resolveDefault(callSmartModelStatus(),  { has_model: false, version: '' }); },

    listSingboxProfiles:  function ()           { return L.resolveDefault(callListSingboxProfiles(),          { profiles: [], active: '' }); },
    getSingboxProfile:    function (name)        { return L.resolveDefault(callGetSingboxProfile(name),        {}); },
    saveSingboxProfile:   function (name, content){ return L.resolveDefault(callSaveSingboxProfile(name, content), {}); },
    setSingboxProfile:    function (name)        { return L.resolveDefault(callSetSingboxProfile(name),        {}); },
    deleteSingboxProfile: function (name)        { return L.resolveDefault(callDeleteSingboxProfile(name),     {}); },
    createSingboxConfig:  function (url, name) { return L.resolveDefault(callCreateSingboxConfig(url, name), {}); },
    commitConfig:         function ()               { return L.resolveDefault(callCommitConfig(),               { success: false }); },
    dnsAutoSetup:         function ()               { return L.resolveDefault(callDnsAutoSetup(),               { success: false }); },
    fetchSingboxNative:   function (url, name)      { return L.resolveDefault(callFetchSingboxNative(url, name), {}); },
    updateSingboxNative:  function (name)           { return L.resolveDefault(callUpdateSingboxNative(name),     {}); },

    toast: _clashooToast
});
