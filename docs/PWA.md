# Install Sanctuary as a web app

The Flutter web application has an installable manifest, branded home-screen icons, and a small **Install app** control. Installing keeps the existing Home / Sounds / Meditate / Sleep navigation and opens the site in a standalone app window where the browser supports it.

## For users

Open the **deployed Flutter app over HTTPS**, outside an embedded preview:

- **Chrome / Edge (Android or desktop):** choose **Install app**. When the browser provides a native installation prompt, the button opens it. Otherwise it shows browser-menu instructions.
- **iPhone / iPad:** open the site in Safari, tap **Share → Add to Home Screen**, keep **Open as Web App** enabled if offered, then tap **Add**.
- **Safari on macOS Sonoma or later:** choose **File → Add to Dock**.
- **Embedded Arena preview:** choose **Install app → Open in a new tab**, then install from that browser tab. Browsers generally do not offer app installation inside embedded frames.

Menu names and availability vary by browser/version. The web page cannot force installation or bypass the browser's confirmation. The install control is hidden when running in standalone mode or after an `appinstalled` event.

### What installation does not do

This update is focused on **installation**, not full offline support. The worker caches only a small reconnect page. It does **not** download/cache the Flutter bundle, audio library, API responses, or user records. An internet connection is needed to load the app and stream sounds. Saved settings remain in the current browser's storage unless that data is cleared. Installation is not a backup or cross-device sync feature.

## Build and deploy the Flutter app

With a project-compatible Flutter SDK:

```sh
flutter pub get
# Domain root deployment:
flutter build web --release --base-href /
# Or a project subdirectory (choose this instead of the root build):
flutter build web --release --base-href /allinone/
```

Deploy the **contents of `build/web/`**, not the `web/` source directory, to an HTTPS static host. Keep all generated files together. The manifest, icons, installer, and worker use relative URLs so both root and subdirectory deployments work. Service workers may also run on localhost during development; plain HTTP on another device/IP is not a secure context.

`web/flutter_bootstrap.js` is a Flutter build template. The build replaces its `{{flutter_js}}` and `{{flutter_build_config}}` markers. The custom bootstrap deliberately does not register Flutter's generated caching worker; `pwa-install.js` owns registration of the scope-local `install-worker.js`. Do not add a second worker registration for the same app scope.

No page load unregisters other service workers, clears browser data, or automatically reloads a playing app. An existing installation may need all its windows closed and reopened after a deployment before a waiting worker activates normally.

## Implementation

- `web/manifest.json`: stable existing app ID, relative start/scope URLs, standalone launch, navy theme, real 192/512 icons, separate maskable variants. The old icon-as-screenshot placeholders and shortcuts that did not route correctly have been removed rather than advertised as working.
- `web/icons/`: lotus icons derived from the existing repository artwork, including an opaque 180px Apple touch icon. See the icons README for provenance and safe-area treatment.
- `web/pwa-install.js` / `.css`: accessible install/help UI; single-use `beforeinstallprompt` handling; accepted/dismissed/error behavior; iOS/macOS/unsupported-browser guidance; top-level-tab guidance for frames; standalone detection. The full-screen player temporarily applies `html.sanctuary-player-expanded` to hide the entry so it cannot cover Minimize, without changing installation state. `lib/services/pwa_player_visibility*.dart` isolates that DOM integration from native builds; compiled Flutter verification is still required.
- `web/install-worker.js` / `offline.html`: network-first navigation with a tiny reconnect fallback. Non-navigation requests, including audio Range requests, are not intercepted. Cache cleanup is restricted to this worker's own versioned, application-scope prefix.
- `web/flutter_bootstrap.js`: installs no competing Flutter caching worker.

The former JS integration points are retained: `window.triggerPwaInstall()` opens the prompt or help, and `window.isPwaInstallable` means a **native browser prompt is currently available**, not that iOS/manual installation is impossible. `window.SanctuaryInstall.state` exposes prompt/installed/embedded/secure-context status; changes emit `sanctuary-install-state`.

## Preview versus the real app

The interactive HTML design preview in `design/preview/` shares the actual installer, worker, and icons through repository-relative links. Its own manifest is explicitly named **Sanctuary Design Preview** with a separate app ID. Installing that preview does **not** install or validate the Flutter build; install the deployed Flutter app for the full application.

```sh
node tool/version_preview_assets.mjs
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

Preview CSS/JS URLs are content-versioned, including the Sleep mixer renderer and icon sizing. Re-run the first command after asset edits and reload any already-open page. A returning-browser regression verifies that old cached small buttons are replaced without clearing saved mixes or autoplaying. This is an asset-delivery check, not proof that any user's prior view was cached; the install worker does not cache these assets.

## Checks

Static manifest/icon/bootstrap checks require only Node.js:

```sh
node --test test/web/pwa_manifest_test.mjs
```

The browser suite requires Playwright and Chromium. Install these in a disposable tools directory if you do not already have them:

```sh
npm install --prefix /tmp/sanctuary-browser-tools playwright
/tmp/sanctuary-browser-tools/node_modules/.bin/playwright install chromium
PLAYWRIGHT_MODULE=/tmp/sanctuary-browser-tools/node_modules/playwright/index.mjs \
  node --test test/web/pwa_install_browser_test.mjs
```

`PLAYWRIGHT_MODULE` can name an absolute module path; `CHROMIUM_PATH` can point to an already installed Chromium binary. Browser tests use a local HTTP test server and isolated contexts; they do not install an OS app. Native prompt outcomes are simulated, while manifest parsing, service-worker registration/scope, cache behavior, navigation fallback, and browser UI are exercised in Chromium.

### Earlier PWA verification (2026-11-19)

The counts below record earlier stages, not the current full suite. See the current follow-up results afterward.

- **15 static PWA checks passed** for manifest identity, deployment-relative URLs, icon dimensions/opacity, HTML integration, and bootstrap ownership.
- **20 Chromium integration tests passed.** Chromium reported no manifest or installability errors for the real preview at `/` and the actual web PWA assets served in framework-free fixtures at `/app/` and `/nested/sanctuary/`. These fixtures validate the installer and deployment paths, not a compiled Flutter runtime. Prompt outcomes and Apple-device environments were simulated; no OS application was installed by the tests.
- **52 existing browser-preview regression checks passed again** for Sounds, Meditate, Sleep, navigation, and local audio samples.
- JavaScript syntax checks and `git diff --check` passed.

The subsequent Home/footer correction was also checked: **17 Home/navigation browser tests passed**, including a separate default Home page and footer SVG pixel checks when font requests fail. Home and Sounds now have separate preview routes (`/` / `/#home` versus `/#sounds`); they still share selected mix levels. See [design notes](../design/README.md). The native footer implementation uses local vector painting rather than icon fonts; its Flutter widget/raster tests still need to run with the SDK.

The earlier sunrise-lake player / moonlit-blue Sleep update added **31 passing browser tests** covering actual sample playback, pause/resume/seek, timer expiry/fade, retry/loading cancellation, responsive layouts and font-independent icons. The real install selector is tested at all four widths; the install entry hides while the player is expanded and returns on minimize/completion without resetting installed state. All **83 browser/PWA tests passed together** after this update (31 player/Sleep + 17 Home + the 35 PWA checks above). The subsequent release-safety pass adds 7 platform/configuration guards; all **90 tests in `test/web/*.mjs` passed together** using the new locked `npm run test:web` setup. See [updated previews and verification](../design/README.md).

### Current wellbeing / sound-library follow-up (2026-11-19)

All **180 repository browser/PWA/source-data/configuration tests passed together**, no failures/skips, including wellbeing routes/timer history, the solid-color Meditate cards and playback of all 18 local chooser sources and 23 individually routed ambient session mixes. [Session-audio verification](SESSION_AUDIO.md) is separate from installer/offline validation. Installer fixtures remain independent of Flutter. The DOM install entry hides over expanded players, sound choosers and wellbeing headers without resetting installed/prompt state. Flutter uses independent visibility classes and visible-page owners; native implementations are no-ops. The preview exercises the same CSS contract, not the compiled-web runtime.

**This sandbox has no Flutter/Dart SDK.** A historical Flutter build passed at `d6447f6`, before the latest wellbeing/audio changes. Fresh analysis/tests/web/native builds for these changes, compiled-web browser checks, and actual home-screen installation on iOS/Android/macOS/Windows remain unverified. The PWA is still install-only, not a full offline/audio cache. See [current screenshots and boundaries](../design/README.md).
