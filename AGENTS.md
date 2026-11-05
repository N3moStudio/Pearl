# Photo Cleaner project instructions

## Current phase

Implementation authorized November 4, 2026: develop the Pearl app, local similar photo/video detection, and core cleanup features. Keep all code in this repository alongside the user's other repositories under `C:\Users\naith\Documents\GitHub`. Use background commands only.

The user's November 5, 2026 instruction supersedes the earlier automatic build/delivery workflow: make requested changes locally, complete applicable pre-build review and static checks, then stop before starting a build. Do not compile/package an IPA, start CI, push, fetch, or contact GitHub/Codemagic unless the user explicitly authorizes that later. The user reports their GitHub account is unavailable. Local commits are allowed; preserve the existing remote configuration and local history. Do not claim native build/test success for new source changes based on the older tested IPA.

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

The existing private remote is `N3moStudio/Pearl`. Preserve it, the canonical local folder and GitHub Desktop registration. Remote operations and builds are paused under the current instruction above. Do not make the repository public or publish a release without a request.

## IPA delivery

If the user later authorizes building and delivery, place the actual latest tested Pearl IPA in `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Keep only the current delivered Pearl IPA there, replacing older Pearl versions after the new tested artifact is available. Leave the existing delivered IPA intact while working only on local source, and leave other projects' IPAs alone. Deliver only the `.ipa`; do not add checksum sidecars, ZIP archives, logs, screenshots, or reports to that folder or Downloads. Keep any needed engineering evidence inside the repository instead. Keep delivery replies brief and omit checksum details unless requested.
