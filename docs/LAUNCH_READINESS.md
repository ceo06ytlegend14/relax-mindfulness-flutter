# Sanctuary launch readiness

Updated: 2026-11-19. Product ownership, branding, accounts, spending authority and release approval remain with the repository owner. Development assistance does not transfer those responsibilities to an AI or make it a legal business partner.

## Current decision: internal validation, not public launch or paid acquisition

A proposed $100,000 traffic budget is not evidence of readiness or authorization to spend. First prove that people can install, use, return to and—if monetized—safely pay for the real application. No ads, production billing changes, store submission or public release have been made. Existing **Home / Sounds / Meditate / Sleep** navigation and shared playback are retained.

## Engineering gate passed — distribution gates remain open

Verified code revision: **`332a3fdc460ae81d580c7203216a9c78e54dbc29`**. [Run 44476084854](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44476084854) completed **successfully in all four jobs** on 2026-11-19. This is evidence for that exact revision, not automatic approval of future code or a store release.

| Check | Observed result |
| --- | --- |
| Flutter 3.38.10 analysis and scoped formatting | Passed. Legacy analyzer infos remain advisory; analyzer warnings/errors fail. |
| Flutter regressions | **218 passed, 0 failed, 0 skipped.** No test was disabled to obtain a pass. |
| Flutter release web compilation | Passed. This does not validate browser audio or installation on every device. |
| Android debug APK | Compilation passed. |
| Android unsigned, R8-minified release AAB | Compilation passed; the unused Play SplitInstall shrinker failure is fixed. |
| Android compiled-artifact inspection | Passed: application ID unchanged, minimum API 24 / target API 36, Billing Library 8 metadata, **5 APK / 6 AAB 64-bit libraries** with 16 KB ELF alignment, debug APK ZIP alignment and unsigned AAB. |
| Android signing rejection test | Passed: a credential-free release without explicit unsigned opt-in failed at the signing guard. |
| iOS unsigned release device build / Xcode 26.3 | Passed. Not an IPA, signed archive or device installation. |
| Browser/PWA/platform configuration and Python fixtures | Passed. Local reproduction was **96/96 browser/source tests** and **15/15 Python tests**; the browser preview is independent HTML, not native screenshots. |
| Dependency-lock gate | Passed on Flutter, Android and iOS. RevenueCat 10.19.1 and direct url_launcher are reconciled in the committed lockfile. |

The earlier lock drift, regression failures and new artifact parser's legacy-AAPT assumptions are resolved. The parser now supports current AAPT2 output without reducing the required API/Billing levels. CI inspected real generated Android artifacts, separately from the Python verifier fixtures. Static alignment does **not** prove behavior on a 16 KB device or validate Play-generated APKs. No app binary was uploaded.

Flutter/Dart are unavailable in the local sandbox; hosted Flutter/native CI is the compilation/test authority. The next milestone is an **owner-approved, signed internal candidate with real-device evidence**, not public submission or paid acquisition.

## Implemented safety boundaries

- Android MainActivity/package/resources match the unchanged `com.sanctuary.relax_mindfulness` identity. Release signing fails closed without owner credentials or explicit compilation-only unsigned opt-in; no debug-signing fallback.
- Backup import validates and stages bounded data before changing profile memory or persistence. Review and explicit replacement confirmation are required. Purchases, credentials and notification permissions never transfer; see [BACKUPS.md](BACKUPS.md). This is not crash-safe transactional or encrypted cloud storage.
- Unconnected feedback no longer pretends a message was received. Default Flutter/platform error reporting is no longer globally swallowed.
- Premium/trial access comes from the active SDK entitlement, not legacy preference flags or a successful checkout callback. Prices are localized store offerings, and cancellation/pending/missing-access/restore failures are distinct. New sales remain **off by default**. See [BILLING.md](BILLING.md).
- Reflection studio is an explicitly local writing template with real copy/clear behavior, **not AI or music generation**. Client provider/key use and false saving claims have been removed. A historically exposed credential still requires **owner-controlled revocation/rotation**; removing it from current source does not revoke it or erase Git history.
- CI has read-only repository permissions, bounded jobs, no production signing/billing/AI secrets, no app-binary upload and no deployment/submission step. All targets share Flutter 3.38.10; lock drift and failed test/build exit codes remain failures.

## Release blockers, highest value first

| Priority | Boundary / source | Why it blocks launch | Required evidence |
| --- | --- | --- | --- |
| P0 | Credential incident — historical AI key / repository history | A removed client key may still be usable by others. | Owner revokes/rotates it in the provider account and reviews usage/cost exposure. Never paste a replacement here or compile it into the app. Remote AI is out of this release unless separately designed/approved with server-side authorization, consent and cost limits. |
| P0 | Billing and real value — `lib/services/subscription_controller.dart`, `lib/screens/premium_screen.dart` | Code/fake-gateway tests cannot prove receipt mapping, real offers, store behavior or a worthwhile paid benefit. | Owner-approved products/entitlement mapping and real legal/support pages; both stores' sandbox matrix for cancellation/pending/restore/expiry/refund/reinstall and localization. Confirm Premium's actual benefits. Sales stay disabled until approved. See [BILLING.md](BILLING.md). |
| P0 | Packaging/signing/identity — native projects | Credentials are intentionally absent. iOS still uses **Zen Night / com.sagozen.zennight**, unlike Sanctuary. Unsigned compilation is not distribution. | Confirm existing app/customer history before any rename; owner-controlled signing, signed install/upgrade/device tests and store validation. [NATIVE_RELEASE.md](NATIVE_RELEASE.md) gives the runbook. |
| P0 | Audio behavior/catalog — `lib/providers/app_state.dart`, catalog models | Real platform interruptions, background behavior, source availability and fallbacks remain unverified. | Device tests for concurrent loads, pause/seek/retry, interruptions, background/lock screen, route changes, long timers, volume limits and network failure; verify that each selected track has an accurate source/fallback. |
| P0 | Content and branding rights — asset provenance/readmes and audio sources | Some retained artwork is cropped from supplied references. Online availability is not proof of redistribution rights. Individual story narration/downloads are not implemented. | Confirm or replace every unclear asset, retain licenses/provenance and truthful marketing descriptions. |
| P0 | Privacy, storage and support — backup/wellbeing/billing flows | Personal data and third-party SDK behavior need disclosure. Local preferences/clipboard are not an encrypted vault; support delivery is not configured. | Owner-approved support/privacy/terms destinations, SDK/data inventory, retention/deletion and store disclosures; backup failure/device tests. Do not claim submissions are sent. |
| P1 | Reminders/timezone — notifications and AppState | A persisted preference is not proof of a permitted, correctly timed notification. | Device timezone/DST, permission-denied/cancel/restart and actual schedule tests with honest UI. |
| P1 | Navigation/demo/accessibility — `lib/main.dart`, legacy/demo surfaces | Legacy routes/admin/demo surfaces need deliberate product review. A clean build does not prove usable assistive navigation. | Every public action leads to a supported destination; isolate demo/admin features; test small screens, larger text, VoiceOver and TalkBack on the compiled candidate. |

## Staged rollout proposal — not an authorized spend plan

1. **Internal release candidate:** green engineering gates, verified rights/privacy/support, signed upgrade/backup/device/audio checks and sandbox billing if enabled. Record exact build, OS and device.
2. **Small invited beta:** after owner approval, observe real task completion and return usage with appropriate consent and minimal collection. No fabricated history, testimonials, ratings or engagement metrics.
3. **Small capped acquisition experiment:** only after explicit approval of budget, platform, audience, destination, creatives and stop conditions. Measure activation/retention/costs before scaling; traffic does not repair broken purchases or churn.
4. **Scale cautiously:** require sustainable value, support, billing accuracy and crash evidence plus a rollback path. Budget changes, public releases and account/data operations require approval.

## Reproduce checks

```sh
# Pinned Flutter 3.38.10, with native build tools where applicable:
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test
flutter build web --release
flutter build apk --debug

# Development-only browser and diagnostic tests:
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
```

Native release compilation and signing boundaries are documented separately in [NATIVE_RELEASE.md](NATIVE_RELEASE.md). Passing these commands is not approval to publish or spend.
