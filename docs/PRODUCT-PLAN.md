# Product plan

> Planning baseline retained for context. Implementation was authorized November 4, 2026. Current status and build instructions: [BUILD.md](BUILD.md). The app and local video matching are now implemented; the remote is private N3moStudio/Pearl.
## Product promise

Make a large camera roll feel manageable. Open the app, choose a small part of the library, keep what matters, and review anything marked for removal.

The useful combination is date-based browsing, fast manual review, album organization, and careful local similarity suggestions. A rich feature set should appear through clear choices and deeper screens, not a wall of tools on the home screen.

## First use

1. One short introduction: what the app does and that photo analysis stays on the iPhone.
2. A clear button to grant Photos access. Explain why browsing and organizing need access.
3. Support full, limited, denied, and restricted permission states. Limited access remains a useful experience with an option to manage the selected photos.
4. Show accessible photos and media categories as soon as possible. Similarity scanning never blocks basic browsing.
5. Offer one clear starting point: continue a session, review a recent month, or begin a small batch.
6. Teach Keep, Remove, Skip, and Undo in context, with visible buttons as well as gestures.

No sign-up, obligatory tutorial, paywall, notification request, or account setup. Sideloading itself still needs installation/signing outside the app.

## Navigation

| Destination | What it contains | Initial visible content |
|---|---|---|
| Library | Years, months, days, media types, favorites, date/size filters | Continue card, Photos/Videos/Screenshots/More, years |
| Clean Up | Exact duplicates, similar photos, screenshots, large videos; later further suggestions | A short list of available groups with honest scan state |
| Albums | Existing albums, new album, unsorted queue, batch filing | Pinned/recent albums and an unsorted entry |

Settings is a toolbar entry. Search and filter are local tools, not additional main tabs. A pending-removal badge opens the review queue; it must never imply the items are already deleted.

## Core flows

### Browse and review by date

Library → year → month → optional day or review session. Users can combine a date range with a media type, such as screenshots from 2023, or videos older than a chosen date. Missing capture dates get an explicit Unknown date group. Show newest or oldest first according to the selected sort.

Each month tracks unreviewed, kept, skipped, and pending-removal items. The counts remain correct when Photos access changes, assets are edited/deleted elsewhere, or new media arrives. Old photos are never labeled junk because of their age.

### Manual cleanup

Start from a month, media type, album, or a small batch. Show one large photo with pinch zoom or a playable video. Keep and Remove are visible buttons; swipe equivalents are optional shortcuts. Undo restores the previous review decision. Skip is neutral and returns later. Users can stop at any point and resume.

Selecting Remove only stages a decision. At the end or mid-session: open review queue → inspect selected thumbnails and estimates → tap a specific delete action → system Photos confirmation → show the actual result. Cancelling at either confirmation preserves the queue and photos.

### Similar photos

Clean Up → Similar photos → a group → compare at full size. The app may suggest a keeper with a short measured reason, such as higher resolution or better sharpness. The recommendation is overridable. Nothing in the group is preselected for deletion by default. Keep all, dismiss this group, protect an item, select candidates, and review the batch are available.

Exact file duplicates have their own lane. A resized photo, crop, edit, burst frame, or shared-media re-encode is not a byte-identical duplicate. Favorites and protected photos must not silently become recommended deletion candidates.

### Similar videos

Later phase: compare candidates using duration and multiple sampled moments, then let the person preview both clips with audio and scrub through them. Label these as possible matches. A matching poster frame cannot establish that two entire videos contain the same content.

### Album organization

One-tap filing into recent/pinned albums; create an album inline; support multiple album membership. Adding to an Apple Photos album does not remove a photo from the main library. Make the difference between Remove from album and Delete from library unmistakable.

Initial date and cleanup collections are app views, not hundreds of automatically created system albums. If system album generation is added later, make it an explicit reviewed action.

### Compression

Later, optional: preview quality/size choices, save a new copy, verify successful output, then separately offer removal of the original. Preserve supported dates, favorites, album memberships, orientation, color/HDR, audio, and metadata; disclose any loss. Never promise lossless results from a lossy codec.

## Honest feedback

- Thinking Orbs appear only while real work is active, beside readable status text.
- Determinate progress needs a known denominator. Otherwise show the current stage without a made-up percentage or ETA.
- Show a subtle textured placeholder only where a thumbnail has not arrived. Already-loaded media remains usable.
- The app must distinguish candidate bytes, bytes requested for deletion, and storage the system has actually reclaimed. Optimized iCloud libraries make simplistic totals misleading.
- State clearly at deletion review that iCloud Photos deletion syncs to other devices. Recovery happens in Photos' Recently Deleted, normally for 30 days. See [Apple's deletion documentation](https://support.apple.com/en-us/104967).

## Features kept out of the initial product

Contact cleanup, email cleanup, charging animations, a separate private vault, AI photo generation, photo enhancement, cloud backup, social sharing services, antivirus claims, and system-cache/RAM cleaning. They surfaced in competitors but add unrelated permissions, complexity, or misleading promises to this photo-focused app.

Optional habit reminders, achievements, widgets, and seasonal memories remain later ideas. No streak pressure or celebration animation by default.
