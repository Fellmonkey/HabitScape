// Registers the COOP/COEP service worker and reloads once so the page loads
// under the worker's control. From then on every navigation is served by the
// worker and the headers are always present.
//
// The reload happens at most once per session (tracked in sessionStorage) and
// only when the page is not yet controlled by the worker.
(function () {
  'use strict';

  if (!('serviceWorker' in navigator)) {
    console.log('Service workers not supported; cross-origin isolation unavailable.');
    return;
  }

  const shouldReload = () => !sessionStorage.getItem('coiReloadedBySelf');

  function reloadOnce() {
    if (shouldReload()) {
      sessionStorage.setItem('coiReloadedBySelf', '1');
      window.location.reload();
    }
  }

  navigator.serviceWorker.register('coi_service_worker.js').then(
    (registration) => {
      // If the worker is already controlling this page, headers are active.
      if (navigator.serviceWorker.controller) {
        return;
      }

      // First visit: the worker registers but does not control the page yet.
      // Reload once so the next load is served by the worker.
      if (registration.active) {
        reloadOnce();
      } else {
        registration.addEventListener('updatefound', () => {
          const worker = registration.installing;
          if (worker) {
            worker.addEventListener('statechange', () => {
              if (worker.state === 'activated') {
                reloadOnce();
              }
            });
          }
        });
      }
    },
    (error) => {
      console.error('COOP/COEP service worker registration failed:', error);
    },
  );
})();
