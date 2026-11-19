# Sanctuary design previews

These screenshots are from an **independent interactive browser design preview**, not a Flutter build or device capture. The corresponding native layouts are implemented in `lib/screens/`.

| Page | Reference-width preview (823 × 1568) | Phone preview (390 × 844) |
| --- | --- | --- |
| Sounds / Home | [Sounds](moonlit-mixer-preview.png) | [Sounds — phone](moonlit-mixer-mobile-preview.png) |
| Meditate | [Meditate](meditate-preview.png) | [Meditate — phone](meditate-mobile-preview.png) |
| Sleep | [Sleep](sleep-preview.png) | [Sleep — phone](sleep-mobile-preview.png) |

## Open the interactive design preview

The optional HTML/CSS/JavaScript preview is saved in `design/preview/`; its `assets` link points to the real bundled assets. It is separate from the Flutter runtime and does not replace native testing.

```sh
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

Open the served page and choose Meditate or Sleep in the unchanged footer (or use `/#meditate` and `/#sleep`). The browser demo plays only available bundled audio samples; the full app uses AppState.

## Installable preview

The preview now exposes the same **Install app** control as the Flutter web source. When embedded, it explains how to open the page in a top-level tab. Its manifest is explicitly named **Sanctuary Design Preview** with its own app identity, so installing this demo is not confused with installing the Flutter app. Installation does not download the audio library or make the full app available offline. See [PWA setup](../docs/PWA.md).

[View the install-help preview](pwa-install-preview.png). This is the web app’s guidance dialog, not a native OS installation confirmation.

## Meditate and Sleep update

- **Navigation is unchanged:** Home, Sounds, Meditate, Sleep retain the existing teal footer. The footers in the new reference images were deliberately not adopted.
- Meditate uses a sunrise/forest background, bundled editorial serif typography, a daily journey, six emotional-intent filters, and the existing 14 practices. Long-press a practice to begin, save/unsave it, or copy its details.
- Sleep uses a moonlit navy/gold design, shared auto-fade timer, Ocean Sleep journey, real current-mix/timer information, five independently configured playlists, quick sound toggles, and the existing eight story entries. `My Stories` filters persisted favorites; `See All` and `Customize` are functional.
- Ocean Sleep now selects ocean and rain with a 45-minute auto-fade timer. Each playlist selects its own tracks and duration instead of routing every choice to Rainy Cabin.
- Continue Listening uses the shared mixer selection; it does not fabricate a previous listening position. With a timer, its bar represents elapsed timer time. Without one, the bar is explicitly labelled as the sound level.
- Story playback still uses the existing calming-audio engine. Individual story narration and downloads have **not** been added; the screen makes that limitation explicit. The existing Twilight controls route remains available.
- Artwork is local. Background landscapes were generated from the supplied visual direction; thumbnail/card crops come from the supplied references. See the artwork READMEs and bundled font licenses for provenance and redistribution considerations.

## Validation (2026-11-19)

- Independent browser preview: **32 Meditate/Sleep checks plus 20 existing Sounds checks passed**, including 320, 390, 823, and 1440px viewports, original footer order, local audio samples, session actions, filters, timer, per-playlist selections, mixer toggles, saving, and navigation. These are **not native Flutter results**.
- Changed/new Dart files passed a tree-sitter syntax parse. Redesigned implementation/test files passed the WASM Dart formatter checks; asset paths and `git diff --check` passed. These checks do not establish Dart type correctness or native runtime behavior.
- Added `test/sanctuary_screen_test.dart` (20 expanded widget cases), extending the platform-free fake used by the mixer tests. It covers both screens at three widths, larger text, real session arguments, filters, timer confirmation/cancellation, correct playlist mixes, quick toggles, continuation, navigation, and story favorites/playback.
- **Flutter and Dart SDKs are unavailable in the current workspace.** No Flutter analysis, widget-test execution, or native build was performed. Run the following with a project-compatible Flutter SDK before release:

```sh
flutter pub get
flutter analyze
flutter test test/mixer_controller_test.dart test/mixer_screen_test.dart test/sanctuary_screen_test.dart
flutter test test/app_flow_test.dart
```
