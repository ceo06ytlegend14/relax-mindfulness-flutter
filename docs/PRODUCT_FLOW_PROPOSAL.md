# Simpler sound choices, Premium access and Meditate

Proposal dated 2026-11-19. **Library/Meditate first pass approved and implemented; commercial allocation is still a proposal, not an implemented access policy.** See [implemented behavior and verification](SIMPLE_LIBRARY_FLOW.md). No existing content has been locked, no new sound pack has been purchased/imported by this pass, and no purchases or checkout have been enabled.

## 1. What is actually in the app

- **18 distinct bundled mixer sources**, not 77 recordings. The catalog retains 77 cards; 23 are stream-only and 36 lack a source. Those are not automatically usable or cleared for a paid sound app.
- Soft Rain has **one bundled recording**. We do not have Light Rain #1 / #2 / #3 or a per-sound alternate-take system.
- Campfire and Fireplace are two genuinely different fire recordings. Forest Birds and Woodland Morning are two different bird/woodland recordings. Those can form the first related choices without relabeling duplicate audio.
- The **ten vibe sets** are saved recipes of existing sounds. The **23 session arrangements** are rendered two-source mixes, not 23 new source recordings or narrated practices.
- At review, the replacement sheet only swapped a layer for a different named sound. The first pass now labels that action Change sound and adds Choose recording for the genuine Fire/Birds pairs, retaining levels and duplicate-source guards. This is not an alternate-take library for every sound.
- The repository has a native billing controller and paywall screen. Public sound/session models do not yet carry a Free/Premium policy, and the normal library does not yet route locked content through that paywall. New sales remain disabled. The native billing path does not support browser checkout.

## 2. A simpler sound-choice flow

**Normal tap plays a sound; the volume slider stays on the card.** Do not make people open a replacement sheet to repair an ordinary listening choice.

1. Default browsing shows recordings that can actually play on the current platform. Preserve old IDs, Favorites, saved mixes and backup/share compatibility; do not delete old data. Keep unsupported legacy entries discoverable in a clearly labeled separate view.
2. Rename the current cross-sound action to **Change sound**. Its helper text says it changes this layer to a different sound and keeps its volume.
3. Offer **Choose recording** only when a family has at least two real, approved recordings. Start with Fire and Birds if useful. Rain remains a single recording until a second genuinely different take is acquired.
4. Future example, not current inventory: `Soft rain — Open air` (Free), `Soft rain — Window` (Premium), `Soft rain — Leaves` (Premium). Clear descriptive names are better than unexplained #1 / #2. Never manufacture a second recording by renaming an alias or changing volume.
5. Changing a recording preserves the layer level and the rest of the mix. Browsing does not autoplay; an explicit short Preview does. Keep the existing eight-second preview limit, duplicate-source checks and cancellation fences.

### Availability and access are different

| State | Display and behavior |
| --- | --- |
| Available + Free | Play / choose normally. |
| Available + Premium | Premium badge + lock; show the real recording and a short explicit preview, then an upgrade option. |
| No usable recording | Unavailable / Not available in this preview. Never use a paid lock or imply buying Premium will supply it. |
| Playback/network failure | Retry the selected recording; do not substitute unrelated audio or send the user to checkout as a repair. |

## 3. Proposed commercial packaging

**One Premium entitlement, with monthly and yearly billing for the same access.** No separate feature tiers, credits, or mandatory subscription to pause, adjust volume or use a timer.

Suggested future split, subject to owner approval, source-rights clearance and an existing-customer review:

| Free starter | Premium |
| --- | --- |
| Six sources: Soft Rain, Fireplace, Ocean Waves, Meadow Breeze, Pink Noise, Brown Noise | All 18 currently bundled sources that pass the release/rights review |
| Starter-mix allocation requires a fresh review: the former Rainlit Cabin / Moonlit Coast / Velvet Night examples were replaced by the user’s exact recipes | Any future allocation of the ten requested mixes remains proposed, not a current lock |
| Today's ambient practice | Full current Meditate and nighttime arrangement collections |
| Mix/adjust available sources, save mixes, timer and normal transport | Additional licensed recording choices when actually acquired, integrated and verified |

The subsequent [ten-preset recipe request](CURATED_SOUND_MIXES.md) changes featured recipes only, not commercial policy. All ten currently remain playable with their bundled ingredients. These are proposed product boundaries, not claims of exclusivity or an enabled paywall. Do not promise downloads, narration, thousands of sounds, tuned frequencies or recurring new releases that are not implemented/delivered. Existing recordings/artwork still require the reviews in [launch readiness](LAUNCH_READINESS.md). Check actual customer/product history before changing access; do not silently erase user mixes or take away purchased entitlements.

### One understandable unlock path

`Locked item → details / optional Preview → Unlock Premium → monthly or yearly offering → store confirmation → verified active entitlement → return to the requested item`

- Use localized prices and full billing periods from the real store offering. Do not invent a price, discount or free trial in the prototype.
- Closing, cancelling, pending payment or failure leaves the previous mix and levels unchanged. Never charge just because a locked item was tapped.
- Recheck access at playback/source selection, shared links and restored mixes, not only on the visible button. Restoring a saved mix is not proof of a purchase. Preserve the recipe even if some layers need access; never silently play a different mix.
- Keep Restore purchases, terms/privacy, management and clear error states. Unlock only on the billing SDK's active entitlement, never a local paid boolean or checkout success callback alone. Continue the existing stale-response/pending-payment safeguards.
- Only resume the requested item if the user still wants it when checkout finishes; do not let a late result interrupt a newer selection.
- For iOS/Android, build on the existing native billing controller. For website/PWA sales, first design separate checkout, identity and authoritative server-side access verification. The independent HTML preview is not a real store or a secure paid-content backend.

## 4. Meditate: fewer decisions, using existing audio

Keep the approved **plain teal page, inset artwork and four navigation destinations**. Use the supplied image as feature context, not an instruction to restore a full-page wallpaper or elaborate glass styling.

Suggested initial view:

```text
Meditate
Ambient practice · No spoken guidance

TODAY · 10 min
Calm Mountain Horizon
Mountain Stream + Meadow Breeze
[ Begin ]                              [ Save ]

[ All ] [ Calm ] [ Focus ] [ Rest ] [ Saved ]

Gentle Relief & Comfort       15 min
Bamboo Chimes + Soft Rain             [ Begin ]

Quiet Mind Sanctuary           8 min
Temple Bowl + Mountain Stream        [ Begin ]

Soft Body Rest & Ease         18 min
Ocean Waves + Pink Noise             [ Begin ]

[ Browse all practices ]
```

- These examples map to real current session assets. Shorter UI labels, if approved, must not break playback/favorite IDs or saved sessions.
- Feature three starters, with all existing practices reachable through Browse all and filters; do not delete the catalog.
- One main action per card, a visible Save action and one ingredients line. Avoid duplicate artwork-play and Begin controls, numbered eyebrow copy, long promotional descriptions and deep option menus for ordinary use.
- Keep pause/loading/error/minimize behavior and source labels. Disclose approximately 30-second repetition/no narration once in accessible session information; do not invent full-length guided recordings.
- A Calm/Focus/Rest filter is navigation language, not a claim of clinically proven effects or frequency tuning. Any Premium badge follows real approved content access, never a missing asset.

## 5. Where to get more recordings

**Recommended first target: 24–36 carefully selected, genuinely different ambient recordings, not a giant generic-effects archive.** Prioritize multiple rain, ocean, wind, forest, fire and stream takes. Keep creator, original page, exact grant, acquisition date, source/output hashes and any attribution with every file. Audition long loops, seams and levels before counting a take as ready.

- **Low-budget route: Freesound, filtered and individually checked for CC0.** Licenses vary per upload; CC BY needs attribution and NC is unsuitable for this paid product. A CC0 label does not establish that an uploader owns every recorded element or eliminate third-party claims. The official FAQ and moderator guidance distinguish these permissions. [7](https://freesound.org/forum/freesound-project/33514/) [Official FAQ](https://freesound.org/help/faq/#licenses)
- **Large professional catalog: BOOM ONE / BOOM Library.** Obtain a written developer-license quote for the exact paid ambient/mixer app before buying a standard pack. BOOM explicitly requires a developer license for audio apps; a normal media-production purchase is not permission to resell an audio product. [1](https://www.boomlibrary.com/support/faq/what-am-i-not-allowed-to-do-with-your-sounds/)
- **Large research/download pool: Sonniss GameAudioGDC archive.** The archive offers commercially usable media-production collections, but this does not automatically clear supplying their sounds as the main product of a paid sound mixer. Review the current agreement and request written app-specific permission where needed. Do not import the entire archive or assume edited versions evade its restrictions. [2](https://sonniss.com/gameaudiogdc/) [Current agreement](https://sonniss.com/gdc-bundle-license/)
- Commissioning a field recordist under a written commercial-app/streaming/offline agreement is another option when consistent alternate takes and clearer ownership are the priority. No commission, vendor contact or spending is authorized by this document.

**Recommendation:** source a small rights-documented set first; expand after listening/device checks. No pack has been acquired or declared release-cleared by this review.

## Suggested build order

1. **First pass implemented:** simplify available-sound browsing and Meditate without changing current access or playback identities. Approve the actual product split, target sales platform and legacy-customer treatment separately before gating content.
2. Build a clearly labeled, non-purchasing lock/paywall preview for review. Do not simulate a successful purchase or store an invented paid entitlement.
3. Wire approved access policy into native selection/playback and the existing billing controller; retain legacy customer access and backup identities.
4. Run current Flutter analysis/tests/builds and store sandbox purchase/restore/expiry/refund/cancellation tests on devices. Only then consider owner-approved enabling of new sales.

See [billing boundaries](BILLING.md), [current source inventory and ten recipes](SOUND_LIBRARY.md) and [session-audio boundaries](SESSION_AUDIO.md). This proposal changes no runtime, catalog, entitlement or payment configuration and adds no test-execution claims.
