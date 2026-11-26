# Candidate build-check evidence — not launch approval

## Candidate identity

- Source checkpoint: `ccb302b7cca0e130e04d624f29a34e662b6f607a` on `arena/6ab3ce1c-relax-mindfulness-flutter`.
- Runtime fingerprint: `8b02ccfdc421379d35232d8e4809a1bdfc4c23396543a603b2f24a45f019bc62`.
- [Exact-source Quality checks run 45739413274](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45739413274). Later documentation-only commits do not change this runtime fingerprint; their own checks remain visible in the [branch workflow history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/workflows/quality.yml?query=branch%3Aarena%2F6ab3ce1c-relax-mindfulness-flutter).
- Toolchain: Flutter **3.38.10**, Java **17**, Android API **36** / minimum **24**, Xcode **26.3**. No Flutter/Dart/Xcode SDK is installed in the local coding sandbox; Flutter and native results below come from hosted CI, not WASM parsing.

## Observed checks

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
