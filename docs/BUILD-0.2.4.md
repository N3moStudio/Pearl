# Pearl 0.2.4 (7) validation

User authorized GitHub Actions tests/build and local IPA replacement on November 14, 2026, after the local refinement. No public release or billing change.

Checklist: core Swift tests and both safety mutation checks; native simulator build; full iOS unit/UI tests; narrow-phone appearance and maximum-text checks; Release arm64 build; unsigned IPA identity/resources/privacy verification; authenticated artifact retrieval and local verification before replacing Pearl only. Preserve bundle ID, saved formats and other apps' IPAs.

Local preflight: changed Swift syntax checks, build-script Bash syntax and git whitespace check passed. Native results will be recorded after the cloud run. Physical iPhone gesture feel, limited/iCloud photo scenarios, background grants/Live Activity, thermal behavior and battery remain device acceptance checks.

## Completed cloud and delivery evidence

GitHub Actions [43648318258](https://github.com/N3moStudio/Pearl/actions/runs/43648318258) passed on source `af61445103f2d66cd1c964dfffb0015e54035391`. All 23 core tests and both safety mutation checks passed. Native simulator compilation passed, followed by 8 iOS unit tests and 11 UI tests with zero failures. The additional iPhone SE appearance/navigation and maximum-text tests both passed (21 native executions total). Release arm64 compilation and unsigned package verification passed. No test was disabled or retried to obtain this result.

Downloaded artifact 14135524418 through authenticated API access; archive integrity and local `verify_ipa.py` passed. Verified version 0.2.4/build 7, bundle identity, arm64 executable, unsigned payload, privacy/notices resources and absence of test fixtures. Verified the delivered copy before deleting only Pearl-0.2.3.ipa. Current delivery: `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Pearl-0.2.4.ipa`. Other projects and the desktop were untouched.

Inspected native Settings, narrow maximum-text dark Settings and review screenshots. Review capture is mid-transition (disabled action controls), not steady-state motion evidence. Normal settings rows are compact; maximum accessibility text wraps/scrolls rather than being capped. Full logs, xcresults, screenshot artifacts and package evidence stay under ignored `.build/github-43648318258/`. Physical-device acceptance remains pending.

GitHub main is updated. The separate GitLab mirror push failed because its saved credential was rejected; it remains behind and was not used for this build. No repository release or billing changes. Non-blocking logs include AppIntents metadata extraction skipped (no AppIntents dependency) and third-party GitHub Action runtime deprecation warnings.
