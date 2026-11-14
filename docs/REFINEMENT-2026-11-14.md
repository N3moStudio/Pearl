# Pearl refinement — 14 November 2026

Baseline: `3f71f9c`, clean working tree. Local-only refinement; no IPA, publication, billing or changes to another app.

## Feature and state map before editing

| Flow | Existing owner / storage | Preservation and proposed refinement |
|---|---|---|
| Full/limited/denied/restricted Photos access | PearlModel.authorization, PhotoKit, LimitedLibraryEditor | Keep real system permission flows and refresh observer; surface limited access on Home. |
| Home categories and albums | HomeOrder / `pearl.home.order`, PhotoKit smart albums, AlbumAccess | Keep sole navigation root, all twelve categories/order and native pushed pages. |
| Date/media/album browsing | SwipeLibraryView, MediaGrid, AlbumsView | Keep month/year/sort/filter and create/file album actions. |
| Full-screen review | ReviewSession, ReviewView (SwipeReview.swift) | Keep media, direct drag, Delete/Heart/Keep, zoom, filmstrip and Undo; add queue access without ending the session; accommodate accessibility text. |
| Queue and deletion | ReviewQueue, ReviewStore review-v1, PhotoAccess.delete | Keep reversible decisions, favorite/protection gates and Apple confirmation; add explicit empty state. Correct stale Undo removal snapshots after favoriting. |
| Exact and similar suggestions | SimilarityScanner, MatchRules, CandidateIndex, scan checkpoint/cache | Keep matching thresholds and five-frame video limits. Distinguish unfinished/no-unreviewed-results/partial-analysis states. |
| Progress/recovery/background | App-owned PearlModel task, BackgroundScan, ScanCheckpoint | Preserve pause/resume, power/heat gates, Live Activity and fallback. No reliability/performance claims from source review. |
| Settings | PearlAppearance, existing UserDefaults keys, host model actions | See SETTINGS-FEATURE-MAP.md. Keep larger identity card; reduce ordinary row padding; group privacy facts as information. |

## Priorities

Observed in source: queue inaccessible during an unfinished full-screen review; review action text capped below accessibility sizes; generic empty matching state regardless of scan completion; privacy facts rendered as three action-sized rows; native list insets compound custom settings row padding. Favorite changes can leave old pending snapshots in Undo even when the current queue is empty (deletion still rechecks favorites).

Verification risks: limited-access changes, externally edited/deleted assets, iCloud unavailable media, repeat swipes, cancellation, theme changes, very large libraries, maximum text and small-screen layouts. Historical screenshots are not evidence of this patch's rendering.

Compression is separately authorized in earlier chat but not implemented. This refinement does not add a placeholder or claim savings. Its acceptance requires real original/output byte counts; cancellable export with disk-space handling; preview and explicit quality tradeoffs (HEVC re-encoding is not lossless); preserved orientation/date/location/color/HDR where supported; verified Live Photo pairing or explicit still conversion; save-success verification before offering separately confirmed original removal. Originals remain until that decision. No compression processing is included here.

## Platform evidence

Apple [materials](https://developer.apple.com/design/human-interface-guidelines/materials) separates readable content from floating controls; [motion](https://developer.apple.com/design/human-interface-guidelines/motion) informs continuity and accessibility. Keep Pearl's existing materials and direct manipulation, with opaque review control fallbacks. [PhotoKit observation](https://developer.apple.com/documentation/photokit/observing-changes-in-the-photo-library) supports the existing refresh observer. [BackgroundTasks](https://developer.apple.com/documentation/backgroundtasks) does not grant unlimited execution; preserve checkpoint recovery and system-controlled scheduling.

Codebase Memory generation 2026-11-14T21:52:17Z matched the inspected source paths; excluded docs were read directly. Graph caller trace confirmed QueueView -> PearlModel.removeConfirmed -> PhotoAccess.delete / ReviewStore / refresh. No new dependency or storage migration.

## Implemented

- Review can open its queue mid-session and return to the same position. Empty queues explain that no removal is selected; queue errors/success are available on the presented screen.
- Favorite reconciliation clears pending removal snapshots from Undo while retaining review progress, protection and unrelated history. Codable fields/formats stay unchanged. PhotoKit's final live favorite/deletion-permission check remains.
- Compact settings reuse kit rows/sections with explicit insets and subheadline text; the larger appearance card and native controls remain. Three privacy facts now share one information row. No theme/surface migration.
- Review retains direct drag and its three actions. Accessibility-size action labels use recognizable symbols with VoiceOver names rather than capping text size. Filmstrip items announce selection/review state. Review overlays/control materials have opaque accessibility fallbacks.
- Home exposes limited-photo access status with a Settings route. Matching empty states distinguish active, failed, unfinished, already reviewed, complete and omitted-media cases. A completed pass with omissions says some items need another try.

## Verification and remaining acceptance

- Local `git diff --check`: passed.
- Tree-sitter Swift 0.7.4 / parser 0.26.1: all 11 changed Swift files parsed without syntax errors. This is **not** Swift type checking, linking or execution.
- Existing kit portable validator: passed 8 themes, 144 solid-color contrast pairs (minimum 5.09:1), 28 local links and source ownership/navigation guardrails. Does not measure translucent overlays or the app's rendered UI.
- Added two core regression cases for favoriting/Undo/persisted history, one for completed scans with omissions, and extended the existing UI review test for queue round-trip/empty state. **Not executed**: no Swift/Xcode/Mac in this session. Prior cloud test results do not validate this patch.
- Inspected the historical native Home capture from run 43373093345 (`.build/home-navigation/Pearl-Library_0_FE4ADFE3-14BC-4584-ADCF-D658CD39E4FC.png`) to preserve sage/ivory identity, category grid and existing navigation. No new rendered screenshots are available. Do not present that image as an after screenshot.
- Next native pass: existing suite plus added tests, SE/narrow iPad and maximum Dynamic Type review/settings, light/dark themes, Reduce Transparency/Increase Contrast, VoiceOver, native Back/edge-pop and partial drags. Test queue alerts/cancellation, repeated swipes and theme changes during a running scan. Physical device: limited-access changes, external edits/deletions/favorite updates, iCloud download failure/cancellation, Low Power/thermal pause, background grants/Live Activity/resumption, large-library memory and matching precision. No battery/smoothness improvement is claimed.
- Source review retained PhotoKit observer/generation handling, missing-item review fallback, preview retry/cancellation, current file/favorite checks before deletion, empty-library and album creation/filing flows. Album removal is not an existing action; library deletion still names the library and iCloud sync consequences. These are source observations, not device acceptance.

Internal parser/runtime evidence stays under ignored `.build/refinement-validation/`; no global Python repair or dependency change. No IPA or delivered files changed.
