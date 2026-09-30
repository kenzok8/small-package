const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '280ebfa593df4ed0';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/ActionGroup-BU73NzbX.js","assets/AddCircle-0OKZjQ6F.js","assets/AreaChart-CsrRISMa.js","assets/AreaCurve-BriPYJva.js","assets/Arrange-Bbxnsdc8.js","assets/Arrange-Dd3j3leY.css","assets/Config-DTOoA8Ct.js","assets/Connections-ZaWxL_iR.js","assets/Coverage-BJmgp_Br.js","assets/DaeCode-B8yPDjSE.js","assets/Dns-CTaKf4B9.js","assets/Donut-Bal7IeCD.js","assets/Events-Cryh0oVV.js","assets/FactStrip-CPXeRki4.js","assets/Flows-C6wPx8Fw.js","assets/Flows-l5FnUA9B.css","assets/ListLayout-CkBMjK9o.js","assets/Login-CfAnL01j.js","assets/LoginShowcase-B9vkePHH.js","assets/Logs-D9CEYzzB.js","assets/NodeSearch-BR3IX28j.js","assets/Nodes-DZ5wlafB.js","assets/Overview-DmsPNbOk.js","assets/Policies-DZOKUNEx.js","assets/Rules-DutfCjRn.js","assets/SearchDialog-CuE64a4y.js","assets/Settings-hUYEzPZ9.js","assets/Sparkline-4ZFN_DWA.js","assets/Table-BkehX7fw.js","assets/TimeCell-COfj2dEh.js","assets/Virtualizer-BIsXGNLZ.js","assets/array-C0P64tl-.js","assets/auth-DKKBdTVr.js","assets/auth-DTgOavf4.js","assets/dns-BY6DX1P3.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/flows-BW6GjUpE.js","assets/geodata-De9_qBkH.js","assets/index-BOpK0UVB.js","assets/index-tAbIWhIz.css","assets/labels-Bgu_ZhL8.js","assets/layout-Bzzn7HLw.js","assets/logo-obi05X1B.svg","assets/nav-B9ea5ZPQ.js","assets/nav-BASDWt23.js","assets/nav-BFiTWnsa.js","assets/nav-BFm4Dw7L.js","assets/nav-BiwTft4m.js","assets/nav-D5WY5Qjf.js","assets/nav-DEBjyEJ7.js","assets/nav-Wiib71Wo.js","assets/openGroup-B1VdMhOs.js","assets/outbounds-BVwoUbXQ.js","assets/policyText-y7dbn7hu.js","assets/probe-BHjulBb8.js","assets/qiangguo-gorges-dark-FlgXSNn1.webp","assets/qiangguo-gorges-light-DCWkLX37.webp","assets/qiangguo-lake-dark-B_VaUlAe.webp","assets/qiangguo-lake-light-oWll36-V.webp","assets/qiangguo-square-dark-CG0rwsS1.webp","assets/qiangguo-square-light-OU6dsCf9.webp","assets/qiangguo-taishan-dark-BI3cd4fj.webp","assets/qiangguo-taishan-light-Dip0HmJZ.webp","assets/qiangguo-wall-dark-DCO0xUUO.webp","assets/qiangguo-wall-light-BYfte2Bi.webp","assets/ranked-DDCHUGeL.js","assets/recorder-DlDpPhd4.js","assets/setup-V0SWKTBk.js","assets/useFilter-6_o4NyOf.js","assets/useGridSelectionCheckbox-C4VxQajJ.js","assets/useQuickRule-qFvcUoSC.js","assets/useRefreshAll-CFXNBP5e.js","assets/vendor-editor-2EGeBPxF.js","assets/vendor-react-Bf71BWbF.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-CjV1NjVp.js"],"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-DF_91JnF.js"],"en":["assets/locale-en-CGmJL3j4.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-SqqyX_jn.js"];
const ROOT = new URL(self.registration.scope);

// A new build takes over on the next online load, including open dashboard tabs.
// Each build records when it was installed, so activation can tell the build it replaces from older ones.
const STAMP = new URL('__installed__', ROOT);
// Fetched past the HTTP cache, so a caching proxy cannot hand the new build an old shell.
self.addEventListener('install', event => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then(cache => Promise.all([cache.addAll(PRECACHE.map(url => new Request(url, {cache: 'reload'}))), cache.put(STAMP, new Response(String(Date.now())))]))
      .then(() => self.skipWaiting())
  );
});
// A page loads its catalogue and backend before this worker controls it, so it reports the language it shows and
// whether it runs on the mock, to have them cached.
self.addEventListener('message', event => {
  if (event.data?.build === true) {
    event.ports[0]?.postMessage(BUILD);
    return;
  }
  const lang = event.data?.language;
  const files = [...(typeof lang === 'string' && Object.hasOwn(LANGUAGES, lang) ? LANGUAGES[lang] : []), ...(event.data?.mock === true ? MOCK : [])];
  if (!files.length) return;
  event.waitUntil(caches.open(CACHE).then(cache => Promise.all(files.map(async url => (await cache.match(url, {ignoreVary: true})) ?? cache.add(url)))));
});
// The build just replaced stays: tabs still showing it load their remaining chunks from it until reloaded.
self.addEventListener('activate', event => {
  event.waitUntil(
    (async () => {
      const older = [];
      for (const key of await caches.keys()) {
        if (!key.startsWith(PREFIX) || key === CACHE) continue;
        const stamp = await (await caches.open(key)).match(STAMP);
        older.push({key, installed: stamp ? Number(await stamp.text()) : 0});
      }
      older.sort((a, b) => b.installed - a.installed);
      await Promise.all(older.slice(1).map(({key}) => caches.delete(key)));
      await self.clients.claim();
    })()
  );
});

function hit(response) {
  if (!response) return Response.error();
  const headers = new Headers(response.headers);
  headers.set('x-doona-sw', 'hit');
  return new Response(response.body, {status: response.status, statusText: response.statusText, headers});
}

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== ROOT.origin || /\/api(?:\/|$)/.test(url.pathname) || !url.pathname.startsWith(ROOT.pathname)) return;
  const navigation = request.mode === 'navigate';
  if (!navigation && !/^(assets|fonts|icons)\//.test(url.pathname.slice(ROOT.pathname.length))) return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      if (navigation) {
        try {
          return await fetch(request);
        } catch {
          return hit(await cache.match(new URL('index.html', ROOT)));
        }
      }
      // A build file is the same for every requester, so a server's Vary: Origin must not turn a cached copy into a miss.
      const response = (await cache.match(request, {ignoreVary: true})) ?? (await caches.match(request, {ignoreVary: true}));
      if (response) return hit(response);
      const fresh = await fetch(request);
      if (fresh.ok && fresh.type === 'basic' && !fresh.redirected) await cache.put(request, fresh.clone());
      return fresh;
    })()
  );
});
