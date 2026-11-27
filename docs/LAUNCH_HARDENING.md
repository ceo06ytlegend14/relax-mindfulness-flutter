# Launch hardening — current decision: blocked, not ready to publish

**Current development-audio checkpoint:** six separately inventoried loop edits of existing development recordings are now used by the mixer. The originals and all 23 session arrangements remain intact; no new takes, video downloads, rights clearance or release approval were added. Local suites pass **322/322 web + 93/93 Python**. Preflight matches **118 local media subjects (48 audio, 68 artwork/drawables, two fonts), 75 stream bindings and nine gates**, all pending: **BLOCKED / 202 pending**. Current runtime fingerprint: `fab4a4b07cfa5b34ea48a50a97fe10d21102dad59cc47bf8683f2b6a24773356`. [Development audio, processing and limits](PLACEHOLDER_AUDIO.md).

**Historical hosted verification:** [exact-source hosted build checks](release/BUILD_CHECKS.md) include **409 passing Flutter tests**, pinned analysis/formatting, web/Android/unsigned-iOS compilation and the browser job for an earlier source candidate. That candidate's fingerprint was `8b02ccfdc421379d35232d8e4809a1bdfc4c23396543a603b2f24a45f019bc62`; its then-current count was 196 pending. This predates the design/inline-toggle/loop-edit changes and does not validate this checkout. Fresh Flutter execution, signed devices and human listening remain open.

**Historical baseline below:** descriptions, test/protection counts and then-unexecuted statements in the original hardening pass describe that earlier checkpoint; the inventory table has been updated for the six pending derivatives. No old CI run or temporary-development permission completes a current review.

Updated 2026-11-19. This pass improves release safeguards; it does **not** add content, obtain media rights, authorize a beta/public launch, enable purchases, change store accounts/signing, or spend money. Custom icons and other new features are deferred while these gates are open.

## What changed

| Change | What it protects | Verification boundary |
| --- | --- | --- |
| Sounds keeps **Available (18)** as normal browsing. **Review unfinished catalog → Full catalog (77)** is now a deliberate disclosure, not a neighboring default chip. | Keeps the 77 stable identities recoverable without presenting them as 77 playable recordings. The review explains 18 bundled / 23 stream-only / 36 without recordings. | Independent HTML executed; corresponding Flutter widget code/regressions still require the SDK. |
| Non-bundled saved selections have an explicit review route. Closing review or returning to Available restores bundled browsing. | No migration/deletion of saved levels, favorites, eight legacy presets or customized mixes. Browsing never starts/stops audio, rewrites levels or changes gain. | Browser playback, storage, focus and large-text checks executed; native device behavior is not certified. |
| Native bundled-source loading no longer silently falls through to a similarly named remote recording. | A failed bundled file produces the existing retry/replacement state; retry loads that same asset. A common name is not proof of identical bytes, equivalent sound or rights. | Dart source and regressions authored/WASM-parsed, **not executed with Flutter**. Explicit stream-only names retain their configured CDN/raw transport; no source URL/binding is changed. |
| Added [launch evidence register](release/launch-review.json) and [offline preflight](../tool/launch_preflight.py). | Detects unreviewed shipped media, checksum/URL drift, stale candidate evidence and missing gates. No code license, source-page grant or old CI run automatically becomes approval. | Local inventory and negative fixtures executed. All real approval fields remain **pending**. |
| Package description now says timed **unguided** practices rather than claiming guided meditation/stories. | Aligns package metadata with the existing ambient arrangements and no-narration disclosure. | No dependency, entitlement, recipe or audio change. |

The original **18 canonical bundled sounds, 77 catalog entries, ten exact requested recipes, individual percentages, gain limiter, separate custom saves, four tabs, Sleep source bindings/drawings and all media bytes are retained**. This is not a new Free/Premium split. The ten requested recipes use only bundled sources; their levels still total 110–165% because they are independent controls, not proportions.

**Scope warning:** normal Sounds browsing is bundled-only; this does not make every legacy route offline or release-cleared. Native Sleep Wind/Thunder and older stream-dependent scenes/selections still use their original network bindings. The browser labels/preflights those sources rather than pretending to play them. Their rights, pinning and real-device behavior remain blockers below. No native Sleep timer bug is claimed fixed by this pass.

## Inventory: bytes and bindings, not cleared content

| Register scope | Count | Current approval state |
| --- | ---: | --- |
| Audio actually included by the directory asset declaration | **48 files** | Pending: 18 original mixer inputs + six loop-edit derivatives + 23 derived arrangements + the unused legacy `calm_guided.mp3`. Derivatives are not extra takes; hiding/unreferencing originals does not stop the directory from shipping them. |
| Flutter/native/web artwork and launch drawables | **68 files** | Pending: 66 image files + two Android drawable XML files. Generated/procedural artwork is not assumed cleared; retained reference-derived artwork needs permission. |
| Custom bundled fonts | **2 files** | SIL OFL texts are present; attribution/packaging review remains pending. SDK/dependency licensing is a separate native/privacy review. |
| Effective stream-only native name bindings | **75 names / 73 distinct URLs** | Pending/unpinned. Includes legacy names outside the 77-card catalog; not 75 additional catalog recordings. There are 86 declared stream bindings; the 11 whose names resolve to bundled assets are no longer network fallback attempts. |
| Required human/build/release gates | **9** | All pending. |

Within the visible 77-card catalog, the established source count remains **18 local + 23 configured stream-only + 36 missing**. The new broader binding inventory accounts for saved legacy names too. It does not download, enable or test these URLs.

The twelve-addition pack has [source-page/generation evidence](audio-licenses/ambient-pack-2026-11-19.md), not blanket release clearance. In particular, resolve the documented wood-thrush Content ID reports. The six original mixer clips and unused legacy session sample still lack recording-specific receipts. The 23 arrangements inherit their ingredient rights issues. Artwork readmes describe provenance, not permission to redistribute a supplied reference.

### Rights work the owner must complete

1. For each shipped recording/artwork/font, identify the exact file, author/provider, grant and permitted commercial redistribution/derivative use; retain attribution requirements and any claim resolution. Keep sensitive originals in owner-controlled storage and only non-sensitive summaries/durable references in the repository.
2. Review retained reference crops and branding/app icons individually. Owning a screenshot or the repository does not establish redistribution rights to its underlying artwork/audio.
3. Resolve unpinned remote content and rights before distribution. Current native streams use moving upstream/sample URLs; a measured duration or URL being reachable is not immutable content enforcement. Any pinning, removal, replacement or packaging change needs a separately reviewed change; none was silently done here.
4. Clear or deliberately exclude `calm_guided.mp3` from future packaging. It has **not** been deleted in this pass. If a file changes or is excluded, update the inventory deliberately and rerun the candidate checks; do not relabel an unknown file as another sound.

**No real register entry was marked approved or passed.** Pending can mean “owner review still required” even where a grant/procedural origin is documented; it does not assert that every generated file infringes rights.

## Run the gate

From the repository root, with Python 3.9+ and local Git:

```sh
# Full evidence accounting. CURRENT EXPECTED RESULT: BLOCKED, exit 1.
python3 tool/launch_preflight.py --json-output build/launch-preflight.json

# Coverage/drift only, used in read-only CI. Can exit 0 while launch is BLOCKED.
python3 tool/launch_preflight.py --inventory-only
```

| Exit | Meaning |
| --- | --- |
| `1` (default mode) | Inventory matches, but rights/stream/build/human evidence remains open. **Do not launch.** |
| `2` | Invalid evidence/schema, unsupported declaration, missing file, or checksum/URL/inventory drift. Fix and review, not bypass. |
| `0` with `--inventory-only` | Inventory coverage matches only. Output still says **BLOCKED**; not a release approval. |
| `0` in full mode | Every required evidence record matches its subject/candidate. Still only **evidence recorded for owner review**, not automated legal clearance or publishing authority. |

The tool only reads source/evidence and optionally writes a JSON report under ignored `build/`. It has no approve, download, signing, upload, checkout-enabling or deployment command. Existing CI adds the clearly labeled **inventory-only** check; routine development CI is not made to fail merely because launch is correctly blocked.

### Recording genuine evidence later

Do this **after** the owner/tester actually performs the review, never to make CI green:

- Each `review` starts as `{"status":"pending"}`. Asset/stream reviews may become `approved`; required gates may become `passed` only with `reviewed_by`, ISO `reviewed_on`, `evidence_path`, `evidence_sha256` and `subject_sha256`.
- `evidence_path` must be a nonempty repository-local, non-secret file outside build/cache/hidden paths. Its SHA-256 must match. Use a redacted factual summary with a durable owner-controlled reference when the original is private. Do not commit credentials, signing keys, personal account screenshots or secret URLs.
- For a local asset, `subject_sha256` is the reviewed row’s file checksum. For a stream, it is SHA-256 of `json.dumps({"name": ..., "url": ...}, sort_keys=True).encode()` using Python’s defaults; the configured content must also satisfy the tool’s immutable-URL rule. Merely supplying an approval for a moving `main`/Google sample URL does not clear it.
- For a gate, `subject_sha256` is the report’s **current runtime candidate fingerprint**. It hashes declared bundled files plus release runtime source/configuration; Git ignores keep machine-specific SDK/generated files out. Documentation/review files, tests, independent `design/preview`, build outputs and secrets are not runtime inputs. Record the Git revision, dirty-tree state, toolchain and signed binary checksums in the actual evidence too; the fingerprint does not prove how a binary was built.
- Any runtime input change invalidates prior candidate gate evidence. Changed files/URLs also fail inventory validation. Approvals are not cryptographic signatures or a substitute for competent human review; this is fail-closed accounting, not a legal or security certification.

## Next work, in order

1. **Rights/credential work:** owner resolves the receipts/claims above and confirms revocation/rotation plus usage review of the historical exposed credential. Never paste a replacement here.
2. **Review current automated evidence:** inspect the [exact-candidate hosted checks](release/BUILD_CHECKS.md), including full Flutter regressions and unsigned web/Android/iOS compilation, using the [native runbook](NATIVE_RELEASE.md). Rerun after any runtime/dependency/platform change. CI now supplies real SDK execution; it does not supply signing, installation, listening or approval of the review register. Historical CI run 44483121445 is not current evidence.
3. **Real devices and listening:** execute [the unfilled device/listening checklist](release/DEVICE_QA.md) on actual signed Android and iOS candidates. Record devices/OS/builds, failures and fixes. Listen to every mix and every independent loop join, particularly the ~15.7-second cafe and ~13.8-second breeze. No longer files are invented or required unless listening demonstrates a quality problem.
4. **Identity/privacy/support:** confirm existing store/customer history before touching **Android `com.sanctuary.relax_mindfulness`** or **iOS `com.sagozen.zennight` / Zen Night**. Owner supplies real legal/support destinations and data/SDK disclosures. Run signed install/upgrade, backup, notifications and accessibility checks too.
5. **Only then ask for a small invited beta decision:** purchases stay off; preserve existing entitlement restoration. Choose audience, distribution, candidate and rollback with the owner. No ads, public launch, signing/account changes, store submission or spending are authorized by this checklist.

## Executed evidence for this pass

- **256/256** browser/PWA/source/configuration tests passed, no failures/skips. This adds ten live-browser hardening cases and two source guards to the earlier 244 baseline. Includes exact ten recipes, eighteen local files, existing session audio, unsupported-source preflight, storage preservation, real media identity/gain retention, keyboard focus, and 1.6× text at 320/390/823px. It is independent HTML, not compiled Flutter.
- **71/71** Python tests passed, including 30 new offline preflight fixtures for stale/missing/forged/duplicate/path/URL/evidence cases, source fingerprint portability and read-only reporting. Existing audio/signing/artifact fixtures remain passing; fixtures are not new native build evidence.
- **40/40 live-review checks at that checkpoint** passed at 320/390/431/823/1440px, with exact local playback/gain/player/storage preservation and saved-selection recovery. Its inspected 390 × 1100 paused HTML capture remains in [pre-cleanup Git history](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/tree/cbaf083108a106dc7f6f6aeea17883c9b9890725/design), not the current tree or native-device evidence. See the separate [current four-tab gallery](../design/README.md).
- **159/159 protected pre-pass hashes** match, including all audio/artwork, exact recipe/catalog data, Sleep/player/controller/billing files that were out of scope. The intended native AppState source-selection branch and Sounds review UI changed; this is not a claim the entire playback implementation is unchanged.
- All 18 preview asset content versions, inline JavaScript syntax and patch whitespace checks pass. Three changed scoped Dart files are WASM format-stable; AppState is WASM-parsed with its legacy formatting retained.
- **Four new native regressions** are authored (two source-loading, two widget), an existing local-fallback case is rewritten for same-asset retry, and five existing widget paths now use explicit review. These and the other current native regressions remain **unexecuted** here.
- Full preflight deliberately reports **BLOCKED** with 112 local review records, 75 stream/pinning records and nine release gates open. Inventory-only passes without claiming launch readiness. No media was downloaded, added, replaced or approved; no commit, push, hosted native run, account change or release was performed in this pass.

Reproduce local checks with `npm run test:web`, `python3 -m unittest discover -s tool -p 'test_*.py' -v`, and `node tool/version_preview_assets.mjs --check`. The sandbox uses its existing Chromium/runtime paths for browser execution. [Launch readiness](LAUNCH_READINESS.md) remains the overall blocker ledger; [source-loop durations](SOUND_DURATIONS.md) remain measurements, not rights or listening certification.
