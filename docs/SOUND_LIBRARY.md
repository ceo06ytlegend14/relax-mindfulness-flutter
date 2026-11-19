# Sound library: scope, source audit and release boundary

Updated: 2026-11-19. **No new audio download, pack, recording take, personal-file import, entitlement or purchase was added.**

## Product choice

- Every one of the **75 familiar sound cards** now has a bundled decorative cover, not a mixture of photographs and emoji placeholders. Covers can be shared and do not prove audio availability. [Artwork provenance](../assets/images/mixer/README.md).
- **Card → ⋯ → Replace sound** opens a small library of **six existing bundled recordings**. This replaces one layer with a different named sound; it is deliberately **not called “Choose recording”** or sold as alternate takes of that sound. New same-sound variants and packs remain deferred until distinct recordings and redistribution rights are documented.
- Opening or selecting a row never autoplays or changes the mix. **Preview** is explicit, quiet and limited to eight seconds. A playing ambient mix is temporarily ducked; a paused mix stays paused. Stopping, closing, leaving the foreground, failure, timeout or using a choice disposes the preview and restores ambient gain. Late loads cannot restart a canceled preview.
- **Use sound** keeps that layer's volume and other layers. An off card selects the new layer at 30%; it does not start a paused mix. The new category is shown so the chosen card is visible. Already-selected targets and aliases using the same bundled clip are unavailable as duplicates.
- Saves, cached selections, share links and backups store the resulting **real sound name and level** through the existing format. There is no invisible audio override or new backup schema. To go back, replace the new card with the original available sound. Normal card/switch taps and long-press Favorites remain; the **Home / Sounds / Meditate / Sleep** footer is unchanged.

## Highest-value remaining work

| Priority / source | Finding and required action |
| --- | --- |
| P0 — audio rights / `assets/sounds/` | Six ambient MP3s and the separate session sample were already in the initial repository. No per-file author/license receipt was found. Existing bytes are unchanged; owner must obtain provenance/redistribution permission or replace them before public distribution. Successful decoding is not rights clearance. |
| P0 — catalog / `lib/providers/app_state.dart` | **35 of 75 card names have a configured source: six bundled-first and 29 stream-only; 40 have no configured recording.** This is a configuration count, not 35 unique or cleared recordings. Retain the cards and mark them as needing a recording. Missing names now fail visibly instead of silently playing unrelated heavy rain. Source-load/play failures remove the failed active layer and offer retry/replacement. |
| P0 — external recordings | Moodist's code license does **not** license its audio. The upstream README says audio uses Pixabay Content License or CC0, without per-file license/author evidence in the inspected category records. Do not add these as newly cleared takes or packs. Audit each original audio source and applicable license, including the existing Google-hosted OGG URLs. |
| P0 — legacy source labels | The incorrect `Ambient Piano` → singing-bowl URL was removed. Old presets/backups can retain that name, but it is now explicitly unconfigured, not a purported piano. Other shared-source aliases are listed below; do not advertise their count as new recordings. Recordings, frequency claims and health/marketing copy need owner review. |
| P0 — compiled-device audio | Automated doubles/browser playback do not prove real iOS/Android routing, interruptions, focus, background behavior, lock screen, sleep fade, output loudness or long-running loops. Signed-device tests remain a release gate. |

### Existing bundled bytes (unchanged)

The chooser lists one name per distinct ambient clip. Legacy aliases are not extra recordings. These hashes record identity, **not origin or a license**.

| Chooser name | Existing file | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Soft Rain | `assets/sounds/soft_rain.mp3` | 538,748 | `9f40e761012c8259e142f6825eb802976850863ee99e4e6f0d2e040f8f9d9833` |
| Ocean Waves | `assets/sounds/ocean_waves.mp3` | 834,956 | `69769264ab133e22ed916553794af4ae14e183227f556e7cb9dca6148c973d8c` |
| Forest Birds | `assets/sounds/forest_birds.mp3` | 582,476 | `67e5e2bb7c94d6dd58a505f62dfc9ad3a3f5c590bddf3229b532acc3410c75bc` |
| Campfire | `assets/sounds/campfire.mp3` | 1,010,636 | `e39ffb4d73814b67aae020e84ae9ca4ba8250ac5d6f5ed04f030df14ac3eac14` |
| Bamboo Chimes | `assets/sounds/wind_chimes.mp3` | 897,356 | `66b3a7165cbff1dca1ad5a9edc1050b05dca0435af83ddb97041e8ae4b7e8079` |
| Temple Bowl | `assets/sounds/tibetan_bowls.mp3` | 1,011,212 | `933c8c4218c0e89d88624db68bb89aa7eda080a41a7a404ee3d6029afaa8d582` |

`calm_guided.mp3` is the seventh existing file, used for timed calming sessions; it is **not narration or a mixer-choice recording**. Its provenance also needs owner review.

### Shared legacy sources

- `Campfire` / `Cozy Hearth`: one bundled fire clip and the same named remote fallback.
- `Bamboo Chimes` / `Wind Chimes`: one bundled wind-chime clip.
- `Temple Bowl` / `Singing Bowl` / `Singing Bowls` / `Tibetan Bowls`: one bundled bowl clip. `Temple Bowl` is now explicitly mapped to it, not generic rain.
- `Wind in Trees` / `Soothing Breeze`: same existing remote tree-wind URL.
- `Gamma Insight` / `Deep Space Drone`: same existing remote binaural-gamma WAV. No unique cosmic-drone recording is implied.
- Local-first clips and their named network fallbacks have not been proven byte-identical or perceptually equivalent. The fallbacks predate this feature; they are not exposed as new alternative takes.

### Audit evidence and limits

Read-only GitHub inspection of [`remvze/moodist`](https://github.com/remvze/moodist) at tree/revision **`11c0be2200116a3635880d600fd6953899cc51a3`** found all currently configured Moodist file paths in its public tree. The [README third-party-assets notice](https://github.com/remvze/moodist/blob/11c0be2200116a3635880d600fd6953899cc51a3/README.md) distinguishes [Pixabay](https://pixabay.com/service/license-summary/) and [CC0](https://creativecommons.org/publicdomain/zero/1.0/) from MIT code. Inspected rain/nature/noise category records contain display labels and paths, **not per-recording licensing receipts**. No external MP3 was downloaded or auditioned, no permission was obtained, and no external service's license was assumed to authorize redistribution. Existing remote URLs still track `main`; a cleared release should pin/provision approved media.

### All sound cards

“Configured stream” means a URL is declared, not that its playback/rights have been verified on a device. In the independent browser preview **only bundled clips play**; it does not fetch the streaming catalog. All names, Favorites and old saved levels remain addressable. In-app missing-source errors are intentional, not placeholders for invented content.

| Category | Card | Current source configuration |
| --- | --- | --- |
| Rain | Soft Rain | Bundled-first: `assets/sounds/soft_rain.mp3` |
| Rain | Thunderstorm | Configured stream: `sounds/rain/thunder.mp3` |
| Rain | Rain on Window | Configured stream: `sounds/rain/rain-on-window.mp3` |
| Rain | Rain on Roof | Configured stream: `sounds/rain/rain-on-car-roof.mp3` |
| Rain | Rain on Umbrella | Configured stream: `sounds/rain/rain-on-umbrella.mp3` |
| Rain | Rain on Tent | Configured stream: `sounds/rain/rain-on-tent.mp3` |
| Rain | Rain on Leaves | Configured stream: `sounds/rain/rain-on-leaves.mp3` |
| Rain | Urban Rain | Configured stream: [OGG](https://actions.google.com/sounds/v1/weather/rain_on_roof.ogg) |
| Rain | Heavy Rain | Configured stream: `sounds/rain/heavy-rain.mp3` |
| Rain | Light Drizzle | **No recording configured** — labeled; no substitute playback |
| Rain | Rain Cave | **No recording configured** — labeled; no substitute playback |
| Rain | Tropical Storm | **No recording configured** — labeled; no substitute playback |
| Nature | Ocean Waves | Bundled-first: `assets/sounds/ocean_waves.mp3` |
| Nature | Mountain Stream | Configured stream: `sounds/nature/river.mp3` |
| Nature | Forest Birds | Bundled-first: `assets/sounds/forest_birds.mp3` |
| Nature | Campfire | Bundled-first: `assets/sounds/campfire.mp3` |
| Nature | Wind in Trees | Configured stream: `sounds/nature/wind-in-trees.mp3` |
| Nature | Crickets | Configured stream: `sounds/animals/crickets.mp3` |
| Nature | Waterfall | Configured stream: `sounds/nature/waterfall.mp3` |
| Nature | Frogs | Configured stream: `sounds/animals/frog.mp3` |
| Nature | Waves on Pebbles | **No recording configured** — labeled; no substitute playback |
| Nature | Underwater | **No recording configured** — labeled; no substitute playback |
| Nature | Meadow Breeze | **No recording configured** — labeled; no substitute playback |
| Nature | Desert Wind | **No recording configured** — labeled; no substitute playback |
| Nature | Jungle Night | **No recording configured** — labeled; no substitute playback |
| Nature | Leaves Rustling | **No recording configured** — labeled; no substitute playback |
| Nature | Mountain Echo | **No recording configured** — labeled; no substitute playback |
| Places | Coffee Shop | Configured stream: `sounds/places/cafe.mp3` |
| Places | Library | Configured stream: `sounds/places/library.mp3` |
| Places | Office Ambience | Configured stream: `sounds/places/office.mp3` |
| Places | Church Bells | **No recording configured** — labeled; no substitute playback |
| Places | Quiet Park | **No recording configured** — labeled; no substitute playback |
| Places | Street Market | **No recording configured** — labeled; no substitute playback |
| Places | Temple Bowl | Bundled-first: `assets/sounds/tibetan_bowls.mp3` |
| Places | Zen Garden | **No recording configured** — labeled; no substitute playback |
| Places | Harbor | **No recording configured** — labeled; no substitute playback |
| Places | Farmyard | **No recording configured** — labeled; no substitute playback |
| Transport | Train Track | **No recording configured** — labeled; no substitute playback |
| Transport | Airplane Cabin | Configured stream: `sounds/transport/airplane.mp3` |
| Transport | Driving Rain Car | **No recording configured** — labeled; no substitute playback |
| Transport | Boat Deck | **No recording configured** — labeled; no substitute playback |
| Transport | Subway Train | **No recording configured** — labeled; no substitute playback |
| Transport | Bicycle Ride | **No recording configured** — labeled; no substitute playback |
| Transport | Sailing Ship | Configured stream: `sounds/transport/sailboat.mp3` |
| Transport | Highway Traffic | Configured stream: `sounds/urban/highway.mp3` |
| Things | Clock Ticking | Configured stream: `sounds/things/clock.mp3` |
| Things | Fan Noise | **No recording configured** — labeled; no substitute playback |
| Things | Keyboard Typing | Configured stream: `sounds/things/keyboard.mp3` |
| Things | Washing Machine | Configured stream: `sounds/things/washing-machine.mp3` |
| Things | Vinyl Crackle | Configured stream: `sounds/things/vinyl-effect.mp3` |
| Things | Boiling Kettle | **No recording configured** — labeled; no substitute playback |
| Things | Bamboo Chimes | Bundled-first: `assets/sounds/wind_chimes.mp3` |
| Things | Page Turning | **No recording configured** — labeled; no substitute playback |
| Things | Pendulum | **No recording configured** — labeled; no substitute playback |
| Things | Wind Generator | **No recording configured** — labeled; no substitute playback |
| Noise | White Noise | Configured stream: `sounds/noise/white-noise.wav` |
| Noise | Pink Noise | Configured stream: `sounds/noise/pink-noise.wav` |
| Noise | Brown Noise | Configured stream: `sounds/noise/brown-noise.wav` |
| Noise | Blue Noise | **No recording configured** — labeled; no substitute playback |
| Noise | Violet Noise | **No recording configured** — labeled; no substitute playback |
| Noise | Grey Noise | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 432Hz Healing | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 528Hz Transformation | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 639Hz Harmonics | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 108Hz Theta Drone | **No recording configured** — labeled; no substitute playback |
| Solfeggio | Delta Deep Sleep | Configured stream: `sounds/binaural/binaural-delta.wav` |
| Solfeggio | Alpha Focus Flow | Configured stream: `sounds/binaural/binaural-alpha.wav` |
| Solfeggio | Beta Energy Boost | **No recording configured** — labeled; no substitute playback |
| Solfeggio | Gamma Insight | Configured stream: `sounds/binaural/binaural-gamma.wav` |
| Solfeggio | 174Hz Pain Relief | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 285Hz Cellular | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 396Hz Liberation | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 741Hz Intuition | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 852Hz Awakening | **No recording configured** — labeled; no substitute playback |
| Solfeggio | 963Hz Crown State | **No recording configured** — labeled; no substitute playback |

## Implementation and verification

- `lib/models/bundled_recordings.dart`: six choices and explicit source identity for legacy bundled aliases.
- `lib/components/{mixer_artwork,sound_replacement_sheet}.dart`, `lib/services/sound_preview_controller.dart`: consistent covers, explicit preview/use, request ownership, lifecycle cancellation and safe errors.
- `lib/providers/{mixer_controller,app_state}.dart`: one-layer level-preserving swaps, duplicate prevention, preview ducking, injectable ambient players, bounded source attempts, visible missing/failing source state and stale-load guards.
- `test/{mixer_catalog,mixer_controller,mixer_screen,sound_preview_controller,ambient_audio_state,user_backup_state}_test.dart`: asset, controller, widget, delayed-load/failure, gain, persistence and legacy-backup regressions. Flutter/native evidence must be from the **new exact revision**, not the earlier green `332a3fd` baseline.
- `design/preview/sound-replacement.{js,css}` and `test/web/sound_replacement_browser_test.mjs`: independent HTML implementation and **19 browser regressions**, including actual decoding/playback of all six bundled files and 320/390/823px/landscape layouts. Local full browser suite: **115 passed, 0 failed, 0 skipped**; Python diagnostics/verifiers: **15 passed**. These are not Flutter/device results.

[Scrolled covers](../design/mixer-covers-mobile-preview.png) and [replacement chooser](../design/sound-replacement-mobile-preview.png) are **independent HTML screenshots**, not native captures. The chooser screenshot shows a selected row with playback paused; merely opening it does not create a player.

No signed build, store submission, live billing change, public launch or spending was authorized or performed by this update. See [launch readiness](LAUNCH_READINESS.md) for the remaining owner-controlled gates.
