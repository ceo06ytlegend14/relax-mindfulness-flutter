# Sound durations — all 77 catalog entries

Measured 2026-11-19 from the current checkout and the pinned upstream revision below. **These are source-loop lengths, not the maximum time you can listen.** Ambient sounds repeat until paused/stopped or a sleep timer ends. The 8-second replacement audition and 15/30/45-minute listening timers are separate from recording length.

## Current loop-edit update

The six legacy mixer identities now use separate overlap-prepared development files: Soft Rain **27s**, Ocean Waves **26s**, Forest Birds **24s**, Campfire **26s**, Bamboo Chimes **27s**, Temple Bowl **26s**. Their source paths, decoded lengths and hashes below/in the CSV reflect these final files, measured with full FFmpeg and Chromium decoding. Original 30-second inputs remain untouched and identified in [the loop manifest](../assets/sounds/placeholder_loops.json). This is a join repair, not a longer master, new take or listening/rights clearance. The other twelve local rows and all upstream measurements are retained. [Scope and validation](PLACEHOLDER_AUDIO.md).

## What is known

| Group | Entries | Duration evidence |
| --- | ---: | --- |
| Bundled sources | 18 | Full FFmpeg decode, independently checked with Chromium offline decoding |
| Configured app streams | 22 | Full decode of the matching source files at a pinned upstream revision |
| Other configured app stream | 1 | Urban Rain: external Google URL could not be inspected here; length remains unverified |
| No recording configured | 36 | No real file exists for these entries yet; duration is not zero or a guessed value |
| **Total catalog** | **77** | **40 measured lengths, 1 unverified stream, 36 without recordings** |

Durations use **minutes:seconds.tenths**, rounded to the nearest 0.1 second. “Bundled” means present in the app; an upstream stream measurement does **not** mean the independent browser preview can play it or that native/CDN/rights/device verification has passed. The preview still supports only the 18 bundled sources. Upstream files were downloaded only into ignored scratch storage for measurement; none was integrated into the app. The original measurement-only inspection changed no playback. The subsequent six-file loop-edit routing change is explicitly described above; no new recording, network fallback, purchase or release approval was added.

[Download the full CSV](sound-durations.csv). The CSV retains decoded seconds to six decimal places, status, source identity and a SHA-256 for each measured file.

## Rain — 12 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| Soft Rain | 0:27.0 | Bundled loop edit |
| Thunderstorm | 1:08.5 | App stream — upstream file measured |
| Rain on Window | 0:33.1 | App stream — upstream file measured |
| Rain on Roof | 0:10.0 | App stream — upstream file measured |
| Rain on Umbrella | 0:26.6 | App stream — upstream file measured |
| Rain on Tent | 1:22.6 | App stream — upstream file measured |
| Rain on Leaves | 0:42.2 | App stream — upstream file measured |
| Urban Rain | — | App stream — length unverified |
| Heavy Rain | 0:21.8 | App stream — upstream file measured |
| Light Drizzle | — | No recording configured |
| Rain Cave | — | No recording configured |
| Tropical Storm | — | No recording configured |

## Nature — 17 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| Ocean Waves | 0:26.0 | Bundled loop edit |
| Mountain Stream | 1:00.0 | Bundled |
| Forest Birds | 0:24.0 | Bundled loop edit |
| Woodland Morning | 1:00.0 | Bundled |
| Campfire | 0:26.0 | Bundled loop edit |
| Fireplace | 0:24.5 | Bundled |
| Wind in Trees | 0:57.6 | App stream — upstream file measured |
| Crickets | 0:48.3 | Bundled |
| Waterfall | 0:23.5 | App stream — upstream file measured |
| Frogs | 1:18.6 | App stream — upstream file measured |
| Waves on Pebbles | — | No recording configured |
| Underwater | — | No recording configured |
| Meadow Breeze | 0:13.8 | Bundled |
| Desert Wind | — | No recording configured |
| Jungle Night | — | No recording configured |
| Leaves Rustling | — | No recording configured |
| Mountain Echo | — | No recording configured |

## Places — 10 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| Coffee Shop | 0:15.7 | Bundled |
| Library | 2:56.5 | App stream — upstream file measured |
| Office Ambience | 2:19.7 | App stream — upstream file measured |
| Church Bells | — | No recording configured |
| Quiet Park | — | No recording configured |
| Street Market | — | No recording configured |
| Temple Bowl | 0:26.0 | Bundled loop edit |
| Zen Garden | — | No recording configured |
| Harbor | — | No recording configured |
| Farmyard | — | No recording configured |

## Transport — 8 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| Train Track | — | No recording configured |
| Airplane Cabin | 1:00.0 | App stream — upstream file measured |
| Driving Rain Car | — | No recording configured |
| Boat Deck | 0:40.6 | Bundled |
| Subway Train | — | No recording configured |
| Bicycle Ride | — | No recording configured |
| Sailing Ship | 2:40.5 | App stream — upstream file measured |
| Highway Traffic | 2:12.5 | App stream — upstream file measured |

## Things — 10 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| Clock Ticking | 0:15.9 | App stream — upstream file measured |
| Fan Noise | — | No recording configured |
| Keyboard Typing | 0:12.1 | App stream — upstream file measured |
| Washing Machine | 0:22.5 | App stream — upstream file measured |
| Vinyl Crackle | 1:05.9 | App stream — upstream file measured |
| Boiling Kettle | — | No recording configured |
| Bamboo Chimes | 0:27.0 | Bundled loop edit |
| Page Turning | — | No recording configured |
| Pendulum | — | No recording configured |
| Wind Generator | — | No recording configured |

## Noise — 6 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| White Noise | 1:00.0 | Bundled |
| Pink Noise | 1:00.0 | Bundled |
| Brown Noise | 1:00.0 | Bundled |
| Blue Noise | 1:00.0 | Bundled |
| Violet Noise | 1:00.0 | Bundled |
| Grey Noise | — | No recording configured |

## Solfeggio — 14 entries

| Sound | Source-loop length | Status |
| --- | --- | --- |
| 432Hz Healing | — | No recording configured |
| 528Hz Transformation | — | No recording configured |
| 639Hz Harmonics | — | No recording configured |
| 108Hz Theta Drone | — | No recording configured |
| Delta Deep Sleep | 0:15.0 | App stream — upstream file measured |
| Alpha Focus Flow | 0:15.0 | App stream — upstream file measured |
| Beta Energy Boost | — | No recording configured |
| Gamma Insight | 0:15.0 | App stream — upstream file measured |
| 174Hz Pain Relief | — | No recording configured |
| 285Hz Cellular | — | No recording configured |
| 396Hz Liberation | — | No recording configured |
| 741Hz Intuition | — | No recording configured |
| 852Hz Awakening | — | No recording configured |
| 963Hz Crown State | — | No recording configured |

## Measurement and limits

- Local names/paths and the seven-category, 77-card order follow `design/preview/data.js`, guarded elsewhere against Flutter catalog drift. Six legacy paths now reference their prepared `loop_*.mp3` derivatives; the underlying recording names/aliases and all other source paths are unchanged.
- The 22 measured app-stream files match the configured `lib/providers/app_state.dart` Moodist paths at revision **`11c0be2200116a3635880d600fd6953899cc51a3`**. The upstream tree was complete, and each inspection-only download was verified against its Git blob identity and size before decoding. [Pinned source tree](https://github.com/remvze/moodist/tree/11c0be2200116a3635880d600fd6953899cc51a3/public/sounds). The app itself still references moving stream URLs/CDN paths; future remote changes can change their lengths.
- Each measured file was decoded completely by FFmpeg. Duration = mono PCM sample count / 22,050 Hz; no estimate from file size or nominal bitrate, and no truncation to the audition length. MP3 codec padding/container metadata can give slightly different player-reported lengths. This report uses decoded audio duration.
- At the original measurement-only checkpoint, all 18 local results independently agreed with Chromium offline decode within **1 ms**. The six new prepared files were fully re-decoded/measured and independently checked in Chromium within **1 ms**; browser playback/repeat tests also ran. Technical duration and scheduling are not a human listening verdict.
- Urban Rain uses `https://actions.google.com/sounds/v1/weather/rain_on_roof.ogg`. This environment cannot inspect that host, so its duration is intentionally unverified, not inferred from a similarly named recording.
- No lengths are invented for the 36 unconfigured entries. Solfeggio/health-effect phrases are existing catalog labels, not verified frequency or medical claims.
- The 10 curated mixes run their individual ingredients as simultaneous independent loops; they are not single files with a fixed ending. The separate 23 Meditate/nighttime arrangements are outside this 77-entry mixer inventory.
- **Historical measurement-only checkpoint: 163/163 app/native/media/preview file hashes unchanged** throughout that earlier inspection. Downloaded inspection copies and raw measurements are confined to ignored `build/sound-duration-audit/`; no inspected upstream audio was put into bundled assets or committed. Current release/licensing/native-device gates remain open.

Temporary raw evidence: `build/sound-duration-audit/measurements.json`, `browser-cross-check.json`, `moodist-tree.json`, `stream-sources.json`, and `/tmp/arena-sound-durations-measurements.log`. These may not persist. The CSV now includes the six measured loop-edit identities/lengths/hashes; their originals are retained in the dedicated manifest. Remeasure after changing a source.
