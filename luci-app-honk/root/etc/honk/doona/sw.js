const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = 'd197b714ef5b1d14';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-Bsrf2UoO.js","assets/AppearanceControls-CRuy5orf.js","assets/AreaChart-Cr3bgyVc.js","assets/AreaCurve-DQSHOSpG.js","assets/Checkbox-DiXDVgGl.js","assets/CodeEditor-bkEq3lkg.js","assets/ConditionRow-EvG4rKpT.js","assets/Config-Bt4CbrM4.js","assets/Connections-DGa-2OdM.js","assets/Copy-BqPmUS7m.js","assets/Coverage-BvvFzjoN.js","assets/DaeCode-DEjXqvav.js","assets/Delete-Kzat-N3j.js","assets/Dns-4R7nsCX0.js","assets/Donut-Wa5QWvM-.js","assets/Editors-9WzBYpJ9.js","assets/Editors-rPgk_VZK.css","assets/Events-j3kIhFYp.js","assets/FlagPicker-D2kKSyH6.js","assets/Flows-B78_vhjx.css","assets/Flows-CL9Xh__A.js","assets/GridList-CYOcEmX9.js","assets/ItemText-CnmwoDur.js","assets/LinkOut-Ff0bS5Fx.js","assets/Login-DgbRG-H2.js","assets/Logs-DRG0t3ZH.js","assets/Nodes-DyFFhzXj.js","assets/NumberField-Cd9mdKJI.js","assets/OutboundTag-yFgWAs1b.js","assets/Overview-CF2yJv8R.js","assets/Policies-CVSnSSix.js","assets/ProbeOptionsDialog-bv58UQw7.js","assets/Rules-Bsj3Y9L1.js","assets/SearchDialog-0G_oHUD5.js","assets/SearchList-B2h2qAe4.js","assets/SearchSelect-ZK-gprFX.js","assets/Select-B67-iUq2.js","assets/Settings-BVpmQMTB.css","assets/Settings-CKdUz8fA.js","assets/Sparkline-hC597b6M.js","assets/Table-DDHjB8la.js","assets/Tabs-DVxF89X7.js","assets/Tag-Bizvcn28.js","assets/TimeCell-B2wYTQbc.js","assets/Toolbar-Yd2KR-zd.js","assets/Trace-L5yFUuZV.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-DBBzjqSD.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-BQ91A1_2.js","assets/activity-Db7VRWAG.css","assets/array-C0VuvQyb.js","assets/auth-BW588zN2.js","assets/auth-CGURHhWN.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-Bm5f0qGx.js","assets/fonts-C5_wsAqZ.css","assets/geodata-X0pHz03D.js","assets/geodataUpdate-b_z-ddHs.js","assets/glass-B8ENqf-S.css","assets/glass-DWGGOADV.js","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/impact-B8feJDtJ.css","assets/index-BClYdby3.css","assets/index-C-WQXF8v.js","assets/index-DUM-iwa2.js","assets/labels-D8xxfRTQ.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/lens-CgVfVtKQ.js","assets/logo-obi05X1B.svg","assets/logs-B-rowQjz.js","assets/match.worker-B2aIccpg.js","assets/nav-BNyZNOjO.js","assets/nav-BO8viH9G.js","assets/nav-C9NL8eDT.js","assets/nav-DN3M4Ewk.js","assets/nav-DORsPGf3.js","assets/nav-DPUoWWE6.js","assets/nav-DrKp2w73.js","assets/nodes-D39HfuKn.js","assets/outbounds-CStRcMI8.js","assets/probe-BRKajYpx.js","assets/recorder-BHyqDNp5.js","assets/rule-C502aJft.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useQuickRule-Dg2XjZII.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","assets/wallpaper-CEC7gitM.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-DccCjlwo.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-Dxfxpqs6.js"],"en":["assets/locale-en-GHtAsGdG.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-BpLc3-JM.js"];
const ROOT = new URL(self.registration.scope);

// A new build takes over on the next online load, including open dashboard tabs.
// Each build records when it was installed, so activation can tell the build it replaces from older ones.
const STAMP = new URL('__installed__', ROOT);
// index.html keeps its name across builds, so it is fetched past the HTTP cache: a caching proxy cannot hand the new
// build an old shell. A file under assets/ is named after its content hash, so the copy the page already loaded through
// the HTTP cache is the same file and is not downloaded again.
const precacheRequest = url => (url.startsWith('assets/') ? url : new Request(url, {cache: 'reload'}));
self.addEventListener('install', event => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then(cache => Promise.all([cache.addAll(PRECACHE.map(precacheRequest)), cache.put(STAMP, new Response(String(Date.now())))]))
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
      // A host may answer a missing file with the page; caching that would keep the file missing once it is installed.
      if (fresh.ok && fresh.type === 'basic' && !fresh.redirected && !fresh.headers.get('content-type')?.includes('html'))
        await cache.put(request, fresh.clone());
      return fresh;
    })()
  );
});
