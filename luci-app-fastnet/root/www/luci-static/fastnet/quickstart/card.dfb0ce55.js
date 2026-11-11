var D = (n, b, v) => new Promise((e, d) => {
  var l = (r) => {
    try {
      f(v.next(r));
    } catch (q) {
      d(q);
    }
  }, a = (r) => {
    try {
      f(v.throw(r));
    } catch (q) {
      d(q);
    }
  }, f = (r) => r.done ? e(r.value) : Promise.resolve(r.value).then(l, a);
  f((v = v.apply(n, b)).next());
});
import { defineAsyncComponent as ia, h as W, computed as z, ref as J, onMounted as ua, onUnmounted as pa, openBlock as C, createElementBlock as B, unref as c, normalizeClass as G, createElementVNode as s, createTextVNode as w, toDisplayString as o, createBlock as la, resolveDynamicComponent as oa, withCtx as fa, createCommentVNode as ca, reactive as ma } from "/luci-static/quickstart/card-runtime-v1.js";
const ga = '[data-fastnet-card]{--fn-down:var(--qs-card-accent);position:relative;isolation:isolate;container-type:inline-size;gap:12px;border-radius:inherit}[data-fastnet-card] .qs-card-header h2>svg{color:var(--fn-down)}[data-fastnet-card] .qs-card-primary{background:var(--qs-card-accent);color:var(--qs-card-panel);border-color:transparent;padding:6px 13px;border-radius:9px;font-weight:600}[data-fastnet-card] .qs-card-menu>summary{border-color:transparent;color:var(--qs-card-muted)}[data-fastnet-card] .fn-speed-stage{flex:1;min-height:0;display:flex;flex-direction:column;justify-content:center;gap:14px;padding:18px 20px;border-radius:14px;border:1px solid var(--qs-card-line);background:var(--qs-card-soft)}[data-fastnet-card] .fn-speed-caption{display:flex;align-items:center;justify-content:space-between;gap:6px;font-size:10px;letter-spacing:.7px;color:var(--qs-card-muted)}[data-fastnet-card] .fn-live{display:flex;align-items:center;gap:5px;letter-spacing:0;white-space:nowrap}[data-fastnet-card] .fn-live:before{content:"";width:5px;height:5px;border-radius:50%;background:var(--qs-card-muted)}[data-fastnet-card] .fn-live.is-active{color:var(--qs-card-accent)}[data-fastnet-card] .fn-live.is-active:before{background:currentColor;box-shadow:0 0 0 3px var(--qs-card-soft)}[data-fastnet-card] .qs-card-metrics{gap:18px;align-items:center;grid-template-columns:1.25fr 1fr}[data-fastnet-card] .qs-card-metrics strong{font-size:clamp(30px,12cqi,52px);line-height:1.15;letter-spacing:-1.7px;font-weight:700;margin-top:4px;color:var(--fn-down)}[data-fastnet-card] .qs-card-metrics>div+div{border-left:1px solid var(--qs-card-line);padding-left:18px}[data-fastnet-card] .qs-card-metrics>div+div strong{font-size:clamp(25px,8cqi,36px);color:var(--qs-card-text);letter-spacing:-.9px}[data-fastnet-card] .qs-card-metrics small{letter-spacing:0}[data-fastnet-card] .qs-card-time{gap:5px;font-size:10px}[data-fastnet-card] .qs-card-statuses{padding:0;border:0;gap:10px}[data-fastnet-card] .qs-card-statuses>div{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:3px 8px;padding:8px 10px;border:1px solid var(--qs-card-line);border-radius:8px;background:var(--qs-card-panel)}[data-fastnet-card] .qs-card-statuses span{display:flex;align-items:center;gap:6px;letter-spacing:.3px;margin:0;flex:none}[data-fastnet-card] .qs-card-statuses i{width:6px;height:6px;border-radius:50%;background:var(--qs-card-muted)}[data-fastnet-card] .qs-card-statuses [data-tone=good] i{background:var(--qs-card-good)}[data-fastnet-card] .qs-card-statuses [data-tone=warning] i{background:var(--qs-card-warning)}[data-fastnet-card].qs-card-summary{gap:3px;background:none}[data-fastnet-card].qs-card-summary .fn-speed-stage{display:block;flex:none;padding:0;border:0;background:none}[data-fastnet-card].qs-card-summary .fn-speed-caption{display:none}[data-fastnet-card].qs-card-summary .qs-card-metrics{grid-template-columns:1fr 1fr;gap:12px}[data-fastnet-card].qs-card-summary .qs-card-metrics strong{font-size:23px;letter-spacing:-.5px;margin:0}[data-fastnet-card].qs-card-summary .qs-card-metrics>div+div{padding:0;border:0}[data-fastnet-card].qs-card-summary .qs-card-statuses>div{padding:0;border:0;background:none;max-width:50%;flex-wrap:nowrap;gap:5px}[data-fastnet-card].qs-card-summary .qs-card-statuses span{margin:0;gap:4px}[data-fastnet-card].qs-card-summary .qs-card-statuses i{width:4px;height:4px}[data-fastnet-card].qs-card-summary .qs-card-primary{padding:2px 7px;border-radius:6px}@media(max-width:600px){[data-fastnet-card]:not(.qs-card-summary) .fn-speed-stage{padding:14px;gap:12px}[data-fastnet-card]:not(.qs-card-summary) .qs-card-metrics strong{font-size:36px}[data-fastnet-card]:not(.qs-card-summary) .qs-card-metrics>div+div strong{font-size:28px}}[data-fastnet-card].fn-dense:not(.qs-card-summary){gap:5px;padding:10px 14px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-speed-stage{padding:6px 12px;gap:3px;min-height:81px;flex-shrink:0}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-speed-caption{display:none}[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-metrics strong{font-size:28px;line-height:1.15;margin:0}[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-metrics>div+div strong{font-size:23px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-statuses>div{padding:6px 9px}[data-fastnet-card] .fn-lan-summary{flex:none;min-width:0;padding:0 20px;color:var(--qs-card-text)}[data-fastnet-card] .fn-lan-caption{display:flex;align-items:baseline;justify-content:space-between;flex-wrap:wrap;gap:2px 8px;font-size:10px;color:var(--qs-card-muted)}[data-fastnet-card] .fn-lan-caption time{font-variant-numeric:tabular-nums;white-space:nowrap}[data-fastnet-card] .fn-lan-metrics{display:grid;grid-template-columns:1.25fr 1fr;gap:18px;margin-top:6px}[data-fastnet-card] .fn-lan-metrics>div{min-width:0}[data-fastnet-card] .fn-lan-metrics>div+div{padding-left:18px;border-left:1px solid var(--qs-card-line)}[data-fastnet-card] .fn-lan-label{display:block;font-size:10px;color:var(--qs-card-muted)}[data-fastnet-card] .fn-lan-metrics strong{display:flex;align-items:baseline;gap:4px;font-size:20px;line-height:1.3;white-space:nowrap;font-weight:600;font-variant-numeric:tabular-nums;letter-spacing:-.4px}[data-fastnet-card] .fn-lan-metrics small{font-size:10px;letter-spacing:0;font-weight:400;color:var(--qs-card-muted)}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-summary{padding:0 12px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-metrics{margin-top:2px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-metrics strong{font-size:17px}[data-fastnet-card].qs-card-summary .fn-lan-summary{display:grid;grid-template-columns:28px minmax(0,1fr);align-items:center;gap:5px;padding:0}[data-fastnet-card].qs-card-summary .fn-lan-route,[data-fastnet-card].qs-card-summary .fn-lan-caption time,[data-fastnet-card].qs-card-summary .fn-lan-label{display:none}[data-fastnet-card].qs-card-summary .fn-lan-metrics{grid-template-columns:1fr 1fr;gap:8px;margin:0}[data-fastnet-card].qs-card-summary .fn-lan-metrics>div+div{border:0;padding:0}[data-fastnet-card].qs-card-summary .fn-lan-metrics strong{font-size:12px;font-weight:500;letter-spacing:0}[data-fastnet-card].qs-card-summary .fn-lan-metrics small{font-size:9px}@container (max-width:340px){[data-fastnet-card] .fn-lan-summary{padding:0 14px}[data-fastnet-card] .fn-lan-metrics strong{font-size:18px}}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-label,[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-progress small{display:none}[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-progress>button{min-height:26px;padding:2px 8px}@media(pointer:coarse){[data-fastnet-card].fn-dense:not(.qs-card-summary) .qs-card-progress>button{min-width:44px;min-height:44px}}@media(pointer:coarse){[data-fastnet-card].fn-dense:not(.qs-card-summary){padding:8px 14px;gap:4px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-summary{display:grid;grid-template-columns:28px minmax(0,1fr);gap:5px;align-items:center}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-route,[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-caption time{display:none}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-metrics{margin:0;grid-template-columns:1fr 1fr;gap:8px}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-metrics>div+div{padding:0;border:0}[data-fastnet-card].fn-dense:not(.qs-card-summary) .fn-lan-metrics strong{font-size:14px}}@media(pointer:coarse){[data-fastnet-card].qs-card-summary{gap:2px}[data-fastnet-card].qs-card-summary .qs-card-metrics span{display:block;font-size:10px;line-height:1.2}[data-fastnet-card].qs-card-summary .qs-card-metrics strong{font-size:21px;line-height:1.1}[data-fastnet-card].qs-card-summary .qs-card-time{line-height:1.2}}', k = (n) => n && ["running", "cancel_requested"].includes(n.state), K = ["running", "cancel_requested", "succeeded", "partial", "failed", "cancelled", "interrupted"];
function ya(n) {
  var b, v, e, d;
  if ((n == null ? void 0 : n.schemaVersion) !== 1 || !["ready", "disabled", "unavailable"].includes((b = n.service) == null ? void 0 : b.state) || !("latest" in n) || !("task" in n)) throw Error("invalid_summary");
  if ((v = n.latest) != null && v.bandwidth) {
    const l = n.latest.bandwidth;
    if (![l.downloadBps, l.uploadBps].every((a) => typeof a == "number" && Number.isFinite(a) && a >= 0) || !l.measuredAt || !Number.isFinite(Date.parse(l.measuredAt))) throw Error("invalid_bandwidth");
  }
  if (n.task && !K.includes(n.task.state)) throw Error("invalid_task");
  for (const l of ["download", "upload", "nat", "ipv6"]) if (n.latest) {
    const a = n.latest[l];
    if (!a || !["ok", "unavailable", "error", "not_tested"].includes(a.status) || a.value !== null && (["download", "upload"].includes(l) ? typeof a.value != "number" || !Number.isFinite(a.value) || a.value < 0 : typeof a.value != "string")) throw Error("invalid_measurement");
  }
  for (const l of ["download", "upload", "lanDownload", "lanUpload", "lanPing"]) {
    const a = (d = (e = n.latestResults) == null ? void 0 : e[l]) == null ? void 0 : d.value;
    if (a != null && (!Number.isFinite(a) || a < 0)) throw Error("invalid_measurement");
  }
  return n;
}
function va(n) {
  var e, d;
  const b = n == null ? void 0 : n.latestResults;
  if (b != null && b.download || b != null && b.upload) {
    const l = b.download, a = b.upload;
    return { downloadBps: (e = l == null ? void 0 : l.value) != null ? e : null, uploadBps: (d = a == null ? void 0 : a.value) != null ? d : null, measuredAt: [l == null ? void 0 : l.measuredAt, a == null ? void 0 : a.measuredAt].filter(Boolean).sort().pop(), mixed: !!(l && a && l.runId !== a.runId) };
  }
  const v = n == null ? void 0 : n.latest;
  return v ? v.bandwidth || { downloadBps: v.download.status === "ok" ? v.download.value : null, uploadBps: v.upload.status === "ok" ? v.upload.value : null, measuredAt: v.measuredAt } : null;
}
function E(n) {
  return n == null ? "—" : n > 0 && n < 1e5 ? "<0.1" : (n / 1e6).toLocaleString("en-US", { maximumFractionDigits: n >= 1e8 ? 0 : 1 });
}
function H(n, b) {
  return !n || !Number.isFinite(Date.parse(n)) ? "—" : new Date(n).toLocaleString(b === "en" ? "en-GB" : "zh-CN", { year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hour12: !1 });
}
function xa(n, b = (e) => e, v = globalThis) {
  const e = b({ loading: !1, summary: null, task: null, submitting: !1, cancelling: !1, error: "", errorAction: "read", paused: !1, failures: 0 });
  let d = !0, l = !0, a, f, r, q = null, y = 0;
  const h = () => {
    v.clearTimeout(a), a = void 0, f == null || f.abort(), f = void 0, y++;
  }, N = (u) => [401, 403].includes(u == null ? void 0 : u.status) ? "permission" : (u == null ? void 0 : u.status) === 404 ? "upgrade" : "unavailable", S = () => {
    d && l && !e.paused && (a = v.setTimeout(k(e.task) ? I : _, k(e.task) ? 2e3 : 15e3));
  };
  function I() {
    return D(this, null, function* () {
      if (!d || !l || !k(e.task)) return;
      const u = e.task.id, m = ++y;
      f = new AbortController();
      try {
        const g = yield n.request("/task?id=" + encodeURIComponent(u), { signal: f.signal });
        if (!d || m !== y) return;
        if (g.id !== u || !K.includes(g.state)) throw Error("invalid_task");
        if (e.task = g, e.failures = 0, e.error = "", !k(g)) {
          q = null, yield _();
          return;
        }
      } catch (g) {
        if (!d || m !== y) return;
        e.failures++, e.error = N(g), e.errorAction = "read", (e.failures >= 3 || ["permission", "upgrade"].includes(e.error)) && (e.paused = !0);
      } finally {
        d && m === y && (f = void 0, S());
      }
    });
  }
  function _() {
    return D(this, null, function* () {
      if (h(), !d || !l) return;
      const u = y;
      e.loading = !0, f = new AbortController();
      try {
        const m = ya(yield n.request("/summary", { signal: f.signal }));
        if (!d || u !== y) return;
        e.summary = m, e.task = m.task || m.lastTask || null, e.error = "", e.failures = 0, e.paused = !1, k(e.task) && (q = null);
      } catch (m) {
        d && u === y && (e.error = N(m), e.errorAction = "read", e.failures++, e.paused = e.failures >= 3 || ["permission", "upgrade"].includes(e.error));
      } finally {
        d && u === y && (e.loading = !1, f = void 0, S());
      }
    });
  }
  function V() {
    return D(this, null, function* () {
      var m;
      if (!d || e.error === "permission" || e.submitting || k(e.task) || e.loading || ((m = e.summary) == null ? void 0 : m.service.state) !== "ready") return;
      h();
      const u = y;
      e.submitting = !0, e.error = "", r = new AbortController(), q || (q = Array.from(crypto.getRandomValues(new Uint8Array(16)), (g) => g.toString(16).padStart(2, "0")).join(""));
      try {
        const g = yield n.request("/run", { method: "POST", body: JSON.stringify({ idempotencyKey: q }), signal: r.signal });
        if (!d) return;
        if (!K.includes(g.state)) throw Error("invalid_task");
        if (q = null, u !== y) return;
        e.task = g, e.paused = !1, e.failures = 0, k(g) ? S() : yield _();
      } catch (g) {
        if (!d || u !== y) return;
        (g == null ? void 0 : g.status) === 409 ? (q = null, yield _()) : (e.error = N(g), e.errorAction = ["permission", "upgrade"].includes(e.error) ? "read" : "run", g != null && g.status && g.status < 500 && (q = null));
      } finally {
        d && (e.submitting = !1, r = void 0);
      }
    });
  }
  function M() {
    return D(this, null, function* () {
      if (!d || !k(e.task) || e.cancelling) return;
      h();
      const u = y;
      e.cancelling = !0, r = new AbortController();
      try {
        const m = yield n.request("/cancel", { method: "POST", body: JSON.stringify({ id: e.task.id }), signal: r.signal });
        if (!d || u !== y) return;
        e.task = m, k(m) ? S() : yield _();
      } catch (m) {
        d && u === y && (e.error = N(m), e.errorAction = "read", S());
      } finally {
        d && (e.cancelling = !1, r = void 0);
      }
    });
  }
  return { state: e, start: V, stop: M, reload: _, visibility(u) {
    l = u, h(), u && _();
  }, dispose() {
    d = !1, h(), r == null || r.abort();
  } };
}
const ba = ["data-task-id"], qa = { class: "qs-card-header" }, ha = {
  key: 0,
  class: "widget-action-group"
}, wa = {
  key: 1,
  class: "qs-card-actions"
}, ka = { class: "qs-card-menu" }, _a = ["aria-label"], Aa = { class: "fn-speed-stage" }, Ca = { class: "fn-speed-caption" }, Na = { class: "qs-card-metrics" }, Sa = { class: "qs-card-time" }, Ta = ["datetime"], za = ["aria-label"], Ba = { class: "fn-lan-caption" }, Ra = { class: "fn-lan-route" }, Fa = ["datetime"], Pa = { class: "fn-lan-metrics" }, Da = { class: "fn-lan-label" }, Ea = { class: "fn-lan-label" }, Ia = { class: "qs-card-statuses" }, La = ["data-tone"], Ua = ["title"], Va = ["data-tone"], Ma = ["title"], Oa = {
  key: 0,
  class: "qs-card-progress",
  role: "status"
}, ja = ["disabled"], $a = {
  key: 1,
  class: "qs-card-alert",
  role: "alert"
}, Wa = {
  key: 2,
  class: "qs-card-alert",
  role: "status"
}, Ha = {
  __name: "Card",
  props: ["context"],
  setup(n) {
    const b = ia(() => import("./chunk.31ac0177.js")), v = ia({ loader: () => import("./chunk.1932f6b1.js"), timeout: 8e3, errorComponent: { render: () => W("p", { role: "alert", style: "padding:24px" }, [W("span", "FastNet 暂时无法打开 / Unable to open FastNet. "), W("a", { href: "/cgi-bin/luci/admin/services/fastnet/open", target: "_blank", rel: "noopener" }, "新窗口打开 / Open in new window ↗")]) } }), e = n, d = e.context, l = d.locale === "en" ? "en" : "zh-cn", a = (i, t) => l === "en" ? t : i, f = xa(d, ma), r = f.state, q = "/cgi-bin/luci/admin/services/fastnet", y = z(() => va(r.summary)), h = z(() => k(r.task)), N = z(() => {
      var i, t, p, x, A, P;
      return [(p = (t = (i = r.summary) == null ? void 0 : i.latestResults) == null ? void 0 : t.lanDownload) == null ? void 0 : p.measuredAt, (P = (A = (x = r.summary) == null ? void 0 : x.latestResults) == null ? void 0 : A.lanUpload) == null ? void 0 : P.measuredAt].filter(Boolean).sort().pop();
    }), S = { preparing: a("准备测速", "Preparing"), ping: a("检测延迟", "Testing latency"), download: a("测试下载", "Testing download"), upload: a("测试上传", "Testing upload"), nat: a("检测 NAT", "Checking NAT"), ipv6: a("检测 IPv6", "Checking IPv6") }, I = z(() => {
      var i, t;
      return ((i = r.task) == null ? void 0 : i.state) === "cancel_requested" ? a("正在停止", "Stopping") : S[(t = r.task) == null ? void 0 : t.stage] || a("测速中", "Testing");
    }), _ = z(() => r.error === "permission" ? a("登录已失效或权限不足，请重新登录", "Session expired or permission denied; sign in again") : r.error === "upgrade" ? a("插件接口不可用，请检查或升级 FastNet", "Plugin API unavailable; check or update FastNet") : r.paused ? a("连接连续失败，已暂停查询；后台任务继续运行", "Queries paused after repeated failures; the background task continues") : a("暂时无法确认结果，保留已有数据", "Result unavailable; existing data retained")), V = z(() => [{ id: "details", label: a("查看上次结果", "Last result details") }, { id: "history", label: a("测速历史", "Test history") }, { id: "reload", label: a("重新读取", "Reload") }, { id: "settings", label: a("插件设置", "Plugin settings") }, { id: "full", label: a("完整 FastNet", "Full FastNet") }]);
    function M(i) {
      i === "details" ? X() : i === "history" ? T("history") : i === "reload" ? f.reload() : i === "settings" ? window.open(q, "_blank", "noopener") : i === "full" && T();
    }
    const u = J(!1), m = J(null), g = J(!1);
    let R, F, O = !0;
    function Q(i) {
      var p, x;
      const t = (x = (p = r.summary) == null ? void 0 : p.latest) == null ? void 0 : x[i];
      return j(i) || (t == null ? void 0 : t.status) === "error" ? "warning" : (t == null ? void 0 : t.status) === "ok" ? "good" : "neutral";
    }
    function T(i) {
      var p, x;
      const t = (p = i == null ? void 0 : i.currentTarget) == null ? void 0 : p.closest("details");
      t == null || t.removeAttribute("open"), (x = t == null ? void 0 : t.querySelector("summary")) == null || x.focus({ preventScroll: !0 }), u.value = !0, f.visibility(!1), d.openDetails(v, { context: d, locale: l, view: i === "history" ? "history" : "quick" }, { wide: !0, headerAction: { href: q + "/open", label: a("新窗口打开", "Open in new window") }, onClose() {
        u.value = !1, f.visibility(!document.hidden && !u.value && O);
      } });
    }
    const j = (i) => {
      var t, p, x;
      return !h.value && !!((x = (p = (t = r.summary) == null ? void 0 : t.lastTask) == null ? void 0 : p.issues) != null && x[i]);
    };
    function L(i) {
      var x, A;
      const t = (A = (x = r.summary) == null ? void 0 : x.latest) == null ? void 0 : A[i];
      let p;
      return !t || t.status === "not_tested" ? p = a("未检测", "Not tested") : t.status === "error" ? p = a("检测失败", "Probe failed") : t.status === "unavailable" ? p = a("不可用", "Unavailable") : i === "ipv6" ? p = /部分|准备度 [0-9]\/10/.test(t.value) ? a("部分可用", "Partly available") : a("可用", "Available") : p = /port.?restricted/i.test(t.value) ? a("端口受限锥形", "Port Restricted Cone") : /restricted.*cone/i.test(t.value) ? a("受限锥形", "Restricted Cone") : /full.?cone/i.test(t.value) ? a("全锥形", "Full Cone") : /symmetric/i.test(t.value) ? a("对称型", "Symmetric") : t.value, j(i) ? p + " · " + a("本次失败", "latest failed") : p;
    }
    function X(i) {
      var p, x;
      const t = (p = i == null ? void 0 : i.currentTarget) == null ? void 0 : p.closest("details");
      t == null || t.removeAttribute("open"), (x = t == null ? void 0 : t.querySelector("summary")) == null || x.focus({ preventScroll: !0 }), d.openDetails(b, { state: r, locale: l, stamp: H, mbps: E });
    }
    function U() {
      f.visibility(!document.hidden && !u.value && O);
    }
    return ua(() => {
      R = new ResizeObserver(() => {
        var i;
        g.value = ((i = m.value) == null ? void 0 : i.clientHeight) < 380;
      }), m.value && R.observe(m.value), F = new IntersectionObserver((i) => {
        var t;
        O = ((t = i[0]) == null ? void 0 : t.isIntersecting) !== !1, U();
      }), m.value && F.observe(m.value), document.addEventListener("visibilitychange", U), U();
    }), pa(() => {
      R == null || R.disconnect(), F == null || F.disconnect(), document.removeEventListener("visibilitychange", U), f.dispose();
    }), (i, t) => {
      var p, x, A, P, Y, Z, aa, ta, ea, sa, na, ra, da;
      return C(), B("article", {
        ref_key: "root",
        ref: m,
        class: G(["qs-card-content", { "qs-card-summary": c(d).form === "summary", "fn-dense": g.value }]),
        "data-fastnet-card": "",
        "data-task-id": h.value ? c(r).task.id : void 0
      }, [
        s("header", qa, [
          s("h2", null, [
            t[4] || (t[4] = s("svg", {
              viewBox: "0 0 24 24",
              "aria-hidden": "true"
            }, [
              s("path", { d: "M3 12h4l3-8 4 16 3-8h4" })
            ], -1)),
            w(o(a("外网测速", "Internet speed")), 1)
          ]),
          (p = c(d).components) != null && p.PrimaryAction && ((x = c(d).components) != null && x.Menu) ? (C(), B("div", ha, [
            (C(), la(oa(c(d).components.PrimaryAction), {
              icon: "activity",
              "data-fastnet-test": "",
              onClick: T
            }, {
              default: fa(() => [
                w(o(h.value ? a("查看进度", "View progress") : a("测速", "Test")), 1)
              ]),
              _: 1
            })),
            (C(), la(oa(c(d).components.Menu), {
              label: a("外网测速更多操作", "Internet speed actions"),
              items: V.value,
              onSelect: M
            }, null, 40, ["label", "items"]))
          ])) : (C(), B("div", wa, [
            s("button", {
              class: "qs-card-primary",
              "data-fastnet-test": "",
              onClick: T
            }, o(h.value ? a("查看进度", "View progress") : a("测速", "Test")), 1),
            s("details", ka, [
              s("summary", {
                "aria-label": a("外网测速更多操作", "Internet speed actions")
              }, "⋮", 8, _a),
              s("div", null, [
                s("button", {
                  "data-fastnet-details": "",
                  onClick: X
                }, o(a("查看上次结果", "Last result details")), 1),
                s("button", {
                  onClick: t[0] || (t[0] = ($) => T("history"))
                }, o(a("测速历史", "Test history")), 1),
                s("button", {
                  onClick: t[1] || (t[1] = ($) => c(f).reload())
                }, o(a("重新读取", "Reload")), 1),
                s("a", {
                  href: q,
                  target: "_blank",
                  rel: "noopener"
                }, o(a("插件设置", "Plugin settings")), 1),
                s("button", { onClick: T }, o(a("完整 FastNet", "Full FastNet")), 1)
              ])
            ])
          ]))
        ]),
        s("div", Aa, [
          s("div", Ca, [
            s("span", null, "WAN · " + o(a("最近有效结果", "LATEST VALID RESULTS")), 1),
            s("span", {
              class: G(["fn-live", { "is-active": h.value }])
            }, o(h.value ? I.value : (A = y.value) != null && A.measuredAt ? a("已保存", "Saved") : a("等待测速", "Ready to test")), 3)
          ]),
          s("div", Na, [
            s("div", null, [
              s("span", null, "↓ " + o(a("上次下载", "Last download")), 1),
              s("strong", null, [
                w(o(c(E)((P = y.value) == null ? void 0 : P.downloadBps)), 1),
                t[5] || (t[5] = s("small", null, "Mbps", -1))
              ])
            ]),
            s("div", null, [
              s("span", null, "↑ " + o(a("上次上传", "Last upload")), 1),
              s("strong", null, [
                w(o(c(E)((Y = y.value) == null ? void 0 : Y.uploadBps)), 1),
                t[6] || (t[6] = s("small", null, "Mbps", -1))
              ])
            ])
          ]),
          s("p", Sa, [
            w(o(a("上次测速", "Last tested")) + " ", 1),
            s("time", {
              datetime: ((Z = y.value) == null ? void 0 : Z.measuredAt) || void 0
            }, o((aa = y.value) != null && aa.measuredAt ? c(H)(y.value.measuredAt, c(l)) : a("尚未测速", "No test yet")), 9, Ta)
          ])
        ]),
        s("section", {
          class: "fn-lan-summary",
          "aria-label": a("内网测速结果", "LAN speed results")
        }, [
          s("div", Ba, [
            s("span", null, [
              t[7] || (t[7] = w("LAN ", -1)),
              s("span", Ra, "· " + o(a("浏览器 → 路由器", "Browser → Router")), 1)
            ]),
            s("time", {
              datetime: N.value || void 0
            }, o(c(H)(N.value, c(l))), 9, Fa)
          ]),
          s("div", Pa, [
            s("div", null, [
              s("span", Da, o(a("下载", "Download")), 1),
              s("strong", null, [
                w("↓ " + o(c(E)((sa = (ea = (ta = c(r).summary) == null ? void 0 : ta.latestResults) == null ? void 0 : ea.lanDownload) == null ? void 0 : sa.value)), 1),
                t[8] || (t[8] = s("small", null, "Mbps", -1))
              ])
            ]),
            s("div", null, [
              s("span", Ea, o(a("上传", "Upload")), 1),
              s("strong", null, [
                w("↑ " + o(c(E)((da = (ra = (na = c(r).summary) == null ? void 0 : na.latestResults) == null ? void 0 : ra.lanUpload) == null ? void 0 : da.value)), 1),
                t[9] || (t[9] = s("small", null, "Mbps", -1))
              ])
            ])
          ])
        ], 8, za),
        s("div", Ia, [
          s("div", {
            "data-tone": Q("nat")
          }, [
            t[10] || (t[10] = s("span", null, [
              s("i", { "aria-hidden": "true" }),
              w("NAT")
            ], -1)),
            s("strong", {
              title: L("nat")
            }, o(L("nat")), 9, Ua)
          ], 8, La),
          s("div", {
            "data-tone": Q("ipv6")
          }, [
            t[11] || (t[11] = s("span", null, [
              s("i", { "aria-hidden": "true" }),
              w("IPv6")
            ], -1)),
            s("strong", {
              class: G({ "qs-card-warning": j("ipv6") }),
              title: L("ipv6")
            }, o(L("ipv6")), 11, Ma)
          ], 8, Va)
        ]),
        h.value ? (C(), B("div", Oa, [
          s("span", null, [
            w(o(I.value), 1),
            s("small", null, o(a("上次有效结果保持显示", "Previous valid results remain visible")), 1)
          ]),
          s("button", {
            disabled: c(r).cancelling || c(r).task.state === "cancel_requested",
            onClick: t[2] || (t[2] = ($) => c(f).stop())
          }, o(c(r).cancelling || c(r).task.state === "cancel_requested" ? a("正在停止", "Stopping") : a("停止", "Stop")), 9, ja)
        ])) : ca("", !0),
        c(r).error ? (C(), B("p", $a, [
          w(o(_.value) + " ", 1),
          s("button", {
            onClick: t[3] || (t[3] = ($) => c(r).errorAction === "run" ? T() : c(f).reload())
          }, o(c(r).paused ? a("恢复查询", "Resume queries") : a("重试", "Retry")), 1)
        ])) : c(r).summary && c(r).summary.service.state !== "ready" ? (C(), B("p", Wa, [
          w(o(c(r).summary.service.state === "disabled" ? a("服务未启用", "Service disabled") : a("服务暂不可用", "Service unavailable")) + " ", 1),
          s("a", { href: q }, o(a("打开设置", "Open settings")), 1)
        ])) : ca("", !0)
      ], 10, ba);
    };
  }
};
if (!document.getElementById("fastnet-card-v1-style")) {
  const n = document.createElement("style");
  n.id = "fastnet-card-v1-style", n.textContent = ga, document.head.appendChild(n);
}
const Ka = 1;
export {
  Ka as apiVersion,
  Ha as default
};
