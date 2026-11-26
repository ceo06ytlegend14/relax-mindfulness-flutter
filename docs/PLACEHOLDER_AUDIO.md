# Temporary development audio and repaired loop joins

Updated: 2026-11-19. **Development placeholders are not release clearance.** The owner accepted temporary audio while the intended library is sourced. No third-party video was downloaded, no new permission was inferred, and launch/purchases remain disabled.

## Scope and recording target

The agreed target is **three genuinely different recordings for each of the 18 available sound cards: 54 total choices**. Retaining an existing recording counts only if it later passes the rights and listening review. A loop edit, alias, re-encode, time stretch, pitch shift or session mix is **not another recording**. No #2/#3 choices have been fabricated by this repair.

The six older mixer recordings are retained as original inputs. Their redistribution provenance is unresolved. `assets/sounds/placeholder_loops.json` identifies a separate `loop_*.mp3` derivative of each, including exact input/output hashes, the overlap, actual decoded duration and processing. The original six files and all 23 existing session arrangements remain untouched. The twelve more recent mixer files also remain untouched.

The mixer and its eight-second recording auditions route to these six loop edits in both Flutter source and the independent HTML preview. Names, aliases, covers, 18 source identities, 77 catalog cards, ten exact recipes, independent percentages and saved/share/backup formats remain the same. The 23 Meditate/Sleep arrangements still use their original input provenance and audio; this repair does not claim they were re-rendered or improved.

Six extra distributed derivatives mean **48 audio files in the bundle inventory**, not 24 unique mixer recordings or 54 completed choices. Both the originals and their derivatives remain individually pending in the release register. Temporary use does not clear rights, certify listening or authorize distribution.

## Join preparation

1. Decode the same original recording at 44.1 kHz, stereo; do not fetch or substitute another source.
2. Overlap its final 3–6 seconds with its opening using equal-power crossfade curves. Rotate past the consumed opening so the wrap meets adjacent source samples, instead of restarting an unrelated intro. Do **not** fade the whole clip to silence at every repeat.
3. Apply only a **constant attenuation** if needed for overlap/codec headroom. A time-varying normalizer after the edit could unmatch the endpoints. Mixer slider values and the existing limiter, preview duck and sleep fade are unchanged.
4. Export 128 kbps MP3 with Xing gapless metadata and measure the entire encoded result. The static gain targets −6 dBTP and the encoded guard is ≤ −5.5 dBTP. This is digital headroom, not a hearing-safety or pleasing-volume guarantee.
5. Use the existing looping transports. No extra players, timer-driven restarts or background crossfade scheduler were added.

Overlap consumes time: the **30-second placeholders become 24–27-second loops**, not longer or less-repetitive master recordings. This is a join repair while longer content is acquired. The target for the replacement masters is roughly **3–5 minutes of genuinely varied material per take**, subject to listening and download/memory review; repeating a short file into a longer container does not meet it.

### Audit that motivated this change

A Chromium full decode of the existing 18 chooser sources found the Forest Birds opening two seconds at about **−14.4 dBFS RMS** in the left channel versus **−24.3 dBFS RMS** in the ending two seconds. This is a signal-level comparison, not a perceptual loudness measurement. The existing Ocean Waves, Campfire and Bamboo Chimes also had large last-to-first sample jumps relative to their whole-file RMS adjacent-sample step. These observations help explain a conspicuous restart, but are not a diagnosis of every device or a human listening result.

The previous decoded-node browser fix addressed repeat-time seek/rebuffer events; it could not repair a discontinuity already present inside the audio. This preparation addresses that separate content problem.

## Reproduce safely

Requires FFmpeg with `libmp3lame`. It is a developer tool, not an app/runtime dependency. No paid service, login, external download or production permission is needed for the transformation of the existing repository inputs.

```sh
# Exact input/output hashes, recipe binding and unresolved-rights safeguards:
python3 tool/prepare_placeholder_loops.py --verify
# Also fully decode and inspect the final six files:
python3 tool/prepare_placeholder_loops.py --verify --ffmpeg /path/to/ffmpeg \
  --report build/placeholder-loop-qc.json
# Prepare into ignored scratch storage without changing routing or the manifest:
python3 tool/prepare_placeholder_loops.py --ffmpeg /path/to/ffmpeg
# Deliberate bundled-derivative replacement requires BOTH flags:
python3 tool/prepare_placeholder_loops.py --ffmpeg /path/to/ffmpeg \
  --output-dir assets/sounds --update-manifest
```

The command refuses changed source bytes, output paths that could overwrite an original, fake extra recordings, rights upgrades, unbounded overlaps and accidental bundled writes. All renders are staged and inspected before output copying. Original masters, scratch WAVs and technical reports are never added as generated build artifacts. Different FFmpeg builds can encode different bytes; a deliberate reviewed rebuild must update its output/recipe hashes and pending release inventory, never an approval flag.

## Executed checks for this repair

- **322/322 web/browser/PWA/catalog/configuration tests** and **93/93 Python tests** pass, with no failures/skips. Six new playback cases fully decode the originals and prepared files, render the actual prepared PCM across its wrap, and observe a real unchanged-node crossing. Four new offline guards cover hashes/routing/aliases/pending reviews; 18 Python cases cover recipe and safe-rebuild behavior.
- The six final encoded files pass full decode, exact duration and digital headroom inspection (**−6.41 to −9.8 dBTP**); output/source/recipe hashes are recorded in the manifest. These checks cannot tell whether the result is relaxing or natural.
- A fresh **49-second real-clock** Forest Birds run on the reused port-3000 preview observed **two natural 24-second wraps**, one request, one unchanged source node, no runtime wait/seek/pause/end/error events, 30% retained and the Sounds mini-player still visible. No seek, virtual clock or synthetic media events were used in that run. This is scheduling evidence, not a recording of physical output.
- One additional native manifest/routing case is authored; existing fake-native source/retry expectations now use the prepared file paths. All three touched Dart files pass WASM parsing/formatting, but **no Flutter analysis, native tests or compiled builds ran**.
- Preflight remains **BLOCKED / 202 pending**: 118 local rights reviews, 75 stream reviews and nine gates. All original review entries/gates remain intact; the six new derivative entries are pending. Purchases stay off.

| Recording identity | Original input | Prepared loop | Overlap | Constant gain |
| --- | ---: | ---: | ---: | ---: |
| Soft Rain | 30s | 27s | 3s | -2.59 dB |
| Ocean Waves | 30s | 26s | 4s | 0 dB |
| Forest Birds | 30s | 24s | 6s | -2.94 dB |
| Campfire | 30s | 26s | 4s | -5.56 dB |
| Bamboo Chimes | 30s | 27s | 3s | 0 dB |
| Temple Bowl | 30s | 26s | 4s | -4.64 dB |

Ignored local diagnostics: `build/loop-joins/{source-audit,render-result,full-audio-qc,live-repeat-result,preflight}.json`, `routing-before.log`, `focused-browser.log`, `full-web-tests.log` and `python-tests.log`. They are scratch evidence, not durable approvals. The checked-in tests and exact manifest are the portable reproduction path.

## What still needs validation before release

- A human must listen at low device volume, then check at least ten joins per recording, intrusive calls/crackles, repetition, long mixes, silence, loudness dips/surges and fatigue. Numerical continuity does not establish pleasant or natural audio.
- Rebuild and run the Flutter app. No Flutter/Dart SDK is installed in this sandbox. Both source maps reference the same prepared files, but native compilation, decoder padding, iOS/Android repeat gaps, interruption/background/lock-screen/Bluetooth behavior and device listening remain unverified.
- The HTML media-element compatibility path shares the prepared file but does not inherit the Web Audio node's scheduling guarantee. Safari and physical output still need checks.
- Source and review the 54 intended choices. For third-party video references, obtain the creator's original downloadable audio and the applicable app-redistribution grant. Public availability or temporary use is not a substitute for permission.
- Keep every source receipt, acquisition/generation details, original/output checksum and required attribution. Resolve the older recordings' provenance or replace them. No paid generation, store submission, signing, release approval or purchase activation is authorized by this work.

[Sound library](SOUND_LIBRARY.md) · [Ambient player and native boundary](AMBIENT_PLAYER.md) · [Launch hardening](LAUNCH_HARDENING.md)
