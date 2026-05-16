'use strict';
'require view';
'require poll';
'require ui';
'require rpc';
'require uci';
'require tools.clashoo as clashoo';

var CSS = [
  '.cl-wrap{padding:8px 0}',
  '.cl-wrap{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
  '.cl-wrap{--cl-live-title-color:rgba(40,50,68,.62);--cl-live-main-color:rgba(84,96,116,.92);--cl-live-sub-color:rgba(74,86,106,.72);--cl-live-foot-color:rgba(74,86,106,.72);--cl-live-zero-color:rgba(128,128,128,.5)}',
  'body.dark .cl-wrap,body.dark .cl-wrap,body[data-theme="dark"] .cl-wrap,body[data-darkmode="1"] .cl-wrap,body[data-darkmode="true"] .cl-wrap,html.dark .cl-wrap,html.dark .cl-wrap,html[data-theme="dark"] .cl-wrap,html[data-bs-theme="dark"] .cl-wrap,html[data-darkmode="1"] .cl-wrap,html[data-darkmode="true"] .cl-wrap{--cl-live-title-color:rgba(230,238,252,.74);--cl-live-main-color:rgba(228,236,248,.9);--cl-live-sub-color:rgba(208,219,238,.72);--cl-live-foot-color:rgba(208,219,238,.72)}',
  '.cl-status-kernel{display:inline-flex;align-items:center;gap:2px;height:26px;padding:1px;border-radius:8px;border:0;background:rgba(0,0,0,.03)}',
  '.cl-status-kernel .cl-core-btn{height:24px;line-height:24px;min-width:58px;padding:0 6px;border:0;border-radius:6px;background:transparent;font-size:11px;font-weight:600;cursor:pointer;opacity:.82}',
  '.cl-status-kernel .cl-core-btn.active{background:rgba(var(--primary-rgb,0,122,255),.2);border:0;color:var(--primary-color,#0b68dd);box-shadow:none;opacity:1}',
  '.cl-status-kernel .cl-core-btn:disabled{opacity:.48;cursor:not-allowed}',
  '.cl-status-kernel.is-busy{opacity:.9}',
  '.cl-core-switch-wrap{display:flex;flex-direction:column;align-items:flex-start;gap:6px}',
  '.cl-core-switch-hint{font-size:12px;line-height:1.35;color:rgba(74,86,106,.72)}',
  'body.dark .cl-core-switch-hint,html[data-theme="dark"] .cl-core-switch-hint,html[data-bs-theme="dark"] .cl-core-switch-hint{color:rgba(208,219,238,.72)}',
  'body.dark .cl-status-kernel,body.dark .cl-status-kernel,html[data-theme="dark"] .cl-status-kernel,html[data-bs-theme="dark"] .cl-status-kernel{border:0;background:rgba(255,255,255,.06)}',
  'body.dark .cl-status-kernel .cl-core-btn.active,body.dark .cl-status-kernel .cl-core-btn.active,html[data-theme="dark"] .cl-status-kernel .cl-core-btn.active,html[data-bs-theme="dark"] .cl-status-kernel .cl-core-btn.active{background:rgba(var(--primary-rgb,122,180,255),.24);border:0;color:rgba(222,236,255,.96);box-shadow:none}',
  '.cl-cards{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:16px}',
  '.cl-card{border:1px solid rgba(0,0,0,.05);border-radius:10px;padding:14px 16px;min-height:70px;box-shadow:0 4px 12px rgba(0,0,0,.03)}',
  '.cl-card-head{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:4px}',
  '.cl-card .lbl{font-size:11px;opacity:.55;margin:0}',
  '.cl-card-tools{display:flex;align-items:center;gap:6px}',
  '.cl-icon-btn{border:0;background:transparent;padding:0;width:16px;height:16px;line-height:16px;font-size:13px;opacity:.55;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;color:inherit}',
  '.cl-icon-btn:hover{opacity:.9}',
  '.cl-icon-btn.is-loading{animation:cl-spin 1s linear infinite;pointer-events:none;opacity:.75}',
  '.cl-card .val{font-size:11px;font-weight:500;word-break:break-all}',
  '.cl-card-mode .val{line-height:1.45;word-break:normal}',
  '.cl-mode-stack{display:flex;flex-direction:column;gap:4px;justify-content:flex-start;align-items:flex-start}',
  '.cl-mode-tag{display:flex;align-items:center;justify-content:flex-start;padding:0;border-radius:0;font-size:11px;line-height:1.35;background:transparent;color:inherit;opacity:.5;width:max-content;max-width:100%;text-align:left}',
  'body.dark .cl-mode-tag,body.dark .cl-mode-tag,body[data-theme="dark"] .cl-mode-tag,body[data-darkmode="1"] .cl-mode-tag,body[data-darkmode="true"] .cl-mode-tag,html.dark .cl-mode-tag,html.dark .cl-mode-tag,html[data-theme="dark"] .cl-mode-tag,html[data-bs-theme="dark"] .cl-mode-tag,html[data-darkmode="1"] .cl-mode-tag,html[data-darkmode="true"] .cl-mode-tag{background:transparent;color:inherit;opacity:.5}',
  '.cl-mode-tag-degraded{color:#b56f00}',
  '.cl-check-note{display:block;margin-top:6px;font-size:11px;line-height:1.45;opacity:.6;font-weight:400}',
    '.cl-badge{display:inline-flex;align-items:center;justify-content:center;padding:2px 12px;border-radius:999px;font-size:11px;font-weight:700;line-height:1.2;background:transparent;border:1px solid transparent}',
    '.cl-badge-run{background:transparent;color:#4aa065;border-color:rgba(74,160,101,.46)}',
    '.cl-badge-stop{background:transparent;color:#df6e6e;border-color:rgba(223,110,110,.52)}',
    '.cl-badge-sync{background:rgba(128,128,128,.08);color:rgba(128,128,128,.92);border-color:rgba(128,128,128,.35)}',
    '.cl-service-tools{display:inline-flex;align-items:center;gap:8px;white-space:nowrap}',
    '.cl-service-label{font-size:11px;font-weight:600;opacity:.62}',
    '.cl-service-switch{position:relative;width:48px;height:26px;border:0;border-radius:999px;background:rgba(128,128,128,.22);padding:2px;box-shadow:none;cursor:pointer;transition:background .18s ease,opacity .18s ease}',
    '.cl-service-switch .cl-service-knob{position:absolute;top:3px;left:3px;width:20px;height:20px;border-radius:50%;background:rgba(255,255,255,.94);box-shadow:0 1px 4px rgba(0,0,0,.18);transition:transform .18s ease,background .18s ease}',
    '.cl-service-switch.is-on{background:rgba(74,160,101,.52)}',
    '.cl-service-switch.is-on .cl-service-knob{transform:translateX(22px)}',
    '.cl-service-switch:disabled{opacity:.48;cursor:not-allowed}',
    '.cl-controls{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:16px}',
  '.cl-ctrl{border:0 !important;border-radius:8px;padding:10px 12px;box-shadow:none !important;background:rgba(128,128,128,.04)}',
  '.cl-ctrl label{display:block;font-size:11px;opacity:.55;margin-bottom:6px}',
  '.cl-ctrl select{width:100%;font-size:13px;box-sizing:border-box}',
  '.cl-ctrl-row{display:flex;gap:6px;align-items:center}',
  '.cl-ctrl-row select{flex:1;min-width:0}',
  '.cl-live-box{border:0 !important;border-radius:10px;padding:12px 14px;box-shadow:none !important;background:transparent}',
  '.cl-traffic-wrap{margin-bottom:12px}',
  '.cl-live-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}',
  '.cl-live-card,.cl-stat-card{position:relative;height:120px;min-height:120px;max-height:120px;box-sizing:border-box;border:0 !important;border-radius:12px;overflow:hidden;box-shadow:0 2px 10px rgba(0,0,0,.03)}',
  '.cl-live-content{position:relative;z-index:2;padding:11px 12px}',
  '.cl-live-bg-chart{position:absolute;left:8px;right:8px;bottom:8px;height:42px;z-index:1;pointer-events:none;opacity:.92}',
  '.cl-live-title{display:flex;align-items:center;gap:6px;font-size:12px;font-weight:600;margin-bottom:8px;color:var(--cl-live-title-color)}',
  '.cl-live-main{display:flex;align-items:flex-end;gap:6px;line-height:1;margin-bottom:14px}',
  '.cl-live-num{font-size:18px;font-weight:800;letter-spacing:-1px;color:var(--cl-live-main-color,rgba(84,96,116,.92));transition:color .18s ease,opacity .18s ease,text-shadow .22s ease,font-size .18s ease}',
  '.cl-live-unit{font-size:11px;font-weight:600;margin-left:3px;padding-bottom:2px;color:var(--cl-live-sub-color,rgba(74,86,106,.72));transition:color .18s ease,opacity .18s ease}',
  '.cl-live-svg{display:block;width:100%;height:100%}',
  '.cl-live-line{fill:none;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}',
  '.cl-live-area{opacity:.16}',
  '.cl-live-foot{font-size:11px;font-weight:500;color:var(--cl-live-foot-color,rgba(74,86,106,.72));transition:color .18s ease,opacity .18s ease}',
  '.cl-live-card.is-active .cl-live-num{color:var(--cl-live-main-color,rgba(84,96,116,.92))!important}',
  '.cl-live-card.is-zero .cl-live-num{font-size:16px;color:var(--cl-live-zero-color)!important;opacity:1;text-shadow:none}',
  '.cl-live-card.is-zero .cl-live-unit,.cl-live-card.is-zero .cl-live-foot{color:var(--cl-live-zero-color)!important;opacity:1}',
  '.cl-card-access .val{font-size:11px;font-weight:500}',
  '.cl-check-modern{display:flex;flex-direction:column;gap:10px}',
  '.cl-check-group{display:flex;flex-direction:column;gap:6px}',
  '.cl-check-group-title{font-size:11px;line-height:1;opacity:.55;font-weight:600;letter-spacing:.2px}',
  '.cl-check-item{display:flex;align-items:center;justify-content:flex-start}',
  '.cl-check-main{display:flex;align-items:center;gap:10px;min-width:0}',
  '.cl-check-icon-wrap{width:18px;height:18px;display:inline-flex;align-items:center;justify-content:center;background:transparent!important;border:0!important;border-radius:0!important;box-shadow:none!important;padding:0!important;overflow:visible}',
  '.cl-check-icon{width:18px;height:18px;object-fit:contain;display:block;flex-shrink:0;background:transparent!important;border:0!important;box-shadow:none!important;border-radius:0!important;padding:0!important;outline:0!important}',
  '.cl-check-item img,.cl-check-main img{background:transparent!important;border:0!important;box-shadow:none!important;border-radius:0!important;padding:0!important;outline:0!important}',
  '.cl-check-icon-fallback{width:18px;height:18px;display:inline-flex;align-items:center;justify-content:center;border-radius:50%;font-size:10px;font-weight:700;background:rgba(31,157,85,.12);color:#1f9d55;flex-shrink:0}',
  '.cl-check-name{font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;width:100px;min-width:100px;max-width:100px;flex:0 0 100px}',
  '.cl-check-latency{margin-left:20px;width:78px;min-width:78px;text-align:left;font-size:11px;font-weight:600;white-space:nowrap;font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace;font-variant-numeric:tabular-nums}',
  '.cl-lat-green{color:#2aa85b}',
  '.cl-lat-warn{color:#d39e00}',
  '.cl-lat-red{color:#c96a5a}',
  '.cl-signal{display:inline-flex;align-items:flex-end;justify-content:flex-start;gap:2px;width:30px;min-width:30px;margin-left:8px}',
  '.cl-signal i{display:block;width:4px;border-radius:2px;background:rgba(120,120,120,.25)}',
  '.cl-signal i:nth-child(1){height:6px}',
  '.cl-signal i:nth-child(2){height:9px}',
  '.cl-signal i:nth-child(3){height:12px}',
  '.cl-signal i:nth-child(4){height:15px}',
  '.cl-signal-green i.active{background:#2aa85b}',
  '.cl-signal-warn i.active{background:#d39e00}',
  '.cl-signal-red i.active{background:#c96a5a}',
  '.cl-signal-offline{opacity:.78;transform:translateX(3px)}',
  '.cl-check-updated{margin-top:6px;font-size:10px;line-height:1.3;opacity:.5}',
  '.cl-check-skeleton{display:flex;flex-direction:column;gap:10px}',
  '.cl-skel-row{display:flex;align-items:center;gap:10px}',
  '.cl-skel-icon{width:18px;height:18px;border-radius:4px;background:rgba(128,128,128,.16)}',
  '.cl-skel-line{height:10px;border-radius:999px;flex:1;background:linear-gradient(90deg,rgba(128,128,128,.10) 25%,rgba(128,128,128,.22) 50%,rgba(128,128,128,.10) 75%);background-size:220% 100%;animation:cl-shimmer 1.3s linear infinite}',
  '.cl-skel-line.short{max-width:90px}',
  '.cl-check-empty{font-size:12px;opacity:.55}',
  '.cl-wrap .cbi-input-text,.cl-wrap .cbi-input-select,.cl-wrap select,.cl-wrap input,.cl-wrap textarea,.cl-wrap .btn,.cl-wrap .cbi-button{font-size:13px !important;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif !important}',
  '.cl-wrap .btn,.cl-wrap .cbi-button{padding:4px 10px;line-height:1.35}',
  '@keyframes cl-fadein{from{opacity:0;transform:translateY(3px)}to{opacity:1;transform:translateY(0)}}',
  '@keyframes cl-spin{to{transform:rotate(360deg)}}',
  '@keyframes cl-shimmer{0%{background-position:220% 0}100%{background-position:-220% 0}}',
  '.cl-op-msg{font-size:12px;font-weight:500;opacity:.85;animation:cl-fadein .25s ease}',
  '@media(max-width:900px){.cl-cards{grid-template-columns:repeat(2,1fr)}.cl-controls{grid-template-columns:repeat(2,1fr)}}',
  '@media(max-width:640px){.cl-live-grid{grid-template-columns:1fr}}',
  '@media(max-width:480px){.cl-cards{grid-template-columns:1fr}.cl-controls{grid-template-columns:1fr}.cl-live-grid{grid-template-columns:1fr}}'
].join('');

var callDownloadSubs = rpc.declare({ object: 'luci.clashoo', method: 'download_subs', expect: {} });
var callOverview = rpc.declare({ object: 'luci.clashoo', method: 'overview', expect: {} });
function fastResolve(promise, timeoutMs, fallback) {
  var t = new Promise(function (resolve) {
    setTimeout(function () { resolve(fallback); }, timeoutMs);
  });
  return Promise.race([L.resolveDefault(promise, fallback), t]);
}

function rpcOverview() {
  var fallback = {
    status: {},
    stats: {},
    configs: { configs: [], current: '', core_type: '' },
    access: {}
  };
  return L.resolveDefault(callOverview(), fallback);
}

/* Progress message sequences — displayed step-by-step during async operations */
var MSGS = {
  mihomo: {
    start: [
      '启动客户端',
      '正在检查配置文件',
      '设置 mihomo 网络规则',
      '设置 DNS 转发器 / 启用自定义 DNS',
      '设置 Cron → 计划任务，启动进程守护程序...',
      '重启 Dnsmasq 程序',
      'mihomo 启动成功，请等待服务器上线！'
    ],
    stop: [
      '正在停止客户端...',
      '清理 mihomo 网络规则',
      '禁用 DNS 缓存',
      'mihomo 停止进程守护程序',
      '删除 Cron → 计划任务',
      '重启 Dnsmasq 程序'
    ],
    restart: [
      '正在重启客户端...',
      '清理 mihomo 网络规则',
      '停止 mihomo',
      '启动客户端',
      '正在检查配置文件',
      '设置 mihomo 网络规则',
      '重启 Dnsmasq 程序',
      'mihomo 重启成功，请等待服务器上线！'
    ]
  },
  singbox: {
    start: [
      '启动客户端',
      '正在检查配置文件',
      '设置 sing-box 网络规则',
      '设置 DNS 转发器 / 启用自定义 DNS',
      '设置 Cron → 计划任务，启动进程守护程序...',
      '重启 Dnsmasq 程序',
      'sing-box 启动成功，请等待服务器上线！'
    ],
    stop: [
      '正在停止客户端...',
      '清理 sing-box 网络规则',
      '禁用 DNS 缓存',
      'sing-box 停止进程守护程序',
      '删除 Cron → 计划任务',
      '重启 Dnsmasq 程序'
    ],
    restart: [
      '正在重启客户端...',
      '清理 sing-box 网络规则',
      '停止 sing-box',
      '启动客户端',
      '正在检查配置文件',
      '设置 sing-box 网络规则',
      '重启 Dnsmasq 程序',
      'sing-box 重启成功，请等待服务器上线！'
    ]
  }
};

return view.extend({
  _busy:      false,
  _op:        null,   /* 'start' | 'stop' | 'restart' | null */
  _opTimers:  null,   /* array of setTimeout IDs for cleanup */
  _accessRefreshing: false,
  _coreSwitchBusy: false,
  _coreSwitchMsg: '',
  _rtHistory: null,

  _lastAc:      null,
  _lastSt:      null,
  _lastCfgData: null,

  load: function () {
    return Promise.resolve(null);
  },

  _overviewCacheKey: 'clashoo.overview.last',

  _readCachedOverview: function () {
    try {
      if (!window.sessionStorage)
        return null;
      var raw = window.sessionStorage.getItem(this._overviewCacheKey);
      if (!raw)
        return null;
      var cached = JSON.parse(raw);
      if (!cached || !cached._ts || (Date.now() - cached._ts) > 60000)
        return null;
      if (!cached.status || typeof cached.status.running !== 'boolean')
        return null;
      return cached;
    } catch (e) {
      return null;
    }
  },

  _writeCachedOverview: function (ov) {
    try {
      if (!window.sessionStorage || !ov || !ov.status || typeof ov.status.running !== 'boolean')
        return;
      var copy = JSON.parse(JSON.stringify(ov));
      copy._ts = Date.now();
      window.sessionStorage.setItem(this._overviewCacheKey, JSON.stringify(copy));
    } catch (e) {}
  },

  _initialOverview: function () {
    var core = uci.get('clashoo', 'config', 'core_type') || 'mihomo';
    var useConfig = uci.get('clashoo', 'config', 'use_config') || '';
    var singboxActive = uci.get('clashoo', 'config', 'singbox_active') || '';
    var slash = useConfig.lastIndexOf('/');
    var configName = slash >= 0 ? useConfig.slice(slash + 1) : useConfig;
    if (core === 'singbox' && singboxActive)
      configName = singboxActive;

    return {
      status: {
        loading: true,
        running: null,
        core_type: core,
        dash_port: uci.get('clashoo', 'config', 'dash_port') || '9090',
        dash_pass: uci.get('clashoo', 'config', 'dash_pass') || '',
        panel_type: uci.get('clashoo', 'config', 'dashboard_panel') || 'zashboard',
        proxy_mode: uci.get('clashoo', 'config', 'p_mode') || 'rule',
        tcp_mode: uci.get('clashoo', 'config', 'tcp_mode') || 'tun',
        udp_mode: uci.get('clashoo', 'config', 'udp_mode') || (uci.get('clashoo', 'config', 'tcp_mode') || 'tun'),
        stack: uci.get('clashoo', 'config', 'stack') || 'system',
        config: configName,
        local_ip: location.hostname,
        health_status: 'loading'
      },
      stats: {},
      configs: {
        configs: configName ? [configName] : [],
        current: configName,
        core_type: core
      },
      access: {
        updated_at: '0',
        updating: true,
        items: []
      }
    };
  },

  render: function (data) {
    var ov      = this._readCachedOverview() || this._initialOverview();
    var st      = ov.status || {};
    var cfgData = ov.configs || { configs: [], current: '' };
    var ac      = ov.access || {};
    var stats   = ov.stats || {};

    if (!document.getElementById('cl-css')) {
      var s = document.createElement('style');
      s.id = 'cl-css'; s.textContent = CSS;
      document.head.appendChild(s);
    }
    if (!document.getElementById('cl-css-ext')) {
      var link = document.createElement('link');
      link.id = 'cl-css-ext';
      link.rel = 'stylesheet';
      link.href = L.resource('view/clashoo/clashoo.css') + '?v=20260425b1';
      document.head.appendChild(link);
    } else {
      document.getElementById('cl-css-ext').href = L.resource('view/clashoo/clashoo.css') + '?v=20260425b1';
    }

    this._lastSt      = st;
    this._lastCfgData = cfgData;
    this._lastAc      = ac;
    this._overviewLoaded = false;

    var root = E('div', { 'class': 'cl-wrap clashoo-container cl-overview-page' }, [
      E('div', { 'class': 'cl-cards', id: 'cl-cards' }, this._cards(st, cfgData, ac)),
      E('div', { 'class': 'cl-traffic-wrap', id: 'cl-traffic-wrap' }, [
        this._card('流量监控', this._renderRealtimePanel(), 'cl-card-traffic')
      ]),
      E('div', { 'class': 'cl-controls', id: 'cl-controls' }, this._controls(st, cfgData))
    ]);
    this._rootEl = root;
    this._applyThemeClass();
    this._observeThemeChanges();
    this._updateRealtimePanel(stats);
    this._loadUciInBackground();

    poll.add(L.bind(this._pollOverview, this), 5);
    this._pollOverview();

    return root;
  },

  _loadUciInBackground: function () {
    var self = this;
    setTimeout(function () {
      L.resolveDefault(uci.load('clashoo'), null).then(function () {
        if (self._overviewLoaded || !self._rootEl)
          return;
        var ov = self._initialOverview();
        self._lastCfgData = ov.configs || { configs: [], current: '' };

        var controls = document.getElementById('cl-controls');
        if (controls) {
          controls.innerHTML = '';
          self._controls(self._lastSt || ov.status || {}, self._lastCfgData).forEach(function (ctrl) {
            controls.appendChild(ctrl);
          });
        }
      });
    }, 0);
  },

  _applyThemeClass: function () {
    if (!this._rootEl || !this._rootEl.classList)
      return;
    var dark = this._isDarkUi();
    this._rootEl.classList.toggle('cl-theme-dark', !!dark);
    this._rootEl.classList.toggle('cl-theme-light', !dark);
  },

  _observeThemeChanges: function () {
    var self = this;
    if (self._themeObserver) {
      try { self._themeObserver.disconnect(); } catch (e0) {}
      self._themeObserver = null;
    }
    if (self._themeMedia && self._themeMediaHandler) {
      try {
        if (self._themeMedia.removeEventListener)
          self._themeMedia.removeEventListener('change', self._themeMediaHandler);
        else if (self._themeMedia.removeListener)
          self._themeMedia.removeListener(self._themeMediaHandler);
      } catch (e00) {}
      self._themeMedia = null;
      self._themeMediaHandler = null;
    }
    if (typeof MutationObserver === 'undefined')
      return self._applyThemeClass();

    var obs = new MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) {
        var a = mutations[i] && mutations[i].attributeName;
        if (!a)
          continue;
        if (a === 'class' || a === 'data-theme' || a === 'data-bs-theme' || a === 'data-darkmode') {
          self._applyThemeClass();
          break;
        }
      }
    });

    var opt = { attributes: true, attributeFilter: ['class', 'data-theme', 'data-bs-theme', 'data-darkmode'] };
    try { obs.observe(document.documentElement, opt); } catch (e1) {}
    if (document.body) {
      try { obs.observe(document.body, opt); } catch (e2) {}
    }
    self._themeObserver = obs;

    if (window.matchMedia) {
      var mq = window.matchMedia('(prefers-color-scheme: dark)');
      var handler = function () { self._applyThemeClass(); };
      try {
        if (mq.addEventListener)
          mq.addEventListener('change', handler);
        else if (mq.addListener)
          mq.addListener(handler);
      } catch (e3) {}
      self._themeMedia = mq;
      self._themeMediaHandler = handler;
    }

    self._applyThemeClass();
  },

  _isDarkUi: function () {
    var docEl = document.documentElement || {};
    var body  = document.body || {};
    var theme = String(
      (docEl.getAttribute && (docEl.getAttribute('data-theme') || docEl.getAttribute('data-bs-theme'))) ||
      (body.getAttribute && (body.getAttribute('data-theme') || body.getAttribute('data-bs-theme'))) ||
      ''
    ).toLowerCase();
    var darkMode = String(
      (docEl.getAttribute && docEl.getAttribute('data-darkmode')) ||
      (body.getAttribute && body.getAttribute('data-darkmode')) ||
      ''
    ).toLowerCase();

    if (theme === 'dark' || darkMode === '1' || darkMode === 'true')
      return true;
    if (theme === 'light' || darkMode === '0' || darkMode === 'false')
      return false;

    var cls = String((docEl.className || '') + ' ' + (body.className || '')).toLowerCase();
    if (/(^|\s)(dark|theme-dark|darkmode)(\s|$)/.test(cls))
      return true;
    if (/(^|\s)(light|theme-light)(\s|$)/.test(cls))
      return false;

    /* Fallback: inspect sidebar brightness for themes that don't expose standard attrs */
    try {
      var byLuminance = function (node) {
        if (!node)
          return null;
        var bg = window.getComputedStyle(node).backgroundColor || '';
        var rgb = String(bg).match(/\d+/g);
        if (rgb && rgb.length >= 3) {
          var sum = (parseInt(rgb[0], 10) || 0) +
                    (parseInt(rgb[1], 10) || 0) +
                    (parseInt(rgb[2], 10) || 0);
          return sum < 380;
        }
        return null;
      };

      var sidebar = document.querySelector('.main-sidebar, .main-left, .sidebar, #mainmenu, #menubar, .left');
      var darkFromSidebar = byLuminance(sidebar);
      if (darkFromSidebar != null)
        return darkFromSidebar;

      var darkFromBody = byLuminance(body);
      if (darkFromBody != null)
        return darkFromBody;
    } catch (e) {}

    if (window.matchMedia)
      return !!window.matchMedia('(prefers-color-scheme: dark)').matches;

    return false;
  },

  _coreLabel: function (family, channel) {
    if (!family)
      return '未运行';
    var f = family === 'singbox' ? 'sing-box' : 'mihomo';
    var c = channel === 'smart' ? 'Smart 版' : channel === 'alpha' ? 'Alpha 版' : '稳定版';
    return f + ' ' + c;
  },

  _configuredChannel: function (family, st) {
    var dcore = (st && st.dcore) || uci.get('clashoo', 'config', 'dcore') || '2';
    if (family === 'singbox')
      return dcore === '5' ? 'alpha' : 'stable';
    if (dcore === '1') return 'smart';
    return dcore === '3' ? 'alpha' : 'stable';
  },

  _currentCoreType: function (st) {
    return (st && st.core_type) || uci.get('clashoo', 'config', 'core_type') || 'mihomo';
  },

  _effectiveCore: function (st) {
    var family = this._currentCoreType(st);
    if (family === 'singbox') return 'singbox';
    /* 优先用 ubus status 实时返回的 dcore，避免 uci.get LuCI 缓存切换后滞后 */
    var dcore = (st && st.dcore) || uci.get('clashoo', 'config', 'dcore') || '2';
    return dcore === '1' ? 'smart' : 'mihomo';
  },

  _refreshCoreSwitch: function () {
    var wrap = document.getElementById('cl-core-switch-inline-wrap');
    if (!wrap) return;
    wrap.innerHTML = '';
    wrap.appendChild(this._renderCoreSwitch(this._lastSt || {}));
  },

  _showCoreSwitchHint: function (msg) {
    var self = this;
    self._coreSwitchMsg = msg;
    self._refreshCoreSwitch();
    setTimeout(function () {
      if (self._coreSwitchMsg === msg) {
        self._coreSwitchMsg = '';
        self._refreshCoreSwitch();
      }
    }, 3500);
  },

  _switchCore: function (targetCore) {
    var self = this;
    if (self._coreSwitchBusy)
      return Promise.resolve();

    if (targetCore === 'smart' && self._lastSt && self._lastSt.has_smart === false) {
      self._showCoreSwitchHint('未检测到 Smart 内核；更新模型不会安装内核，请到系统页下载 Smart 版');
      return Promise.resolve();
    }

    var currentEffective = self._effectiveCore(self._lastSt || {});
    if (targetCore === currentEffective)
      return Promise.resolve();

    var currentDcore = (self._lastSt && self._lastSt.dcore) || uci.get('clashoo', 'config', 'dcore') || '2';
    var rpcCore, nextDcore, targetLabel;
    if (targetCore === 'smart') {
      rpcCore = 'mihomo'; nextDcore = '1'; targetLabel = 'Smart';
    } else if (targetCore === 'singbox') {
      rpcCore = 'singbox'; nextDcore = currentDcore === '5' ? '5' : '4'; targetLabel = 'sing-box';
    } else {
      rpcCore = 'mihomo'; nextDcore = currentDcore === '3' ? '3' : '2'; targetLabel = 'mihomo';
    }

    self._coreSwitchBusy = true;
    self._coreSwitchMsg = '正在切换到 ' + targetLabel + '...';
    self._refreshCoreSwitch();

    return clashoo.setCore(rpcCore, nextDcore)
      .then(function (r) {
        if (r && r.success === false && r.error === 'smart_core_missing') {
          self._showCoreSwitchHint('未检测到 Smart 内核；更新模型不会安装内核，请到系统页下载 Smart 版');
          throw { soft: true };
        }
        if (r && r.success === false && r.error === 'singbox_core_missing') {
          self._showCoreSwitchHint('未检测到 sing-box 内核；请到系统页下载 sing-box');
          throw { soft: true };
        }
        if (r && r.success === false)
          throw new Error(r.message || '切换内核失败');
        self._lastSt = self._lastSt || {};
        self._lastSt.core_type = rpcCore;
        self._lastSt.dcore = nextDcore;          /* 乐观更新，避免重绘前 uci 缓存滞后 */
        self._lastSt.running = false;
        self._lastSt.health_status = 'stopped';
      })
      .then(function () {
        /* 切到 Smart 时后端 set_core 已自动开启 smart_auto_switch；启动后 init.d
         * smart_inject 会把 url-test/load-balance 转成 Smart 策略，无需手动操作。 */
        self._coreSwitchMsg = '已切换到 ' + targetLabel + '，点击启动后生效';
        self._refreshCoreSwitch();
        return new Promise(function (resolve) { setTimeout(resolve, 500); });
      })
      .then(function () { return self._pollStatus(); })
      .then(function () {
        var msg = targetCore === 'smart'
          ? '已切换 Smart 内核，Smart 策略已自动启用。点击启动即可生效。'
          : '内核已切换：' + targetLabel + '。需要代理时请点击启动。';
        ui.addNotification(null, E('p', msg));
      })
      .catch(function (e) {
        if (e && e.soft)
          return;
        self._coreSwitchMsg = '切换失败';
        ui.addNotification(null, E('p', '切换失败: ' + (e.message || e)));
      })
      .then(function () {
        self._coreSwitchBusy = false;
        setTimeout(function () {
          self._coreSwitchMsg = '';
          self._refreshCoreSwitch();
        }, 900);
      });
  },

  _renderCoreSwitch: function (st) {
    var self = this;
    var effective = this._effectiveCore(st);
    var note = this._coreSwitchMsg || '';

    var mkBtn = function (core, label) {
      var active = core === effective;
      var missingSmart = core === 'smart' && st && st.has_smart === false;
      return E('button', {
        type: 'button',
        title: missingSmart ? '未检测到 Smart 内核；更新模型不会安装内核' : null,
        'class': 'cl-core-btn' + (active ? ' active' : ''),
        disabled: self._coreSwitchBusy ? '' : null,
        click: function (ev) {
          ev.preventDefault();
          self._switchCore(core);
        }
      }, label);
    };

    var children = [
      E('div', {
        'class': 'cl-status-kernel' + (this._coreSwitchBusy ? ' is-busy' : ''),
        title: note || null
      }, [
        mkBtn('mihomo', 'Mihomo'),
        mkBtn('smart', 'Smart'),
        mkBtn('singbox', 'Sing-box')
      ])
    ];
    if (note)
      children.push(E('div', { 'class': 'cl-core-switch-hint' }, note));

    return E('div', { 'class': 'cl-core-switch-wrap' }, children);
  },

  _proxyModeLabel: function (mode) {
    var map = { rule: '规则', global: '全局', direct: '直连' };
    return map[mode] || mode || '—';
  },

  _panelLabel: function (name) {
    var map = {
      metacubexd: 'MetaCubeXD',
      yacd: 'YACD',
      zashboard: 'Zashboard',
      razord: 'Razord'
    };
    return map[name] || name || '面板';
  },

  _renderServiceSwitch: function (st) {
    var self = this;
    var known = st && typeof st.running === 'boolean';
    var running = known && st.running === true;
    var disabled = this._busy || !known || this._coreSwitchBusy;
    return E('div', { 'class': 'cl-service-tools' }, [
      E('span', { 'class': 'cl-service-label' }, '启用服务'),
      E('button', {
        type: 'button',
        title: !known ? '正在同步运行状态' : (running ? '停止服务' : '启动服务'),
        'aria-pressed': running ? 'true' : 'false',
        'class': 'cl-service-switch' + (running ? ' is-on' : ' is-off'),
        disabled: disabled ? '' : null,
        click: function (ev) {
          ev.preventDefault();
          if (disabled) return;
          return running ? self._stop() : self._start();
        }
      }, [E('span', { 'class': 'cl-service-knob' })])
    ]);
  },

  _cards: function (st, cfgData, ac) {
    var statusKnown = st && typeof st.running === 'boolean';
    var running = statusKnown && st.running === true;
    var health = st.health_status || 'unknown';
    var configuredCoreLabel = this._coreLabel(st.core_type, this._configuredChannel(st.core_type, st));

    var statusChildren = [
      !statusKnown
        ? E('span', { 'class': 'cl-status-state cl-status-state-sync' }, '同步中')
        : running
        ? E('span', { 'class': 'cl-status-state cl-status-state-run' }, '运行中 🟢')
        : E('span', { 'class': 'cl-status-state cl-status-state-stop' }, '已停止 ⚪'),
      E('span', { 'class': 'cl-status-note cl-status-note-core' }, configuredCoreLabel)
    ];
    if (st.runtime_degraded)
      statusChildren.push(E('span', { 'class': 'cl-status-note cl-status-note-degraded' }, '已降级运行'));
    if (running && health === 'fail')
      statusChildren.push(E('span', { 'class': 'cl-status-note cl-status-note-fail' }, '健康检查失败'));
    else if (running && health === 'pass')
      statusChildren.push(E('span', { 'class': 'cl-status-note cl-status-note-pass' }, '健康检查通过'));
    var statusEl = E('span', { id: 'cl-status-val' }, statusChildren);

    return [
      this._card('运行状态', statusEl, 'cl-card-status', this._renderServiceSwitch(st)),
      this._card('内核切换',
        E('div', { id: 'cl-core-switch-inline-wrap' }, [
          this._renderCoreSwitch(st)
        ]),
        'cl-card-kernel'
      ),
      this._card('透明代理', this._renderTpMode(st), 'cl-card-mode'),
      this._card('访问检查', this._renderCheckStatus(st, ac), 'cl-card-access', this._renderAccessRefresh(ac))
    ];
  },

  /* Directly update the status card content without rebuilding all cards */
  _showOpMsg: function (msg) {
    var el = document.getElementById('cl-status-val');
    if (!el) return;
    el.innerHTML = '';
    el.appendChild(E('span', { 'class': 'cl-op-msg' }, msg));
  },

  /* Schedule message animation: space messages evenly over (totalMs - tailMs) */
  _startMsgAnim: function (messages, totalMs) {
    var self = this;
    var tailMs  = 2500;                            /* last message stays visible for tailMs before poll */
    var spanMs  = Math.max(totalMs - tailMs, 1000);
    var stepMs  = messages.length > 1 ? Math.floor(spanMs / (messages.length - 1)) : spanMs;
    self._opTimers = [];
    messages.forEach(function (msg, i) {
      var t = setTimeout(function () {
        self._showOpMsg(msg);
      }, i * stepMs);
      self._opTimers.push(t);
    });
  },

  _clearOpTimers: function () {
    if (this._opTimers) {
      this._opTimers.forEach(function (t) { clearTimeout(t); });
      this._opTimers = null;
    }
  },

  _tpModeName: function (mode) {
    var m = String(mode || '').toLowerCase();
    var map = {
      redirect: 'Redirect',
      redir: 'Redirect',
      tproxy: 'TProxy',
      tun: 'TUN',
      off: '关闭'
    };
    if (map[m]) return map[m];
    if (!mode) return '—';
    return String(mode);
  },

  _stackLabel: function (stack) {
    var s = String(stack || '').toLowerCase();
    var map = { gvisor: 'gVisor', system: 'System', mixed: 'Mixed' };
    return map[s] || (stack ? String(stack) : 'System');
  },

  _tpModeRows: function (st) {
    var tcpRaw = st.tcp_node || st.effective_tcp_mode || st.tcp_mode || uci.get('clashoo', 'config', 'tcp_mode') || 'off';
    var udpRaw = st.udp_node || st.effective_udp_mode || st.udp_mode || uci.get('clashoo', 'config', 'udp_mode') || tcpRaw;
    var stackRaw = st.stack_type || st.stack || uci.get('clashoo', 'config', 'stack') || 'system';

    return {
      rows: [
        { proto: 'TCP', mode: this._tpModeName(tcpRaw), suffix: String(tcpRaw).toLowerCase() === 'off' ? '' : '模式' },
        { proto: 'UDP', mode: this._tpModeName(udpRaw), suffix: String(udpRaw).toLowerCase() === 'off' ? '' : '模式' }
      ],
      stack: this._stackLabel(stackRaw)
    };
  },

  _isTpModeDegraded: function (st) {
    if (!st)
      return false;

    if (st.runtime_degraded)
      return true;

    var tcp = String(st.tcp_mode || uci.get('clashoo', 'config', 'tcp_mode') || '').toLowerCase();
    var udp = String(st.udp_mode || uci.get('clashoo', 'config', 'udp_mode') || tcp).toLowerCase();
    var stack = String(st.stack || uci.get('clashoo', 'config', 'stack') || '').toLowerCase();
    var wantsTun = tcp === 'tun' || udp === 'tun' || stack === 'mixed';
    return wantsTun && String(st.has_tun_device) === '0';
  },

  _renderTpMode: function (st) {
    var data = this._tpModeRows(st);
    var rows = data.rows.map(function (row) {
      return E('div', { 'class': 'cl-mode-row' }, [
        E('span', { 'class': 'cl-mode-proto' }, row.proto),
        E('span', { 'class': 'cl-mode-name' }, row.mode),
        E('span', { 'class': 'cl-mode-suffix' }, row.suffix)
      ]);
    });
    rows.push(
      E('div', { 'class': 'cl-mode-row cl-mode-row-stack' }, [
        E('span', { 'class': 'cl-mode-proto' }, '网络栈'),
        E('span', { 'class': 'cl-mode-name' }, data.stack),
        E('span', { 'class': 'cl-mode-suffix' }, '模式')
      ])
    );
    if (this._isTpModeDegraded(st))
      rows.push(E('div', { 'class': 'cl-check-updated cl-mode-degraded' }, '降级运行'));

    return E('div', { id: 'cl-tpmode', 'class': 'cl-mode-stack' }, rows);
  },

  _renderAccessRefresh: function (ac) {
    var self = this;
    var loading = !!(this._accessRefreshing || (ac && ac.updating));
    return E('button', {
      type: 'button',
      id: 'cl-access-refresh',
      title: '刷新访问检查',
      'class': 'cl-icon-btn' + (loading ? ' is-loading' : ''),
      click: function (ev) {
        ev.preventDefault();
        ev.stopPropagation();
        self._manualRefreshAccess();
      }
    }, '↻');
  },

  _card: function (lbl, val, extraCls, tool) {
    var head = [
      E('div', { 'class': 'lbl' }, lbl)
    ];
    if (tool)
      head.push(E('div', { 'class': 'cl-card-tools' }, [tool]));

    return E('div', { 'class': 'cl-card' + (extraCls ? (' ' + extraCls) : '') }, [
      E('div', { 'class': 'cl-card-head' }, head),
      E('div', { 'class': 'val' }, [val])
    ]);
  },

  _toInt: function (v) {
    var n = parseInt(v, 10);
    return isFinite(n) && n > 0 ? n : 0;
  },

  _fmtRate: function (bytes) {
    var b = this._toInt(bytes);
    if (b >= 1024 * 1024)
      return { value: (b / (1024 * 1024)).toFixed(2), unit: 'MB/s' };
    if (b >= 1024)
      return { value: (b / 1024).toFixed(2), unit: 'kB/s' };
    return { value: '' + b, unit: 'B/s' };
  },

  _fmtBytes: function (bytes) {
    var b = this._toInt(bytes);
    if (b >= 1024 * 1024 * 1024)
      return (b / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    if (b >= 1024 * 1024)
      return (b / (1024 * 1024)).toFixed(0) + ' MB';
    if (b >= 1024)
      return (b / 1024).toFixed(0) + ' KB';
    return b + ' B';
  },

  _fmtMiB: function (bytes) {
    var b = this._toInt(bytes);
    return (b / (1024 * 1024)).toFixed(0) + ' MiB';
  },

  _initRealtimeHistory: function () {
    if (!this._rtHistory) {
      this._rtHistory = { up: [], down: [], conn: [] };
    }
  },

  _pushRealtimeSample: function (key, value) {
    this._initRealtimeHistory();
    var hist = this._rtHistory[key] || (this._rtHistory[key] = []);
    hist.push(this._toInt(value));
    if (hist.length > 36)
      hist.shift();
    return hist;
  },

  _smoothPath: function (pts) {
    if (!pts || !pts.length)
      return '';
    if (pts.length === 1)
      return 'M ' + pts[0].x.toFixed(1) + ' ' + pts[0].y.toFixed(1);

    var d = 'M ' + pts[0].x.toFixed(1) + ' ' + pts[0].y.toFixed(1);
    for (var i = 0; i < pts.length - 1; i++) {
      var p0 = i > 0 ? pts[i - 1] : pts[i];
      var p1 = pts[i];
      var p2 = pts[i + 1];
      var p3 = (i !== pts.length - 2) ? pts[i + 2] : p2;

      var cp1x = p1.x + (p2.x - p0.x) / 6;
      var cp1y = p1.y + (p2.y - p0.y) / 6;
      var cp2x = p2.x - (p3.x - p1.x) / 6;
      var cp2y = p2.y - (p3.y - p1.y) / 6;

      d += ' C ' +
        cp1x.toFixed(1) + ' ' + cp1y.toFixed(1) + ', ' +
        cp2x.toFixed(1) + ' ' + cp2y.toFixed(1) + ', ' +
        p2.x.toFixed(1) + ' ' + p2.y.toFixed(1);
    }
    return d;
  },

  _renderSparkline: function (points, tone) {
    var w = 260, h = 42;
    var vals = (points && points.length) ? points.slice() : [0];
    if (vals.length < 2)
      vals.push(vals[0]);

    var max = 1;
    for (var i = 0; i < vals.length; i++) {
      if (vals[i] > max)
        max = vals[i];
    }

    var n = vals.length;
    var pts = [];
    for (var j = 0; j < n; j++) {
      var x = n === 1 ? 0 : (j * w / (n - 1));
      var y = h - ((vals[j] / max) * (h - 2)) - 1;
      pts.push({ x: x, y: y });
    }

    var linePath = this._smoothPath(pts);
    var areaPath = linePath + ' L ' + w.toFixed(1) + ' ' + h + ' L 0 ' + h + ' Z';

    return E('svg', { 'class': 'cl-live-svg', viewBox: '0 0 ' + w + ' ' + h, preserveAspectRatio: 'none' }, [
      E('path', { 'class': 'cl-live-area ' + tone, d: areaPath }),
      E('path', { 'class': 'cl-live-line ' + tone, d: linePath })
    ]);
  },

  _renderRealtimeCard: function (name, title) {
    var mainId = 'cl-live-' + name + '-main';
    var unitId = 'cl-live-' + name + '-unit';
    var footId = 'cl-live-' + name + '-foot';
    var chartId = 'cl-live-' + name + '-chart';
    var titleChildren = [title];

    return E('div', { 'class': 'cl-live-card cl-stat-card cl-live-card-' + name + ' is-zero', id: 'cl-live-' + name + '-card' }, [
      E('div', { 'class': 'cl-live-bg-chart', id: chartId }, [this._renderSparkline([0, 0], name)]),
      E('div', { 'class': 'cl-live-content' }, [
        E('div', { 'class': 'cl-live-title' }, titleChildren),
        E('div', { 'class': 'cl-live-main' }, [
          E('span', { 'class': 'cl-live-num', id: mainId }, '0'),
          E('span', { 'class': 'cl-live-unit', id: unitId }, name === 'conn' ? '' : 'B/s')
        ]),
        E('div', { 'class': 'cl-live-foot', id: footId }, '等待数据...')
      ])
    ]);
  },

  _renderRealtimePanel: function () {
    this._initRealtimeHistory();
    return E('div', { 'class': 'cl-live-box' }, [
      E('div', { 'class': 'cl-live-grid' }, [
        this._renderRealtimeCard('up', '上传'),
        this._renderRealtimeCard('down', '下载'),
        this._renderRealtimeCard('conn', '连接')
      ])
    ]);
  },

  _setLiveCardState: function (name, value, hotThreshold, online) {
    var card = document.getElementById('cl-live-' + name + '-card');
    if (!card) return;
    var cls = 'cl-live-card cl-stat-card cl-live-card-' + name;
    if (name === 'conn' && !online)
      cls += ' is-offline';
    if (value > 0)
      cls += ' is-active';
    else
      cls += ' is-zero';
    if (value >= hotThreshold)
      cls += ' is-hot';
    card.className = cls;
  },

  _updateRealtimePanel: function (raw) {
    var st = raw || {};
    var up = this._toInt(st.up);
    var down = this._toInt(st.down);
    var upTotal = this._toInt(st.up_total);
    var downTotal = this._toInt(st.down_total);
    var conn = this._toInt(st.connections);
    var mem = this._toInt(st.memory_inuse);
    var online = !!(st.ok && st.running);

    var upRate = this._fmtRate(up);
    var downRate = this._fmtRate(down);
    var upHist = this._pushRealtimeSample('up', up);
    var downHist = this._pushRealtimeSample('down', down);
    var connHist = this._pushRealtimeSample('conn', conn);

    var setText = function (id, text) {
      var el = document.getElementById(id);
      if (el) el.textContent = text;
    };
    var setChart = L.bind(function (id, points, tone) {
      var box = document.getElementById(id);
      if (!box) return;
      box.innerHTML = '';
      box.appendChild(this._renderSparkline(points, tone));
    }, this);

    setText('cl-live-up-main', upRate.value);
    setText('cl-live-up-unit', upRate.unit);
    setText('cl-live-up-foot', '总计 ' + this._fmtBytes(upTotal));
    setChart('cl-live-up-chart', upHist, 'up');

    setText('cl-live-down-main', downRate.value);
    setText('cl-live-down-unit', downRate.unit);
    setText('cl-live-down-foot', '总计 ' + this._fmtBytes(downTotal));
    setChart('cl-live-down-chart', downHist, 'down');

    setText('cl-live-conn-main', '' + conn);
    setText('cl-live-conn-unit', '');
    setText('cl-live-conn-foot', '内存使用 ' + this._fmtMiB(mem));
    setChart('cl-live-conn-chart', connHist, 'conn');

    this._setLiveCardState('up', up, 512 * 1024, online);
    this._setLiveCardState('down', down, 1024 * 1024, online);
    this._setLiveCardState('conn', conn, 80, online);

  },

  _probeLabel: function (key, probe) {
    if (probe && probe.name) return String(probe.name);
    if (probe && probe.title) return String(probe.title);
    if (probe && probe.site) return String(probe.site);
    var map = {
      baidu: 'Baidu',
      google: 'Google',
      github: 'GitHub',
      youtube: 'YouTube',
      bytedance: '字节跳动',
      cloudflare: 'Cloudflare',
      bilibili: 'Bilibili',
      taobao: 'Taobao'
    };
    var k = String(key || '').toLowerCase();
    return map[k] || String(key || 'Unknown');
  },

  _probeIcon: function (key, probe) {
    if (probe && probe.icon) {
      if (/^(https?:)?\//.test(probe.icon))
        return probe.icon;
      return L.resource('view/clashoo/' + probe.icon);
    }
    var map = {
      baidu: 'baidu.svg',
      google: 'google.svg',
      github: 'github.svg',
      youtube: 'youtube.svg',
      bytedance: 'bytedance.svg',
      cloudflare: 'cloudflare.svg',
      bilibili: 'bilibili.svg',
      taobao: 'taobao.svg'
    };
    var k = String(key || '').toLowerCase();
    return map[k] ? (L.resource('view/clashoo/' + map[k]) + '?v=20260421p') : null;
  },

  _probeGrade: function (probe) {
    var ms = probe && probe.avg_ms != null ? parseInt(probe.avg_ms, 10) :
      (probe && probe.ms != null ? parseInt(probe.ms, 10) :
      (probe && probe.latency != null ? parseInt(probe.latency, 10) : NaN));
    var ok = !!(probe && (probe.ok === true || probe.state === 'ok' || probe.state === 'high_latency' || probe.state === 'loss'));
    if (!ok || !isFinite(ms))
      return {
        tone: 'red',
        bars: 1,
        text: (probe && probe.code && probe.code !== '000') ? 'Offline' : 'Timeout',
        offline: true
      };

    if (ms <= 400)
      return { tone: 'green', bars: 4, text: ms + 'ms' };
    if (ms <= 800)
      return { tone: 'warn', bars: 3, text: ms + 'ms' };
    return { tone: 'red', bars: 2, text: ms + 'ms' };
  },

  _renderSignalBars: function (grade) {
    var bars = [];
    for (var i = 0; i < 4; i++) {
      bars.push(E('i', { 'class': i < grade.bars ? 'active' : '' }));
    }
    var cls = 'cl-signal cl-signal-' + grade.tone + (grade.offline ? ' cl-signal-offline' : '');
    return E('span', { 'class': cls }, bars);
  },

  _renderProbeIcon: function (icon, label) {
    var wrap = E('span', { 'class': 'cl-check-icon-wrap' });
    if (!icon) {
      wrap.appendChild(E('span', { 'class': 'cl-check-icon-fallback' }, (label || '?').charAt(0).toUpperCase()));
      return wrap;
    }
    wrap.appendChild(E('img', {
      'class': 'cl-check-icon',
      src: icon,
      alt: label,
      error: function (ev) {
        var fb = E('span', { 'class': 'cl-check-icon-fallback' }, (label || '?').charAt(0).toUpperCase());
        if (ev.target && ev.target.parentNode)
          ev.target.parentNode.replaceChild(fb, ev.target);
      }
    }));
    return wrap;
  },

  _normalizeCheckItems: function (ac) {
    if (!ac) return [];
    if ((parseInt(ac.updated_at || '0', 10) || 0) <= 0 && ac.updating)
      return [];
    var self = this;

    var normalizeItems = function (source) {
      if (!source) return [];

      if (Array.isArray(source)) {
        return source.map(function (item, idx) {
          var key = item.key || item.name || item.title || item.site || ('item_' + idx);
          return {
            key: key,
            label: self._probeLabel(key, item),
            icon: self._probeIcon(key, item),
            probe: item
          };
        });
      }

      var preferred = ['bytedance', 'youtube', 'google', 'github', 'baidu', 'cloudflare'];
      var keys = Object.keys(source);
      keys.sort(function (a, b) {
        var ia = preferred.indexOf(a), ib = preferred.indexOf(b);
        if (ia !== -1 || ib !== -1) {
          if (ia === -1) return 1;
          if (ib === -1) return -1;
          return ia - ib;
        }
        return a.localeCompare(b);
      });

      return keys.map(function (key) {
        var probe = source[key] || {};
        return {
          key: key,
          label: self._probeLabel(key, probe),
          icon: self._probeIcon(key, probe),
          probe: probe
        };
      });
    };

    if (Array.isArray(ac.items) && ac.items.length)
      return normalizeItems(ac.items);
    if (ac.proxy)
      return normalizeItems(ac.proxy);
    if (ac.direct)
      return normalizeItems(ac.direct);
    return [];
  },

  _renderCheckItem: function (item) {
    var grade = this._probeGrade(item.probe || {});
    return E('div', { 'class': 'cl-check-item' }, [
      E('div', { 'class': 'cl-check-main' }, [
        this._renderProbeIcon(item.icon, item.label),
        E('span', { 'class': 'cl-check-name site-name' }, item.label)
      ]),
      E('span', { 'class': 'cl-check-latency latency-val cl-lat-' + grade.tone }, grade.text),
      this._renderSignalBars(grade)
    ]);
  },

  _timeAgoText: function (ts) {
    var now = Math.floor(Date.now() / 1000);
    var delta = now - (parseInt(ts, 10) || 0);
    if (!isFinite(delta) || delta < 0) delta = 0;
    if (delta < 5) return '刚刚';
    if (delta < 60) return delta + ' 秒前';
    if (delta < 3600) return Math.floor(delta / 60) + ' 分钟前';
    return Math.floor(delta / 3600) + ' 小时前';
  },

  _renderCheckUpdated: function (ac) {
    if (!ac) return null;
    var updatedAt = parseInt(ac.updated_at || '0', 10) || 0;
    if (updatedAt <= 0) {
      return E('div', { 'class': 'cl-check-updated' }, '上次检查：初始化中');
    }
    var msg = '上次检查：' + this._timeAgoText(updatedAt);
    if (ac.updating && this._accessRefreshing)
      msg += '（刷新中）';
    return E('div', { 'class': 'cl-check-updated' }, msg);
  },

  _renderCheckSkeleton: function () {
    return E('div', { 'class': 'cl-check-skeleton' }, [
      E('div', { 'class': 'cl-skel-row' }, [
        E('span', { 'class': 'cl-skel-icon' }),
        E('span', { 'class': 'cl-skel-line' }),
        E('span', { 'class': 'cl-skel-line short' })
      ]),
      E('div', { 'class': 'cl-skel-row' }, [
        E('span', { 'class': 'cl-skel-icon' }),
        E('span', { 'class': 'cl-skel-line' }),
        E('span', { 'class': 'cl-skel-line short' })
      ]),
      E('div', { 'class': 'cl-check-updated' }, '上次检查：初始化中')
    ]);
  },

  _renderCheckStatus: function (st, ac) {
    var items = this._normalizeCheckItems(ac);
    if (!items.length) {
      return this._renderCheckSkeleton();
    }

    var self = this;
    var children = items.map(function (item) {
      return self._renderCheckItem(item);
    });
    var updated = this._renderCheckUpdated(ac);
    if (updated) children.push(updated);
    return E('div', { 'class': 'cl-check-modern' }, children);
  },

  _controls: function (st, cfgData) {
    var self = this;
    var configs   = (cfgData && cfgData.configs) ? cfgData.configs : [];
    var current   = (cfgData && cfgData.current) || '';
    var proxyMode = st.proxy_mode  || 'rule';
    var stackMode = st.stack || '';
    var tunLike   = (st.tcp_mode === 'tun' || st.udp_mode === 'tun');
    var tpMode    = 'fake-ip';

    if (tunLike && stackMode === 'mixed')
      tpMode = 'mixed';
    else if (tunLike)
      tpMode = 'tun';
    var panelType = st.panel_type  || 'zashboard';
    var panelUrl  = this._dashboardUrl(st);
    var panels    = ['metacubexd', 'yacd', 'zashboard', 'razord'];

    var mkSel = function (opts, val, fn) {
      return E('select', { 'class': 'cbi-input-select', change: fn },
        opts.map(function (o) {
          return E('option', { value: o[0], selected: o[0] === val ? '' : null }, o[1]);
        }));
    };

    var panelSel = mkSel(panels.map(function (p) {
      return [p, self._panelLabel(p)];
    }), panelType, function (ev) {
      var next = ev.target.value;
      var prev = panelType;
      ev.target.disabled = true;
      self._lastSt = self._lastSt || {};
      self._lastSt.panel_type = next;
      clashoo.setPanel(next).then(function (r) {
        if (r && r.error)
          throw new Error(r.error);
        return self._pollOverview(true);
      }).catch(function (e) {
        self._lastSt.panel_type = prev;
        ev.target.value = prev;
        ui.addNotification(null, E('p', '面板切换失败: ' + (e.message || e)));
      }).then(function () {
        ev.target.disabled = false;
      });
    });

    return [
      E('div', { 'class': 'cl-ctrl' }, [
        E('label', {}, '代理模式'),
        mkSel([['rule','规则'],['global','全局'],['direct','直连']], proxyMode,
          function (ev) { clashoo.setProxyMode(ev.target.value); })
      ]),
      E('div', { 'class': 'cl-ctrl' }, [
        E('label', {}, '运行模式'),
        mkSel([['fake-ip','Fake-IP'],['tun','TUN 模式'],['mixed','Mixed 模式']], tpMode,
          function (ev) {
            var mode = ev.target.value;
            ev.target.disabled = true;
            self._op = 'mode';
            self._lastSt = self._lastSt || {};
            if (mode === 'mixed') {
              self._lastSt.tcp_mode = 'tun';
              self._lastSt.udp_mode = 'tun';
              self._lastSt.stack = 'mixed';
            } else if (mode === 'tun') {
              self._lastSt.tcp_mode = 'tun';
              self._lastSt.udp_mode = 'tun';
              self._lastSt.stack = 'system';
            } else {
              self._lastSt.tcp_mode = 'redirect';
              self._lastSt.udp_mode = 'tproxy';
              self._lastSt.stack = 'gvisor';
            }
            clashoo.setMode(mode).then(function (r) {
              if (r && r.error)
                ui.addNotification(null, E('p', '运行模式设置失败: ' + r.error));
              return self._pollOverview(true);
            }).catch(function (e) {
              ui.addNotification(null, E('p', '运行模式设置失败: ' + (e.message || e)));
            }).then(function () {
              self._op = null;
              ev.target.disabled = false;
            });
          })
      ]),
      E('div', { 'class': 'cl-ctrl' }, [
        E('label', {}, '配置文件'),
        E('div', { 'class': 'cl-ctrl-row cl-config-row' }, [
          mkSel(configs.length ? configs.map(function(c){return[c,c];}) : [['','（空）']], current,
            function (ev) {
              var sel = ev.target;
              var name = sel.value;
              var prev = sel.getAttribute('data-cl-prev') || current;
              sel.disabled = true;
              var setter = (st.core_type === 'singbox')
                ? clashoo.setSingboxProfile(name)
                : clashoo.setConfig(name);
              setter
                .then(function (r) {
                  if (r && r.error) {
                    ui.addNotification(null, E('p', '切换配置失败: ' + r.error));
                    sel.value = prev;
                    return;
                  }
                  sel.setAttribute('data-cl-prev', name);
                })
                .catch(function (e) {
                  ui.addNotification(null, E('p', '切换配置失败: ' + (e.message || e)));
                  sel.value = prev;
                })
                .then(function () {
                  sel.disabled = false;
                  /* 强制立即刷新一次状态，让卡片/按钮拿到新 current（重启服务期间还会再次自然 poll） */
                  return self._pollOverview(true);
                });
            }),
          E('button', {
            'class': 'btn cbi-button-action cl-btn-update-sub',
            click: L.bind(this._updSubs, this)
          }, '更新订阅')
        ])
      ]),
      E('div', { 'class': 'cl-ctrl' }, [
        E('label', {}, '管理面板'),
        E('div', { 'class': 'cl-ctrl-row' }, [
          panelSel,
          E('button', {
            'class': 'btn cbi-button cl-btn-panel-update',
            click: function () {
              var panelName = self._panelLabel(panelSel.value);
              clashoo.updatePanel(panelSel.value).then(function () {
                clashoo.toast(panelName + ' 更新任务已提交，请到系统/日志查看进度', {
                  duration: 3600
                });
              });
            }
          }, '更新'),
          E('a', {
            'class': 'btn cbi-button cl-btn-panel-open',
            href: panelUrl,
            target: '_blank',
            rel: 'noopener noreferrer',
            click: function (ev) {
              ev.preventDefault();
              window.open(self._dashboardUrl(self._lastSt || st), '_blank', 'noopener');
            }
          }, '打开面板')
        ])
      ])
    ];
  },

  _dashboardUrl: function (st) {
    st = st || {};
    var dashPort = st.dash_port ||
      uci.get('clashoo', 'config', 'dash_port') ||
      uci.get('clashoo', 'config', 'dashboard_port') ||
      '9090';
    var host = location.hostname || st.local_ip || '127.0.0.1';
    var secret = st.dash_pass ||
      uci.get('clashoo', 'config', 'dash_pass') ||
      '';
    var params = [
      ['host', host],
      ['hostname', host],
      ['port', dashPort],
      ['secret', secret]
    ].map(function (kv) {
      return encodeURIComponent(kv[0]) + '=' + encodeURIComponent(kv[1] || '');
    }).join('&');

    return 'http://' + host + ':' + dashPort + '/ui/?' + params + '#/proxies';
  },

  _pollOverview: function (force) {
    this._applyThemeClass();
    if (!force && this._op) return Promise.resolve();
    if (!force && this._coreSwitchBusy) return Promise.resolve();
    if (!force && document.hidden) return Promise.resolve();
    var self = this;
    return rpcOverview()
      .then(function (ov) {
        ov = ov || {};
        var st = ov.status || {};
        var cfgData = ov.configs || { configs: [], current: '' };
        var ac = ov.access || {};
        var stats = ov.stats || {};

        /* 服务未运行时立即把 proxy 探测项强制标 down，避免显示陈旧绿色（不等 daemon 5-20s 刷新） */
        if (!st.running && ac && ac.proxy) {
          var downProbe = { ok: false, state: 'down', code: '000', ok_count: 0, attempts: 1, loss: 1, avg_ms: 0 };
          Object.keys(ac.proxy).forEach(function (k) { ac.proxy[k] = downProbe; });
        }

        self._overviewLoaded = true;
        self._lastSt      = st;
        self._lastCfgData = cfgData;
        self._lastAc      = ac;
        self._writeCachedOverview(ov);
        self._refreshCoreSwitch();

        /* 只有用户能直接看到的字段变化时才重建 DOM——避免每 5 秒一次的"闪烁"，
           尤其是切换 tab 回到 overview 时缓存数据与首次 poll 数据通常一致 */
        var sig = JSON.stringify({
          running: st.running,
          health: st.health_status,
          proxy_mode: st.proxy_mode,
          tcp_mode: st.tcp_mode,
          udp_mode: st.udp_mode,
          config: st.config,
          core_type: st.core_type,
          panel_type: st.panel_type,
          dcore: st.dcore,
          configs: cfgData.configs || [],
          current: cfgData.current,
          ac_updated: ac.updated_at,
          ac_updating: ac.updating
        });
        var skipRebuild = (sig === self._lastRenderSig);
        self._lastRenderSig = sig;

        var cards = document.getElementById('cl-cards');
        if (!cards) return;
        if (!skipRebuild) {
          var newCards = self._cards(st, cfgData, ac);
          cards.innerHTML = '';
          newCards.forEach(function (card) { cards.appendChild(card); });

          var controls = document.getElementById('cl-controls');
          if (controls) {
            controls.innerHTML = '';
            self._controls(st, cfgData).forEach(function (ctrl) { controls.appendChild(ctrl); });
          }
        }

        self._updateRealtimePanel(stats);
      });
  },

  /* Compatibility wrapper for existing call sites */
  _pollStatus: function () {
    return this._pollOverview();
  },

  /* Slow poll for connectivity check — every 60s, network probes are expensive */
  _pollAccess: function () {
    return this._pollOverview(true);
  },

  _refreshAccessCard: function () {
    var cards = document.getElementById('cl-cards');
    if (!cards) return;
    var st = this._lastSt || {};
    var ac = this._lastAc || {};
    var newCard = this._card('访问检查', this._renderCheckStatus(st, ac), 'cl-card-access', this._renderAccessRefresh(ac));
    var oldCard = cards.querySelector('.cl-card-access');
    if (oldCard && oldCard.parentNode) {
      oldCard.parentNode.replaceChild(newCard, oldCard);
    } else {
      cards.appendChild(newCard);
    }
  },

  _manualRefreshAccess: function () {
    var self = this;
    if (self._accessRefreshing) return Promise.resolve();
    var previousUpdatedAt = parseInt((self._lastAc && self._lastAc.updated_at) || 0, 10) || 0;
    self._accessRefreshing = true;
    self._refreshAccessCard();

    var trigger = (clashoo && typeof clashoo.accessCheckRefresh === 'function')
      ? clashoo.accessCheckRefresh()
      : Promise.resolve({ success: true });

    return L.resolveDefault(trigger, { success: false })
      .then(function () {
        return self._waitAccessRefresh(previousUpdatedAt);
      })
      .catch(function () {
        return self._pollAccess();
      })
      .then(function () {
        self._accessRefreshing = false;
        self._refreshAccessCard();
      });
  },

  _waitAccessRefresh: function (previousUpdatedAt) {
    var self = this;
    var started = Date.now();
    var maxWait = 25000;

    function sleep(ms) {
      return new Promise(function (resolve) { setTimeout(resolve, ms); });
    }

    function loop() {
      return self._pollAccess().then(function () {
        var ac = self._lastAc || {};
        var updatedAt = parseInt(ac.updated_at || 0, 10) || 0;
        if (updatedAt > previousUpdatedAt && !ac.updating)
          return;
        if (!ac.updating && updatedAt > 0 && (Date.now() - started) > 2500)
          return;
        if ((Date.now() - started) >= maxWait)
          return;
        return sleep(700).then(loop);
      });
    }

    return sleep(500).then(loop);
  },

  _pollRealtime: function () {
    return this._pollOverview();
  },

  /* health_detail → 用户看得懂的中文（参考 P2-F 字典；详细状态时只在状态卡上展示） */
  _friendlyHealth: function (detail) {
    var map = {
      'boot_disabled':                    '已停止（开机不自启动）',
      'service_disabled':                 '服务已禁用',
      'service_stopped':                  '服务已停止',
      'preflight:openclash_conflict':     'OpenClash 已启用，请先停用以避免规则冲突',
      'preflight:config_missing':         '未找到配置文件，请先在「配置」页导入订阅或上传配置',
      'preflight:missing_fw4_stack':      '系统缺少 nftables 运行时',
      'preflight:core_validation_failed': '内核校验未通过，请到「系统 → 内核」检查',
      'start:core_not_running':           '内核未在 15 秒内启动（procd 自愈中）',
      'start:singbox_service_failed':     'sing-box 服务启动失败，请到「系统 → 日志」查看',
      'init':                             '初始化中…'
    };
    return map[detail] || '';
  },

  /* health_detail → 启动 / 停止 进度文字 */
  _opPhase: function (opKey, st) {
    var hd = (st && st.health_detail) || '';
    if (opKey === 'stop') {
      if (st && st.running === false) return '已停止 ✓';
      return '停止中…';
    }
    if (!st || st.running !== true) return '启动内核…';
    if (hd === 'init')                    return '检查环境…';
    if (hd.indexOf('preflight:') === 0)   return '检查环境…';
    if (hd.indexOf('start:') === 0)       return this._friendlyHealth(hd) || '启动内核…';
    if (st.health_status === 'pass')      return '已就绪 ✓';
    if (st.health_status === 'fail')      return '已启动（' + (this._friendlyHealth(hd) || '健康检查未通过') + '）';
    return '健康检查中…';
  },

  /* fn: fire-and-forget RPC + 秒速轮询直到状态到位 */
  /* 注：点按即翻转开关（秒回），不等 RPC 确认，体验如 OpenClash */
  _svc: function (fn, opKey) {
    if (this._busy) return Promise.resolve();
    this._busy = true;
    var self = this;
    self._op = opKey;

    /* 立即翻转 switch 视觉 */
    var btn = document.querySelector('.cl-service-switch');
    if (btn) {
      var running = btn.getAttribute('aria-pressed') === 'true';
      var newRunning = opKey === 'start';
      if (newRunning !== running) {
        btn.setAttribute('aria-pressed', newRunning ? 'true' : 'false');
        btn.className = 'cl-service-switch' + (newRunning ? ' is-on' : ' is-off');
      }
      self._showOpMsg(opKey === 'stop' ? '停止中…' : '启动中…');
    }

    var maxWait = opKey === 'stop' ? 15000 : 35000;
    fn().catch(function () {});   /* fire-and-forget */

    var started   = Date.now();
    var pollTimer = null;

    function finish(finalMsg) {
      if (pollTimer) { clearTimeout(pollTimer); pollTimer = null; }
      if (finalMsg) self._showOpMsg(finalMsg);
      self._busy = false;
      self._op   = null;
      self._pollOverview(true);
    }

    function pollOnce() {
      L.resolveDefault(clashoo.status(), {}).then(function (st) {
        st = st || {};
        var elapsed = Date.now() - started;
        if (opKey === 'stop') {
          if (st.running === false)          return finish('已停止 ⚪');
        } else {
          if (st.running === true)           return finish('运行中 🟢');
          if (st.health_status === 'fail')   return finish(null);
        }
        if (elapsed >= maxWait) return finish(null);
        pollTimer = setTimeout(pollOnce, 500);
      }).catch(function () {
        if (Date.now() - started < maxWait) pollTimer = setTimeout(pollOnce, 500);
        else finish(null);
      });
    }
    pollTimer = setTimeout(pollOnce, 100);
  },

  _start:   function () { return this._svc(function () { return clashoo.start(); },   'start'); },
  _stop:    function () { return this._svc(function () { return clashoo.stop();  },   'stop'); },
  _restart: function () { return this._svc(function () { return clashoo.restart(); }, 'restart'); },

  _updSubs: function () {
    return L.resolveDefault(callDownloadSubs(), {}).then(function (r) {
      ui.addNotification(null, E('p', r.success ? '订阅更新成功' : ('更新失败: ' + (r.message || '未知错误'))));
    });
  },

  handleSaveApply: null,
  handleSave:      null,
  handleReset:     null
});
