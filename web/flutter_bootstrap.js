// Custom Flutter bootstrap.
//
// Deliberately omits `serviceWorkerSettings`: Flutter's generated service
// worker is a self-unregistering stub, and loading it would race with the
// COOP/COEP service worker (coi_service_worker.js). The app's offline and
// header logic is handled there instead.
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load();
