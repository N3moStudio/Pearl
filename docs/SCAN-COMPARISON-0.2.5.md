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

Platform references: [Apple album subtypes](https://developer.apple.com/documentation/photos/phassetcollectionsubtype), [album changes](https://developer.apple.com/documentation/photos/phassetcollectionchangerequest).

Local checks: whitespace and build-script shell syntax pass. The portable Swift grammar parser accepts the other changed Swift files but flags Fingerprints.swift both at HEAD and after the change (its existing CPU-device pattern is unsupported by that parser). This is not a Swift compiler result; native compilation and tests are required below.
