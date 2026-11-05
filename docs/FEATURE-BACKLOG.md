# Full feature checklist

Checked items are implemented in the 0.1.0 source; device acceptance is separate. Partial items remain unchecked. See [build scope and validation](BUILD.md). The user moved local similar-video detection into this first build.

P0 = first useful sideloaded version. P1 = next release after core behavior is trustworthy. P2 = optional extension, to be reconsidered with the user. Phases are scope recommendations, not time estimates.

## Groundwork

- [x] G01 Survey commercial, independent, open-source and sideloadable options.
- [x] G02 Inspect 12 GitHub projects and distinguish source availability from IPA availability.
- [x] G03 Show existing-app visual references.
- [x] G04 Generate Pearl, Mist and Ink design directions.
- [x] G05 Record the user's selection of Pearl and local similarity matching.
- [x] G06 Recover the Thinking Orbs reference from Elsepin.
- [x] G07 Create product, design and technical plans.
- [x] G08 Initialize a local repository in `C:\Users\naith\Documents\GitHub\Photo Cleaner`.
- [ ] G09 Finalize name, icon, bundle ID, minimum iOS and repository license.

## P0 — Enter without friction

- [x] O01 One concise introduction with a clear Photos access action.
- [x] O02 No login, account, paywall, ad, server setup or required notification permission.
- [x] O03 Handle full, limited, denied and restricted Photos access.
- [ ] O04 Manage limited selection without losing existing review decisions.
- [x] O05 Start browsing before the full similarity scan finishes.
- [x] O06 Contextual gesture explanation; visible Keep/Remove/Skip buttons.
- [x] O07 Empty-library, no-results and all-reviewed states.
- [ ] O08 A useful initial small session with an obvious way to stop.

Acceptance: a person with partial access can reach accessible photos, complete a small review, and resume later without configuration or forced onboarding.

## P0 — Browse a large library

- [x] L01 Library / Clean Up / Albums navigation; Settings in the toolbar.
- [ ] L02 Years → months → optional days, with newest/oldest sorting.
- [x] L03 Photos, Videos and Screenshots as prominent media types.
- [ ] L04 More media types: Live Photos, screen recordings, bursts, selfies, portraits, panoramas, RAW and slow-motion/time-lapse where public APIs support them.
- [ ] L05 Combine date range, media type, album, favorites and review state.
- [x] L06 Media metadata: date, dimensions, duration and supported size details.
- [ ] L07 Largest-first ordering with unknown-size handling and cancellable size work.
- [ ] L08 Unknown date group; explicit date/time-zone semantics.
- [ ] L09 Visible month progress and a Continue card.
- [x] L10 Keep app smart collections separate from system albums.
- [ ] L11 Full-size viewer with zoom, video playback/scrubbing and Live Photo preview.
- [x] L12 Reflect additions, modifications, deletions and permission changes from Photos.
- [ ] L13 Preserve selection and navigation position during refresh.
- [ ] L14 Responsive thumbnail loading, bounded caching and prefetching.

Acceptance: a user can reach videos from a specific old month without scanning a long mixed grid; changing permissions or receiving new media does not corrupt counts or selections.

## P0 — Review safely

- [x] R01 Swipe or tap to Keep, queue Remove, or Skip.
- [x] R02 Undo the last decision; restore its position and counts.
- [x] R03 Persist session progress and pending queue across launches.
- [ ] R04 Resume a partially reviewed month or category.
- [x] R05 Grid multi-selection for people who prefer batch review.
- [ ] R06 Favorite and protect an item without leaving review.
- [x] R07 Exclude favorites/protected assets from deletion recommendations by default.
- [x] R08 Review the entire pending batch before a deletion request.
- [ ] R09 Explicit item count, clear action wording and honest byte estimates.
- [x] R10 PhotoKit system confirmation; preserve the queue if the user cancels.
- [ ] R11 Handle inaccessible, externally deleted, unsupported and changed assets.
- [x] R12 Refresh after actual completion and report failures accurately.
- [x] R13 Explain iCloud deletion propagation at the relevant moment.
- [x] R14 Provide recovery instructions for Photos' Recently Deleted.
- [ ] R15 Keep an optional local history of confirmed operations without storing copies of deleted media.

Acceptance: every removal is inspectable and user-confirmed. A cancelled or failed operation never appears as a successful cleanup. Undo before deletion and recovery after deletion are clearly different.

## P0 — Exact and very similar photos

- [x] S01 Separate Exact duplicates and Similar photos entry points.
- [x] S02 Establish exact-resource identity rules for photos, videos, Live Photos, RAW pairs and edited assets.
- [x] S03 Stream hashes for eligible exact candidates with bounded memory.
- [x] S04 Generate/cache Vision image feature prints locally.
- [x] S05 Candidate filtering for efficient comparisons, including cross-date copies.
- [ ] S06 Calibrate conservative similarity thresholds on a labeled test library.
- [x] S07 Prevent weak transitive chains from producing misleading groups.
- [x] S08 Show groups progressively with truthful scan state and cancellation.
- [ ] S09 Side-by-side/full-size comparison and quick candidate switching.
- [ ] S10 Overridable suggested keeper with actual measured reasons.
- [x] S11 No default deletion selection for similar-photo groups.
- [ ] S12 Keep all / dismiss group / protect item; persist those decisions.
- [x] S13 Preserve meaningful metadata and album membership during keeper decisions.
- [ ] S14 Invalidate cached comparisons after edits, permission changes or API/model revision changes.
- [ ] S15 Distinguish unavailable iCloud resources from a completed scan with no matches.
- [ ] S16 Pause/resume deep scans and incrementally process new media.

Acceptance: intentionally similar but distinct receipts, documents, sunsets and burst expressions are in the evaluation set. Similarity is presented as a suggestion; no unattended selection or deletion is permitted.

## P0 — Album organization

- [ ] A01 Browse and pin existing albums.
- [x] A02 Create a new album inline.
- [ ] A03 File a photo into recent/pinned albums in one action.
- [x] A04 Batch filing and multiple album membership.
- [ ] A05 Unsorted queue based on supported album membership, with clear exclusions.
- [ ] A06 Separate Remove from album from Delete from library.
- [x] A07 Reflect album changes made in Apple Photos.

Acceptance: filing does not imply moving photos out of the main camera roll; people can organize without deleting.

## P0 — Pearl design and accessibility

- [x] U01 Warm white/sage design system with a matching dark appearance.
- [x] U02 Rounded continuous corners and consistent spacing/type hierarchy.
- [x] U03 Native Liquid Glass on supported floating controls, with older-OS and reduced-transparency fallbacks.
- [x] U04 Small Thinking Orbs for real active work, accompanied by status text.
- [x] U05 Fine-grain loading placeholders matching the final thumbnail geometry.
- [x] U06 Preserve loaded content and avoid artificial loading delays.
- [x] U07 Disable decorative motion under Reduce Motion, Low Power and inactive/offscreen states.
- [ ] U08 Dynamic Type and VoiceOver, including labeled photo actions and accessible comparison.
- [x] U09 Comfortable touch targets, clear focus and alternatives to every gesture.
- [ ] U10 Verify contrast over bright/dark photos and all glass accessibility settings.
- [ ] U11 Native back gestures, dismissible sheets, interruption-safe transitions and subtle optional haptics.
- [x] U12 Calm completion feedback; no forced streaks, confetti or guilt language.

Acceptance: the app remains usable with the largest supported text sizes, VoiceOver and motion/transparency reductions. Concept-image appearance alone does not satisfy this gate.

## First build — Similar videos (promoted from P1)

- [x] V01 Dedicated Possible similar videos category.
- [x] V02 Shortlist by supported metadata and duration.
- [x] V03 Compare multiple downsampled frames across time.
- [ ] V04 Handle trimmed, re-encoded, rotated and differently sized variants conservatively.
- [x] V05 Show duration/resolution differences and preserve distinct audio/moments.
- [x] V06 Preview both clips with scrubbing; do not infer equivalence from a poster frame.
- [ ] V07 Explicit compute/iCloud-download controls and durable checkpoints.
- [ ] V08 Evaluate false matches and missed matches on real video variants before shipping.

## P1 — Smarter categories

- [ ] C01 Blurry/technically poor suggestions with explanation and dismiss/protect controls.
- [ ] C02 Local OCR for document, receipt, note and text-heavy screenshot views.
- [ ] C03 Optional expired-ticket/pass suggestions; uncertain dates remain review-only.
- [ ] C04 Short/accidental video filter with user-adjustable duration.
- [ ] C05 Large-media threshold and date filters.
- [ ] C06 Burst comparison and optional edited-version review.
- [ ] C07 Saved smart filters, such as screenshots older than a year and not favorited.
- [ ] C08 Optional user tags/ratings stored locally; system sync only where public APIs and chosen OS support it.

## P1 — Compression and export

- [ ] X01 Photo and video compression presets with realistic estimates.
- [ ] X02 Before/after preview and format/HDR/audio/metadata disclosure.
- [ ] X03 Create and verify a copy before offering removal of originals.
- [ ] X04 Preserve supported dates, favorite flags and album memberships.
- [ ] X05 Live Photo to still conversion only as an explicit loss-of-motion choice.
- [ ] X06 Recover cleanly from cancellation, low storage, export error or termination.
- [ ] X07 Export selected originals/copies through the system share sheet or Files.
- [ ] X08 Export/import app review state and settings with documented identity limitations; no claim that IDs are stable across unrelated library migrations.

## P2 — Optional, not committed

- [ ] E01 On This Day and small resurfacing sessions.
- [ ] E02 Optional gentle reminders or a widget opening the next session.
- [ ] E03 Places/map view using existing photo metadata and minimal additional permissions.
- [ ] E04 On-device natural-language search only after evaluating model size and energy.
- [ ] E05 iPad adaptation with more comparison space.
- [ ] E06 Review-state synchronization after defining privacy and conflict handling.
- [ ] E07 Optional quick-session limits or quiet progress summaries, without mandatory streaks.

## P0 — Quality and IPA delivery

- [ ] Q01 Validate permissions, limited access, shared/synced media and iCloud availability.
- [ ] Q02 Validate interrupted/restarted scans and resumed review decisions.
- [ ] Q03 Validate deletion cancel/failure and concurrent library changes.
- [ ] Q04 Evaluate photo matching against labeled positives and difficult negatives.
- [ ] Q05 Measure scrolling, memory, cold/incremental scan costs and energy on representative library sizes.
- [ ] Q06 Validate Low Power, thermal pressure and app suspension behavior.
- [x] Q07 Check that logs and diagnostics contain no personal media or sensitive metadata.
- [x] Q08 Review dependency licenses and retain required notices.
- [x] Q09 Compile on a suitable Mac/Xcode runner after implementation is authorized.
- [x] Q10 Produce a versioned IPA, validate its contents and record SHA-256.
- [ ] Q11 Install with the selected signing workflow and test on the actual iPhone.
- [ ] Q12 Test upgrading the app without losing sessions, exclusions or settings.

## Order of work after authorization

1. Approve name/OS baseline and implement the Pearl navigation shell.
2. Add real library access and date/media browsing.
3. Add resumable manual review, album filing and confirmed deletion.
4. Add exact matching and local similar-photo grouping.
5. Complete performance/accessibility/device validation and first private IPA.
6. Validate local video matching on real variants and add further P1 tools in independently reviewable increments.
