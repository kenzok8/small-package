const PREFIX = `doona-shell:${self.registration.scope}:`;
const CACHE = PREFIX + 'e04d983c68066328';
const PRECACHE = ["assets/Arrange-Bj1RDXH-.js","assets/Config-2XR1nv6T.js","assets/Connections-BczQe6wI.js","assets/DaeCode-DiCSVZqN.js","assets/Dns-BK1SUdcJ.js","assets/Events-DVvE1ftR.js","assets/Lifecycle-Bzqu798h.js","assets/Login-Cv7JOH_5.js","assets/Logs-DFawd0eg.js","assets/Nodes-BB5aoEWD.js","assets/Overview-CH_KjwCO.js","assets/Policies-BlTN9WSS.js","assets/PolicyPicker-Co3M7riw.js","assets/Rules-DEItn1oU.js","assets/SearchDialog-DB3YVXVY.js","assets/Settings-DELRoUnj.js","assets/Table-DKSbgKqx.js","assets/TimeCell-B3IzNKis.js","assets/auth-r8fZtcLc.js","assets/dns-HDXAfY6N.js","assets/duck-night-CbKHyiul.webp","assets/files-BxEOxSF8.js","assets/index-BKG-v5Px.js","assets/index-By985uBM.css","assets/index-DcQy51vI.js","assets/layout-D265RSCQ.js","assets/link-DQHXqUks.js","assets/logo-obi05X1B.svg","assets/names-BA_7UeqQ.js","assets/outbounds-CgRnEIFb.js","assets/query-CooI-_z8.js","assets/setup-yfmpo9-_.js","assets/useGridSelectionCheckbox-2weFhIll.js","assets/vendor-charts-BSOgcWus.js","assets/vendor-editor-BYSNX95r.js","assets/vendor-react-Ey0dazfG.js","assets/view-BsLKT3Rt.js","assets/view-C4oO8wTQ.js","assets/view-CXspp4Ub.js","assets/view-CgcDYwFT.js","assets/view-DG3UsfX9.js","assets/vocab-BfgnwTNm.js","index.html"];
// Each language's catalogue and stylesheets in this build, cached only for a language a reader uses.
const LANGUAGES = {"zh-CN":["assets/fonts-sc-DWPGxLPK.css","assets/locale-zh-CN-CfAGUvtt.js"],"zh-TW":["assets/fonts-tc-B6Zt5HQN.css","assets/locale-zh-TW-DoMtzV1B.js"],"en":["assets/locale-en-C6KOt0R-.js"]};
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
// A page loads its catalogue before this worker controls it, so it reports the language it shows to have it cached.
self.addEventListener('message', event => {
  const lang = event.data?.language;
  if (typeof lang !== 'string' || !Object.hasOwn(LANGUAGES, lang)) return;
  event.waitUntil(
    caches.open(CACHE).then(cache => Promise.all(LANGUAGES[lang].map(async url => (await cache.match(url, {ignoreVary: true})) ?? cache.add(url))))
  );
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
