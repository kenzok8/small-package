'use strict';
'require view';
'require form';
'require uci';
'require ui';
'require poll';
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

var callHostHints = rpc.declare({
  object: 'luci-rpc',
  method: 'getHostHints',
  expect: { '': {} }
});

var callBackupExport = rpc.declare({ object: 'luci.clashoo', method: 'backup_export', expect: {} });
var callBackupImport = rpc.declare({ object: 'luci.clashoo', method: 'backup_import', params: ['data'], expect: {} });
var callBackupReset  = rpc.declare({ object: 'luci.clashoo', method: 'backup_reset',  expect: {} });

var CSS = [
  '.cl-wrap{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif}',
  '.cl-tabs{display:flex;border-bottom:2px solid rgba(128,128,128,.15);margin-bottom:18px}',
  '.cl-tab{padding:10px 20px;cursor:pointer;font-size:13px;opacity:.55;border-bottom:2px solid transparent;margin-bottom:-2px}',
  '.cl-tab.active{opacity:1;border-bottom-color:currentColor;font-weight:600}',
  '.cl-panel{display:none}.cl-panel.active{display:block}',
  '.cl-section{margin-bottom:20px}',
  '.cl-section h4{font-size:.95rem;font-weight:600;margin-bottom:10px;color:var(--title-color,rgba(92,102,120,.72));opacity:.95}',
  '.cl-save-bar{display:flex;gap:8px;margin-top:14px;padding-top:12px;border-top:1px solid rgba(128,128,128,.15)}',
  '.cl-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px}',
  '.cl-log-area{font-family:monospace;font-size:11px;opacity:.75;max-height:300px;overflow-y:auto;border:1px solid rgba(128,128,128,.2);border-radius:8px;padding:10px;white-space:pre-wrap;margin-top:8px}',
  '.cl-log-tabs{display:flex;gap:8px;margin-bottom:8px}',
  '.cl-log-tab{padding:4px 12px;border:1px solid rgba(128,128,128,.2);border-radius:20px;font-size:12px;cursor:pointer;opacity:.6}',
  '.cl-log-tab.active{opacity:1;font-weight:600;background:rgba(128,128,128,.1)}',
  '.cl-log-line{display:block;padding:1px 4px;border-radius:3px}',
	  '.cl-log-line.cl-log-info{color:#7fc7a8}',
	  '.cl-log-line.cl-log-warn{color:#e8b95a}',
	  '.cl-log-line.cl-log-error{color:#ea7878;background:rgba(234,120,120,.06)}',
	  '.cl-log-line.cl-log-debug{color:#7a8290;opacity:.7}',
	  '.cl-log-line.cl-log-hidden{display:none}',
	  '.cl-log-ts{color:#6b7480;margin-right:8px}',
	  '.cl-log-msg{color:inherit}',
	  '.cl-dl-hint{margin-top:6px;font-size:12px;min-height:18px;line-height:1.4}',
  '.cl-component-card{padding:16px 18px;border:1px solid var(--cl-surface-border,rgba(128,128,128,.14));border-radius:var(--border-radius,var(--cl-radius,12px));background:var(--cl-card-bg,#fff);box-shadow:var(--card-shadow,var(--cl-card-shadow));margin:0 14px 14px}',
  '.cl-component-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:12px}',
  '.cl-component-head h4{display:flex;align-items:center;gap:8px;margin:0 0 4px !important;padding:0 !important;font-size:0.95rem;font-weight:600;color:var(--title-color,var(--cl-title-color,inherit));background:transparent !important}',
  '.cl-component-head h4:before{content:"";width:3px;height:14px;border-radius:2px;background:var(--primary-color,var(--cl-primary,#2f80ed));flex:0 0 3px}',
  '.cl-component-adv{margin-top:10px}',
  '.cl-component-adv-bar{display:flex;align-items:center;justify-content:space-between;padding:10px 12px;cursor:pointer;user-select:none;font-size:13px;font-weight:700;background:var(--cl-control-bg,rgba(128,128,128,.04));border:1px solid var(--cl-control-border,rgba(128,128,128,.14));border-radius:8px}',
  '.cl-component-adv-bar:hover{background:var(--cl-primary-soft,rgba(0,122,255,.08))}',
  '.cl-component-adv-chevron{font-size:16px;font-weight:700;opacity:.55;transition:transform .2s}',
  '.cl-component-adv:not(.cl-closed) .cl-component-adv-chevron{transform:rotate(90deg)}',
  '.cl-component-adv-body{margin-top:8px}',
  '.cl-component-adv.cl-closed .cl-component-adv-body{display:none}',
  '.cl-component-sub{font-size:12px;color:rgba(120,130,150,.9);line-height:1.45}',
  '.cl-component-list{display:grid;gap:8px}',
  '.cl-component-row{display:grid;grid-template-columns:minmax(170px,1.1fr) minmax(180px,1.5fr) minmax(130px,.9fr) auto;align-items:center;gap:10px;padding:10px 12px;border:1px solid var(--cl-surface-border,rgba(128,128,128,.14));border-radius:8px;background:var(--cl-card-bg,#fff)}',
  '.cl-component-name{font-weight:700;font-size:13px}',
  '.cl-component-desc{font-size:12px;color:rgba(120,130,150,.92);margin-top:2px}',
  '.cl-component-version{font-size:12px;line-height:1.45;color:rgba(90,100,120,.95);word-break:break-word}',
  '.cl-theme-dark .cl-component-version{color:rgba(210,220,235,.86)}',
  '.cl-component-status{font-size:12px;line-height:1.45;color:rgba(90,100,120,.95)}',
  '.cl-component-status.cl-st-running{color:#2f80ed}.cl-component-status.cl-st-success{color:#239b56}.cl-component-status.cl-st-failed{color:#d43f3a}',
  '.cl-component-log{margin-top:10px;font-family:monospace;font-size:11px;white-space:pre-wrap;max-height:140px;overflow:auto;padding:9px;border:1px solid var(--cl-surface-border,rgba(128,128,128,.14));border-radius:8px;background:var(--cl-card-bg,#fff);color:#4a8c63}',
  '.cl-theme-dark .cl-component-log{color:#a3d9ad}',
  '.cl-component-arch{margin-bottom:12px}',
  '.cl-component-arch-row{display:flex;align-items:center;gap:10px;flex-wrap:wrap;padding:9px 12px;border:1px solid var(--cl-surface-border,rgba(128,128,128,.14));border-radius:8px;background:var(--cl-card-bg,#fff)}',
  '.cl-component-arch-label{font-size:13px;font-weight:700}',
  '.cl-component-arch-auto{font-size:12px;color:rgba(90,100,120,.82);line-height:1.2}',
  '.cl-theme-dark .cl-component-arch-auto{color:rgba(210,220,235,.78)}',
  '.cl-wrap .cl-component-arch-sel{font-size:12px!important;font-weight:700!important;padding:4px 9px!important;border:1px solid rgba(46,170,92,.28)!important;border-radius:6px!important;background:rgba(46,170,92,.12)!important;color:#24844d!important}',
  '.cl-wrap.cl-theme-dark .cl-component-arch-sel{background:rgba(104,199,135,.16)!important;color:#c6f6d3!important;border-color:rgba(104,199,135,.3)!important}',
  '.cl-component-arch-sel option{background:var(--background-color,#fff);color:inherit}',
  '.cl-component-arch-hint{font-size:12px;color:rgba(120,130,150,.9)}',
  '.cl-comp-var-box{display:inline-flex;gap:4px;margin-top:5px}',
  '.cl-comp-var{font-size:11px;padding:2px 10px;border-radius:10px;border:1px solid rgba(128,128,128,.3);background:transparent;color:inherit;cursor:pointer;min-width:52px}',
  '.cl-comp-var.on{background:rgba(var(--primary-rgb,0,122,255),.18);border-color:rgba(var(--primary-rgb,0,122,255),.64);color:var(--primary-color,#0b68dd);font-weight:800;box-shadow:0 0 0 1px rgba(var(--primary-rgb,0,122,255),.1) inset}',
  '.cl-comp-updatable{font-size:10px;font-weight:700;color:#239b56;margin-left:2px}',
  '@media(max-width:760px){.cl-component-head{display:block}.cl-component-head .btn{margin-top:10px}.cl-component-row{grid-template-columns:1fr;gap:6px}.cl-component-row .btn{width:auto;justify-self:start;padding-left:18px;padding-right:18px}}',
  /* align form.Map font with config page */
  '.cl-panel .cbi-section>h3{font-size:13px !important;font-weight:600;margin-bottom:8px}',
  '.cl-panel .cbi-value-title{font-size:13px !important}',
  '.cl-panel .cbi-value-field input,.cl-panel .cbi-value-field select,.cl-panel .cbi-value-field textarea{font-size:13px !important}',
  '.cl-panel .cbi-section-descr,.cl-panel .cbi-value-helptext{font-size:12px !important}',
  '.cl-panel .cbi-section{margin-bottom:12px}',
  '.cl-wrap .cbi-section>h3,.cl-wrap .cbi-value-title,.cl-wrap .cbi-section-descr,.cl-wrap .cbi-value-helptext{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif !important}',
  '.cl-wrap .cbi-input-text,.cl-wrap .cbi-input-select,.cl-wrap select,.cl-wrap input,.cl-wrap textarea,.cl-wrap .btn,.cl-wrap .cbi-button{font-size:13px !important;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC",sans-serif !important}',
  '.cl-wrap .btn,.cl-wrap .cbi-button{padding:4px 10px;line-height:1.35}'
].join('');

/* component update: main area = clashoo/client only; rest in collapsible */
var COMPONENT_MAIN_IDS = { clashoo: true, luci: true };

function fastResolve(promise, timeoutMs, fallback) {
  var t = new Promise(function (resolve) {
    setTimeout(function () { resolve(fallback); }, timeoutMs);
  });
  return Promise.race([L.resolveDefault(promise, fallback), t]);
}

function decorateSystemForm(root) {
  if (!root || !root.querySelectorAll)
    return;

  var fields = root.querySelectorAll('.cbi-value-field');
  for (var i = 0; i < fields.length; i++) {
    if (fields[i] && fields[i].classList)
      fields[i].classList.add('cl-control-wrap');
  }

  var sections = root.querySelectorAll('.cbi-section');
  for (var j = 0; j < sections.length; j++) {
    if (sections[j] && sections[j].classList)
      sections[j].classList.add('cl-form-card');
  }
}

function randomSecret(len) {
  var chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  var out = '';
  var n = Math.max(6, parseInt(len, 10) || 6);
  for (var i = 0; i < n; i++) {
    out += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return out;
}

function enhanceDashPasswordField(root) {
  if (!root || !root.querySelector)
    return;

  var input = root.querySelector('input[id$=".dash_pass"], input[name$=".dash_pass"]');
  if (!input || input.dataset.clEnhanced === '1')
    return;

  input.dataset.clEnhanced = '1';
  input.type = 'password';
  input.autocomplete = 'new-password';

  var parent = input.parentNode;
  if (!parent)
    return;

  /* Remove LuCI default password helper controls (e.g. stray "*" button) */
  var children = parent.children ? Array.prototype.slice.call(parent.children) : [];
  children.forEach(function (el) {
    if (!el || el === input)
      return;
    var tag = (el.tagName || '').toUpperCase();
    var isBtnLike = tag === 'BUTTON'
      || (tag === 'INPUT' && String(el.type || '').toLowerCase() === 'button')
      || ((el.className || '').indexOf('cbi-button') >= 0);
    if (isBtnLike)
      parent.removeChild(el);
  });

  var wrap = E('div', { 'class': 'cl-pass-wrap' });
  parent.insertBefore(wrap, input);
  wrap.appendChild(input);

  var eyeBtn = E('button', {
    type: 'button',
    'class': 'btn cbi-button cl-pass-btn',
    title: '显示/隐藏',
    click: function (ev) {
      ev.preventDefault();
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      eyeBtn.textContent = show ? '🙈' : '👁';
    }
  }, '👁');

  var genBtn = E('button', {
    type: 'button',
    'class': 'btn cbi-button-action cl-pass-btn cl-pass-gen',
    click: function (ev) {
      ev.preventDefault();
      input.type = 'text';
      input.value = randomSecret(6);
      eyeBtn.textContent = '🙈';
      input.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }, '随机');

  wrap.appendChild(eyeBtn);
  wrap.appendChild(genBtn);
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

return view.extend({
  _tab:    'kernel',
  _logTab: 'plugin',

  load: function () {
    return Promise.all([
      fastResolve(clashoo.getCpuArch(), 1200, ''),
      fastResolve(clashoo.getLogStatus(), 1200, {}),
      fastResolve(clashoo.readLog(), 1200, ''),
      uci.load('clashoo'),
      fastResolve(L.resolveDefault(callHostHints(), {}), 1500, {})
    ]);
  },

  render: function (data) {
    var self      = this;
    var cpuArch   = data[0] || '';
    var logStatus = data[1] || {};
    var runLog    = data[2] || '';
    var hostHints = data[4] || {};
    this._hostHints = hostHints;

    if (!document.getElementById('cl-css')) {
      var s = document.createElement('style');
      s.id = 'cl-css'; s.textContent = CSS;
      document.head.appendChild(s);
    }
    if (!document.getElementById('cl-css-ext')) {
      var link = document.createElement('link');
      link.id = 'cl-css-ext';
      link.rel = 'stylesheet';
      link.href = L.resource('view/clashoo/clashoo.css') + '?v=20260521a4';
      document.head.appendChild(link);
    } else {
      document.getElementById('cl-css-ext').href = L.resource('view/clashoo/clashoo.css') + '?v=20260521a4';
    }

    var tabs = [
      { id: 'kernel', label: '内核与数据' },
      { id: 'rules',  label: '规则与控制' },
      { id: 'logs',   label: '日志' }
    ];
    var tabEls = {}, panelEls = {};

    var tabBar = E('div', { 'class': 'cl-tabs' },
      tabs.map(function (t) {
        var el = E('div', {
          'class': 'cl-tab' + (self._tab === t.id ? ' active' : ''),
          click: function () {
            Object.keys(tabEls).forEach(function (k) {
              tabEls[k].className   = 'cl-tab'   + (k === t.id ? ' active' : '');
              panelEls[k].className = 'cl-panel' + (k === t.id ? ' active' : '');
            });
            self._tab = t.id;
          }
        }, t.label);
        tabEls[t.id] = el;
        return el;
      })
    );

    var kernelPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'kernel' ? ' active' : ''), id: 'cl-panel-kernel' });
    panelEls['kernel'] = kernelPanel;
    this._buildComponentUpdatePanel(kernelPanel, cpuArch);
    this._buildBackupPanel(kernelPanel);
    this._buildKernelPanel(kernelPanel, cpuArch);

    var rulesPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'rules' ? ' active' : ''), id: 'cl-panel-rules' });
    panelEls['rules'] = rulesPanel;
    this._buildRulesForm(rulesPanel);

    var logsPanel = E('div', { 'class': 'cl-panel' + (this._tab === 'logs' ? ' active' : ''), id: 'cl-panel-logs' },
      this._buildLogsPanel(runLog)
    );
    panelEls['logs'] = logsPanel;

    this._tabEls = tabEls;
    this._panelEls = panelEls;
    poll.add(L.bind(this._pollLogs, this), 8);

    return E('div', { 'class': 'cl-wrap clashoo-container cl-system-page cl-form-page ' + getThemeClass() }, [tabBar, kernelPanel, rulesPanel, logsPanel]);
  },

  _detectMihomoArch: function (raw) {
    if (!raw) return '';
    if (raw === 'x86_64')             return 'amd64-compatible';
    if (/^aarch64/.test(raw))         return 'arm64';
    if (/^armv7|^arm_cortex-a[7-9]|^arm_cortex-a1[0-9]/.test(raw)) return 'armv7';
    if (/^armv6|^arm_cortex-a[56]/.test(raw))  return 'armv6';
    if (/^arm/.test(raw))             return 'armv5';
    if (/^i[3-6]86/.test(raw))        return '386';
    if (/^mips64el/.test(raw))        return 'mips64le';
    if (/^mips64/.test(raw))          return 'mips64';
    if (/^mipsel/.test(raw))          return 'mipsle';
    if (/^mips/.test(raw))            return 'mips';
    return '';
  },

  _buildComponentUpdatePanel: function (container, cpuArch) {
    var self = this;
    this._compCpuArch = cpuArch || '';
    this._compVariant = this._compVariant || {};
    this._compLatest = this._compLatest || {};
    var listEl = E('div', { 'class': 'cl-component-list' });
    var advListEl = E('div', { 'class': 'cl-component-list' });
    this._compAdvListEl = advListEl;
    var logEl = E('div', { 'class': 'cl-component-log', style: 'display:none' }, '');
    this._compLogEl = logEl;
    var archWrap = E('div', { 'class': 'cl-component-arch' });
    this._compArchWrap = archWrap;
    var refreshBtn = E('button', {
      'class': 'btn cbi-button cbi-button-neutral',
      click: function (ev) {
        ev.preventDefault();
        refreshBtn.disabled = true;
        refreshBtn.textContent = '检查中…';
        self._refreshComponentUpdatePanel(listEl, logEl, true);
      }
    }, '检查更新');
    this._compRefreshBtn = refreshBtn;

    /* advanced: core/data, collapsed by default to keep page compact.
       CPU arch stays outside — it decides core binary arch */
    var advWrap = E('div', { 'class': 'cl-component-adv cl-closed' }, [
      E('div', { 'class': 'cl-component-adv-bar' }, [
        E('span', {}, '高级设置（内核 / 数据组件）'),
        E('span', { 'class': 'cl-component-adv-chevron' }, '›')
      ]),
      E('div', { 'class': 'cl-component-adv-body' }, [advListEl])
    ]);
    advWrap.firstChild.addEventListener('click', function () {
      advWrap.classList.toggle('cl-closed');
    });

    /* wrap in cl-component-map, reuse LuCI .cbi-map container
       浅色出现灰托盘、暗色满宽对齐，与下方表单卡片同构 */
    container.appendChild(E('div', { 'class': 'cl-component-map' }, [
      E('div', { 'class': 'cl-component-card' }, [
        E('div', { 'class': 'cl-component-head' }, [
          E('div', {}, [
            E('h4', {}, '组件更新'),
            E('div', { 'class': 'cl-component-sub' }, '按组件单独更新，便于定位失败。点「检查更新」获取最新版本。')
          ]),
          refreshBtn
        ]),
        archWrap,
        listEl,
        advWrap,
        logEl
      ])
    ]));

    this._refreshComponentUpdatePanel(listEl, logEl, false);
  },

  /* 备份与还原：折腾内核/配置前的兜底。导出当前配置为 JSON 文件随时可导入还原；
     还原默认配置则把 UCI 设置重置为出厂值（订阅/配置文件保留）。仅含配置，不含内核。 */
  _buildBackupPanel: function (container) {
    function stamp() {
      var d = new Date();
      function p(n) { return (n < 10 ? '0' : '') + n; }
      return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) +
             '-' + p(d.getHours()) + p(d.getMinutes());
    }

    var exportBtn = E('button', { 'class': 'btn cbi-button cbi-button-neutral' }, '导出备份');
    exportBtn.addEventListener('click', function (ev) {
      ev.preventDefault();
      exportBtn.disabled = true;
      var orig = exportBtn.textContent;
      exportBtn.textContent = '导出中…';
      var done = function () { exportBtn.disabled = false; exportBtn.textContent = orig; };
      callBackupExport().then(function (r) {
        done();
        if (!r || !r.success) {
          clashoo.toast('导出失败：' + ((r && r.message) || '未知错误'), { kind: 'err' });
          return;
        }
        var text = JSON.stringify({ manifest: r.manifest, files: r.files || {} }, null, 2);
        var url = URL.createObjectURL(new Blob([text], { type: 'application/json' }));
        var a = E('a', { href: url, download: 'clashoo-backup-' + stamp() + '.json' });
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
        var n = 0; if (r.files) for (var k in r.files) n++;
        clashoo.toast('备份已导出（' + n + ' 个文件）', { kind: 'ok' });
      }).catch(function (e) {
        done();
        clashoo.toast('导出失败：' + (e.message || e), { kind: 'err' });
      });
    });

    var fileInput = E('input', {
      type: 'file', accept: '.json,application/json', style: 'display:none'
    });
    fileInput.addEventListener('change', function (ev) {
      var file = ev.target.files && ev.target.files[0];
      if (!file) return;
      if (!confirm('导入将用备份覆盖当前的全部配置与设置，原有的订阅/配置文件会被替换。确定继续吗？')) {
        fileInput.value = '';
        return;
      }
      var reader = new FileReader();
      reader.onload = function (e) {
        callBackupImport(e.target.result).then(function (r) {
          fileInput.value = '';
          if (r && r.success)
            clashoo.toast(r.message || '已还原备份，正在重启服务', { kind: 'ok' });
          else
            clashoo.toast('导入失败：' + ((r && r.message) || '未知错误'), { kind: 'err' });
        }).catch(function (err) {
          fileInput.value = '';
          clashoo.toast('导入失败：' + (err.message || err), { kind: 'err' });
        });
      };
      reader.readAsText(file);
    });
    var importBtn = E('button', { 'class': 'btn cbi-button cbi-button-neutral' }, '导入还原');
    importBtn.addEventListener('click', function (ev) {
      ev.preventDefault();
      fileInput.click();
    });

    var resetBtn = E('button', { 'class': 'btn cbi-button cbi-button-negative' }, '还原默认配置');
    resetBtn.addEventListener('click', function (ev) {
      ev.preventDefault();
      if (!confirm('将把 clashoo 的设置恢复为出厂默认值（订阅与配置文件保留）。确定继续吗？'))
        return;
      resetBtn.disabled = true;
      var orig = resetBtn.textContent;
      resetBtn.textContent = '还原中…';
      var done = function () { resetBtn.disabled = false; resetBtn.textContent = orig; };
      callBackupReset().then(function (r) {
        done();
        if (r && r.success)
          clashoo.toast(r.message || '已还原出厂默认设置', { kind: 'ok' });
        else
          clashoo.toast('还原失败：' + ((r && r.message) || '未知错误'), { kind: 'err' });
      }).catch(function (e) {
        done();
        clashoo.toast('还原失败：' + (e.message || e), { kind: 'err' });
      });
    });

    container.appendChild(E('div', { 'class': 'cl-component-map' }, [
      E('div', { 'class': 'cl-component-card' }, [
        E('div', { 'class': 'cl-component-head' }, [
          E('div', {}, [
            E('h4', {}, '备份与还原'),
            E('div', { 'class': 'cl-component-sub' },
              '折腾内核或配置前先导出一份，改坏了能一键导入还原。仅含配置与设置，不含内核。')
          ])
        ]),
        E('div', { 'class': 'cl-backup-actions' }, [exportBtn, importBtn, resetBtn, fileInput])
      ])
    ]));
  },

  _replaceChildren: function (node, children) {
    while (node.firstChild)
      node.removeChild(node.firstChild);
    children.forEach(function (child) { if (child) node.appendChild(child); });
  },

  /* latest map key: mihomo/sing-box with variant; smart fixed; pkg by id */
  _compLatestKey: function (comp, variant) {
    if (comp.id === 'smart') return 'smart';
    if (comp.variant) return comp.id + '_' + (variant || 'stable');
    return comp.id;
  },

  _compNorm: function (s) {
    return String(s || '').toLowerCase().replace(/^v/, '').replace(/~/g, '.');
  },

  _compVariantOf: function (comp) {
    if (!comp.variant) return '';
    if (this._compVariant[comp.id]) return this._compVariant[comp.id];
    var inst = String(comp.installed_version || '').toLowerCase();
    return /(?:alpha|beta|rc|pre)/.test(inst) ? 'alpha' : 'stable';
  },

  _compInstalledVersion: function (comp, variant) {
    if (comp && comp.installed_versions && comp.installed_versions[variant])
      return comp.installed_versions[variant];
    if (comp && comp.variant)
      return '';
    return (comp && comp.installed_version) || '';
  },

  /* install != latest = updatable (alpha compared by hash)*/
  _compUpdatable: function (comp, latestMap) {
    if (!comp) return false;
    /* lgbm has no version; compare local vs remote model sha256 (kind=data skips generic path) */
    if (comp.id === 'lgbm') {
      var rem = latestMap.lgbm, ins = comp.installed_version;
      return !!(rem && ins && this._compNorm(rem) !== this._compNorm(ins));
    }
    if (comp.kind === 'data') return false;
    var variant = this._compVariantOf(comp);
    var inst = this._compInstalledVersion(comp, variant);
    if (!inst || inst === '未安装' || inst === '未知') return false;
    var latest = latestMap[this._compLatestKey(comp, variant)];
    if (!latest) return false;
    return this._compNorm(latest) !== this._compNorm(inst);
  },

  _componentStatusText: function (comp, globalRunning) {
    if (comp.status === 'running')
      return comp.message || '更新中';
    if (comp.status === 'success')
      return comp.message || '已完成';
    if (comp.status === 'failed')
      return comp.message || '失败';
    if (globalRunning)
      return '等待当前任务完成';
    return '';
  },

  /* CPU arch: auto-detected + manual override (download_core UCI)*/
  _renderComponentArchRow: function (arch) {
    var self = this;
    arch = arch || {};
    var sys = arch.system || '未知';
    var detected = this._detectMihomoArch(this._compCpuArch || sys) || '';
    var cur = arch.download_core || detected || 'amd64-compatible';
    var archList = ['amd64-compatible', 'amd64-v1', 'amd64-v2', 'amd64-v3', 'arm64', 'armv7', 'armv6', 'armv5', '386', 'mips', 'mipsle', 'mips64', 'mips64le'];
    var sel = E('select', { 'class': 'cl-component-arch-sel' },
      archList.map(function (a) {
        return E('option', { value: a, selected: a === cur ? '' : null }, a);
      }));
    sel.addEventListener('change', function () {
      uci.set('clashoo', 'config', 'download_core', sel.value);
      uci.save()
        .then(function () { return clashoo.commitConfig(); })
        .then(function () { return clearClashooDirty(); })
        .then(function () { clashoo.toast('处理器架构已设为 ' + sel.value, { kind: 'info' }); })
        .catch(function () {});
      /* re-render row: show hint when mismatched */
      if (self._compArchWrap)
        self._replaceChildren(self._compArchWrap,
          [self._renderComponentArchRow({ system: sys, download_core: sel.value })]);
    });
    var row = [
      E('span', { 'class': 'cl-component-arch-label' }, '处理器架构'),
      E('span', { 'class': 'cl-component-arch-auto' }, '自动识别'),
      sel
    ];
    /* no hint when auto-detected matches; only show when manual choice differs */
    if (detected && cur !== detected)
      row.push(E('span', { 'class': 'cl-component-arch-hint' }, '推荐 ' + detected + '（按设备自动检测）'));
    return E('div', { 'class': 'cl-component-arch-row' }, row);
  },

  _renderComponentRow: function (comp, globalRunning, latestMap, listEl, logEl) {
    var self = this;
    var statusText = this._componentStatusText(comp, globalRunning);
    var inst = comp.installed_version || '';
    var instStable = !/(?:alpha|beta|rc|pre)/i.test(inst);

    /* mihomo / sing-box：行内稳定 / Alpha 切换 */
    var variant = '';
    var variantBox = null;
    if (comp.variant) {
      if (!self._compVariant[comp.id])
        self._compVariant[comp.id] = instStable ? 'stable' : 'alpha';
      variant = self._compVariant[comp.id];
      var mkV = function (v, label) {
        var active = variant === v;
        var b = E('button', { 'class': 'cl-comp-var' + (active ? ' on' : '') }, (active ? '✓ ' : '') + label);
        b.addEventListener('click', function (ev) {
          ev.preventDefault();
          self._compVariant[comp.id] = v;
          self._refreshComponentUpdatePanel(listEl, logEl, false);
        });
        return b;
      };
      variantBox = E('div', { 'class': 'cl-comp-var-box' }, [mkV('stable', '稳定版'), mkV('alpha', 'Alpha')]);
      inst = this._compInstalledVersion(comp, variant) || '未安装';
    }
    var latest = latestMap[this._compLatestKey(comp, variant || this._compVariantOf(comp))];
    if (!statusText && latest)
      statusText = '远端：' + latest;

    /* 绿色「可更新」徽标：最新版与已装不一致时显示 */
    var badge = this._compUpdatable(comp, latestMap)
      ? E('span', { 'class': 'cl-comp-updatable' }, '可更新')
      : null;

    var btn = E('button', {
      'class': 'btn cbi-button cbi-button-apply',
      disabled: globalRunning ? 'disabled' : null,
      click: function (ev) {
        ev.preventDefault();
        btn.disabled = true;
        btn.textContent = '提交中';
        if (self._compLogEl) self._compLogEl.style.display = '';
        clashoo.componentUpdate(comp.id, variant).then(function (res) {
          if (res && res.success)
            clashoo.toast('组件更新任务已提交', { kind: 'info' });
          else
            clashoo.toast((res && res.message) || '组件更新任务提交失败', { kind: 'error' });
          setTimeout(function () { self._refreshComponentUpdatePanel(listEl, logEl, false); }, 700);
        });
      }
    }, comp.status === 'running' ? '更新中' : '更新');

    var verChildren = [E('span', {}, '当前：' + (inst || '未知') + ' ')];
    if (badge) verChildren.push(badge);
    var verBlock = [E('div', {}, verChildren)];
    if (variantBox) verBlock.push(variantBox);

    return E('div', { 'class': 'cl-component-row' }, [
      E('div', {}, [
        E('div', { 'class': 'cl-component-name' }, comp.name || comp.id),
        E('div', { 'class': 'cl-component-desc' }, comp.description || '')
      ]),
      E('div', { 'class': 'cl-component-version' }, verBlock),
      E('div', { 'class': 'cl-component-status cl-st-' + (comp.status || 'idle') }, statusText),
      btn
    ]);
  },

  _refreshComponentUpdatePanel: function (listEl, logEl, doCheck) {
    var self = this;
    if (this._componentPollTimer) {
      clearTimeout(this._componentPollTimer);
      this._componentPollTimer = null;
    }

    clashoo.componentStatus().then(function (data) {
      var comps = data.components || [];
      if (self._compArchWrap)
        self._replaceChildren(self._compArchWrap, [self._renderComponentArchRow(data.arch)]);

      var paint = function () {
        var mainComps = [], advComps = [];
        comps.forEach(function (comp) {
          (COMPONENT_MAIN_IDS[comp.id] ? mainComps : advComps).push(comp);
        });
        var render = function (comp) {
          return self._renderComponentRow(comp, !!data.running, self._compLatest || {}, listEl, logEl);
        };
        self._replaceChildren(listEl, mainComps.map(render));
        if (self._compAdvListEl)
          self._replaceChildren(self._compAdvListEl, advComps.map(render));
      };
      paint();
      logEl.textContent = data.log || data.last_log || '暂无组件更新日志';

      if (data.running) {
        /* 有任务运行：展开日志，取消收起计时 */
        if (self._compLogHideTimer) {
          clearTimeout(self._compLogHideTimer);
          self._compLogHideTimer = null;
        }
        logEl.style.display = '';
        self._componentPollTimer = setTimeout(function () {
          self._refreshComponentUpdatePanel(listEl, logEl, false);
        }, 2000);
      } else {
        /* 任务结束：日志若展开着，8 秒后自动收起 */
        if (logEl.style.display !== 'none' && !self._compLogHideTimer) {
          self._compLogHideTimer = setTimeout(function () {
            logEl.style.display = 'none';
            self._compLogHideTimer = null;
          }, 8000);
        }
        if (doCheck) {
          clashoo.componentCheckUpdates().then(function (r) {
            self._compLatest = (r && r.latest) || {};
            paint();
            var n = comps.reduce(function (acc, c) {
              return acc + (self._compUpdatable(c, self._compLatest) ? 1 : 0);
            }, 0);
            if (self._compRefreshBtn) {
              self._compRefreshBtn.disabled = false;
              self._compRefreshBtn.textContent = '检查更新';
            }
            clashoo.toast(n > 0 ? (n + ' 项可更新') : '所有组件已是最新',
              { kind: n > 0 ? 'info' : 'success' });
          }).catch(function () {
            if (self._compRefreshBtn) {
              self._compRefreshBtn.disabled = false;
              self._compRefreshBtn.textContent = '检查更新';
            }
            clashoo.toast('检查更新失败，请检查网络', { kind: 'error' });
          });
        }
      }
    });
  },

  _buildKernelPanel: function (container, cpuArch) {
    var self = this;
    var detectedArch = this._detectMihomoArch(cpuArch);
    var m = new form.Map('clashoo', '', '');
    var s, o;

    s = m.section(form.NamedSection, 'config', 'clashoo', '后端核心');
    s.addremove = false;
    o = s.option(form.ListValue, 'core_type', '核心类型');
    o.value('mihomo', 'mihomo（Clash Meta 内核）');
    o.value('singbox', 'sing-box（需已安装并启用 clash_api）');
    o.description = '';

    s = m.section(form.NamedSection, 'config', 'clashoo', '管理面板配置');
    s.addremove = false;
    o = s.option(form.Value, 'dash_port', '面板端口');
    o.placeholder = '9090';
    o = s.option(form.Value, 'dash_pass', '访问密钥');
    o.placeholder = 'clashoo';
    o = s.option(form.ListValue, 'dashboard_panel', '面板 UI');
    ['metacubexd','yacd','zashboard','razord'].forEach(function(p){ o.value(p,p); });

    m.render().then(function (node) {
      decorateSystemForm(node);
      enhanceDashPasswordField(node);
      container.appendChild(node);
      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'cbi-button', click: function () {
          m.save().then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', '保存失败: ' + (e.message || e))); });
        }}, '保存配置'),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          saveCommitApplyMaybeReload(m, '配置已保存并热重载服务', '配置已保存，服务未启动')
            .catch(function (e) { ui.addNotification(null, E('p', '操作失败: ' + (e.message || e))); });
        }}, '应用配置')
      ]));
    });
  },

  _buildRulesForm: function (container) {
    var m = new form.Map('clashoo', '', '');
    var s, o;

    s = m.section(form.NamedSection, 'config', 'clashoo', '绕过规则');
    s.addremove = false;
    o = s.option(form.Flag, 'bypass_china',  '大陆 IP 绕过');
    o = s.option(form.ListValue, 'bypass_port_mode', '绕过端口');
    o.value('all', '所有端口');
    o.value('common', '常用端口');
    o.value('custom', '自定义');
    o.default = 'all';

    o = s.option(form.Value, 'bypass_port_custom', '自定义端口');
    o.depends('bypass_port_mode', 'custom');
    o.placeholder = '22,53,80,443,8080,8443';
    o.datatype = 'string';
    o.rmempty = true;

    o = s.option(form.Flag, 'sniffer_streaming', '嗅探功能（流媒体兼容）');
    o.default = '1';
    o.rmempty = false;
    o.description = '启用后自动注入 sniffer 配置，提升流媒体域名识别与分流稳定性。';

    s = m.section(form.NamedSection, 'config', 'clashoo', '局域网控制');
    s.addremove = false;
    o = s.option(form.ListValue, 'access_control', '访问控制');
    o.value('0', '所有设备'); o.value('1', '白名单'); o.value('2', '黑名单');

    /* Populate host hints for both IP list fields */
    var hints = this._hostHints || {};
    var hostOptions = [];
    var seen = {};
    Object.keys(hints).forEach(function (mac) {
      var h = hints[mac] || {};
      var macU = mac.toUpperCase();
      var addrs = h.ipaddrs || (h.ipv4 ? [h.ipv4] : []);
      addrs.forEach(function (ip) {
        if (ip && !seen[ip]) {
          seen[ip] = true;
          hostOptions.push([ip, ip + ' (' + macU + ')']);
        }
      });
    });

    o = s.option(form.DynamicList, 'proxy_lan_ips', 'IP白名单');
    o.placeholder = '192.168.1.100';
    o.depends('access_control', '1');
    hostOptions.forEach(function (kv) { o.value(kv[0], kv[1]); });

    o = s.option(form.DynamicList, 'reject_lan_ips', 'IP黑名单');
    o.placeholder = '192.168.1.100';
    o.depends('access_control', '2');
    hostOptions.forEach(function (kv) { o.value(kv[0], kv[1]); });

    s = m.section(form.NamedSection, 'config', 'clashoo', '自动化任务');
    s.addremove = false;
    o = s.option(form.Flag,  'auto_update',   '定时更新规则数据');
    o.description = '规则数据包含：大陆白名单（直连 IP 段）与 GeoIP / GeoSite 地理库';
    o = s.option(form.Value, 'auto_update_time',   '更新间隔（小时）');
    o = s.option(form.Flag,  'auto_clear_log',    '定时清理日志');
    o = s.option(form.Value, 'clear_time','清理间隔（小时）');
    o = s.option(form.ListValue, 'geoip_source', 'GeoIP 数据源');
    o.value('2', 'GitHub'); o.value('4', '自定义');

    m.render().then(function (node) {
      decorateSystemForm(node);
      container.appendChild(node);
      container.appendChild(E('div', { 'class': 'cl-save-bar' }, [
        E('button', { 'class': 'cbi-button', click: function () {
          m.save().then(function () { return clashoo.commitConfig(); })
            .then(function () { return clearClashooDirty(); })
            .then(function () { location.reload(); })
            .catch(function (e) { ui.addNotification(null, E('p', '保存失败: ' + (e.message || e))); });
        }}, '保存配置'),
        E('button', { 'class': 'btn cbi-button-action', click: function () {
          saveCommitApplyMaybeReload(m, '配置已保存并热重载服务', '配置已保存，服务未启动')
            .catch(function (e) { ui.addNotification(null, E('p', '操作失败: ' + (e.message || e))); });
        }}, '应用配置')
      ]));
    });
  },

  _buildLogsPanel: function (runLog) {
    var self = this;
    var logTypes = [
      { id: 'plugin', label: '插件日志', read: clashoo.readLog.bind(clashoo),              clear: clashoo.clearLog.bind(clashoo) },
      { id: 'core',   label: '核心日志', read: clashoo.readCoreLog.bind(clashoo),           clear: clashoo.clearCoreLog.bind(clashoo) },
      { id: 'update', label: '更新日志', read: clashoo.readUpdateMergedLog.bind(clashoo),   clear: clashoo.clearUpdateMergedLog.bind(clashoo) }
    ];
    var MAX_LINES = 5000;

    var state = { autoScroll: true, paused: false, filter: '' };

    function esc(s) {
      return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    /* Expose helpers for _pollLogs */
    self._buildLogLine = buildLine;
    self._applyLogFilter = applyFilter;

    /* parse level token; no keyword (e.g. mihomo info lines with [info] stripped) => info */
    function detectLevelToken(ln) {
      var m = ln.match(/\b(DEBUG|INFO|WARN(?:ING)?|ERROR|FATAL|PANIC)\b/i);
      if (!m) return 'info';
      var l = m[1].toUpperCase();
      if (l === 'DEBUG') return 'debug';
      if (l === 'INFO')  return 'info';
      if (l.startsWith('WARN')) return 'warn';
      if (l === 'FATAL' || l === 'PANIC') return 'fatal';
      return 'error';
    }
    function levelClass(token) {
      if (token === 'debug') return 'cl-log-debug';
      if (token === 'warn')  return 'cl-log-warn';
      if (token === 'error' || token === 'fatal') return 'cl-log-error';
      return 'cl-log-info';
    }

    var MONTHS = { Jan:'01',Feb:'02',Mar:'03',Apr:'04',May:'05',Jun:'06',Jul:'07',Aug:'08',Sep:'09',Oct:'10',Nov:'11',Dec:'12' };
    /* render a single line as colored HTML */
    function buildLine(ln) {
      var token = detectLevelToken(ln);
      var cls = levelClass(token);
      var ts = '', msg = ln;
      /* core syslog: Mon DD HH:MM:SS YYYY → MM-DD HH:MM:SS */
      var cm = ln.match(/^(\w{3})\s+(\d{1,2})\s+(\d{2}:\d{2}:\d{2})\s+\d{4}\s+\S+\.(\S+)\s+\S+\[\d+\]:\s+(.*)$/);
      if (cm) { ts = (MONTHS[cm[1]] || cm[1]) + '-' + cm[2].padStart(2,'0') + ' ' + cm[3]; msg = cm[5] || ln; }
      /* plugin / update: MM-DD HH:MM:SS [warn] message */
      else if (/^\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s/.test(ln)) {
        ts = ln.substring(0,14);
        msg = ln.substring(15);
        /* update: MM-DD HH:MM:SS - message → strip dash */
        if (msg.indexOf(' - ') === 0) msg = msg.substring(3);
      }
      if (ts) {
        return '<div class="cl-log-line ' + cls + '" data-level="' + token + '"><span class="cl-log-ts">' + esc(ts) + '</span><span class="cl-log-msg">' + esc(msg) + '</span></div>';
      }
      return '<div class="cl-log-line ' + cls + '" data-level="' + token + '">' + esc(ln) + '</div>';
    }

    function renderLines(text) {
      var lines = text.split('\n').filter(function(l) { return l; });
      var html = '';
      for (var i = 0; i < lines.length; i++) {
        html += buildLine(lines[i]);
      }
      return html;
    }

    function applyFilter() {
      var f = state.filter;   /* '' = all, else exact level: info/warn/error/fatal */
      var els = document.querySelectorAll('#cl-log-area .cl-log-line');
      for (var i = 0; i < els.length; i++) {
        if (!f || els[i].getAttribute('data-level') === f)
          els[i].classList.remove('cl-log-hidden');
        else
          els[i].classList.add('cl-log-hidden');
      }
    }

    var logTabEls = {};
    var logArea = E('div', { 'class': 'cl-log-area', id: 'cl-log-area' });
    logArea.innerHTML = runLog ? renderLines(runLog) : '<em>（空）</em>';

    var clearBtn = null;

    function activateLogTab(id) {
      var logType = logTypes.find(function (lt) { return lt.id === id; }) || logTypes[0];
      Object.keys(logTabEls).forEach(function (k) {
        logTabEls[k].className = 'cl-log-tab' + (k === logType.id ? ' active' : '');
      });
      self._logTab = logType.id;
      syncClearButton();
      return logType.read().then(function (content) {
        logArea.innerHTML = (content && content.trim()) ? renderLines(content) : '<em>（空）</em>';
        applyFilter();
        if (state.autoScroll) logArea.scrollTop = logArea.scrollHeight;
      });
    }
    this._activateLogTab = activateLogTab;

    var logTabBar = E('div', { 'class': 'cl-log-tabs' },
      logTypes.map(function (lt) {
        var el = E('span', {
          'class': 'cl-log-tab' + (self._logTab === lt.id ? ' active' : ''),
          click: function () { activateLogTab(lt.id); }
        }, lt.label);
        logTabEls[lt.id] = el;
        return el;
      })
    );

    var currentType = function () {
      return logTypes.find(function (lt) { return lt.id === self._logTab; }) || logTypes[0];
    };

    function syncClearButton() {
      if (!clearBtn) return;
      var ct = currentType();
      clearBtn.disabled = !ct.clear;
    }

    /* ---- toolbar ---- */
    var cbAuto = E('input', { type: 'checkbox', checked: 'checked' });
    cbAuto.addEventListener('change', function () { state.autoScroll = cbAuto.checked; });

    var cbPause = E('input', { type: 'checkbox' });
    cbPause.addEventListener('change', function () { state.paused = cbPause.checked; });

    var selFilter = E('select', { 'class': 'cbi-button', style: 'font-size:11px;padding:2px 8px' }, [
      E('option', { value: '' }, '全部'),
      E('option', { value: 'info' }, 'INFO'),
      E('option', { value: 'warn' }, 'WARN'),
      E('option', { value: 'error' }, 'ERROR'),
      E('option', { value: 'fatal' }, 'FATAL')
    ]);
    selFilter.addEventListener('change', function () {
      state.filter = selFilter.value;
      applyFilter();
    });

    var btnClearView = E('button', { 'class': 'cbi-button', style: 'font-size:11px;padding:2px 8px' }, '清空显示');
    btnClearView.addEventListener('click', function () { logArea.innerHTML = ''; });

    var btnDownload = E('button', { 'class': 'cbi-button', style: 'font-size:11px;padding:2px 8px' }, '下载');
    btnDownload.addEventListener('click', function () {
      var blob = new Blob([logArea.textContent || ''], { type: 'text/plain' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = 'clashoo-' + new Date().toISOString().replace(/[:.]/g, '-') + '.log';
      document.body.appendChild(a); a.click(); document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });

    clearBtn = E('button', { 'class': 'cbi-button', style: 'font-size:11px;padding:2px 8px' }, '清空文件');
    clearBtn.addEventListener('click', function () {
      var ct = currentType();
      if (!ct.clear) return;
      if (!confirm('确定要清空当前日志文件吗？此操作不可恢复。')) return;
      ct.clear().then(function () { logArea.innerHTML = ''; });
    });
    syncClearButton();

    var toolbar = E('div', { style: 'display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-bottom:8px' }, [
      E('label', { style: 'font-size:11px;display:inline-flex;align-items:center;gap:3px;cursor:pointer' }, [cbAuto, '自动滚动']),
      E('label', { style: 'font-size:11px;display:inline-flex;align-items:center;gap:3px;cursor:pointer' }, [cbPause, '暂停']),
      selFilter,
      btnClearView,
      btnDownload,
      clearBtn
    ]);

    return E('div', { 'class': 'cl-section cl-card cl-log-card' }, [
      E('h4', {}, '日志'),
      logTabBar,
      toolbar,
      logArea
    ]);
  },

  _pollLogs: function () {
    if (this._tab !== 'logs') return Promise.resolve();
    var self = this;
    var el = document.getElementById('cl-log-area');
    if (!el) return Promise.resolve();
    var cbPause = el.parentNode.querySelector('input[type="checkbox"]:nth-of-type(2)');
    if (cbPause && cbPause.checked) return Promise.resolve();
    var logFns = {
      plugin: clashoo.readLog.bind(clashoo),
      core:   clashoo.readCoreLog.bind(clashoo),
      update: clashoo.readUpdateMergedLog.bind(clashoo)
    };
    var readFn = logFns[this._logTab] || logFns.plugin;
    return readFn().then(function (content) {
      if (!content || !content.trim()) { el.innerHTML = '<em>（空）</em>'; return; }
      var html = '';
      var lines = content.split('\n').filter(function(l) { return l; });
      for (var i = 0; i < lines.length; i++) {
        html += self._buildLogLine(lines[i]);
      }
      el.innerHTML = html;
      self._applyLogFilter();
      var cbAuto = el.parentNode.querySelector('input[type="checkbox"]:first-of-type');
      if (!cbAuto || cbAuto.checked) el.scrollTop = el.scrollHeight;
    });
  },

  _switchTab: function (id) {
    var tabEls = this._tabEls || {};
    var panelEls = this._panelEls || {};
    Object.keys(tabEls).forEach(function (k) {
      tabEls[k].className = 'cl-tab' + (k === id ? ' active' : '');
      panelEls[k].className = 'cl-panel' + (k === id ? ' active' : '');
    });
    this._tab = id;
  },

  handleSaveApply: null,
  handleSave:      null,
  handleReset:     null
});
