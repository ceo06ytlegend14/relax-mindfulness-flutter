# Manual backup and restore

## User flow

Open **Home → Your wellbeing → Backup & restore**. This leads to the native, solid-color backup page; the redesign does not change its schema or confirmation safeguards:

1. **Copy backup to clipboard** and save the text somewhere private. Success is shown only after the clipboard call succeeds.
2. Paste JSON and choose **Review backup**. Review does not change the profile.
3. Inspect the included categories/counts. Omitted categories will remain unchanged.
4. Choose **Restore reviewed backup**, then explicitly confirm **Replace reviewed data**. Cancel leaves the profile untouched. Editing the JSON invalidates the review.

The app does not upload a backup, send a feedback message or play audio during this flow. Other apps or browser extensions may have access to the clipboard. Backups may contain personal session titles and mood ratings; do not post them publicly or send them to support without reviewing them.

## Data and compatibility

Exports retain the existing **`2.0.0`** format: streaks, theme, library/sound favorites, saved mixes, preset names, up to the latest **500 sessions**, and reminder preferences. This is not a complete device archive. Wallpaper choice, recents, cached mixer levels and other non-exported settings are not transferred.

The validator supports that version and partial versionless legacy documents containing recognized fields. Unknown metadata is ignored, but an empty/unrecognized document or an unsupported explicit version is rejected. Imported history is ordered newest-first. Duplicate favorites are deduplicated in their existing order; duplicate session IDs are rejected rather than silently discarding records.

Imports do **not** grant premium/trial access, change billing records, import API keys, restore audio downloads, or transfer OS notification permission. Reminder preferences are persisted, but notification permission/scheduling must be checked separately on the destination device.

## Validation guarantees

`lib/models/user_backup.dart` validates the entire input before AppState assigns any imported category. Model conversion is staged too. A bad final session therefore cannot partially clear favorites, alter a streak or replace saved mixes. Validation failures do not write preferences or notify listeners. Review repeats at application time so changed current state cannot bypass the consistency checks. Restore is disabled until device preferences are available.

Validation includes:

- A **2 MiB UTF-8** input limit; the UI also bounds the text field.
- Typed, bounded nonnegative integer streaks and consistent current/longest streaks.
- Recognized themes; nonempty bounded names/IDs; boolean reminder preference and valid 24-hour time.
- Finite track levels in **0–1**, not strings, out-of-range values or infinity.
- Sessions with typed IDs, titles, categories, timestamps, whole-minute durations in **0–1440**, and mood ratings in **0–5** (omitted mood remains unrated).
- Collection limits: 10,000 entries per favorites category, 1,000 saved mixes/renamed entries, 200 tracks per mix and 5,000 imported sessions. Oversized inputs are rejected, not silently truncated. Export still intentionally includes only 500 session records.
- Immutable validated collections. Error notices/logs do not echo the backup payload.

**These are validation-atomic application updates, not a database transaction.** SharedPreferences still persists multiple keys using its existing asynchronous API. Disk failure, a crash during persistence, device loss, clearing browser storage or a compromised device are not protected by this change. No encrypted backup, automatic cloud sync or crash-safe journal has been added. Keep an independent copy; durable storage/backup migration remains a release decision.

## Verification

New Flutter suites:

- `test/user_backup_test.dart`: schema, legacy compatibility, invalid types/ranges, size/collection bounds, finite levels, duplicate IDs, immutable review data and excluded credential/billing metadata.
- `test/user_backup_state_test.dart`: no partial mutation/persistence on invalid input, side-effect-free review, replacement/preservation behavior, reminder persistence, rehydration, chronological history, early-restore protection and no autoplay/premium grant.
- `test/data_backup_screen_test.dart`: clipboard success/failure, review, cancellation, explicit confirmation, stale-review invalidation, private error text, readiness and narrow/large-text layouts.

**These suites are written but have not run in the current workspace because Flutter/Dart SDKs are unavailable.** Formatting and syntax parsing are not compilation. The quality workflow is configured to run real Flutter analysis/tests/builds once the changes are pushed; its results must be inspected before release. Browser preview tests do not exercise this native backup screen.
