# Direct comparison and scan coverage

Scope: local photo comparison, broader candidate retrieval, honest coverage and retry of unchecked work; GitHub Actions native tests and verified IPA delivery. No personal-photo uploads, external AI service, new model download, automatic removal or compression.

Starting point: 0.2.4 (7), clean tree. Existing app-owned background scanner, pause/recovery, saved review decisions, favorites/protection and PhotoKit confirmation remain. The Codebase Memory index refreshed; subsequent graph calls lost transport, so affected source is read directly (including partially parsed Fingerprints.swift).

Feature map before changes:
- Media grids retain browse/review, selection, album filing and staging. Two selected photos gain a pushed Compare action. Smart Cleanup gains a direct entry to choose two photos.
- Direct comparison uses a view-owned cancellable task and existing native PhotoKit/Vision/CryptoKit helpers. It never writes the scan checkpoint or review decisions by itself. Original-byte verification and visual similarity are distinct outcomes; Live/edited multi-resource assets are not labeled exact.
- Scan metadata remains in scan-v1.plist; optional failure reasons decode old records without a migration. Matching revision increments, reusing fingerprints/digests while invalidating old similarity comparisons.
- The shortlist probes one-bit differences in each hash band, retaining the bounded candidate count and strict final photo/video thresholds. This improves retrieval coverage, not a claim of measured real-library recall.
- Coverage shows analyzed, reused, download-required, other unavailable and pending work. Retry retains successful records/results and retries failed or unattempted work plus failed original verification. iCloud downloads remain opt-in through Apple; matching stays local.

Acceptance: unit cases for scattered-bit candidates/bounded shortlist, checkpoint compatibility and retry preservation; native comparison/queue UI flow, native Vision fixture accuracy, main and narrow-phone suites, unsigned arm64 package verification. Real-device large-library accuracy, PhotoKit/iCloud failures, background grants, heat/power and interruption behavior remain separate acceptance.

## Album organization follow-up

- Albums gains Not in an album with visible All / Photos / Videos filters. It subtracts personal/synced album membership from accessible media, excluding automatic smart categories and shared streams. Limited access shows an explanation instead of a misleading empty membership result.
- Existing real PhotoKit album filing remains in the grid selection toolbar. The picker now creates-and-adds in one Photos transaction, preserves selection on cancellation/errors, shows failures inline, and refreshes membership after success. It never duplicates or removes an original.
- Favorite albums and drag order live in `pearl.albums.favorites` and `pearl.albums.order` in UserDefaults. Favorites appear first, with manual order within each group, consistently in Albums and the picker. Temporarily inaccessible IDs are retained. Photos' own album order and photo-favorite state are unchanged.
- Native tests cover real album create/add/membership, failed selections, preference persistence, filters, cancellation and create-from-picker. Physical-device album permission changes remain pending.
- Swipe follow-up: a compact album action in the review header opens the same real album picker for the current item. Its copy explicitly says adding keeps the item and continues. Only successful filing records Keep and advances; cancellation/failure preserves the current photo. Delete / Heart / Keep remain the three main actions. Review undo changes the review decision, not the album membership.
- The unfiled grid gains Start swiping for its active All / Photos / Videos filter, starting at the first unfiled item even if it was previously reviewed. Swipe's horizontal category list also links to this filter screen. The active session stays stable when album membership refreshes.

Platform references: [Apple album subtypes](https://developer.apple.com/documentation/photos/phassetcollectionsubtype), [album changes](https://developer.apple.com/documentation/photos/phassetcollectionchangerequest).

Local checks: whitespace and build-script shell syntax pass. The portable Swift grammar parser accepts the other changed Swift files but flags Fingerprints.swift both at HEAD and after the change (its existing CPU-device pattern is unsupported by that parser). This is not a Swift compiler result; native compilation and tests are required below.

Native setup findings: the unit host initially lacked Photos access; repeatedly changing simulator privacy while tests ran killed the host and the first UI launches. That workaround was removed. Real create/add/membership and exact-original comparison checks now run through UI automation after the real permission flow. Preference persistence, unavailable comparisons and changed-selection rejection remain unit checks. The UI integration checks assert both removal from the unfiled view and two-item membership in the actual Photos album; comparison selects named synthetic original/copy fixtures and requires Exact copies. Fixture names are exposed only under a debug launch argument and are compiled out of the IPA.

## Verified build and delivery

- GitHub Actions [43689373814](https://github.com/N3moStudio/Pearl/actions/runs/43689373814) succeeded for source `5d17fb518ba1e5ce8231cff1395f42c836015c48` on November 15, 2026 UTC. No GitHub release was published. Subsequent changes to this report do not change the tested implementation.
- Passed: 28 core tests, three native Mac Vision fixture comparisons, both mutation guards, 11 iOS unit tests, 14 main iPhone UI tests and two additional iPhone SE UI executions. Native simulator and unsigned arm64 Release builds succeeded. The only build warning was skipped App Intents metadata extraction because the app has no App Intents dependency.
- Inspected native screenshots for direct comparison (verified exact copies), complete coverage counters, unfiled media, album order, in-swipe filing, and narrow-screen maximum accessibility text. The large-text settings remain scrollable; wrapped labels are preserved rather than clipped. Synthetic fixtures establish these paths, not recall or precision on a personal library.
- Downloaded artifact `14152053594`. Independently verified `Pearl-0.2.5.ipa`: version 0.2.5, build 8, 1,858,168 bytes, arm64, unsigned, expected bundle/background identifiers, privacy manifest and third-party notices, with no signing material or test fixtures. Evidence, screenshots and package verification are retained under ignored `.build/github-43689373814/`.
- Delivered and reverified: `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Pearl-0.2.5.ipa`. Removed only Pearl 0.2.4 after the new copy passed verification; other projects were untouched. Only the IPA was placed in the delivery folder.
- Still unverified on a physical phone: sideload signing/launch, personal-library match accuracy at scale, actual iCloud/network failures, changing Photos permissions, background execution grants, heat/battery and interruption behavior.
