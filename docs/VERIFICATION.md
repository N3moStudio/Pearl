# Pearl 0.2.0 delivery

Built November 4, 2026 (America/Los_Angeles). The delivered IPA is from tested source commit `85036ecf` in the private [N3moStudio/Pearl repository](https://github.com/N3moStudio/Pearl). It includes the home/month/full-screen review redesign, true PhotoKit favorites, direct-drag swipes, faster two-phase local matching, durable scan recovery, and iOS 26+ continued-processing integration.

- **IPA:** `C:\Users\naith\Downloads\Pearl-0.2.0.ipa`
- **Size:** 1,289,342 bytes (about 1.3 MB)
- **SHA-256:** `9af88855d8e14a56b2052ccb2ec4831e1c11889a98d2b8b1d9af4161b884799a`
- **Identity:** Pearl 0.2.0, build 2, `com.n3mostudio.pearl`, arm64, iOS 18+
- **Signing:** ad-hoc integrity signature; personal signing/provisioning through the user's sideloader is still required.
- **Passing CI:** https://github.com/N3moStudio/Pearl/actions/runs/41967547298
- [Previous 0.1.0 verification](VERIFICATION-0.1.0.md)

## Automated and package evidence

Xcode 27.1 compiled Release for iPhone and Debug for the simulator. **14 Swift core tests and 6 simulator UI tests passed.** Two controlled mutations were caught: broken favorite protection and stale-photo checkpoint reuse. Both original files were restored before packaging. Compiler logs contain no Swift diagnostics; Apple's metadata tool notes that there is no AppIntents dependency.

Core tests include a 10,001-item metadata checkpoint round trip, incremental reconciliation after edit/removal, old cross-date duplicate candidates, unavailable-item retry, phase progress, and small/vertical swipe rejection. This is not a 10,000-photo inference benchmark.

The simulator library contained 15 synthetic/stock items. Local scanning found one exact, one similar-photo and one possible similar-video group. The recovery test paused after six completed items, terminated/relaunched the app, and verified that the resumed scan reused six previous checks and finished. UI tests also exercised navigation to other tabs during a scan, actual favorite changes and deletion disabling, filmstrip jumps, swipe/undo, final queue unstaging, and large text/dark appearance.

**Background evidence boundary:** the simulator reported `saved fallback`, not a continued-processing grant. It verified saving/pausing when leaving the app without a grant. Real iPhone background execution, the system Live Activity/Lock Screen, expiration/cancellation and sideloader compatibility remain unverified. The iOS 26+ integration is compiled, with CPU-only Vision and software Core Image to avoid restricted background GPU/Neural Engine entitlements.

The package verifier checked bundle/version/build/minimum OS, arm64 Mach-O, background mode and permitted identifier, icon declarations, Photos usage text, privacy manifest, license notices, signature resources, and absence of fixtures or credentials. The Mac verified the ad-hoc signature. The downloaded IPA and Downloads copy match the CI SHA-256.

[REA](pearl-0.2.0-rea-evidence.json) independently inventoried the final IPA: 10 files, 3 directories, complete container-entry coverage and zero integrity contradictions. REA observed the same hash. This is read-only archive evidence, not a runtime or Apple provisioning guarantee; the session was closed after export.

## Saved source changes not in the IPA

Commit `84aacd4c` adds an accessibility-size row layout for home shortcuts, a one-column media grid at large text sizes, a softer header gradient, and cheaper per-drag filmstrip/count updates. These changes are saved and pushed, but **are not compiled or included in the delivered IPA**.

The final build [41968346754](https://github.com/N3moStudio/Pearl/actions/runs/41968346754) was refused before runner allocation, with GitHub's message: “The job was not started because recent account payments have failed or your spending limit needs to be increased.” No billing settings were changed, no public repository/release was created, and the failed job was not repeatedly retried. Once the account block is cleared, dispatch the existing workflow to validate and package the saved polish revision.

## Visual and device limits

Home, month list, comparison and scan captures were inspected. Normal-size photo review is visible in the queue-test capture, taken during its outgoing transition. The separate month-review capture after a small drag shows a black media area; its first item may be a video and this capture does not establish working video rendering. Verify full-screen video rendering/playback on the iPhone. The largest-text home capture exposed cramped shortcut columns; that correction exists only in the unbuilt polish revision described above.

Physical signing/install, real-library precision/recall, locked/background work, actual video playback, iCloud resources, limited/shared libraries, destructive PhotoKit confirmation/cancel/recovery, gestures/VoiceOver, thermal behavior, memory and battery remain [device acceptance checks](DEVICE-CHECK.md). No personal photos were accessed or uploaded. The user's screenshot references were viewed locally and were not copied into the repository or CI.
