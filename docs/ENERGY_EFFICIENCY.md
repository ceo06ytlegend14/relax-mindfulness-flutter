# Long-session energy efficiency

**Goal:** avoid unnecessary CPU/GPU, audio-rendering and UI work during long listening sessions. This is not a promise that any phone will stay cold. Hardware, OS restrictions, charging, brightness, network conditions and room temperature matter.

## What this pass changes

### Flutter app

- The outer tab/player shell selects structural state instead of rebuilding for every countdown, gain or unrelated notification. Individual controls still receive their real updates.
- Decorative tickers stop when the app is inactive/hidden/paused. The covered tab stack also stops ticking behind an expanded player or mood dialog. Audio remains owned by `AppState`, not by a visible widget.
- Both player artwork animations honor background state, `TickerMode` and accessibility settings. Artwork has its own repaint boundary so its pulse need not repaint the entire player.
- A playing guided session uses one background deadline wake instead of a one-second background UI heartbeat. Foreground countdowns remain live. Pause, seek, extension and return to foreground replace/reconcile that wake.
- Sleep shutdown now uses an absolute deadline, not the number of timer callbacks delivered. In the background it waits until the final 30-second fade, then updates gain without rebuilding the UI each second. Late callbacks/foreground resume reconcile the actual remaining time. Replacement, cancellation and expiry clear timer ownership before asynchronous audio shutdown. A sleep deadline never invents listened minutes or a completed session.

### Independent browser preview

- No permanent 250 ms breathing poll or one-second idle session poll. Only an active breathing practice or a real sleep/guided deadline schedules a clock. Breathing updates at the displayed second and stops on pause, completion or leaving/hiding the page.
- Timer ticks update time-dependent controls, not all playback cards, artwork rows, practice buttons and Home. Hidden countdowns wait for their deadline/fade instead of refreshing invisible DOM.
- An empty Web Audio graph suspends after a one-second mix-switch grace. Pausing one layer cannot suspend other active/pending layers. Gain edits cannot postpone idle suspension indefinitely. Explicit Play/Resume unlocks the graph; visibility or gain changes do not auto-resume interrupted audio.
- Player rings stop when their dialog is minimized or the page is hidden. Existing reduced-motion, waveform offscreen/tab/dialog and source-ownership guards remain.

There is **no** new audio encoding, recording, quality reduction, shortened session, mix-level normalization, layer cap, analytics poll or background-audio disable. All 96 declared bundled inputs remain byte-identical. Existing decoded-buffer reuse, bounded PCM caching and active-source retention are preserved. Cache sizes are not arbitrarily reduced: repeated decoding or evicting a live loop could cost more energy and break playback, so further cache changes need device profiling.

## Evidence and limits

Local engineering measurements compare base `c92093ca94f35a34205579f0decf26716e80e39f` with this pass in **desktop headless Chromium**, not on an iPhone/Android phone:

| Real-clock observation | Before | After |
| --- | --- | --- |
| Recurring `setInterval` callbacks during 12 idle seconds | 60 (1 s + 250 ms heartbeat) | 0 |
| Recurring `setInterval` callbacks during a 50-second, four-layer session with no deadline | 251 in this sample | 0 |
| Web Audio context after all ambience is paused and the idle grace has elapsed | Running | Suspended |
| Healthy players/source nodes during 50-second playback | Retained | Retained |
| New audio requests during that steady-playback window | 0 | 0 |
| Natural Forest Birds 24-second wraps, same node | 2 | 2 |

These are specific application-scheduling/source-retention counters. **They do not establish a CPU percentage, battery saving, temperature decrease, seamless human listening verdict or overnight/device clearance.** Native audio decoders and OS background execution are different from the independent HTML preview. The real-clock sample is only 50 seconds; automated virtual-clock deadline tests are not sustained listening tests.

A same-page, fixed-time before/after visual comparison passed 24 responsive layout/target checks. Sounds, Meditate and Sleep were pixel-identical; Home differed at four antialiased rounded-edge pixels (maximum channel delta 4/255). An earlier uncontrolled comparison also showed tiny blur-edge differences. This is not a claim of an all-screen zero-pixel match. No stylesheet, artwork or layout specification was changed by this pass.

Reproduction/engineering evidence is generated under ignored `build/thermal-pass/`; it is not a shipped dependency. Persistent browser regressions are in `test/web/energy_efficiency_browser_test.mjs`; native deadline, shell and lifecycle regressions are in the existing ambient/guided state/player test files. Run `npm run test:web` and the configured Flutter/native quality workflow on the exact candidate. A prior revision's green checks do not validate this one.

## Required physical-device check — NOT RUN

Use the actual signed, rights-reviewed private test candidate and the existing [device checklist](release/DEVICE_QA.md). No signing, store upload, release, purchases or distribution is approved by this document. The owner currently has an iPhone only; its exact model and iOS version still need recording. Do not substitute unsigned CI compilation for installing/testing it.

1. **Record the candidate and conditions.** Git revision, app version/build, exact phone/OS, battery health if available, battery start %, room conditions, charging state, brightness, volume/output route, network and Low Power Mode. Use comfortable listening levels. Remove unrelated heavy workloads; keep conditions consistent between comparisons.
2. **Compare the same phone before/after.** Let initial downloads/decode settle. Prefer an unplugged, fixed-brightness comparison; charging is a separate scenario. Do not deliberately heat the phone. Run a static idle screen, then the exact same one-layer and four-layer bundled mixes for at least 30 minutes each. Record battery end %, elapsed real time, perceived warmth, stutters, audible joins and any OS warning/dimming. Repeat comparable runs before drawing a battery conclusion; battery % alone is coarse.
3. **Lock-screen long listening.** Run the same mix locked for at least 30 minutes, then a longer overnight-style check when safe/practical. Confirm uninterrupted intended audio, unchanged selected levels, no duplicate sources, accurate resume and no surprise autoplay. Test interrupted/failed network sources separately from bundled audio.
4. **Timers and mode changes.** Run real 1-minute and 30+-minute sleep timers, including screen lock, pause, cancellation, replacement and return after expiry. Confirm final fade and shutdown, no revived pending load and no fabricated completion. Repeat guided pause/resume, seek/extend and switching between session and ambient modes.
5. **Inspect actual platform energy behavior when engineering tools are available.** On iOS use a profile/release build and Instruments/Xcode energy/CPU/GPU diagnostics; on Android use a profile/release build and the platform profiler/Perfetto/thermal diagnostics. Check that locked-screen decorative frames and idle clock wakeups cease. Device thermal state is not a fabricated temperature reading. Save real traces and compare the same candidate/conditions.

**Stop the test** for an OS temperature warning, unexpected severe warmth, performance collapse or unsafe behavior. Let the device cool normally and record the failure; do not mark a pass based on a short browser run. Do not promise “never hot” or a battery-life number before these measurements.

**Current physical-device outcome: NOT RUN.** All release/listening/rights gates and purchase restrictions remain in force.
