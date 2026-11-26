# Sanctuary design previews

All screenshots on this page are **independent interactive HTML captures**, not compiled Flutter, native-device or store screenshots. Corresponding Flutter source lives in `lib/screens/` and `lib/components/`. Browser behavior does not verify Flutter behavior.

## Ambient full player and persistent mini-player — latest playback follow-up

Starting an ambient mix now opens its full player automatically, with actual selected sounds/independent levels and per-layer Playing/Preparing/Paused/Unavailable status. Minimize keeps playback; its mini-player reopens on every tab and stays available while paused. There is no invented narration/progress timeline. The same local browser audio now uses decoded audio-clock loops; native audio continuity is not established by this preview.

[Full Enchanted Forest Morning, 390 × 1100](ambient-player-mobile-preview.png) · [Mini-player on Sleep, 390 × 844](ambient-mini-player-mobile-preview.png) · [Behavior, before/after telemetry and limits](../docs/AMBIENT_PLAYER.md).

Both images were inspected from the actual live HTML preview. The current interruption-safe gain/timer follow-up passes **289/289 web and 71/71 Python checks**; the original full-player batch passed **55/55 live checks**, which were not rerun for this non-visual follow-up. Volume/timer refreshes no longer unlock an interrupted browser clock. The earlier real-clock 67-second run crossed eight boundaries on four unchanged nodes with zero runtime rebuffer events; this is not human listening or Flutter/device verification. Matching Flutter source and **22 player-related Dart additions** (the original 15 plus seven safety cases) are authored but unexecuted without the SDK. The earlier captures/counts below remain historical; in particular, the prior disappearing paused ambient mini-player and ten-second total browser timeout are superseded by this follow-up.

## Launch-hardening review path

Normal Sounds browsing remains 18 bundled sources. The 77-entry inventory now needs **Review unfinished catalog → Full catalog**, with explicit source counts and non-destructive saved-selection recovery. Closing review returns to Available. No media, recipes, player/Sleep drawings or purchases changed. **256 web / 71 Python** local tests pass; native execution, rights and human/device listening remain open. [Hardening handoff](../docs/LAUNCH_HARDENING.md) · [Current 390 × 1100 paused capture](launch-hardening-mobile-preview.png). This inspected capture and **40/40 current live-review checks** at 320/390/431/823/1440px show the deliberate review path with preserved Rainy Window Café levels; they are independent HTML only. The older library/set captures below predate this disclosure change; they are historical HTML evidence, not fresh native screenshots.

## Simplified library and Meditate — earlier flow

**Available (18)** now leads Sounds, with the full 77-card catalog and older presets preserved separately. Change sound still offers all 18 bundled sources; Choose recording only offers the two genuine Fire or Birds sources. Meditate leads with today and three starters, visible Save/ingredients, All/Calm/Focus/Rest/Saved and Browse all 14. No new audio, access locks or checkout were introduced. [Behavior and verification](../docs/SIMPLE_LIBRARY_FLOW.md).

| Current view | Independent HTML capture |
| --- | --- |
| Meditate — 390px-wide full-content viewport | [Today and three starters](simple-meditate-mobile-preview.png) |
| Sounds — 390px-wide full-content viewport | [Available library](simple-library-mobile-preview.png) |
| Related-recording chooser — 390 × 844 | [Two Fire recordings](recording-choice-mobile-preview.png) |

Full-content viewports keep the fixed footer below the complete page in the first two captures; these are not native-device screenshots. Normal phone heights were checked separately at 320/390/431/823/1440px: **40/40 live checks**, plus the full **244/244 browser tests** and **41/41 Python tests**. New flow coverage includes 1.6× text, 44px actions, keyboard focus through re-renders, preserved selections, real family previews/duplicate guards, all 14 practices and all existing playback regressions. Sixteen new native cases are authored but unexecuted without Flutter. Older styling/set captures below predate this simplification.

## Browser availability warning — corrected before playback

A reported generic “Some selected sounds cannot play” toast was reproducible from Sleep’s Wind/Thunder controls, three app-stream sleep scenes, old presets and unsupported saved/cached selections. The preview now labels these sources before playback and preflights every UI entry point. An unavailable request does not pause a running practice, replace the current mix, partially play a different recipe or reset its timer. Details name the actual missing/app-stream sources, with Keep / Review / Browse actions. A legacy layer can be explicitly removed from the current selection without deleting saved recipes or favorites.

[Named-source details](preview-availability-details-mobile.png) · [Preserved Sleep drawings with app-stream labels](preview-sleep-stream-labels-mobile.png). These are actual 390 × 844 independent HTML captures; Ocean Sleep is really playing in the second. No new Wind/Thunder recording, fallback, native binding, paid lock or entitlement was added.

**20 new browser cases** passed with the then-full **239/239 web + 41/41 Python suites**, no skips/failures. An additional **25/25 live checks** cover 320/390/431/823/1440px. The source/state engine, vector drawings and 148 protected native/media/catalog/player files are unchanged, apart from intentional browser UI guards and a source-naming diagnostic. [Detailed evidence](../docs/SIMPLE_LIBRARY_FLOW.md#browser-availability-follow-up).

## Ten requested one-tap mixes — current recipes

The ten featured chips now use **Rainy Window Café → Peaceful Ocean Journey**, in the user’s exact order and with the supplied main purposes and levels. Each uses 3–4 existing bundled sounds; the purpose and complete ingredient percentages appear when selected. Unselected layers immediately read 0%/off. Custom edits and Save do not mutate the original presets. Percentages need not add to 100%; the existing output limiter stays active without changing sliders. [All ten exact recipes](../docs/CURATED_SOUND_MIXES.md).

[Current paused Rainy Window Café capture](requested-curated-mixes-mobile-preview.png) is inspected independent HTML at **390 × 1100**, with the 65% / 25% / 15% / 10% selection retained after real playback and pause. All ten recipes played at **320 / 390 / 431 / 823 / 1440px**: **50/50 live recipe/viewport checks**, no page errors/overflow and 44px focusable chips. **22/22 recipe-browser cases**, **9/9 parity guards**, full **244/244 web + 41/41 Python**, and **147 protected hashes** pass. All media/catalog/source bindings, Sleep controls and existing inline audio/availability engines are unchanged; no linked stock artwork or new recordings were imported.

Matching Flutter source and **34 set-related native cases** (22 model/provider/controller + 12 widget; two newly added) remain **unexecuted** without the SDK. The [older Rainlit Cabin capture](vibe-sets-mobile-preview.png), 52–70% starting levels and 202-test set-batch evidence predate this requested replacement; they do not depict current presets. Eight legacy built-ins and existing saved snapshots remain intact.

## Current softer-surface rollout

The user reviewed the Home-first trial and approved extending it across all pages. These are fresh captures of that continuation, not older screenshots relabeled as a new build.

| View | Screenshot | What it shows |
| --- | --- | --- |
| Home — 390 × 920 | [Home](soft-surfaces-home-mobile-preview.png) | Approved matte dashboard with the cleaner shared footer |
| Sounds — 390 × 920 | [Sounds](soft-surfaces-sounds-mobile-preview.png) | Tonal track panels, filled master actions, selected underline and moving switch states |
| Sounds — 823 × 1568 | [Wider Sounds](soft-surfaces-sounds-preview.png) | Same surface treatment on the reference canvas |
| Meditate — 390 × 920 | [Meditate](soft-surfaces-meditate-mobile-preview.png) | Plain teal page, borderless daily/practice panels, inset arched artwork and intent selection |
| Sleep — 390 × 920 | [Sleep](soft-surfaces-sleep-mobile-preview.png) | Matte navy containers, moonlit art, four visible covers and the preferred five outline symbols/gold Thunder; no audio playing |
| Sleep — 823 × 1568 | [Wider Sleep](soft-surfaces-sleep-preview.png) | Navy surfaces and retained mixer drawings at the reference width |
| Your wellbeing — 390 × 920 | [Wellbeing](soft-surfaces-wellbeing-mobile-preview.png) | Filled panels and actual zero-data week, not sample progress |
| Breathing room — 390 × 920 | [Breathing](soft-surfaces-breathing-mobile-preview.png) | Matte timer panel, solid primary action, selected-choice underline and retained breathing geometry |
| Sound chooser — 390 × 920 | [Chooser](soft-surfaces-chooser-mobile-preview.png) | Flat rows, focused-input boundary and underlined Ocean Waves selection; no autoplay |
| Full player — 390 × 920 | [Player](soft-surfaces-player-mobile-preview.png) | Solid transport controls and option groups with retained backdrop, artwork and breathing rings; actual daily soundscape playback |

### What changed, and what did not

[Shared preview styles](preview/soft-surfaces.css) carry the Home palette across Sounds, Meditate, players/chooser, wellbeing, breathing, progress, reflection and backup; Sleep retains a separate matte navy palette. The installer’s shared CSS is also softer. Decorative card borders, gradients, inset shine, shadows and heading rules are removed. Tonal fills keep grouping legible. This is not a new layout or icon-family rollout.

Focus rings, 44px controls and non-color selected indicators remain. The five preferred outlined Sleep drawings, gold bolt, playback-driven glow, compact playlist artwork and pinned starfield are unchanged. Breathing/progress geometry, form boundaries and the native selected-plan outline are meaningful state/interaction cues and are retained. The four destinations stay **Home / Sounds / Meditate / Sleep**.

Flutter’s shared surfaces and local screen/player/utility decorations mirror this direction, including onboarding, subscription, review and CMS surfaces that have no independent HTML page. Five new Dart surface/contrast/widget regressions are authored and WASM-parsed/formatted, **not executed on Flutter**. The Home-only gate is superseded by the user’s approval; native verification is still open in the [active goals](../docs/PROJECT_GOALS.md#softer-surfaces-across-pages--implemented-native-verification-open).

At completion of the softer-surface batch, the full browser suite passed **180/180** and Python **41/41**. Live checks covered nine routes at 320/390/431/823/1440px with no page errors, document overflow, autoplay or sub-44px rendered enabled controls. Ten new rollout regressions check matte surfaces, normal-text contrast on solid fills, touch/focus/selection states, larger text and installation help. An audio-retry assertion now allows subsecond real-media progress after resume; strict paused-time, source and seek checks remain. Playback engines/handlers, source choices, audio files and icon geometry did not change in this styling batch.

The [original Home phone trial](home-soft-surfaces-mobile-preview.png), [original wider Home trial](home-soft-surfaces-preview.png), and earlier captures below remain historical evidence, not current native renders.

### Distinct ambient session audio

[The expanded player](session-soundscape-player-preview.png), [practice cards](session-soundscape-cards-preview.png) and [Nighttime Journeys](sleep-ambient-journeys-preview.png) now show actual ingredient names. **23 different two-source arrangements** replace the universal session sample; Home and Meditate share only the same daily practice. These are approximately 30-second loops of **14 existing recordings**, not full-length narration or 23 new field recordings. Missing audio shows an error without substituting another sample. [Recipes, verification and rights boundary](../docs/SESSION_AUDIO.md).

### Playback stability follow-up

The [active goals](../docs/PROJECT_GOALS.md) prioritize stability before a custom icon rollout. In the independent preview, Home/Sounds/Sleep and the mini-player now count only confirmed playing media. Loading is explicit and cancelable; failed or stream-only layers do not light the Sleep controls or pretend to play. Selections survive failures, and explicit retry keeps healthy loops and their positions. That first batch used a ten-second total load timeout (superseded by the progress-aware deadline above); cancelled/discarded media cannot revive later. Starting either audio mode also cancels the other's pending request. No source was substituted, no icon geometry changed and no native playback success is implied.

### Sleep visual correction

The user confirmed that the requested buttons are the **five round Sleep mixer controls**, not playback transport or the footer. [Close-up of the actual updated controls](sleep-mixer-buttons-preview.png): approximately 40px outline drawings inside 44px phone orbs, with the gold bolt and playback-driven mint glow. This is a browser capture, not a new Flutter build.

Sleep follows the first/preferred supplied reference, not a new redesign: large outlined Ocean/Rain/Wind/Nature symbols, a gold Thunder bolt, selected-layer mint glow, defined blue surfaces and four fully visible playlist covers at ordinary phone widths. The fifth playlist remains horizontally scrollable; narrower phones retain readable cover sizes. The HTML starfield now stays behind the scrolled content, matching Flutter's existing pinned backdrop. That symbol/playlist restoration was local to Sleep. The subsequently approved all-page surface pass changes its panel chrome, not those drawings or the **Home / Sounds / Meditate / Sleep** destinations.

The capture uses **Ocean Waves + Mountain Stream at 60% each**, genuinely playing local files. It does not invent the reference's Wind in Trees mix or 100% level. Wind/Thunder retain their existing stream bindings; the independent HTML preview only plays local sources and reports unavailable stream-only selections rather than substituting unrelated audio. In that historical capture batch, pause removed active highlights and the ambient mini-player without losing selected levels; the latest player update above deliberately retains a paused mini-player instead. The Flutter source has matching sizing/glow changes and authored regressions, but has not been compiled or captured in this sandbox.

### Wellbeing destinations

**Home → Your wellbeing** opens a coherent, solid-color hub. Separate pushed Flutter pages provide breathing, real weekly/session progress, local reflection and validated staged backup/restore. No extra footer tab is added. The old breathe-to-Meditate entry path is no longer used by these actions. The shell still has legacy enum aliases; this update is not a claim that every legacy/demo route has been audited.

The preview implements its own clearly labeled hub, breathing timer, progress and reflection at `#wellbeing/{hub,breathing,progress,reflection}`. Only breathing practices actually completed in that browser populate its history (`sanctuary.preview.breaths.v1`, capped at 100). It does not read Flutter data or fabricate sample sessions. Hiding the browser or leaving breathing pauses it; pattern/duration changes reset it. Reflection uses local text and truthfully reports clipboard denial.

The browser's `#wellbeing/backup` page is **layout-only** with a disabled copy action and explicit boundary notice. Actual backup and restore remain in Flutter with validation, review, separate confirmation and the existing schema. The install entry hides over wellbeing headers and the sound chooser independently from the full-screen player, without resetting installed/prompt state. Flutter's web implementation tracks visible page owners; native uses a no-op implementation. Fresh compiled-web execution remains unverified.

Progress no longer invents scores, mood or streak samples. Existing reminder preferences/services are preserved, but the old notification card is not part of the redesigned progress page; reminder permission/scheduling and replacement controls need a separate reviewed pass.

### Meditate cards and page color

The page is a **single solid teal color**, not a sunrise/forest wallpaper or page gradient. Photography is confined to inset arched card art, with orbital linework and intent accents. Today and three starters lead; Browse all retains 14 practices. All/Calm/Focus/Rest/Saved replace the six older intent chips without changing session IDs/intents. Begin/Pause, visible Save, options and copy remain. Options are visible buttons as well as long-press actions. Every card names its own ambient ingredients; disclosures identify repeating mixes of existing recordings, **not spoken guidance or verified frequency tuning**. The separate full-screen player's lake backdrop and Sleep's moonlit styling are retained.

### Sound covers and safe one-layer swaps

All 75 familiar cards and covers remain; Woodland Morning and Fireplace bring the catalog to **77**. The chooser now has **18 distinct local sources**, six legacy plus twelve additions: seven source-page-documented CC0/public-domain recordings and five generated noises. Search names/descriptions and view new-source credits. These are not alternate takes for every card or personal-file imports.

**⋯ → Change sound → explicit Preview → Use sound** preserves the selected layer's level, other layers, paused state, saved mix names and footer. Search/selection does not autoplay; aliases are blocked as duplicate sources. Current card-name coverage is **41 configured (18 local + 23 stream-only), 36 missing**. Configuration is not media-rights or device-playback clearance. See the [full inventory](../docs/SOUND_LIBRARY.md) and [recording-specific evidence](../docs/audio-licenses/ambient-pack-2026-11-19.md), including the unresolved birds Content ID risk and separate legacy rights review.

[Scrolled familiar covers](mixer-covers-mobile-preview.png) remain a useful earlier capture. The old six-choice screenshot is historical; use the current search capture above for the expanded library.

## Other retained page previews

| Page | 823 × 1568 | 390 × 844 |
| --- | --- | --- |
| Full-screen player | [Player](player-preview.png) | [Player — phone](player-mobile-preview.png) |
| Sleep | [Sleep](sleep-preview.png) | [Sleep — phone](sleep-mobile-preview.png) |
| Home | [Home](home-preview.png) | [Home — phone](home-mobile-preview.png) |
| Sounds | [Sounds](moonlit-mixer-preview.png) | [Sounds — phone](moonlit-mixer-mobile-preview.png) |

These earlier captures are retained, not relabeled as new renders. The player/Sleep captures show real local sample playback in the independent preview. The [install-help capture](pwa-install-preview.png) shows browser guidance, not an OS installation confirmation. Older `meditate-preview.png` / `meditate-mobile-preview.png` show the superseded wallpaper design, not the current page.

### Retained player / Sleep / Home behavior

- The full-screen player has lake-at-dawn artwork, breathing rings, countdown/seek, pause/resume, ±10 seconds, duration extension, loop, restart and completion. Loading/error states are retryable; minimizing retains a paused or playing session. Timed sessions do not imply individually narrated catalog content.
- Sleep keeps the moonlit ocean hero, timer, five distinct playlist mixes, eight ambient nighttime journeys, Favorites, continuation card and Customize link. **Ocean Sleep** selects ocean 70% + rain 30% with a 45-minute auto-fade. Continuation progress is labeled **Auto-fade** or **Level**, not made-up listening history. Individual story narration and downloads remain unavailable.
- Home remains a separate dashboard, not Sounds renamed. It shares actual selection/playback with the mixer. The footer stays **Home / Sounds / Meditate / Sleep** in that order, with local vector icons rather than icon-font dependencies.
- Artwork is bundled locally. Retained supplied-reference crops and older audio still need owner rights review; see [player provenance](../assets/images/player/README.md), [Sleep provenance](../assets/images/sleep/README.md) and [mixer provenance](../assets/images/mixer/README.md).

## Open the interactive preview

```sh
node tool/version_preview_assets.mjs
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

Stylesheet and script links carry SHA-256 content versions. Run the first command after editing preview assets; the browser regression suite checks the versions. An already-open tab still needs a reload. For a fresh Sleep document, open `/?ui=sleep-outline#sleep`. The current live sandbox server also sends `Cache-Control: no-store`. No storage-clearing or service-worker-reset code is used. A returning-browser regression first proves the old 23px CSS and renderer are cached, then verifies that the actual updated page bypasses them, uses the large outline buttons and preserves saved selections without autoplay. This protects against a stale-asset path; it does not establish what caused any particular user's old view. The install worker itself only caches the reconnect page, not UI assets.

Open Home by default, or `/#sounds`, `/#meditate`, `/#sleep`, `/#wellbeing/hub`. `design/preview/assets` links to the real bundled assets. Only local mixer sources play here; stream-only Flutter catalog cards are disclosed, not silently substituted.

The preview shares installer assets with the Flutter web source but uses its own **Sanctuary Design Preview** identity. Installing it does not install/validate Flutter, cache the full application/audio library or prove full offline support. See [PWA setup](../docs/PWA.md).

## Validation — 2026-11-19

- **244/244 repository browser/PWA/source-data/configuration tests passed**, zero failures/skips. Chromium actually decoded/played all 18 chooser sources and all 23 selected session arrangements, and all ten new live vibe sets, with exact routing/ingredient/volume checks, no-fallback errors, Home/Med identity and stale-media/retry regressions. Tests cover the new navigation, browser-only breathing completion/history, phase-preserving pause, background/tab exits, reflection clipboard denial, solid Meditate/filter/options behavior and chooser search/credits. Sleep checks include restored icon/orb proportions, playback-driven glow, four visible covers, access to the fifth playlist and the pinned starfield. Existing player/PWA/configuration regressions remain green.
- Responsive checks include 320/390/823px destinations, Sleep at the supplied 431px width and 1440px desktop, plus chooser landscape, footer reachability, long titles, reduced motion, actual install-entry visibility and vector icons when font requests fail. These are independent-browser checks, not compiled Flutter screenshots or accessibility certification.
- **41/41 Python tests passed.** All twelve source-pack additions passed manifest/hash/distinct-source/full-decode/non-silence/bounded-level checks. All 23 session arrangements passed hash/full-decode, measured stereo loudness/headroom and pairwise similarity-regression checks, and a scratch rebuild reproduced their hashes. No human listening, spectrum, sample-perfect loop, native interruptions or signed-device pass has been completed.
- Changed Dart files passed a WASM formatter/parser with the project's Dart language version. This is **not type analysis or compilation**. New Flutter regressions are authored but unexecuted because this sandbox has no Flutter/Dart SDK. Fresh Flutter analysis/tests/web/Android/iOS builds remain required.
- Historical [run 44483121445 at `d6447f6`](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44483121445) passed 260 Flutter tests and all four jobs, including unsigned native builds, **before this update**. It does not validate these new source changes, and unsigned CI is never store-release approval.

Reproduce browser checks with Node.js 22+, Playwright and Chromium:

```sh
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
```

`PLAYWRIGHT_MODULE` / `CHROMIUM_PATH` can use existing tools. With the pinned Flutter SDK, run `flutter analyze --no-fatal-infos`, `flutter test` and `flutter build web --release`; follow the [native runbook](../docs/NATIVE_RELEASE.md) for unsigned builds and owner-controlled signing gates.
