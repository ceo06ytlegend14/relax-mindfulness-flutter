'use strict';

// A small, scope-local worker for installation and a truthful offline fallback.
// The app bundle, personal data, API responses, and audio are NOT precached.
// Change this version when offline.html changes; old versions are removed only
// within this worker's own scope. Never clear another application's caches.
const CACHE_PREFIX = `sanctuary-install:${self.registration.scope}:`;
const CACHE_NAME = `${CACHE_PREFIX}v1`;
const OFFLINE_URL = new URL('offline.html', self.registration.scope).href;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      cache.add(new Request(OFFLINE_URL, { cache: 'reload' })),
    ),
  );
  // Do not force activation/reload over an existing, possibly playing app.
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  // Leave audio (including Range requests), Flutter files, and APIs untouched.
  if (event.request.method !== 'GET' || event.request.mode !== 'navigate') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin || !url.href.startsWith(self.registration.scope)) return;

  event.respondWith((async () => {
    try {
      return await fetch(event.request);
    } catch (_) {
      return (await caches.match(OFFLINE_URL, { cacheName: CACHE_NAME })) ||
        new Response('Reconnect to open Sanctuary.', {
          status: 503,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
    }
  })());
});
