# Pearl 0.1.0 delivery

Built November 4, 2026 (America/Los_Angeles). Source commit `00b07129` in the private [N3moStudio/Pearl repository](https://github.com/N3moStudio/Pearl). Subsequent documentation commits do not change the delivered binary.

- **IPA:** `C:\Users\naith\Downloads\Pearl-0.1.0.ipa`
- **Size:** 1,084,793 bytes (about 1.1 MB)
- **SHA-256:** `fc9ace1284715a43523105674fc4ba452c266f3870be7823955d714deef74c8d`
- **App:** Pearl 0.1.0, build 1, `com.n3mostudio.pearl`, arm64, iOS 18+
- **Signing:** ad-hoc integrity signature; import into your personal sideloader to sign/provision for your device.
- **Successful build:** https://github.com/N3moStudio/Pearl/actions/runs/41957741437

## Verified

Xcode 27.1 compiled the Release iPhone app and Debug simulator app. All **9 Swift core tests** and **3 simulator UI tests** passed. The protection-guard mutation was detected by the test, and the source was restored before packaging. The simulator UI tests covered large text with an explicit dark appearance, photo browsing/staging/undo/final review/unstaging, completed local scans, photo comparison with no preselected removals, and local grouping of re-encoded videos.

The seeded simulator library contained 15 items, including synthetic photo variants, an exact file copy and two re-encoded synthetic video clips. It reported 15 checked, 15 originals hashed, and one group in each of Exact duplicates, Similar photos and Possible similar videos. These are fixture results, not a benchmark of real-library accuracy.

The IPA verifier checked bundle ID/version/minimum OS, arm64 Mach-O architecture, app-icon declarations, photo-access usage text, signature resources, privacy manifest, MIT notices and exclusion of test fixtures/credentials/provisioning files. The Mac verified the ad-hoc signature. The downloaded copy's SHA-256 matches the build output.

Actual simulator captures were inspected: Library, Clean Up, Review, Compare and large-text Dark Library. The screenshots use synthetic/stock simulator media. See [screenshots](SCREENSHOTS.md).

## REA artifact inspection

The user's REA skill was used on the **final IPA**, read-only. REA observed the same SHA-256 and a complete container-entry inventory, with 10 file occurrences, 3 directory occurrences and **zero integrity contradictions**. Its scope is archive contents, not runtime behavior, trusted Apple signing, or a complete security review. The native session was closed after export.

- Inventory manifest: `agm_b05a319484516d6cb060804235343e82bbb05e859f8a4a156ebd4fc4d771c5c6`
- Inspection Evidence: `ev_b0ed8f4af4d75c95df96ba72e33c0da3c51adb7ede2e3bb3f1e29c8823b69bf4`
- Inventory Evidence: `ev_a7c62561ef819fc1fc3b3c1447c581007c1df5bf2ae4cb66c2894dd91bf16104`
- [Exported REA Evidence bundle](pearl-0.1.0-rea-evidence.json)

## Still to check on the iPhone

Personal signing and installation, real-library precision/recall, iCloud-only resources, limited/shared libraries, actual system deletion cancellation/failure/recovery, upgrades, VoiceOver, Reduce Transparency, thermal behavior and battery/memory performance remain physical-device acceptance work. No personal photos were accessed or uploaded during development. Use the [first iPhone check](DEVICE-CHECK.md) with disposable copies first.

Small follow-up polish: singular/plural group labels and a compact quick-switch comparison layout. Full Live Photo motion playback, compression, OCR and other unchecked research features are outside this initial build.
