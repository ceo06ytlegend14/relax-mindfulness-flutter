# Sanctuary design preview

This folder contains the **working interactive HTML preview** and a small gallery of its current four tabs. It is not a second Flutter project or an installable iPhone build. Flutter app source remains in `lib/`, with its native projects in `ios/` and `android/`.

## Current visual target — no Install app button

Keep the owner-selected midnight-blue Home, compact art-first Meditate, preferred moonlit Sleep, inline Sounds controls and floating **Home / Sounds / Meditate / Sleep** footer. The shared controller no longer creates an in-page **Install app** entry.

| Current tab | Capture |
| --- | --- |
| Home | [Home — 418 × 885](home-no-install-mobile-preview.png) |
| Sounds | [Sounds — 418 × 885](sounds-no-install-mobile-preview.png) |
| Meditate | [Meditate — 418 × 885](meditate-no-install-mobile-preview.png) |
| Sleep | [Sleep — 418 × 885](sleep-no-install-mobile-preview.png) |

These are inspected **independent HTML / Chromium captures**, not compiled Flutter, device/store screenshots or recordings of physical audio. The ordinary tab captures have no audio playing; selected levels are not playback evidence. No activity/completion data was fabricated.

## Shared appearance and behavior

- Page **`#02132C`**, surface **`#122945`**, active surface **`#193853`**, controls **`#223F5C`**. Artwork stays inside its intended cards/player; the old Home/Sounds forest wallpaper is not the target.
- Floating navy footer in the same four-tab order, at most 520px wide, inset 16px on phones and lifted 12px above the system safe area. Keep non-color selection cues, visible focus and at least 44px navigation targets. The mini-player sits separately above it.
- Individual sound switches/sliders stay **on Sounds**. Reopen the full player deliberately through the mini-player; explicit whole-mix starts can expand it. Healthy audio, independent levels, pause state and scroll position are preserved. [Player contract](../docs/AMBIENT_PLAYER.md).
- Sounds opens with **18 bundled choices**; the unfinished 77-entry inventory needs deliberate review. No source substitution or invented alternate recording. [Library and chooser](../docs/SOUND_LIBRARY.md) · [ten exact recipes](../docs/CURATED_SOUND_MIXES.md).
- Meditate leads with today and three practices, visible Save/ingredients, five filters and Browse all 14. Session arrangements are source-labeled ambient loops, **not spoken guidance**. [Flow](../docs/SIMPLE_LIBRARY_FLOW.md) · [session audio](../docs/SESSION_AUDIO.md).
- Sleep retains its large outlined Ocean/Rain/Wind/Nature symbols, gold Thunder bolt, real-playback glow and moonlit art. Stream-only choices remain disclosed. No fabricated story narration or listening history.
- Wellbeing has separate breathing, progress, reflection and backup views. Browser history is local to this preview; browser backup is explicitly layout-only. Actual staged backup/restore remains native Flutter functionality.

## Source cleanup

The gallery now keeps **only four current tab captures** instead of 59 overlapping/historical screenshots. The 57 superseded PNGs are removed from the current tree, not erased from [the previous Git checkpoint](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design). Focused feature docs retain their historical measurements without presenting old screenshots as the current design.

The repository also removes nine undeclared Flutter-export leftovers and two unreferenced theme showcases. The native Neumorphism screen is still reachable from Sleep, so it is **not** deleted as if unused. Active app routes, canonical preview CSS/JS/HTML, every declared asset, source licences/provenance, native build identities, tests and CI remain intact.

A controlled **418 × 885 before/after cleanup comparison found zero changed pixels on each of all four tabs**. Another **24 tab/viewport checks** retained footer placement, ≥44px navigation targets and no overflow, page errors or failed asset responses. The existing healthy port-3000 process was reused, not restarted. These checks do not establish native or physical-audio behavior. [Build and release boundaries](../docs/release/BUILD_CHECKS.md).

## Open the interactive preview

```sh
node tool/version_preview_assets.mjs
python3 -m http.server 3000 --bind 0.0.0.0 --directory design/preview
```

Reuse an already healthy port-3000 server. Open Home at `/`, or use `/#sounds`, `/#meditate`, `/#sleep` and `/#wellbeing/hub`.

`design/preview/assets` links to the real bundled assets. Installer styles/controller, icons, favicon, reconnect worker and offline page also link to canonical `web/` files. **Preserve these symlinks**; do not create copied bundles to make the preview lighter.

Stylesheets/scripts carry content-version queries. Run the versioning command after editing preview CSS/JS and reload an open tab. The worker caches only its scoped reconnect page, not UI or audio; no storage-clearing/reset code is needed. The live sandbox preview sends `Cache-Control: no-store`. Browser-menu installation keeps the separate **Sanctuary Design Preview** identity; it is not installation of the Flutter app. [PWA setup](../docs/PWA.md).

## Verification

Fresh cleanup suites pass **326/326 web + 97/97 Python**, zero failures/skips. All 21 preview script/stylesheet versions, relative documentation targets and patch whitespace pass. The four source-hygiene cases were observed failing before cleanup; no existing regression was removed or skipped.

The pre-cleanup source was merged into `main` through [PR #1](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/pull/1) after both exact-head workflows passed all four jobs. The [main post-merge workflow](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/45795349126) also passed, including **429 Flutter tests, zero failed/skipped**. Those runs are not a fresh hosted verification of this later cleanup; see [the current evidence record](../docs/release/BUILD_CHECKS.md#source-cleanup--local-verification).

```sh
npm ci --ignore-scripts
npx playwright install --with-deps chromium
npm run test:web
python3 -m unittest discover -s tool -p 'test_*.py' -v
```

`PLAYWRIGHT_MODULE` / `CHROMIUM_PATH` can reuse existing tools. Source-hygiene regressions keep old build exports/showcases out, limit the gallery to the four current tabs and check relative documentation links. With Flutter **3.38.10**, run analysis/full tests/web compilation and the [native runbook](../docs/NATIVE_RELEASE.md) as well. Tests, captures and unsigned builds do not approve rights, purchases, signing, deployment or TestFlight/store distribution; **202 release reviews/gates remain pending**.
