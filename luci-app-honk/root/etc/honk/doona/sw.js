const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '17b6131b258868ec';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-prR7q573.js","assets/AreaChart-8u_BHC3w.js","assets/AreaCurve-DQSHOSpG.js","assets/ConditionRow-CmAHHzfr.js","assets/Config-kDn1yln4.js","assets/Connections-CjRavXMq.js","assets/Coverage-VYQXivNr.js","assets/DaeCode-DEjXqvav.js","assets/Delete-DA-ArqRQ.js","assets/Dns-muAKZqBa.js","assets/Donut-ICRrmfL0.js","assets/Editors-BWyc5snq.css","assets/Editors-CF-H0sca.js","assets/Events-DhkgQmOB.js","assets/FlagPicker-DvzEtm7E.js","assets/Flows-Bc5zvW8x.js","assets/Flows-Bgp2RBuw.css","assets/GridList-BUQihjaB.js","assets/Login-Dmoi1b-S.js","assets/LoginShowcase-B3T5ZpRs.js","assets/Logs-kFCPXU2U.js","assets/Nodes-3yvkRhfS.js","assets/OutboundTag-jvAhyeqj.js","assets/Overview-DwLMYJiG.js","assets/Policies-8HLSs6CT.js","assets/ProbeOptionsDialog-DbXtrnP-.js","assets/Rules-DlWozzHL.js","assets/SearchDialog-lJhZ2e4h.js","assets/SearchList-Bhc2_bS4.js","assets/SearchSelect-CO6FsBaz.js","assets/Select-CkiGmyVC.js","assets/Settings-DVKP5cdM.js","assets/Sparkline-B6w2i-1G.js","assets/Table-Dprh3Btz.js","assets/Tabs-CD2lZase.js","assets/Tag-PTwIjtR6.js","assets/TimeCell-B4WLB8Ou.js","assets/Toolbar-CIBfeuEz.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-CZl-q5wo.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-6eX5ba7W.css","assets/activity-D06xJ7oH.js","assets/array-C0VuvQyb.js","assets/auth-9NIU4RkK.js","assets/auth-B7tMStu6.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-xKlsDqlH.js","assets/format-s2EANuUb.js","assets/geodata-X0pHz03D.js","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/index-BgFj_VXE.js","assets/index-DUM-iwa2.js","assets/index-h-bbwFHc.css","assets/labels-DPpd4zRF.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/logo-obi05X1B.svg","assets/logs-BxISynQ4.js","assets/match.worker-B2aIccpg.js","assets/nav-4gpXURa5.js","assets/nav-BidFSCY-.js","assets/nav-CsTMInze.js","assets/nav-Ct52fcy8.js","assets/nav-D44ro1l_.js","assets/nav-KYKfR_0p.js","assets/nav-Wiib71Wo.js","assets/outbounds-BApwKyMu.js","assets/probe-CvLYPWKB.js","assets/recorder-BHyqDNp5.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useGridSelectionCheckbox-BxnCShqN.js","assets/useQuickRule-fWQicp9K.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-CgyqV-qN.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-DbWVhWuv.js"],"en":["assets/locale-en-Dn2JtjOh.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-D3-KABFr.js"];
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
