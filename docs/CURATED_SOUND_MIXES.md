# Ten requested curated sound mixes

The later [launch-hardening pass](LAUNCH_HARDENING.md) keeps every recipe below intact, puts the 77-entry inventory behind explicit review and removes automatic native network fallback for bundled identities. Its local totals are 256 web / 71 Python; rights/native/device/listening gates remain open. Recipe-batch counts and captures below describe their original verification, not a fresh native run.

Implemented: 2026-11-19. These replace the preceding ten featured vibe recipes in **Sounds → Curated one-tap mixes**, in the user’s requested order. They are live mixer recipes in Flutter source and the independent HTML preview, not names-only mockups, new recordings, rendered session files or narrated practices.

## Exact preset catalog

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

The main purposes match the user’s final recommended catalog. Scene names are evocative: existing woodland/field/water recordings are not claimed to be newly recorded tropical, mountain or café-window locations. Existing app artwork is reused; linked stock/example images were not downloaded or represented as licensed assets.

## One-tap behavior

The subsequent [ambient-player update](AMBIENT_PLAYER.md) automatically opens the actual layer/level view when a recipe starts. Minimize keeps audio running; its mini-player reopens this view on every tab, including while paused. The exact recipes below are unchanged.

1. Tapping a preset immediately selects **only** its listed sounds and their exact percentages. Every other catalog entry reads as off / zero; an old selection cannot remain mixed underneath it.
2. Switches, slider positions, percentage badges and the selected-preset recipe update synchronously, before asynchronous media readiness. Playback indicators still depend on actual ready/playing audio, not selection alone.
3. Users can adjust any level or switch a sound off. This makes a custom selection and removes the official-recipe highlight/readout; it never edits the immutable preset definition.
4. **Save** records that custom name/level map separately in the existing saved-mix format. Reloading a preset restores its official levels without overwriting the saved custom mix. A saved mix sharing an official name is not falsely presented as the official recipe unless its actual levels match.
5. Pause/resume retains selected levels. Switching recipes retains shared healthy players and silences removed layers. Browser reload restores a selection without autoplay.
6. No new source, alias, fallback, availability entitlement, audio file, narration or purchase gate is added. All ingredients are existing canonical bundled sources, so the app-stream preview warning is not needed for these ten choices.

## Inventory and gain boundaries

- **77 catalog cards / seven categories**, **18 distinct bundled sources**, source paths and aliases are unchanged. The ten recipes use **15** existing recordings; unused Pink/Blue/Violet Noise remain available.
- The **eight older curated recipes** remain unchanged, giving **18 built-in preset choices in Full catalog**. Available shows the ten requested recipes plus the compatible older Zen Sanctuary recipe. Saved mixes are never filtered out or migrated. Existing saved snapshots using a preceding featured name (for example Rainlit Cabin) retain their original names and levels, even though that name is no longer a featured chip.
- The **23 Meditate/nighttime arrangements** are separate and unchanged. So are the daily practice, four navigation tabs and preferred Sleep outline drawings/bindings/glow.
- Percentages are independent slider positions, **not proportions required to total 100%**. The requested totals range from **110% to 165%**, and no selected layer exceeds 65%.
- The existing output gain remains `min(1, 1 / sum(selected levels))`, followed by existing per-track cap, preview ducking and sleep-fade rules. For Rainy Window Café, the Soft Rain slider remains **65%** while its initial media gain is `0.65 / 1.15`. This does not rewrite sliders, storage, share links or official percentages. It is an output safeguard, not a calibrated acoustic-loudness or hearing-safety guarantee; start with low device volume.
- Source rights, native/device playback and human listening remain separate release gates. No new audio acquisition, stock-image licensing, SDK/build certification, spending, billing activation or publication occurred.

## Verification

Executed locally for these exact recipes:

- The requested-name discoverability case failed against the preceding ten-featured UI, before implementation.
- **22/22 focused browser recipe/UI regressions**, including all ten actual-media recipes, immediate toggles/sliders, all unselected levels zero, custom/same-name saves, reselect, previous saved snapshots, no unrelated requests, existing output gain, shared-player continuity, failure, pause/share/reload, mode exclusivity and large-text 44px/focus/wrapping checks.
- **9/9 source/parity guards**, including the independent exact recipe contract in `test/fixtures/curated_sound_mixes.json`, purpose/name/level equality across Flutter/HTML, 18-source/77-card/alias/family parity, and all eight legacy recipe maps. Two source guards and three browser cases were added; the earlier recipe cases were deliberately updated rather than skipped.
- **244/244 full browser/PWA/source/configuration tests + 41/41 Python tests**, zero failures/skips. This retains the full available-source chooser, 23 session arrangements and unavailable-source preflight/runtime-retry coverage.
- **50/50 live recipe/viewport checks**: all ten recipes at 320/390/431/823/1440px. Verify exact selection/purpose/recipe, actual local-only playback and limiter output, no browser errors or document/panel overflow, and 44px keyboard-focusable chips. Full catalog still has 77 cards and 18 preset choices.
- **147/147 protected-file hashes unchanged**: every media/artwork/font file, all native source except the intended recipe model and Sounds details, and the preview Sleep/session/player/chooser bindings and engines. Five preview catalog/source constants are byte-identical; only featured recipe data and its details/purpose presentation change. The inline readiness/gain/transport/apply/switch/slider/save/preflight code is byte-identical to the prior warning-fix baseline.
- Four touched Dart files are WASM parse/format-stable; native assertions were reviewed for the new output-gain expectations and required imports. All JS/inline syntax, 18 asset content versions, documentation links and patch whitespace pass. **This is not Dart type analysis or native compilation.**

**Native execution is pending:** Flutter/Dart are unavailable here. The set-related native test coverage now comprises **22 model/provider/controller + 12 widget cases** (34 total; two added, the preceding cases updated), including exact recipes/purposes, zeroed unselected layers, custom saves, output gain, retry/cancellation and narrow layouts. These remain unexecuted; existing readiness and simplification native gates also remain open. Do not treat an earlier CI run as verification of this change.

The historical paused Rainy Window Café capture is preserved in [pre-cleanup Git history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design), not duplicated in the current tree. It was inspected 390 × 1100 independent HTML, not a native screenshot: the recipe was started, checked and paused with 65/25/15/10 selected. The [current four-tab gallery](../design/README.md) is a separate visual reference, not a rerun of that playback measurement.

Reproduce with `npm run test:web`, `python3 -m unittest discover -s tool -p 'test_*.py' -v` and `node tool/version_preview_assets.mjs --check`. Focused browser source: `test/web/vibe_sets_browser_test.mjs`; parity: `test/web/catalog_sync_test.mjs`; native: `test/vibe_sound_sets_test.dart` and `test/mixer_screen_test.dart`.

Temporary logs: `/tmp/arena-requested-curated-{red,focused,parity,all-web,python}.log`. Ignored baseline/live evidence: `build/requested-curated-protected-before.json`, `build/requested-curated-live-check.json`. Test sources persist; temporary evidence may not.
