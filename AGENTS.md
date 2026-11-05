# Photo Cleaner project instructions

## Current phase

Research, design, and repository setup only. The user explicitly asked not to build the app yet. A later request to set up the local repository does not itself approve app implementation. Keep future app code in this repository, alongside the user's other repositories under `C:\Users\naith\Documents\GitHub`.

## Accepted product decisions

- Pearl is the chosen visual direction. Preserve the bright, quiet, rounded look, sage accent, generous spacing, and low barrier to entry.
- Include on-device similar-photo grouping. Plan similar-video comparison as well, with its own validation and resource budget.
- Reuse the Thinking Orbs visual reference from Elsepin. It is a native library reference, not a reason to add a web runtime.
- No account, subscription, ad, or server dependency for core cleanup.
- Library, Clean Up, Albums are the proposed three main destinations. Keep deeper tools inside them.
- No automatic deletion. Keep a reversible decision queue, a review step, and PhotoKit's system confirmation.
- Organize by media type, year, month, and optional day. Age alone is never evidence that a photo should be deleted.
- Use background commands for setup. Do not take control of the user's mouse, keyboard, or everyday browser.

## Engineering when implementation is authorized

Use the relevant installed Axiom topic router; Apple Design for HIG decisions; native finishing guidance for actual polish. Read only the relevant references. Do not copy web interaction APIs into SwiftUI.

Use native Apple frameworks where they meet requirements. Treat third-party code as a possible reference, not an approved dependency. Inspect its license, platform requirements, and behavior before reuse.

Validate changes at the right level. Static analysis and conceptual images do not prove device performance, battery use, photo permissions, iCloud behavior, deletion safety, or accessibility. Keep those limitations explicit.

Protect real personal media and signing credentials. No personal-photo fixtures in Git, logs, or remote services. Keep any temporary source downloads under ignored `research/evidence/`.

Do not publish a GitHub repository, release, website, or IPA without a request to do so. The current repository is local only.
