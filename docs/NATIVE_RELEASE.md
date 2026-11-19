# Native build and release runbook

Updated 2026-11-19. These are preparation steps, **not permission to publish**. The repository owner controls the app, store accounts, identities, signing keys, products and final submission. Never paste signing passwords, private keys or account credentials into chat, source files committed to Git, CI logs or public issues.

## Evidence and current limits

The first hosted run ([603976a / run 44468832125](https://github.com/ceo06ytlegend14/relax-mindfulness-flutter/actions/runs/44468832125)) passed Flutter 3.32.8 analysis, formatting, release web compilation and 90 browser/config checks. **Flutter tests failed.** Native compilation was not run. Those results do not establish native release readiness.

The next toolchain is pinned to **Flutter 3.38.10 / Java 17 / Android API 36 / Xcode 26.3** in [quality.yml](../.github/workflows/quality.yml). Verification of this migration and its dependency-lock update is pending. All targets use the same Flutter version. Dependency drift is a failing gate, not an implicitly accepted update. Test failures are reported as escaped, bounded annotations; the original test/build exit codes remain failures.

CI compiles an Android debug APK, an explicitly unsigned release AAB and an unsigned iOS device build. It contains no production signing keys, uploads no app binary, has read-only repository permissions, and cannot submit to either store. A successful unsigned compile is **not** proof of installation, store approval, billing, audio reliability or device behavior.

### Store toolchain requirements checked 2026-11-19

- [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/): uploads require Xcode 26 or later with the iOS 26 SDK family; iOS/iPadOS deployment targets must be at least iOS 13. The existing project target remains iOS 13. A newer build SDK is different from the minimum device OS.
- [Google Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en): new phone/tablet apps and updates must target Android 16 / API 36. Android now explicitly compiles/targets 36 rather than inheriting an older Flutter default. AGP is 8.9.1, Gradle 8.12, and desugaring is enabled for notifications.
- The Android minimum is now **API 24 / Android 7.0**, matching the supported Flutter 3.38 baseline. This deliberately stops supporting older Android devices; verify the intended audience before release.
- Recheck store policies immediately before submission, including privacy manifests/required-reason APIs, billing SDK deadlines, 16 KB native-library support, age ratings and declarations. This page is not a substitute for the stores' upload validation.

## Preserve and confirm identities

| Platform | Existing identity | Display name |
| --- | --- | --- |
| Android | `com.sanctuary.relax_mindfulness` | Sanctuary |
| iOS | `com.sagozen.zennight` | Zen Night |

These IDs have **not** been changed or assumed to be published. The iOS name differs from the Sanctuary in-app branding. Confirm whether an existing App Store Connect record, TestFlight build, subscription or installed user base uses it before any rename. Changing an identifier can create a different app and disconnect purchases/upgrades. No development team is selected by this pass.

The iOS network policy no longer permits unrestricted remote HTTP. Only local networking is excepted for audio-proxy compatibility; catalog endpoints use HTTPS. The unimplemented background-fetch mode is removed; audio mode is retained. Actual background/lock-screen audio still needs device testing.

## Android release signing: fail closed by default

The release build **does not use the debug signing configuration**. It requires an existing owner-controlled upload keystore. If this app already exists in Play Console, use its correct upload identity—do not generate a replacement casually.

1. Store the keystore outside the repository with a separate encrypted backup.
2. Supply the following environment variables locally or through an approved secret manager:
   - `SANCTUARY_KEYSTORE_PATH`: absolute keystore path (or path relative to `android/`).
   - `SANCTUARY_KEYSTORE_PASSWORD`.
   - `SANCTUARY_KEY_ALIAS`.
   - `SANCTUARY_KEY_PASSWORD`.
3. Alternatively use **ignored** `android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Environment variables take precedence. Do not commit that file; `*.jks` and `*.keystore` are ignored too. Ignoring a file is not encryption or secure backup.
4. With the pinned Flutter SDK, resolve locked dependencies and run tests. Then build locally:

   ```sh
   flutter pub get --enforce-lockfile
   flutter analyze --no-fatal-infos
   flutter test
   flutter build appbundle --release --build-name=<release-version> --build-number=<unused-higher-build-number>
   ```

5. Inspect the release certificate against Play Console, package ID, merged manifest/API levels, native libraries/16 KB compatibility and final permissions. Exercise the **signed release**, not only a debug APK, on actual devices and an internal testing track after owner approval.

Without complete signing configuration, release tasks stop with guidance rather than silently debug-signing. Compilation-only CI explicitly sets `ORG_GRADLE_PROJECT_allowUnsignedRelease=true` (equivalent to Gradle `-PallowUnsignedRelease=true`). That produces an **unsigned, non-uploadable** AAB. This is not a production workaround and must never be described as a store-ready artifact.

## iOS signing and archive (owner-controlled Mac)

1. Install the pinned Flutter SDK, a supported Xcode 26+ and CocoaPods. Reproduce `flutter pub get --enforce-lockfile` and tests.
2. Open `ios/Runner.xcworkspace`, not the `.xcodeproj`. Confirm the existing bundle ID, chosen display name, capabilities, app icons and the owner's Apple development team. Keep signing certificates/private keys out of Git.
3. CI runs `flutter build ios --release --no-codesign --no-pub` for device architecture/plugin linking only. It is not a signed archive or installable IPA.
4. On the authorized signing machine, build an archive/IPA with the correct team, distribution method, release version and unused build number. Use Xcode Organizer validation before any owner-approved upload. Exercise that release on real iPhones/iPads and TestFlight, including interruptions, network loss, restore purchases, accessibility and upgrades.
5. Review App Store Connect privacy labels, applicable SDK privacy manifests, age rating, subscription disclosures, support URL and privacy-policy URL. Confirm all content redistribution rights before submission.

## Mandatory release gates still open

See [LAUNCH_READINESS.md](LAUNCH_READINESS.md) for billing entitlement security, AI credential/cost boundaries, content rights, privacy/support, reminders and the device test matrix. No account setup, production billing change, ad spend, store submission or public release is authorized or completed by these build checks.
