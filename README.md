# Sanctuary — Relax & Mindfulness

A Flutter app for ambient sound mixing, timed calming sessions, breathing and sleep routines. Home, Sounds, Meditate and Sleep share playback state while keeping distinct screens.

**Status: pre-release.** The visual redesign and independent browser preview are implemented, but the app is not yet cleared for a paid acquisition launch. See the [prioritized release plan](docs/LAUNCH_READINESS.md), especially billing, credential handling, real-device audio and content rights.

## Run the Flutter app

- Minimum **Flutter 3.32 / Dart 3.8**, matching `pubspec.lock`.
- Quality automation is pinned to **Flutter 3.32.8** as a reproducible starting point, not a claim that native builds are already passing.

```sh
flutter pub get --enforce-lockfile
flutter run
```

No private API key is required for the core screens and bundled audio. `.env.example` is guidance only: Flutter does not automatically load it. Do not compile private service credentials into a client via `--dart-define`; those values are recoverable from the application. A RevenueCat integration must use its **public platform SDK key**, never a secret REST key. AI service credentials need a server-side boundary before production use.

## Quality checks

With Flutter installed:

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build web --release
# Android development smoke build, not a store release:
flutter build apk --debug
```

Development-only browser/PWA/configuration tests require Node.js 22+:

```sh
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm run test:web
```

Local verification on 2026-11-19: **90 browser/PWA/configuration checks passed**. Flutter/Dart SDKs are unavailable in this workspace; the new native backup tests and compiled builds remain unverified.

For checks without a browser download: `npm run test:pwa` and `npm run test:platform`. `PLAYWRIGHT_MODULE` and `CHROMIUM_PATH` can point to existing tools; see [PWA checks](docs/PWA.md#checks).

`.github/workflows/quality.yml` defines read-only, SHA-pinned browser and Flutter jobs on pushes/PRs. Flutter errors/warnings and failed tests/builds fail the job; stylistic analyzer infos remain advisory. A manual Android debug job is also defined. No workflow deploys the app, publishes a store binary, accesses billing secrets or launches ads. The workflow itself has not yet run for this local improvement pass; a green preview suite is not a substitute for it.

## Preview the design

```sh
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

[Player, Sleep, Home and other screenshots](design/README.md) come from an **independent HTML design preview**, not a compiled Flutter/device capture. The preview plays bundled samples and has its own PWA identity. It is not the deployed Flutter app.

## Backup and privacy

From **Home → Wellbeing → backup icon**, open **Backup & restore**. Copy a private JSON backup, review an import and explicitly confirm replacement. Malformed input is fully validated before changing profile fields. Purchases, API keys and notification permissions do not transfer. Backups and local preferences are not an encrypted vault or automatic cloud sync; see [backup guarantees and limits](docs/BACKUPS.md).

There is no verified feedback delivery endpoint. The former button that falsely reported a message as received has been removed rather than pretending submissions are delivered.

## Installable web app

Sanctuary includes home-screen icons, standalone launch and an **Install app** control with browser-specific guidance. Serve a **built Flutter web app over HTTPS**. Installation does not download the full app or audio library for offline use.

See [PWA installation/deployment](docs/PWA.md) and the [release checklist](docs/LAUNCH_READINESS.md).
