# Pearl 0.2.3 (6) private IPA

Built and delivered November 7, 2026, after the user's explicit IPA request. Tested source `a09349693294d731dfbf60afe2778028c07490c1`; subsequent documentation changes do not alter the tested app, dependencies or tests.

- [Private Codemagic run](https://codemagic.io/app/6aecf0269562a7261fedc429/build/6af018f424e1ec2375576960) passed in 11m 43s on the personal free `mac_mini_m2`, Xcode 26.6 (17F113). No paid billing, browser/desktop control, public release or cancellation of another project.
- 20 core tests, three native macOS Vision cases, seven iOS unit tests and ten iPhone simulator UI tests passed, zero failures. Debug app/test targets and the Release device app compiled successfully.
- Two narrow iPhone SE UI tests and 11 inspected settings captures from the preceding validation are reused after confirming identical app/package/test/build sources. They were not rerun by the IPA workflow. The latest run's default Pearl and dark Ion settings captures were also inspected.
- Package: `com.n3mostudio.pearl`, version 0.2.3, build 6, iOS 18+, real-device arm64, 1,683,588 bytes. Unsigned; the user's sideloader supplies personal signing.
- Only `Pearl-0.2.3.ipa` was delivered to `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. The delivered copy passed verification before deleting `Pearl-0.2.2.ipa`; the old file's bundle identity was checked first. Other projects' files were preserved. No ZIP, report, log or verification sidecar was added to that folder.

The cloud, downloaded and delivered packages agree. Checks cover identity/version, iPhoneOS platform and Mach-O platform/architecture, privacy resources (including UserDefaults reason), background task identifiers, icon metadata, retained ThinkingOrbs/Native Settings Kit notices, and absence of provisioning/signature material or test fixtures. The [internal receipt](BUILD-RECEIPT-0.2.3.json) retains package evidence. Full logs, screenshots, xcresults and downloads remain in private Codemagic artifacts and ignored `.build/cloud-0.2.3-ipa-final` storage.

The initial free allowance snapshot was 85.63 minutes; after delivery the account reported 72.23 minutes, no subscription/payment information and zero paid M2 seconds. These are account-wide snapshots, not a measurement of only this build's consumption. GitLab remains private with its CI/CD and Pages disabled.

## Included changes

[Native Settings Kit adoption](SETTINGS-0.2.3.md) adds compact rounded text, the larger Pearl appearance card, grouped native rows, focused help, and independent persisted theme/surface choices without resetting navigation or scan work. Existing actions, stored review data, permission handling and confirmations remain connected to their original models. [Scanner corrections](SCAN-0.2.3.md) repair the Home shortcut, improve bounded candidate retrieval, include Live Photo stills in visual comparison, and recheck older matches while retaining usable analysis.

## Remaining physical-device checks

Signing/installation, real-library duplicate recall/precision, large-library performance, iCloud/limited-access error paths, gestures/accessibility services, thermal/battery behavior and a granted background Live Activity remain unverified on an iPhone. The simulator exercised the saved-background fallback. Native macOS Vision fixtures validate those production-helper cases; this is not proof of iPhone inference quality. The prior cloud iOS simulator anomaly and unchanged matching thresholds remain documented in the scanner investigation.

Only the existing nonfatal no-AppIntents-dependency metadata warning appeared in compiler logs; no Swift errors/warnings were found. No new app behavior was changed just to package this IPA.
