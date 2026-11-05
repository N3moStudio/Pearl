# Pearl 0.2.1 verification

November 4, 2026, America/Los_Angeles. Source remains in `C:\Users\naith\Documents\GitHub\Photo Cleaner`; `N3moStudio/Pearl` was verified private before and after the attempt. No public release, billing change or desktop takeover occurred.

## Delivered build

- Source: `8855a989f75ab3614290b6834072a879b2a7b0f6` on `main`; subsequent changes only document this result and add captures.
- Passing [Codemagic build 3](https://codemagic.io/app/6aec14d6c73110160e3cd00e/build/6aec1ca2004ce28f20ee0ae7), 8m 3s, Mac mini M2, Xcode 26.6.
- **14 core tests and 7 simulator UI tests passed**, with zero test failures. UI suite: 223.820 seconds on iPhone 17 Pro simulator. Release arm64 app and Debug simulator/test targets compiled successfully.
- Download: `C:\Users\naith\Downloads\Pearl-0.2.1.ipa`, **1,335,886 bytes**.
- SHA-256: `18acd023ab2287fb7df287eddf279f134e03204918072dd7fe8f6d04150c898e`.
- Version **0.2.1 (3)**, bundle `com.n3mostudio.pearl`, minimum iOS **18.0**, arm64. Ad-hoc signed for integrity; personal sideload signing/provisioning is still required.

`scripts/verify_ipa.py` passed on the downloaded IPA: package path safety, app identity/version, architecture, background configuration, icon, privacy manifest, license notice, signature resources, and absence of test fixtures/signing credentials. The Mac build also ran strict `codesign` verification. Compiler logs contain no Swift warnings/errors; Apple's metadata tool reports that AppIntents extraction was skipped because Pearl has no AppIntents dependency.

The seven UI checks cover large-text/dark home layout, reversible removal/undo, local photo and video matching, favorite protection and direct partial/full swipes, filmstrip jumps, scan continuity across tabs and restoration after relaunch, leaving-app fallback, and explicit video poster/playback/rapid navigation. Colored-pixel assertions passed for visible media after the relevant interactions. The saved photo and playing-video screenshots were visually inspected, alongside Home, months, cleanup, comparison, resumed scan and large text. See [actual captures](SCREENSHOTS.md).

The simulator used the **saved fallback** when leaving Pearl; this run does not establish granted background processing or Live Activity behavior on an iPhone. Five cached checks were reused after relaunch. The 10,001-item core test checks indexing/recovery logic, not real-library inference speed. Mutation checks were not rerun by the Codemagic workflow; their older result applies only to 0.2.0.

The first two Codemagic attempts compiled and passed core tests but failed UI startup. Their logs showed an early Photos prompt and XCTest's default refusal. The final source registers the library observer only after access is granted and invalidates in-flight refreshes on access loss; the tests explicitly handle the synthetic library permission prompt. Build 3 passed actual onboarding and all later checks without bypassing production permission logic.

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

This GitHub attempt produced no artifact. The later Codemagic result above supersedes its compilation/testing limitation. The previous [0.2.0 receipt](VERIFICATION.md) remains historical evidence only.

## Free path prepared

The private GitHub Actions workflow is manual, standard-runner-only, with a three-day artifact retention. It cannot override GitHub's account block. The user created a personal Codemagic account and connected GitHub, then authorized the remaining setup and build. The manual M2 workflow was run through ChatGPT's built-in browser using that account. [FREE-BUILD.md](FREE-BUILD.md) documents repeating it. No public release was created.

Physical-device preview behavior, gestures, iCloud loading, background execution/Live Activity, signing, performance and battery remain pending in either path.
