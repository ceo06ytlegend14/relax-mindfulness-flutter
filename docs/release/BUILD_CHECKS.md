# Candidate build-check evidence — not launch approval

## Verified current-design baseline — `cbaf083` and main merge `0830d28`

The owner approved [PR #1](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/pull/1) merging the selected midnight-blue design into `main` only after fresh checks passed. Exact source **`cbaf083108a106dc7f6f6aeea17883c9b9890725`** passed all four jobs in both [push run 45793507523](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45793507523) and [PR run 45793622507](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45793622507):

- **429 Flutter tests passed, 0 failed, 0 skipped**, plus pinned analysis/scoped formatting and release web compilation. The prior three asset-path/lazy-list failures below are resolved without skipping assertions.
- Browser/PWA/platform checks, Python fixtures and inventory-only accounting passed.
- Android debug/explicitly unsigned release compilation, signing rejection and compiled-artifact checks passed.
- Xcode 26 unsigned iOS device compilation passed; no signed archive, IPA, install or TestFlight upload.

The merge **`0830d28ed31f5901b65429eb74ff85692017d847`** has exactly the verified source tree **`3a979841ecfd0a2126b801824dc75f0ca53eb6d4`**. [Post-merge main run 45795349126](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45795349126) also completed successfully in all four jobs. The working branch was retained; no history rewrite, website deployment or store distribution occurred.

## Source cleanup — local verification

The later cleanup removes **57 superseded PNGs, nine undeclared old Flutter-export files and two unreferenced theme showcases**, replacing the gallery with four current tab captures. Only the obsolete demo URL is removed from the existing sitemap; other owner URLs/identities are unchanged. Active native routes, preview HTML/CSS/JS/symlinks, dependency locks, all **96 declared bundled inputs**, source licences/provenance, tests and CI are protected. The similarly named native Neumorphism page is still used by Sleep and is retained.

A controlled **418 × 885** before/after comparison found **zero changed pixels on each of Home, Sounds, Meditate and Sleep**. Another **24 tab/viewport checks** passed: no overflow, page errors or failed responses, ≥44px navigation targets, and the footer retained. The healthy existing port-3000 process was reused. These are independent HTML/Chromium checks, not native-device or listening evidence.

Current cleanup runtime fingerprint: **`bc0000ea70d7319b7870dac1bede4a3527565bb27369797b521e8e8e7ce7f06e`**. The fingerprint changes when unused Dart/web demo sources and sitemap metadata are removed; no active engine, source binding, recipe or media input changes. Fresh cleanup checks pass **326/326 web + 97/97 Python**, zero failures/skips; the Python total includes four new source-hygiene cases, observed failing before the cleanup. All **21 preview content versions**, relative documentation targets and patch whitespace also pass. Hosted cleanup Flutter/native results must be matched to the exact pushed source in the [branch workflow history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/workflows/quality.yml?query=branch%3Aarena%2F6ab3ce1c-relax-mindfulness-flutter), separately from the pre-cleanup runs above. Local checks and those older runs alone do not establish cleanup Flutter execution.

All **118 local rights reviews + 75 stream reviews + nine release gates = 202 pending** remain unchanged; purchases stay off. Removing build leftovers does not grant rights or shrink Git history, and the source-tree saving is not an installed-app-size measurement.

## Historical checkpoint `b2e2a1a` — failed before the verified correction

[Run 45782497839](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45782497839) completed for `b2e2a1a8aa5f5cad4604e2520d1ad19862422328`, whose two-parent merge preserved checkpoint `5a65abc` exactly and retained the existing GitHub history. **Browser/PWA/platform, Android debug/unsigned release and unsigned iOS compilation passed. The Flutter job failed: 426 passed, 3 failed, 0 skipped.** This is not all-target approval or device verification.

Failures were one stale audition expectation (the implementation correctly selected `loop_ocean_waves.mp3`) and two inline-Sounds cases that assumed lazy controls/headers were already built or remained in view. Prepared test corrections keep the exact asset assertion, scroll the real vertical lazy list, verify retained scroll position/no full-player expansion, and explicitly reveal the header before checking it. No failure is skipped or suppressed. Both Dart test files pass WASM parse/format only; the corrections had no fresh Flutter execution when this note was prepared.

The accompanying install-entry removal passes **326/326 local web + 93/93 Python** checks. Runtime fingerprint: `133eb131f88b436c7124b496b80f45d388ee78bb5fca17ccfc7838430e53e514`; **202 release reviews/gates remain pending**. Consult the [live branch checks](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/workflows/quality.yml?query=branch%3Aarena%2F6ab3ce1c-relax-mindfulness-flutter) for subsequent exact-source results. Older green candidates below do not certify these later changes.

## Historical verified candidate identity

- Source checkpoint: `ccb302b7cca0e130e04d624f29a34e662b6f607a` on `arena/6ab3ce1c-relax-mindfulness-flutter`.
- Runtime fingerprint: `8b02ccfdc421379d35232d8e4809a1bdfc4c23396543a603b2f24a45f019bc62`.
- [Exact-source Quality checks run 45739413274](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45739413274). Later documentation-only commits do not change this runtime fingerprint; their own checks remain visible in the [branch workflow history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/workflows/quality.yml?query=branch%3Aarena%2F6ab3ce1c-relax-mindfulness-flutter).
- Toolchain: Flutter **3.38.10**, Java **17**, Android API **36** / minimum **24**, Xcode **26.3**. No Flutter/Dart/Xcode SDK is installed in the local coding sandbox; Flutter and native results below come from hosted CI, not WASM parsing.

## Historical observed checks for `ccb302b`

| Check | Exact-source result | Boundary |
| --- | --- | --- |
| Flutter analysis and scoped formatting | **Passed** | Analyzer warnings/errors and scoped format drift still fail. Advisory style infos are not a native behavior certificate. |
| Full Flutter regression suite | **409 passed, 0 failed, 0 skipped** | Includes fake-native readiness/interruption/late-load fences, timers/history, exact recipes, presentation, navigation, billing, backup and player coverage. No physical audio output or signed device execution. |
| Release Flutter web compilation | **Passed** | Compiled only; not hosted, installed, listened to or tested as a signed native application. |
| Browser/PWA/platform job | **Passed** | Full `npm run test:web`, Python fixtures and inventory-drift check passed. Browser playback is the independent HTML implementation, not Flutter native audio. |
| Android debug APK + explicitly unsigned release AAB | **Passed** | Owner-signing guard rejected a credential-free release without unsigned opt-in. Compiled application ID/API/Billing Library 8, APK ZIP alignment and 5 APK / 6 AAB 64-bit libraries with 16 KB ELF alignment passed inspection. No production keys or app-binary upload. |
| Unsigned iOS device compilation | **Passed** | `flutter build ios --release --no-codesign`; not a signed install, archive, IPA, TestFlight or App Store submission. |

All four jobs completed successfully for the stated source SHA: browser **2m24s**, Flutter/tests/web **2m14s**, Android **6m33s**, iOS **8m38s**. A non-blocking maintenance warning notes that the pinned Android setup action declares Node 20 while the runner uses Node 24; it did not fail the build. No required test or assertion was disabled to obtain green results.

Additional local checks: **75/75 Python tests**, **26/26 Node source/configuration tests**, **20 preview asset versions**, and patch whitespace passed. The Node subset is not an additional independent full browser run. Hosted browser totals are not inferred from an old local count.

## What the verification continuation changed

The restored snapshot was preserved and reconciled on top of remote `bd8fa2c`, then pushed normally on the same working branch. No remote history was rewritten and no work was reset away.

The first hosted run exposed real layout defects and previously unexecuted test-harness errors. Corrections retain the assertions rather than suppressing failures:

- The legacy sound-controls sheet wraps titles/actions and scrolls as a whole on short, large-text layouts. Its gain slider no longer resumes an interrupted retained player. The requested full ambient player and its audio ownership remain separate and unchanged.
- Widget tests finish Cupertino's 500 ms route transition, use valid inactive/hidden/paused/resumed lifecycle edges, and reveal lazy-list targets before hitting or measuring them. Simulated MediaQuery dimensions now match the control-sheet viewport.
- Semantics handles are disposed before widget-test end verification. Stream cleanup drains real and fake event queues without silently advancing the deterministic timer.
- The sleep-expiry/late-load test now begins loading during the timer's last six seconds. It verifies the actual sleep shutdown fence instead of letting the separate 12-second load timeout fire first. It still asserts revoked ownership and no late play, listening history or mood completion.
- Flutter regressions have an eight-minute step deadline inside the 25-minute job, leaving time for diagnostics, event retention and an independent web build. Deterministic sleep fixtures also have individual backstops. Timeouts, partial event streams and test failures remain failures; additional diagnostics are grouped to respect Actions annotation limits.

**262 preserved media/preview/platform/catalog/engine/fixture paths** match the recovered checkpoint, including audio/artwork bytes, exact requested percentages and source identities, the Sleep design/bindings, AppState/mixer transport, billing implementation, dependency lockfiles and the curated recipe contract. The intended native control-sheet layout/gain-callback change is not included in an unchanged-engine claim. No recording identity, recipe or artwork was substituted to make a test pass.

## Release decision: still blocked

Full `python3 tool/launch_preflight.py` still reports **BLOCKED**, expected exit **1**: **112 local rights reviews**, **75 stream reviews/pins** and **nine release gates** remain pending. Inventory-only success is not release clearance. The review register was not auto-approved because automation passed.

Next evidence is owner-led: recording/artwork/font rights and claims; historical credential revocation/usage review; existing store identities/signing and privacy/support disclosures; signed Android/iOS install/upgrade, interruption/background/routes/accessibility checks; human listening to every exact mix and independent loop join; and an explicit candidate/audience/distribution/rollback decision. Use the unfilled [device/listening worksheet](DEVICE_QA.md) and [release ledger](../LAUNCH_READINESS.md).

Purchases remain disabled by default. No production signing, app deployment, store submission, sales activation, spending or public launch occurred. Separate HTML-preview hosting is still deferred; this run did not establish a shareable preview URL.

The earlier **289 web / 71 Python**, **55 live-preview checks**, screenshots, loop telemetry and pre-follow-up fingerprints are historical measurements. They remain useful context, not substitutes for this exact-source CI evidence or physical-device/listening proof.
