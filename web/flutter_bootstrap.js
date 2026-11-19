{{flutter_js}}
{{flutter_build_config}}

// Installation is handled by pwa-install.js and install-worker.js. Do not also
// register Flutter's generated caching worker for this same application scope.
// This deliberately does not download/cache the Flutter bundle or audio library.
_flutter.loader.load();
