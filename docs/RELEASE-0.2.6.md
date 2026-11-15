# Pearl 0.2.6 (9)

Requested November 15, 2026: build the latest Pearl IPA and replace only Pearl's older IPA in the usual delivery folder. No release publication, billing changes or desktop control.

Includes the tested Privacy padding/alignment, compact album lists, and Organize albums inside the destination picker. Favorite/order storage, selected media, cancellation, real Photos operations and background scan ownership are preserved. Layout and interaction evidence is recorded in SETTINGS-FEATURE-MAP.md.

## Build and tests

- Source: `86ad9020e91963b7f06beb2f0a2da59f9698b16c`.
- Successful [GitHub Actions run 43760338195](https://github.com/N3moStudio/Pearl/actions/runs/43760338195), job `132953502154`, artifact `14180733966`.
- Passed 28 core tests, native Mac Vision fixture checks, both safety mutations, 11 iOS unit tests, 15 main iPhone UI tests and two additional iPhone SE UI executions. This includes native album dragging, favorite changes, picker order after relaunch, selection cancellation, Privacy spacing and accessibility text.
- Simulator and Release arm64 builds passed. Only Release build warning: skipped App Intents metadata extraction because the app has no App Intents dependency.
- Independently inspected the downloaded IPA: version 0.2.6, build 9, 1,878,699 bytes, unsigned arm64 executable, expected identity/background metadata, privacy manifest and third-party notices; no signing material or test fixtures. Complete ZIP/logs/screenshots and package verification remain under ignored `.build/github-43760338195/`.

## Delivery

Copied and reverified `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Pearl-0.2.6.ipa`, then removed only `Pearl-0.2.5.ipa`. Other projects were untouched. Only the IPA was added to the delivery folder. Subsequent documentation commits do not change the tested implementation.

Personal sideload signing and physical-iPhone acceptance remain pending. Simulator results do not establish real-library matching accuracy, changing permissions, iCloud/network failures, long background grants, thermal behavior or battery use.
