// Service worker that makes the app cross-origin isolated on static hosts
// (e.g. GitHub Pages) where HTTP response headers cannot be configured.
//
// It intercepts every response and adds the two headers that unlock OPFS for
// SQLite WASM:
//   Cross-Origin-Opener-Policy: same-origin
//   Cross-Origin-Embedder-Policy: require-corp
//
// Same-origin resources are unaffected. Cross-origin resources must opt in to
// being loaded (CORS or CORP), which is satisfied by the app's own assets.
// See https://web.dev/articles/coop-coep and https://github.com/gzuidhof/coi-serviceworker
'use strict';

self.addEventListener('install', () => {
  // Activate immediately instead of waiting for the previous worker to die.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // `only-if-cached` is only valid for same-origin requests; skip the
  // interception so the browser handles it normally.
  if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') {
    return;
  }

  event.respondWith(
    fetch(request).then(
      (response) => {
        if (response.status === 0) {
          // Opaque (no-cors) response — cannot be modified. Return as-is.
          return response;
        }

        const headers = new Headers(response.headers);
        headers.set('Cross-Origin-Opener-Policy', 'same-origin');
        headers.set('Cross-Origin-Embedder-Policy', 'require-corp');

        return new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers,
        });
      },
      (error) => {
        console.error('COOP/COEP service worker fetch failed:', error);
        throw error;
      },
    ),
  );
});
