'use strict';
'require view';
'require form';
'require uci';
'require ui';
'require rpc';
'require tools.clashoo as clashoo';

function getThemeClass() {
  var h = document.documentElement;
  // Bootstrap: explicit data-bs-theme attribute wins first
  if (h.dataset.bsTheme === 'dark') return 'cl-theme-dark';
  if (h.dataset.bsTheme === 'light') return 'cl-theme-light';
  // Argon: explicit darkmode attribute
  if (h.dataset.darkmode === 'true') return 'cl-theme-dark';
  // Argon: dark.css loaded in document = dark mode active (most reliable)
  var links = document.querySelectorAll('link[rel="stylesheet"]');
  for (var i = 0; i < links.length; i++) {
    if (links[i].href && links[i].href.indexOf('dark.css') !== -1) return 'cl-theme-dark';
  }
  // Generic: .dark class on root element
  if (h.classList.contains('dark')) return 'cl-theme-dark';
  // Body background luminance (skip transparent/rgba backgrounds)
  var bg = window.getComputedStyle(document.body).backgroundColor;
  if (bg && bg.indexOf('rgba') === -1 && bg.indexOf('rgb') !== -1) {
    var m = bg.match(/\d+/g);
    if (m && m.length >= 3 && (parseInt(m[0]) + parseInt(m[1]) + parseInt(m[2])) / 3 < 100) return 'cl-theme-dark';
  }
  return 'cl-theme-light';
}

var CSS = [
  '.cl-wrap{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif;--cl-card-border:rgba(128,128,128,.22);--cl-card-bg:rgba(128,128,128,.08);--cl-card-shadow:0 4px 12px rgba(0,0,0,.08);--cl-muted:rgba(92,102,120,.72);--cl-meta:var(--cl-muted);--cl-primary:rgba(0,122,255,.8);--cl-primary-border:rgba(0,122,255,.45);--cl-primary-soft:rgba(0,122,255,.08)}',
  '.cl-tabs{display:flex;border-bottom:2px solid rgba(128,128,128,.15);margin-bottom:18px}',
  '.cl-tab{padding:10px 20px;cursor:pointer;font-size:13px;opacity:.55;border-bottom:2px solid transparent;margin-bottom:-2px;transition:opacity .15s}',
  '.cl-tab.active{opacity:1;border-bottom-color:currentColor;font-weight:600}',
  '.cl-panel{display:none}.cl-panel.active{display:block}',
  '.cl-sub-list{width:100%;border-collapse:collapse;margin:12px 0;font-size:13px;table-layout:fixed}',
  '.cl-sub-list th,.cl-sub-list td{padding:8px 10px;border-bottom:1px solid rgba(128,128,128,.15);text-align:left;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
  '.cl-sub-list th{font-size:11px;opacity:.55;font-weight:600}',
  '.cl-sub-list th:nth-child(2),.cl-sub-list td:nth-child(2){width:72px}',
  '.cl-sub-list th:nth-child(3),.cl-sub-list td:nth-child(3){width:220px;text-align:right;white-space:nowrap}',
  '.cl-sub-url{border:1px solid rgba(128,128,128,.3);border-radius:6px;padding:8px 10px;width:100%;box-sizing:border-box;font-size:13px;margin-bottom:8px}',
  '.cl-sub-traffic{margin-top:4px;font-size:11px;color:var(--cl-meta,var(--cl-muted,#666))}',
  '.cl-sub-traffic-bar{height:4px;border-radius:2px;background:rgba(128,128,128,.18);margin-top:3px;overflow:hidden}',
  '.cl-sub-traffic-fill{height:100%;border-radius:2px;background:var(--primary-color,#0b68dd);transition:width .3s}',
  '.cl-sub-traffic-fill.cl-traffic-warn{background:#f59e0b}',
  '.cl-sub-traffic-fill.cl-traffic-danger{background:#ef4444}',
  '.cl-sub-expire{font-size:11px;color:var(--cl-meta,var(--cl-muted,#666));margin-top:2px}',
  '.cl-sub-expire.cl-expire-soon{color:#f59e0b}',
  '.cl-btn-sm{padding:4px 10px;font-size:12px;border-radius:4px;cursor:pointer}',
  '.cl-section{margin-bottom:24px}',
  '.cl-section h4{font-size:1.15rem;font-weight:600;margin-bottom:10px;color:var(--title-color,var(--cl-muted));opacity:.95}',
  /* constrain form inputs on desktop, table stays full-width */
  '.cl-form-wrap{max-width:640px}',
  '.cl-file-list{display:flex;flex-direction:column;gap:10px;margin-top:10px}',
  '.cl-file-item{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 12px;border:1px solid var(--cl-card-border);border-radius:8px;background:var(--cl-card-bg);box-shadow:var(--cl-card-shadow)}',
  '.cl-file-item.is-active{background:rgba(var(--primary-rgb,0,122,255),.08);border-color:rgba(var(--primary-rgb,0,122,255),.2)}',
  '.cl-file-meta{display:flex;flex:1;min-width:0;align-items:center;justify-content:space-between;gap:12px}',
  '.cl-file-name{display:flex;align-items:center;gap:8px;min-width:0}',
  '.cl-file-name-text{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}',
  '.cl-sb-file-name{display:flex;align-items:center;gap:8px;min-width:0;white-space:normal !important;overflow:visible !important;text-overflow:clip !important}',
  '.cl-sb-file-name .cl-file-name-text{min-width:0}',
  '.cl-file-size{font-size:12px;color:var(--cl-meta);white-space:nowrap}',
  '.cl-file-actions{display:flex;align-items:center;gap:8px;flex-shrink:0}',
  '.cl-rewrite-wrap{max-width:760px;padding:0;border:0;background:transparent;box-shadow:none}',
  '.cl-rewrite-group{display:flex;flex-direction:column;gap:8px}',
  '.cl-rewrite-group-title{font-size:12px;font-weight:700;opacity:.68}',
  '.cl-rw-divider{height:1px;background:rgba(128,128,128,.18);margin:10px 0}',
  '.cl-rewrite-wrap .cl-sub-url,.cl-rewrite-wrap .cbi-input-select{padding:8px 12px;border-radius:6px;width:100%;box-sizing:border-box;margin-bottom:0}',
  '.cl-rewrite-actions{margin-top:4px}',
  '.cl-actions{display:flex;gap:8px;flex-wrap:wrap}',
  '.cl-btn-update-sub{border-color:var(--cl-primary-border);color:var(--cl-primary)}',
  '.cl-btn-switch{background:var(--cl-primary-soft);border:1px solid var(--cl-primary-border);color:var(--cl-primary)}',
  '.cl-btn-switch:hover{background:rgba(0,122,255,.14);border-color:rgba(0,122,255,.62);color:rgba(0,96,220,.92)}',
  '.cl-btn-delete{border:1px solid rgba(var(--primary-rgb,0,122,255),.32);color:var(--cl-primary);background:rgba(var(--primary-rgb,0,122,255),.1)}',
  '.cl-btn-delete:hover{background:rgba(var(--primary-rgb,0,122,255),.16);border-color:rgba(var(--primary-rgb,0,122,255),.4);color:var(--cl-primary)}',
  '.cl-btn-generate-switch{box-shadow:0 4px 10px rgba(0,0,128,.2)}',
  '.cl-save-bar{display:flex;gap:8px;margin-top:14px;padding-top:12px;border-top:1px solid rgba(128,128,128,.15)}',
  '.cl-dns-auto{display:flex;flex-direction:column;gap:8px;max-width:640px}',
  '.cl-dns-auto-actions{display:flex;align-items:center;gap:10px;flex-wrap:wrap}',
  '.cl-dns-auto-status{font-size:12px;color:var(--cl-meta);line-height:1.55}',
  '.cl-dns-auto-result{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:6px 14px;padding:8px 10px;border:1px solid var(--cl-card-border);border-radius:8px;background:var(--cl-card-bg);color:var(--cl-meta);font-size:12px;line-height:1.5}',
  '.cl-dns-auto-result b{font-weight:700;opacity:.72;margin-right:4px}',
  '.cl-section-toggle{font-size:12px;cursor:pointer;flex-shrink:0;margin-left:auto}',
  '.cl-collapsible.cl-closed>*:not(h3){display:none!important}',
  '.cl-wrap .cbi-section-remove.right{background:transparent!important}',
  '.cl-json-editor{width:100%;height:340px;font-family:monospace;font-size:11px;border:1px solid rgba(128,128,128,.25);border-radius:8px;padding:10px;box-sizing:border-box;resize:vertical;background:rgba(0,0,0,.02)}',
  '.cl-editor-hdr{display:flex;align-items:center;gap:8px;margin-bottom:6px;font-size:12px;font-weight:600}',
  '.cl-active-badge{font-size:10px;font-weight:700;padding:2px 7px;border-radius:10px;background:rgba(var(--primary-rgb,0,122,255),.12);color:var(--cl-primary)}',
  '.cl-hint{font-size:11px;opacity:.45;margin-left:auto}',
  /* hide auto-generated section IDs in TypedSection */
  '.cbi-section-table-titles .cbi-section-table-cell:first-child{display:none}',
  '.cbi-section-table-row .cbi-section-table-cell:first-child{display:none}',
  '.cl-mode-tabs{display:inline-flex;gap:4px;margin:6px 0}',
  '.cl-mode-tab-active{font-weight:700}',
  '.cl-panel .cbi-section>h3{font-size:13px !important;font-weight:600;margin-bottom:8px}',
  '.cl-panel .cbi-value-title{font-size:13px !important}',
  '.cl-panel .cbi-value-field input,.cl-panel .cbi-value-field select,.cl-panel .cbi-value-field textarea{font-size:13px !important}',
  '.cl-panel .cbi-section-descr,.cl-panel .cbi-value-helptext{font-size:12px !important}',
  '.cl-panel .cbi-section{margin-bottom:12px}',
  '.cl-wrap .cbi-section>h3,.cl-wrap .cbi-value-title,.cl-wrap .cbi-section-descr,.cl-wrap .cbi-value-helptext{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif !important}',
  '.cl-wrap .cbi-input-text,.cl-wrap .cbi-input-select,.cl-wrap select,.cl-wrap input,.cl-wrap textarea,.cl-wrap .btn,.cl-wrap .cbi-button{font-size:13px !important;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif !important}',
  '.cl-wrap .btn,.cl-wrap .cbi-button{padding:4px 10px;line-height:1.35}',
  '.cl-sb-list td,.cl-sb-size{color:var(--cl-meta)}',
  '@media(prefers-color-scheme:dark){.cl-wrap{--cl-card-border:rgba(255,255,255,.14);--cl-card-bg:rgba(255,255,255,.04);--cl-card-shadow:0 4px 12px rgba(0,0,0,.28);--cl-muted:rgba(220,228,244,.58);--cl-meta:rgba(220,228,244,.72)}}',
  '.cl-theme-dark{--cl-card-border:rgba(255,255,255,.14);--cl-card-bg:rgba(255,255,255,.04);--cl-card-shadow:0 4px 12px rgba(0,0,0,.28);--cl-muted:rgba(220,228,244,.58);--cl-meta:rgba(220,228,244,.72)}',
  '@media(max-width:680px){.cl-wrap{--cl-meta:#4b5870}.cl-sub-list.cl-sb-list td:first-child{white-space:normal;overflow:visible;text-overflow:clip}}',
  '@media(max-width:680px){.cl-file-name-text,.cl-file-size,.cl-sub-traffic,.cl-sub-expire,.cl-sb-list td,.cl-sb-size,.cl-dns-auto-status,.cl-dns-auto-result{color:#4b5870!important}}',
  '@media(max-width:680px){html body .cl-wrap .cl-file-item .cl-file-meta .cl-file-size{color:#4b5870!important}}',
  '@media(max-width:680px){.cl-form-wrap{max-width:100%}}',
  '@media(max-width:680px){.cl-dns-auto,.cl-dns-auto-result{max-width:100%;width:100%;box-sizing:border-box}.cl-dns-auto-result{grid-template-columns:1fr}}'
].join('');

var callListSubs      = rpc.declare({ object: 'luci.clashoo', method: 'list_subscriptions',  expect: {} });
var callListDir       = rpc.declare({ object: 'luci.clashoo', method: 'list_dir_files',      params: ['type'], expect: {} });
var callDownloadSubs  = rpc.declare({ object: 'luci.clashoo', method: 'download_subs',       expect: {} });
var callUpdateSub     = rpc.declare({ object: 'luci.clashoo', method: 'update_sub',          params: ['name'], expect: {} });
var callSetConfig     = rpc.declare({ object: 'luci.clashoo', method: 'set_config',          params: ['name'], expect: {} });
var callDeleteCfg     = rpc.declare({ object: 'luci.clashoo', method: 'delete_config',       params: ['name', 'type'], expect: {} });
var callUploadConfig  = rpc.declare({ object: 'luci.clashoo', method: 'upload_config',       params: ['name', 'content', 'type'], expect: {} });
var callReadOtherConfig = rpc.declare({ object: 'luci.clashoo', method: 'read_other_config',  params: ['name', 'type'], expect: {} });
var callListTemplates = rpc.declare({ object: 'luci.clashoo', method: 'list_templates',      expect: {} });
var callUploadTemplate= rpc.declare({ object: 'luci.clashoo', method: 'upload_template',     params: ['name', 'content'], expect: {} });
var callApplyRewrite  = rpc.declare({ object: 'luci.clashoo', method: 'apply_rewrite',          params: ['base_type','base_name','rewrite_type','rewrite_name','output_name','set_active'], expect: {} });
var callFetchUrl      = rpc.declare({ object: 'luci.clashoo', method: 'fetch_rewrite_url',      params: ['url','name'], expect: {} });
var callApplyTplUrl   = rpc.declare({ object: 'luci.clashoo', method: 'apply_template_with_url', params: ['template_source','sub_url','output_name','set_active'], expect: {} });
var callMigrateSbProfile = rpc.declare({ object: 'luci.clashoo', method: 'migrate_singbox_profile', params: ['name'], expect: {} });
var callSmartModelStatus = rpc.declare({ object: 'luci.clashoo', method: 'smart_model_status',  expect: {} });
var callSmartUpgradeLgbm = rpc.declare({ object: 'luci.clashoo', method: 'smart_upgrade_lgbm',  expect: {} });
var callSmartFlushCache  = rpc.declare({ object: 'luci.clashoo', method: 'smart_flush_cache',   expect: {} });

function fastResolve(promise, timeoutMs, fallback) {
  var t = new Promise(function (resolve) {
    setTimeout(function () { resolve(fallback); }, timeoutMs);
  });
  return Promise.race([L.resolveDefault(promise, fallback), t]);
}

function loadUiState() {
  return L.resolveDefault(uci.load('clashoo'), null).then(function () {
    return {
      core_type:      uci.get('clashoo', 'config', 'core_type') || 'mihomo',
      subscribe_url:  uci.get('clashoo', 'config', 'subscribe_url') || '',
      config_name:    uci.get('clashoo', 'config', 'config_name') || ''
    };
  });
}

function readSavedTab(key, fallback, allowed) {
  var raw = '';
  if (window.location.hash)
    raw = window.location.hash.replace(/^#/, '');
  if (!raw) {
    try { raw = window.localStorage.getItem(key) || ''; } catch (e) {}
  }
  return allowed.indexOf(raw) >= 0 ? raw : fallback;
}

function rememberTab(key, id) {
  try { window.localStorage.setItem(key, id); } catch (e) {}
  if (window.history && window.history.replaceState)
    window.history.replaceState(null, '', '#' + id);
  else
    window.location.hash = id;
}

function fmtBytes(b) {
  b = parseInt(b) || 0;
  if (b >= 1e12) return (b / 1e12).toFixed(2) + ' TB';
  if (b >= 1e9)  return (b / 1e9).toFixed(2)  + ' GB';
  if (b >= 1e6)  return (b / 1e6).toFixed(1)  + ' MB';
  return Math.round(b / 1e3) + ' KB';
}
function fmtExpireDate(ts) {
  if (!ts || ts === 0) return '';
  var d = new Date(ts * 1000);
  var pad2 = function (n) { return n < 10 ? '0' + n : '' + n; };
  return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate());
}
/* 渲染流量条；返回 DOM 节点或 null */
function renderTrafficBar(used, total) {
  total = parseInt(total) || 0;
  if (total <= 0) return null;
  used = parseInt(used) || 0;
  var pct = Math.min(100, Math.round(used / total * 100));
  var fillCls = 'cl-sub-traffic-fill' + (pct >= 90 ? ' cl-traffic-danger' : pct >= 75 ? ' cl-traffic-warn' : '');
  return E('div', { 'class': 'cl-sub-traffic' }, [
    fmtBytes(used) + ' / ' + fmtBytes(total) + ' (' + pct + '%)',
    E('div', { 'class': 'cl-sub-traffic-bar' }, [
      E('div', { 'class': fillCls, 'style': 'width:' + pct + '%' })
    ])
  ]);
}
/* 渲染到期文本；返回 DOM 节点或 null */
function renderExpire(ts) {
  if (!ts) return null;
  var daysLeft = Math.ceil((ts * 1000 - Date.now()) / 86400000);
  var cls = 'cl-sub-expire' + (daysLeft <= 7 ? ' cl-expire-soon' : '');
  return E('div', { 'class': cls },
    '到期：' + fmtExpireDate(ts) + (daysLeft > 0 ? '（' + daysLeft + ' 天）' : '（已过期）'));
}

function decorateControlWraps(root) {
  if (!root || !root.querySelectorAll)
    return;
  var fields = root.querySelectorAll('.cbi-value-field');
  for (var i = 0; i < fields.length; i++) {
    if (fields[i] && fields[i].classList)
      fields[i].classList.add('cl-control-wrap');
  }
}

function clearClashooDirty() {
  var applyPromise;
  try {
    applyPromise = (L.uci && typeof L.uci.callApply === 'function')
      ? Promise.resolve(L.uci.callApply(0, false)).catch(function () {})
      : Promise.resolve();
  } catch (e) { applyPromise = Promise.resolve(); }
  return applyPromise.then(function () {
    try {
      if (L.ui && L.ui.changes && L.ui.changes.changes) {
        delete L.ui.changes.changes.clashoo;
        var n = Object.keys(L.ui.changes.changes).length;
        if (typeof L.ui.changes.renderChangeIndicator === 'function')
          L.ui.changes.renderChangeIndicator(n);
        else if (typeof L.ui.changes.setIndicator === 'function')
          L.ui.changes.setIndicator(n);
      }
    } catch (e) {}
  });
}

function saveCommitApplyMaybeReload(m, runningMsg, stoppedMsg) {
  return clashoo.status()
    .then(function (st) { return !!(st && st.running); })
    .catch(function () { return false; })
    .then(function (running) {
      return m.save()
        .then(function () { return clashoo.commitConfig(); })
        .then(function () {
          return running ? clashoo.reload() : { success: true, skipped: true };
        })
        .then(function () { return clearClashooDirty(); })
        .then(function () {
          ui.addNotification(null, E('p', running ? runningMsg : stoppedMsg));
          window.setTimeout(function () { location.reload(); }, 300);
        });
    });
}

function dnsAutoSummaryNode(res) {
  if (!res || !res.success)
    return E('div', { 'class': 'cl-dns-auto-status' }, '暂无自动配置结果');
  var elapsed = Math.max(0, parseInt(res.elapsed_ms || 0, 10));
  var failed = parseInt(res.failed_count || 0, 10);
  return E('div', { 'class': 'cl-dns-auto-result' }, [
    E('span', [E('b', '国内'), res.nameserver || '-']),
    E('span', [E('b', '代理'), res.proxy_nameserver || '-']),
    E('span', [E('b', 'Fallback'), res.fallback || '-']),
    E('span', [E('b', 'Bootstrap'), res.bootstrap || res.direct_nameserver || '-']),
    E('span', [E('b', '耗时'), elapsed ? (elapsed / 1000).toFixed(1) + ' 秒' : '-']),
    E('span', [E('b', '失败'), failed + ' 个候选'])
  ]);
}

function dnsAutoResultMessage(res) {
  if (!res || !res.success)
    return (res && res.message) || 'DNS 自动配置失败';
  return res.restarted
    ? 'DNS 自动配置已应用，服务正在重启'
    : 'DNS 自动配置已保存，服务未启动';
}

function storeDnsAutoResult(res) {
  try {
    res._saved_at = Date.now();
    window.localStorage.setItem('clashoo.dns_auto.last', JSON.stringify(res));
  } catch (e) {}
}

function readDnsAutoResult() {
  try {
    var raw = window.localStorage.getItem('clashoo.dns_auto.last') || '';
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

function clearDnsAutoResult() {
  try { window.localStorage.removeItem('clashoo.dns_auto.last'); } catch (e) {}
}

function setDnsAutoStatus(statusEl, nodeOrText) {
  statusEl.textContent = '';
  if (nodeOrText && nodeOrText.nodeType)
    statusEl.appendChild(nodeOrText);
  else
    statusEl.textContent = nodeOrText || '';
}

function findCbiSection(root, title) {
  var heads = root.querySelectorAll('.cbi-section > h3');
  for (var i = 0; i < heads.length; i++) {
    if ((heads[i].textContent || '').trim() === title)
      return heads[i].parentNode;
  }
  return null;
}

function makeSectionCollapsible(root, title, open) {
  var section = findCbiSection(root, title);
  if (!section || section.classList.contains('cl-collapsible'))
    return;
  section.classList.add('cl-collapsible');
  if (!open) section.classList.add('cl-closed');
  var btn = E('button', {
    'class': 'btn cbi-button cl-section-toggle',
    click: function (ev) {
      ev.preventDefault();
      section.classList.toggle('cl-closed');
      btn.textContent = section.classList.contains('cl-closed') ? '展开' : '折叠';
    }
  }, open ? '折叠' : '展开');
  var h3 = section.querySelector('h3');
  if (h3) h3.appendChild(btn);
}

return view.extend({
  _tab: null,
  _sbTab: null,

  load: function () {
    return Promise.all([
      fastResolve(callListSubs(), 1200, { subs: [], url: '' }),
      fastResolve(callListDir('1'), 1200, { files: [] }),
      fastResolve(callListDir('2'), 1200, { files: [] }),
      fastResolve(callListDir('3'), 1200, { files: [] }),
      fastResolve(callListTemplates(), 1200, { files: [] }),
      fastResolve(loadUiState(), 1200, { core_type: 'mihomo', subscribe_url: '', config_name: '' }),
      fastResolve(clashoo.listSingboxProfiles(), 1200, { profiles: [], active: '' }),
      fastResolve(callSmartModelStatus(), 1500, { has_model: false, version: '' })
    ]);
  },

  render: function (data) {
    var self       = this;
    var subsData   = data[0] || {};
    var subFiles   = (data[1] && data[1].files) || [];
    var upFiles    = (data[2] && data[2].files) || [];
    var customFiles= (data[3] && data[3].files) || [];
    var tplFiles   = (data[4] && data[4].files) || [];
    var uiData     = data[5] || { core_type: 'mihomo', subscribe_url: '', config_name: '' };
    var sbData          = data[6] || { profiles: [], active: '' };
    var smartModelData  = data[7] || { has_model: false, version: '' };
    var coreType   = uiData.core_type || 'mihomo';

    if (!document.getElementById('cl-css')) {
      var s = document.createElement('style');
      s.id = 'cl-css'; s.textContent = CSS;
      document.head.appendChild(s);
    }
    if (!document.getElementById('cl-css-ext')) {
      var link = document.createElement('link');
      link.id = 'cl-css-ext';
      link.rel = 'stylesheet';
      link.href = L.resource('view/clashoo/clashoo.css') + '?v=20260502b1';
      document.head.appendChild(link);
    } else {
      document.getElementById('cl-css-ext').href = L.resource('view/clashoo/clashoo.css') + '?v=20260502b1';
    }

    if (coreType === 'singbox') return this._renderSingbox(sbData);

    var tabs = [
      { id: 'subs', label: '订阅' },
      { id: 'proxy', label: '代理' },
      { id: 'dns',   label: 'DNS' }
    ];
    var allowedTabs = tabs.map(function (t) { return t.id; });
    this._tab = readSavedTab('clashoo.config.tab', this._tab || 'subs', allowedTabs);
    rememberTab('clashoo.config.tab', this._tab);
    var tabEls   = {};
    var panelEls = {};

    var subPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'subs' ? ' active' : ''), id: 'cl-panel-subs' },
      this._buildSubsPanel(subsData, subFiles, upFiles, customFiles, tplFiles, uiData)
    );
    panelEls['subs'] = subPanel;

    var proxyPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'proxy' ? ' active' : ''), id: 'cl-panel-proxy' });
    panelEls['proxy'] = proxyPanel;

    var dnsPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'dns' ? ' active' : ''), id: 'cl-panel-dns' });
    panelEls['dns'] = dnsPanel;

    var built = { subs: true, proxy: false, dns: false };
    var ensureBuilt = function (id) {
      if (built[id]) return;
      if (id === 'proxy') self._buildProxyForm(proxyPanel, smartModelData);
      else if (id === 'dns') self._buildDnsForm(dnsPanel);
      built[id] = true;
    };
    if (this._tab !== 'subs') ensureBuilt(this._tab);

    var tabBar = E('div', { 'class': 'cl-tabs' },
      tabs.map(function (t) {
        var el = E('div', {
          'class': 'cl-tab' + (self._tab === t.id ? ' active' : ''),
          click: function () {
            ensureBuilt(t.id);
            Object.keys(tabEls).forEach(function (k) {
              tabEls[k].className   = 'cl-tab'   + (k === t.id ? ' active' : '');
              panelEls[k].className = 'cl-panel' + (k === t.id ? ' active' : '');
            });
            self._tab = t.id;
            rememberTab('clashoo.config.tab', t.id);
          }
        }, t.label);
        tabEls[t.id] = el;
        return el;
      })
    );

    return E('div', { 'class': 'cl-wrap clashoo-container cl-config-page cl-form-page ' + getThemeClass() }, [tabBar, subPanel, proxyPanel, dnsPanel]);
  },

  _buildSubsPanel: function (subsData, subFiles, upFiles, customFiles, tplFiles, uiData) {
    var self = this;
    var sanitizeText = function (v) { return (v == null || v === 'null') ? '' : String(v); };
    var subUrl      = sanitizeText(uiData && uiData.subscribe_url);
    var savedName   = sanitizeText(uiData && uiData.config_name);
    var subs        = subsData.subs || [];
    var safeText    = function (v) { return (v == null || v === 'null') ? '' : String(v); };

    var urlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '订阅链接（多条用换行分隔）',
      value: subUrl
    });

    var nameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '文件名（选填，留空自动生成）',
      value: savedName,
      style: 'margin-top:0'
    });

    var dlBtn = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      click: function () {
        L.resolveDefault(uci.load('clashoo'), null)
          .then(function () {
            uci.set('clashoo', 'config', 'subscribe_url', urlInput.value);
            uci.set('clashoo', 'config', 'config_name',   nameInput.value.trim());
            return uci.save();
          })
          .then(function () { return clashoo.commitConfig(); })
          .then(function () { return clearClashooDirty(); })
          .then(function () { return L.resolveDefault(callDownloadSubs(), {}); })
          .then(function (r) {
            ui.addNotification(null, E('p', r.success ? '下载成功' : '下载失败: ' + (r.message || '')));
            location.reload();
          });
      }
    }, '下载订阅');

    var subCards = subs.map(function (sub) {
      var nameNodes = [];
      if (sub.active) nameNodes.push(E('span', { 'class': 'cl-active-badge' }, '使用中'));
      nameNodes.push(E('span', { 'class': 'cl-file-name-text' }, safeText(sub.name)));

      var used = (parseInt(sub.sub_upload) || 0) + (parseInt(sub.sub_download) || 0);
      var trafficEl = renderTrafficBar(used, sub.sub_total);
      var expireEl  = renderExpire(sub.sub_expire);

      return E('div', { 'class': 'cl-file-item' + (sub.active ? ' is-active' : '') }, [
        E('div', { 'class': 'cl-file-meta' }, [
          E('div', { 'class': 'cl-file-name' }, nameNodes),
          E('div', { 'class': 'cl-file-size' }, safeText(sub.size)),
          trafficEl, expireEl
        ]),
        E('div', { 'class': 'cl-file-actions' }, [
          E('button', {
            'class': 'btn cbi-button cl-btn-sm cl-btn-update-sub',
            click: function () {
              L.resolveDefault(callUpdateSub(sub.name), {}).then(function (r) {
                ui.addNotification(null, E('p', r.success ? sub.name + ' 更新成功' : '更新失败'));
                location.reload();
              });
            }
          }, '更新'),
          E('button', {
            'class': 'btn cbi-button cl-btn-sm cl-btn-switch',
            click: function () {
              L.resolveDefault(callSetConfig(sub.name), {}).then(function () { location.reload(); });
            }
          }, '切换'),
          E('button', {
            'class': 'btn cbi-button cl-btn-sm cl-btn-delete',
            click: function () {
              if (!confirm('删除 ' + sub.name + '？')) return;
              L.resolveDefault(callDeleteCfg(sub.name, '1'), {}).then(function () { location.reload(); });
            }
          }, '删除')
        ])
      ]);
    });

    var uploadInput = E('input', { type: 'file', accept: '.yaml,.yml', style: 'display:none', id: 'cl-upload-input' });
    uploadInput.addEventListener('change', function (ev) {
      var file = ev.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        L.resolveDefault(callUploadConfig(file.name, e.target.result, '2'), {}).then(function (r) {
          ui.addNotification(null, E('p', r.success ? '上传成功: ' + r.name : '上传失败'));
          location.reload();
        });
      };
      reader.readAsText(file);
    });

    var mkSel = function (files, placeholder) {
      return E('select', { 'class': 'cbi-input-select' },
        [E('option', { value: '' }, placeholder)].concat(
          files.map(function (f) { return E('option', { value: f.name }, f.name); })
        )
      );
    };

    /* ── 模板复写（注入订阅 URL 模式）── */
    var tplSel     = mkSel(tplFiles, '选择本地模板文件');
    tplSel.classList.add('cl-template-select');
    tplSel.setAttribute('title', tplSel.value || '');
    tplSel.addEventListener('change', function () { tplSel.setAttribute('title', tplSel.value || ''); });

    var tplUploadInput = E('input', { type: 'file', accept: '.yaml,.yml', style: 'display:none', id: 'cl-template-upload-input' });
    tplUploadInput.addEventListener('change', function (ev) {
      var file = ev.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        L.resolveDefault(callUploadTemplate(file.name, e.target.result), {}).then(function (r) {
          if (r && r.success) {
            ui.addNotification(null, E('p', '模板上传成功: ' + (r.name || file.name)));
            location.reload();
            return;
          }
          ui.addNotification(null, E('p', '模板上传失败: ' + ((r && (r.message || r.error)) || '未知错误')));
        });
      };
      reader.readAsText(file);
    });

    var tplUrlIn   = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: '输入远程模板 URL，例如 https://raw.githubusercontent.com/…/Clash.yaml' });
    var subUrlIn   = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: '输入订阅链接 URL（注入到模板的 proxy-providers）' });
    var outNameIn  = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: '输出文件名（不含扩展名，留空自动填写）' });
    var rwMode     = 'local';

    function rwAutoFill() {
      if (outNameIn.value) return;
      var tpl = rwMode === 'local' ? tplSel.value.replace(/\.(yaml|yml)$/, '') : 'remote-tpl';
      if (tpl) outNameIn.value = tpl + '-rewrite';
    }
    tplSel.addEventListener('change', rwAutoFill);

    var localPanel  = E('div', { 'class': 'cl-rw-pane cl-rw-pane-local' }, [
      tplUploadInput,
      E('div', { 'class': 'cl-template-row' }, [
        E('div', { 'class': 'cl-template-select-wrap' }, [tplSel]),
        E('button', {
          'class': 'btn cbi-button cl-btn-sm cl-btn-template-upload',
          click: function () { document.getElementById('cl-template-upload-input').click(); }
        }, '上传 YAML 模板')
      ])
    ]);
    var remotePanel = E('div', { 'class': 'cl-rw-pane cl-rw-pane-remote', style: 'display:none' }, [tplUrlIn]);

    var tabLocal  = E('button', { 'class': 'btn cbi-button cl-btn-sm cl-mode-tab-active',
      click: function () {
        rwMode = 'local';
        localPanel.style.display  = ''; remotePanel.style.display = 'none';
        tabLocal.classList.add('cl-mode-tab-active');
        tabRemote.classList.remove('cl-mode-tab-active');
        outNameIn.value = '';
        rwAutoFill();
      }
    }, '本地模板');
    var tabRemote = E('button', { 'class': 'btn cbi-button cl-btn-sm',
      click: function () {
        rwMode = 'remote';
        localPanel.style.display  = 'none'; remotePanel.style.display = '';
        tabRemote.classList.add('cl-mode-tab-active');
        tabLocal.classList.remove('cl-mode-tab-active');
        outNameIn.value = '';
      }
    }, '远程模板');

    var rwApply = function (setActive) {
      var tplSrc = rwMode === 'local' ? tplSel.value : tplUrlIn.value.trim();
      var subUrl = subUrlIn.value.trim();
      var out    = outNameIn.value.trim();
      if (!tplSrc) { ui.addNotification(null, E('p', rwMode === 'local' ? '请选择本地模板文件' : '请输入远程模板 URL')); return; }
      if (!subUrl) { ui.addNotification(null, E('p', '请输入订阅链接 URL')); return; }
      if (!out)    { ui.addNotification(null, E('p', '请填写输出文件名')); return; }
      L.resolveDefault(callApplyTplUrl(tplSrc, subUrl, out, setActive ? '1' : '0'), {}).then(function (r) {
        ui.addNotification(null, E('p', r && r.success ? (r.message || '生成成功: ' + r.output_name) : ('生成失败: ' + (r && r.message || '未知错误'))));
        if (r && r.success) location.reload();
      });
    };

    /* ── 其他配置文件（上传 + 自定义/复写输出）── */
    var otherEditorTitle    = E('span', { 'class': 'cl-editor-hdr' }, '选择上方配置后可在此处编辑');
    var otherTextarea       = E('textarea', { 'class': 'cl-json-editor cl-other-editor', placeholder: '选择配置文件后内容将显示在这里…' });
    var otherSaveBtn        = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      disabled: '',
      click: function () {
        var meta = otherTextarea.dataset;
        if (!meta.name) return;
        L.resolveDefault(callUploadConfig(meta.name, otherTextarea.value, meta.type), {}).then(function (r) {
          if (r && r.success) ui.addNotification(null, E('p', meta.name + ' 已保存'));
          else ui.addNotification(null, E('p', '保存失败: ' + ((r && (r.message || r.error)) || '')));
        });
      }
    }, '保存');

    var otherEditorBox = E('div', { 'class': 'cl-section cl-card cl-sb-editor' }, [
      otherEditorTitle,
      otherTextarea,
      E('div', { 'class': 'cl-actions cl-sb-row-actions cl-sb-editor-actions' }, [
        otherSaveBtn,
        E('span', { 'class': 'cl-hint' }, '编辑后点击保存；切换配置后服务将自动重启')
      ])
    ]);

    function loadOtherEditor(name, type) {
      otherEditorTitle.textContent = '编辑：' + name;
      otherSaveBtn.removeAttribute('disabled');
      otherTextarea.dataset.name = name;
      otherTextarea.dataset.type = type;
      otherTextarea.value = '加载中…';
      L.resolveDefault(callReadOtherConfig(name, type), {}).then(function (r) {
        otherTextarea.value = r.content || '';
      });
    }

    var makeOtherCards = function (files, type) {
      return files.map(function (f) {
        var nameNodes = [];
        if (f.active) nameNodes.push(E('span', { 'class': 'cl-active-badge' }, '使用中'));
        nameNodes.push(E('span', { 'class': 'cl-file-name-text' }, safeText(f.name)));

        return E('div', { 'class': 'cl-file-item' + (f.active ? ' is-active' : '') }, [
          E('div', { 'class': 'cl-file-meta' }, [
            E('div', { 'class': 'cl-file-name' }, nameNodes),
            E('div', { 'class': 'cl-file-size' }, safeText(f.size))
          ]),
          E('div', { 'class': 'cl-file-actions' }, [
            E('button', {
              'class': 'btn cbi-button cl-btn-sm cl-btn-edit',
              click: function () { loadOtherEditor(f.name, type); }
            }, '编辑'),
            E('button', {
              'class': 'btn cbi-button cl-btn-sm cl-btn-switch',
              click: function () {
                L.resolveDefault(callSetConfig(f.name), {}).then(function () { location.reload(); });
              }
            }, '切换'),
            E('button', {
              'class': 'btn cbi-button cl-btn-sm cl-btn-delete',
              click: function () {
                if (!confirm('删除 ' + f.name + '？')) return;
                L.resolveDefault(callDeleteCfg(f.name, type), {}).then(function () { location.reload(); });
              }
            }, '删除')
          ])
        ]);
      });
    };

    var otherFiles = (upFiles || []).map(function(f){ return {f:f, t:'2'}; })
      .concat((customFiles || []).map(function(f){ return {f:f, t:'3'}; }));

    var otherCards = otherFiles.map(function(o) {
      return makeOtherCards([o.f], o.t)[0];
    });

    var sections = [
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, '订阅链接'),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600' }, [urlInput, nameInput, dlBtn])
      ]),
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, '已下载订阅'),
        subs.length ? E('div', { 'class': 'cl-fixed-600' }, [
          E('div', { 'class': 'cl-file-list' }, subCards)
        ])
          : E('p', { style: 'opacity:.5;font-size:13px' }, '暂无订阅')
      ]),
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, '上传配置文件'),
        uploadInput,
        E('button', {
          'class': 'btn cbi-button cl-btn-sm cl-btn-upload-config',
          click: function () { document.getElementById('cl-upload-input').click(); }
        }, '选择 YAML 文件上传')
      ])
    ];

    if (otherFiles.length) {
      sections.push(E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, '其他配置文件（上传 / 复写输出）'),
        E('div', { 'class': 'cl-fixed-600' }, [
          E('div', { 'class': 'cl-file-list' }, otherCards)
        ])
      ]));
      sections.push(otherEditorBox);
    }

    sections.push(
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, '复写设置'),
        E('div', { 'class': 'cl-form-wrap cl-rewrite-wrap cl-fixed-600' }, [
          E('div', { 'class': 'cl-rewrite-group cl-rewrite-group-template' }, [
            E('div', { 'class': 'cl-rewrite-group-title' }, '模板选择'),
            E('div', { 'class': 'cl-mode-tabs' }, [tabLocal, tabRemote]),
            localPanel,
            remotePanel
          ]),
          E('div', { 'class': 'cl-rw-divider' }),
          E('div', { 'class': 'cl-rewrite-group cl-rewrite-group-input' }, [
            E('div', { 'class': 'cl-rewrite-group-title' }, '信息录入'),
            subUrlIn,
            outNameIn,
            E('div', { 'class': 'cl-actions cl-rewrite-actions' }, [
              E('button', { 'class': 'btn cbi-button cl-btn-sm', click: function(){ rwApply(false); } }, '生成配置'),
              E('button', { 'class': 'btn cbi-button-action cl-btn-sm cl-btn-generate-switch', click: function(){ rwApply(true); } }, '应用配置')
            ])
          ])
        ])
      ])
    );

    return sections.filter(function (n) { return n !== null && n !== undefined; });
  },

  _buildProxyForm: function (container, modelStatus) {
    var m = new form.Map('clashoo', '', '');
    var s, o;
    modelStatus = modelStatus || {};

    s = m.section(form.NamedSection, 'config', 'clashoo', '透明代理');
    s.addremove = false;
    o = s.option(form.ListValue, 'tcp_mode', 'TCP 模式');
    o.value('redirect', 'Redirect'); o.value('tproxy', 'TPROXY'); o.value('tun', 'TUN'); o.value('off', '关闭');
    o = s.option(form.ListValue, 'udp_mode', 'UDP 模式');
    o.value('tun', 'TUN'); o.value('tproxy', 'TPROXY'); o.value('off', '关闭');
    o = s.option(form.ListValue, 'stack', '网络栈类型');
    o.value('system', 'System'); o.value('gvisor', 'gVisor'); o.value('mixed', 'Mixed');
    o = s.option(form.Flag, 'disable_quic_gso', '禁用 QUIC GSO');
    o = s.option(form.Flag, 'ipv4_dns_hijack', 'IPv4 DNS 劫持');
    o = s.option(form.Flag, 'ipv6_dns_hijack', 'IPv6 DNS 劫持');
    o = s.option(form.Flag, 'ipv4_proxy',      'IPv4 代理');
    o = s.option(form.Flag, 'ipv6_proxy',      'IPv6 代理');
    o = s.option(form.Flag, 'fake_ip_ping_hijack', '虚拟 IP Ping 劫持');
    o = s.option(form.Flag, 'dns_leak_protect', '防 DNS 泄漏');
    o.description = '阻止国内 DNS 解析国外域名、关闭 IPv6 解析、阻断 DoT/DoQ（853 端口）。切换后需重启服务生效。<br>' +
                    '<strong>注意：</strong>开启后 IPv6 网站只能通过 IPv4 访问，纯 IPv6 网络下可能无法上网。';

    s = m.section(form.NamedSection, 'config', 'clashoo', '端口配置');
    s.addremove = false;
    o = s.option(form.Flag,  'allow_lan',   '允许局域网连接');
    o = s.option(form.Value, 'http_port',   'HTTP 端口');
    o = s.option(form.Value, 'socks_port',  'SOCKS5 端口');
    o = s.option(form.Value, 'mixed_port',  '混合端口');
    o = s.option(form.Value, 'redir_port',  'Redirect 端口');
    o = s.option(form.Value, 'tproxy_port', 'TPROXY 端口');

    s = m.section(form.NamedSection, 'config', 'clashoo', 'Smart 策略设置');
    s.addremove = false;

    o = s.option(form.Flag,  'smart_auto_switch', 'Smart 策略自动切换');
    o.description = '自动切换 Url-test、Load-balance 策略组到 Smart 策略组';

    o = s.option(form.Value, 'smart_policy_priority', 'Policy Priority（权重加成）');
    o.default = 'Premium:0.9;SG:1.3';
    o.placeholder = 'Premium:0.9;SG:1.3';
    o.rmempty = true;
    o.description = '节点权重加成，<1 表示较低优先级，>1 表示较高优先级；可按需修改，留空则不注入 policy-priority';

    o = s.option(form.Flag,  'smart_prefer_asn', 'ASN 优先');
    o.description = '选择节点时强制查找并优先使用目标的 ASN 信息，以获得更稳定的体验';

    o = s.option(form.Flag,  'smart_uselightgbm', '启用 LightGBM 模型');
    o.description = '使用 LightGBM 模型来预测权重';

    o = s.option(form.Flag,  'smart_collectdata', '收集训练数据');
    o.description = '收集节点延迟数据供 LightGBM 模型训练';

    o = s.option(form.Value, 'smart_collect_size', '训练数据量');
    o.datatype = 'uinteger';
    o.placeholder = '100';
    o.description = 'smart-collector-size，最多保留的训练样本数，默认 100';

    o = s.option(form.Value, 'smart_collect_rate', '采样率');
    o.datatype = 'uinteger';
    o.placeholder = '1';
    o.description = 'sample-rate，1 = 每次测速都采样，调大可降低采集频率';

    o = s.option(form.Flag,  'smart_lgbm_auto_update', '自动更新模型');

    o = s.option(form.Value, 'smart_lgbm_update_interval', '更新间隔（小时）');
    o.datatype = 'uinteger';
    o.placeholder = '72';
    o.description = '自动拉取新模型的周期，同时决定 cron 触发频率，默认 72 小时';

    o = s.option(form.Value, 'smart_lgbm_url', '模型下载 URL');
    o.placeholder = 'https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model.bin';
    o.rmempty = true;
    o.description = 'LightGBM 模型文件下载地址，留空使用默认官方地址';

    var sa = m.section(form.TypedSection, 'authentication', '代理认证');
    sa.anonymous = true; sa.addremove = true;
    o = sa.option(form.Value, 'username', '用户名');
    o = sa.option(form.Value, 'password', '密码');

    m.render().then(function (node) {
      decorateControlWraps(node);
      container.appendChild(node);

      // Smart section action buttons
      var sections = node.querySelectorAll('.cbi-section');
      var smartSec;
      for (var i = 0; i < sections.length; i++) {
        var h3 = sections[i].querySelector('h3');
        if (h3 && h3.textContent.indexOf('Smart') >= 0) { smartSec = sections[i]; break; }
      }
      if (smartSec) {
        var verEl = modelStatus.has_model
          ? E('span', { 'class': 'cl-ver-tag' }, [
              E('span', { 'class': 'cl-ver-label' }, '当前版本: '),
              E('span', { 'class': 'cl-ver-value' }, modelStatus.version)
            ])
          : E('span', { 'class': 'cl-ver-tag cl-ver-label' }, '模型未安装');
        var upgBtn = E('button', { 'class': 'btn cbi-button-action', 'click': function () {
          upgBtn.disabled = true; upgBtn.textContent = '更新中...';
          callSmartUpgradeLgbm().then(function () {
            upgBtn.disabled = false; upgBtn.textContent = '检查并更新';
            ui.addNotification(null, E('p', '模型更新任务已启动'));
          }).catch(function () { upgBtn.disabled = false; upgBtn.textContent = '检查并更新'; });
        }}, '检查并更新');
        smartSec.appendChild(E('div', { 'class': 'cbi-value' }, [
          E('label', { 'class': 'cbi-value-title' }, '更新模型'),
          E('div', { 'class': 'cbi-value-field' }, [
            E('div', { 'class': 'cl-btn-ver-wrap' }, [
              upgBtn,
              verEl
            ])
          ])
        ]));
        var flushBtn = E('button', { 'class': 'btn cbi-button', 'click': function () {
          flushBtn.disabled = true;
          callSmartFlushCache().then(function (res) {
            flushBtn.disabled = false;
            ui.addNotification(null, E('p', (res && res.success) ? 'Smart 缓存已清理' : '清理失败（mihomo 可能未运行）'));
          }).catch(function () { flushBtn.disabled = false; });
        }}, '清理');
        smartSec.appendChild(E('div', { 'class': 'cbi-value' }, [
          E('label', { 'class': 'cbi-value-title' }, '清理 Smart 缓存'),
          E('div', { 'class': 'cbi-value-field' }, [flushBtn])
        ]));
      }
      makeSectionCollapsible(node, 'Smart 策略设置', false);
      makeSectionCollapsible(node, '代理认证', false);

      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'btn cbi-button', click: function () {
          m.save().then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', '保存失败: ' + (e.message || e))); });
        }}, '保存配置'),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          saveCommitApplyMaybeReload(m, '代理配置已保存并热重载服务', '代理配置已保存，服务未启动')
            .catch(function (e) { ui.addNotification(null, E('p', '操作失败: ' + (e.message || e))); });
        }}, '应用配置')
      ]));
    });
  },

  _buildDnsForm: function (container) {
    var m = new form.Map('clashoo', '', '');
    var s, o;

    s = m.section(form.NamedSection, 'config', 'clashoo', '基础 DNS');
    s.addremove = false;
    o = s.option(form.DummyValue, '_dns_auto_setup', 'DNS 自动配置');
    o.cfgvalue = function () {
      var statusEl = E('div', { 'class': 'cl-dns-auto-status' }, []);
      var last = readDnsAutoResult();
      if (last && last.success)
        setDnsAutoStatus(statusEl, dnsAutoSummaryNode(last));
      else
        statusEl.textContent = '自动选择可用 DNS，仅更新上游服务器；分流策略和高级设置保持不变。';
      if (last && last.success)
        window.setTimeout(function () {
          clearDnsAutoResult();
          statusEl.textContent = '自动选择可用 DNS，仅更新上游服务器；分流策略和高级设置保持不变。';
        }, 6000);
      var btn = E('button', {
        'class': 'btn cbi-button-action',
        click: function (ev) {
          ev.preventDefault();
          btn.disabled = true;
          setDnsAutoStatus(statusEl, '正在测速并写入 DNS 上游…');
          clashoo.dnsAutoSetup()
            .then(function (res) {
              btn.disabled = false;
              if (!res || !res.success) {
                setDnsAutoStatus(statusEl, (res && res.message) || 'DNS 自动配置失败');
                ui.addNotification(null, E('p', (res && res.message) || 'DNS 自动配置失败'));
                return;
              }
              storeDnsAutoResult(res);
              setDnsAutoStatus(statusEl, dnsAutoSummaryNode(res));
              ui.addNotification(null, E('p', dnsAutoResultMessage(res)));
              window.setTimeout(function () {
                clearDnsAutoResult();
                statusEl.textContent = '自动配置已完成。';
              }, 6000);
            })
            .catch(function (e) {
              btn.disabled = false;
              setDnsAutoStatus(statusEl, 'DNS 自动配置失败: ' + (e.message || e));
              ui.addNotification(null, E('p', 'DNS 自动配置失败: ' + (e.message || e)));
            });
        }
      }, '一键测速并应用');
      return E('div', { 'class': 'cl-dns-auto' }, [
        E('div', { 'class': 'cl-dns-auto-actions' }, [btn]),
        statusEl
      ]);
    };
    o.write = function () {};
    o = s.option(form.Flag,        'enable_dns',        '启用 DNS 模块');
    o = s.option(form.Value,       'listen_port',       'DNS 监听端口');
    o.datatype = 'port';
    o = s.option(form.ListValue,   'enhanced_mode',     '增强模式');
    o.value('fake-ip', 'Fake-IP'); o.value('redir-host', 'Redir-Host');
    o.default = 'fake-ip';
    o = s.option(form.Value,       'fake_ip_range',     'Fake-IP 网段');
    o.default = '198.18.0.1/16';
    o.placeholder = '198.18.0.1/16';
    o.depends('enhanced_mode', 'fake-ip');
    o.remove = function () {};
    o = s.option(form.Flag,        'enable_ipv6',       'IPv6 DNS');

    s = m.section(form.NamedSection, 'config', 'clashoo', '高级 DNS');
    s.addremove = false;
    o = s.option(form.Flag,        'dnsforwader',       '强制转发 DNS');
    o = s.option(form.DynamicList, 'fake_ip_filter',    'Fake-IP 过滤域名');
    o.placeholder = '*.lan / localhost.ptlogin2.qq.com';
    o.depends('enhanced_mode', 'fake-ip');
    o.remove = function () {};
    o = s.option(form.DynamicList, 'default_nameserver', 'Bootstrap DNS');
    o.placeholder = '223.5.5.5';
    o.description = '用于解析 DoH/DoT/DoQ 服务器域名，建议填写纯 IP DNS。';
    o = s.option(form.Value, 'dns_ecs', 'ECS 客户端子网');
    o.placeholder = '223.5.5.0/24';
    o.description = 'Mihomo 写入 DNS URL 的 ecs 参数；sing-box 写入 dns.client_subnet。清空则不写入。';
    o.rmempty = true;
    o = s.option(form.Flag, 'dns_ecs_override', '强制覆盖 ECS');
    o.default = '0';
    o = s.option(form.Flag, 'fallback_filter_geoip', 'Fallback GeoIP 过滤');
    o.default = '1';
    o = s.option(form.DynamicList, 'fallback_filter_ipcidr', 'Fallback IP CIDR');
    o.placeholder = '240.0.0.0/4';
    o = s.option(form.Flag, 'singbox_independent_cache', 'sing-box 独立 DNS 缓存');
    o.default = '0';
    o.description = '开启后，direct / proxy / fallback 等角色各自独立 DNS 缓存；适用于同一域名按分流走不同解析链的场景。一般无需开启。';

    s = m.section(form.TypedSection, 'dnsservers', '上游 DNS');
    s.addremove = true; s.anonymous = true;
    o = s.option(form.Flag, 'enabled', '启用');
    o.default = '1';
    o = s.option(form.ListValue, 'ser_type', '角色');
    o.value('nameserver', '国内上游 DNS');
    o.value('direct-nameserver', '直连域名解析');
    o.value('proxy-server-nameserver', '节点域名解析专用');
    o.value('fallback', '国外加密 DNS（防污染）');
    o.default = 'nameserver';
    o = s.option(form.Value,     'ser_address', 'DNS 地址');
    o.placeholder = 'https://dns.alidns.com/dns-query / https://doh.pub/dns-query';
    o = s.option(form.ListValue, 'protocol',    '协议');
    o.value('none', '完整 URL / 不补协议');
    o.value('udp://', 'UDP');
    o.value('tcp://', 'TCP');
    o.value('tls://', 'DoT / TLS');
    o.value('https://', 'DoH / HTTPS');
    o.value('quic://', 'DoQ / QUIC');
    o.default = 'none';
    o = s.option(form.Value, 'ser_port', '端口');
    o.placeholder = '853 / 784';
    o.rmempty = true;

    s = m.section(form.TypedSection, 'dns_policy', '分流解析策略');
    s.addremove = true; s.anonymous = true;
    o = s.option(form.Flag, 'enabled', '启用');
    o.default = '1';
    o = s.option(form.ListValue, 'policy_type', '策略类型');
    o.value('nameserver-policy', '域名分流解析');
    o.value('proxy-server-nameserver-policy', '代理域名分流解析');
    o.default = 'nameserver-policy';
    o = s.option(form.Value, 'matcher', '匹配规则');
    o.placeholder = 'geosite:cn / domain:example.com / domain-suffix:google.com';
    o = s.option(form.DynamicList, 'nameserver', '使用 DNS');
    o.placeholder = 'udp://223.5.5.5';
    o.description = '示例：geosite:cn 使用 https://dns.alidns.com/dns-query；geosite:geolocation-!cn 使用 https://cloudflare-dns.com/dns-query。';

    m.render().then(function (node) {
      decorateControlWraps(node);
      makeSectionCollapsible(node, '基础 DNS', true);
      makeSectionCollapsible(node, '高级 DNS', false);
      makeSectionCollapsible(node, '上游 DNS', false);
      makeSectionCollapsible(node, '分流解析策略', false);
      container.appendChild(node);
      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'btn cbi-button', click: function () {
          m.save().then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', '保存失败: ' + (e.message || e))); });
        }}, '保存配置'),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          saveCommitApplyMaybeReload(m, 'DNS 配置已保存并热重载服务', 'DNS 配置已保存，服务未启动')
            .catch(function (e) { ui.addNotification(null, E('p', '操作失败: ' + (e.message || e))); });
        }}, '应用配置')
      ]));
    });
  },

  /* ── sing-box UI ── */

  _renderSingbox: function (sbData) {
    var self = this;
    var profiles = sbData.profiles || [];
    var tabEls = {}, panelEls = {};

    var tabs = [
      { id: 'profiles', label: '配置文件' },
      { id: 'wizard',   label: '快速向导' }
    ];
    var allowedTabs = tabs.map(function (t) { return t.id; });
    this._sbTab = readSavedTab('clashoo.config.singbox.tab', this._sbTab || 'profiles', allowedTabs);
    rememberTab('clashoo.config.singbox.tab', this._sbTab);

    var tabBar = E('div', { 'class': 'cl-tabs' },
      tabs.map(function (t) {
        var el = E('div', {
          'class': 'cl-tab' + (self._sbTab === t.id ? ' active' : ''),
          click: function () {
            Object.keys(tabEls).forEach(function (k) {
              tabEls[k].className   = 'cl-tab'   + (k === t.id ? ' active' : '');
              panelEls[k].className = 'cl-panel' + (k === t.id ? ' active' : '');
            });
            self._sbTab = t.id;
            rememberTab('clashoo.config.singbox.tab', t.id);
          }
        }, t.label);
        tabEls[t.id] = el;
        return el;
      })
    );

    var profilesPanel = E('div', { 'class': 'cl-panel' + (this._sbTab === 'profiles' ? ' active' : ''), id: 'cl-panel-profiles' },
      self._buildSbProfilesPanel(profiles, sbData.active || ''));
    panelEls['profiles'] = profilesPanel;

    var wizardPanel = E('div', { 'class': 'cl-panel' + (this._sbTab === 'wizard' ? ' active' : ''), id: 'cl-panel-wizard' },
      self._buildSbWizardPanel());
    panelEls['wizard'] = wizardPanel;

    return E('div', { 'class': 'cl-wrap clashoo-container cl-config-page cl-form-page ' + getThemeClass() }, [tabBar, profilesPanel, wizardPanel]);
  },

  _buildSbProfilesPanel: function (profiles, activeProfile) {
    var self = this;
    var safeText = function (v) { return (v == null || v === 'null') ? '' : String(v); };
    var formatJsonForEditor = function (content) {
      try {
        return JSON.stringify(JSON.parse(content || '{}'), null, 2) + '\n';
      } catch (e) {
        return content || '';
      }
    };

    /* ── JSON editor (initially hidden) ── */
    var editorTitle = E('span', { 'class': 'cl-editor-hdr' }, '选择上方配置后可在此处编辑');
    var textarea    = E('textarea', { 'class': 'cl-json-editor', placeholder: '选择配置文件后内容将显示在这里…' });
    var saveBtn = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      disabled: '',
      click: function () {
        var name = textarea.dataset.name;
        if (!name) return;
        clashoo.saveSingboxProfile(name, formatJsonForEditor(textarea.value)).then(function (r) {
          if (r.success) ui.addNotification(null, E('p', name + ' 已保存'));
          else ui.addNotification(null, E('p', '保存失败: ' + (r.message || r.error || '')));
        });
      }
    }, '保存');

    var migrateBtn = E('button', {
      'class': 'btn cbi-button cl-btn-sm',
      disabled: '',
      click: function () {
        var name = textarea.dataset.name;
        if (!name) return;
        L.resolveDefault(callMigrateSbProfile(name), {}).then(function (r) {
          if (r && r.success) {
            var msg = r.changes && r.changes.length ? '已修复废弃字段: ' + r.changes.join(', ') : '配置已是最新，无需修复';
            ui.addNotification(null, E('p', msg));
            /* 重新加载编辑器内容 */
            clashoo.getSingboxProfile(name).then(function (gr) { textarea.value = formatJsonForEditor(gr.content || ''); });
          } else {
            ui.addNotification(null, E('p', '修复失败: ' + ((r && r.message) || '')));
          }
        });
      }
    }, '修复废弃字段');

    var editorBox = E('div', { 'class': 'cl-section cl-card cl-sb-card cl-sb-editor' }, [
      editorTitle,
      textarea,
      E('div', { 'class': 'cl-actions cl-sb-row-actions cl-sb-editor-actions' }, [
        saveBtn,
        migrateBtn,
        E('span', { 'class': 'cl-hint' }, '编辑后点击保存；切换配置后服务将自动重启')
      ])
    ]);

    function loadEditor(name) {
      editorTitle.textContent = '编辑：' + name;
      saveBtn.removeAttribute('disabled');
      migrateBtn.removeAttribute('disabled');
      textarea.dataset.name = name;
      textarea.value = '加载中…';
      clashoo.getSingboxProfile(name).then(function (r) {
        textarea.value = formatJsonForEditor(r.content || '');
      });
    }

    /* ── Profile table ── */
    var rows = profiles.length
      ? profiles.map(function (p) {
          var nameCell = [
            E('div', { 'class': 'cl-sb-file-name' }, [
              p.active ? E('span', { 'class': 'cl-active-badge' }, '使用中') : '',
              E('span', { 'class': 'cl-file-name-text' }, safeText(p.name))
            ])
          ];
          var trafficEl = renderTrafficBar(p.sub_used, p.sub_total);
          var expireEl  = renderExpire(p.sub_expire);
          if (trafficEl) nameCell.push(trafficEl);
          if (expireEl)  nameCell.push(expireEl);
          return E('tr', {}, [
            E('td', {}, nameCell),
            E('td', { 'class': 'cl-sb-size' }, safeText(p.size) || '—'),
            E('td', {}, [
              E('div', { 'class': 'cl-sb-row-actions' }, [
              p.source !== 'native' ? E('button', {
                'class': 'btn cbi-button cl-btn-sm cl-btn-sb-action cl-btn-sb-edit',
                click: function () { loadEditor(p.name); }
              }, '编辑') : '',
              E('button', {
                'class': 'btn cbi-button-action cl-btn-sm cl-btn-sb-action cl-btn-sb-switch',
                click: function () {
                  clashoo.setSingboxProfile(p.name).then(function (r) {
                    ui.addNotification(null, E('p', r.success ? '已切换至 ' + p.name : ('切换失败: ' + (r.message || ''))));
                    if (r.success) location.reload();
                  });
                }
              }, '切换'),
              p.source === 'native' && p.sub_url ? E('button', {
                'class': 'btn cbi-button cl-btn-sm cl-btn-sb-action',
                click: function (ev) {
                  var btn = ev.currentTarget;
                  btn.disabled = true;
                  btn.textContent = '更新中…';
                  clashoo.updateSingboxNative(p.name).then(function (r) {
                    btn.disabled = false;
                    btn.textContent = '更新';
                    ui.addNotification(null, E('p', r.success ? (r.message || p.name + ' 已更新') : ('更新失败: ' + (r.message || ''))));
                    if (r.success) location.reload();
                  });
                }
              }, '更新') : '',
              E('button', {
                'class': 'btn cbi-button-negative cl-btn-sm cl-btn-sb-action cl-btn-sb-delete',
                click: function () {
                  if (!confirm('删除 ' + p.name + '？')) return;
                  clashoo.deleteSingboxProfile(p.name).then(function () { location.reload(); });
                }
              }, '删除')
              ])
            ])
          ]);
        })
      : [E('tr', {}, [E('td', { 'class': 'cl-sb-empty', colspan: '3' }, '暂无配置文件，请使用快速向导生成或上传 JSON 文件')])];

    /* ── Upload ── */
    var uploadInput = E('input', { type: 'file', accept: '.json', style: 'display:none', id: 'sb-upload' });
    uploadInput.addEventListener('change', function (ev) {
      var file = ev.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        clashoo.saveSingboxProfile(file.name, e.target.result).then(function (r) {
          if (r.success) { ui.addNotification(null, E('p', '上传成功: ' + r.name)); location.reload(); }
          else ui.addNotification(null, E('p', '上传失败: ' + (r.message || r.error || '')));
        });
      };
      reader.readAsText(file);
    });

    return [
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, 'sing-box 配置文件'),
        E('table', { 'class': 'cl-sub-list cl-sb-list' }, [
          E('thead', {}, E('tr', {}, [E('th', {}, '文件名'), E('th', {}, '大小'), E('th', {}, '操作')])),
          E('tbody', {}, rows)
        ]),
        uploadInput,
        E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [
          E('button', {
            'class': 'btn cbi-button-add cl-btn-sm cl-btn-sb-upload',
            click: function () { document.getElementById('sb-upload').click(); }
          }, '上传 JSON 配置')
        ])
      ]),
      editorBox
    ];
  },

  _buildSbWizardPanel: function () {
    var urlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '粘贴订阅链接（支持 vmess / vless / trojan 等）'
    });
    var nameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '配置文件名（选填，留空自动生成 singbox.json）',
      style: 'margin-top:0'
    });
    var secretInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: 'API 密钥（选填，留空使用当前面板密码）',
      style: 'margin-top:0'
    });

    var genBtn, applyBtn;
    function setBusy(busy) {
      [genBtn, applyBtn].forEach(function (b) {
        if (!b) return;
        b.disabled = busy ? '' : null;
        if (busy) {
          if (!b.dataset.label) b.dataset.label = b.textContent;
          b.textContent = '生成中…';
        } else if (b.dataset.label) {
          b.textContent = b.dataset.label;
        }
      });
    }
    function doCreate(setActive) {
      var url = urlInput.value.trim();
      if (!url) { ui.addNotification(null, E('p', '请填写订阅链接')); return; }
      setBusy(true);
      clashoo.createSingboxConfig(url, nameInput.value.trim(), secretInput.value.trim())
        .then(function (r) {
          /* RPC 超时被 resolveDefault 兜底成 {}，r.success 是 undefined。
           * 此时后端可能仍在跑（yaml2singbox 转 90 节点等），让用户直接刷新页
           * 看实际产物，而不是误报"失败"。 */
          if (!r || typeof r.success === 'undefined') {
            ui.addNotification(null, E('p', '生成时间较长，正在刷新查看结果…'));
            setTimeout(function () { location.reload(); }, 1500);
            return;
          }
          if (!r.success) {
            setBusy(false);
            ui.addNotification(null, E('p', '生成失败: ' + (r.message || '')));
            return;
          }
          if (setActive) {
            return clashoo.setSingboxProfile(r.name).then(function () {
              ui.addNotification(null, E('p', r.message + '，已切换为活动配置'));
              location.reload();
            });
          }
          ui.addNotification(null, E('p', r.message));
          location.reload();
        }).catch(function (e) {
          setBusy(false);
          ui.addNotification(null, E('p', '生成异常: ' + (e && e.message || e)));
        });
    }

    genBtn   = E('button', { 'class': 'btn cbi-button cl-btn-sm',        click: function () { doCreate(false); } }, '生成配置');
    applyBtn = E('button', { 'class': 'btn cbi-button-action cl-btn-sm', click: function () { doCreate(true);  } }, '应用配置');

    /* ── native sing-box subscription card ── */
    var nativeUrlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '粘贴原生 sing-box 订阅链接（直接返回 JSON 的链接）'
    });
    var nativeNameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: '文件名（选填，留空自动命名）',
      style: 'margin-top:0'
    });

    var fetchBtn, fetchApplyBtn;
    function setNativeBusy(busy) {
      [fetchBtn, fetchApplyBtn].forEach(function (b) {
        if (!b) return;
        b.disabled = busy ? '' : null;
        if (busy) {
          if (!b.dataset.label) b.dataset.label = b.textContent;
          b.textContent = '拉取中…';
        } else if (b.dataset.label) {
          b.textContent = b.dataset.label;
        }
      });
    }
    function doFetchNative(setActive) {
      var url = nativeUrlInput.value.trim();
      if (!url) { ui.addNotification(null, E('p', '请填写订阅链接')); return; }
      setNativeBusy(true);
      clashoo.fetchSingboxNative(url, nativeNameInput.value.trim())
        .then(function (r) {
          setNativeBusy(false);
          if (!r || typeof r.success === 'undefined') {
            ui.addNotification(null, E('p', '拉取超时，请刷新页面查看结果'));
            setTimeout(function () { location.reload(); }, 1500);
            return;
          }
          if (!r.success) {
            ui.addNotification(null, E('p', '拉取失败: ' + (r.message || '')));
            return;
          }
          if (setActive) {
            return clashoo.setSingboxProfile(r.name).then(function () {
              ui.addNotification(null, E('p', r.message + '，已切换为活动配置'));
              location.reload();
            });
          }
          ui.addNotification(null, E('p', r.message));
          location.reload();
        }).catch(function (e) {
          setNativeBusy(false);
          ui.addNotification(null, E('p', '拉取异常: ' + (e && e.message || e)));
        });
    }

    fetchBtn      = E('button', { 'class': 'btn cbi-button cl-btn-sm',        click: function () { doFetchNative(false); } }, '拉取配置');
    fetchApplyBtn = E('button', { 'class': 'btn cbi-button-action cl-btn-sm', click: function () { doFetchNative(true);  } }, '拉取并应用');

    return [
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, '节点订阅'),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600 cl-sb-form' }, [
          nativeUrlInput, nativeNameInput,
          E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [
            fetchBtn,
            fetchApplyBtn
          ])
        ]),
        E('p', { 'class': 'cl-sb-note' },
          '适用于机场直接提供 sing-box JSON 格式订阅、或已用外部工具转换好的链接。\n' +
          '拉取后可在「配置文件」标签的对应条目点击「更新」重新拉取最新配置。'
        )
      ]),
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, 'YAML 订阅转换'),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600 cl-sb-form' }, [
          urlInput, nameInput, secretInput,
          E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [
            genBtn,
            applyBtn
          ])
        ]),
        E('p', { 'class': 'cl-sb-note' },
          '将 YAML 订阅转换为 sing-box JSON，自动注入 TUN 透明代理与大陆直连规则。同名文件直接覆盖，更新时填相同名称即可。'
        )
      ])
    ];
  },

  handleSaveApply: null,
  handleSave:      null,
  handleReset:     null
});
