# Sanctuary — active project goals

Agreed 2026-11-19. **Stability first, custom icons next.** Work in small, testable batches rather than redesigning the app at once. This is a development plan, not authorization to publish, spend, sign builds or change store identities.

**Current priority: release hardening, not new features or a public launch.** The requested ambient-player/stutter correction, exact recipes and simpler library are implemented. [Current hosted verification](release/BUILD_CHECKS.md) now includes **409 passing Flutter tests**, pinned analysis/formatting, release web compilation and the browser job, plus successful exact-source Android debug/unsigned release and unsigned iOS compilation. Device audio, human listening, rights, credentials and owner release decisions remain open. The preflight remains **BLOCKED** and custom icons remain deferred.

The restored snapshot was reconciled and pushed on the existing working branch without resetting work or rewriting remote history. Hosted verification exposed and corrected native control-sheet overflow and test lifecycle/route/lazy-layout issues without disabling assertions. The earlier readiness, recipe, surface and player regressions are included in the full Flutter suite.

**Historical implementation checklists below** preserve what had and had not run at each local stage. Their then-unexecuted/native-SDK labels are superseded by the current hosted record, **not** by signed-device or human-listening evidence. The old **289 web / 71 Python** and **55 live checks** are historical runs, not new physical-output certification. [Hardening handoff](LAUNCH_HARDENING.md) · [unfilled device/listening worksheet](release/DEVICE_QA.md).

## Preserve throughout

- Keep **Home / Sounds / Meditate / Sleep**, in that order, with their existing destinations.
- Preserve the preferred large outlined **Ocean / Rain / Wind / Thunder / Nature** controls, gold Thunder symbol, moonlit Sleep design and compact playlist cards. Playback glow must mean playback, not just a selected level.
- Keep Meditate's plain teal page and artwork inside cards, not page wallpaper.
- Preserve the distinct source-labeled ambient arrangements, same daily practice across Home/Med, and no unrelated audio fallback or narration claim.
- Keep safe gain, explicit loading/error/retry/cancellation, pause/resume/seek/loop/minimize, one-layer replacements and saved selections.
- Do not fabricate listening activity, completion, audio availability or native verification. HTML preview, Flutter compilation and real-device evidence are separate.

## Requested ambient player / actual audio interruptions — IMPLEMENTED LOCALLY, NATIVE CHECKS OPEN

- [x] Automatically expand intentional ambient starts; minimize without stopping and reopen from a persistent mini-player on every tab, including paused/loading/failed selections.
- [x] Show/edit actual layers and independent levels, same-source retry, separate custom Save and the existing timer/fade. No fake narrated timeline or source substitution.
- [x] Reproduce browser loop-boundary rebuffer events and replace that path with decoded local audio-clock loops. The 67-second after-run observed eight wraps on four retained nodes with zero runtime waits; the artificial slow-download test eventually played all four without a timeout failure.
- [x] Execute 27 new web regressions with the complete 283-case suite, 71 Python tests and 55 live checks; inspect two actual HTML captures. Author 15 new Dart cases; WASM parsing/formatting only, **not a Flutter run**.
- [x] Reproduce three gain/timer-triggered browser resumes after interruption, then separate gain updates from explicit transport. Retain normal deliberate starts and failed-layer selections; add the new native part/widget tests to the CI format command without triggering CI. Current full suite: **289/289 web + 71/71 Python**; **115/115 protected hashes** unchanged. Seven more native cases are authored/WASM-parsed but unexecuted (22 player-related additions total).
- [ ] Fresh Flutter compilation/tests, signed devices, background/interruption checks and human listening. Browser findings do not prove the native stutter is fixed.

[Implementation, captures, measured timings and boundaries](AMBIENT_PLAYER.md). This requested correction does not authorize publishing, sales, accounts, spending or a custom-icon rollout.

## Launch hardening — IMPLEMENTED LOCALLY, EXTERNAL GATES OPEN

- [x] Put the preserved 77-entry inventory behind a deliberate review path; retain 18 normal sources, ten exact recipes, all saved/favorite/legacy identities and individual levels.
- [x] Remove native automatic network fallback for bundled identities; same-asset retry remains, with source/fixture checks and four new unexecuted native regressions. No source binding/media/Sleep drawing changed.
- [x] Inventory all shipped media and effective remote legacy bindings; add fail-closed evidence accounting and inventory-only read-only CI validation. All real approvals remain pending, not auto-filled by tests.
- [x] Execute 256 web / 71 Python tests, protect 159 hashes, check asset versions/JS/whitespace and prepare the owner device/listening worksheet.
- [ ] Owner rights/claims and historical credential-incident resolution.
- [ ] Fresh pinned Flutter/native analysis/tests/release compilation for current source; signed install/upgrade and actual device/listening/accessibility/backup/reminder checks.
- [ ] Owner confirms identities, privacy/support and a small invited beta decision. Purchases stay off; no public launch, spending or automatic signing/upload.

## Simpler library / Meditate — IMPLEMENTED, NATIVE VERIFICATION OPEN

The user approved proceeding with the [flow proposal](PRODUCT_FLOW_PROPOSAL.md). This first pass simplifies existing features without enabling new locks or checkout; the Free/Premium allocation and sales configuration remain proposed. [Detailed behavior and limits](SIMPLE_LIBRARY_FLOW.md).

- [x] Default Sounds to Available (18), preserve Full catalog (77), older presets, saved mixes/favorites/legacy levels and share/backup identities. Browsing is non-destructive and never autoplays. Missing/stream-only sources are labeled separately from access.
- [x] Separate Change sound (18 searchable sources) from Choose recording (the real Fire/Birds pairs only). Preserve explicit eight-second previews, duplicate-source guards, levels, pause state, gain recovery and cancellation fences. Do not invent alternate rain takes.
- [x] Start Meditate with today and three real practices; retain all 14 behind Browse all and simple filters. Add visible Save, retain source labels/IDs/no-narration disclosure, options/copy and truthful playback/loading state. Keep plain teal, artwork, four tabs and preferred Sleep controls.
- [x] Pass **15 new browser flow cases**, two new family/filter source-parity guards and the full **219/219 web + 41/41 Python suites**, zero failures/skips. Exercise all existing sources, 23 arrangements and ten sets; retain keyboard focus through filter/save updates.
- [x] Live-check five viewport widths: **40/40 checks**, plus 1.6× browser text/44px actions and inspected current HTML captures. Verify **93 protected audio/artwork/Sleep/engine/recipe/billing hashes**, 18 preview asset versions, JS syntax and patch whitespace.
- [x] Author **16 native model/controller/widget cases**; eleven touched Dart files are WASM parse/format-stable. This is **not executed Flutter, type analysis or native compilation**.
- [ ] Run the pinned Flutter analysis/full tests/builds, then actual listening/device checks. Do not treat the old CI run as current evidence or enable sales to test availability.
- [ ] Review a separately labeled non-purchasing unlock/paywall preview and the actual sales platform/access policy before content gates. No real purchase, entitlement simulation, licence acquisition or release is authorized by this pass.

### Browser availability screenshot follow-up — IMPLEMENTED

- [x] Reproduce the reported toast from Sleep Wind/Thunder and old stream-dependent mix paths. Before mutation, preflight browser transport, presets, saved mixes, Sleep scenes/controls and Sounds switches/sliders; unavailable choices must not interrupt audio, partially apply recipes or reset timers.
- [x] Name exact app-stream versus unconfigured sources in accessible details; label unavailable choices before playback. Keep normal 18-source playback and real runtime retry behavior. Allow only explicit removal from the current selection, retaining saved mixes/favorites/other levels. No cache clearing, fallback, new recording, paid lock or native-source change.
- [x] Execute **20 new browser regressions**, **239/239 full web + 41/41 Python**, **25/25 live viewport checks**, 18 asset versions and JS/whitespace checks. Verify **148 protected native/audio/artwork/catalog/player files**, the readiness/ownership engine and all existing Sleep/nav drawings/bindings unchanged. Current [evidence and captures](SIMPLE_LIBRARY_FLOW.md#browser-availability-follow-up).

## Ten user-specified curated mixes — IMPLEMENTED, NATIVE VERIFICATION OPEN

The user supplied ten exact names, purposes and recipes and required one-tap application with individual volume levels. They replace the preceding featured ten, not the eight legacy built-ins. [Exact contract, behavior and evidence](CURATED_SOUND_MIXES.md).

- [x] Implement all ten in order, from Rainy Window Café to Peaceful Ocean Journey, with exact purposes and percentages. Use 15 canonical bundled ingredients, 3–4 per mix; do not create audio, aliases or substitute unavailable recordings.
- [x] Apply only listed layers, zero every unselected sound and immediately update switches, sliders and badges. Preserve all 18 bundled choices, 77 catalog cards, eight legacy recipes, old saved snapshots and current share/backup formats. No app-stream preflight, Sleep or 23-session recipe behavior changes.
- [x] Keep editable custom selections and separate Save; reselect restores the immutable official recipe without changing saved custom/old mixes. Preserve independent sliders (110–165% totals), with existing master output gain, per-track cap, ducking/fade and readiness/retry safeguards unchanged.
- [x] Observe the new-name discoverability regression fail before implementation; pass **22 recipe-browser + 9 parity/source cases**, full **244/244 web + 41/41 Python**, zero failures/skips. Check **50/50 live recipe/viewport combinations**, **147 protected hashes**, byte-identical source/catalog constants and inline gain/playback/availability controls, 18 asset versions, JS syntax and whitespace.
- [x] Update the native recipe/meaningful purpose UI and maintain **34 set-related native cases**: 22 model/provider/controller + 12 widget, including two added for unrelated-layer removal and separately saved customization. Four Dart files WASM parse/format-stable, not analyzed/compiled/executed. Keep existing stock/example artwork links as reference, not imported or cleared assets.
- [ ] Run pinned Flutter analysis/tests/builds and human listening/device checks. No release, sales activation, licence purchase, spending, CI push or signing is authorized by this recipe update.

### Historical first ten-set batch — recipes subsequently replaced

This records the earlier delegated-recipe batch, not current levels. The user subsequently supplied ten exact replacement recipes; current behavior and evidence are immediately above.

- [x] Add ten distinct 2–4-layer recipes using 16 existing canonical bundled sources; no missing/stream-only ingredient, duplicate alias, new recording or narration. Independent levels retain 52–70% combined starting gain rather than normalizing up to 100%.
- [x] Lead the existing Sounds tray with one-tap choices and show the selected recipe's source names/percentages. Retain the eight older keys/recipes, long-press renames, user-saved mixes, storage/share/backup identities, layout/artwork and Sleep controls. Edited or same-named custom mixes must not display a false official recipe.
- [x] Repair native named-preset application to include bundled-only names and start intent concurrently. A pending first load cannot serialize the set; existing request/readiness/ownership fences and controller application remain.
- [x] Execute **19 new independent-browser playback/UI cases** and **three recipe/source parity cases**. All ten sets actually play their exact local ingredients at the selected levels. Cover shared-loop continuity, pause/resume, honest failure, save/share/reload/no autoplay, mode exclusivity, 44px/focus/wrapping at 320/390/823px and larger text. Full suites: **202/202 web, 41/41 Python**, no skips/failures.
- [x] Live-check all ten recipes at 320/390/431/823/1440px: 50 exact playback/level/touch/overflow checks, no page errors. Preserve 67 protected audio/catalog/icon/theme/source hashes and the exact inline ambient engine; take a truthful [paused phone capture](../design/vibe-sets-mobile-preview.png).
- [x] Author **32 additional native cases**: 20 recipe/provider/controller checks in [vibe_sound_sets_test.dart](../test/vibe_sound_sets_test.dart) and 12 new widget checks in [mixer_screen_test.dart](../test/mixer_screen_test.dart). Parse/format the new source/tests with WASM; **not compiled, typechecked or executed**. These are separate from the earlier 29 readiness cases below.
- [ ] Run current Flutter analysis/full tests/builds, then human listening and device playback checks. Recipes are deliberate starting choices, not a subjective listening or acoustic-safety certification. Existing source-rights gates stay open.

## Softer surfaces across pages — IMPLEMENTED, NATIVE VERIFICATION OPEN

The original Home-first trial passed 170/170 browser checks and was shown for review. The user then requested “continou all page please”; the previous Home-only review gate is superseded.

- [x] Extend the approved matte fills to Sounds, Meditate, Sleep, full/minimized players, the sound chooser, wellbeing hub, breathing, progress, reflection, backup and installation help. Remove decorative card outlines, panel shadows, button gradients and heading rules, not meaningful outlines.
- [x] Preserve the four-tab order, content/destinations, inset and moonlit artwork, source labels and transport behavior. Keep the five preferred outlined Sleep symbols, gold Thunder and actual-playback glow byte-for-byte.
- [x] Retain keyboard-focus rings, 44px targets and non-color state cues: selected tab underline, chip/choice underlines, switch positions, chooser checkmark in Flutter, visible play/pause and progress/breathing geometry. Input boundaries and the selected subscription-plan outline remain functional.
- [x] Mirror the surface/action palette in shared Flutter components and local decorations, including onboarding, subscription and review/CMS utility surfaces. Optional light card palettes remain available without decorative shadows. Home keeps its already-approved local helpers.
- [x] Pass **180/180 browser/PWA/source/configuration checks** and **41/41 Python checks**, no failures/skips. Ten added rollout regressions cover matte panels/controls, solid-fill contrast, keyboard focus, selection, responsive text, utilities and installation help. Replace the now-obsolete Home isolation requirement rather than dropping Sleep/state coverage.
- [x] Check nine live routes at **320 / 390 / 431 / 823 / 1440px**: 45 route/viewport combinations with no page errors, document overflow or autoplay, and no rendered enabled controls smaller than 44px. Also exercise 1.6× text in browser regressions. These checks are not comprehensive accessibility certification.
- [x] Author five shared Dart surface/contrast/widget regressions in [soft_surfaces_test.dart](../test/soft_surfaces_test.dart). Thirteen changed Dart files passed WASM parsing/format stability; five legacy-formatted files passed parse-only. **No Flutter tests, type analysis, compilation or native screenshot capture ran.**
- [ ] Execute the native/shared/widget regressions and inspect compiled web and real devices on the pinned toolchain; the stability gates below remain open.

Current independent-HTML captures: [Sounds](../design/soft-surfaces-sounds-mobile-preview.png) · [Meditate](../design/soft-surfaces-meditate-mobile-preview.png) · [Sleep](../design/soft-surfaces-sleep-mobile-preview.png) · [Player](../design/soft-surfaces-player-mobile-preview.png) · [All views](../design/README.md#current-softer-surface-rollout).

No playback engine, catalog/source choice, icon geometry or audio bytes changed in this rollout: 69 protected source/catalog/audio files, the inline preview behavior and the native Sleep quick-control implementation retained their pre-rollout hashes. The earlier audio decoding/rebuild evidence is unchanged. No new icon family, publication or release is implied.

## 1. Playback stability — ACTIVE

### First batch

- [x] Exercise unavailable, blocked, partially failed and cancelled ambient loads in the independent browser preview, not just successful playback.
- [x] Make the preview's Sleep/Home/Sounds/master/mini-player indicators follow confirmed playback. Loading and unavailable streams stay unlit; loading remains cancelable and failed audio is retryable.
- [x] Preserve selected levels and healthy media when one source fails. Retrying a failed layer does not restart the healthy loop, fetch unrelated audio or change the gain limit. Late/cancelled/expired requests cannot revive old players.
- [x] Audit the native auto-fade/history boundary. Remove the unconditional activity record from timer expiry: a timer can end while silent, paused, loading or failed. Four native regressions are authored; execution remains pending.
- [x] Add ten browser regressions and rerun available web/Python checks, including current source/output hashes. Audio bytes and arrangements are unchanged; their previous full decode/level/rebuild evidence is retained separately.

### Native ambient readiness follow-up — SOURCE IMPLEMENTED, EXECUTION OPEN

- [x] Separate `requestedAmbientTracks` (intent for selection/cancellation) from `activeAmbientTracks` (owned players reporting **playing + ready**). Expose loading, buffering, playing, paused and unavailable states. Global ambient-playing labels/counts no longer use positive targets as proof of playback. Native-reported readiness is **not proof of sound at the device speaker**.
- [x] Observe ambient player-state changes as well as errors. An unconfirmed start has a 12-second readiness deadline, independent of the existing per-source load timeouts. Buffering and platform pauses remove a layer from the playing count without discarding its requested level. Unexpected loop completion becomes a retryable failure.
- [x] Preserve cancellation before readiness, running-intent replacements, pause/resume levels and ownership fences. Revoke cancelled loading/starting players before a new request can reuse them. A late global pause, old play future or stale state event must not own a replacement request.
- [x] Retain failed selected levels and named mixes. Add an explicit 44px **Retry** action for a configured failed layer; retry that layer at its existing level without reloading/restarting healthy loops or deleting other failed selections. Unconfigured sounds still need a real replacement, not unrelated fallback audio.
- [x] Update Home, Sounds, Sleep, the shared mini-player and sound-controls sheet with truthful state text/transport. Pending mixes keep enabled cancel controls. Sleep glow receives only ready/playing levels; the preferred `_QuickTrack` implementation, all icon drawings, theme files, catalogs, preview implementation and audio bytes remain unchanged by this follow-up.
- [x] Author **29 regressions**: 14 state/controller-integration cases in [ambient_audio_state_test.dart](../test/ambient_audio_state_test.dart), five presentation-controller cases in [mixer_controller_test.dart](../test/mixer_controller_test.dart), and ten widget cases in [ambient_playback_presentation_test.dart](../test/ambient_playback_presentation_test.dart). Extend fakes to simulate delayed starts, readiness, buffering, interruptions and stale events. **None has executed on Flutter here.**
- [x] Rerun available checks: **180/180 browser checks** and **41/41 Python tests**, zero failures/skips. Verify 18 preview asset versions, 76 protected preview/audio/catalog/icon/theme file hashes, and the Sleep quick-control byte hash. Ten changed Dart files pass WASM parsing/format stability; AppState and the legacy-formatted shared components pass parse-only. These checks do not execute or typecheck native code.

When the pinned Flutter SDK is available, first run:

```sh
flutter analyze --no-fatal-infos
flutter test test/vibe_sound_sets_test.dart test/ambient_audio_state_test.dart test/mixer_controller_test.dart test/ambient_playback_presentation_test.dart test/home_navigation_test.dart test/mixer_screen_test.dart test/sanctuary_screen_test.dart test/guided_player_test.dart
```

Then run the full existing quality/build gates and real-device matrix, not just the new focused cases. No commit, push, hosted workflow or release was triggered for this source-only follow-up.

### Remaining stability work / exit gates

- [ ] Execute and inspect the native readiness/buffering follow-up across Home/Sounds/Sleep and shared controls. The source now separates requested targets from native-reported ready/playing state; neither the browser fix nor WASM parsing establishes compiled Flutter behavior.
- [ ] Run the four new sleep-timer regressions and the existing ambient/session race, failure, retry and replacement regressions on Flutter.
- [ ] Current Flutter analysis/tests and release-web compilation pass on the pinned SDK.
- [ ] Current Android debug/unsigned release and unsigned iOS compilation pass. Unsigned compilation is not installation or release approval.
- [ ] Human listening/device matrix: start/switch, pause/resume, seek/loop, long timer/fade, connection loss, interruptions, background/lock screen and route changes. Record device/OS/build and actual observations.

**Native execution is blocked in this sandbox:** neither Flutter nor Dart is installed. Do not relabel browser checks, WASM parsing or historical CI as current native results. Use the [native runbook](NATIVE_RELEASE.md) and the existing pinned quality workflow on an approved current revision; do not run old committed code and call it validation of uncommitted changes. No commit, push or hosted workflow was triggered in this batch.

## 2. Custom navigation icon family — QUEUED

Start with only **Home / Sounds / Meditate / Sleep**. No new tab or layout redesign.

- [ ] Create editable custom vectors in one calm, rounded outline style; build on existing vector support rather than replacing icons with bitmaps or depending on an icon font.
- [ ] Keep consistent viewbox, stroke weight, optical size and rounded caps/joins. Mint is the active treatment; muted color is inactive.
- [ ] Keep text labels and an explicit selected state; do not communicate meaning using color alone. Preserve at least 44px touch targets.
- [ ] Check all four at small and large phone sizes, larger text, reduced motion and without font downloads.
- [ ] Match Flutter and the independent preview; verify navigation and player behavior before widening the rollout.

## 3. Extend the family — LATER, one group at a time

1. Sound-category symbols.
2. Player controls, retaining familiar transport meanings.
3. Utility/settings actions.

Reuse the agreed family after the four-icon batch is reviewed. Keep the preferred Sleep mixer drawings unless a separate change is requested. A launcher/store icon is a separate deliverable and must not silently replace app identities.

## Evidence log — 2026-11-19

- **Reproduced first:** three new browser regressions failed against the old implementation: stream-only controls, pending-load glow and partial-mix failure counts. They passed after the fix.
- **First stability batch: 165/165 repository browser/PWA/source/configuration checks passed**, zero failures/skips, including all ten new ambient regressions. The Home trial expanded the suite to 170/170; its subsequently approved all-page continuation now passes 180/180, as recorded above. The suite still plays all 23 session arrangements and all 18 chooser recordings. Run `npm run test:web`; focused cases are in [player_sleep_browser_test.mjs](../test/web/player_sleep_browser_test.mjs).
- **41/41 Python tests passed**, zero skips, including exact source/output/recipe hashes and provenance/rebuild safeguards. Run `python3 -m unittest discover -s tool -p 'test_*.py' -v`.
- The running HTML preview was additionally checked at **320 / 390 / 431 / 823px**: stream-only selections stayed inactive, one failed layer left only the healthy layer illuminated/counting, and there were no page errors or horizontal overflow.
- **Prior native timer source guard:** removed timer-generated listening history and added four cases in [ambient_audio_state_test.dart](../test/ambient_audio_state_test.dart). That test file passed the Dart WASM parser/formatter; AppState passed parse-only with its existing formatting preserved. These are **not executed Flutter tests, type analysis or compilation**.
- **Native readiness source follow-up:** implemented the request/readiness split and per-layer retry described above, with 29 additional native regressions authored but unexecuted. Available browser/Python checks again pass 180/180 and 41/41. Ten Dart files are WASM format-stable; AppState/shared legacy components parse only. Logs: `/tmp/arena-native-readiness-web.log` and `/tmp/arena-native-readiness-python.log`; these are workspace evidence, not portable native test reports.
- Audio assets were not regenerated in this batch. Their prior full decode/loudness/headroom/distinctness checks and independent 23-file scratch rebuild remain recorded in [session audio](SESSION_AUDIO.md).
- **Ten-set follow-up:** 19 new browser cases and three source-data guards brought that batch’s suite to **202/202**, with Python **41/41**, no failures/skips. The original discoverability regression first failed `0 !== 10` against the old UI, then passed after implementation. All 32 newly authored native cases remain unexecuted. Audio/catalog/icon/theme hashes and the preview ambient engine remain unchanged from this batch’s pre-edit baseline. Logs: `/tmp/arena-vibe-sets-all-web.log` and `/tmp/arena-vibe-sets-python.log`.
- **Library/Meditate simplification:** 15 new browser cases and two family/filter guards brought the first-pass checks to **219/219 web + 41/41 Python**, zero failures/skips. Forty live checks and 93 protected hashes pass. Sixteen new native cases are authored but unexecuted. Logs: `/tmp/arena-simple-flow-all-web-final.log`, `/tmp/arena-simple-flow-python-final.log`, `/tmp/arena-simple-flow-focused.log`. [Current flow and captures](SIMPLE_LIBRARY_FLOW.md).
- **Screenshot-warning follow-up:** the same warning was reproduced from Sleep app-stream selections. Twenty new availability/preflight cases brought that batch to **239/239 web + 41/41 Python**, zero failures/skips. Twenty-five live checks and 148 protected files pass. Native source/media/bindings/drawings are unchanged; missing recordings were not fabricated or acquired. Logs: `/tmp/arena-preview-availability-{focused,all-web,python}.log`.
- **User-specified replacement recipes:** exact names/purposes/levels now pass 22 recipe-browser and 9 source/parity cases, full **244/244 web + 41/41 Python**, **50 live checks** and **147 protected hashes**. The original eight presets, 18-source/77-card catalog and all media/engines remain intact. Two native cases added; 34 set-related cases remain unexecuted. Logs: `/tmp/arena-requested-curated-{focused,parity,all-web,python}.log`. [Current recipes and capture](CURATED_SOUND_MIXES.md).
- Flutter/native/device gates above remain open. Content-rights, privacy, signing and store gates remain in [launch readiness](LAUNCH_READINESS.md).
