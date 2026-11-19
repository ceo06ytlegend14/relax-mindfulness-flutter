# Store billing boundary and release gates

Updated 2026-11-19. **New purchases are disabled by default.** No production store product, price, offer, account, live billing configuration or budget has been changed. This document is not approval to charge users or publish a monetized build.

## Implemented boundary — hosted verification pending

- `SubscriptionController` receives access from RevenueCat `CustomerInfo` and the configured **active entitlement**. A successful checkout callback alone grants nothing. SDK updates and restore results can grant **or revoke** access.
- `AppState` no longer reads local `is_premium` / `trial_active` flags to grant access. The no-argument local purchase/trial grant methods are removed. Old flags are ignored rather than imported, trusted or used to fabricate a new trial. Existing legitimate customers need their store account/restore path, not a local boolean.
- Trial status and expiry come from the entitlement. Expired/malformed dates and failed SDK verification deny access. Cancelling auto-renewal does not prematurely revoke an otherwise active paid period. Known SDK access can remain available offline only until its recorded expiry; refund synchronization depends on fresh SDK/store data, not an instant client guarantee.
- Store customer-info updates are observed, status refreshes on foreground return, duplicate operations are blocked, and a stale fetch/checkout response cannot overwrite a newer listener update. Listeners/timers are disposed with AppState.
- Paywall plans/prices come from the current store offering. Only matching monthly/annual subscription periods with finite positive prices and localized currency strings are offered. No hardcoded dollar prices, invented 7-day trial, savings percentage, narrated-story count, unlimited-AI claim or “forever” subscription promise remains.
- Purchase cancellation, pending payment, missing entitlement, unavailable setup and restore/network failure are distinct states. Private platform error payloads are not displayed. A restore error is not presented as “no previous purchase”. Unknown verification/active-access conflicts block another checkout and direct the user toward restore/support.
- Legal links actually launch the configured HTTPS pages and report launch failure. Store-provided management links are restricted to App Store/Google Play hosts. URL syntax checks **do not verify legal adequacy, ownership, reachability or approval** of those pages.
- RevenueCat is pinned to **purchases_flutter 10.19.1**, whose Android integration selects its **Billing Library 8** variant. This replaces 8.11.0's older native dependency line. Native dependency resolution, SDK migration and release behavior still need hosted/device verification.

The adapter enables RevenueCat's informational entitlement verification and rejects reported verification failures. This is **not a tamper-proof client or a new billing backend**. Any future paid cloud/AI endpoint must independently authenticate and authorize requests server-side using authoritative billing data; never accept this client's `hasFullAccess` boolean as proof.

## Build configuration (public values, not private credentials)

Use the owner's approved build process / a local file outside Git with `--dart-define-from-file`. Flutter does not automatically load `.env.example`.

| Setting | Meaning |
| --- | --- |
| `REVENUECAT_IOS_API_KEY` | Public iOS SDK key (`appl_…`), not a secret REST key. |
| `REVENUECAT_ANDROID_API_KEY` | Public Android SDK key (`goog_…`). Android is configured explicitly rather than being skipped. |
| `REVENUECAT_ENTITLEMENT_ID` | Existing configured access entitlement; defaults to `premium`. Confirm product mappings before changing it. |
| `ENABLE_STORE_PURCHASES` | Boolean; defaults to `false`. Enable only after owner approval and sandbox release gates. |
| `PRIVACY_POLICY_URL`, `TERMS_URL` | Working, owner-approved public HTTPS pages. Missing/invalid/placeholder values block new purchases. |

The legacy shared `REVENUECAT_API_KEY` is no longer used. Web and unsupported desktop clients never initialize this native billing path. Empty, secret-key-shaped or wrong-platform keys fail closed. Configured native clients can restore existing access even when **new purchases remain disabled**, or legal URLs are not yet configured. The default app contains no real SDK keys or legal URLs.

Signing passwords/keystores belong to the native signing process described in [NATIVE_RELEASE.md](NATIVE_RELEASE.md), **never Dart defines**. Never put a RevenueCat secret key or AI provider credential in a client build.

## Owner-controlled configuration and sandbox test matrix

Before allowing any monetized release:

1. Confirm the Android/iOS app records and existing bundle IDs. Confirm whether there are existing paid customers. Preserve their product IDs, access entitlement and restore/identity behavior. Decide what Premium actually includes; do not sell benefits that are missing or already presented as exclusive when they are free.
2. In the owner's store/RevenueCat accounts, confirm product/base-plan availability, regional prices/currencies, offering assignment, entitlement mapping, signing identities and required store API credentials. **No such account changes were performed by this pass.** Public SDK key configuration alone is not sufficient.
3. Provide real support, privacy and terms destinations and review the SDK's actual data collection/retention against store disclosures. A vendor policy is not a substitute for the app owner's policy.
4. In sandbox/internal builds, record exact build/OS/account/storefront and verify: fresh install, no entitlement, monthly/annual localization, full billing period disclosure, eligibility/not eligible for any offer, user cancellation, declined authentication, pending/parental approval, successful purchase, no-entitlement response, network failure, duplicate taps, foreground reconciliation, app restart/reinstall, restore, subscription expiration, cancellation while paid access remains, refund/revocation and billing grace periods. Use sandbox accounts only; no real charge is authorized here.
5. Verify failure/restore behavior on both stores, not just fake-gateway tests. Check merged Android billing metadata/dependency versions and signed-store upload validation. [Google's billing deprecation policy](https://developer.android.com/google/play/billing/deprecation-faq) must be rechecked before upload; [integration guidance](https://developer.android.com/google/play/billing/integrate) requires Billing Library 8+ for current submissions.
6. Only the owner can authorize enabling new sales in a signed release and submitting it. Passing unit/widget tests or an unsigned build does not do that.

Regression sources: `test/subscription_controller_test.dart`, `test/premium_screen_test.dart`, `test/support/billing_fixtures.dart`; they use inert fixtures, never a real store or payment. Full hosted execution is pending for this implementation. Keep the [launch checklist](LAUNCH_READINESS.md) as the overall go/no-go gate.
