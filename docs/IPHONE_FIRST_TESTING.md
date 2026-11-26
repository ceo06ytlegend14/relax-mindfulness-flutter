# iPhone first: from this checkout to a real device test

Prepared 2026-11-19. **Route selected for preparation; no installable build or TestFlight invitation has been created.** The owner confirmed an iPhone only, no computer, an existing paid Apple Developer Program membership, and 10+ hours/week. Membership is owner-reported; team roles and signing access are not yet established. No new device or membership purchase is needed to assess this route.

## Do this first—on the iPhone

1. Open **https://appstoreconnect.apple.com/** in Safari and open **Apps**. Use Safari's Request Desktop Website option if the mobile layout hides controls.
2. Look for this project under **Zen Night**, **Sanctuary**, or another name. **Do not create, rename, delete, submit or upload anything yet.**
3. If the app is listed, open it and check **TestFlight** for existing build entries. Report the app name, whether builds are listed, and the **App Information / Bundle ID** if visible. Do not share passwords, 2FA codes, API keys, certificates or private account screenshots. A cropped app-name/Bundle-ID view is sufficient if needed; hide account/team/contact information.

Also useful later: **Settings → General → About → Model Name / iOS Version**. Those facts are still unknown; no current iPhone test has passed merely because hardware is available.

## What the repository actually has

| Item | Observed state |
| --- | --- |
| iOS display name | `Zen Night` in `ios/Runner/Info.plist`; the app's in-app branding is Sanctuary. |
| iOS bundle identifier | `com.sagozen.zennight` in all three Runner build configurations. This is a source value, not proof that the owner controls the Apple identifier or an existing app record. |
| App Store Connect / TestFlight | Owner reports an existing app record **with no TestFlight builds**, a **different Bundle ID** from `com.sagozen.zennight`, and an **Account Holder / Admin** role (the combined option selected; specific role not distinguished). No Apple account was accessed by this session. **Identity reconciliation is blocked:** request the exact app name and Bundle ID from App Information, then confirm intended app/ownership/history before any identity edit, signing setup or upload. Do not ask the owner to repeat the already-reported role. |
| Team/signing setup | No `DEVELOPMENT_TEAM` selected in the Xcode project; no authorized signing configuration supplied by this handoff. |
| Background audio configuration | `UIBackgroundModes` includes `audio`; AppState configures the music audio session. Configuration is not proof of background/lock-screen behavior. |
| Build environment here | Linux; no Flutter/Dart/Xcode SDK. A native iOS archive cannot be built or signed locally in this sandbox. |
| Existing hosted CI | `.github/workflows/quality.yml` has a macOS iOS job, pinned to Xcode 26.3 / Flutter 3.38.10. It runs `flutter build ios --release --no-codesign --no-pub`: **compilation only**, not an installable IPA or TestFlight upload. |
| Current candidate | Changes were uncommitted when this handoff was prepared. A local checkpoint commit does not verify this source; a workflow on an older remote commit does not test it either. Pushes, hosted jobs, signing and uploads still require owner approval; repository work stays on the current Arena branch. |
| Apple account access from this session | No supported App Store Connect connector was available in discovery. The assistant has not inspected or authenticated to the owner's Apple account. |

**Do not rename the app or bundle identifier to match the UI yet.** First check existing app records, customer history and ownership; a new identifier can create a separate app and disconnect upgrades or purchases. Paid membership alone does not prove the required team role, signing assets or identifier access.

## Recommended route—without owning a Mac

**Approved current source → hosted macOS quality build → owner-approved signing/archive → TestFlight processing → manually selected owner-only internal test → the iPhone.** The existing macOS CI is the starting point, not a completed signing/upload pipeline.

- **First verify the app record and account role.** Match the actual Apple record to the intended source identifier and existing customer history. Stop on a mismatch; don't invent an App Store Connect ID or create a replacement app automatically.
- **Approve and verify the exact source.** Obtain permission before committing/pushing the current snapshot or starting billable hosted jobs. Run fresh analysis/tests/native compilation for that source, not the historical green candidate. Check the toolchain against the actual iPhone OS and current Apple upload requirements before archiving.
- **Design secure signing with the owner.** An authorized team, distribution signing identity/provisioning and upload authentication are needed. An App Store Connect API key is not by itself a complete signing setup. Keep private keys/certificates in approved encrypted CI secrets/ephemeral runner storage—not chat, Git, logs or build artifacts. No certificate creation/revocation or profile change has been authorized. Exact configuration instructions come after the app/account checks, not speculative secret creation now.
- **Seek explicit owner-only upload approval.** Before sending any build to Apple, review content permissions, the credential incident, privacy/support, signing identity, version/build number and the exact private-testing scope. Inspect existing TestFlight automatic-distribution groups so an upload cannot unexpectedly notify other testers. This is a store upload even if it is not a public launch.
- **Prefer TestFlight Internal Only for the first approved candidate.** Apple documents that these builds are limited to internal testing and cannot be submitted to customers. Keep distribution manual and limited to the owner; do not create a public link or invite external testers. This is a proposed future configuration, **not a workflow already implemented or executed**. [Apple: Add internal testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)
- **Install through the official TestFlight app only after the build is processed and assigned.** Apple requires an uploaded eligible build and the appropriate app identifier in its provisioning profile. Membership, an unsigned `.app`, an HTML preview or a downloaded IPA alone does not complete that path. [Apple: TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)

No public App Store submission, external beta, purchases or new spend is authorized. Android checks remain open; there is no instruction to buy Android hardware. A separately approved owner-only validation install is preparation for device evidence, **not a passed device gate or permission to recruit the planned ten-person beta**. See the [full release boundary](LAUNCH_READINESS.md).

## First smoke test—only after the real candidate is installed

Record build/version, exact source, iPhone model, iOS version, route/headphones and actual results. Protect existing data; do not delete a previous install before the backup/upgrade path is reviewed.

1. Cold open: no autoplay; all four tabs work. On Sounds, enable a layer: remain on Sounds with the mini-player, not an automatic full-screen jump.
2. Listen to **Forest Birds** at a low comfortable level for at least three real minutes. Its current loop-edit placeholder is 24 seconds, not a long final recording. Note every harsh join, gap or intrusive repeat. Silence/failed playback is a failure, not a completed session.
3. Start **Rainy Window Café**: Soft Rain 65%, Coffee Shop 25%, Brown Noise 15%, Bamboo Chimes 10%. Intentional preset starts may expand. Minimize/reopen and pause/resume; retain independent levels without duplicate playback.
4. Test the shortest timer offered by the ambient player (currently **15 minutes**) through its fade and stop, then a separate real background/locked-screen run of **20+ minutes**. Note interruptions, stops, heat and unexpected restarts; a foreground timer test does not pass the background case.
5. Confirm new purchases remain off. Do not simulate a successful purchase or change existing entitlements.

This smoke test does not replace all mixes, offline behavior, calls/routes, accessibility, long listening, privacy/backup or other entries in the [unfilled signed-device worksheet](release/DEVICE_QA.md). **All device results remain NOT RUN.** Safari/Home Screen preview observations must be recorded separately from native TestFlight results.

[Native runbook](NATIVE_RELEASE.md) · [Working business plan](REVENUE_ROADMAP.md) · [Apple internal tester instructions](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)
