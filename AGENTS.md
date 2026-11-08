# Photo Cleaner project instructions

## Current phase

Implementation authorized November 4, 2026: develop the Pearl app, local similar photo/video detection, and core cleanup features. Keep all code in this repository alongside the user's other repositories under `C:\Users\naith\Documents\GitHub`. Use background commands only.

The user's latest November 5, 2026 instruction authorizes private GitLab hosting, Codemagic cloud Mac builds, appropriate tests, and unsigned IPA delivery. Reuse this checkout; add/use the `gitlab` remote without duplicating the local project. GitHub is suspended: preserve its remote/history but do not contact it. Use CLI/API access only, with no browser automation or desktop control. Use the personal account's free `mac_mini_m2` allowance, check remaining minutes before dispatch, and never enable paid billing. Let Pearl queue behind Tendelm; do not modify Tendelm or cancel its build. Keep credentials outside the repository and never print tokens. Do not claim native build/test success for new source changes based on an older tested IPA.

## Accepted product decisions

- Pearl is the chosen visual direction. Preserve the bright, quiet, rounded look, sage accent, generous spacing, and low barrier to entry.
- Include on-device similar-photo grouping. Include conservative five-frame similar-video comparison, with its own validation and resource budget. Support user-initiated continued background processing and system Live Activity on iOS 26+, with durable recovery and honest fallback on older iOS or denied execution.
- Reuse the Thinking Orbs visual reference from Elsepin. It is a native library reference, not a reason to add a web runtime.
- No account, subscription, ad, or server dependency for core cleanup.
- Home, Clean Up, Albums are the main destinations. Home opens Swipe with month rows. Full-screen review uses Delete / Heart / Keep and direct drag feedback, following the November 4 screenshot references.
- No automatic deletion. Keep a reversible decision queue, a review step, and PhotoKit's system confirmation.
- Organize by media type, year, month, and optional day. Age alone is never evidence that a photo should be deleted.
- Use background commands for setup. Do not take control of the user's mouse, keyboard, or everyday browser.

## Engineering when implementation is authorized

Use the relevant installed Axiom topic router; Apple Design for HIG decisions; native finishing guidance for actual polish. Read only the relevant references. Do not copy web interaction APIs into SwiftUI.

Use native Apple frameworks where they meet requirements. Treat third-party code as a possible reference, not an approved dependency. Inspect its license, platform requirements, and behavior before reuse.

Validate changes at the right level. Static analysis and conceptual images do not prove device performance, battery use, photo permissions, iCloud behavior, deletion safety, or accessibility. Keep those limitations explicit.

Protect real personal media and signing credentials. No personal-photo fixtures in Git, logs, or remote services. Keep any temporary source downloads under ignored `research/evidence/`.

The active private remote is `https://gitlab.com/gajula.naithik/pearl.git`; the preserved GitHub remote is `N3moStudio/Pearl`. Keep the canonical local folder and GitHub Desktop registration. Do not make either repository public or publish a release without a request.

## IPA delivery

Latest scope (November 7, 2026): Native Settings Kit adoption and simulator validation only. Do not dispatch another IPA workflow or deliver a new IPA until explicitly requested again. The older tested IPA remains intact.

For appearance/settings work, read `UI/NativeSettingsKit/DESIGN.md` and `ADOPTION.md`. Preserve existing settings, storage, permissions and feature behavior; update `docs/SETTINGS-FEATURE-MAP.md` before moving controls. Use compact rounded presentation, grouped native rows, the larger appearance card and native navigation. Native compilation and screenshot/device checks are separate from portable validation. Pearl's host palette is retained through the kit's optional palette override. Theme changes must not recreate active work or navigation.

Place the actual latest tested Pearl IPA in `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Keep only the current delivered Pearl IPA there, replacing older Pearl versions after the new tested artifact is available. Leave the existing delivered IPA intact until the replacement passes tests and package verification, and leave other projects' IPAs alone. Deliver only the `.ipa`; do not add checksum sidecars, ZIP archives, logs, screenshots, or reports to that folder or Downloads. Keep any needed engineering evidence inside the repository instead. Keep delivery replies brief and omit checksum details unless requested.
