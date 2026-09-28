const PREFIX = `doona-shell:${self.registration.scope}:`;
const CACHE = PREFIX + '7c5ed3d81a85ec8a';
const PRECACHE = ["assets/ActionGroup-BKxDwmnT.js","assets/AddCircle-CIj8X2wL.js","assets/AreaChart-D20yx2yz.js","assets/AreaCurve-BriPYJva.js","assets/Arrange-BvqJLS4m.js","assets/Arrange-Dd3j3leY.css","assets/Config-DgoxfEHn.js","assets/Connections-B3chbGPe.js","assets/DaeCode-B8yPDjSE.js","assets/Dns-CTpwVfIj.js","assets/Donut-C-REp4Mf.js","assets/Events-M5fPrUeR.js","assets/FactStrip-n2q1T87k.js","assets/ListLayout-F74Z1Dpf.js","assets/Login-DgzaXVol.js","assets/LoginShowcase-CyHbTm5w.js","assets/Logs-sKihIR9Z.js","assets/NodeSearch-B91jhtS3.js","assets/Nodes-CnRnSpMd.js","assets/Overview-CuiLM_k-.js","assets/Policies-DiLR7S4N.js","assets/PolicyPicker-BmHzmXzJ.js","assets/Rules-DVu2iSwz.js","assets/Rules-l5FnUA9B.css","assets/SearchDialog-BrTpocW0.js","assets/Settings-DCKpUXHp.js","assets/Sparkline-D9jmRGJ6.js","assets/Table-DyWJelc_.js","assets/TimeCell-DUt0i0gi.js","assets/Virtualizer-DipGMcji.js","assets/array-C0P64tl-.js","assets/auth-TcOYUrrj.js","assets/auth-kokL-_Tb.js","assets/dns-CvJ19DpX.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/flows-CMFlFH_d.js","assets/geodata-DprMPspn.js","assets/index-BNBwb-FJ.js","assets/index-C8vJM6q6.css","assets/labels-Bgu_ZhL8.js","assets/layout-wfdMYi2n.js","assets/link-CIkWI7An.js","assets/logo-obi05X1B.svg","assets/nav-BeFLfZq8.js","assets/nav-D5WY5Qjf.js","assets/nav-DKmRxmdR.js","assets/nav-DuA2h3KP.js","assets/outbounds-DPmb26w8.js","assets/policyText-CmeXgUK2.js","assets/probe-BZEn7bbG.js","assets/qiangguo-gorges-dark-FlgXSNn1.webp","assets/qiangguo-gorges-light-DCWkLX37.webp","assets/qiangguo-lake-dark-B_VaUlAe.webp","assets/qiangguo-lake-light-oWll36-V.webp","assets/qiangguo-square-dark-CG0rwsS1.webp","assets/qiangguo-square-light-OU6dsCf9.webp","assets/qiangguo-taishan-dark-BI3cd4fj.webp","assets/qiangguo-taishan-light-Dip0HmJZ.webp","assets/qiangguo-wall-dark-DCO0xUUO.webp","assets/qiangguo-wall-light-BYfte2Bi.webp","assets/ranked-B09X8uKl.js","assets/recorder-DlDpPhd4.js","assets/setup-d2VGFWY1.js","assets/useFilter-jz02VVEB.js","assets/useGridSelectionCheckbox-CrCOlZv8.js","assets/vendor-editor-CF5uj9id.js","assets/vendor-react-Bf71BWbF.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses. A partial
// language's list holds the reference language's files too, since it loads them.
const LANGUAGES = {"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-BAWlQXtd.js"],"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-i45wENUR.js"],"en":["assets/locale-en-Ds2zf-Id.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-DwWqXSpV.js"];
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
