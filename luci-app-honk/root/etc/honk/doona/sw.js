const PREFIX = `doona-shell:${self.registration.scope}:`;
// The page reads the same build from index.html, to tell whether this worker taking it over is a new build.
const BUILD = '04c292a116374877';
const CACHE = PREFIX + BUILD;
const PRECACHE = ["assets/AddCircle-C6Jc7GCc.js","assets/AppearanceControls-sRy1p156.js","assets/AreaChart-CMjcgmpk.js","assets/AreaCurve-DQSHOSpG.js","assets/Checkbox-CJt7u9-e.js","assets/CodeEditor-DdrUcw42.js","assets/ConditionRow-B8Otz3rt.js","assets/Config-C2AJDYeV.js","assets/Connections-DUegD4fy.js","assets/Copy-CGFSe6tr.js","assets/Coverage-8qg_JeNJ.js","assets/DaeCode-DEjXqvav.js","assets/Delete-CR2AtZsd.js","assets/Dns-BTZu7DCC.js","assets/Donut-CLXBHnKk.js","assets/Editors-DQ5Z_NlY.js","assets/Editors-rPgk_VZK.css","assets/Events-ZfmwKzoO.js","assets/FlagPicker-CiyGi8d1.js","assets/Flows-B78_vhjx.css","assets/Flows-C_tb9jRq.js","assets/GridList-D7qdplA5.js","assets/ItemText-DOD_75iR.js","assets/LinkOut-D-cvJjm2.js","assets/Login-BVyvQsKI.js","assets/Logs-B3lfustY.js","assets/Nodes-BV5Yc4KB.js","assets/NumberField-q4-QmTAT.js","assets/OutboundTag-CO8Ndxdr.js","assets/Overview-uWeDda-p.js","assets/Policies-bhHTQ4Ln.js","assets/ProbeOptionsDialog-BynYQcxa.js","assets/Rules-BCWmv1Ss.js","assets/SearchDialog-9DTpWveT.js","assets/SearchList-LjCruZYP.js","assets/SearchSelect-BcScGUbQ.js","assets/Select-D7_6MaHd.js","assets/Settings-BVpmQMTB.css","assets/Settings-DFP_j9Wp.js","assets/Sparkline-rgYPkbE4.js","assets/Table-yWn0d3vL.js","assets/Tabs-DT6MQhIo.js","assets/Tag-SxASl3TF.js","assets/TimeCell-BIqfL3y_.js","assets/Toolbar-BTFtduwD.js","assets/Trace-BZtIse5U.js","assets/TwemojiCountryFlags-Bymva2JV.woff2","assets/Virtualizer-DMIKG2CD.js","assets/_commonjsHelpers-CXUWDbkB.js","assets/activity-Db7VRWAG.css","assets/activity-yZTrGy-J.js","assets/array-C0VuvQyb.js","assets/auth-BHtDKZwR.js","assets/auth-CSMbhh2E.js","assets/daeTokens-BVtuNnWZ.js","assets/duck-night-CbKHyiul.webp","assets/files-Dt8K7QfP.js","assets/flows-dBNkBg79.js","assets/fonts-C5_wsAqZ.css","assets/geodata-X0pHz03D.js","assets/geodataUpdate-D9CXpIul.js","assets/glass-B8ENqf-S.css","assets/glass-DWGGOADV.js","assets/gorges-dark-FlgXSNn1.webp","assets/gorges-light-DCWkLX37.webp","assets/impact-B8feJDtJ.css","assets/index-CcbWXWDN.css","assets/index-DUM-iwa2.js","assets/index-HxEUeoab.js","assets/labels-D8xxfRTQ.js","assets/lake-dark-B_VaUlAe.webp","assets/lake-light-oWll36-V.webp","assets/lens-CgVfVtKQ.js","assets/logo-obi05X1B.svg","assets/logs-C4GIy4tX.js","assets/match.worker-B2aIccpg.js","assets/nav-BMNMQSWb.js","assets/nav-BO8viH9G.js","assets/nav-Bkujhswg.js","assets/nav-CBqYxt5v.js","assets/nav-CKRufMnz.js","assets/nav-D8kaolOs.js","assets/nav-DG4JD5-H.js","assets/nodes-6sIn2I0s.js","assets/outbounds-Bbb6kdae.js","assets/probe-Bj7oT3ox.js","assets/recorder-BHyqDNp5.js","assets/rule-Bl9YOsFn.js","assets/square-dark-CG0rwsS1.webp","assets/square-light-OU6dsCf9.webp","assets/taishan-dark-BI3cd4fj.webp","assets/taishan-light-Dip0HmJZ.webp","assets/useQuickRule-DUEi6geL.js","assets/vendor-editor-BRV-W12m.js","assets/vendor-react-64fcanlc.js","assets/wall-dark-DCO0xUUO.webp","assets/wall-light-BYfte2Bi.webp","assets/wallpaper-CEC7gitM.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-D9rvq3k7.css","assets/locale-zh-TW-0sgfwIDq.js"],"zh-CN":["assets/fonts-sc-Dyn9aW84.css","assets/locale-zh-CN-N8zRZAxn.js"],"en":["assets/locale-en-DY0E5cqv.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-B-vRbGlz.js"];
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
