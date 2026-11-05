# Photo cleaner landscape

Research date: November 4, 2026, America/Los_Angeles.

**Scope: 29 distinct products/projects, including 12 GitHub repositories.** This is a broad survey of the relevant design and feature families, not a claim to have found every app or IPA. No apps were installed or benchmarked. Product descriptions are vendor claims; source/release checks establish what is publicly provided, not its safety or correctness.

## Existing products and adjacent references

| Product and primary source | Useful idea | How it informs this app |
|---|---|---|
| [Apple Photos](https://support.apple.com/en-us/104967) | Built-in duplicate merging, system deletion and Recently Deleted | The baseline to complement; respect its confirmation/recovery and iCloud semantics |
| [Google Photos](https://support.google.com/photos/answer/10100180?hl=en) | Storage review categories including blur, screenshots and large videos | Clear category entry points; cloud behavior is not a model for this local app |
| [Slidebox](https://slidebox.co/) | Swipe review and quick album filing | Recent album shortcuts and a genuinely useful organizer alongside cleanup |
| [Swipewipe](https://swipewipe.com/features) | Months, resumable swiping, duplicates, On This Day and photo details | Manageable date-based sessions; memories remain optional |
| [CleanMyPhone](https://macpaw.com/cleanmyphone) | Separate declutter/organize functions, duplicates, blurred shots, large videos and compression | Clear task grouping; quiet the presentation for Pearl |
| [Clever Cleaner](https://www.cleverfiles.com/clever-cleaner/) | Similar groups, large videos, swipe mode and compression | A strong category reference and a low-friction benchmark |
| [HashPhotos](https://www.hashphotos.app/) | Timeline/calendar, tags, tray, smart albums, compare-and-pick, unsorted filing | Rich organization available through deeper views; don't put every control on the home screen |
| [Utiful](https://www.utifulapp.com/) | Folder-based separation outside the camera roll | Understand the value of categories; copying into app storage adds separate backup/lifecycle costs and is not the initial architecture |
| [GetSorted](https://apps.apple.com/gb/app/getsorted-clean-up-photos/id1475025504) | Small batches and month completion | Finishable sessions and persistent progress; no mandatory streaks |
| [Sponge — prismtree](https://apps.apple.com/us/app/sponge-gallery-cleaner/id6738958624) | Swipe review, remembered progress and focused cleanup | Simple resume flow. This is distinct from similarly named Sponge listings |
| [Sweepr](https://sweeprapp.com/) | Media/date entry points, full-screen decisions, albums and compression | One consistent review flow across different starting collections |
| [Gleam](https://gleam.photos/) | Reason-labeled groups, expired screenshot suggestions, large/heavy media | Explain why a suggestion exists; OCR/expiry remains later, conservative work |
| [PhotoBroom](https://photobroom.com/) | Similar photos, screenshots, low-scored photos, recordings, large/short videos; incremental scan | Separate technical-quality suggestions and avoid rescanning unchanged assets |
| [Cleanup](https://apps.apple.com/us/app/cleanup-phone-storage-cleaner/id1510944943) | Similar photos/videos, compression and final review | Borrow relevant photo flows. Contacts, email, vault and charging animations stay outside scope |
| [Cleaner Kit](https://www.bpmobile.com/apps/cleanerkit) | Screenshots, Live Photo/burst duplicates and grouped review | Include nonstandard media types; do not adopt unrelated contact permissions |
| [Remo Duplicate Photos Remover](https://www.remosoftware.com/help-manual/remo-duplicate-photos-remover/ios/en/) | Explicit exact-versus-similar modes and set previews | Keep exact and visual matches distinct. Documentation is older; current installation availability was not established |
| [PhotoSweeper](https://overmacs.com/?p=photosweeper) | Mac comparison modes, configurable rules, protected/locked items, similarity threshold | Protect keepers and compare carefully. The linked Mac feature set is not assumed to be identical to its mobile app |

## GitHub projects

GitHub API metadata, default-branch README and the most recent three release records were inspected. “No IPA found” is limited to that inspected release surface; it is not a claim about every historical release or CI artifact.

| Project | License observed | What to study | Distribution evidence / limitations |
|---|---|---|---|
| [StorageSaver](https://github.com/alidiab2/StorageSaver) | MIT | Exact-photo/video hashing, separate visual matches, batch compression and review-before-original-removal | [v0.2.0](https://github.com/alidiab2/StorageSaver/releases/tag/v0.2.0) contains `StorageSaver-v0.2.0-unsigned.ipa`. Actual asset listed; not installed or audited |
| [PhotoSwipe](https://github.com/noluyorAbi/photoswipe-ios) | MIT | Resumable swipe queue, media/year sources, album filing and similar detection | Native SwiftUI source; no public releases returned. Source is not a ready IPA |
| [PhotoSweep](https://github.com/Enderfga/PhotoSweep) | MIT | Small random batches, persisted reviewed IDs and final deletion review | Describes itself as a prototype; no public releases returned |
| [iPhone Cleaner](https://github.com/SPerekrestova/iphone-cleaner) | MIT | Vision feature prints, OCR, blur and quality categories | Source-only in inspected release surface; some claimed capabilities are OS-gated and need independent validation |
| [SwipeSweep](https://github.com/graygillman/SwipeSweep) | No license identified by GitHub API | Minimal scope, persisted review and visual hierarchy | README calls it open source; reuse permission is unresolved. No public releases returned; promotional asset/CDN claims are not an offline audit |
| [OnePhoto / PhotoDelete](https://github.com/01MVP/PhotoDelete) | AGPL-3.0 | Staged decisions, swipe or two-row browsing, media/time/place sources | App Store route and source; no public releases returned. Not a default source-copy candidate |
| [OpenCleaner](https://github.com/arthurBricq/open-cleaner) | GPL-3.0 | Calendar time ranges, cluster comparison, documented similarity pipeline | Inspected v1.0 release has a Mac DMG, not an iPhone IPA; iOS App Store route documented |
| [TidyByte](https://github.com/YORDINDIA/tidybyte) | MIT | Native cleanup categories, local review and multi-product separation | Earlier `360ghar/tidybyte` URL redirects here. Newest three iOS release records had no binary assets |
| [SnipSnaps](https://github.com/Kyter-com/SnipSnaps) | MIT | Small review sessions, broad media types, similar-shot comparison and screenshot assets | Native source plus App Store route; no public releases returned |
| [Queryable](https://github.com/mazzzystar/Queryable) | MIT | On-device CLIP/MobileCLIP embeddings and semantic search | Public search core differs from current shipping app; models are separate downloads. See [developer explanation](https://queryable.app/open-source) |
| [Immich](https://github.com/immich-app/immich) | AGPL-3.0 | Timeline, asset organization and a [duplicate review utility](https://docs.immich.app/features/duplicates-utility/) | Server-backed photo ecosystem, not a lightweight local SwiftUI cleaner. Newest inspected releases expose server/APK assets, not IPA |
| [Ente Photos](https://github.com/ente/ente) | AGPL-3.0 | Privacy-oriented product approach, duplicate identity and album-reference preservation | Larger encrypted backup ecosystem. [Duplicate documentation](https://help.ente.io/photos/features/deduplicate) is useful; inspected releases did not establish an IPA route |

These license labels are a source-selection screen, not a completed reuse review. No third-party app source has been incorporated. A candidate's repository license also does not automatically settle model-weight, artwork or bundled dependency rights.

## Recommended shortlist

1. **SnipSnaps** for simple native review flows and media categories.
2. **PhotoSwipe** for resumable decisions and album filing.
3. **StorageSaver** for exact-versus-similar separation, conservative compression flow and an actual IPA example.
4. **iPhone Cleaner** for a compact catalogue of native analysis techniques, to be validated rather than copied wholesale.
5. **Queryable** only if later natural-language search needs its own local model.

The proposed app should begin as a small native project with this user's Pearl design. There is no evidence yet that adopting any entire fork would be less work or safer than a focused implementation.

## Feature synthesis

| Feature family | Best references | Planned location/phase |
|---|---|---|
| Year/month review | Swipewipe, GetSorted, OpenCleaner | Library, P0 |
| Media categories | SnipSnaps, Clever Cleaner, PhotoBroom | Library and Clean Up, P0 |
| Swipe and batch decisions | PhotoSwipe, Slidebox, OnePhoto | Shared review flow, P0 |
| Exact and similar groups | StorageSaver, Remo, OpenCleaner | Separate Clean Up lanes, P0 |
| Protected keepers and detailed comparison | PhotoSweeper, HashPhotos | Group detail and preferences, P0 |
| Quick album filing | Slidebox, HashPhotos, PhotoSwipe | Review and Albums, P0 |
| Similar videos | StorageSaver exact-video lane; Sweepr/Cleanup product claims | Separate proposed frame-based analysis, P1 |
| Blurry/text/expired candidates | iPhone Cleaner, Gleam, PhotoBroom | Optional suggestions, P1 |
| Compression | StorageSaver, Clever Cleaner, CleanMyPhone | Explicit copy-first workflow, P1 |
| Semantic search | Queryable, Ente/Immich as broader references | Optional measured model work, P2 |

## Sideload research

An open repository, an App Store listing, a Mac binary and a sideloadable IPA are different deliverables. Only the StorageSaver IPA above was directly confirmed in the cleaner shortlist's inspected releases. Random IPA mirrors were not treated as proof of provenance or included as reusable source.

The intended deliverable for this project, once built, is its own versioned IPA. The signing path is a later choice: [AltStore Classic](https://faq.altstore.io/altstore-classic/your-altstore) and [Sideloadly](https://sideloadly.io/) are documented options. Sideloading does not remove Photos permission, confirmation, or iCloud behavior.

## Search boundaries

Search covered generic iPhone cleaners, swipe/month organizers, duplicate/similarity tools, media organization, open-source repositories, public releases and adjacent photo-management projects. Tiny launch projects and name collisions are common; screenshots and README claims are not code audits. Feature availability and release contents can change. No promise of exhaustive market coverage, universal compatibility or measured app quality is made.
