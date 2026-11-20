// YMAP — يحفظ ما تفتحه من الخريطة لتعمل بدون إنترنت.
// ملفات التطبيق: من الشبكة أولاً (لتصلك التحديثات)، وعند انقطاع النت من الحفظ.
// بلاطات الخريطة والخطوط والأيقونات: من الحفظ أولاً ثم تُحدّث في الخلفية.
const APP = 'ymap-app-v1';
const TILES = 'ymap-tiles-v1';
const MAX_TILES = 4000; // تقريباً 150–250 ميجا كحد أقصى

const TILE_HOSTS = ['tiles.openfreemap.org', 'unpkg.com', 'fonts.gstatic.com'];

self.addEventListener('install', (e) => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

async function trim(cache) {
  const keys = await cache.keys();
  for (let i = 0; i < keys.length - MAX_TILES; i++) await cache.delete(keys[i]);
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (TILE_HOSTS.includes(url.hostname)) {
    event.respondWith((async () => {
      const cache = await caches.open(TILES);
      const hit = await cache.match(req);
      const net = fetch(req).then(async (res) => {
        if (res.ok) {
          await cache.put(req, res.clone());
          if (Math.random() < 0.02) trim(cache);
        }
        return res;
      }).catch(() => hit);
      return hit || net;
    })());
    return;
  }

  if (url.origin === self.location.origin) {
    event.respondWith((async () => {
      const cache = await caches.open(APP);
      try {
        const res = await fetch(req);
        if (res.ok) cache.put(req, res.clone());
        return res;
      } catch (_) {
        return (await cache.match(req)) || (await cache.match('./')) || Response.error();
      }
    })());
  }
  // باقي الطلبات (البحث، المسارات) تمر للشبكة كما هي.
});
