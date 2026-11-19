# Sanctuary design previews

These screenshots are from an **independent interactive browser design preview**, not a Flutter build or device capture. The corresponding native layouts are implemented in `lib/screens/` and `lib/components/guided_player.dart`.

| Page | Reference-width preview (823 × 1568) | Phone preview (390 × 844) |
| --- | --- | --- |
| Full-screen player | [Player](player-preview.png) | [Player — phone](player-mobile-preview.png) |
| Sleep | [Sleep](sleep-preview.png) | [Sleep — phone](sleep-mobile-preview.png) |
| Home | [Home](home-preview.png) | [Home — phone](home-mobile-preview.png) |
| Sounds | [Sounds](moonlit-mixer-preview.png) | [Sounds — phone](moonlit-mixer-mobile-preview.png) |
| Meditate | [Meditate](meditate-preview.png) | [Meditate — phone](meditate-mobile-preview.png) |

The player and Sleep captures were refreshed for the sunrise-lake / moonlit-blue update. They show real bundled audio playing in the independent preview, not a fabricated playback state. Home, Sounds and Meditate captures illustrate the preceding redesigns.

## Open the interactive design preview

The optional HTML/CSS/JavaScript preview is saved in `design/preview/`; its `assets` link points to the real bundled assets. It is separate from the Flutter runtime and does not replace native testing.

```sh
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

The served page opens Home. Choose any footer tab, or open `/#home`, `/#sounds`, `/#meditate`, or `/#sleep` directly. For the full-screen player, open Meditate and choose **Gentle Relief & Comfort**, or start Home's daily session. The browser demo plays available bundled samples; the full app uses AppState/just_audio.

## Sunrise-lake player and moonlit-blue Sleep

- **Full-screen player:** newly generated lake-at-dawn background, larger rounded meditation art, subtle breathing rings, prominent countdown, seek slider and time labels, mint transport, glass option chips, and an accessible completion card. Content scrolls on short displays or with longer text. Reduced-motion settings stop the breathing animation.
- **Functional controls:** pause retains the source position, countdown and open player; resume does not restart the session. The slider and ±10-second buttons seek the calming sample, wrapping its position while Loop is on. `+10 Min` extends both total and remaining time. Restart uses the selected/extended duration, never a hardcoded ten minutes. With Loop off, the description warns that playback stops when the source ends.
- **Shared state:** minimizing does not stop audio. A retained paused session can be reopened/resumed through the artwork mini-player or Home's daily action. Guided playback is not reported as an active ambient mixer. Starting either audio mode pauses the other through the existing shared flows.
- **Loading and failure:** loading has a visible state and disabled transport. Errors leave a retryable paused session, not a decorative live countdown. AppState now accepts an injected player/clock for regression tests and guards superseded requests. Existing local/CDN/raw source fallbacks remain. Completion records positive whole minutes of active session time; seeks, loading and pauses are not counted as listening. Platform interruption and race behavior still need native verification.
- **Sleep:** luminous moonlit-blue ocean hero, starry backdrop, higher-resolution campfire/rain art, glass timer and continuation cards, mint section markers, meaningful Ocean/Rain/Wind/Thunder/Nature vector symbols, and an artwork mini-player. The five playlist mixes, eight stories, persisted favorites, saved mixes, shared auto-fade timer and Customize link remain functional.
- **Honest capabilities:** this is timed calming audio, not new individual narration. No fictional playback speed, HD quality, downloads, previous/next catalog behavior or listening history was added. Continue Listening shows the current selection; its bar is labelled **Auto-fade** for elapsed timer time or **Level** for the selected volume.
- **Original navigation retained:** distinct Home, Sounds, Meditate and Sleep destinations keep the teal footer in that order. The reference-image footers were not adopted. New footer, player and Sleep mixer symbols do not depend on icon fonts.
- **Install control:** the full-screen Flutter JavaScript web player temporarily applies `html.sanctuary-player-expanded`, hiding the DOM install entry so it cannot cover Minimize. The class is released on minimize/completion/disposal without changing prompt or installed state. Native builds use a no-op conditional implementation. The independent preview exercises the same CSS contract; Flutter release web compilation passes, but browser execution of that compiled build still needs verification.

New artwork is bundled locally and compressed to WebP; the six new/replaced player/Sleep images total about 569 KiB. See [player provenance](../assets/images/player/README.md) and [Sleep provenance](../assets/images/sleep/README.md). Some retained catalog/story crops still come from an earlier supplied reference and need redistribution-rights confirmation before public release.

## Home and footer correction

- `HomeScreen` no longer returns `SoundsScreen`. Home is a separate teal dashboard with a time-of-day greeting, the catalog's daily meditation, quick links to Sounds/Meditate/Sleep, the actual shared soundscape selection, and the existing wellbeing dashboard. The full track list, categories, sliders, and save/share controls remain under **Sounds**.
- Neither page autoplays. Home's play/pause card shares `MixerController` with Sounds, including cached levels and named mixes; it does not invent history or create a second local mixer.
- All four Flutter footer icons use the local `SanctuaryIcon` CustomPainter, including active/inactive colors and mint glow. The exact font-loading failure on the reported device has not been reproduced here; removing icon-font dependencies avoids that failure mode.
- The independent browser preview uses inline SVG symbols. Its wellbeing link discloses that those tools run in Flutter rather than pretending the preview implements them.

## Existing Meditate / Sleep functionality

Meditate retains its sunrise/forest backdrop, bundled editorial serif typography, daily journey, six emotional-intent filters and 14 practices. Long-press a practice to begin, save/unsave or copy its details.

Ocean Sleep selects **Ocean Waves 70% + Soft Rain 30%** with a **45-minute** auto-fade timer. Each wind-down playlist selects its own tracks/duration rather than routing to Rainy Cabin. `My Stories` filters persisted favorites; `See All`, `Customize` and the existing Twilight controls route remain available. Story sessions still disclose the lack of individual narration/downloads.

## Installable preview

The preview shares the actual **Install app** control, worker and icons with the Flutter web source. Embedded previews explain how to open a top-level tab. Its manifest is explicitly named **Sanctuary Design Preview** with a separate identity; installing it does not install or validate Flutter. Installation does not download audio or enable full offline operation. See [PWA setup](../docs/PWA.md).

[Install-help preview](pwa-install-preview.png) shows guidance, not an OS installation confirmation.

## Validation (2026-11-19)

- **All 96 repository browser/PWA/source-configuration tests passed**, with no failures/skips, on 2026-11-19. This includes player/Sleep, Home/navigation, PWA/install-controller and expanded platform/billing/release-configuration guards. Those guards inspect source; they are not compilation evidence. See the [release-readiness plan](../docs/LAUNCH_READINESS.md).
- The new player/Sleep suite uses actual bundled HTMLAudio samples and a range-capable local server. It covers pause/resume/seek, duration extension/restart/loop, minimize/paused mini-player/Home resume, deadline completion, source failure/retry, loading cancellation, ambient exclusivity, auto-fade volume/expiry, stories/favorites and playlists. Virtual clocks are installed before application timers are created.
- Responsive checks cover 320/390/823/1440px widths, reachable completion controls, 44px transport targets, long titles, reduced motion, the real install entry's placement/visibility, and distinct painted SVG pixels while all font requests are blocked.
- The legacy independent-preview interaction runs also passed again: **20 Sounds + 32 Meditate/Sleep checks**. These and the repository browser tests are **not Flutter widget/native-build results**.
- All `lib/` and `test/` Dart files passed a tree-sitter syntax parse. Changed implementation/test sections were formatted; literal asset paths, JavaScript syntax checks and `git diff --check` passed. This is not Dart type analysis or compilation.
- Hosted Flutter regressions now **pass**: [332a3fd / run 44476084854](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44476084854) completed **218/218 tests with no failures/skips**. Guided session/player, Home, mixer, Sleep, reflection, backup and store-controller/widget tests are part of that real Flutter suite, not the independent preview tests.
- **All four jobs in that run are green**, including clean dependency locks, Flutter analysis/scoped formatting/release web compilation, the browser/Python job and **Android debug, R8-minified unsigned release and iOS unsigned release compilation**. Built-Android identity/API/Billing/16 KB alignment and negative signing-guard checks passed too. Flutter/Dart SDKs are unavailable in the local sandbox. No compiled Flutter/device screenshots, signed installs, real platform audio interruption results or actual home-screen installation evidence have been produced. All screenshots above remain independent HTML captures; a green workflow is not store-release approval.

Run the repository browser/PWA suites with Playwright/Chromium as described in [PWA checks](../docs/PWA.md#checks):

```sh
PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
CHROMIUM_PATH=/path/to/chromium \
  node --test --test-timeout=180000 test/web/*.mjs
```

With a project-compatible Flutter SDK:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
```
