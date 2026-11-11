import { openBlock as d, createElementBlock as i, createElementVNode as l, toDisplayString as s, Fragment as N, renderList as g, createTextVNode as h, unref as y, createCommentVNode as P } from "/luci-static/quickstart/card-runtime-v1.js";
const k = { class: "qs-card-details" }, D = { key: 0 }, T = {
  href: "/cgi-bin/luci/admin/services/fastnet/open",
  target: "_blank",
  rel: "noopener"
}, x = {
  __name: "Details",
  props: ["state", "locale", "stamp", "mbps"],
  setup(c) {
    const o = c, b = o.stamp, w = o.mbps, _ = ["download", "upload", "nat", "ipv6", "lanPing", "lanDownload", "lanUpload"], e = (a, t) => o.locale === "en" ? t : a, f = { download: e("下载", "Download"), upload: e("上传", "Upload"), nat: "NAT", ipv6: "IPv6", lanPing: e("内网延迟", "LAN latency"), lanDownload: e("内网下载", "LAN download"), lanUpload: e("内网上传", "LAN upload") };
    function p(a) {
      var t, n, r, u;
      return ((n = (t = o.state.summary) == null ? void 0 : t.latestResults) == null ? void 0 : n[a]) || ((u = (r = o.state.summary) == null ? void 0 : r.latest) == null ? void 0 : u[a]);
    }
    function A(a) {
      const t = p(a);
      return !t || t.status === "not_tested" ? e("未检测", "Not tested") : t.status === "error" ? e("检测失败", "Probe failed") : t.status === "unavailable" ? e("不可用", "Unavailable") : a === "lanPing" ? t.value.toFixed(1) + " ms" : /download|upload/i.test(a) ? w(t.value) + " Mbps" : t.value;
    }
    return (a, t) => (d(), i("div", k, [
      l("p", null, s(e("默认外网出口 · 路由器 → 互联网", "Default WAN route · Router → Internet")), 1),
      l("dl", null, [
        (d(), i(N, null, g(_, (n) => {
          var r, u, m, v;
          return d(), i(N, { key: n }, [
            l("dt", null, s(f[n]), 1),
            l("dd", null, [
              h(s(A(n)), 1),
              l("small", null, s(y(b)((r = p(n)) == null ? void 0 : r.measuredAt, c.locale)), 1),
              (v = (m = (u = c.state.summary) == null ? void 0 : u.lastTask) == null ? void 0 : m.issues) != null && v[n] ? (d(), i("span", D, s(e("本次探测失败，保留上次有效结果", "Latest probe failed; previous valid result retained")), 1)) : P("", !0)
            ])
          ], 64);
        }), 64))
      ]),
      l("p", null, s(e("测速会使用外网上传和下载带宽。NAT 与 IPv6 分别反映各自检测时间的结果。", "Testing uses WAN upload and download bandwidth. NAT and IPv6 describe their own detection times.")), 1),
      l("a", T, s(e("打开完整 FastNet", "Open full FastNet")), 1)
    ]));
  }
};
export {
  x as default
};
