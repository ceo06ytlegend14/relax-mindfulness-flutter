# Sanctuary launch readiness

Updated: 2026-11-19. Product ownership, branding, accounts, spending authority and release approval remain with the repository owner. Development assistance does not transfer those responsibilities to an AI or make it a legal business partner.

## Current decision: do not scale paid acquisition yet

A proposed $100,000 traffic budget is not evidence of product readiness or a commitment to spend. First prove that people can install, use, return to and—if monetized—safely pay for the real application. This repository does not authorize ad spending or guarantee users, revenue, retention or returns.

The priority is release reliability and truthful capabilities, not adding screens to create an appearance of progress. Existing Home / Sounds / Meditate / Sleep navigation and shared playback are retained.

## Safety and native preparation — verification in progress

- [x] Correct Android MainActivity's package/path to match the existing `com.sanctuary.relax_mindfulness` namespace. The application ID is unchanged.
- [x] Replace the nonexistent `ic_launcher_round` reference with the existing launcher resource. Structural tests cover both launcher references and the activity package/path; this is not an Android compilation result.
- [x] Validate/stage all backup categories before changing memory or saving preferences. Add side-effect-free review, explicit replacement confirmation, readiness checks, payload/type/range limits, private error notices and persisted reminder fields. See [backup guarantees/limits](BACKUPS.md).
- [x] Remove the unconnected feedback form that claimed a message had been received.
- [x] Align the declared minimum SDKs with the existing lockfile: Flutter 3.32 / Dart 3.8.
- [x] Define read-only quality automation with SHA-pinned actions, locked browser tooling and Flutter analysis/tests/web compilation. It neither deploys nor modifies billing or store accounts.
- [x] Obtain the first hosted Flutter result: [run 44468832125 / 603976a](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44468832125) passed analysis, formatting, release web compilation and all 90 browser/config checks. **Flutter regressions failed**; the run is not green.
- [x] Replace Android release's debug-signing fallback with explicit owner-controlled configuration and a fail-closed guard. Restrict iOS HTTP exceptions to local networking and remove unimplemented background fetch. Existing application IDs remain unchanged.
- [x] Add automatic Android debug/unsigned release and unsigned iOS/Xcode 26 CI jobs, API 36 targeting and a shared Flutter 3.38.10 toolchain. See [native release runbook](NATIVE_RELEASE.md). **This migration, dependency lock update and native compilation are not verified yet.**
- [ ] Resolve all real hosted test/build failures and pass the complete workflow. The sandbox has no local Flutter/Dart SDK; syntax parsing is not compilation.

## Release blockers, highest value first

| Priority | Boundary / source | Why it blocks launch | Required evidence |
| --- | --- | --- | --- |
| P0 | Real Flutter/runtime checks — `.github/workflows/quality.yml`, `test/` | The first hosted Flutter analysis/web build passed, but Flutter tests failed. The newer native toolchain/lock migration is pending. HTML preview success cannot prove native correctness. | Passing analysis/tests/web build on the shared pin; Android debug/release compilation and real-device checks; iOS build/device evidence. Fix failures rather than weakening checks. |
| P0 | Billing — `lib/screens/premium_screen.dart`, premium methods in `lib/providers/app_state.dart` | The purchase path chooses local trial/premium state after a purchase call instead of deriving access from the returned active entitlement. Trial/conversion text and displayed pricing also need to match actual store offers. | Verified RevenueCat/store configuration, localized products/prices, active entitlement reconciliation, cancellation/refund/expiry/reinstall/restore tests and supported-platform behavior. No live billing settings were changed in this pass. |
| P0 | AI credential/cost boundary — `lib/screens/ai_studio_screen.dart` | A `GEMINI_API_KEY` compiled into a client can be extracted. The procedural fallback and unavailable generation/save capabilities must not be sold as more than they are. | Server-side credentials, authenticated/rate-limited requests, user-visible data-handling rules and cost caps; accurate UI and a safe unavailable mode. No AI API request or account change was made in this pass. |
| P0 | Android/iOS packaging and signing — `android/app/build.gradle.kts`, native projects | Debug-signing fallback is removed; production credentials are intentionally absent. API 36/Xcode 26 compilation and the iOS Zen Night/Sanctuary naming mismatch still need verification/owner confirmation. | Owner-controlled signing/configuration, confirmed stable IDs/branding, signed install/upgrade/device checks and store metadata. Follow [NATIVE_RELEASE.md](NATIVE_RELEASE.md). Never put signing keys or passwords in chat/Git. |
| P0 | Audio behavior/catalog — `lib/providers/app_state.dart`, catalog models | Playback request guards need real platform validation. External source availability, category aliases and fallbacks need auditing so a selected sound is not silently represented by unrelated audio. | Device tests for concurrent loads, pause/seek/retry, interruptions, background/lock screen, route changes, long timers, volume limits and network failure; verified catalog/source mapping. |
| P0 | Content and branding rights — `assets/images/*/README.md`, audio sources | Some inherited artwork is cropped from supplied references; availability online is not proof of redistribution rights. Individual story narration/downloads are not implemented. | Confirm or replace every unclear asset; retain licenses/provenance and truthful feature descriptions before public/store marketing. |
| P0 | Privacy, storage and support — `docs/BACKUPS.md`, wellbeing/AI flows | Mood/session data can be personal. Local preferences/clipboard exports are not encrypted cloud backup or crash-safe storage. No verified feedback delivery endpoint exists. | Appropriate privacy/retention/deletion policy and support destination, least-data collection, reviewed storage strategy and backup failure/device tests. Do not claim submissions are sent until delivery is implemented and verified. |
| P1 | Reminders/timezone — `lib/providers/app_state.dart`, notification services | Persisted preference is not proof that a local-time notification is scheduled with permission. | Correct device timezone/DST behavior, permission-denied/cancel/restart tests, platform schedule verification and honest UI. |
| P1 | Navigation/demo cleanup — `lib/main.dart`, CMS/admin/demo screens | Legacy breathe/AI tab mapping and mock/demo surfaces need deliberate product decisions, not silent exposure or arbitrary removal. | Every public action leads to a supported destination; demo/admin functions removed or properly isolated; accessibility and small-screen checks on compiled builds. |

## Staged rollout proposal — not an authorized spend plan

1. **Internal release candidate:** pass the checks above, validate upgrades/backups, inspect crash/audio behavior on target devices, verify privacy/billing/support, and record which build was tested.
2. **Small invited beta:** observe real task completion and return usage, with appropriate consent and minimal collection. No fabricated listening history, testimonials, app ratings or engagement numbers. Choose success criteria from the actual audience and pricing; no metrics have been measured by this repository pass.
3. **Small capped acquisition experiment:** only after the owner approves the budget, platform, audience, destination, creatives and stop conditions. Measure reliable activation/retention and costs before increasing spend. More traffic does not fix churn, broken purchases or audio failures.
4. **Scale cautiously:** require evidence of sustainable value, functioning support, billing accuracy and crash-free operation. Keep a rollback path. Budget changes, ads, public releases and destructive account/data actions require explicit owner approval.

## Checking this pass

**Local results (2026-11-19):** `npm ci --ignore-scripts` succeeded and **all 90 repository browser/PWA/platform-configuration tests passed**, with no failures/skips. All **48 Dart source/test trees** passed syntax parsing; the seven new Dart implementation/test files were formatted. Manifest XML, quality-workflow YAML, documentation links and `git diff --check` also passed. None of these substitute for Dart type analysis, Flutter widget tests, compiled builds or a hosted workflow result. The new Flutter backup suites remain unexecuted.

- Development browser tooling is reproducible with `npm ci --ignore-scripts` and `npx playwright install --with-deps chromium`; run `npm run test:web`.
- Framework-free Android checks: `npm run test:platform`. They inspect source/resource consistency only.
- Real Flutter checks: `flutter pub get --enforce-lockfile`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build web --release`, and `flutter build apk --debug` as applicable.
- The quality workflow has read-only repository permissions, no deployment step, no billing/AI credentials and bounded job timeouts. Native compilation now runs on pushes/PRs too; unsigned compilation is deliberately separate from signing or store submission. Build and test diagnostics preserve failing exit codes.
- No ads, analytics SDK, accounts, backend services, live billing configuration or release publication were introduced by this safety pass.
