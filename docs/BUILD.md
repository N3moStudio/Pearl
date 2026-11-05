# Pearl 0.2.0 implementation

Authorized November 4, 2026. Canonical code: `C:\Users\naith\Documents\GitHub\Photo Cleaner`. Private remote: https://github.com/N3moStudio/Pearl. The existing GitHub Desktop registration is retained. No desktop input or browser control is required.

## Build

Requires macOS and Xcode 26+ (CI uses Xcode 27.1), Swift 6, XcodeGen. Deployment target iOS 18. Run `swift test`, then `bash scripts/build.sh`. Or dispatch **Build Pearl** in Actions with `tests_only: false`.

The build script generates an original Pearl icon and synthetic test media, generates the Xcode project, builds the device app, applies an ad-hoc integrity signature, constructs `Payload/Pearl.app`, builds for an iPhone simulator and executes UI tests. Test media is under ignored `build/fixtures`; it is never in the shipping app. Logs, screenshots, test results and the IPA are retained as private CI artifacts for seven days.

The IPA is for personal signing with a compatible sideloader such as SideStore or AltStore. The ad-hoc build signature is not an Apple device provisioning signature. Personal Apple signing/provisioning and installation happen through the user's chosen sideloader. No Apple credentials are bundled.

## Architecture

- `Sources/PearlCore`: platform-independent review decisions, protection/undo, candidate shortlisting, similarity gates and date grouping.
- `App/PearlModel.swift`: observable main-actor UI state and PhotoKit change refresh. `performChanges` receives explicit Sendable closures outside the UI actor.
- `App/Services/PhotoAccess.swift`: cancellable PhotoKit image/video bridges and album/library mutations. The legacy AVAsset bridge is narrowly immutable and has a single consumer per request.
- `App/Services/ScanEngine.swift`: actor-owned two-phase scan, durable checkpoints, bounded decoded-observation cache, conservative complete-link groups, cancellation and power gating.
- `App/Services/Fingerprints.swift`: Vision revision 2, oriented/downsampled images, streamed SHA-256 and five downsampled video frames (10/30/50/70/90%). No downloaded ML model.
- `App/Services/ReviewStore.swift`: atomic protected local review-state file in Application Support; revision ordering avoids older saves replacing newer decisions. Excluded from backups. Cache files live in Caches, with a 128 MiB pruning budget (no 6,000-item cap) after each scan.
- `App/Views`: native SwiftUI tabs, adaptive sage/ivory surfaces, system navigation/materials, loading texture and pinned native ThinkingOrbsKit (MIT notices included).

## Matching semantics

Exact matching first shortlists equal perceptual hashes with matching media type, dimensions and duration, then hashes the complete sole original resource of each eligible candidate. Perceptual hashes never establish equality; the shortlist can miss copies. Assets with multiple resources (Live Photos, RAW pairs, edited versions) are deliberately excluded. The result means byte-identical resources, not identical captions, dates, albums or other metadata.

Photo suggestions use Vision revision-2 distance ≤ 0.24 and require every member of an existing group to match the candidate. No transitive chains and no automatic keeper/deletion selection. The UI reports largest resolution as a factual hint, not a subjective quality claim.

Video suggestions require five frame distances ≤ 0.18, aspect difference ≤ 0.03 and duration difference ≤ the smaller of 0.5 seconds or 2%. Sound is not analyzed. These are **possible similar videos**, never proof that videos are interchangeable.

Candidate retrieval combines up to 32 recent shots within two minutes and bounded perceptual hash bands across dates. Each shortlist is bounded to 160; groups to 20. This avoids an all-pairs scan but can miss crops, heavy edits, trimmed clips, very large groups and some cross-date matches. Thresholds are initial conservative choices, not calibrated confidence percentages.

## Scope and remaining validation

This is the initial useful native build, not completion of every research idea. It includes the requested local video workflow now rather than deferring it to P1. Live Photos can be browsed and reviewed as stills; full motion playback, RAW/burst handling, compression, OCR, semantic search, byte-savings estimates, album pinning and export are later work.

Review decisions and scan checkpoints persist across launches. A resumed scan reuses completed comparisons and groups, rebuilds only the cheap candidate index, and processes new/modified/unavailable items. The binary checkpoint is atomically saved every 128 items or 15 seconds, at phase transitions, on cooperative cancellation and on completion. Abrupt termination may repeat the last small batch; cached fingerprints avoid repeating inference where possible. Checkpoints are in protected Application Support, excluded from backup. Fingerprints are in purgeable Caches. Both are invalidated by schema, Vision revision, OS version and asset modification date.

The scan first generates visual suggestions, then streams original bytes only for likely copies. A 192-entry actor-confined decoded-observation cache avoids repeated secure unarchives. Each candidate group is checked once per item; incompatible video durations/aspects are filtered before Vision distances. Video frames pass directly as CGImages instead of PNG encode/decode round trips. CPU-only Vision and software Core Image processing avoid unsupported background GPU/Neural Engine entitlements under personal sideload signing. This can trade foreground inference throughput for background eligibility; no physical-device speedup factor is claimed.

On iOS 26+, an explicit scan button requests `BGContinuedProcessingTask` with a unique job identifier. Apple's system Live Activity reports real phase/progress and supports cancellation. The scan is owned by the app model, independent of the current tab or review screen. System cancellation saves completed work and completes the task once. On older iOS or if immediate background execution is unavailable, scanning works across Pearl tabs; leaving the app cancels and uses a short background lease only to save the checkpoint. No indefinite-background workaround, audio/location mode or automatic deletion is used. Force-quit stops work. Low Power Mode and serious heat pause it. Optional iCloud access remains off each launch.

The home screen uses device storage (not an invented photo-library size), three direct entry points, and media tiles. Swipe opens months with progress and year/order filters. Review is a fixed full-screen presentation, with a title/count/percentage, close/undo, a tappable filmstrip, and Delete / Heart / Keep. The heart changes the real PhotoKit favorite flag. Swipes follow the finger and only commit on release. Pinch/double-tap zoom, video playback and a protection context menu remain available. Delete stages a reversible choice; the final queue and Apple confirmation remain mandatory.

Core tests cover reversible choices, favorites/protected items, stale IDs, deletion completion, persistence round trips, complete-link distances, five-frame/duration gates, cross-date candidates and shortlist bounds. CI also mutates the favorite guard and requires the relevant test to fail before restoring the original source.

Simulator UI tests use synthetic photos and re-encoded videos to exercise browsing, queue/undo, local scanning and unselected comparison groups. They do not prove real-library precision, physical-device battery/memory behavior, iCloud edge cases, Apple signing, or every accessibility setting. These remain device acceptance checks.

## Platform references

- [Apple: continuous background work and system Live Activity](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados)
- [Apple: Vision compute-stage device selection](https://developer.apple.com/documentation/vision/vnrequest/setcomputedevice(_:for:))
- [Apple: required-reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) — disk-space reason 85F4.1 is used only to display local device storage.

## Source review

Main-agent review covers deletion authorization, live favorites, permission changes, preserved review data, phase completion, cache invalidation, actor confinement, stale task callbacks, background expiration, gesture cancellation, and accessibility alternatives. Synthetic 10,001-item tests validate metadata recovery and retained exact candidates; they are not a 10,000-photo inference benchmark. CI mutation checks require broken favorite protection and edited-photo invalidation to fail their relevant tests.
