var S = (p, d, t) => new Promise((_, o) => {
  var u = (i) => {
    try {
      n(t.next(i));
    } catch (a) {
      o(a);
    }
  }, f = (i) => {
    try {
      n(t.throw(i));
    } catch (a) {
      o(a);
    }
  }, n = (i) => i.done ? _(i.value) : Promise.resolve(i.value).then(u, f);
  n((t = t.apply(p, d)).next());
});
import { ref as v, computed as B, watch as H, onMounted as L, onUnmounted as O, openBlock as w, createElementBlock as g, createElementVNode as x, createCommentVNode as y, toDisplayString as b } from "/luci-static/quickstart/card-runtime-v1.js";
function R(p, d = location) {
  const t = new URL(p);
  if (t.protocol !== "http:" || t.hostname !== d.hostname || t.pathname !== "/webui/" || t.username || t.password || t.hash) throw Error("invalid_direct_target");
  return { url: t.href, origin: t.origin, mixedContent: d.protocol === "https:" };
}
const j = ".fn-web-dialog{width:100%;min-width:0;min-height:0;display:flex;flex-direction:column;background:var(--qs-card-panel);color:var(--qs-card-text)}.fn-web-frame{position:relative;flex:1;min-height:0}.fn-web-frame iframe{display:block;border:0;width:100%;height:100%;background:var(--qs-card-panel)}.fn-web-loading{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;padding:24px;text-align:center;background:var(--qs-card-panel);color:var(--qs-card-muted)}.fn-web-loading strong{color:var(--qs-card-text);font-size:16px}.fn-web-loading p{font-size:12px;line-height:1.7;max-width:360px;margin:0}.fn-web-loading button{font:inherit;color:var(--qs-card-accent);border:1px solid var(--qs-card-line);background:var(--qs-card-soft);padding:10px 20px;border-radius:8px;cursor:pointer}.fn-web-loading a{color:var(--qs-card-accent);font-size:14px}.fn-web-footnote{font-size:10px;color:var(--qs-card-muted);line-height:1.6;margin:0!important;padding:9px 20px;border-top:1px solid var(--qs-card-line)}@media(max-width:600px){.fn-web-footnote{padding:8px 14px}}", U = {
  class: "fn-web-dialog",
  "data-fastnet-web-dialog": ""
}, W = { class: "fn-web-frame" }, A = ["src", "title"], D = ["role"], M = ["href"], V = { class: "fn-web-footnote" }, J = {
  __name: "WebDialog",
  props: ["context", "locale", "view"],
  emits: ["close"],
  setup(p, { emit: d }) {
    if (!document.getElementById("fastnet-web-v1-style")) {
      const e = document.createElement("style");
      e.id = "fastnet-web-v1-style", e.textContent = j, document.head.appendChild(e);
    }
    const t = p, _ = d, o = (e, r) => t.locale === "en" ? r : e, u = v(null), f = v(!1), n = v(!1), i = v(0), a = v(null), P = B(() => {
      if (!a.value) return "";
      const e = new URL(a.value.url);
      return e.searchParams.delete("embed"), e.searchParams.delete("theme"), e.href;
    });
    let c, s, k = !1;
    function z() {
      clearTimeout(c), c = setTimeout(() => {
        f.value || (n.value = !0);
      }, 15e3);
    }
    function T() {
      return S(this, null, function* () {
        s == null || s.abort(), s = new AbortController();
        const e = s;
        clearTimeout(c), a.value = null, f.value = !1, n.value = !1, i.value++, z();
        try {
          const r = yield fetch("/cgi-bin/luci/admin/services/fastnet/embed?format=json&theme=" + t.context.theme.effective + (t.view === "history" ? "&view=history" : ""), { credentials: "same-origin", cache: "no-store", redirect: "error", signal: e.signal });
          if (!r.ok) throw Error("launch_unavailable");
          const l = R((yield r.json()).url);
          if (k || e.signal.aborted) return;
          a.value = l, l.mixedContent && clearTimeout(c);
        } catch (r) {
          !k && !e.signal.aborted && (clearTimeout(c), n.value = !0);
        }
      });
    }
    function q() {
      var e, r;
      a.value && ((r = (e = u.value) == null ? void 0 : e.contentWindow) == null || r.postMessage({ type: "quickstart:theme", theme: t.context.theme.effective }, a.value.origin));
    }
    function C(e) {
      var r, l, h, N, F, E;
      if (!(!a.value || e.origin !== a.value.origin || e.source !== ((r = u.value) == null ? void 0 : r.contentWindow))) {
        if (((l = e.data) == null ? void 0 : l.type) === "fastnet:ready")
          clearTimeout(c), f.value = !0, n.value = !1, q();
        else if (((h = e.data) == null ? void 0 : h.type) === "fastnet:close") _("close");
        else if (((N = e.data) == null ? void 0 : N.type) === "fastnet:focus") {
          const m = (F = u.value) == null ? void 0 : F.closest("section.network-dialog");
          (E = (m == null ? void 0 : m.querySelector(e.data.backward ? "[data-network-dialog-close]" : "[data-network-dialog-open]")) || (m == null ? void 0 : m.querySelector("[data-network-dialog-close]"))) == null || E.focus();
        }
      }
    }
    return H(() => t.context.theme.effective, q), L(() => {
      window.addEventListener("message", C), T();
    }), O(() => {
      k = !0, s == null || s.abort(), clearTimeout(c), window.removeEventListener("message", C);
    }), (e, r) => {
      var l, h;
      return w(), g("div", U, [
        x("div", W, [
          a.value && !n.value && !a.value.mixedContent ? (w(), g("iframe", {
            key: i.value,
            ref_key: "frame",
            ref: u,
            src: a.value.url,
            title: o("FastNet 完整测速界面", "FastNet speed test interface"),
            referrerpolicy: "origin"
          }, null, 8, A)) : y("", !0),
          f.value ? y("", !0) : (w(), g("div", {
            key: 1,
            class: "fn-web-loading",
            role: n.value ? "alert" : "status"
          }, [
            x("strong", null, b((l = a.value) != null && l.mixedContent ? o("在新窗口中直接测速", "Test directly in a new window") : n.value ? o("FastNet 页面暂时无法加载", "FastNet could not be loaded") : o("正在打开 FastNet…", "Opening FastNet…")), 1),
            x("p", null, b((h = a.value) != null && h.mixedContent ? o("当前 HTTPS 页面无法嵌入 HTTP 测速服务，请在新窗口打开 FastNet。", "This HTTPS page cannot embed the HTTP service. Open FastNet in a new window.") : n.value ? o("可以重试，或在新窗口中打开。请确认插件服务已启用。", "Retry or open in a new window. Check that the plugin service is enabled.") : o("打开页面不会自动测速；请在子窗口中点击开始。", "Opening the page does not start a test. Select Start inside the window.")), 1),
            a.value && (n.value || a.value.mixedContent) ? (w(), g("a", {
              key: 0,
              href: P.value,
              target: "_blank",
              rel: "noopener noreferrer"
            }, b(o("打开 FastNet ↗", "Open FastNet ↗")), 9, M)) : y("", !0),
            n.value ? (w(), g("button", {
              key: 1,
              onClick: T
            }, b(o("重新加载", "Reload")), 1)) : y("", !0)
          ], 8, D))
        ]),
        x("p", V, b(o("核心已接受的测速继续运行；关闭窗口将中断浏览器测量，已保存结果保留。", "Accepted core tests continue. Browser tests stop when closed; saved results remain.")), 1)
      ]);
    };
  }
};
export {
  J as default
};
