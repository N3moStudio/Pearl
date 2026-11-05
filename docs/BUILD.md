# Pearl 0.1.0 implementation

Authorized November 4, 2026. Canonical code: `C:\Users\naith\Documents\GitHub\Photo Cleaner`. Private remote: https://github.com/N3moStudio/Pearl. The existing GitHub Desktop registration is retained. No desktop input or browser control is required.

## Build

Requires macOS and Xcode 26+ (CI uses Xcode 27.1), Swift 6, XcodeGen. Deployment target iOS 18. Run `swift test`, then `bash scripts/build.sh`. Or dispatch **Build Pearl** in Actions with `tests_only: false`.

The build script generates an original Pearl icon and synthetic test media, generates the Xcode project, builds the device app, applies an ad-hoc integrity signature, constructs `Payload/Pearl.app`, builds for an iPhone simulator and executes UI tests. Test media is under ignored `build/fixtures`; it is never in the shipping app. Logs, screenshots, test results and the IPA are retained as private CI artifacts for seven days.

The IPA is for personal signing with a compatible sideloader such as SideStore or AltStore. The ad-hoc build signature is not an Apple device provisioning signature. Personal Apple signing/provisioning and installation happen through the user's chosen sideloader. No Apple credentials are bundled.

## Architecture

- `Sources/PearlCore`: platform-independent review decisions, protection/undo, candidate shortlisting, similarity gates and date grouping.
- `App/PearlModel.swift`: observable main-actor UI state and PhotoKit change refresh. `performChanges` receives explicit Sendable closures outside the UI actor.
- `App/Services/PhotoAccess.swift`: cancellable PhotoKit image/video bridges and album/library mutations. The legacy AVAsset bridge is narrowly immutable and has a single consumer per request.
- `App/Services/SimilarityScanner.swift`: background actor, incremental progress, cached fingerprints, conservative complete-link groups, cancellation and power gating.
- `App/Services/Fingerprints.swift`: Vision revision 2, oriented/downsampled images, streamed SHA-256 and five downsampled video frames (10/30/50/70/90%). No downloaded ML model.
- `App/Services/ReviewStore.swift`: atomic protected local review-state file in Application Support; revision ordering avoids older saves replacing newer decisions. Excluded from backups. Cache files live in Caches, with a 128 MiB / 6,000-entry pruning budget after each scan.
- `App/Views`: native SwiftUI tabs, adaptive sage/ivory surfaces, system navigation/materials, loading texture and pinned native ThinkingOrbsKit (MIT notices included).

## Matching semantics

Exact matching hashes the complete sole original resource of an eligible asset. Assets with multiple resources (Live Photos, RAW pairs, edited versions) are deliberately excluded. The result means byte-identical resources, not identical captions, dates, albums or other metadata.

Photo suggestions use Vision revision-2 distance ≤ 0.24 and require every member of an existing group to match the candidate. No transitive chains and no automatic keeper/deletion selection. The UI reports largest resolution as a factual hint, not a subjective quality claim.

Video suggestions require five frame distances ≤ 0.18, aspect difference ≤ 0.03 and duration difference ≤ the smaller of 0.5 seconds or 2%. Sound is not analyzed. These are **possible similar videos**, never proof that videos are interchangeable.

Candidate retrieval combines up to 32 recent shots within two minutes and bounded perceptual hash bands across dates. Each shortlist is bounded to 160; groups to 20. This avoids an all-pairs scan but can miss crops, heavy edits, trimmed clips, very large groups and some cross-date matches. Thresholds are initial conservative choices, not calibrated confidence percentages.

## Scope and remaining validation

This is the initial useful native build, not completion of every research idea. It includes the requested local video workflow now rather than deferring it to P1. Live Photos can be browsed and reviewed as stills; full motion playback, RAW/burst handling, compression, OCR, semantic search, byte-savings estimates, album pinning and export are later work.

Review decisions persist across launches. A restarted scan reuses valid fingerprints but rebuilds groups; it does not resume an exact scan cursor. Cache invalidation uses modification date and a schema/version pinned to Vision request revision 2. The cache may be purged by iOS. Scanning is foreground-only and uses available local resources unless the user enables iCloud downloads. An unavailable item is counted rather than treated as a non-match.

Core tests cover reversible choices, favorites/protected items, stale IDs, deletion completion, persistence round trips, complete-link distances, five-frame/duration gates, cross-date candidates and shortlist bounds. CI also mutates the favorite guard and requires the relevant test to fail before restoring the original source.

Simulator UI tests use synthetic photos and re-encoded videos to exercise browsing, queue/undo, local scanning and unselected comparison groups. They do not prove real-library precision, physical-device battery/memory behavior, iCloud edge cases, Apple signing, or every accessibility setting. These remain device acceptance checks.

## Source review

Main-agent review covers deletion authorization, live favorite checks, original-resource identity, privacy, cancellation, actor isolation, bounded image work, UI state and failure reporting. One bounded free supporting review inspected the scanner and rules. Its suggested changes were checked against source and rejected: the cache guard already retries missing digests with network enabled, pruning already handles missing directories, hash-band keys intentionally include band identity, incomplete fingerprints must not form a group, and exactly five video frames is intentional. No unsupported reviewer suggestion was applied.
