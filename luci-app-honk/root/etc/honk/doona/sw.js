const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '7f438d4e705c953b';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-CHGG3gmp.js","assets/AppearanceControls-CFYEH-9B.js","assets/AreaChart-BwRLWWA0.js","assets/AreaCurve-DQSHOSpG.js","assets/Checkbox-C2Mg11jF.js","assets/CodeEditor-ChL7r2CH.js","assets/ConditionRow-DniHGfar.js","assets/Config-BFgaFJfJ.js","assets/Connections-CS1wO94h.js","assets/Copy-qIVfhwk3.js","assets/Coverage-B2dxQLlY.js","assets/DaeCode-DEjXqvav.js","assets/Delete-B9WvjapD.js","assets/Dns-4vrjG_3h.js","assets/Dns-CsAXSf3H.css","assets/Donut-BFFWmwxk.js","assets/Editors-Bm6X9s8l.js","assets/Editors-rPgk_VZK.css","assets/Events-DiOJ7EB_.js","assets/FlagPicker-CyOM-9zl.js","assets/Flows-B78_vhjx.css","assets/Flows-Bbt1u0uJ.js","assets/GridList-CVrD-QYL.js","assets/ItemText-CppSqjUt.js","assets/LinkOut-CIdzMzU1.js","assets/Login-DmT59uXL.js","assets/Logs-C969ebJN.js","assets/Nodes-BpvaKDx0.js","assets/NumberField-CzDHtRUv.js","assets/OutboundTag-NqdJKQoF.js","assets/Overview-B4ZUi9A_.js","assets/Policies-CZtQzTZz.js","assets/ProbeOptionsDialog-CEmFylD7.js","assets/Rules-dqPzRSwJ.js","assets/SearchDialog-Dcbbe4Kz.js","assets/SearchList-BHajJOoL.js","assets/SearchSelect-CaPwCsMa.js","assets/Select-ClPUkYAH.js","assets/Settings--s90mEeN.js","assets/Settings-BVpmQMTB.css","assets/Sparkline-0RXxRBe3.js","assets/SubscriptionFields-Dg__CaEa.js","assets/Table-CkhW1eXk.js","assets/Tabs-_MUBwxGf.js","assets/Tag-BseBadyi.js","assets/TimeCell-BmjbFVHU.js","assets/Toolbar-CqHpyiTA.js","assets/Trace-DFiZ_F_8.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-DKq5P7zs.js","assets/WallpaperSettings-BC8TkFcQ.js","assets/XhttpOptions-BnEptJyQ.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-CfH8r6Xl.js","assets/activity-Db7VRWAG.css","assets/array-C0VuvQyb.js","assets/auth-D90lbtgt.js","assets/auth-p39M2UTm.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-Cyy9UQVe.js","assets/fonts-C5_wsAqZ.css","assets/geodata-X0pHz03D.js","assets/geodataUpdate-C_ejlkFh.js","assets/glass-Cqyc7cvc.js","assets/glass-D3s0PXdk.css","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/impact-B8feJDtJ.css","assets/index-Bs-5iCsP.js","assets/index-CcbWXWDN.css","assets/index-DUM-iwa2.js","assets/ipLookup-BYorpVJi.css","assets/ipLookup-l3Vq27Sl.js","assets/labels-D8xxfRTQ.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/lens-BItwTMX6.js","assets/logo-obi05X1B.svg","assets/logs-DVohIf9h.js","assets/match.worker-B2aIccpg.js","assets/nav-B6vzRjBd.js","assets/nav-BO8viH9G.js","assets/nav-BakDou3C.js","assets/nav-CNKHkvR7.js","assets/nav-CXHp7qHo.js","assets/nav-XgANqWQZ.js","assets/nav-p0rSnHU0.js","assets/nodes-G-saHURV.js","assets/outbounds-_QTC1rLV.js","assets/probe-Jtso9rq7.js","assets/recorder-BHyqDNp5.js","assets/rule-ca80gObq.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useQuickRule-CoDwjX9z.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","assets/wallpaper-CEC7gitM.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-DvcJ4kYC.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-D6Q1OjT7.js"],"en":["assets/locale-en-DJB3cTDY.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-C0C4i1if.js"];
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
