# Pearl 0.2.1 build attempt

November 4, 2026, America/Los_Angeles. Source remains in `C:\Users\naith\Documents\GitHub\Photo Cleaner`; `N3moStudio/Pearl` was verified private before and after the attempt. No public release, billing change or desktop takeover occurred.

## Changes prepared

Preview repairs keep a poster during full-resolution loading, favorite changes and video startup, use AVKit's first-frame readiness to reveal playback, cancel stale asset requests, and expose bounded retry/cancel/download paths. The protection menu moved from the draggable photo to the heart button. Photo/video views share the video loading path. The existing large-text/home/filmstrip polish from `84aacd4c` is retained. Version is 0.2.1, build 3; identifiers, persistent review data, scanner checkpoint schema and deletion safeguards are unchanged.

UI regression coverage now checks visible colored fixture pixels after favorite changes, partial drags and filmstrip jumps, plus explicit video poster/playback and rapid navigation. The same region/threshold was applied locally to historical screenshots: the black capture scored 0.000 and fails; the visible-photo capture scored 1.000 and passes. This validates the check's ability to reject that known defect, not the repaired SwiftUI app's behavior.

## Fresh GitHub run

The user explicitly requested removal of every previous Pearl workflow run before retrying. All **14 completed runs** were deleted and the API returned **zero remaining** before dispatch. A local history inventory is retained under ignored `.build/removed-run-history.json`. The downloaded 0.2.0 IPA remains unchanged with SHA-256 `9af88855d8e14a56b2052ccb2ec4831e1c11889a98d2b8b1d9af4161b884799a`.

- Attempt: [41972827539](https://github.com/N3moStudio/Pearl/actions/runs/41972827539)
- Attempted commit: `7ed475af4e761383724fd85850e86caacaac2d92`
- Runner label: standard `macos-26`
- Result: rejected before runner allocation; **zero steps executed**
- GitHub error: “The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings”
- Additional annotation: macOS arm64 capacity may cause longer queues. This was a completed failure, not a continuing queue.
- Existing self-hosted runners available to this repo: **0**

The attempted source and subsequent small preview fallback cleanup are **uncompiled and untested on an iPhone/simulator**. The 14 core tests, 7 current UI tests and two mutation checks have not run for 0.2.1. No 0.2.1 IPA/checksum exists. Current successful local checks are YAML/version consistency, Python script syntax, whitespace/diff review and the historical screenshot-gate comparison. The last native test/package evidence applies only to [0.2.0](VERIFICATION.md).

## Free path prepared

The private GitHub Actions workflow is manual, standard-runner-only, with a three-day artifact retention. It cannot override GitHub's account block. An optional manual Codemagic M2 workflow is syntax-checked and documented in [FREE-BUILD.md](FREE-BUILD.md); it is eligible for that service's personal free allowance but has not been connected or run. It requires the user to connect the private repository to their personal Codemagic account. No third-party account or repository access was created here.

Physical-device preview behavior, gestures, iCloud loading, background execution/Live Activity, signing, performance and battery remain pending in either path.
