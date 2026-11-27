# Signed-candidate device and listening checklist — NOT RUN

This is an **unfilled worksheet**, not test evidence or release permission. Every checkbox starts open. Run it on the actual signed candidate on real Android and iOS hardware after rights/credential/native-build review. Browser automation, decoded durations, screenshots, unsigned builds and WASM parsing cannot fill these boxes. Record failures honestly; stop beta preparation on any blocker. No accounts, purchases, signing, uploads or public launch are authorized by this document.

## Candidate and people

| Field | Actual value — leave unfilled until known |
| --- | --- |
| Tester(s) and date/timezone | Pending |
| Owner approval for private testing method/audience | Pending |
| Git revision and dirty-tree state / source snapshot | Pending |
| `launch_preflight.py` runtime candidate SHA-256 | Pending |
| Version/build number and signed APK/IPA SHA-256 | Pending |
| Flutter/toolchain/native quality job evidence | Pending |
| Android model / OS / security patch / audio accessories | Pending |
| iPhone/iPad model / iOS version / audio accessories | Pending |
| Network conditions / battery settings / output volume | Pending |
| Existing install/customer upgrade path and test backup | Pending |

Use safe, comfortable listening levels. Software slider percentages/master limiting are not a measured headphone SPL or a safety guarantee. Do not normalize the supplied recipe percentages to 100%.

## Core tasks — run separately on each platform

Record a non-sensitive evidence file per platform with build/device/OS, steps, expected result, actual result and defects. The matrix stays **not run** until a human actually executes it.

| Task | Expected behavior / evidence to capture | Android | iOS |
| --- | --- | --- | --- |
| Cold install and relaunch | No autoplay or fabricated listening history. Four tabs work; default Sounds shows 18 canonical bundled sources. | Not run | Not run |
| Catalog review | Expanding review only explains inventory; explicit Full catalog shows 77 stable entries with honest source labels. Closing/Available returns to 18. No audio/levels/favorites/saved data change. | Not run | Not run |
| All ten presets | Exact names, purposes and independent percentages; unrelated tracks off immediately. Sliders remain editable. Separate custom Save survives restart; official preset unchanged. | Not run | Not run |
| Pause, stop, resume, cancel | Accurate loading/buffering/playing state; pending loads cancel; a late load cannot revive audio. Resume retains selected levels. No duplicate loops/player multiplication. | Not run | Not run |
| Replacement and eight-second preview | Explicit preview only; close/timeout/cancel/error restores mix gain. Use keeps other levels and a paused mix paused; duplicate aliases do not stack. | Not run | Not run |
| Bundled-only/offline | All eighteen bundled sources and all ten presets play without network. A deliberately failed fixture asset reports a retryable failure and never requests another remote recording. Use a diagnostic build for failure injection, then repeat normal checks on the unmodified signed candidate. | Not run | Not run |
| Legacy streams / failures | After separate rights/pinning review, test exact configured streams, slow/offline/failing network, retry and cancellation. No unrelated replacement; healthy loops stay intact; errors name unavailable layers honestly. Sleep Wind/Thunder are stream bindings, not new bundled clips. | Not run | Not run |
| Background and lock | Play multiple layers, switch apps and lock for 20+ minutes, then return. Record actual OS restrictions, audio continuity, pending cancellation and truthful UI/countdown. Never infer this from foreground browser tests. | Not run | Not run |
| Calls, alarms, other media | Trigger real interruptions/ducking and competing audio. Confirm an explicit documented pause/resume policy, no unexpected restart, stuck ducking or sudden level jump. | Not run | Not run |
| Headphone/Bluetooth routes | Wired/Bluetooth connect/disconnect, route change, volume buttons and speaker transition. Check no loud unexpected speaker playback or stale glow/state. | Not run | Not run |
| Timer/fade | Use real-clock 1-minute and 30+-minute timers, including background/lock, pause/cancel/change. Check final fade, stop at expiry, no surprise resume, accurate remaining time and no invented completion/session history. | Not run | Not run |
| Mode ownership | Ambient → timed practice/journey → ambient; rapid switching and Home/Med daily practice reuse. Only the current request owns playback; minimized transport stays truthful. | Not run | Not run |
| Long listening | 30+ minutes per platform, and a longer overnight-style candidate session when safe/practical. Note loop clicks, drift, heat/battery, leaks, interruptions and stops; do not fake a passed duration. | Not run | Not run |
| Saved/legacy data and upgrade | Existing saved/favorite/share/backup identities survive signed install/upgrade; non-bundled selections remain recoverable. Confirm iOS/Android store identity history before any rename. | Not run | Not run |
| Backup and privacy | Export, canceled import, malformed import, staged review and confirmed replacement on test data. Check failure behavior, clipboard/local storage disclosures and no entitlement/credential transfer. | Not run | Not run |
| Reminders | Actual OS permission denied/granted, schedule/cancel, restart, timezone/DST where relevant. A saved preference is not notification delivery evidence. | Not run | Not run |
| Accessibility/navigation | Small display, larger text, screen reader (TalkBack/VoiceOver), focus, labels and 44px targets; every public action reaches a supported destination. No accidental demo/admin exposure. | Not run | Not run |
| Purchases off | New checkout remains disabled in the built candidate. Existing access/restore is not simulated. Any later sales enablement requires separate owner approval and both-store sandbox testing. | Not run | Not run |

An automated failure-injection result does not substitute for a clean, unmodified signed release test. Unsigned compilation, static library alignment and fake audio players are separate engineering evidence.

For long-session heat/battery comparisons, follow the [energy-efficiency protocol](../ENERGY_EFFICIENCY.md#required-physical-device-check--not-run): record exact hardware/OS, candidate, duration, brightness, charging/network/output conditions and before/after battery observations. Browser scheduling counters are not phone-temperature or battery-life evidence. **These device checks remain not run.**

## Human mix listening — all ten required

Play each official recipe for **at least five minutes and at least three complete wraps of every ingredient**, then try pause/resume and volume/fade changes. Listen on speakers and comfortable headphones; record perceived balance, identifiable ingredients, repeats/clicks, harshness and any masking. Source files loop independently; there is no fixed mix ending. Longer listening is still needed above.

| Exact mix | Speaker pass | Headphone pass | Joins/balance/notes |
| --- | --- | --- | --- |
| Rainy Window Café | Not run | Not run | Pay particular attention to ~15.7s Coffee Shop repetition. |
| Enchanted Forest Morning | Not run | Not run | Check ~13.8s Meadow Breeze and bird layers. |
| Ocean Deep Sleep | Not run | Not run | Check ocean/crickets/noise balance and fade. |
| Mountain Meditation | Not run | Not run | Check bowl transients and breeze joins. |
| Cozy Fireplace Night | Not run | Not run | Check fireplace/rain/crickets repetition. |
| Tropical Rainforest | Not run | Not run | Check independent stream/rain/bird loops. |
| Zen Temple Sanctuary | Not run | Not run | Check bowl/chime transients at the actual requested levels. |
| Midnight Focus | Not run | Not run | Check broadband noise mix and short cafe repeat. |
| Campfire Under Stars | Not run | Not run | Check fire/crickets/breeze/ocean balance. |
| Peaceful Ocean Journey | Not run | Not run | Check boat-deck/ocean/breeze/chime joins. |

Use the [exact recipe contract](../CURATED_SOUND_MIXES.md) and [all 77 source-loop lengths/statuses](../SOUND_DURATIONS.md). Do not invent replacement recordings, different source identities or longer files to tick a box. If a human finds a quality defect, record it and propose a rights-cleared, explicitly reviewed fix before changing audio.

## Failure and exit record

- [ ] Every failure has a reproducible issue, actual result, candidate/device context and disposition. Do not paste personal call data or credentials into issues.
- [ ] Critical fixes have fresh native builds and repeated affected/full regressions; earlier candidate evidence is not carried forward automatically.
- [ ] Rights/claims, historical credential incident, legal/support disclosures, identity/signing and all nine [evidence gates](launch-review.json) have genuine owner/tester records. This worksheet alone clears none of them.
- [ ] Owner chooses the exact **small invited beta** candidate, audience, distribution and rollback. Purchases remain off. This is **not public-launch permission**.

**Current outcome: NOT RUN / BLOCKED.** Replace this only with an honest dated result from the actual candidate; keep history of failures and retests.
