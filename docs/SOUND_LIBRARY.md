# Sound library: sources, safeguards and release boundary

Updated: 2026-11-19. **77 mixer cards, 18 distinct local chooser sources, 12 additions; ten live vibe sets; 23 session arrangements from 14 existing recordings.** Source configuration, original-page grants, technical playback checks and release clearance are separate facts.

## Latest development-audio follow-up

The agreed expansion target is **three real recordings for each of the 18 available sounds: 54 total choices**. The owner accepted temporary development audio while replacements are sourced, not release clearance. No video audio was downloaded and no additional takes have been added. Six older mixer sources now use separate **3–6-second overlap-blended loop edits**, while their originals, the twelve newer mixer files and all 23 session arrangements stay byte-identical. The edits are **24–27-second placeholders**, not longer recordings. Both native/browser source maps and recording auditions reference the same prepared files; Flutter/device playback and human listening remain unverified. [Processing, exact manifest, checks and remaining work](PLACEHOLDER_AUDIO.md).

## Current launch gate

The latest local suites pass **322/322 web + 93/93 Python** checks, but full preflight remains **BLOCKED / 202 pending**. The [register](release/launch-review.json) covers **48 shipped audio files** (18 original mixer inputs + six loop-edit derivatives + 23 arrangements + unused legacy sample), 68 artwork/drawable files, two fonts and all 75 effective stream-only native name bindings, including legacy names outside the 77-card catalog. These are inventory counts, not approvals or additional recordings. All 118 local rights reviews, 75 stream reviews and nine release gates remain pending; normal Sounds browsing is bundled-only, not a promise every legacy route is offline or cleared.

## Current product behavior

- Preserve all **75 familiar cards/covers**, plus **Woodland Morning** and **Fireplace**. Every card has local decorative artwork; related sounds may share a cover. An image does not prove a recording's location, availability or rights. [Artwork provenance](../assets/images/mixer/README.md).
- **Available (18)** is normal browsing. **Review unfinished catalog → Full catalog (77)** deliberately exposes all stable cards with 18 bundled / 23 stream-only / 36 no-recording context; it is not a claim of 77 playable sounds. Categories/curated recipes follow the view; saved mixes, favorites, legacy levels and share/backup formats are preserved. The browser disables inactive stream-only/missing controls; native retains configured streams and disables missing sources. Availability is not Premium access. [Full flow and evidence](SIMPLE_LIBRARY_FLOW.md).
- **Card → ⋯ → Change sound** offers **18 local sources**, searchable by name/description. Twelve additions have visible creator/terms credits. This replaces one layer with a different named sound; it is not alternate takes of every card or a personal-file importer.
- The browser now preflights all mix/transport/switch/slider entry points before selecting unsupported content or pausing another audio mode. Sleep’s app-stream sources and incompatible legacy recipes have visible availability labels; exact-source details preserve current players/timer/levels and offer review or an explicit current-layer removal. A saved recipe is not silently partially applied. [Screenshot-warning follow-up](SIMPLE_LIBRARY_FLOW.md#browser-availability-follow-up). Native stream bindings are unchanged; these are not Premium locks or new audio files.
- **Choose recording (2)** appears only for Fire (Campfire/Fireplace) and Birds (Forest Birds/Woodland Morning). The compact two-choice sheet is distinct from the searchable cross-source chooser. No alternate rain takes were added.
- Opening, searching or selecting a row never autoplays or changes the mix. **Preview** is explicit, quiet and limited to eight seconds, with loading/failure/timeout handling. A playing mix is temporarily ducked; a paused mix stays paused. Stop, close, lifecycle loss, failure, timeout or use disposes the preview and restores gain. Late loads cannot restart a canceled preview.
- **Use sound** keeps the layer's volume and other layers. An off card selects the new layer at 30%, without starting a paused mix. The chosen category is shown. Already-selected targets and aliases sharing the same source are blocked as duplicates. The web install entry is hidden independently while the chooser owns the screen.
- Saves, cached selections, share links and backups keep the **real chosen name and level** in the existing format; there is no hidden override or new backup schema. Local-only additions work in shared links. Return to a bundled original by choosing it again; for a stream-only original, turn off the replacement and reselect its card. Existing saved mixes are not overwritten by a swap. Card/switch taps, independent levels, long-press Favorites and **Home / Sounds / Meditate / Sleep** remain.

## Ten one-tap vibe sets

The first ten chips in **Sounds → Curated one-tap mixes** now use the user’s exact requested recipes below, replacing the preceding featured ten. They use **15 of the 18 existing bundled recordings**, not new recordings or the separately rendered Meditate/Sleep arrangements. Names, main purposes and percentages match the requested catalog.

| # | Preset | Main purpose | Individual volume levels |
| --- | --- | --- | --- |
| 1 | **Rainy Window Café** | Focus | Soft Rain 65% · Coffee Shop 25% · Brown Noise 15% · Bamboo Chimes 10% |
| 2 | **Enchanted Forest Morning** | Morning | Woodland Morning 65% · Forest Birds 55% · Meadow Breeze 25% · Mountain Stream 20% |
| 3 | **Ocean Deep Sleep** | Sleep | Ocean Waves 65% · Brown Noise 35% · Crickets 15% |
| 4 | **Mountain Meditation** | Meditate | Mountain Stream 50% · Meadow Breeze 30% · Forest Birds 25% · Temple Bowl 15% |
| 5 | **Cozy Fireplace Night** | Comfort | Fireplace 65% · Crickets 30% · Soft Rain 20% · Brown Noise 15% |
| 6 | **Tropical Rainforest** | Relax | Mountain Stream 55% · Soft Rain 40% · Forest Birds 40% · Meadow Breeze 15% |
| 7 | **Zen Temple Sanctuary** | Meditate | Temple Bowl 55% · Meadow Breeze 25% · Mountain Stream 20% · Bamboo Chimes 15% |
| 8 | **Midnight Focus** | Focus | Brown Noise 55% · White Noise 30% · Coffee Shop 15% · Soft Rain 10% |
| 9 | **Campfire Under Stars** | Relax | Campfire 65% · Crickets 50% · Meadow Breeze 20% · Ocean Waves 10% |
| 10 | **Peaceful Ocean Journey** | Escape | Boat Deck 45% · Ocean Waves 65% · Meadow Breeze 20% · Bamboo Chimes 10% |

Percentages are **independent volume sliders**, not a 100% split. Requested totals are **110–165%**; no layer exceeds 65%. The existing master output gain, per-track cap, preview ducking and sleep fade remain active without changing selected/saved slider levels. These are not measured acoustic-loudness or hearing-safety guarantees. Start with low device volume. Pink, Blue and Violet Noise remain in the library even though these recipes do not use them.

- One tap immediately enables the exact ingredients, resets every other sound to off/zero and updates badges, switches and sliders. Readiness/glow still reflects actual playback. Pause/resume retains the recipe; shared healthy loops are not restarted when switching mixes.
- Editing a level or toggling an ingredient makes a custom mix without mutating the original. Save writes a separate custom snapshot in the existing format; reselecting a preset restores official levels without overwriting saved mixes. Same-named custom recipes cannot display an incorrect official ingredient panel.
- The **eight older preset names/recipes**, rename keys, Favorites, saved snapshots, cached selections and backup/share formats remain intact. Incompatible old recipes remain in Full catalog. Old saved snapshots bearing a preceding featured name are preserved rather than renamed or migrated.
- The 77-card catalog, 18 bundled source choices, audio/artwork bytes, aliases, player/readiness/availability guards, Sleep drawings and all 23 session arrangements are unchanged. No stock/example image from the supplied links was imported or treated as licensed.
- Results at completion of the requested-recipe batch (before launch hardening): **22/22 browser playback/UI cases + 9/9 source/parity guards**; full **244/244 web + 41/41 Python**, zero failures/skips. **50/50 live recipe/viewport checks** cover 320/390/431/823/1440px. **147 protected hashes** and the inline engine remain unchanged from this pass’s baseline. The 34 set-related native cases (22 model/provider/controller + 12 widget, two newly added) remain **unexecuted** without Flutter.

[Exact behavior, independent recipe contract and limits](CURATED_SOUND_MIXES.md) · [current four-tab gallery](../design/README.md). Historical paused Rainy Window Café and earlier Rainlit Cabin captures remain in [Git history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design), not the current source tree. The earlier 202-test/52–70% evidence is not current recipe settings. Browser decoding is not native/device or human-listening certification.

## Meditate / nighttime session audio

Meditate initially shows today and three starters, visible Save/ingredients, All/Calm/Focus/Rest/Saved filters and Browse all 14. This is a browsing simplification, not deletion or access gating.

The daily practice, 14 Meditate cards and eight nighttime journeys now use **23 explicitly routed ambient arrangements**, each mixing a different pair from 14 existing recordings. Home and Meditate reuse the same daily practice. Ingredient names are visible on cards/player; approximate 30-second repetition and no narration are disclosed. Missing/failed content has no universal or unrelated remote fallback. This does not add 23 new master recordings, expand the 18-choice mixer or clear source rights. See [all recipes, measured checks and rebuild instructions](SESSION_AUDIO.md).

## Coverage, counted by card name

| Measure | Current value | Meaning |
| --- | ---: | --- |
| Cards | **77** | 75 retained + 2 additions |
| Configured card names | **41** | 18 bundled + 23 stream-only; not 41 unique or cleared recordings |
| Cards still needing a recording | **36** | Kept in Full catalog and explicitly labeled; never silently substituted with unrelated rain |
| Local chooser sources | **18** | Six legacy clips + twelve additions; source aliases are not extra choices |
| Local name aliases | **23** | Includes legacy saved-mix names sharing the six older clips |
| Additions with provenance in this pack | **12** | Seven field recordings + five generated noises; 6,765,450 bytes |

Six previously stream-only card names now use the new local recordings. Other additions fill previously missing sources or appear on the two new cards. This does **not** mean twelve new catalog cards or twelve extra versions of rain.

## New additions and original-page evidence

The [manifest](../assets/sounds/ambient_pack.json) pins every output hash/size, original page/creator, grant, mirror commit/blob, source hash and processing description. The [recording-specific evidence](audio-licenses/ambient-pack-2026-11-19.md) records the checked CC0/public-domain statements and limitations. The mirror's **code licence is not used as an audio licence**.

| Chooser name | Kind | Distributed file | Original grant / creator |
| --- | --- | --- | --- |
| Woodland Morning | Field recording | `woodland_morning.mp3` | [CC0-1.0](https://freesound.org/people/kvgarlic/sounds/156826/) · kvgarlic |
| Boat Deck | Field recording | `boat_deck.mp3` | [CC0-1.0](https://freesound.org/people/Falcet/sounds/439365/) · Falcet |
| Mountain Stream | Field recording | `woodland_stream.mp3` | [CC0-1.0](https://freesound.org/people/gluckose/sounds/333987/) · gluckose |
| Meadow Breeze | Field recording | `meadow_wind.mp3` | [CC0-1.0](https://freesound.org/people/felix.blume/sounds/217506/) · felix.blume |
| Coffee Shop | Field recording | `cafe_ambience.mp3` | [Public domain (source-page designation)](https://soundbible.com/1664-Restaurant-Ambiance.html) · stephan |
| Fireplace | Field recording | `fireplace.mp3` | [Public domain (source-page designation)](https://soundbible.com/1543-Fireplace.html) · ezwa |
| Crickets | Field recording | `night_crickets.mp3` | [Public domain (source-page designation)](https://soundbible.com/2083-Crickets-Chirping-At-Night.html) · Lisa Redfern |
| White Noise | Generated noise | `noise_white.mp3` | [CC0-1.0](../tool/prepare_ambient_pack.py) · Sanctuary project |
| Pink Noise | Generated noise | `noise_pink.mp3` | [CC0-1.0](../tool/prepare_ambient_pack.py) · Sanctuary project |
| Brown Noise | Generated noise | `noise_brown.mp3` | [CC0-1.0](../tool/prepare_ambient_pack.py) · Sanctuary project |
| Blue Noise | Generated noise | `noise_blue.mp3` | [CC0-1.0](../tool/prepare_ambient_pack.py) · Sanctuary project |
| Violet Noise | Generated noise | `noise_violet.mp3` | [CC0-1.0](../tool/prepare_ambient_pack.py) · Sanctuary project |

These are MP3 derivatives, not original lossless masters or individual narrated sessions. Stream/boat/wind descriptions reflect the source pages, not artwork or unverified locations. All bundled identities now have **no automatic remote fallback** in native source: a failed local asset produces a retry/replacement error. Source/fixture checks are not native execution evidence. Five independently seeded noises contain no third-party samples; Grey Noise remains unconfigured rather than relabeling another color.

### Highest-value remaining work

| Priority / source | Finding and required action |
| --- | --- |
| P0 — legacy audio / `assets/sounds/` | The six old mixer MP3s and separate `calm_guided.mp3` predate this work. No per-file redistribution receipts were found. Their bytes remain unchanged; owner must establish provenance/permission or replace them before distribution. |
| P0 — new-pack claim review / `docs/audio-licenses/` | Original-page CC0/public-domain grants are documented, not a warranty of all third-party rights. The wood-thrush source page contains historical Content ID complaints. Review/resolve that risk before release; do not promise claim-free use. |
| P0 — streams / `lib/providers/app_state.dart` | Existing Moodist/Google URLs are configured, not individually rights-cleared or device-verified. Moodist's MIT code licence does not clear its audio; audit original sources and pin/provision approved media. |
| P0 — listening and device playback | Browser decoding/FFmpeg checks do not establish pleasing levels, clean seams, correct spectrum or iOS/Android audio routing, interruptions, background/lock screen, long timers or fades. A human listening pass and signed-device matrix remain required. |
| Deferred — missing cards / `lib/models/mixer_catalog.dart` | 36 entries remain review-only without recordings; adding content is not launch hardening. Preserve names/saved levels. Any later additions need real distinct recordings, accurate descriptions and recording-specific grants; never count aliases or make unverified frequency/health claims. |

### Retained original input bytes (unchanged)

The chooser still lists one name per distinct recording, but its six legacy identities now play the separate loop edits in [the exact manifest](../assets/sounds/placeholder_loops.json). The files below remain intact as original inputs for provenance/rebuilds and existing session arrangements; they are not extra chooser options. These hashes record identity, **not origin or a license**.

| Chooser name | Existing file | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Soft Rain | `assets/sounds/soft_rain.mp3` | 538,748 | `9f40e761012c8259e142f6825eb802976850863ee99e4e6f0d2e040f8f9d9833` |
| Ocean Waves | `assets/sounds/ocean_waves.mp3` | 834,956 | `69769264ab133e22ed916553794af4ae14e183227f556e7cb9dca6148c973d8c` |
| Forest Birds | `assets/sounds/forest_birds.mp3` | 582,476 | `67e5e2bb7c94d6dd58a505f62dfc9ad3a3f5c590bddf3229b532acc3410c75bc` |
| Campfire | `assets/sounds/campfire.mp3` | 1,010,636 | `e39ffb4d73814b67aae020e84ae9ca4ba8250ac5d6f5ed04f030df14ac3eac14` |
| Bamboo Chimes | `assets/sounds/wind_chimes.mp3` | 897,356 | `66b3a7165cbff1dca1ad5a9edc1050b05dca0435af83ddb97041e8ae4b7e8079` |
| Temple Bowl | `assets/sounds/tibetan_bowls.mp3` | 1,011,212 | `933c8c4218c0e89d88624db68bb89aa7eda080a41a7a404ee3d6029afaa8d582` |

`calm_guided.mp3` is the seventh existing file, **formerly** the universal timed-session sample. It is no longer referenced by playback or used as a fallback and is not narration or a mixer-choice source. It is still present in the bundled asset directory; remove it or establish provenance before distribution. None of the arrangements uses it.

### Shared legacy sources

- `Campfire` / `Cozy Hearth`: one bundled fire clip. The former similarly named network fallback is no longer attempted for either local identity.
- `Bamboo Chimes` / `Wind Chimes`: one bundled wind-chime clip.
- `Temple Bowl` / `Singing Bowl` / `Singing Bowls` / `Tibetan Bowls`: one bundled bowl clip. `Temple Bowl` is now explicitly mapped to it, not generic rain.
- `Wind in Trees` / `Soothing Breeze`: same existing remote tree-wind URL.
- `Gamma Insight` / `Deep Space Drone`: same existing remote binaural-gamma WAV. No unique cosmic-drone recording is implied.
- Legacy local files and similarly named network URLs have not been proven byte-identical, perceptually equivalent or rights-equivalent. **Native source now loads only the bundled file for local identities**; failure is explicit and retry reloads that asset. This hardening change has authored tests but still needs Flutter/device execution. Stream-only bindings retain their original CDN/raw transport; no source URL is silently replaced.

### Remote audit evidence and limits

Read-only inspection of [`remvze/moodist` at `11c0be2200116a3635880d600fd6953899cc51a3`](https://github.com/remvze/moodist/tree/11c0be2200116a3635880d600fd6953899cc51a3) found the configured Moodist paths in its tree. Its [third-party-assets notice](https://github.com/remvze/moodist/blob/11c0be2200116a3635880d600fd6953899cc51a3/README.md) distinguishes Pixabay Content License/CC0 audio from MIT code. Inspected category records do not supply individual licence receipts. No Moodist audio was imported or relicensed by this addition. Existing remote URLs still track `main`; availability is not permission.

## All sound cards

“Configured stream” means a declared URL, not proven playback or redistribution rights. The independent HTML preview **plays only local sources**, not the remote catalog. All names and old Favorites/saved levels remain addressable. Missing-source notices are intentional, not fake playback.

| Category | Card | Current source configuration |
| --- | --- | --- |
| Rain | Soft Rain | Bundled loop edit: `assets/sounds/loop_soft_rain.mp3` |
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
| Nature | Ocean Waves | Bundled loop edit: `assets/sounds/loop_ocean_waves.mp3` |
| Nature | Mountain Stream | Bundled: `assets/sounds/woodland_stream.mp3` |
| Nature | Forest Birds | Bundled loop edit: `assets/sounds/loop_forest_birds.mp3` |
| Nature | Woodland Morning | Bundled: `assets/sounds/woodland_morning.mp3` |
| Nature | Campfire | Bundled loop edit: `assets/sounds/loop_campfire.mp3` |
| Nature | Fireplace | Bundled: `assets/sounds/fireplace.mp3` |
| Nature | Wind in Trees | Configured stream: `sounds/nature/wind-in-trees.mp3` |
| Nature | Crickets | Bundled: `assets/sounds/night_crickets.mp3` |
| Nature | Waterfall | Configured stream: `sounds/nature/waterfall.mp3` |
| Nature | Frogs | Configured stream: `sounds/animals/frog.mp3` |
| Nature | Waves on Pebbles | **No recording configured** — labeled; no substitute playback |
| Nature | Underwater | **No recording configured** — labeled; no substitute playback |
| Nature | Meadow Breeze | Bundled: `assets/sounds/meadow_wind.mp3` |
| Nature | Desert Wind | **No recording configured** — labeled; no substitute playback |
| Nature | Jungle Night | **No recording configured** — labeled; no substitute playback |
| Nature | Leaves Rustling | **No recording configured** — labeled; no substitute playback |
| Nature | Mountain Echo | **No recording configured** — labeled; no substitute playback |
| Places | Coffee Shop | Bundled: `assets/sounds/cafe_ambience.mp3` |
| Places | Library | Configured stream: `sounds/places/library.mp3` |
| Places | Office Ambience | Configured stream: `sounds/places/office.mp3` |
| Places | Church Bells | **No recording configured** — labeled; no substitute playback |
| Places | Quiet Park | **No recording configured** — labeled; no substitute playback |
| Places | Street Market | **No recording configured** — labeled; no substitute playback |
| Places | Temple Bowl | Bundled loop edit: `assets/sounds/loop_tibetan_bowls.mp3` |
| Places | Zen Garden | **No recording configured** — labeled; no substitute playback |
| Places | Harbor | **No recording configured** — labeled; no substitute playback |
| Places | Farmyard | **No recording configured** — labeled; no substitute playback |
| Transport | Train Track | **No recording configured** — labeled; no substitute playback |
| Transport | Airplane Cabin | Configured stream: `sounds/transport/airplane.mp3` |
| Transport | Driving Rain Car | **No recording configured** — labeled; no substitute playback |
| Transport | Boat Deck | Bundled: `assets/sounds/boat_deck.mp3` |
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
| Things | Bamboo Chimes | Bundled loop edit: `assets/sounds/loop_wind_chimes.mp3` |
| Things | Page Turning | **No recording configured** — labeled; no substitute playback |
| Things | Pendulum | **No recording configured** — labeled; no substitute playback |
| Things | Wind Generator | **No recording configured** — labeled; no substitute playback |
| Noise | White Noise | Bundled: `assets/sounds/noise_white.mp3` |
| Noise | Pink Noise | Bundled: `assets/sounds/noise_pink.mp3` |
| Noise | Brown Noise | Bundled: `assets/sounds/noise_brown.mp3` |
| Noise | Blue Noise | Bundled: `assets/sounds/noise_blue.mp3` |
| Noise | Violet Noise | Bundled: `assets/sounds/noise_violet.mp3` |
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

The [stability follow-up](PROJECT_GOALS.md) adds confirmed-playback indicators to the independent HTML mixer: unavailable/failed sources do not count or glow, pending loads stay cancelable, and explicit retry leaves healthy loops running. The ten new ambient regressions cover partial failure, playback refusal, timeout, late media events, retry and mode-switch cancellation. This does not establish native readiness/buffering behavior.

- `lib/models/{bundled_recordings,mixer_catalog,vibe_sound_sets}.dart`: 77 cards, 18 source choices, 23 explicit aliases, ten live mixer recipes and new-pack credits.
- `lib/components/sound_replacement_sheet.dart`, `lib/services/sound_preview_controller.dart`, `lib/providers/{mixer_controller,app_state}.dart`: searchable explicit preview/use, source identity/duplicate guards, level/paused-state preservation, local-only link support and safe load/play errors. Preview request ownership, lifecycle cancellation and gain recovery are retained.
- `tool/verify_ambient_pack.py`: checks twelve exact output hashes/sizes, seven distinct pinned source identities and per-recording provenance; optionally fully decodes the MP3s and checks duration, non-silence and bounded mono/downsampled levels. It is not a subjective loudness/true-peak/spectrum/seam guarantee. All twelve final files passed full decode/QC on 2026-11-19.
- Historical pre-hardening checkpoint: **244/244 browser/PWA/source/configuration tests**, including actual playback of all **18** chooser sources, **23** session arrangements and **ten** new live vibe sets; **41/41 Python tests**, including provenance/duplicate/corruption/rebuild guards for both packs. The 23 final arrangements also passed full decode, full-bandwidth stereo loudness/headroom measurement, and 253 pairwise identity-regression checks; those checks do not replace a human listening pass. No skips. New wellbeing, breathing, responsive Meditate/filter and chooser-search regressions are included, along with 15 first-pass library/Meditate cases and two family/filter parity guards. The [simplification evidence](SIMPLE_LIBRARY_FLOW.md#verification-and-limits) records 40 live checks, 93 unchanged protected hashes and 16 additional unexecuted native cases. The subsequent warning follow-up adds 20 preflight/availability regressions and 25 live checks; 148 protected files were unchanged for that earlier browser-only pass. The later requested-preset update replaces only the featured ten recipes, updates their details/purposes and maintains exact independent volume levels: 22 recipe-browser cases, 9 parity guards, 50 live checks and 147 current protected hashes pass. [Current recipe evidence](CURATED_SOUND_MIXES.md). Tests use isolated browser history, not fabricated native data.
- Changed Dart source/tests were WASM-parsed/formatted, **not compiled**. New Flutter regressions cover wellbeing navigation/real activity/timer phases and new sources/search/keyboard/clipboard handling; they remain unexecuted without the SDK. [Run 44483121445 / `d6447f6`](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44483121445) passed 260 Flutter tests and all four jobs **before these changes**. Fresh Flutter/web/unsigned-native verification is still required.

### Reproduce and rebuild

```sh
python3 -m unittest discover -s tool -p 'test_*.py' -v
python3 tool/verify_ambient_pack.py
python3 tool/verify_ambient_pack.py --ffmpeg /path/to/ffmpeg --report build/audio-qc.json
# Restore pinned source blobs and rebuild into ignored scratch storage:
python3 tool/prepare_ambient_pack.py --download --ffmpeg /path/to/ffmpeg
```

The rebuild defaults to `build/rebuilt-ambient-pack`. Changing reviewed bundled files requires **both** `--output-dir assets/sounds --update-manifest`; a scratch rebuild cannot rewrite the bundled manifest. Different encoder builds can produce different hashes: review/recheck the files and update the encoder/evidence description when deliberately replacing them. Raw downloads and QC reports stay in ignored `build/` storage.

Historical sound-search and card-cover captures remain in [pre-cleanup Git history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design), not the current tree. They are independent HTML, not native captures; the search image was paused and filtering/selecting did not create a player. See the separate [current four-tab gallery](../design/README.md).

No signed distribution, store submission, live billing change, public launch or spending was performed by this follow-up. See [launch readiness](LAUNCH_READINESS.md) for the owner-controlled gates.
