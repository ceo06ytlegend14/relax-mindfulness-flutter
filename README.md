# Sanctuary — Relax & Mindfulness

A Flutter app for ambient sound mixing, timed calming sessions, breathing and sleep routines. Home, Sounds, Meditate and Sleep share playback state while keeping distinct screens.

**Status: pre-release.** The visual redesign and independent browser preview are implemented, but the app is not yet cleared for a paid acquisition launch. See the [prioritized release plan](docs/LAUNCH_READINESS.md), especially billing, credential handling, real-device audio and content rights.

## Sound library update

All **75 sound cards have local cover art**, including Rain on Leaves and Urban Rain. Use **a card’s ⋯ → Replace sound → Preview → Use sound** to swap only that layer from six existing bundled clips. Opening the chooser never autoplays; other layers and the current level are preserved, paused selections stay paused, and saved mixes remember the real chosen name. Packs, personal imports and new same-sound recording variants are deferred—not invented from duplicate audio.

The source audit found **35 cards with configured audio and 40 without**. Unconfigured cards remain visible but are labeled; they no longer silently play generic rain. Existing media rights and device playback still need review. See the [sound-library inventory and scope](docs/SOUND_LIBRARY.md). Local browser checks for this update are **116/116**, including playback of all six bundled clips; the exact hosted verification below also covers this sound-library update.

## Run the Flutter app

- Minimum **Flutter 3.32 / Dart 3.8**, matching `pubspec.lock`.
- Use the quality automation pin **Flutter 3.38.10** to reproduce web/Android/iOS results, with **Android API 36 / minimum API 24** and **Xcode 26.3**. All four hosted jobs pass at verified code revision **`d6447f6`**, including lock/tests and unsigned Android/iOS release compilation. Signed-device/store validation is still required; see the [native release runbook](docs/NATIVE_RELEASE.md).

```sh
flutter pub get --enforce-lockfile
flutter run
```

No private API key is required for core screens and bundled audio. Reflection studio is an explicitly **local writing template**, not an AI/music-generation service. Current source no longer uses a provider key; the owner still needs to revoke/rotate a historically exposed credential.

**New subscription purchases are disabled by default.** Access/restore use SDK entitlements, never a local premium/trial flag. The paywall uses real localized store offerings; see [billing configuration and sandbox gates](docs/BILLING.md). `.env.example` is guidance only—Flutter does not automatically load it. The owner must supply approved platform-specific **public SDK keys**, legal URLs and explicit opt-in before new sales. Never compile a secret REST key, signing password or AI provider credential via Dart defines; client values are recoverable. No live billing configuration or payment was made.

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

Verification on 2026-11-19: [**all four hosted jobs passed** at `d6447f6`](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44483121445), including **260/260 Flutter tests**, analysis/scoped formatting/web compilation, clean dependency locks, Android debug/unsigned release, iOS unsigned release and built-Android safety checks. Android artifact inspection verifies the unchanged identity, API 36, Billing Library 8, 16 KB native-library/APK alignment and unsigned release output; a real negative signing test verifies the fail-closed guard. Local reproduction also passes **116/116 browser/PWA/source-configuration checks** and **15/15 Python diagnostic/verifier fixtures**. No tests were skipped. These are engineering gates, **not signed installation or store approval**. Flutter/Dart SDKs are unavailable in the local sandbox; hosted CI is the real Flutter compilation/test gate.

For checks without a browser download: `npm run test:pwa` and `npm run test:platform`. `PLAYWRIGHT_MODULE` and `CHROMIUM_PATH` can point to existing tools; see [PWA checks](docs/PWA.md#checks).

`.github/workflows/quality.yml` defines read-only, SHA-pinned browser, Flutter, Android debug/unsigned release and unsigned iOS device jobs on pushes/PRs. Dependency drift, Flutter errors/warnings and failed tests/builds fail the job; stylistic analyzer infos remain advisory. No workflow deploys the app, uploads an app binary, accesses production signing/billing secrets or launches ads. Android production release signing now requires explicit owner-controlled credentials; debug signing is never a release fallback.

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
