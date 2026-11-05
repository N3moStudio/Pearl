# Pearl 0.2.1 (4) verification

November 5, 2026, America/Los_Angeles. The existing local checkout at `C:\Users\naith\Documents\GitHub\Photo Cleaner` was reused. Source is hosted privately at `gajula.naithik/pearl` on GitLab. GitHub's remote remains configured but unused. No browser automation, desktop control, billing changes, public release or cancellation of another project's build occurred.

## Built and delivered

- Tested source: `731579e206da3091d235f25b76a93ed24018b21c`; later receipt changes affect documentation only.
- [Codemagic run](https://codemagic.io/app/6aecf0269562a7261fedc429/build/6aecf040ab17f8deb7533597): completed successfully in 499.667 seconds on the personal account's free `mac_mini_m2`, Xcode 26.6.
- **14 core tests and 7 simulator UI tests passed**, with zero failures. UI suite: 202.667 seconds on iPhone 17 Pro simulator. Debug simulator/test targets and Release arm64 app compiled successfully.
- Version **0.2.1 (4)**, bundle `com.n3mostudio.pearl`, minimum iOS **18.0**, arm64, **1,326,837 bytes**.
- Delivered only `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Pearl-0.2.1.ipa`, replacing Pearl build 3. Other applications' files were untouched.
- The IPA is **unsigned**; the sideloader must supply personal signing and provisioning.

`scripts/verify_ipa.py` passed on the cloud artifact, downloaded artifact and final delivered copy. The copies match. Checks cover package path safety, identity/version, arm64 Mach-O, background configuration, icon, privacy manifest, license notice, absence of bundled test fixtures/signing credentials, and absence of signature directories and executable signature load commands. The machine-readable [receipt](BUILD-RECEIPT-0.2.1-4.json) retains engineering integrity evidence without a delivery sidecar.

The seven UI tests cover large-text/dark layout, library review and reversible removal, local photo/video scan, favorite protection and continuous partial/full swipes, filmstrip navigation, scan continuity across tabs and restoration after relaunch, leaving-app fallback, and video poster/playback/rapid navigation. Visible-media assertions passed; this build's photo-review and video-playback captures were also visually inspected and show the synthetic media. Full logs, test results and captures remain in ignored local `.build/cloud` storage and private Codemagic artifacts.

No Swift compile warnings or errors were found in the simulator/device logs. Apple's metadata tool reports skipped AppIntents extraction because the app has no AppIntents dependency. A nonfatal Homebrew tap update notice did not prevent XcodeGen setup or compilation.

## Limits and account checks

The simulator exercised the **saved fallback** when leaving Pearl. This does not establish a granted background task or Live Activity on an iPhone. The 10,001-item core test covers indexing/recovery, not real-library inference throughput. Historical mutation tests were not rerun in this workflow. Physical-device signing, preview behavior, gestures, iCloud loading, background execution, battery and performance still require device checks.

GitLab visibility was verified private after the build; CI/CD and Pages remain disabled. Codemagic's personal account reported **461.82 free minutes remaining**, no paid subscription, no payment information, and **zero paid M2 seconds** after completion. Usage is shared with other apps, so the difference from the pre-build balance is not Pearl's individual duration. No paid billing was enabled and no Tendelm files or builds were modified.

The app retains the existing preview repair and approved Pearl UI. This build changes the build number and private build/package workflow, including simulator checks before packaging and removal of linker-generated ad-hoc signatures. The [build 3 receipt](VERIFICATION-0.2.1.md) remains historical evidence.
