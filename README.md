# Sanctuary — Relax & Mindfulness

A Flutter app for ambient sound mixing, timed calming sessions, breathing and sleep routines. **Home / Sounds / Meditate / Sleep** keep distinct screens and share playback state.

**Status: pre-release / launch blocked.** Stop adding features while rights, credentials, fresh native builds and human/device audio checks are open. The [launch-hardening handoff](docs/LAUNCH_HARDENING.md) includes the offline evidence gate and an unfilled [device/listening checklist](docs/release/DEVICE_QA.md); the [prioritized release plan](docs/LAUNCH_READINESS.md) remains the overall ledger. No release, sales activation or spending is authorized.

## Active project goals

[Tracked goals and acceptance checks](docs/PROJECT_GOALS.md): **launch hardening and the explicitly requested ambient-player/stutter correction; other features and custom icons deferred**. The newly approved player flow is documented below; earlier stability work remains separate from release approval. The first preview-stability batch now distinguishes confirmed playback from loading/failed selections, preserves healthy layers on retry and fences cancelled loads. Native source now also separates requested ambient levels from ready/playing state, keeps pending playback cancellable and adds per-layer retry without restarting healthy loops. Timer expiry no longer generates unsupported listening history. The 29 new readiness/controller/widget regressions and earlier native changes still require Flutter verification; they have not run in this sandbox. The four custom navigation icons are queued; existing layouts and preferred Sleep controls are unchanged.

After reviewing Home, the user approved the **softer treatment across all pages**. Matte teal/navy panels and solid actions now extend through Sounds, Meditate, Sleep, players/chooser, wellbeing tools and installation help. Focus rings, 44px controls and non-color selected cues remain; the preferred outlined Sleep drawings/gold Thunder and playback engines are untouched. [Sounds](design/soft-surfaces-sounds-mobile-preview.png) · [Meditate](design/soft-surfaces-meditate-mobile-preview.png) · [Sleep](design/soft-surfaces-sleep-mobile-preview.png) · [All current captures](design/README.md#current-softer-surface-rollout). These are independent HTML renders; matching Flutter styles and five additional surface/contrast/widget regressions are in source, **not native-verified**.

## Simpler library and Meditate

**Sounds** opens on **Available (18)**. The unfinished inventory is reachable only through **Review unfinished catalog → Full catalog (77)**, with explicit 18-local / 23-stream-only / 36-no-recording context. Saved non-bundled selections have a non-destructive review route. Stream-only/missing sources are labeled honestly; browsing never rewrites saved selections or starts playback. **Change sound** offers all 18 bundled sources; **Choose recording (2)** is limited to the real Fire and Birds pairs. There are no invented alternate rain takes.

**Meditate** starts with today and three compact practices, visible Save, ingredients, **All / Calm / Focus / Rest / Saved** and **Browse all 14 practices**. Playback identities, player behavior, matte styling, four tabs and preferred Sleep controls remain. No new locks or checkout were enabled. Browser app-stream choices now declare their limitation before playback; unavailable requests leave the current audio/timer intact and show exact source details rather than a vague toast. [Implemented behavior, checks and native limits](docs/SIMPLE_LIBRARY_FLOW.md) · [Meditate capture](design/simple-meditate-mobile-preview.png) · [Library capture](design/simple-library-mobile-preview.png) · [Recording chooser](design/recording-choice-mobile-preview.png). All captures are independent HTML, not native screenshots.

## Ten requested one-tap sound mixes

**Sounds → Curated one-tap mixes** now leads with **Rainy Window Café, Enchanted Forest Morning, Ocean Deep Sleep, Mountain Meditation, Cozy Fireplace Night, Tropical Rainforest, Zen Temple Sanctuary, Midnight Focus, Campfire Under Stars and Peaceful Ocean Journey**. These replace the preceding featured ten with the user’s exact names, main purposes and volume percentages. They use 3–4 layers from 15 existing bundled recordings; no sound files or stock images were added. [Exact recipes and behavior](docs/CURATED_SOUND_MIXES.md) · [Paused Rainy Window Café phone capture](design/requested-curated-mixes-mobile-preview.png).

One tap updates switches/sliders immediately and leaves every unselected sound off at 0%. Editing creates a custom selection; Save stores it separately without modifying the original preset. Percentages need not total 100%: requested totals are 110–165%, while existing master output gain/ducking/fade safeguards remain active without rewriting slider values. All 18 bundled sounds, 77 catalog cards, eight legacy presets, saved snapshots, share/backup formats, four tabs and Sleep controls remain. Matching Flutter source and **34 set-related native cases** (22 model/provider/controller + 12 widget) still need SDK/device verification; browser playback is not native verification.

## Full ambient player and loop continuity

Starting a mix now **automatically opens its full player** with the actual selected sounds, individual percentages and truthful per-layer status/retry. Minimize without stopping; tap the mini-player to reopen on any of the four tabs, even while paused. Full-player edits keep a paused mix paused, and Save makes a separate custom mix. Volume/timer refreshes now also preserve an interrupted browser clock; the matching native source retains platform pauses and failed-layer errors until an explicit transport/retry action (Flutter execution still pending). No fake narrated-session timeline is shown for continuous ambience. Flutter source mirrors this flow, but has not been compiled here.

The independent browser preview now decodes the same local MP3s into audio-clock loops instead of seeking/rebuffering a media element at each repeat. A measured 67-second forest run crossed eight loop boundaries on four unchanged nodes with **zero runtime rebuffer events**, versus eight before. A progressing-download deadline also replaces the old absolute ten-second timeout. This is **browser telemetry, not native/device or human-listening certification**; full-file decode can take longer initially on a slow connection. [Implementation, measured results and limits](docs/AMBIENT_PLAYER.md) · [Full player](design/ambient-player-mobile-preview.png) · [Minimized on Sleep](design/ambient-mini-player-mobile-preview.png).

## Wellbeing, Meditate and sound-library update

- **Home → Your wellbeing** now opens a solid-color hub with separate breathing, progress, reflection and backup pages. Progress uses recorded sessions, not sample history. Breathing has pattern/duration selection, pause/resume/reset and foreground safeguards.
- **Meditate** uses a plain teal background and inset arched artwork with orbital details. Today and three starters lead, with all 14 practices reachable through Browse all, five simple filters, Begin/Pause and visible Save/options. Each practice has its own source-labeled ambient mix, **not spoken guidance**. Full-player and Sleep artwork are separate and retained.
- **Distinct session audio:** 23 two-source arrangements cover the daily practice, 14 Meditate cards and eight nighttime journeys. No universal-sample fallback remains; missing content errors honestly. These are approximately 30-second repeating mixes of **14 existing recordings**, not new narrated works. Home and Meditate intentionally share the same daily practice. [Routes, ingredients, measurements and rebuild guide](docs/SESSION_AUDIO.md).
- **Sleep** restores the preferred larger outline mixer symbols, playback-driven mint glow, matte navy cards and compact four-cover phone layout. Moonlit artwork, playback bindings and the four-tab footer remain. [Updated browser capture](design/soft-surfaces-sleep-mobile-preview.png); compiled Flutter validation is still pending.
- All **75 familiar sound cards and covers remain**, joined by Woodland Morning and Fireplace: **77 cards** total. **⋯ → Change sound → explicit Preview → Use sound** now offers **18 distinct local sources**, with search and credits for the additions. Opening/searching/selecting never autoplays. Using a sound preserves that layer's level, other layers and the paused state; saved mixes keep the real chosen name.
- The **12 additions** are seven recordings with recording-specific CC0/public-domain source-page evidence, plus five generated noises. See the [audio manifest](assets/sounds/ambient_pack.json) and [licence/provenance evidence](docs/audio-licenses/ambient-pack-2026-11-19.md). These grants do not clear the six legacy clips or remote streams; owner/content review and a human listening pass remain necessary.
- Current configuration: **41 of 77 card names have a source — 18 bundled and 23 stream-only; 36 still need recordings.** This is not a count of cleared or device-verified recordings. Missing cards stay explicit rather than silently playing unrelated rain. Personal-file imports and alternate takes for every card are not implemented. [Full inventory and safeguards](docs/SOUND_LIBRARY.md).

## Run the Flutter app

Minimum **Flutter 3.32 / Dart 3.8**, matching `pubspec.lock`. Quality automation pins **Flutter 3.38.10**, Android API **36** / minimum **24**, Java **17** and **Xcode 26.3**. See the [native build runbook](docs/NATIVE_RELEASE.md).

```sh
flutter pub get --enforce-lockfile
flutter run
```

Core screens and bundled audio require no private API key. Reflection studio is an explicitly **local writing template**, not an AI/music service. The owner still needs to revoke/rotate a historically exposed provider credential.

**New subscription purchases are disabled by default.** Access/restore use SDK entitlements, never local premium/trial flags. The paywall uses real localized store offerings; see [billing configuration and sandbox gates](docs/BILLING.md). `.env.example` is guidance only, not automatically loaded by Flutter. The owner must supply approved platform-specific **public SDK keys**, legal URLs and explicit opt-in before new sales. Never compile a secret REST key, signing password or AI credential via Dart defines; client values are recoverable. No live billing changes or spending occurred.

## Quality checks and evidence

Current local checks after the ambient interruption-safety follow-up (2026-11-19): **289/289 browser/PWA/source-data/configuration tests** and **71/71 Python tests** pass, with no failures/skips. All 115 protected media/catalog/recipe/theme/Sleep/release-evidence hashes for this follow-up match. The original player batch passed **55/55 additional live-player checks**; those captures/checks and the earlier full decoding/hash/provenance/distinctness/bounded-level checks for all **12 new MP3s** were not rerun for this non-visual safety change. The browser suite actually plays all **18 chooser sources, 23 session mixes and ten new live vibe sets** in Chromium. The requested-preset follow-up passes 22 recipe-browser cases, nine parity/source guards, 50 live recipe/viewport checks and 147 protected-file hashes. Its independent recipe contract verifies the exact user names/purposes/levels. The original set batch added 19 browser playback/UI cases and three recipe-parity/source guards; the subsequent simplification adds 15 flow cases and two family/filter parity guards. The screenshot-warning follow-up adds 20 availability/preflight regressions, 25 live viewport checks and verifies 148 native/audio/artwork/catalog/player files unchanged. No new recordings or native changes were made for that browser fix. Forty additional live-preview checks cover five viewport widths, and 93 protected audio/artwork/engine/Sleep/billing files matched their pre-simplification hashes for that earlier pass. The 23 arrangements also passed full decode, measured loudness/headroom and pairwise similarity-regression checks; the latter is not a perceptual listening test. It also checks wellbeing routes, real browser-only breathing completion, pause/background behavior, filters, search, clipboard failure and responsive layouts. This does **not** prove human listening quality, seamless device looping or Flutter behavior.

Changed Dart files passed a WASM-based formatter/parser, **not Dart type analysis or compilation**. Flutter/Dart SDKs are unavailable in this sandbox; the new Flutter regressions (including 16 library/Meditate model/controller/widget cases) and web/Android/iOS compilation still need to run. The [historical green run at `d6447f6`](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44483121445) passed 260 Flutter tests and all four jobs, including unsigned native builds, **before this wellbeing/audio update**. Do not use it as evidence for the current changes.

The current hardening pass adds ten browser cases, two source guards and 30 Python fixtures. **159 protected hashes** match; bundled native failures now retry the same local asset instead of silently using an unreviewed network file (source implemented, Flutter execution pending). `python3 tool/launch_preflight.py` intentionally exits **1 / BLOCKED**: **112 shipped-media reviews, 75 effective legacy-inclusive stream bindings and nine release gates** remain pending. The CI inventory-only check can pass without approving launch. [What changed, evidence and next steps](docs/LAUNCH_HARDENING.md).

With the pinned Flutter SDK:

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build web --release
# Development smoke build, not a store release:
flutter build apk --debug
```

Development-only browser and Python checks:

```sh
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
python3 tool/verify_ambient_pack.py
# Optional full decode/level check with an installed FFmpeg:
python3 tool/verify_ambient_pack.py --ffmpeg /path/to/ffmpeg --report build/audio-qc.json
python3 tool/prepare_session_soundscapes.py --verify --ffmpeg /path/to/ffmpeg --report build/session-audio-qc.json
```

For checks without a browser download: `npm run test:pwa` and `npm run test:platform`. `PLAYWRIGHT_MODULE` and `CHROMIUM_PATH` can point to existing tools; see [PWA checks](docs/PWA.md#checks).

`.github/workflows/quality.yml` has read-only, SHA-pinned browser, Flutter, Android debug/unsigned release and unsigned iOS jobs. Failed tests/builds, lock drift and analyzer errors/warnings fail the job; stylistic infos are advisory. No workflow deploys, submits to stores, uploads an app binary, accesses production signing/billing secrets or launches ads. Android release signing fails closed without owner credentials or explicit compilation-only unsigned opt-in.

## Preview the design

```sh
node tool/version_preview_assets.mjs
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

Run the first command after editing preview CSS/JS so a returning browser loads fresh assets. Reload any already-open preview tab; see the [Sleep controls and cache-upgrade check](design/README.md#open-the-interactive-preview). Saved selections are not cleared.

[Current softer-surface page/player/chooser screenshots](design/README.md) are **independent HTML captures**, not compiled Flutter/device screenshots. The preview plays local samples and has its own PWA identity. Its breathing history belongs only to that browser; its backup page is **layout-only** and cannot access Flutter data.

## Backup and privacy

From **Home → Your wellbeing → Backup & restore**, copy a private JSON backup or stage an import for review and explicit replacement confirmation. Malformed input is validated before profile mutation; purchases, API keys and notification permissions do not transfer. Preferences and backups are not an encrypted vault or automatic cloud sync. See [backup guarantees and limits](docs/BACKUPS.md).

There is no verified feedback delivery endpoint. The former false “message received” control remains removed. The progress redesign does not configure notifications; existing reminder preferences/services are retained, but reminder controls and real permission/scheduling behavior need a separate reviewed pass.

## Installable web app

Sanctuary includes home-screen icons, standalone launch and an **Install app** control with browser-specific guidance. Serve a **built Flutter web app over HTTPS**. Installation does not download the full app or audio library for offline use. See [PWA installation/deployment](docs/PWA.md).
