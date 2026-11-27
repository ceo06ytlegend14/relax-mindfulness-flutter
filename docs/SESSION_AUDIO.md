# Per-session ambient audio

Updated: 2026-11-19. **23 arrangements from 14 existing library recordings**, not 23 newly recorded works, spoken meditations or narrated stories.

## What changed

The repeated audio was a routing defect: Flutter tried `calm_guided.mp3` before every title-specific URL, and the independent HTML player always opened that same file. Clearing a cache could not fix that wiring.

- The daily practice plus 14 Meditate practices and eight **Nighttime Journeys** each have one explicit, local arrangement. **Home and Meditate intentionally share Calm Mountain Horizon**, because they are the same practice.
- Cards and the expanded player display the actual ingredient names. Fictional narrator metadata is removed; old `story-*` favorite IDs remain so saved journeys are preserved.
- Each arrangement is approximately **30 seconds**, repeating for the displayed session duration while Loop is on. Turning Loop off stops at the end of that short recording, not after a full-length narrated work. Both behaviors are disclosed in the player.
- Missing, corrupt or unknown content produces an error, **never an unrelated shared sample or remote fallback**. Retry loads the same arrangement and restores elapsed source position. The old universal MP3 is unreferenced by playback but still present in the asset directory; it has not acquired a rights grant.
- Pause/resume, seek ±10 seconds, scrubbing, loop, extend, restart, minimize, cancellation, replacement/exclusivity and real countdown states remain. The browser uses one active arrangement element at a time and fences late events from discarded media; Flutter retains its single `just_audio` transport and request guards. The existing Sounds mixer and five Sleep quick controls keep their own bindings.

Titles/artwork remain creative themes. In particular, **Healing Crystal Chimes uses Bamboo Chimes + Temple Bowl, not a crystal recording**, and **Chakra Solfeggio Alignment uses Temple Bowl + Brown Noise, not verified frequency-tuned audio**. The descriptions identify this; no therapeutic, frequency or recording-location claim follows from a title.

## The arrangements

Weights below are pre-render mixing coefficients after source normalization, not the player's volume slider or a guarantee of perceived loudness.

| Practice / journey | Actual ingredients and mixing weights | Bundled output |
| --- | --- | --- |
| Calm Mountain Horizon | Mountain Stream 72% + Meadow Breeze 28% | `session_calm_mountain.mp3` |
| Gentle Relief & Comfort | Bamboo Chimes 65% + Soft Rain 35% | `session_gentle_relief.mp3` |
| Soft Body Rest & Ease | Ocean Waves 60% + Pink Noise 40% | `session_body_rest.mp3` |
| Peaceful Morning Awakening | Woodland Morning 80% + Meadow Breeze 20% | `session_morning_awakening.mp3` |
| Quiet Mind Sanctuary | Temple Bowl 65% + Mountain Stream 35% | `session_quiet_mind.mp3` |
| Cozy Bedtime Slumber | Soft Rain 75% + Fireplace 25% | `session_bedtime_slumber.mp3` |
| Healing Crystal Chimes | Bamboo Chimes 70% + Temple Bowl 30% | `session_crystal_chimes.mp3` |
| Warm Heart Comfort | Fireplace 65% + Brown Noise 35% | `session_warm_heart.mp3` |
| Peaceful Haven Journey | Mountain Stream 70% + Forest Birds 30% | `session_peaceful_haven.mp3` |
| Gentle Breeze Rest | Meadow Breeze 70% + Bamboo Chimes 30% | `session_breeze_rest.mp3` |
| Loving Warmth & Peace | Campfire 65% + Ocean Waves 35% | `session_loving_warmth.mp3` |
| Ocean Horizon Slumber | Ocean Waves 55% + Crickets 45% | `session_ocean_horizon.mp3` |
| Chakra Solfeggio Alignment | Temple Bowl 80% + Brown Noise 20% | `session_solfeggio.mp3` |
| Pine Forest Bathing | Forest Birds 65% + Meadow Breeze 35% | `session_forest_bathing.mp3` |
| Release Anxious Tension | Soft Rain 65% + Temple Bowl 35% | `session_release_tension.mp3` |
| The Starry Night | Crickets 80% + Brown Noise 20% | `session_starry_night.mp3` |
| Journey to Dreamland | Ocean Waves 65% + Bamboo Chimes 35% | `session_dreamland.mp3` |
| The Hidden Waterfall | Mountain Stream 65% + Pink Noise 35% | `session_hidden_waterfall.mp3` |
| The Lighthouse Keeper | Ocean Waves 55% + Boat Deck 45% | `session_lighthouse.mp3` |
| Moonlit Japanese Garden | Bamboo Chimes 45% + Mountain Stream 55% | `session_japanese_garden.mp3` |
| Whispering Pine Forest | Meadow Breeze 60% + Crickets 40% | `session_whispering_pines.mp3` |
| Desert Stargazing | Meadow Breeze 65% + Brown Noise 35% | `session_stargazing.mp3` |
| Ancient Temple Bells | Temple Bowl 75% + Crickets 25% | `session_temple_bells.mp3` |

The [manifest](../assets/sounds/session_soundscapes.json) is the recipe/source/hash authority. Generated [Dart metadata](../lib/models/session_soundscapes.dart) and [browser metadata](../design/preview/session-audio.js) provide the same routes and labels. Unknown titles have no default. Only the explicitly listed legacy names `Peaceful Morning Start` and `Soft Sanctuary Horizon` are aliased.

## Rendering and measured checks

`tool/prepare_session_soundscapes.py` operates only on existing local bytes; it downloads nothing and creates no new rights grant. It normalizes each source, combines two contributing layers, makes a one-second end/head crossfade with rotation, and encodes 44.1 kHz stereo MP3 at 96 kbps. Source targets are −26 LUFS / −8 dBTP; arrangement targets are −24 LUFS / −6 dBTP. These targets are distinct from measured final-file values.

Executed on the final **23 files / 8,297,328 bytes**:

- Exact input/output hashes and full decoding passed; decoded mono durations are approximately 29.95–30.00 seconds. All 23 output files and decoded PCM identities differ, and every recipe uses a different pair of original recordings.
- FFmpeg's full-bandwidth stereo measurement of the final encoded files reported **−25.10 to −23.87 LUFS integrated** and **−14.26 to −6.20 dBTP**. Playback retains the existing **0.35 gain**. These are file-level checks, not a guarantee of device/headphone loudness or comfort.
- All **253 phase-aligned comparison pairs** passed the similarity regression guard (<0.97 absolute correlation). Maximum observed: **0.929719**. This uses 8 kHz mono PCM sampled every eighth sample; it is an engineering regression guard, **not a perceptual-distance measure or proof of human-audible differentiation**.
- A separate scratch rebuild reproduced all 23 pinned file hashes with the recorded encoder. Different FFmpeg/LAME builds can produce different bytes.
- **202/202 browser/PWA/source/configuration tests** and **41/41 Python tests** passed, zero failures/skips. Chromium actually played all 23 selected session assets as well as all 18 chooser recordings. The later [ten live mixer sets](SOUND_LIBRARY.md#ten-one-tap-vibe-sets) add 22 browser/source cases; they do not alter this manifest, these session routes or any audio bytes. Coverage includes exact selected-file requests/labels, Home/Med identity, no fallback, real loading failure and retry, retained-time seeking, late old media events and existing transport/Sleep/PWA safeguards.
- The live HTML server was checked at 320/390/431/823px with actual Meditate and nighttime playback, 0.35 gain, the expected sources and no page errors or player overflow. The original player/cards/nighttime captures remain in [pre-cleanup Git history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design), not the current tree. They are historical independent HTML, **not Flutter/device evidence**; the [current four-tab gallery](../design/README.md) is separate.

A **human listening pass**, seam/repetition review and real iOS/Android interruption/background/routing tests remain open. The new native regressions were authored and changed Dart files passed WASM parsing/formatting only; **no current Flutter analysis, tests or native/web builds ran in this sandbox**. The [native ambient readiness follow-up](PROJECT_GOALS.md#native-ambient-readiness-follow-up--source-implemented-execution-open) adds separate requested/ready state and per-layer retry in source, with 29 additional native cases awaiting execution; it does not change these session arrangements or audio bytes. Installed native apps need a separately rebuilt/installed version; updating the HTML preview does not update them.

## Provenance and release boundary

All ingredients preserve their existing credit, exact source hash, evidence path and unresolved/evidence-only rights status in the manifest. See the [library inventory](SOUND_LIBRARY.md#existing-bundled-bytes-unchanged) and [recording-specific source-page evidence](audio-licenses/ambient-pack-2026-11-19.md). Six legacy sources still need owner provenance review. The documented new-source grants, including wood-thrush Content ID concerns, are evidence **not release clearance or a claim-free warranty**. Mixing/re-encoding does not clear any input or assign its copyright to this project. No new third-party media, voices or music service was acquired for these arrangements.

## Reproduce

```sh
# Offline recipes, source/output hashes and renderer safety guards:
python3 -m unittest discover -s tool -p 'test_*.py' -v
# Fully decode/measure all outputs and check pairwise regression:
python3 tool/prepare_session_soundscapes.py --verify --ffmpeg /path/to/ffmpeg \
  --report build/session-audio-qc.json
# Rebuild into ignored scratch storage, verifying pinned output hashes:
python3 tool/prepare_session_soundscapes.py --ffmpeg /path/to/ffmpeg
# Deliberately replace bundled arrangements AND update measured hashes/catalogs:
python3 tool/prepare_session_soundscapes.py --ffmpeg /path/to/ffmpeg \
  --output-dir assets/sounds --update-manifest
# Routing-only changes (never changes audio):
python3 tool/prepare_session_soundscapes.py --write-catalogs
# After any preview CSS/JS/catalog change:
node tool/version_preview_assets.mjs
node tool/version_preview_assets.mjs --check
npm run test:web
```

Default rendering writes only `build/rebuilt-session-soundscapes/`. Bundled replacement requires **both** explicit flags; all renders/checks finish in scratch before any shipped output is copied. Raw scratch/WAVs and QC reports stay in ignored `build/`. If changing recipe coefficients, rerender/review the MP3s rather than merely regenerating routing labels, and keep provenance and release evidence separate.
