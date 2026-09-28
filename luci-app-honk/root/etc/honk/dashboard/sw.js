const PREFIX = `doona-shell:${self.registration.scope}:`;
const CACHE = PREFIX + '16b7a3b0bc887eec';
const PRECACHE = ["assets/ActionGroup-90AzAQje.js","assets/AddCircle-Db3HxlxQ.js","assets/AreaChart-DtE4xcoZ.js","assets/AreaCurve-BriPYJva.js","assets/Arrange-Aggv2ZKG.js","assets/Arrange-Dd3j3leY.css","assets/Config-BTdL4dU5.js","assets/Connections-L2aJE6s8.js","assets/DaeCode-STEiRZuV.js","assets/Dns-vjK8rYCH.js","assets/Donut-BhofZH9-.js","assets/Events-B-WlUhq0.js","assets/FactStrip-BgQ_tYB6.js","assets/ListLayout-CPapuywx.js","assets/Login-CBpAitxd.js","assets/LoginShowcase-CwRzXrsa.js","assets/Logs-bjF3zhK-.js","assets/NodeSearch-Dmxd0d8_.js","assets/Nodes-CF-Y3hZu.js","assets/Overview-Fg9wiBtP.js","assets/Policies-wpHv6bOW.js","assets/PolicyPicker-DSSmYroN.js","assets/Rules-CSApE4tY.js","assets/Rules-l5FnUA9B.css","assets/SearchDialog-h0qVIWxg.js","assets/Settings-Ajzo2fTI.js","assets/Sparkline-B2EO782x.js","assets/Table-D0NFHHNQ.js","assets/TimeCell-gSIuLEFc.js","assets/Virtualizer--Vfl8O3n.js","assets/array-C0P64tl-.js","assets/auth-BGnwk8Hi.js","assets/auth-DmBaDwOI.js","assets/dns-DQrpG8y_.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/flows-C0byZ3sY.js","assets/geodata-DprMPspn.js","assets/index-BMPxGQXj.css","assets/index-CXHBmSa5.js","assets/layout-BRLew_nj.js","assets/link-D6L0Eg5i.js","assets/logo-obi05X1B.svg","assets/nav-BIpfWn6-.js","assets/nav-BeFLfZq8.js","assets/nav-C2A1sZKm.js","assets/nav-D1cfWFA0.js","assets/outbounds-f8QoVoCV.js","assets/policyText-CAFy3qpo.js","assets/probe-C8ejAKwA.js","assets/ranked-FVqORIQj.js","assets/recorder-DlDpPhd4.js","assets/setup-B5f1cfyO.js","assets/useFilter-DZ8TXqn_.js","assets/useGridSelectionCheckbox-BV96yL-N.js","assets/vendor-editor-CF5uj9id.js","assets/vendor-react-Bf71BWbF.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses.
const LANGUAGES = {"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-DVMwebSP.js"],"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-uoOhY-ul.js"],"en":["assets/locale-en-C8dLKl7q.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-ChxA9-bE.js"];
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
