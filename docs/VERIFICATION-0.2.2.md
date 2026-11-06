# Pearl 0.2.2 (5) verification

November 6, 2026. Tested source: `b1bb0ce74aa4121e1c87cdceb0a81d4b4e375dea`, in the existing checkout at `C:\Users\naith\Documents\GitHub\Photo Cleaner`. Subsequent documentation changes do not change the tested app or tests.

## Result

- [Codemagic run](https://codemagic.io/app/6aecf0269562a7261fedc429/build/6aee5bee24e1ec237556fd68): successful, 677.029 seconds, personal free `mac_mini_m2`, Xcode 26.6.
- **14 core and 8 simulator UI tests passed**, zero failures in the final run. UI suite: 254.661 seconds on iPhone 17 Pro simulator. Debug simulator/test targets and Release arm64 app compiled successfully.
- Version **0.2.2 (5)**, bundle `com.n3mostudio.pearl`, iOS 18+, arm64, **1,371,296 bytes**. Unsigned; personal sideload signing is required.
- Delivered only `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Pearl-0.2.2.ipa`. The previous Pearl 0.2.1 IPA was removed after checking the replacement and the older app's identity. Other projects' files remain untouched.
- `scripts/verify_ipa.py` passed on the cloud, downloaded and delivered copies. Integrity, bundle/version, architecture, privacy resources, background configuration, notices and absence of credentials/test fixtures/signature material were checked. The downloaded copy matches the cloud package.

The [machine-readable receipt](BUILD-RECEIPT-0.2.2.json) retains integrity evidence inside the source workspace. Logs, test results and other captures remain in private Codemagic artifacts and ignored `.build/cloud-0.2.2-delivery` storage. No checksum sidecar, ZIP, log or report was delivered to the IPA folder.

## Settings changes and checks

The main page now contains six compact rows under Your library, Your data and About, a centered inline title, rounded native groups and contained sage icon badges. Photo access, limited-library editing, iOS Settings, iCloud downloads, privacy information, cache clearing and licenses remain available. Longer matching/background explanations are collapsed inside the relevant pages. Version and build read from the installed bundle instead of a stale literal.

The new UI flow verifies photo-access navigation, changing the iCloud switch, navigating through cache and About, retaining the preference across navigation, and resetting it off after relaunch. The existing large-text/dark test now opens Settings and Scanning. Root, About and maximum-text/dark settings captures from the passing run were inspected; the final app's Scanning layout was also inspected in the preceding run with identical app source. See [actual settings captures](SETTINGS-0.2.2.md). The seven pre-existing checks still cover media previews/playback, review/undo/favorites/filmstrip, local photo/video matching, cross-tab scanning and saved recovery.

Two earlier runs stopped before packaging on new test assertions. Run `6aee4d0a24e1ec237556f8dd` tapped the broad switch row without changing its state; the label was simplified and the test now targets the switch thumb and waits for its accessible value. Its captures also exposed icons overflowing their fixed badges at maximum text size; the icons are now contained. Run `6aee500a24e1ec237556f9e2` passed the switch check but looked for the native version row as standalone text. The test now accepts the row's accessible label or value. The final run passed the complete flow; earlier failed artifacts were never delivered.

The compiler logs contain no Swift errors or warnings; Apple's metadata tool reports skipped AppIntents extraction because Pearl does not depend on that framework.

## Evidence limits and privacy

The background simulator path was **saved fallback**. This does not prove a granted background scan or Live Activity on an iPhone. Physical-device gestures, VoiceOver, limited-picker presentation, iCloud loading, signing, battery and large-library inference speed remain device checks. Cache mutation/scan guards remain unchanged; the new navigation test verifies the clear-cache control is reachable without clearing user data. Historical mutation checks were not rerun.

GitLab was verified private after the build, with GitLab CI/CD and Pages disabled. The personal Codemagic account reported **275.13 free minutes remaining**, no paid subscription/payment information and zero paid M2 seconds. No paid billing, public release, browser automation, desktop control, or cancellation/modification of another project's build occurred.
