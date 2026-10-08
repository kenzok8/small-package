const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '774cbb946d6e4b33';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-7x8u9Pw1.js","assets/AppearanceControls-Q-jHRGz9.js","assets/AreaChart-hPc0US1K.js","assets/AreaCurve-DQSHOSpG.js","assets/Checkbox-BewExwKL.js","assets/CodeEditor-B7e2c4Ke.js","assets/ConditionRow-mKWPcuZs.js","assets/Config-D4r3VSJ0.js","assets/Connections-D4_pDN1k.js","assets/Copy-Cix1qeo3.js","assets/Coverage-fmBkVF9H.js","assets/DaeCode-DEjXqvav.js","assets/Delete-BlpuXHjZ.js","assets/Dns-BhjuEpsD.js","assets/Donut-BMxkBF7W.js","assets/Editors-D7Xgy5vR.js","assets/Editors-rPgk_VZK.css","assets/Events-fDbWsOSi.js","assets/FlagPicker-YsJ19Gt1.js","assets/Flows-B78_vhjx.css","assets/Flows-DlYoWpUG.js","assets/GridList-wfRSpULl.js","assets/ItemText-Bvif-kkw.js","assets/LinkOut-BfQApT3z.js","assets/Login-CYtOUqQI.js","assets/Logs-CFjmcBrv.js","assets/Nodes-B55C7kXE.js","assets/NumberField-Bo9iJ94r.js","assets/OutboundTag-B01P-KVW.js","assets/Overview-Drw6LT_U.js","assets/Policies-DaY31pHO.js","assets/ProbeOptionsDialog-fRxfzbxN.js","assets/Rules-gNsJvc3i.js","assets/SearchDialog-mIEPMN0z.js","assets/SearchList-DWooTdFX.js","assets/SearchSelect-BVGce3l_.js","assets/Select-OqnbuzuK.js","assets/Settings-BVpmQMTB.css","assets/Settings-Bf16OoOZ.js","assets/Sparkline-ByQBSxiF.js","assets/Table-DqqJleJD.js","assets/Tabs-BGWzF0yW.js","assets/Tag-BaZZD5o2.js","assets/TimeCell-B6QtVZge.js","assets/Toolbar-CFyWgMbW.js","assets/Trace-Cq_wRvDo.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-FvdVRagH.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-7OeQMmIs.js","assets/activity-Db7VRWAG.css","assets/array-C0VuvQyb.js","assets/auth-5ngSjiJI.js","assets/auth-C2Jiec7E.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-CjEC9Jxw.js","assets/fonts-C5_wsAqZ.css","assets/geodata-X0pHz03D.js","assets/geodataUpdate-Blcy6CRD.js","assets/glass-B8ENqf-S.css","assets/glass-DWGGOADV.js","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/impact-B8feJDtJ.css","assets/index-BClYdby3.css","assets/index-DUM-iwa2.js","assets/index-XeGFdFb3.js","assets/labels-D8xxfRTQ.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/lens-CgVfVtKQ.js","assets/logo-obi05X1B.svg","assets/logs-DNePHVHd.js","assets/match.worker-B2aIccpg.js","assets/nav-4iHQTLCW.js","assets/nav-B6IjqlWU.js","assets/nav-BIicxOIW.js","assets/nav-BO8viH9G.js","assets/nav-BgyFg1Tl.js","assets/nav-DxD_yNm9.js","assets/nav-xz-AMjAg.js","assets/nodes-Bm1vmvln.js","assets/outbounds-UWplA2Qq.js","assets/probe-Bp5QvROd.js","assets/recorder-BHyqDNp5.js","assets/rule-BUktGcKO.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useQuickRule-8yoKk9d5.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","assets/wallpaper-CEC7gitM.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-Bn_bEcMK.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-BVrEb9w1.js"],"en":["assets/locale-en-CiuUUtAQ.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-BF-omOFK.js"];
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
