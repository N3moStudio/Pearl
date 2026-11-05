# Decisions and status

Date: November 4, 2026 (America/Los_Angeles).

## User decisions

1. Research photo cleaners widely across App Store apps, GitHub, open-source projects, and sideloadable IPAs.
2. Show existing-app screenshots and multiple original visual directions before building.
3. Produce the complete feature checklist and groundwork; do not implement the app yet.
4. Set up a local repository and make it available in GitHub Desktop using background operations.
5. Store the repository alongside existing GitHub repositories. Canonical path: `C:\Users\naith\Documents\GitHub\Photo Cleaner`.
6. Select Pearl's visual design.
7. Add local, lightweight grouping of very similar photos and videos to Pearl.

## Recovered reference

The loading orb is ThinkingOrbsKit, previously used by Elsepin. Current local Elsepin documentation and `project.yml` identify the native package and pinned revision:

[ThinkingOrbsKit, revision 54722cc9a3dcb167037f7d449d6cca4d174e9eb5](https://github.com/Jakubantalik/Libraries.dev/tree/54722cc9a3dcb167037f7d449d6cca4d174e9eb5/packages/thinking-orbs/ports/ios/ThinkingOrbsKit).

For this new app, it is a visual/dependency candidate only. No package has been added.

## Recommendations, still adjustable

- SwiftUI + PhotoKit; Vision image feature prints for similarity; AVFoundation for video work.
- Start with a new native app rather than adopting a complete cleaner fork. Evaluate bounded source references individually.
- Consider iOS 18 as the minimum, with native Liquid Glass on supported newer versions and a standard-material fallback. Confirm the user's device/OS before setting the build target.
- First useful version: year/month/media browsing, resumable review, album filing, safe removal, exact duplicates, and similar photos.
- Similar videos, OCR categories, and compression follow once the basic review and photo matching are trustworthy.
- No custom model download for initial similar-photo matching. Optional semantic search is a later decision.

## Open choices

- Final app name, icon, bundle identifier, and repository license.
- Exact iOS minimum and target devices.
- Whether to offer optional semantic search after measuring the native approach.
- Distribution/signing method when an IPA is ready.

These choices do not block the current research or repository setup.

## Completed in this phase

- Broad survey of 29 distinct products/projects, including 12 GitHub repositories.
- Inspected public repository metadata, README descriptions, license identifiers, and the newest three release records per repository where available.
- Verified StorageSaver v0.2.0 includes an unsigned IPA release asset; did not download, install, or audit the binary.
- Created three visual directions and a second Pearl board showing local similarity review.
- Wrote product plan, technical plan, feature backlog, design specification, and linked visual references.
- Initialized the local `main` branch. No remote or publication.
- Registered the canonical folder in GitHub Desktop's local repository list using a hidden, temporary instance. The registration transaction was verified; all five pre-existing repository records were unchanged by that transaction. No mouse/keyboard automation or foreground window was used. The temporary instance was closed afterward.

## Validation limits

Research is based on primary product pages, developer listings, public repositories, and Apple documentation. Vendor claims are not hands-on verification. No competitor app was installed or tested. No app source was written, compiled, or run. The concept images contain illustrative content and do not establish behavior or contrast compliance.
