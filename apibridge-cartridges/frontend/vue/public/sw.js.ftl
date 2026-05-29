<#if enableOfflineSupport>
const CACHE_NAME = '${id}-shell-v1';
const API_CACHE = '${id}-api-v1';

const APP_SHELL_PATTERNS = [
  /\/index\.html$/,
  /\.js$/,
  /\.css$/,
  /\.woff2?$/,
  /\.png$/,
  /\.svg$/,
  /\.ico$/,
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(['/index.html']);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME && k !== API_CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  if (event.request.method !== 'GET') {
    event.respondWith(fetch(event.request));
    return;
  }

  const isApi = url.pathname.startsWith('${basePath}') || url.pathname.startsWith('/api/');

  if (isApi) {
    event.respondWith(
      caches.open(API_CACHE).then((cache) =>
        fetch(event.request)
          .then((response) => {
            if (response.ok) {
              const clone = response.clone();
              cache.put(event.request, clone);
            }
            return response;
          })
          .catch(() => cache.match(event.request))
      )
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (response.ok && APP_SHELL_PATTERNS.some((p) => p.test(url.pathname))) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      });
    })
  );
});
</#if>