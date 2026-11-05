# Technical groundwork — proposal, not implementation

> Planning baseline retained for context. Implementation was authorized November 4, 2026. Current status and build instructions: [BUILD.md](BUILD.md). The app and local video matching are now implemented; the remote is private N3moStudio/Pearl.
## Native foundation

| Responsibility | Proposed approach | Why |
|---|---|---|
| Interface | SwiftUI; native navigation, sheets and controls | Familiar interaction, system text scaling and materials |
| Photo library | PhotoKit | Read accessible assets, track changes, organize albums, request user-confirmed edits |
| Thumbnails | PHCachingImageManager; bounded prefetching | Avoid decoding every full-resolution asset |
| Photo similarity | Apple Vision image feature prints + candidate filtering | Local comparison using system facilities; no separate large model needed initially |
| Exact comparison | CryptoKit streaming digest of eligible resource sets | Byte identity remains separate from visual similarity |
| Video comparison | AVFoundation sampled frames + Vision | Analyze a bounded set of moments before asking the user to compare |
| Local state | Persistent database for asset IDs, review decisions, hashes, feature-print versions, sessions | Resume, incremental work, avoid rescanning unchanged assets |
| Loading orb | Evaluate the previously used native ThinkingOrbsKit revision | Preserve the user's existing visual preference |

Core scanning will have no external account or server requirement. Fetching an iCloud-only original through PhotoKit can require Apple's network service; that is distinct from uploading images to an app-owned AI server.

## Similarity pipeline

### 1. Make the library useful first

Fetch accessible metadata and construct media/date sections. Request only appropriately sized thumbnails for visible content. Start manual review immediately. Deep scanning is cancellable and incremental.

### 2. Exact files

Build candidate buckets from available safe metadata. Compare the relevant resources by streaming bytes into a digest instead of loading an entire photo/video into memory. The exact definition must account for multiple resources: a Live Photo's still and video, RAW+JPEG pairs, edits, and originals versus rendered versions.

A perceptual hash is a candidate tool, not proof of byte identity. Byte-identical media may still have differing dates, favorites, captions or album membership. The review must explain which asset remains and avoid silently discarding meaningful metadata. Do not claim to reproduce Apple's own duplicate-merge semantics.

Full hashing of cloud-only originals can be expensive. Default to available local work and make a deeper iCloud pass explicit. Unknown sizes remain unknown; do not use unsupported private file-size keys.

### 3. Very similar photos

Generate a Vision feature print from a bounded-size image. Cache it with asset modification data and the request/model revision. Use temporal/burst information and coarse visual candidates to avoid comparing every pair. Include a broader visual pass so re-saved duplicates months apart are not permanently missed by a time-only filter.

Compare feature distances within candidate sets. Use conservative, evaluated thresholds. Exact values must be calibrated on labeled examples for the chosen API revision, not copied blindly from a repository.

Avoid a chain where A resembles B and B resembles C but A does not resemble C. Confirm group cohesion; keep large ambiguous clusters for manual browsing. Similar content (two unrelated sunsets or two receipts) is not enough to justify a deletion suggestion.

Offer a keeper suggestion only when supported by measurable signals. Consider resolution, technical sharpness, user favorites/protection, edits, and metadata completeness. A sharp photo is not necessarily the emotionally preferred one. No model may choose and delete silently.

Apple supplies [image-similarity feature-print APIs](https://developer.apple.com/documentation/vision/analyzing-image-similarity-with-feature-print). Their existence supports this approach; the new app's accuracy, latency, and energy use still need implementation and measurement.

### 4. Videos

Exact video files can use the exact lane. Near-duplicate videos are a separate feature: shortlist by duration/dimensions and metadata, extract several low-resolution frames across time, compare frame sequences with conservative temporal alignment, and check more moments for ambiguous pairs.

Keep clips separate when audio, duration, slow-motion segments, edits, or meaningful moments differ. A trimmed clip and its source are related, not necessarily interchangeable. Offer linked scrubbing/playback and understandable differences. Apple describes frame-by-frame analysis through [Vision VideoProcessor](https://developer.apple.com/documentation/vision/videoprocessor).

Near-duplicate video matching is proposed second-stage work. No current benchmark or working capability is claimed.

### 5. Optional lightweight semantic model

Only add a bundled Core ML model if testing shows a concrete benefit beyond Vision, or if the user wants natural-language search such as “dog at the beach.” [Queryable](https://github.com/mazzzystar/Queryable) is a useful MIT reference for local MobileCLIP integration; its public core is different from the current shipping app. Review model licensing, artifact size, conversion accuracy, memory, energy, and device compatibility separately.

Semantic search and deduplication have different failure modes. A model grouping visually related subjects should not become a delete-confidence score. There is no need for an LLM to browse dates, categorize media types, or detect identical files.

## Resource behavior

- Prioritize scrolling and user interaction over scanning.
- Bound concurrent image requests and inference. Keep large originals out of memory unless an operation needs them.
- Cache results and analyze only changed/new items after first scan.
- Pause or reduce expensive work on thermal pressure/Low Power Mode. Save checkpoints before suspension.
- Avoid promises of continuous scans while the app is closed. iOS controls background execution.
- Keep an explicit Download from iCloud or retry state for unavailable originals. Do not spin indefinitely.
- Remove stale cache/index entries after revoked access or deleted/modified assets.
- Feature prints and identifiers stay local. Do not put them in analytics, remote diagnostics, or the repository.

## Permissions and deletion boundary

PhotoKit read/write access is appropriate because this app browses and modifies the library; a one-off picker cannot supply the whole cleanup experience. Limited library access must remain supported. See [PhotoKit](https://developer.apple.com/documentation/photokit).

Only send a confirmed set of current, accessible IDs to a change request. Handle system cancellation, permissions changing, library changes during review, unsupported shared/synced assets, and partial or failed operations. Refresh from PhotoKit after completion rather than assuming all staged IDs were removed.

Undo applies to app decisions before system deletion. After system deletion, guide the user to Photos recovery; do not promise an in-app restoration API or the ability to empty Recently Deleted. [Apple recovery and iCloud behavior](https://support.apple.com/en-us/104967).

## Build and sideload plan

The current Windows environment has Node and Python but no discovered Swift or Xcode executable. A Mac/Xcode environment or an authorized macOS CI runner will be needed for native compilation and IPA creation.

When implementation is authorized:

1. Pick the app name, bundle ID and supported OS baseline.
2. Create a minimal native Xcode project with no server dependency.
3. Keep signing files and real library fixtures out of Git.
4. Build and test on a Mac; generate a separately identified unsigned IPA when appropriate.
5. Validate app metadata, resources, icons, deployment target, archive contents and checksum.
6. Sign/install with the user's chosen workflow; verify on a real iPhone.
7. Preserve bundle identity and local progress across subsequent upgrades.

[AltStore Classic](https://faq.altstore.io/altstore-classic/your-altstore) and [Sideloadly](https://sideloadly.io/) document signing/refresh restrictions. An IPA is a distribution artifact, not an extra feature set and not proof that an app can bypass PhotoKit permissions. No signing account is needed for this planning phase.

## Verification gates

Use a consented test library with known labels: exact copies, re-encodes, crops, rotations, exposure edits, different receipts with similar layouts, close burst frames, Live Photos, RAW pairs, panoramas, HDR, favorites, cloud-only assets, long/trimmed/repeated-frame videos, and missing dates.

Measure precision/recall and false groups, not just how many matches are found. Prioritize avoiding incorrect deletion suggestions. Track cold scan, incremental scan, scrolling responsiveness, peak memory, energy and thermal behavior on representative small/large libraries. Define targets before testing; no numeric performance claims have been established yet.

Verify interruptions, cancellation, permission changes, limited access, iCloud failures, app relaunch, album changes, and deletion rejection. Validate VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency and light/dark appearance on-device.
