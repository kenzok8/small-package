const PREFIX = `doona-shell:${self.registration.scope}:`;
const CACHE = PREFIX + 'c7f89ec873064f30';
const PRECACHE = ["assets/ActionGroup-C-LVMOvQ.js","assets/AddCircle-DSsJ-CRu.js","assets/AreaChart-BPSqH5mH.js","assets/AreaCurve-BriPYJva.js","assets/Arrange-C-Cvg5Lz.js","assets/Arrange-Dd3j3leY.css","assets/Config-BVUCd2Cc.js","assets/Connections-DAjj-jeW.js","assets/DaeCode-B4MDdwFy.js","assets/Dns-BCY3zvs7.js","assets/Donut-Dusnd_Se.js","assets/Events-BUl_BoAv.js","assets/FactStrip-vcLr7nBw.js","assets/ListLayout-DU_9AgrU.js","assets/Login-CoF6Tj1K.js","assets/Logs-JK5xuRFC.js","assets/NodeSearch-BdGpTyio.js","assets/Nodes-BPHOu_UD.js","assets/Overview-D7zbQze3.js","assets/Policies-VixfIaVZ.js","assets/PolicyPicker-iyQz7WhP.js","assets/Rules-2i24Jtpl.js","assets/Rules-l5FnUA9B.css","assets/SearchDialog-ByDSjolq.js","assets/Settings-Cznhh7lT.js","assets/Sparkline-C9XwgOxX.js","assets/Table-DLlwyNFJ.js","assets/TimeCell-DxlzlVpw.js","assets/Virtualizer-CTh266-x.js","assets/array-C0P64tl-.js","assets/auth-CPB25VPp.js","assets/dns-BoPCaePc.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/flows-Bv2rvXJX.js","assets/geodata-DprMPspn.js","assets/index-CszNs-yj.css","assets/index-zQjLFfuj.js","assets/layout-B3T-zLsm.js","assets/link-CaqmdEp1.js","assets/logo-obi05X1B.svg","assets/logs-KkruktUh.js","assets/nav--TYgv3Ng.js","assets/nav-BIVfQR1w.js","assets/nav-BIpfWn6-.js","assets/nav-BeFLfZq8.js","assets/outbounds-CM0Hhk3q.js","assets/policyText-IIH31itq.js","assets/probe-CjOLdDVD.js","assets/ranked-C_Wt6A1w.js","assets/setup-BqwQo7FE.js","assets/useFilter-BYneYrGs.js","assets/useGridSelectionCheckbox-BK6qtlfZ.js","assets/vendor-editor-BYSNX95r.js","assets/vendor-react-Bf71BWbF.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses.
const LANGUAGES = {"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-FbJVHSGr.js"],"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-tVBw2Pbf.js"],"en":["assets/locale-en-xL0bZCSM.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-BJD5IosD.js"];
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
