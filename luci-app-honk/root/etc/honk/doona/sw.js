const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '51003e38d54f0173';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-DcHltO1v.js","assets/AppearanceControls-BD1aEDs9.js","assets/AreaChart-Y60Tk7EY.js","assets/AreaCurve-DQSHOSpG.js","assets/Checkbox-BKj4Db2Z.js","assets/CodeEditor-ZqXnueJH.js","assets/ConditionRow-Bg6LNTMF.js","assets/Config-BwU4-77g.js","assets/Connections-C-zyuxCZ.js","assets/Copy-DHPoevAT.js","assets/Coverage-BJvTedGL.js","assets/DaeCode-DEjXqvav.js","assets/Delete-CgOxVZmw.js","assets/Dns-C35liudY.js","assets/Donut-ChW4T7Ls.js","assets/Editors-BMVESW5J.js","assets/Editors-rPgk_VZK.css","assets/Events-Y7Eh_yO9.js","assets/FlagPicker-B_BuIbZ7.js","assets/Flows-B78_vhjx.css","assets/Flows-Id9Tv8zW.js","assets/GridList-jozAdMNn.js","assets/ItemText-Dgdpwlya.js","assets/LinkOut-DQlNJltN.js","assets/Login-DDSFVPAj.js","assets/Logs-B2asluLb.js","assets/Nodes-B195WUBw.js","assets/NumberField-exuGk_4K.js","assets/OutboundTag-DpL0gM64.js","assets/Overview-CFXYzabj.js","assets/Policies-DHbYI2TJ.js","assets/ProbeOptionsDialog-DXNaD9Eq.js","assets/Rules-iifuvJFD.js","assets/SearchDialog-BWi5KAyC.js","assets/SearchList-B6lRzyrx.js","assets/SearchSelect-D4K5x3Dr.js","assets/Select-DWbhcwJn.js","assets/Settings-BDveNjbx.js","assets/Settings-BVpmQMTB.css","assets/Sparkline-Cw_TSVYz.js","assets/Table-F4IqiSpF.js","assets/Tabs-B4sGtt9H.js","assets/Tag-vHzdKKtd.js","assets/TimeCell-9GclRD1_.js","assets/Toolbar-CjvMWlYW.js","assets/Trace-Ch8hdxbk.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-BvEOIH-1.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-Db7VRWAG.css","assets/activity-DculzrMC.js","assets/array-C0VuvQyb.js","assets/auth-BoGeFHxR.js","assets/auth-jZpqFYEv.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-CRseZIch.js","assets/fonts-C5_wsAqZ.css","assets/geodata-X0pHz03D.js","assets/geodataUpdate-bQ8_tj1F.js","assets/glass-C5izaGYk.js","assets/glass-Dp_Mnqov.css","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/impact-B8feJDtJ.css","assets/index-DUM-iwa2.js","assets/index-h01My1hi.js","assets/index-o3F3WGy0.css","assets/labels-D8xxfRTQ.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/lens-CgVfVtKQ.js","assets/logo-obi05X1B.svg","assets/logs-B4ll2i37.js","assets/match.worker-B2aIccpg.js","assets/nav-05lCG3do.js","assets/nav-BO8viH9G.js","assets/nav-DewbE61H.js","assets/nav-Duf_Hx_S.js","assets/nav-UNLkiPHs.js","assets/nav-VClRNgZl.js","assets/nav-fqIhwTDn.js","assets/nodes-DWy8SDzN.js","assets/outbounds-BEDDa3ac.js","assets/probe-BNlw1o3h.js","assets/recorder-BHyqDNp5.js","assets/rule-CMfsBXoY.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useQuickRule-Ddub5u-I.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","assets/wallpaper-CEC7gitM.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-DccCjlwo.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-Dxfxpqs6.js"],"en":["assets/locale-en-GHtAsGdG.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-N1ndy6Ft.js"];
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
