# Simpler library and Meditate — first implementation

Updated: 2026-11-19. Implements the first, non-purchasing step of the approved [product-flow proposal](PRODUCT_FLOW_PROPOSAL.md). Both Flutter source and the independent HTML preview are updated. **Browser verification is not native verification.**

No new recording was acquired. No existing purchase/access policy was changed, no content was locked and no checkout was enabled. The proposed Free/Premium allocation remains a proposal, not a live entitlement policy.

## Sounds: choose playable sources first

The subsequent [launch-hardening pass](LAUNCH_HARDENING.md) hides the unfinished inventory behind explicit review and adds a saved-selection recovery action, without deleting entries or changing levels. The later [ambient-player/loop follow-up](AMBIENT_PLAYER.md) brings local checks to **283 web / 71 Python / 55 live-player checks**; native SDK/device/listening verification and all rights approvals remain open. Older screenshots below show the prior neighboring full-catalog chip, not the new deliberate review step.

| View | What is shown |
| --- | --- |
| **Available (18)** — default | The 18 canonical bundled sources. All starts selected as the category. Categories and curated presets are scoped to bundled content. |
| **Review unfinished catalog → Full catalog (77)** | Deliberate review path for all stable entries, not a neighboring normal-browsing option. Explains 18 bundled / 23 stream-only / 36 no-recording entries. Older curated presets remain alongside the ten requested sets. |

- Available contains the ten new bundled-source sets and the compatible older Zen Sanctuary recipe; Full catalog retains all 18 curated presets. User-saved mixes are never filtered out or rewritten.
- Scope/category/Favorites controls change only the view. They do not start or stop playback, change levels, rename sounds, delete favorites or alter saved mixes/backups/shared links. A hidden non-bundled selection gets a notice and stays selected at its original level.
- Browser stream-only cards say **“Streaming in app · not in this preview.”** Missing cards say **“No recording configured · unavailable.”** Inactive non-playable toggles are disabled; a previously selected unavailable layer can still be turned off. Flutter retains configured stream playback with a connection-required label and disables only entries with no configured source.
- Playback/network failures keep the existing explicit Retry path. A different sound is an optional deliberate change, not an automatic repair or a reason to buy Premium.
- Shuffle now chooses three different canonical bundled sources, not arbitrary missing cards or duplicate aliases. Existing level, gain, timer, readiness and mode-ownership safeguards remain.

## Different sound versus related recording

**Change sound** (the card’s three-dot button) offers all 18 bundled sources, with name/description search and source credits. It changes the layer to a different named sound.

**Choose recording (2)** appears only for these real families:

| Family | Existing recordings |
| --- | --- |
| Fire | Campfire · Fireplace |
| Birds | Forest Birds · Woodland Morning |

The two-choice sheet has no unnecessary search field. Family membership resolves native legacy aliases through their underlying asset; aliases do not become extra recordings. Soft Rain still has one bundled recording: there are **no Light Rain #1/#2 takes**.

For either action:

1. Opening, searching or selecting does not autoplay or change the mix.
2. **Preview** is explicit, limited to eight seconds and cancelable. Stop/close/background/failure/use restores gain; late requests cannot revive a canceled preview.
3. **Use sound / Use recording** preserves the layer’s level and the rest of the mix. A paused mix stays paused. Replacing an off layer selects the new source at 30%, as disclosed.
4. Existing targets and aliases sharing an already-selected source remain blocked as duplicates. Cached selections, share links and saved mixes use the real chosen name and existing formats.

## Meditate: today and three starters

The initial view is **today’s Calm Mountain Horizon** plus:

| Starter / stable ID | Duration | Actual ingredients |
| --- | ---: | --- |
| Gentle Relief & Comfort / `gentle-relief` | 15 min | Bamboo Chimes + Soft Rain |
| Quiet Mind Sanctuary / `quiet-mind` | 8 min | Temple Bowl + Mountain Stream |
| Soft Body Rest & Ease / `body-rest` | 18 min | Ocean Waves + Pink Noise |

Each compact card has title, duration, one ingredients line, Begin/Pause, a visible heart-shaped Save button and the retained options button. Numbered eyebrows and long promotional card descriptions are removed. Long-press/options still support save/unsave and copy details.

| Filter | Existing data it includes |
| --- | --- |
| All | Three starters initially; all 14 after Browse all |
| Calm | Comfort + Healing intents |
| Focus | Focus + Morning intents |
| Rest | Sleep intent |
| Saved | Saved entries in the 14-practice collection, using existing `meditation-…` favorite IDs |

**Browse all 14 practices** retains the full collection; **Show featured practices** returns to three. Today’s card remains above the filtered collection and keeps its own Save action. Filtering or saving never starts/stops the current session. Re-rendered playback buttons retain truthful Pause/Opening state; browser keyboard focus survives filter/save updates, including removing the last Saved card.

The page remains plain teal with inset arched artwork. **“Ambient practice · No spoken guidance”** is visible at the top. Source labels and approximately 30-second repetition/no-narration disclosure remain. These are the existing timed ambient arrangements, not new narrated recordings, verified-frequency treatments or medical claims. Home and Meditate still share the same daily audio identity.

## Verification and limits

The following records the completed first-pass baseline. The later [browser availability follow-up](#browser-availability-follow-up) passed 239/239 web + 41/41 Python without changing native source or media. The subsequent [user-specified ten-preset replacement](CURATED_SOUND_MIXES.md) now passes **244/244 web + 41/41 Python**, preserves this browsing/recording flow and all media, and deliberately changes the ten featured recipes plus their purpose/details presentation.

Executed locally for the first pass:

- **219/219 browser/PWA/source/configuration tests**, zero failures/skips. This includes all 18 chooser sources, all 23 session arrangements and all ten live sets with actual Chromium media playback, plus **15 new flow cases** and **two new family/filter parity guards**.
- **41/41 Python tests**, zero failures/skips, including current asset/provenance/recipe integrity guards. Audio was not regenerated in this pass; earlier decode/loudness/rebuild evidence remains separate in [session audio](SESSION_AUDIO.md).
- **40/40 additional live-preview checks** at 320 / 390 / 431 / 823 / 1440px: default/full scope, disabled unavailable controls, three starters/all 14, saving, no autoplay, 1.6× text, 44px key actions, no document overflow, preserved unlit Sleep controls and no page errors. These are not comprehensive accessibility certification.
- **93/93 protected-file hashes unchanged** from the first-pass baseline: sounds/manifests, artwork, native Sleep, AppState, recipe/session models, preview session/player engines and native billing/paywall. The inline ambient playback engine and Sleep handlers were not redesigned; their existing regression coverage still runs.
- All **18 preview CSS/JS content versions** verified; JavaScript syntax and `git diff --check` pass. Eleven touched Dart source/test files parse and are format-stable with the WASM formatter; the native icon enum was also checked for undefined references. **These checks do not analyze Dart types or compile Flutter.**

**16 new Flutter cases are authored but unexecuted** across `mixer_controller_test.dart`, `mixer_catalog_test.dart`, `session_soundscapes_test.dart`, `mixer_screen_test.dart` and `sanctuary_screen_test.dart`. They cover default/scoped catalogs, preserved legacy levels/saves/favorites, canonical shuffle, real recording families, practice filters/audio IDs, visible Save, full-catalog access, playback state and larger text. Existing affected UI assertions were updated to navigate the actual new controls rather than bypassing or dropping catalog/playback coverage.

Flutter/Dart are unavailable in this sandbox. Current Flutter analysis, full tests, web/Android/iOS builds and device/listening verification remain open; historical CI is not evidence for these changes. No commit, push, hosted workflow, signing, publishing, licence purchase or billing activation was performed for this pass.

### Reproduce

```sh
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
node tool/version_preview_assets.mjs --check
# On the pinned Flutter toolchain, still required:
flutter analyze --no-fatal-infos
flutter test
```

Local execution logs: `/tmp/arena-simple-flow-all-web-final.log`, `/tmp/arena-simple-flow-python-final.log`, `/tmp/arena-simple-flow-focused.log`. Ignored live-check evidence is in `build/simple-flow-live-check.json`; the protected baseline is `build/simple-flow-protected-before.json`. Temporary/build files may not persist across environments; the tests are the reproducible evidence.

### Visual review

[Simple Meditate](../design/simple-meditate-mobile-preview.png) · [Available library](../design/simple-library-mobile-preview.png) · [Two Fire recordings](../design/recording-choice-mobile-preview.png).

These are independent HTML renders, **not compiled Flutter or native-device screenshots**. The first two use a 390px-wide full-content viewport to show the page without repeating/overlaying the fixed footer; the chooser uses 390 × 844. Normal phone heights are exercised separately above. Existing four-tab navigation, matte surfaces, artwork and preferred Sleep controls are retained.

## Browser availability follow-up

A subsequent screenshot showed the generic “Some selected sounds cannot play in this browser preview” toast. The same message was reproduced by adding Sleep Wind to an already-playing Ocean mix: it selected the non-bundled Soothing Breeze stream, left only the ocean audible and then warned. Thunder and three old sleep scenes had the same availability mismatch; old presets and saved/cached mixes supplied further paths. The screenshot alone does not establish which control the user pressed.

The browser fix does not acquire a missing file, substitute rain for wind/thunder, clear storage or change a paid entitlement:

- Wind/Thunder and incompatible sleep/preset choices have visible **App stream / Unavailable** labels. Their configured source names and native bindings remain unchanged.
- Preflight occurs **before** selecting a mix, changing a timer or pausing another audio mode. This covers master/Home/Sleep transports, quick controls, scenes and their library dialog, curated/saved mixes, and indirect starts via Sounds switches/sliders. A recipe with a missing ingredient is not silently partially applied.
- Accessible details name each exact source and distinguish an app stream from **No recording configured**. Keep closes without side effects. Review opens the full catalog and focuses a known source; Browse available returns to the 18-source view without autoplay. No pending purchase, retry or deferred playback is attached to closing the dialog.
- Existing cached levels are not silently erased or relabeled. Where a missing legacy source is already selected, an optional **Remove from current mix** action explicitly sets only that current layer to zero, does not autoplay a paused mix, and leaves saved recipes/favorites/other levels intact. This also handles legacy names outside the visible card catalog.
- Ordinary runtime failures of real bundled files keep the existing source-specific retry, healthy-player continuity, gain and cancellation safeguards. The low-level missing-source diagnostic now names the actual source rather than “some selected sounds.”

**Executed evidence for the warning-fix batch (before the later preset replacement):**

- **20/20 new browser cases** in `test/web/preview_availability_browser_test.mjs`; the Wind discoverability case failed against the pre-fix UI before implementation. Existing Heavy Rain/stream-only assertions were updated to check preserved mix/timer/state rather than expecting an invalid selection to be applied.
- **239/239 full browser/PWA/source/configuration tests + 41/41 Python tests**, no failures/skips. Existing 18-source, 23-arrangement, ten-set, runtime-failure/retry/race/PWA coverage remains included.
- **25/25 additional live checks** at 320/390/431/823/1440px: named app-stream details, preserved active players/recipe/timer, blocked partial scene, 44px keyboard actions, no overflow/page errors and retained gold Thunder/outline drawings. Larger text, Escape/focus recovery, saved/cached identities, explicit current-only removal and alternate-mode preservation are also covered by the new suite.
- **148/148 protected files unchanged**: all native source, audio/artwork/fonts, source/recipe catalogs and preview session/player/chooser engines/styles. Existing nav/Sleep vector definitions and five quick-source bindings are byte-identical. The ambient readiness/ownership engine is byte-identical; the sync loop differs only at the named missing-source diagnostic. Browser intent/preflight/presentation code is deliberately changed.
- All **18 CSS/JS content versions**, JS/inline syntax and patch whitespace pass. No new Flutter/native execution, listening, signing, publishing, licence acquisition or billing activation is claimed. Prior native verification gates remain open.

[Source-detail capture](../design/preview-availability-details-mobile.png) · [Sleep app-stream labels](../design/preview-sleep-stream-labels-mobile.png). These are inspected 390 × 844 independent HTML screenshots, not native captures; the retained Ocean Sleep mix is actually playing in the labels capture.

Logs: `/tmp/arena-preview-availability-focused.log`, `/tmp/arena-preview-availability-all-web.log`, `/tmp/arena-preview-availability-python.log`. Ignored baseline/live evidence: `build/preview-availability-protected-before.json`, `build/preview-availability-live-check.json`. Reproduce with the existing full browser/Python commands or `node --test test/web/preview_availability_browser_test.mjs` with Playwright/Chromium installed. Temporary evidence may not persist; the test source does.

## Next commercial step — not implemented

Create a clearly labeled, non-purchasing unlock/paywall preview for review, then approve the actual access policy, target platform and legacy-customer treatment before wiring content gates. Native access must use verified billing entitlements; browser sales need real identity, checkout and authoritative server verification. Missing audio must never look Premium-locked. [Billing boundaries](BILLING.md) and [rights/device/release gates](LAUNCH_READINESS.md) remain in force.
