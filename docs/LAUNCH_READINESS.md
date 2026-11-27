# Sanctuary launch readiness

Updated: 2026-11-19. Product ownership, branding, accounts, spending authority and release approval remain with the repository owner. Development assistance does not transfer those responsibilities to an AI or make it a legal business partner.

**Revenue-focused execution plan:** the owner requested structured help and confirmed **10+ hours/week**. The [working roadmap](REVENUE_ROADMAP.md), [customer interview kit](business/CUSTOMER_INTERVIEWS.md) and [blank scorecard](business/weekly-scorecard-template.csv) put customer evidence and repeat use before a paid offer or advertising. The proposed focus audience and hypothetical economics are not market proof. Actual publication/users/revenue remain unknown; no outreach, analytics, sales, spending, public deployment or release approval was performed by the planning update. The release gates below remain unchanged.

## Current decision: internal validation, not public launch or paid acquisition

A proposed $100,000 traffic budget is not evidence of readiness or authorization to spend. First prove that people can install, use, return to and—if monetized—safely pay for the real application. No ads, production billing changes, store submission or public release have been made. Existing **Home / Sounds / Meditate / Sleep** navigation and shared playback are retained.

## Latest UI/source follow-up — current design, no install entry

The midnight-blue design and four-tab navigation remain the target. The page-level **Install app** entry is removed from both shared web surfaces, with no native runtime/layout or audio-source changes. Local suites pass **326/326 web + 93/93 Python**; a controlled Home comparison changed no pixels outside the removed control, and 24 tab/viewport checks passed. [Current captures](../design/README.md#current-visual-target--no-install-app-button).

The owner-approved design is now on default `main` through PR #1, not only the working branch. Both pre-merge workflows at `cbaf083` and post-merge run 45795349126 at `0830d28` passed all four jobs, including **429 Flutter tests, zero failed/skipped**. The earlier three Flutter failures are resolved. This is source/build verification, not site deployment, signed installation or TestFlight distribution. [Exact-source evidence](release/BUILD_CHECKS.md).

A subsequent cleanup removes 57 old screenshots, nine undeclared build exports and two unreferenced demos while preserving active code, every declared asset and all regression coverage. All four tabs are pixel-identical in controlled before/after cleanup captures; 24 responsive checks passed. Cleanup runtime fingerprint: `bc0000ea70d7319b7870dac1bede4a3527565bb27369797b521e8e8e7ce7f06e`. The green hosted runs above certify the pre-cleanup baseline; cleanup Flutter/native results must identify the cleanup's own exact pushed source in the build record/workflow history. Preflight remains **BLOCKED / 202 pending** and purchases stay off. No website deployment, identity change, signing or store upload is authorized by this cleanup.

## Preceding development-audio follow-up — release still BLOCKED

Temporary audio is accepted for development, not distribution. Six older mixer clips now use separately inventoried overlap-blended loop edits; the original inputs, twelve newer mixer sources and all 23 arrangements remain unchanged. No video audio or extra #2/#3 takes were acquired. The target is three genuinely different recordings per available sound, **54 total**, still pending. [Scope and reproduction](PLACEHOLDER_AUDIO.md).

At the audio checkpoint, local suites passed **322/322 web + 93/93 Python**, zero failures/skips; six final edits also passed full decode/headroom checks. One new native case and the updated source paths are authored/WASM-parsed, **not Flutter-executed or device-listened**. Current preflight is **BLOCKED / 202 pending**: 118 local media reviews (including 48 audio files, not 48 unique recordings), 75 stream reviews and nine gates. No source is newly approved; purchases remain off. The historical hosted results and the older counts below do not certify these changes.

## Original launch-hardening pass — historical engineering checkpoint

New features/custom icons are deferred. The [hardening handoff](LAUNCH_HARDENING.md) now provides a deliberate unfinished-catalog review route, same-local-file native failure/retry instead of silent network fallback, a complete media/effective-stream evidence register and a read-only offline preflight. All 18 bundled sources, 77 stable cards, ten exact recipes, saves/favorites, Sleep drawings/bindings and media bytes are retained. Native source changes require fresh Flutter verification.

Current executed local result: **256/256 web + 71/71 Python**, no failures/skips; **159 protected hashes** match. All 112 local media reviews, 75 effective stream-only native name bindings (including legacy names outside the 77 cards) and nine required evidence gates remain pending. Full preflight deliberately returns **BLOCKED / exit 1**; inventory-only CI success is not readiness approval. The [device/listening worksheet](release/DEVICE_QA.md) is unfilled. No licensing, credential rotation, signing, native SDK run, commit/push, store submission, purchase enablement or launch was performed by this pass.

## Active development sequence

[Project goals](PROJECT_GOALS.md) now prioritize **launch hardening; feature/icon work is deferred**. The earlier stability-first sequence remains recorded below as history. The first browser-stability batch fixes false-active loading/error indicators and cancelled-load ownership without changing layouts or audio recipes. A native source guard removes timer-expiry-generated listening records; its four regressions remain unexecuted. The follow-up now implements separate ambient request/readiness state, pending cancellation, truthful counts/glow and per-layer retry in Flutter source, with 29 more regressions authored but unexecuted. Compiled native readiness/buffering behavior remains an explicit open gate, not covered by the HTML fix or WASM parsing.

## Current wellbeing / Meditate / audio follow-up — local checks passed, Flutter pending

Home's wellbeing actions now push separate solid-color breathing/progress/reflection/backup pages; progress uses recorded activity. Meditate has arched inset cards on a plain teal page. The four footer tabs, timed player and staged native backup safeguards remain. These changes are not a diagnosis of every unspecified device error or an audit of all legacy/demo routes.

The [sound-library inventory](SOUND_LIBRARY.md) now has **77 cards** (75 retained + two new), **18 distinct local chooser sources**, searchable explicit Preview/Use controls and new-source credits. **41/77 card names have sources: 18 local + 23 stream-only; 36 still need recordings.** The [twelve-addition pack](audio-licenses/ambient-pack-2026-11-19.md) documents seven original-page CC0/public-domain grants and five generated noises, not blanket clearance for legacy audio/artwork/streams. Wood-thrush Content ID reports, human listening and device audio remain open gates.

The [first-pass simplification](SIMPLE_LIBRARY_FLOW.md) now defaults to 18 bundled sources, keeps all 77 stable entries in Full catalog and separates Change sound from the real Fire/Birds recording pairs. Meditate starts with today and three practices, visible Save/ingredients, simple filters and Browse all 14. This does not activate the proposed Free/Premium split or sales. Existing selections/access, playback identities, Sleep controls and billing files are preserved.

The session-audio routing defect is now fixed in source and the independent preview: **23 named two-source ambient arrangements** replace the universal sample. Actual ingredients and ~30-second repetition/no-narration labels are visible; missing audio fails explicitly rather than silently substituting a different recording. Home and Meditate still share the daily practice. The eight former story entries are labeled **Nighttime Journeys** with fictional narrators removed. [Recipes and measured checks](SESSION_AUDIO.md); this does not clear input rights or constitute a human/device listening pass.

Executed pre-hardening follow-up evidence: **244/244 browser/PWA/source-data/configuration tests**, **41/41 Python tests**, and all twelve final MP3 full-decode/hash/provenance/distinctness/bounded-level checks passed, with no skipped tests. The browser suite plays all eighteen chooser files, all 23 selected session arrangements and all ten new bundled-source vibe sets. The set batch adds 19 browser cases and three recipe/source guards; 32 new native recipe/provider/controller/widget cases are authored but unexecuted. The subsequent library/Meditate pass adds 15 browser cases, two parity guards and 16 more unexecuted native cases; 40 live-preview checks and 93 unchanged protected-file hashes passed. The later screenshot-warning fix adds 20 browser preflight/availability cases and 25 live checks; 148 native/media/catalog/player files, all source bindings and vector drawings are unchanged. It fixes browser entry points, not missing recordings or native/device verification. The subsequent [user-requested preset replacement](CURATED_SOUND_MIXES.md) updates the featured ten with exact names/purposes/levels, 22 recipe-browser cases and 9 parity guards; 50 new live checks and 147 current protected hashes pass. Existing gain limiting preserves requested slider values even when totals exceed 100%. Set-related native coverage is now 34 cases (two added), still unexecuted; no media, catalog/source binding or playback engine changes. [Recipes and boundaries](SOUND_LIBRARY.md#ten-one-tap-vibe-sets). The arrangements also passed full decode, measured stereo loudness/headroom and 253 pairwise identity-regression comparisons; a scratch rebuild reproduced their hashes. Screenshots remain **independent HTML**; browser breathing history is separate, and browser backup is explicitly layout-only. Changed Dart files were WASM-parsed/formatted, not compiled. New Flutter regressions are authored but **unexecuted**. Fresh Flutter analysis/tests/web/Android/iOS CI is required for this follow-up; the historical run below does not cover it.

## Historical verified engineering baseline — not approval of current changes

Verified code revision: **`d6447f6417e864b3194483722ef0cc98a3bc866d`**. [Run 44483121445](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44483121445) completed **successfully in all four jobs** on 2026-11-19. This is evidence for that exact revision, not automatic approval of future code or a store release.

| Check | Observed result |
| --- | --- |
| Flutter 3.38.10 analysis and scoped formatting | Passed. Legacy analyzer infos remain advisory; analyzer warnings/errors fail. |
| Flutter regressions | **260 passed, 0 failed, 0 skipped.** No test was disabled to obtain a pass. |
| Flutter release web compilation | Passed. This does not validate browser audio or installation on every device. |
| Android debug APK | Compilation passed. |
| Android unsigned, R8-minified release AAB | Compilation passed; the unused Play SplitInstall shrinker failure is fixed. |
| Android compiled-artifact inspection | Passed: application ID unchanged, minimum API 24 / target API 36, Billing Library 8 metadata, **5 APK / 6 AAB 64-bit libraries** with 16 KB ELF alignment, debug APK ZIP alignment and unsigned AAB. |
| Android signing rejection test | Passed: a credential-free release without explicit unsigned opt-in failed at the signing guard. |
| iOS unsigned release device build / Xcode 26.3 | Passed. Not an IPA, signed archive or device installation. |
| Browser/PWA/platform configuration and Python fixtures | Passed. Local reproduction was **116/116 browser/source tests** and **15/15 Python tests**; the browser preview is independent HTML, not native screenshots. |
| Dependency-lock gate | Passed on Flutter, Android and iOS. RevenueCat 10.19.1 and direct url_launcher are reconciled in the committed lockfile. |

The earlier lock drift, regression failures and new artifact parser's legacy-AAPT assumptions are resolved. The parser now supports current AAPT2 output without reducing the required API/Billing levels. CI inspected real generated Android artifacts, separately from the Python verifier fixtures. Static alignment does **not** prove behavior on a 16 KB device or validate Play-generated APKs. No app binary was uploaded.

Flutter/Dart are unavailable in the local sandbox; hosted Flutter/native CI is the compilation/test authority. First rerun it for the current wellbeing/audio changes after an approved commit/push. Only then pursue an **owner-approved, signed internal candidate with real-device and rights evidence**, not public submission or paid acquisition.

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
| P0 | Content and branding rights — asset provenance/readmes and audio sources | Some retained artwork is cropped from supplied references; legacy audio/streams lack recording-specific clearance. New-pack grants are documented but the birds source has Content ID complaints. Individual story narration/downloads are not implemented. | Confirm or replace unclear assets, review/resolve claims, retain recording-specific evidence and use truthful descriptions. A source-site grant is not a claim-free warranty. |
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
