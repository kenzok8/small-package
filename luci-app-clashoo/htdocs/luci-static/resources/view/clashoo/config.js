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
  '.cl-wrap{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif;--cl-card-border:rgba(128,128,128,.22);--cl-card-bg:rgba(128,128,128,.08);--cl-card-shadow:0 4px 12px rgba(0,0,0,.08);--cl-muted:rgba(74,85,104,.9);--cl-meta:var(--cl-muted);--cl-primary:rgba(0,122,255,.8);--cl-primary-border:rgba(0,122,255,.45);--cl-primary-soft:rgba(0,122,255,.08)}',
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
  '.cl-sub-schedule{display:flex;flex-direction:column;gap:5px;max-width:760px;box-sizing:border-box;margin:2px 0 14px;padding:8px 2px 4px 6px}',
  '.cl-sub-schedule-row{display:flex;align-items:center;gap:10px;flex-wrap:nowrap}',
  '.cl-sub-schedule-toggle{display:inline-flex;align-items:center;gap:8px;height:30px;font-size:13px;font-weight:600;line-height:30px;cursor:pointer;white-space:nowrap}',
  '.cl-sub-schedule-toggle input[type="checkbox"]{appearance:none!important;-webkit-appearance:none!important;position:static!important;top:auto!important;bottom:auto!important;width:16px!important;height:16px!important;min-width:16px!important;min-height:16px!important;margin:0!important;padding:0!important;border:1px solid rgba(128,128,128,.7)!important;border-radius:3px!important;background:transparent!important;box-shadow:none!important;vertical-align:middle!important;flex:0 0 16px}',
  '.cl-sub-schedule-toggle input[type="checkbox"]:checked{border-color:var(--cl-primary)!important;background:var(--cl-primary) url("data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 16 16%27%3E%3Cpath fill=%27none%27 stroke=%27white%27 stroke-width=%272.2%27 d=%27M3 8l3 3 7-7%27/%3E%3C/svg%3E") center/12px 12px no-repeat!important}',
  '.cl-sub-schedule-status{font-size:11px;color:var(--cl-meta);line-height:1.45}',
  '.cl-sub-schedule-interval{display:inline-flex;align-items:center;gap:6px;height:30px;font-size:12px;line-height:30px;color:var(--cl-meta);white-space:nowrap}',
  '.cl-sub-schedule-interval input[type="number"]{width:52px!important;height:30px!important;min-height:30px!important;box-sizing:border-box!important;margin:0!important;padding:2px 6px!important;line-height:24px!important;text-align:center}',
  '.cl-sub-schedule-row .btn,.cl-sub-schedule-row .cbi-button{height:30px!important;min-height:30px!important;box-sizing:border-box!important;padding:3px 10px!important;line-height:22px!important}',
  '.cl-sub-schedule-row :disabled{cursor:not-allowed;opacity:.62}',
  '.cl-section-toggle{font-size:12px;cursor:pointer;flex-shrink:0;margin-left:auto}',
  '.cl-collapsible.cl-closed>*:not(h3){display:none!important}',
  /* 折叠标题：通过 .clashoo-section-header wrapper class 上色，不裸改 LuCI 默认 h3 样式 */
  '.clashoo-section-header{display:flex!important;align-items:center;gap:8px;position:relative}',
  '.clashoo-section-header::before{content:"";flex:0 0 3px;width:3px;height:14px;border-radius:2px;background:var(--primary-color,var(--cl-primary,#007aff))}',
  '.cl-wrap .cbi-section-remove.right{background:transparent!important}',
  '.cl-json-editor{width:100%;height:340px;font-family:monospace;font-size:11px;border:1px solid rgba(128,128,128,.25);border-radius:8px;padding:10px;box-sizing:border-box;resize:vertical;background:rgba(0,0,0,.02)}',
  '.cl-editor-hdr{display:flex;align-items:center;gap:8px;margin-bottom:6px;font-size:12px;font-weight:600}',
  /* CodeMirror 编辑器外观（小文件套 CM，大文件回退 cl-json-editor textarea）*/
  '.cl-cm-wrap{width:100%}',
  '.cl-cm-host .CodeMirror{height:340px;border:1px solid rgba(128,128,128,.25);border-radius:8px;font-size:12px;font-family:monospace}',
  '.cl-cm-host.cl-cm-dark .CodeMirror{background:#1e2228;color:#d4d4d4}',
  '.cl-cm-host.cl-cm-dark .CodeMirror-gutters{background:#23282f;border-right:1px solid rgba(255,255,255,.08)}',
  '.cl-cm-host.cl-cm-dark .CodeMirror-linenumber{color:#5c6370}',
  '.cl-cm-host.cl-cm-dark .CodeMirror-cursor{border-left-color:#d4d4d4}',
  '.cl-cm-host.cl-cm-dark .CodeMirror-selected{background:rgba(255,255,255,.12)}',
  '.cl-cm-host.cl-cm-dark .CodeMirror-activeline-background{background:rgba(255,255,255,.04)}',
  '.cl-cm-host.cl-cm-dark .cm-string{color:#ce9178}',
  '.cl-cm-host.cl-cm-dark .cm-number{color:#b5cea8}',
  '.cl-cm-host.cl-cm-dark .cm-keyword,.cl-cm-host.cl-cm-dark .cm-atom{color:#569cd6}',
  '.cl-cm-host.cl-cm-dark .cm-property,.cl-cm-host.cl-cm-dark .cm-attribute{color:#9cdcfe}',
  '.cl-cm-host.cl-cm-dark .cm-comment{color:#6a9955}',
  '.cl-cm-host.cl-cm-dark .cm-meta,.cl-cm-host.cl-cm-dark .cm-def{color:#dcdcaa}',
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
  '@media(max-width:680px){.cl-dns-auto,.cl-dns-auto-result{max-width:100%;width:100%;box-sizing:border-box}.cl-dns-auto-result{grid-template-columns:1fr}}',
  '@media(max-width:680px){.cl-sub-schedule{width:100%;padding:8px 0 4px 4px}.cl-sub-schedule-row{gap:8px;flex-wrap:wrap}.cl-sub-schedule-toggle{width:100%}.cl-sub-schedule-interval{gap:5px}.cl-sub-schedule-row .cbi-button-action{white-space:nowrap}}'
].join('');

var callListSubs      = rpc.declare({ object: 'luci.clashoo', method: 'list_subscriptions',  expect: {} });
var callListDir       = rpc.declare({ object: 'luci.clashoo', method: 'list_dir_files',      params: ['type'], expect: {} });
var callDownloadSubs  = rpc.declare({ object: 'luci.clashoo', method: 'download_subs',       expect: {} });
var callDownloadSubsStatus = rpc.declare({ object: 'luci.clashoo', method: 'download_subs_status', expect: {} });
var callUpdateSub     = rpc.declare({ object: 'luci.clashoo', method: 'update_sub',          params: ['name'], expect: {} });
var callSubscriptionUpdateAll = rpc.declare({ object: 'luci.clashoo', method: 'subscription_update_all', expect: {} });
var callSubscriptionUpdateStatus = rpc.declare({ object: 'luci.clashoo', method: 'subscription_update_status', expect: {} });
var callSetSubscriptionUpdateSchedule = rpc.declare({ object: 'luci.clashoo', method: 'set_subscription_update_schedule', params: ['enabled', 'interval'], expect: {} });
var callSetConfig     = rpc.declare({ object: 'luci.clashoo', method: 'set_config',          params: ['name'], expect: {} });
var callDeleteCfg     = rpc.declare({ object: 'luci.clashoo', method: 'delete_config',       params: ['name', 'type'], expect: {} });
var callUploadConfigChunk = rpc.declare({ object: 'luci.clashoo', method: 'upload_config_chunk', params: ['name', 'content', 'type', 'index', 'total'], expect: {} });
var callReadOtherConfig = rpc.declare({ object: 'luci.clashoo', method: 'read_other_config',  params: ['name', 'type'], expect: {} });
var callListTemplates = rpc.declare({ object: 'luci.clashoo', method: 'list_templates',      expect: {} });
var callUploadTemplate= rpc.declare({ object: 'luci.clashoo', method: 'upload_template',     params: ['name', 'content'], expect: {} });
var callApplyRewrite  = rpc.declare({ object: 'luci.clashoo', method: 'apply_rewrite',          params: ['base_type','base_name','rewrite_type','rewrite_name','output_name','set_active'], expect: {} });
var callFetchUrl      = rpc.declare({ object: 'luci.clashoo', method: 'fetch_rewrite_url',      params: ['url','name'], expect: {} });
var callApplyTplUrl   = rpc.declare({ object: 'luci.clashoo', method: 'apply_template_with_url', params: ['template_source','sub_url','output_name','set_active'], expect: {} });
var callMigrateSbProfile = rpc.declare({ object: 'luci.clashoo', method: 'migrate_singbox_profile', params: ['name'], expect: {} });
var callSmartModelStatus = rpc.declare({ object: 'luci.clashoo', method: 'smart_model_status',  expect: {} });
var callSmartUpgradeLgbm = rpc.declare({ object: 'luci.clashoo', method: 'smart_upgrade_lgbm',  expect: {} });
var callSmartUpgradeLgbmStatus = rpc.declare({ object: 'luci.clashoo', method: 'smart_upgrade_lgbm_status', expect: {} });
var callSmartFlushCache  = rpc.declare({ object: 'luci.clashoo', method: 'smart_flush_cache',   expect: {} });
var callDetectPrimaryGroup = rpc.declare({ object: 'luci.clashoo', method: 'detect_primary_group', expect: {} });

function fastResolve(promise, timeoutMs, fallback) {
  var t = new Promise(function (resolve) {
    setTimeout(function () { resolve(fallback); }, timeoutMs);
  });
  return Promise.race([L.resolveDefault(promise, fallback), t]);
}

function uploadConfigContent(name, content, type) {
  var chunkSize = 24576;
  var total = Math.max(1, Math.ceil((content || '').length / chunkSize));
  var index = 0;

  function sendNext() {
    var chunk = (content || '').slice(index * chunkSize, (index + 1) * chunkSize);
    return L.resolveDefault(callUploadConfigChunk(name, chunk, type || '2', index, total), {}).then(function (r) {
      if (!r || !r.success)
        throw new Error((r && (r.message || r.error)) || _("Upload failed"));
      index++;
      return index < total ? sendNext() : r;
    });
  }

  return sendNext();
}

function loadUiState() {
  return L.resolveDefault(uci.load('clashoo'), null).then(function () {
    return {
      core_type:      uci.get('clashoo', 'config', 'core_type') || 'mihomo',
      subscribe_url:  uci.get('clashoo', 'config', 'subscribe_url') || '',
      config_name:    uci.get('clashoo', 'config', 'config_name') || '',
      sub_ua:         uci.get('clashoo', 'config', 'sub_ua') || '',
      auto_subscription_update: uci.get('clashoo', 'config', 'auto_subscription_update') || '0',
      subscription_update_interval: uci.get('clashoo', 'config', 'subscription_update_interval') || '72'
    };
  });
}

function buildSubscriptionSchedule(uiData, initialStatus) {
  var enabled = E('input', {
    type: 'checkbox',
    checked: uiData.auto_subscription_update === '1' ? '' : null
  });
  var interval = E('input', {
    type: 'number',
    min: '1',
    max: '8760',
    value: uiData.subscription_update_interval || '72'
  });
  var statusEl = E('div', { 'class': 'cl-sub-schedule-status' });
  var saveBtn, runBtn, timer;

  function syncScheduleState() {
    interval.disabled = !enabled.checked;
  }

  enabled.addEventListener('change', syncScheduleState);

  function renderStatus(st) {
    st = st || {};
    if (st.running) {
      statusEl.textContent = _("Updating all subscriptions…");
      return;
    }
    if (!st.last_run) {
      statusEl.textContent = _("Only subscriptions with recorded source URLs are overwritten; no duplicate files are created.");
      return;
    }
    var when = new Date(st.last_run * 1000).toLocaleString();
    statusEl.textContent = _("Last run: ") + when + _("; updated ") + (st.updated || 0) +
      _(", unchanged ") + (st.unchanged || 0) + _(", failed ") + (st.failed || 0) +
      _(", skipped ") + (st.skipped || 0) + '.';
  }

  function pollStatus() {
    L.resolveDefault(callSubscriptionUpdateStatus(), {}).then(function (st) {
      renderStatus(st);
      if (!st.running) {
        if (timer) clearInterval(timer);
        timer = null;
        runBtn.disabled = false;
        runBtn.textContent = _("Update All Now");
      }
    });
  }

  saveBtn = E('button', {
    'class': 'btn cbi-button cl-btn-sm',
    click: function () {
      var hours = parseInt(interval.value, 10);
      if (!hours || hours < 1 || hours > 8760) {
        ui.addNotification(null, E('p', _("Update interval must be 1 to 8760 hours")));
        return;
      }
      saveBtn.disabled = true;
      L.resolveDefault(callSetSubscriptionUpdateSchedule(enabled.checked ? '1' : '0', String(hours)), {}).then(function (r) {
        saveBtn.disabled = false;
        ui.addNotification(null, E('p', r && r.success ? _("Scheduled update settings saved") : (_("Save failed: ") + ((r && r.message) || ''))));
      });
    }
  }, _("Save"));

  runBtn = E('button', {
    'class': 'btn cbi-button-action cl-btn-sm',
    click: function () {
      runBtn.disabled = true;
      runBtn.textContent = _("Updating…");
      L.resolveDefault(callSubscriptionUpdateAll(), {}).then(function (r) {
        if (!r || (!r.success && !r.running)) {
          runBtn.disabled = false;
          runBtn.textContent = _("Update All Now");
          ui.addNotification(null, E('p', _("Start failed: ") + ((r && r.message) || '')));
          return;
        }
        renderStatus({ running: true });
        timer = setInterval(pollStatus, 2000);
        setTimeout(pollStatus, 500);
      });
    }
  }, _("Update All Now"));

  syncScheduleState();
  renderStatus(initialStatus);
  return E('div', { 'class': 'cl-sub-schedule' }, [
    E('div', { 'class': 'cl-sub-schedule-row' }, [
      E('label', { 'class': 'cl-sub-schedule-toggle' }, [enabled, E('span', {}, _("Scheduled Subscription Update"))]),
      E('div', { 'class': 'cl-sub-schedule-interval' }, [
        E('span', {}, _("Every")),
        interval,
        E('span', {}, _("hours"))
      ]),
      saveBtn,
      runBtn
    ]),
    statusEl
  ]);
}

var SUB_UA_PRESETS = ['', 'clash', 'clash.meta', 'mihomo'];

// 构造 UA 选择器：select 预设 + custom 切到 input
// 返回 { wrap, getValue() }
function buildUaPicker(initialValue) {
  var presets   = SUB_UA_PRESETS;
  var isPreset  = presets.indexOf(initialValue) !== -1;
  var customVal = (!initialValue || isPreset) ? '' : initialValue;
  var pickerVal = isPreset ? initialValue : (initialValue ? '__custom__' : '');

  var customInput = E('input', {
    'class': 'cl-sub-url',
    type: 'text',
    placeholder: _("Custom User-Agent"),
    value: customVal,
    style: 'margin-top:0;' + (pickerVal === '__custom__' ? '' : 'display:none')
  });

  var selectEl = E('select', {
    'class': 'cbi-input-select cl-sub-url',
    style: 'margin-top:0',
    change: function (ev) {
      customInput.style.display = (ev.target.value === '__custom__') ? '' : 'none';
      if (ev.target.value === '__custom__') customInput.focus();
    }
  }, [
    E('option', { value: '',           selected: pickerVal === ''           ? '' : null }, _("Default")),
    E('option', { value: 'clash',      selected: pickerVal === 'clash'      ? '' : null }, 'clash'),
    E('option', { value: 'clash.meta', selected: pickerVal === 'clash.meta' ? '' : null }, 'clash.meta'),
    E('option', { value: 'mihomo',     selected: pickerVal === 'mihomo'     ? '' : null }, 'mihomo'),
    E('option', { value: '__custom__', selected: pickerVal === '__custom__' ? '' : null }, _("Customize..."))
  ]);

  return {
    wrap: E('div', { 'class': 'cl-ua-picker', style: 'display:flex;flex-direction:column;gap:6px;margin-top:0' }, [
      E('label', { style: 'font-size:12px;color:var(--text-secondary, #888)' }, _("User-Agent (UA)")),
      selectEl, customInput,
      E('div', { style: 'font-size:12px;color:var(--text-secondary, #888)' }, _("Keep the default if unsure."))
    ]),
    getValue: function () {
      return selectEl.value === '__custom__' ? customInput.value.trim() : selectEl.value;
    }
  };
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
    _("Expires: ") + fmtExpireDate(ts) + (daysLeft > 0 ? ' (' + daysLeft + _(" days)") : _(" (expired)")));
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
      /* silent=true so the caller's catch reports validation errors once (no double popup) */
      return m.save(null, true)
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
    return E('div', { 'class': 'cl-dns-auto-status' }, _("No auto setup result yet"));
  var elapsed = Math.max(0, parseInt(res.elapsed_ms || 0, 10));
  var failed = parseInt(res.failed_count || 0, 10);
  return E('div', { 'class': 'cl-dns-auto-result' }, [
    E('span', [E('b', _("Domestic")), res.nameserver || '-']),
    E('span', [E('b', _("Proxy")), res.proxy_nameserver || '-']),
    E('span', [E('b', 'Fallback'), res.fallback || '-']),
    E('span', [E('b', 'Bootstrap'), res.bootstrap || res.direct_nameserver || '-']),
    E('span', [E('b', _("Time")), elapsed ? (elapsed / 1000).toFixed(1) + _(" seconds") : '-']),
    E('span', [E('b', _("Failed")), failed + _(" candidates")])
  ]);
}

function dnsAutoResultMessage(res) {
  if (!res || !res.success)
    return (res && res.message) || _("DNS auto setup failed");
  return res.restarted
    ? _("DNS auto setup applied, service is restarting")
    : _("DNS auto setup saved, service is not running");
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
      btn.textContent = section.classList.contains('cl-closed') ? _("Expand") : _("Collapse");
    }
  }, open ? _("Collapse") : _("Expand"));
  var h3 = section.querySelector('h3');
  if (h3) {
    h3.classList.add('clashoo-section-header');
    h3.appendChild(btn);
  }
}

/* ── CodeMirror 懒加载（资源打包在 luci-static/resources/cm/）── */
var _cmLoad = null;
function loadCodeMirror() {
  if (_cmLoad) return _cmLoad;
  _cmLoad = new Promise(function (resolve, reject) {
    var base = L.resource('cm'), ver = '?v=20260520';
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = base + '/codemirror.css' + ver;
    document.head.appendChild(link);
    var inject = function (src) {
      return new Promise(function (res, rej) {
        var s = document.createElement('script');
        s.src = src; s.async = false;
        s.onload = res;
        s.onerror = function () { rej(new Error('load failed: ' + src)); };
        document.head.appendChild(s);
      });
    };
    /* 核心先就位，mode/addon 注册在全局 CodeMirror 上 */
    inject(base + '/codemirror.js' + ver)
      .then(function () {
        return Promise.all([
          inject(base + '/mode/yaml.js' + ver),
          inject(base + '/mode/javascript.js' + ver),
          inject(base + '/addon/matchbrackets.js' + ver)
        ]);
      })
      .then(function () {
        if (window.CodeMirror) resolve();
        else reject(new Error('CodeMirror not available'));
      })
      .catch(reject);
  });
  return _cmLoad;
}

/* CodeMirror for files ≤512KB; fallback to textarea for oversized or failed load */
function createConfigEditor(mode) {
  var LARGE = 512 * 1024;
  var ta = E('textarea', {
    'class': 'cl-json-editor',
    placeholder: _("Configuration content appears here after selecting a file…")
  });
  var host = E('div', { 'class': 'cl-cm-host', style: 'display:none' });
  var wrap = E('div', { 'class': 'cl-cm-wrap' }, [host, ta]);
  var cm = null, usingCM = false;

  function showTextarea(content) {
    usingCM = false;
    ta.value = content;
    ta.style.display = '';
    host.style.display = 'none';
  }
  function showCM(content) {
    usingCM = true;
    cm.setValue(content);
    ta.style.display = 'none';
    host.style.display = '';
    setTimeout(function () { cm.refresh(); }, 0);
  }

  return {
    el: wrap,
    textarea: ta,
    setValue: function (content) {
      content = (content == null) ? '' : String(content);
      if (content.length > LARGE) { showTextarea(content); return; }
      if (cm) { showCM(content); return; }
      loadCodeMirror().then(function () {
        if (!cm && window.CodeMirror) {
          cm = window.CodeMirror(host, {
            value: '', mode: mode,
            lineNumbers: true, matchBrackets: true,
            lineWrapping: true, tabSize: 2, indentUnit: 2,
            viewportMargin: 60
          });
          if (getThemeClass().indexOf('dark') >= 0)
            host.classList.add('cl-cm-dark');
        }
        if (cm) showCM(content); else showTextarea(content);
      }).catch(function () { showTextarea(content); });
    },
    getValue: function () {
      return (usingCM && cm) ? cm.getValue() : ta.value;
    }
  };
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
      fastResolve(loadUiState(), 1200, { core_type: 'mihomo', subscribe_url: '', config_name: '', sub_ua: '' }),
      fastResolve(clashoo.listSingboxProfiles(), 1200, { profiles: [], active: '' }),
      fastResolve(callSmartModelStatus(), 1500, { has_model: false, version: '' }),
      fastResolve(callSubscriptionUpdateStatus(), 1200, {})
    ]);
  },

  render: function (data) {
    var self       = this;
    var subsData   = data[0] || {};
    var subFiles   = (data[1] && data[1].files) || [];
    var upFiles    = (data[2] && data[2].files) || [];
    var customFiles= (data[3] && data[3].files) || [];
    var tplFiles   = (data[4] && data[4].files) || [];
    var uiData     = data[5] || { core_type: 'mihomo', subscribe_url: '', config_name: '', sub_ua: '' };
    var sbData          = data[6] || { profiles: [], active: '' };
    var smartModelData  = data[7] || { has_model: false, version: '' };
    var subscriptionUpdateStatus = data[8] || {};
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
      link.href = L.resource('view/clashoo/clashoo.css') + '?v=20260609b1';
      document.head.appendChild(link);
    } else {
      document.getElementById('cl-css-ext').href = L.resource('view/clashoo/clashoo.css') + '?v=20260609b1';
    }

    if (coreType === 'singbox') return this._renderSingbox(sbData, uiData, subscriptionUpdateStatus);

    var tabs = [
      { id: 'subs', label: _("Subscription") },
      { id: 'proxy', label: _("Proxy") },
      { id: 'dns',   label: 'DNS' }
    ];
    var allowedTabs = tabs.map(function (t) { return t.id; });
    this._tab = readSavedTab('clashoo.config.tab', this._tab || 'subs', allowedTabs);
    rememberTab('clashoo.config.tab', this._tab);
    var tabEls   = {};
    var panelEls = {};

    var subPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'subs' ? ' active' : ''), id: 'cl-panel-subs' },
      this._buildSubsPanel(subsData, subFiles, upFiles, customFiles, tplFiles, uiData, subscriptionUpdateStatus)
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

  _buildSubsPanel: function (subsData, subFiles, upFiles, customFiles, tplFiles, uiData, subscriptionUpdateStatus) {
    var self = this;
    var sanitizeText = function (v) { return (v == null || v === 'null') ? '' : String(v); };
    var subUrl      = sanitizeText(uiData && uiData.subscribe_url);
    var savedName   = sanitizeText(uiData && uiData.config_name);
    var savedUa     = sanitizeText(uiData && uiData.sub_ua);
    var subs        = subsData.subs || [];
    var safeText    = function (v) { return (v == null || v === 'null') ? '' : String(v); };

    var urlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("Subscription URLs (one per line)"),
      value: subUrl
    });

    var nameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("File name (optional, blank to auto-generate)"),
      value: savedName,
      style: 'margin-top:0'
    });

    var uaPicker = buildUaPicker(savedUa);

    var dlStatusEl = E('div', { 'class': 'cl-update-status', style: 'margin-top:6px;font-size:12px;min-height:18px;line-height:1.4' });
    var setDlStatus = function (text, tone) {
      dlStatusEl.textContent = text || '';
      dlStatusEl.style.color = tone === 'success' ? 'var(--success-color, #2e7d32)'
                             : tone === 'error'   ? 'var(--error-color, #d32f2f)'
                             : tone === 'progress'? 'var(--tip-color, #1976d2)'
                             : '';
    };
    var stopDlPoll = function () {
      if (self._subDlTimer) { clearInterval(self._subDlTimer); self._subDlTimer = null; }
    };

    var dlBtn = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      click: function () {
        if (!urlInput.value.trim()) {
          setDlStatus(_("✗ Please enter a subscription URL first"), 'error');
          setTimeout(function () { setDlStatus(''); }, 4000);
          return;
        }
        stopDlPoll();
        dlBtn.disabled = true;
        dlBtn.textContent = _("Downloading…");
        setDlStatus(_("⏳ Submitting download task..."), 'progress');

        var pollCount = 0;
        var pollDl = function () {
          pollCount++;
          callDownloadSubsStatus().then(function (st) {
            st = st || {};
            var raw  = st.last_line || '';
            var line = clashoo.localizeLogLine(raw);
            if (st.running) {
              setDlStatus('⏳ ' + (line || _("Downloading subscription...")), 'progress');
              return;
            }
            /* sh has not flushed yet, wait a few polls */
            if (!raw && pollCount < 4) return;
            stopDlPoll();
            /* 收尾行只有三种：「订阅下载完成：成功 N 个，失败 M 个」=成功（含"失败 0 个"
               字样，不能按"失败"判负）；「订阅下载失败：全部链接失败」「未找到订阅链接」=失败 */
            var ok = /下载完成|completed/i.test(raw);
            /* fail_detail carries the real cause（rc=/HTTP/校验失败）：
               all fail: show real cause; partial: summary + cause */
            var detail = st.fail_detail ? clashoo.localizeLogLine(st.fail_detail) : '';
            var shown = ok ? (line + (detail ? ' · ' + detail : ''))
                           : (detail || line || _("Subscription download failed"));
            dlBtn.disabled = false;
            dlBtn.textContent = _("Download Subscription");
            setDlStatus((ok ? '✓ ' : '✗ ') + shown, ok ? 'success' : 'error');
            setTimeout(function () { location.reload(); }, 1200);
          }).catch(function () {});
        };

        L.resolveDefault(uci.load('clashoo'), null)
          .then(function () {
            uci.set('clashoo', 'config', 'subscribe_url', urlInput.value);
            uci.set('clashoo', 'config', 'config_name',   nameInput.value.trim());
            uci.set('clashoo', 'config', 'sub_ua',        uaPicker.getValue());
            return uci.save();
          })
          .then(function () { return clashoo.commitConfig(); })
          .then(function () { return clearClashooDirty(); })
          .then(function () { return L.resolveDefault(callDownloadSubs(), {}); })
          .then(function (r) {
            if (r && r.running) setDlStatus(_("⏳ A download task is already running..."), 'progress');
            self._subDlTimer = setInterval(pollDl, 2000);
            setTimeout(pollDl, 800);
          })
          .catch(function (e) {
            stopDlPoll();
            dlBtn.disabled = false;
            dlBtn.textContent = _("Download Subscription");
            setDlStatus(_("✗ Start failed: ") + (e && e.message || e), 'error');
          });
      }
    }, _("Download Subscription"));

    var subCards = subs.map(function (sub) {
      var nameNodes = [];
      if (sub.active) nameNodes.push(E('span', { 'class': 'cl-active-badge' }, _("Active")));
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
                ui.addNotification(null, E('p', r.success ? sub.name + _(" update succeeded") : _("Update failed")));
                location.reload();
              });
            }
          }, _("Update")),
          E('button', {
            'class': 'btn cbi-button cl-btn-sm cl-btn-switch',
            click: function () {
              L.resolveDefault(callSetConfig(sub.name), {}).then(function () { location.reload(); });
            }
          }, _("Switch")),
          E('button', {
            'class': 'btn cbi-button cl-btn-sm cl-btn-delete',
            click: function () {
              if (!confirm(_("Delete ") + sub.name + '?')) return;
              L.resolveDefault(callDeleteCfg(sub.name, '1'), {}).then(function () { location.reload(); });
            }
          }, _("Delete"))
        ])
      ]);
    });

    var uploadInput = E('input', { type: 'file', accept: '.yaml,.yml', style: 'display:none', id: 'cl-upload-input' });
    uploadInput.addEventListener('change', function (ev) {
      var file = ev.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        uploadConfigContent(file.name, e.target.result, '2').then(function (r) {
          ui.addNotification(null, E('p', _("Upload succeeded: ") + r.name));
          location.reload();
        }).catch(function (err) {
          ui.addNotification(null, E('p', _("Upload failed: ") + (err && err.message ? err.message : err)));
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
    var tplSel     = mkSel(tplFiles, _("Select local template file"));
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
            ui.addNotification(null, E('p', _("Template uploaded: ") + (r.name || file.name)));
            location.reload();
            return;
          }
          ui.addNotification(null, E('p', _("Template upload failed: ") + ((r && (r.message || r.error)) || _("Unknown error"))));
        });
      };
      reader.readAsText(file);
    });

    var tplUrlIn   = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: _("Enter remote template URL, e.g. https://raw.githubusercontent.com/…/Clash.yaml") });
    var subUrlIn   = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: _("Enter subscription URL (injected into template proxy-providers)") });
    var outNameIn  = E('input', { type: 'text', 'class': 'cl-sub-url', placeholder: _("Output file name (without extension, blank to auto-fill)") });
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
        }, _("Upload YAML Template"))
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
    }, _("Local Template"));
    var tabRemote = E('button', { 'class': 'btn cbi-button cl-btn-sm',
      click: function () {
        rwMode = 'remote';
        localPanel.style.display  = 'none'; remotePanel.style.display = '';
        tabRemote.classList.add('cl-mode-tab-active');
        tabLocal.classList.remove('cl-mode-tab-active');
        outNameIn.value = '';
      }
    }, _("Remote Template"));

    var rwApply = function (setActive) {
      var tplSrc = rwMode === 'local' ? tplSel.value : tplUrlIn.value.trim();
      var subUrl = subUrlIn.value.trim();
      var out    = outNameIn.value.trim();
      if (!tplSrc) { ui.addNotification(null, E('p', rwMode === 'local' ? _("Please select a local template file") : _("Please enter a remote template URL"))); return; }
      if (!subUrl) { ui.addNotification(null, E('p', _("Please enter a subscription URL"))); return; }
      if (!out)    { ui.addNotification(null, E('p', _("Please enter an output file name"))); return; }
      L.resolveDefault(callApplyTplUrl(tplSrc, subUrl, out, setActive ? '1' : '0'), {}).then(function (r) {
        ui.addNotification(null, E('p', r && r.success ? (r.message || _("Generated: ") + r.output_name) : (_("Generate failed: ") + (r && r.message || _("Unknown error")))));
        if (r && r.success) location.reload();
      });
    };

    /* ── 其他配置文件（上传 + 自定义/复写输出）── */
    var otherEditorTitle    = E('span', { 'class': 'cl-editor-hdr' }, _("Select a configuration above to edit it here"));
    var otherEd             = createConfigEditor('yaml');
    var otherSaveBtn        = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      disabled: '',
      click: function () {
        var meta = otherEd.textarea.dataset;
        if (!meta.name) return;
        uploadConfigContent(meta.name, otherEd.getValue(), meta.type).then(function (r) {
          if (r && r.success) ui.addNotification(null, E('p', meta.name + _(" saved")));
          else ui.addNotification(null, E('p', _("Save failed: ") + ((r && (r.message || r.error)) || '')));
        }).catch(function (err) {
          ui.addNotification(null, E('p', _("Save failed: ") + (err && err.message ? err.message : err)));
        });
      }
    }, _("Save"));

    var otherEditorBox = E('div', { 'class': 'cl-section cl-card cl-sb-editor' }, [
      otherEditorTitle,
      otherEd.el,
      E('div', { 'class': 'cl-actions cl-sb-row-actions cl-sb-editor-actions' }, [
        otherSaveBtn,
        E('span', { 'class': 'cl-hint' }, _("Click Save after editing; switching configuration automatically restarts the service"))
      ])
    ]);

    function loadOtherEditor(name, type) {
      otherEditorTitle.textContent = _("Editing: ") + name;
      otherSaveBtn.removeAttribute('disabled');
      otherEd.textarea.dataset.name = name;
      otherEd.textarea.dataset.type = type;
      otherEd.setValue(_("Loading…"));
      L.resolveDefault(callReadOtherConfig(name, type), {}).then(function (r) {
        otherEd.setValue(r.content || '');
      });
    }

    var makeOtherCards = function (files, type) {
      return files.map(function (f) {
        var nameNodes = [];
        if (f.active) nameNodes.push(E('span', { 'class': 'cl-active-badge' }, _("Active")));
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
            }, _("Edit")),
            E('button', {
              'class': 'btn cbi-button cl-btn-sm cl-btn-switch',
              click: function () {
                L.resolveDefault(callSetConfig(f.name), {}).then(function () { location.reload(); });
              }
            }, _("Switch")),
            E('button', {
              'class': 'btn cbi-button cl-btn-sm cl-btn-delete',
              click: function () {
                if (!confirm(_("Delete ") + f.name + '?')) return;
                L.resolveDefault(callDeleteCfg(f.name, type), {}).then(function () { location.reload(); });
              }
            }, _("Delete"))
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
        E('h4', {}, _("Subscription URL")),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600' }, [urlInput, nameInput, uaPicker.wrap, dlBtn, dlStatusEl])
      ]),
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, _("Downloaded Subscriptions")),
        buildSubscriptionSchedule(uiData, subscriptionUpdateStatus),
        subs.length ? E('div', { 'class': 'cl-fixed-600' }, [
          E('div', { 'class': 'cl-file-list' }, subCards)
        ])
          : E('p', { style: 'opacity:.5;font-size:13px' }, _("No subscriptions"))
      ]),
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, _("Upload Configuration File")),
        uploadInput,
        E('button', {
          'class': 'btn cbi-button cl-btn-sm cl-btn-upload-config',
          click: function () { document.getElementById('cl-upload-input').click(); }
        }, _("Select YAML file to upload"))
      ])
    ];

    if (otherFiles.length) {
      sections.push(E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, _("Other Configuration Files (upload / overwrite output)")),
        E('div', { 'class': 'cl-fixed-600' }, [
          E('div', { 'class': 'cl-file-list' }, otherCards)
        ])
      ]));
      sections.push(otherEditorBox);
    }

      sections.push(
      E('div', { 'class': 'cl-section cl-card' }, [
        E('h4', {}, _("Overwrite Settings")),
        E('div', { 'class': 'cl-form-wrap cl-rewrite-wrap cl-fixed-600' }, [
          E('div', { 'class': 'cl-rewrite-group cl-rewrite-group-template' }, [
            E('div', { 'class': 'cl-rewrite-group-title' }, _("Template Selection")),
            E('div', { 'class': 'cl-mode-tabs' }, [tabLocal, tabRemote]),
            localPanel,
            remotePanel
          ]),
          E('div', { 'class': 'cl-rw-divider' }),
          E('div', { 'class': 'cl-rewrite-group cl-rewrite-group-input' }, [
            E('div', { 'class': 'cl-rewrite-group-title' }, _("Information Input")),
            subUrlIn,
            outNameIn,
            E('div', { 'class': 'cl-actions cl-rewrite-actions' }, [
              E('button', { 'class': 'btn cbi-button cl-btn-sm', click: function(){ rwApply(false); } }, _("Generate Configuration")),
              E('button', { 'class': 'btn cbi-button-action cl-btn-sm cl-btn-generate-switch', click: function(){ rwApply(true); } }, _("Apply Configuration"))
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

    s = m.section(form.NamedSection, 'config', 'clashoo', _("Transparent Proxy"));
    s.addremove = false;
    o = s.option(form.ListValue, 'tcp_mode', _("TCP Mode"));
    o.value('redirect', 'Redirect'); o.value('tproxy', 'TPROXY'); o.value('tun', 'TUN'); o.value('off', _("Off"));
    o = s.option(form.ListValue, 'udp_mode', _("UDP Mode"));
    o.value('tun', 'TUN'); o.value('tproxy', 'TPROXY'); o.value('off', _("Off"));
    o = s.option(form.ListValue, 'stack', _("Network Stack Type"));
    o.value('system', 'System'); o.value('gvisor', 'gVisor'); o.value('mixed', 'Mixed');
    o = s.option(form.Flag, 'disable_quic_gso', _("Disable QUIC GSO"));
    o = s.option(form.Flag, 'ipv4_dns_hijack', _("IPv4 DNS Hijack"));
    o = s.option(form.Flag, 'ipv6_dns_hijack', _("IPv6 DNS Hijack"));
    o.description = _("Intercept IPv6 DNS traffic to prevent devices with hard-coded DNS from bypassing the traffic.");
    o = s.option(form.Flag, 'ipv4_proxy',      _("IPv4 Proxy"));
    o = s.option(form.Flag, 'ipv6_proxy',      _("IPv6 Proxy"));
    o = s.option(form.Flag, 'fake_ip_ping_hijack', _("Virtual IP Ping Hijacking"));
    o = s.option(form.Flag, 'dns_leak_protect', _("Prevent DNS Leaks"));
    o.description = _("Regular domains only use overseas DNS and DNS connections follow proxy rules; DoT/DoQ (port 853) is blocked and IPv6 resolution is disabled. Takes effect after restart.<br>") +
                    _("<strong>Note:</strong> Proxy node domains still use direct DNS for startup resolution, not for normal client domain queries.<br>") +
                    _("<strong>Warning:</strong> After enabling, IPv6 sites can only be accessed over IPv4; pure IPv6 networks may lose connectivity.");
    o = s.option(form.Flag, 'core_only', _("Core Only (advanced)"));
    o.description = _("Run only the core with your imported configuration, without taking over firewall / DNS / routing.<br>") +
                    _("mihomo runs as-is for nikki/OpenClash compatibility; sing-box automatically upgrades old formats for momo/homeproxy compatibility.<br>") +
                    _("<strong>Prerequisite:</strong> The configuration must include transparent proxying (TUN auto-route or TProxy inbound). Restart after switching.");

    s = m.section(form.NamedSection, 'config', 'clashoo', _("Port Settings"));
    s.addremove = false;
    o = s.option(form.Flag,  'allow_lan',   _("Allow LAN Access"));
    o = s.option(form.Value, 'http_port',   _("HTTP Port"));
    o = s.option(form.Value, 'socks_port',  _("SOCKS5 Port"));
    o = s.option(form.Value, 'mixed_port',  _("Mixed Port"));
    o = s.option(form.Value, 'redir_port',  _("Redirect Port"));
    o = s.option(form.Value, 'tproxy_port', _("TPROXY Port"));

    s = m.section(form.NamedSection, 'config', 'clashoo', _("Smart Policy Settings"));
    s.addremove = false;

    o = s.option(form.Flag,  'smart_auto_switch', _("Smart Policy Auto Switch"));
    o.description = _("Automatically switch Url-test and Load-balance policy groups to Smart policy groups");

    o = s.option(form.Value, 'smart_policy_priority', _("Policy Priority (weight bonus)"));
    o.default = 'Premium:0.9;SG:1.3';
    o.placeholder = 'Premium:0.9;SG:1.3';
    o.rmempty = true;
    o.description = _("Node weight bonus. <1 means lower priority, >1 means higher priority. Modify as needed; leave blank to skip policy-priority injection.");

    o = s.option(form.Flag,  'smart_prefer_asn', _("ASN Priority"));
    o.description = _("Force ASN lookup and prefer target ASN information when selecting nodes for a more stable experience");

    o = s.option(form.Flag,  'smart_uselightgbm', _("Enable LightGBM Model"));
    o.description = _("Use LightGBM model to predict weights");

    o = s.option(form.Flag,  'smart_collectdata', _("Collect Training Data"));
    o.description = _("Collect node latency data for LightGBM model training");

    o = s.option(form.Value, 'smart_collect_size', _("Training Data Size"));
    o.datatype = 'uinteger';
    o.placeholder = '100';
    o.description = _("smart-collector-size, maximum retained training samples, default 100");

    o = s.option(form.Value, 'smart_collect_rate', _("Sample Rate"));
    o.datatype = 'uinteger';
    o.placeholder = '1';
    o.description = _("sample-rate, 1 = sample every latency test; increase to reduce sampling frequency");

    o = s.option(form.Flag,  'smart_lgbm_auto_update', _("Auto Update Model"));

    o = s.option(form.Value, 'smart_lgbm_update_interval', _("Update interval (hours)"));
    o.datatype = 'uinteger';
    o.placeholder = '72';
    o.description = _("Period for automatically fetching a new model; also controls the cron trigger frequency, default 72 hours");

    o = s.option(form.Value, 'smart_lgbm_url', _("Model Download URL"));
    o.placeholder = 'https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model.bin';
    o.rmempty = true;
    o.description = _("LightGBM model file download URL; leave blank to use the default official URL");

    var sa = m.section(form.TypedSection, 'authentication', _("Proxy Authentication"));
    sa.anonymous = true; sa.addremove = true;
    o = sa.option(form.Value, 'username', _("Username"));
    o = sa.option(form.Value, 'password', _("Password"));

    var sr = m.section(form.TypedSection, 'addtype', _("Custom Routing Rules"),
      _("Correct routing by forcing a domain or IP to Direct or Proxy. These rules take priority over subscription rules and apply to both mihomo and sing-box."));
    sr.anonymous = true; sr.addremove = true;
    o = sr.option(form.Value, 'ipaaddr', _("Domain / IP"));
    /* allow empty so the default placeholder row never blocks saving other settings;
       empty rule rows are pruned on save (pruneEmptyAddtype) instead of erroring */
    o.rmempty = true;
    o.placeholder = _("example.com or 1.2.3.0/24");
    o = sr.option(form.ListValue, 'type', _("Type"));
    o.value('DOMAIN-SUFFIX', _("Domain suffix (e.g. google.com)"));
    o.value('DOMAIN', _("Exact domain (e.g. www.google.com)"));
    o.value('DOMAIN-KEYWORD', _("Domain keyword (e.g. youtube)"));
    o.value('IP-CIDR', _("IP / CIDR (e.g. 8.8.8.8/32)"));
    o.default = 'DOMAIN-SUFFIX';
    o = sr.option(form.ListValue, 'pgroup', _("Target"));
    o.value('DIRECT', _("Direct"));
    o.value('__PROXY__', _("Proxy"));
    o.default = 'DIRECT';
    o = sr.option(form.Flag, 'res', 'no-resolve');
    o.depends('type', 'IP-CIDR');
    o.description = _("IP rules do not trigger DNS resolution");

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
              E('span', { 'class': 'cl-ver-label' }, _("Current version: ")),
              E('span', { 'class': 'cl-ver-value' }, modelStatus.version)
            ])
          : E('span', { 'class': 'cl-ver-tag cl-ver-label' }, _("Model not installed"));
        var statusEl = E('div', { 'class': 'cl-update-status', style: 'margin-top:6px;font-size:12px;min-height:18px;line-height:1.4' });
        var upgPoller = null;
        function stopUpgPoller() { if (upgPoller) { clearInterval(upgPoller); upgPoller = null; } }
        function setStatus(text, tone) {
          // tone: '' / 'success' / 'error' / 'progress'
          statusEl.textContent = text || '';
          statusEl.style.color = tone === 'success' ? 'var(--success-color, #2e7d32)'
                                : tone === 'error'   ? 'var(--error-color, #d32f2f)'
                                : tone === 'progress'? 'var(--tip-color, #1976d2)'
                                : '';
        }
        function pollUpgStatus() {
          callSmartUpgradeLgbmStatus().then(function (st) {
            st = st || {};
            var rawLine = st.last_line || '';
            var line = clashoo.localizeLogLine(rawLine);
            if (st.running) {
              setStatus('⏳ ' + (line || _("Downloading LightGBM model...")), 'progress');
              return;
            }
            stopUpgPoller();
            upgBtn.disabled = false; upgBtn.textContent = _("Check and Update");
            var ok = /success|complete|done|完成|成功|无需更新|已是最新/i.test(rawLine + ' ' + line) || (st.has_model && st.size_kb > 100);
            var sizeTxt = st.size_kb ? ' (' + (st.size_kb >= 1024 ? (st.size_kb/1024).toFixed(1) + ' MB' : st.size_kb + ' KB') + ')' : '';
            setStatus((ok ? '✓ ' : '✗ ') + (line || (ok ? _("Update succeeded") : _("Update failed"))) + sizeTxt, ok ? 'success' : 'error');
            // 刷新版本标签
            if (verEl && st.version) {
              var valEl = verEl.querySelector('.cl-ver-value');
              if (valEl) valEl.textContent = st.version;
              else verEl.textContent = _("Current version: ") + st.version;
            }
            setTimeout(function () { setStatus(''); }, 8000);
          });
        }
        var upgBtn = E('button', { 'class': 'btn cbi-button-action', 'click': function () {
          stopUpgPoller();
          upgBtn.disabled = true; upgBtn.textContent = _("Downloading...");
          setStatus(_("⏳ Starting update task..."), 'progress');
          callSmartUpgradeLgbm().then(function () {
            // 开启状态轮询：每 2s 一次直到结束
            upgPoller = setInterval(pollUpgStatus, 2000);
            // 立即先拉一次，反馈更快
            setTimeout(pollUpgStatus, 500);
          }).catch(function () {
            upgBtn.disabled = false; upgBtn.textContent = _("Check and Update");
            setStatus(_("✗ Start failed"), 'error');
            setTimeout(function () { setStatus(''); }, 5000);
          });
        }}, _("Check and Update"));
        smartSec.appendChild(E('div', { 'class': 'cbi-value' }, [
          E('label', { 'class': 'cbi-value-title' }, _("Update Model")),
          E('div', { 'class': 'cbi-value-field' }, [
            E('div', { 'class': 'cl-btn-ver-wrap' }, [
              upgBtn,
              verEl
            ]),
            statusEl
          ])
        ]));
        var flushBtn = E('button', { 'class': 'btn cbi-button', 'click': function () {
          flushBtn.disabled = true;
          callSmartFlushCache().then(function (res) {
            flushBtn.disabled = false;
            ui.addNotification(null, E('p', (res && res.success) ? _("Smart cache cleared") : _("Cleanup failed (mihomo may not be running)")));
          }).catch(function () { flushBtn.disabled = false; });
        }}, _("Clear"));
        smartSec.appendChild(E('div', { 'class': 'cbi-value' }, [
          E('label', { 'class': 'cbi-value-title' }, _("Clear Smart Cache")),
          E('div', { 'class': 'cbi-value-field' }, [flushBtn])
        ]));
      }
      makeSectionCollapsible(node, _("Transparent Proxy"), true);
      makeSectionCollapsible(node, _("Port Settings"), true);
      makeSectionCollapsible(node, _("Smart Policy Settings"), false);
      makeSectionCollapsible(node, _("Proxy Authentication"), false);
      makeSectionCollapsible(node, _("Custom Routing Rules"), false);

      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'btn cbi-button', click: function () {
          m.save(null, true).then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', _("Save failed: ") + (e.message || e))); });
        }}, _("Save Configuration")),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          // 保存前探测主代理组，供自定义分流规则的「代理」(__PROXY__) 解析（失败忽略，注入器回退 GLOBAL）
          callDetectPrimaryGroup().catch(function () {}).then(function () {
            return saveCommitApplyMaybeReload(m, _("Proxy configuration saved and service hot-reloaded"), _("Proxy configuration saved, service is not running"));
          }).catch(function (e) { ui.addNotification(null, E('p', _("Operation failed: ") + (e.message || e))); });
        }}, _("Apply Configuration"))
      ]));
    });
  },

  _buildDnsForm: function (container) {
    var m = new form.Map('clashoo', '', '');
    var s, o;

    s = m.section(form.NamedSection, 'config', 'clashoo', _("Basic DNS"));
    s.addremove = false;
    o = s.option(form.DummyValue, '_dns_auto_setup', _("DNS Auto Setup"));
    o.cfgvalue = function () {
      var statusEl = E('div', { 'class': 'cl-dns-auto-status' }, []);
      var last = readDnsAutoResult();
      if (last && last.success)
        setDnsAutoStatus(statusEl, dnsAutoSummaryNode(last));
      else
        statusEl.textContent = _("Automatically choose available DNS and update only upstream servers; split policies and advanced settings remain unchanged.");
      if (last && last.success)
        window.setTimeout(function () {
          clearDnsAutoResult();
          statusEl.textContent = _("Automatically choose available DNS and update only upstream servers; split policies and advanced settings remain unchanged.");
        }, 6000);
      var btn = E('button', {
        'class': 'btn cbi-button-action',
        click: function (ev) {
          ev.preventDefault();
          btn.disabled = true;
          setDnsAutoStatus(statusEl, _("Testing latency and writing upstream DNS…"));
          clashoo.dnsAutoSetup()
            .then(function (res) {
              btn.disabled = false;
              if (!res || !res.success) {
                setDnsAutoStatus(statusEl, (res && res.message) || _("DNS auto setup failed"));
                ui.addNotification(null, E('p', (res && res.message) || _("DNS auto setup failed")));
                return;
              }
              storeDnsAutoResult(res);
              setDnsAutoStatus(statusEl, dnsAutoSummaryNode(res));
              ui.addNotification(null, E('p', dnsAutoResultMessage(res)));
              window.setTimeout(function () {
                clearDnsAutoResult();
                statusEl.textContent = _("Auto setup completed.");
              }, 6000);
            })
            .catch(function (e) {
              btn.disabled = false;
              setDnsAutoStatus(statusEl, _("DNS auto setup failed: ") + (e.message || e));
              ui.addNotification(null, E('p', _("DNS auto setup failed: ") + (e.message || e)));
            });
        }
      }, _("Test and Apply"));
      return E('div', { 'class': 'cl-dns-auto' }, [
        E('div', { 'class': 'cl-dns-auto-actions' }, [btn]),
        statusEl
      ]);
    };
    o.write = function () {};
    o = s.option(form.Flag,        'enable_dns',        _("Enable DNS Module"));
    o = s.option(form.Value,       'listen_port',       _("DNS Listen Port"));
    o.datatype = 'port';
    o = s.option(form.ListValue,   'enhanced_mode',     _("Enhanced Mode"));
    o.value('fake-ip', 'Fake-IP'); o.value('redir-host', 'Redir-Host');
    o.default = 'fake-ip';
    o.description = _("<span style=\"display:inline-block;padding:1px 7px;border-radius:4px;font-size:12px;font-weight:600;background:rgba(var(--primary-rgb),0.14);color:var(--cl-primary,#3886a1);\">Fake-IP · Recommended</span> Fast resolution and accurate routing; China routing is handled by the core.<br />") +
      _("<span style=\"display:inline-block;padding:1px 7px;border-radius:4px;font-size:12px;background:rgba(128,128,128,0.16);color:var(--cl-label-muted,#888);\">Redir-Host</span> China traffic bypasses the core at firewall level; DNS behavior is slightly weaker. Choose as needed.");
    o = s.option(form.Value,       'fake_ip_range',     _("Fake-IP Range"));
    o.default = '198.18.0.1/16';
    o.placeholder = '198.18.0.1/16';
    o.depends('enhanced_mode', 'fake-ip');
    o.remove = function () {};
    o = s.option(form.Flag,        'enable_ipv6',       'IPv6 DNS');

    s = m.section(form.NamedSection, 'config', 'clashoo', _("Advanced DNS"));
    s.addremove = false;
    o = s.option(form.Flag,        'dnsforwader',       _("Force DNS Forwarding"));
    o = s.option(form.ListValue,   'fake_ip_filter_mode', _("Fake-IP Filter Mode"));
    o.value('blacklist', _("Blocklist (listed items use real IP, default)"));
    o.value('whitelist', _("Allowlist (only listed items use fake-IP)"));
    o.value('rule',      _("Rule mode (same syntax as rules)"));
    o.default = 'blacklist';
    o.depends('enhanced_mode', 'fake-ip');

    o = s.option(form.DynamicList, 'fake_ip_filter',    _("Fake-IP Filter Domains"));
    o.placeholder = '*.lan / geosite:cn / RULE-SET,cn_domain,real-ip';
    o.description = _("Blocklist/allowlist mode: enter domains or shorthand like <code>geosite:cn</code>. Rule mode: enter items with the same syntax as rules, such as <code>GEOSITE,cn,real-ip</code> / <code>RULE-SET,xxx,real-ip</code>; usually add <code>MATCH,fake-ip</code> at the end as fallback. <code>geosite:cn</code> automatically uses built-in cn.mrs acceleration and avoids loading the 10MB geosite.dat.");
    o.depends('enhanced_mode', 'fake-ip');
    o.remove = function () {};
    o = s.option(form.DynamicList, 'default_nameserver', 'Bootstrap DNS');
    o.placeholder = '223.5.5.5';
    o.description = _("Used to resolve DoH/DoT/DoQ server domains; plain IP DNS is recommended.");
    o = s.option(form.Value, 'dns_ecs', _("ECS Client Subnet"));
    o.placeholder = _("Recommended blank");
    o.description = _("mihomo writes the ecs parameter to DNS URLs; sing-box writes dns.client_subnet. Leave empty to skip.");
    o.rmempty = true;
    o = s.option(form.Flag, 'dns_ecs_override', _("Force ECS Override"));
    o.default = '0';
    o = s.option(form.Flag, 'fallback_filter_geoip', _("Fallback GeoIP Filter"));
    o.default = '0';
    o.description = _("Requires MMDB. If enabled while the local GeoIP database is missing, the core may fail to start. Usually not needed.");
    o = s.option(form.DynamicList, 'fallback_filter_ipcidr', 'Fallback IP CIDR');
    o.placeholder = '240.0.0.0/4';
    o = s.option(form.Flag, 'singbox_independent_cache', _("sing-box Independent DNS Cache"));
    o.default = '0';
    o.description = _("When enabled, direct / proxy / fallback roles each use an independent DNS cache. Useful when the same domain needs different resolver chains by routing. Usually not needed.");

    s = m.section(form.TypedSection, 'dnsservers', _("Upstream DNS"));
    s.addremove = true; s.anonymous = true;
    o = s.option(form.Flag, 'enabled', _("Enable"));
    o.default = '1';
    o = s.option(form.ListValue, 'ser_type', _("Role"));
    o.value('nameserver', _("Domestic Upstream DNS"));
    o.value('direct-nameserver', _("Direct Domain Resolver"));
    o.value('proxy-server-nameserver', _("Proxy Node Domain Resolver"));
    o.value('fallback', _("Overseas Encrypted DNS (anti-pollution)"));
    o.default = 'nameserver';
    o = s.option(form.Value,     'ser_address', _("DNS Address"));
    o.placeholder = 'https://dns.alidns.com/dns-query / https://doh.pub/dns-query';
    o = s.option(form.ListValue, 'protocol',    _("Protocol"));
    o.value('none', _("Full URL / no protocol prefix"));
    o.value('udp://', 'UDP');
    o.value('tcp://', 'TCP');
    o.value('tls://', 'DoT / TLS');
    o.value('https://', 'DoH / HTTPS');
    o.value('quic://', 'DoQ / QUIC');
    o.default = 'none';
    o = s.option(form.Value, 'ser_port', _("Port"));
    o.placeholder = '853 / 784';
    o.rmempty = true;

    s = m.section(form.TypedSection, 'dns_policy', _("DNS Policy"));
    s.addremove = true; s.anonymous = true;
    o = s.option(form.Flag, 'enabled', _("Enable"));
    o.default = '1';
    o = s.option(form.ListValue, 'policy_type', _("Policy Type"));
    o.value('nameserver-policy', _("Domain Split DNS"));
    o.value('proxy-server-nameserver-policy', _("Proxy Domain Split DNS"));
    o.default = 'nameserver-policy';
    o = s.option(form.Value, 'matcher', _("Match Rule"));
    o.placeholder = 'geosite:cn / domain:example.com / domain-suffix:google.com';
    o = s.option(form.DynamicList, 'nameserver', _("Use DNS"));
    o.placeholder = 'udp://223.5.5.5';
    o.description = _("Example: geosite:cn uses https://dns.alidns.com/dns-query; geosite:geolocation-!cn uses https://cloudflare-dns.com/dns-query.");

    m.render().then(function (node) {
      decorateControlWraps(node);
      makeSectionCollapsible(node, _("Basic DNS"), true);
      makeSectionCollapsible(node, _("Advanced DNS"), false);
      makeSectionCollapsible(node, _("Upstream DNS"), false);
      makeSectionCollapsible(node, _("DNS Policy"), false);
      container.appendChild(node);
      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'btn cbi-button', click: function () {
          m.save(null, true).then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', _("Save failed: ") + (e.message || e))); });
        }}, _("Save Configuration")),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          saveCommitApplyMaybeReload(m, _("DNS configuration saved and service hot-reloaded"), _("DNS configuration saved, service is not running"))
            .catch(function (e) { ui.addNotification(null, E('p', _("Operation failed: ") + (e.message || e))); });
        }}, _("Apply Configuration"))
      ]));
    });
  },

  /* ── sing-box UI ── */

  _renderSingbox: function (sbData, uiData, subscriptionUpdateStatus) {
    var self = this;
    var profiles = sbData.profiles || [];
    var tabEls = {}, panelEls = {};

    var tabs = [
      { id: 'profiles', label: _("Configuration Files") },
      { id: 'wizard',   label: _("Quick Wizard") }
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
      self._buildSbProfilesPanel(profiles, sbData.active || '', uiData, subscriptionUpdateStatus));
    panelEls['profiles'] = profilesPanel;

    var wizardPanel = E('div', { 'class': 'cl-panel' + (this._sbTab === 'wizard' ? ' active' : ''), id: 'cl-panel-wizard' },
      self._buildSbWizardPanel());
    panelEls['wizard'] = wizardPanel;

    return E('div', { 'class': 'cl-wrap clashoo-container cl-config-page cl-form-page ' + getThemeClass() }, [tabBar, profilesPanel, wizardPanel]);
  },

  _buildSbProfilesPanel: function (profiles, activeProfile, uiData, subscriptionUpdateStatus) {
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
    var editorTitle = E('span', { 'class': 'cl-editor-hdr' }, _("Select a configuration above to edit it here"));
    var ed          = createConfigEditor({ name: 'javascript', json: true });
    var saveBtn = E('button', {
      'class': 'btn cbi-button-action cl-btn-sm',
      disabled: '',
      click: function () {
        var name = ed.textarea.dataset.name;
        if (!name) return;
        clashoo.saveSingboxProfile(name, formatJsonForEditor(ed.getValue())).then(function (r) {
          if (r.success) ui.addNotification(null, E('p', name + _(" saved")));
          else ui.addNotification(null, E('p', _("Save failed: ") + (r.message || r.error || '')));
        });
      }
    }, _("Save"));

    var migrateBtn = E('button', {
      'class': 'btn cbi-button cl-btn-sm',
      disabled: '',
      click: function () {
        var name = ed.textarea.dataset.name;
        if (!name) return;
        L.resolveDefault(callMigrateSbProfile(name), {}).then(function (r) {
          if (r && r.success) {
            var msg = r.changes && r.changes.length ? _("Fixed deprecated fields: ") + r.changes.join(', ') : _("Configuration is up to date; no fixes needed");
            ui.addNotification(null, E('p', msg));
            /* 重新加载编辑器内容 */
            clashoo.getSingboxProfile(name).then(function (gr) { ed.setValue(formatJsonForEditor(gr.content || '')); });
          } else {
            ui.addNotification(null, E('p', _("Fix failed: ") + ((r && r.message) || '')));
          }
        });
      }
    }, _("Fix Deprecated Fields"));

    var editorBox = E('div', { 'class': 'cl-section cl-card cl-sb-card cl-sb-editor' }, [
      editorTitle,
      ed.el,
      E('div', { 'class': 'cl-actions cl-sb-row-actions cl-sb-editor-actions' }, [
        saveBtn,
        migrateBtn,
        E('span', { 'class': 'cl-hint' }, _("Click Save after editing; switching configuration automatically restarts the service"))
      ])
    ]);

    function loadEditor(name) {
      editorTitle.textContent = _("Editing: ") + name;
      saveBtn.removeAttribute('disabled');
      migrateBtn.removeAttribute('disabled');
      ed.textarea.dataset.name = name;
      ed.setValue(_("Loading…"));
      clashoo.getSingboxProfile(name).then(function (r) {
        ed.setValue(formatJsonForEditor(r.content || ''));
      });
    }

    /* ── Profile table ── */
    var rows = profiles.length
      ? profiles.map(function (p) {
          var nameCell = [
            E('div', { 'class': 'cl-sb-file-name' }, [
              p.active ? E('span', { 'class': 'cl-active-badge' }, _("Active")) : '',
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
              }, _("Edit")) : '',
              E('button', {
                'class': 'btn cbi-button-action cl-btn-sm cl-btn-sb-action cl-btn-sb-switch',
                click: function () {
                  clashoo.setSingboxProfile(p.name).then(function (r) {
                    ui.addNotification(null, E('p', r.success ? _("Switched to ") + p.name : (_("Switch failed: ") + (r.message || ''))));
                    if (r.success) location.reload();
                  });
                }
              }, _("Switch")),
              p.source === 'native' && p.sub_url ? E('button', {
                'class': 'btn cbi-button cl-btn-sm cl-btn-sb-action',
                click: function (ev) {
                  var btn = ev.currentTarget;
                  btn.disabled = true;
                  btn.textContent = _("Updating…");
                  clashoo.updateSingboxNative(p.name).then(function (r) {
                    btn.disabled = false;
                    btn.textContent = _("Update");
                    ui.addNotification(null, E('p', r.success ? (r.message || p.name + _(" updated")) : (_("Update failed: ") + (r.message || ''))));
                    if (r.success) location.reload();
                  });
                }
              }, _("Update")) : '',
              E('button', {
                'class': 'btn cbi-button-negative cl-btn-sm cl-btn-sb-action cl-btn-sb-delete',
                click: function () {
                  if (!confirm(_("Delete ") + p.name + '?')) return;
                  clashoo.deleteSingboxProfile(p.name).then(function () { location.reload(); });
                }
              }, _("Delete"))
              ])
            ])
          ]);
        })
      : [E('tr', {}, [E('td', { 'class': 'cl-sb-empty', colspan: '3' }, _("No configuration files yet. Use Quick Wizard to generate one or upload a JSON file."))])];

    /* ── Upload ── */
    var uploadInput = E('input', { type: 'file', accept: '.json', style: 'display:none', id: 'sb-upload' });
    uploadInput.addEventListener('change', function (ev) {
      var file = ev.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        clashoo.saveSingboxProfile(file.name, e.target.result).then(function (r) {
          if (r.success) { ui.addNotification(null, E('p', _("Upload succeeded: ") + r.name)); location.reload(); }
          else ui.addNotification(null, E('p', _("Upload failed: ") + (r.message || r.error || '')));
        });
      };
      reader.readAsText(file);
    });

    return [
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, _("Subscription Update")),
        buildSubscriptionSchedule(uiData || {}, subscriptionUpdateStatus || {})
      ]),
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, _("sing-box Configuration Files")),
        E('table', { 'class': 'cl-sub-list cl-sb-list' }, [
          E('thead', {}, E('tr', {}, [E('th', {}, _("File Name")), E('th', {}, _("Size")), E('th', {}, _("Actions"))])),
          E('tbody', {}, rows)
        ]),
        uploadInput,
        E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [
          E('button', {
            'class': 'btn cbi-button-add cl-btn-sm cl-btn-sb-upload',
            click: function () { document.getElementById('sb-upload').click(); }
          }, _("Upload JSON Configuration"))
        ])
      ]),
      editorBox
    ];
  },

  _buildSbWizardPanel: function () {
    var urlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("Paste subscription URL (supports vmess / vless / trojan, etc.)")
    });
    var nameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("Configuration file name (optional, blank auto-generates singbox.json)"),
      style: 'margin-top:0'
    });
    var savedUa = '';
    try { savedUa = uci.get('clashoo', 'config', 'sub_ua') || ''; } catch (e) {}
    // YAML 订阅转换走 mihomo 订阅流程（拉 yaml → yaml2singbox），UA 与 mihomo 共用 sub_ua
    var convertUaPicker = buildUaPicker(savedUa);

    var genBtn, applyBtn;
    function setBusy(busy, activeBtn) {
      [genBtn, applyBtn].forEach(function (b) {
        if (!b) return;
        b.disabled = busy ? '' : null;
        if (busy) {
          if (!b.dataset.label) b.dataset.label = b.textContent;
          if (b === activeBtn)
            b.textContent = b._clBusyLabel || _("Processing…");
        } else if (b.dataset.label) {
          b.textContent = b.dataset.label;
        }
      });
    }
    function doCreate(setActive) {
      var url = urlInput.value.trim();
      if (!url) { ui.addNotification(null, E('p', _("Please enter a subscription URL"))); return; }
      setBusy(true, setActive ? applyBtn : genBtn);
      // 保存 UA 到 UCI，后端 create_singbox_config 会读这个字段
      var uaPromise = L.resolveDefault(uci.load('clashoo'), null).then(function () {
        uci.set('clashoo', 'config', 'sub_ua', convertUaPicker.getValue());
        return uci.save()
          .then(function () { return clashoo.commitConfig(); })
          .then(function () { return clearClashooDirty(); });
      }).catch(function () {});
      uaPromise.then(function () {
        return clashoo.createSingboxConfig(url, nameInput.value.trim());
      })
        .then(function (r) {
          /* RPC 超时被 resolveDefault 兜底成 {}，r.success 是 undefined。
           * 此时后端可能仍在跑（yaml2singbox 转 90 节点等），让用户直接刷新页
           * 看实际产物，而不是误报"失败"。 */
          if (!r || typeof r.success === 'undefined') {
            ui.addNotification(null, E('p', _("Generation is taking longer, refreshing to show results…")));
            setBusy(false);
            setTimeout(function () { location.reload(); }, 1500);
            return;
          }
          if (!r.success) {
            setBusy(false);
            ui.addNotification(null, E('p', _("Generate failed: ") + (r.message || '')));
            return;
          }
          if (setActive) {
            return clashoo.setSingboxProfile(r.name).then(function () {
              ui.addNotification(null, E('p', r.message + _(", switched to active configuration")));
              location.reload();
            });
          }
          ui.addNotification(null, E('p', r.message));
          location.reload();
        }).catch(function (e) {
          setBusy(false);
          ui.addNotification(null, E('p', _("Generate error: ") + (e && e.message || e)));
        });
    }

    genBtn   = E('button', { 'class': 'btn cbi-button cl-btn-sm',        click: function () { doCreate(false); } }, _("Generate Configuration"));
    applyBtn = E('button', { 'class': 'btn cbi-button-action cl-btn-sm', click: function () { doCreate(true);  } }, _("Apply Configuration"));
    genBtn._clBusyLabel = _("Generating…");
    applyBtn._clBusyLabel = _("Applying…");

    /* ── native sing-box subscription card ── */
    // 注：原生 sing-box JSON 订阅不需要 UA 选项（机场按链接参数/路径区分格式）
    var nativeUrlInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("Paste native sing-box subscription URL (direct JSON response)")
    });
    var nativeNameInput = E('input', {
      'class': 'cl-sub-url',
      type: 'text',
      placeholder: _("File name (optional, blank for automatic name)"),
      style: 'margin-top:0'
    });

    var fetchBtn, fetchApplyBtn;
    var fetchStatusEl = E('div', { 'class': 'cl-update-status', style: 'margin-top:6px;font-size:12px;min-height:18px;line-height:1.4' });
    var setFetchStatus = function (text, tone) {
      fetchStatusEl.textContent = text || '';
      fetchStatusEl.style.color = tone === 'success' ? 'var(--success-color, #2e7d32)'
                                : tone === 'error'   ? 'var(--error-color, #d32f2f)'
                                : tone === 'progress'? 'var(--tip-color, #1976d2)'
                                : '';
    };
    function setNativeBusy(busy) {
      [fetchBtn, fetchApplyBtn].forEach(function (b) {
        if (!b) return;
        b.disabled = busy ? '' : null;
        if (busy) {
          if (!b.dataset.label) b.dataset.label = b.textContent;
          b.textContent = _("Fetching…");
        } else if (b.dataset.label) {
          b.textContent = b.dataset.label;
        }
      });
    }
    function doFetchNative(setActive) {
      var url = nativeUrlInput.value.trim();
      if (!url) {
        setFetchStatus(_("✗ Please enter a subscription URL"), 'error');
        setTimeout(function () { setFetchStatus(''); }, 4000);
        return;
      }
      setNativeBusy(true);
      setFetchStatus(_("⏳ Fetching configuration..."), 'progress');
      clashoo.fetchSingboxNative(url, nativeNameInput.value.trim())
        .then(function (r) {
          setNativeBusy(false);
          if (!r || typeof r.success === 'undefined') {
            setFetchStatus(_("⏳ Fetch timed out, refreshing to show results..."), 'progress');
            setTimeout(function () { location.reload(); }, 1500);
            return;
          }
          if (!r.success) {
            setFetchStatus(_("✗ Fetch failed: ") + (r.message || ''), 'error');
            return;
          }
          if (setActive) {
            setFetchStatus('⏳ ' + r.message + _(", switching to active configuration..."), 'progress');
            return clashoo.setSingboxProfile(r.name).then(function () {
              setFetchStatus('✓ ' + r.message + _(", switched to active configuration"), 'success');
              setTimeout(function () { location.reload(); }, 1200);
            });
          }
          setFetchStatus('✓ ' + r.message, 'success');
          setTimeout(function () { location.reload(); }, 1200);
        }).catch(function (e) {
          setNativeBusy(false);
          setFetchStatus(_("✗ Fetch error: ") + (e && e.message || e), 'error');
        });
    }

    fetchBtn      = E('button', { 'class': 'btn cbi-button cl-btn-sm',        click: function () { doFetchNative(false); } }, _("Fetch Configuration"));
    fetchApplyBtn = E('button', { 'class': 'btn cbi-button-action cl-btn-sm', click: function () { doFetchNative(true);  } }, _("Fetch and Apply"));

    return [
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, _("Node Subscription")),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600 cl-sb-form' }, [
          nativeUrlInput, nativeNameInput,
          E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [fetchBtn, fetchApplyBtn]),
          fetchStatusEl
        ]),
        E('p', { 'class': 'cl-sb-note' },
          _("For providers that directly offer sing-box JSON subscriptions, or links already converted by external tools.\n") +
          _("After fetching, click Update on the corresponding item in the Configuration Files tab to fetch the latest configuration again.")
        )
      ]),
      E('div', { 'class': 'cl-section cl-card cl-sb-card' }, [
        E('h4', {}, _("YAML Subscription Conversion")),
        E('div', { 'class': 'cl-form-wrap cl-fixed-600 cl-sb-form' }, [
          urlInput, nameInput, convertUaPicker.wrap,
          E('div', { 'class': 'cl-actions cl-sb-top-actions' }, [
            genBtn,
            applyBtn
          ])
        ]),
        E('p', { 'class': 'cl-sb-note' },
          _("Convert YAML subscriptions to sing-box JSON, automatically injecting TUN transparent proxy and China direct rules. Files with the same name are overwritten; use the same name when updating.")
        )
      ])
    ];
  },

  handleSaveApply: null,
  handleSave:      null,
  handleReset:     null
});
