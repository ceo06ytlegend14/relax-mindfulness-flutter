# Reopenable ambient player and browser loop continuity

Updated: 2026-11-19. Implements the user-approved **automatic full ambient player**, separate from the timed Meditate player, and investigates the reported **actual audio stuttering/stopping**. This is not a decorative waveform-only fix.

**Current local result: 289/289 web checks and 71/71 Python checks. The original player batch also passed 55/55 live-preview checks; those captures/checks were not rerun for the non-visual interruption-safety follow-up below. Flutter analysis, compilation, device audio and human listening are still unverified. Launch remains blocked.**

## User flow

1. Starting a curated/custom/saved mix, Shuffle, Home soundscape or a playable Sleep mix opens the full ambient player automatically. Unsupported browser recipes still go through the existing whole-recipe availability check; they do not partially start or replace the current audio.
2. The full player shows **each actual selected sound, its independent percentage and its current Playing / Preparing / Paused / Unavailable state**. Selection is not proof of playing audio. Failed layers remain visible at their selected level, with a same-source per-layer retry.
3. **Minimize** or browser Escape / native Back keeps audio running. The mini-player remains reachable on **all four tabs**, including while paused, loading or failed. Tapping its title/artwork opens this same full mix view without issuing a play/load/seek request.
4. Full-player sliders edit those actual mixer levels. They do not normalize to 100%, replace the underlying recording, rewrite the official recipe or undo an intentional minimize. Editing a user-paused mix in this view keeps it paused.
5. Pause/resume keeps the selection and ready source positions. The mini transport resumes in place without unexpectedly expanding. **Stop** dismisses the current playback view; a late event cannot revive stopped/canceled audio. Removing the final selected layer dismisses it too.
6. **Add sounds** minimizes and opens Sounds. **Save a separate mix** stores the current level map under a custom name, leaving the preset unchanged. The shared sleep auto-fade timer remains available and retains its existing fade/expiry behavior; it keeps counting while paused/minimized.
7. Starting a timed Meditate/nighttime practice switches presentation/audio ownership to that session. Starting an ambient mix pauses/cancels the timed session's playback request. Indefinite ambience has **no invented narrated-session progress, duration or completion**.

The ten exact recipes, 18 bundled recordings, 77 catalog entries, eight older presets, source identities/aliases, gain limiter, saved formats and preferred Sleep artwork/outline controls are retained. No recording, rendered arrangement, replacement network fallback, purchase lock or checkout was added.

## Browser interruption investigation

The independent preview previously used one looping `HTMLAudioElement` per layer. Before-state telemetry played **Enchanted Forest Morning for 67 seconds** with four fully downloaded local files:

- Four initial `waiting` events, followed by **eight runtime `waiting` / seeking / seeked cycles at loop boundaries**.
- Those measured wait-to-playing event intervals were approximately **4.5–10 ms**. Meadow Breeze's short loop repeated four times, Forest Birds twice, and the two 60-second layers once each.
- There were no pause/error events and all four players reported active at the end. Event timing identifies a loop-rebuffer path, **not proof of an audible gap or a complete diagnosis of the user's device**.
- A separate artificial **300 ms latency / 36,000 bytes-per-second shared download** run hit all four old ten-second deadlines: at 45 seconds it had four failures and no confirmed playing layers. That is controlled stress, not evidence of the user's connection.

### Implemented browser transport change

`design/preview/ambient-loop.js` decodes the **same configured local MP3** once and uses an `AudioBufferSourceNode` with `loop = true`. The audio clock, not a JavaScript restart timer, handles repeats. UI repaint, minimizing, reopening, a volume change and an unchanged healthy layer do not recreate its source node. A short gain ramp reduces abrupt control changes without changing displayed/saved percentages.

- Full-file decode deliberately trades initial download/decode latency and PCM memory for no media-element seek/rebuffer at each repeat. Each layer has truthful loading status and can be canceled before readiness.
- Downloads get a **20-second inactivity deadline**, renewed by real download progress, with a **three-minute absolute cap**. A slow progressing download is not failed merely because ten seconds passed. Failure/cancellation removes ownership and aborts the fetch; late decode results cannot start audio.
- Decoded PCM uses a **64 MiB soft cache budget**. Inactive buffers are evicted first; currently active sounds may exceed this budget and are never evicted to satisfy it. Paused players release their node/buffer reference and resume from the retained offset/cache when available.
- Audio-clock suspension is shown as paused, not Playing. Explicit Resume unlocks the retained nodes. A closed context fails retryably. These Chromium checks do not certify Safari/iOS interruption/background policy.
- Browsers without Web Audio retain a compatibility media-element path using the **same local file**. That fallback preserves player flow/source identity but does **not** inherit the decoded-node loop-continuity finding.
- The decorative mixer waveform now stops behind full players, on other tabs, offscreen, in a hidden document and under reduced motion. This is a resource safeguard, **not the evidence that audio continuity improved**.

### Measured after-state

Both real-clock runs used the existing live preview server and unmodified audio files; no virtual time or synthetic loop events were used in this measurement.

| Condition | Observed result |
| --- | --- |
| Same 67-second normal run, including minimize/reopen | Four startup waits, **zero runtime waits/seeks/pauses/errors**. Eight actual clock wraps observed: Breeze ×4, Birds ×2, Woodland Morning ×1, Mountain Stream ×1. **One unchanged source node per layer**, exactly four local-file requests; four active at the end. |
| Same artificial latency/bandwidth, observed for 90 seconds | **Zero failures/runtime rebuffer events**. At 45 seconds Breeze was playing and three layers were still honestly loading. First starts were approximately 28.0s / 67.7s / 75.3s / 75.4s; all four were active by the end. This is not an instant-start claim. |

These are **browser scheduling, identity, readiness and network-event findings**, not a recording of the physical output, a human listening pass, overnight stability proof or a fix certification for the Flutter/native transport. Content-inherent joins/repeats, platform suspension, Bluetooth routes and other causes can still need work. The unchanged recording boundaries still need the [human/device checklist](release/DEVICE_QA.md), especially ~13.8s breeze and ~15.7s cafe repetition.

Ignored diagnostics in this workspace: `build/ambient-stutter-before.{mjs,json}`, `build/ambient-stutter-after.{mjs,json}` and `/tmp/arena-ambient-stutter-{before,after}.log`. Temporary/build files may not persist in another environment; the checked-in regression tests are the reproducible engineering checks.

## Interruption-safe gain and timer follow-up

A subsequent local review reproduced **three unintended-resume cases** in Chromium before the fix:

1. Suspend the real Web Audio context, then change a full-player volume: the context incorrectly becomes running.
2. Suspend that context, then cancel auto-fade: the timer's gain update incorrectly resumes the loops.
3. In the same-file media-element compatibility path, pause one layer while others play, then edit another layer's gain: the paused layer incorrectly receives `play()`.

`syncAudio` now treats gain/timer/ducking refreshes separately from a transport command. It updates retained gains without resuming paused sources; explicit Play/mix starts opt into resume. A normal deliberate Sounds-slider start after a **user pause** retains its prior behavior, without undoing minimize. Full-player paused edits still never start audio. Pending loads keep their own readiness/cancellation fences. Retry continues to select only its failed original recording and leave other errors intact.

The corresponding native source adds a `resumePaused` intent to existing-player updates. Gain edits preserve requested levels after a platform pause without calling `play()`, and no longer reapply any failed selected layer. The new percentage remains available for explicit Play/Retry. This is source implementation, **not an observed native fix**.

Five new browser regressions cover the three reproduced cases, multiple retained failures and deliberate-start compatibility. A sixth source/configuration regression verifies that the new ambient part and its widget tests are actually listed in the pinned CI format command; the workflow was edited, **not triggered**. All **289/289** web checks pass. Seven more Dart cases (three controller, three fake-native audio, one widget) are authored/WASM-parsed but **unexecuted**. The complete player-related addition is now 22 unexecuted Dart cases, including the original 15.

All **115 protected hashes** for this narrow follow-up match: bundled media, catalog/recipes, theme, the Sleep screen, dependency files, launch register and unfilled device worksheet. No source recording, independent percentage, artwork, store identity or approval was changed. Current runtime fingerprint is **`3c95e71ae4b986ea90ff04f0c165b927743fe74156924038a70069a647fd9771`**; read-only preflight still exits **1 / BLOCKED** with **196** pending records/gates. The previous `90a04e…` fingerprint does not verify this candidate.

Diagnostics remain ignored/local: `/tmp/arena-ambient-edit-before.log` (three reproduced failures), `/tmp/arena-ambient-edit-focused.log`, `/tmp/arena-ambient-edit-all-web-final.log`, `/tmp/arena-ambient-edit-python-final.log`, and `build/ambient-edit-safety-preflight.json`. Checked-in tests are the portable regression evidence, not native/device execution. No new screenshots or physical-output listening claim is made by this non-visual follow-up.

## Flutter implementation and verification boundary

`AmbientPlayerOverlay` is a part of `guided_player.dart` so it reuses the existing photographic backdrop/artwork/glass/control components. It reads `MixerController.levels` and `AppState` readiness/errors/timer; it owns **no audio player or audio clock**. AppState tracks ambient presentation lifetime independently from active playback intent, so a pause no longer makes the mini-player disappear. `AppShell` shows the appropriate full player or the shared mini-player.

Intentional mix starts expand; retained-loop volume/state updates do not. The native transport remains the existing pooled `just_audio` players with `LoopMode.one`, fixed bundled-local retry identity and unchanged limiter/duck/fade behavior. **The browser decoded-loop change does not replace or establish gapless behavior for Flutter's native or compiled-web audio engine.**

The PWA visibility helper now tracks full-player owners, preventing disposal of a previous guided/ambient overlay from revealing Install over its replacement. Home and Sounds also reserve their existing guided-mini bottom clearance for ambient playback, so the newly persistent bar cannot cover the last scrollable actions. For the original full-player batch, **124 of 128 before-state protected hashes matched**. The only intentional protected-file changes are those two padding predicates and the native/web PWA visibility helper signatures/owner tracking; audio, artwork, catalog/recipe data, configured source bindings, launch review and the unfilled device worksheet are unchanged.

**The original 15 additional Dart regressions remain authored, not executed:** eleven overlay/widget/responsive/mini-clearance cases, three controller cases and one native fake-player source/ownership case. The prior pending-cancel mini assertion now expects a retained paused control rather than disappearance. Touched Dart files pass WASM formatting/parsing only; **there is no Flutter/Dart SDK in this sandbox**, so that is not type analysis or compilation. A fresh pinned-toolchain run and signed-device listening are still required.

## Executed checks and captures

- **289/289** current browser/PWA/source/configuration tests, no failures/skips. This includes the six interruption-safety/configuration additions above. The original 27 added cases cover actual decoding, exact layers/levels, all entry points/tabs, no autoplay, healthy source-node continuity, actual loop-boundary crossing, slow/stalled loading deadlines, late-result fencing, partial failure/retry, suspension/context closure, memory eviction, media-element compatibility, save, mode ownership, timers/fade, keyboard containment, 44px targets and five viewport shapes with 1.6× text and blocked fonts.
- **71/71** Python tests, no failures/skips. Media/provenance/recipe checks remain unchanged.
- **55/55** original-player checks (not rerun for the non-visual safety follow-up) against the existing port-3000 preview at 320 / 390 / 431 / 823 / 1440px; no page errors or player/layer overflow. Four exact layers/gains, automatic expansion, minimize/reopen identity, paused persistence and 44px targets checked.
- **20** CSS/JS content versions verified; JavaScript syntax and `git diff --check` pass. Existing mixer/availability tests now deliberately minimize before using background controls; none force-click through a modal or disable the new flow.
- Inspected actual independent HTML captures: [full ambient mix, 390 × 1100](../design/ambient-player-mobile-preview.png) and [minimized on Sleep, 390 × 844](../design/ambient-mini-player-mobile-preview.png). These are **not native screenshots**.

```sh
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
node tool/version_preview_assets.mjs --check
# Still required on the pinned Flutter toolchain:
flutter analyze --no-fatal-infos
flutter test
flutter build web --release
```

**The original player work was committed locally as `cd7abf3`; that is the earlier checkpoint, not this follow-up candidate. No push, hosted workflow, signing, publishing, spending or sales activation occurred for this follow-up.** The [launch-hardening evidence gate](LAUNCH_HARDENING.md) remains fail-closed with all rights/credential/native-build/device/human/owner requirements open. Earlier launch fingerprints or historical green CI do not verify this changed candidate.
