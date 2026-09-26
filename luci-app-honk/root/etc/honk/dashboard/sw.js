const PREFIX = `doona-shell:${self.registration.scope}:`;
const CACHE = PREFIX + '15385fcb432aeda2';
const PRECACHE = ["assets/ActionGroup-DWWqC_OI.js","assets/AreaChart-CAPxMEa9.js","assets/AreaCurve-BriPYJva.js","assets/Arrange-Cw20-mxp.js","assets/Arrange-Dd3j3leY.css","assets/Beeswarm-CYZQhE1e.js","assets/Config-BjVKr6L0.js","assets/Connections-Vst-xGKI.js","assets/DaeCode-B4MDdwFy.js","assets/Dns-BYRR7SFp.js","assets/Donut-Dbc8V763.js","assets/Events-CK56KfTp.js","assets/FactStrip-DprrkMgd.js","assets/ListLayout-Ds3Jwlym.js","assets/Login-CXR8p5CT.js","assets/Logs-DtacRIH0.js","assets/NodeSearch-CLstg8iZ.js","assets/Nodes-C3pX9Hmx.js","assets/Overview-DnVHLcP-.js","assets/Policies-BXp5Ca_-.js","assets/PolicyPicker-BJqX15d9.js","assets/Rules-ChjJ9T_U.js","assets/Rules-l5FnUA9B.css","assets/SearchDialog-C61SjJ-0.js","assets/Settings-BkR1ZBJ0.js","assets/Sparkline-D4rCjH0l.js","assets/Table-Dst2TDcq.js","assets/TimeCell-C2PwaBzl.js","assets/Virtualizer-BHxBcQwi.js","assets/array-C0P64tl-.js","assets/auth-D6BDJ9Af.js","assets/dns-CTi3CJrE.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/flows-Cv2TAHF4.js","assets/geodata-DprMPspn.js","assets/index-BCoOz7L7.js","assets/index-CsgqKws4.css","assets/interaction-TDRcRWKx.js","assets/layout-BhWAF08Z.js","assets/link-CKEORRHc.js","assets/logo-obi05X1B.svg","assets/logs-B37eFsWX.js","assets/nav-BGA9RGl_.js","assets/nav-BIpfWn6-.js","assets/nav-BeFLfZq8.js","assets/nav-DXBqqPsp.js","assets/outbounds-CCN0VOgj.js","assets/policyText-yVvReZXI.js","assets/probe-B0HzTCKk.js","assets/setup-ChbuRuEl.js","assets/tip-D0lkGLXB.js","assets/useFilter-Sr23AqnI.js","assets/useGridSelectionCheckbox-BLDkC2B7.js","assets/vendor-editor-BYSNX95r.js","assets/vendor-react-Bf71BWbF.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses.
const LANGUAGES = {"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-BsiDYEvS.js"],"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-BMVYxwjY.js"],"en":["assets/locale-en-B1RFud87.js"]};
// The mock backend's chunk, cached only for a page that runs on it.
const MOCK = ["assets/index-CV9QD4qT.js"];
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
