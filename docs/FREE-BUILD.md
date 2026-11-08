# Private GitLab and free Codemagic builds

Current authorization, November 5, 2026: use CLI/API access only. Keep the existing checkout at `C:\Users\naith\Documents\GitHub\Photo Cleaner`; its `gitlab` remote is `https://gitlab.com/gajula.naithik/pearl.git`. The user subsequently requested GitHub synchronization on November 7; access and private visibility were verified. `origin` is `https://github.com/N3moStudio/Pearl.git`, and `main` tracks `origin/main`. Keep GitLab synchronized for the existing Codemagic connection. GitLab source is private, with GitLab CI/CD and Pages disabled.

Codemagic uses a repository-specific read-only SSH deployment key. Private keys and the encrypted API token stay outside the repository and must never appear in command output or logs. The personal account, rather than a paid Team, owns the app.

Before dispatch, check the personal account's remaining free M2 time and billing state through the API. The personal plan includes 500 monthly M2 minutes. Never enable billing, add payment information, switch to paid machines or raise concurrency. Let Pearl queue if Tendelm is running; do not cancel or modify Tendelm.

Latest scope, November 7: the user explicitly requested an IPA after the completed settings validation. Use `pearl-private-ipa` on reviewed private `main`, instance `mac_mini_m2`, with remote access disabled. It is capped at 30 minutes, uses Xcode 26.6 and has no automatic triggers, release publication or notification steps. `pearl-private-validation` remains available for future source checks without packaging. Keep later builds within the user's requested scope.

The current validation workflow runs 20 core tests, three native macOS Vision accuracy cases, seven iOS unit tests, ten regular-phone UI tests, and two focused narrow-phone UI tests. The configured counts are not a result claim; see [the current validation report](SETTINGS-0.2.3.md) for actual execution. It deliberately produces no IPA. The separate historical IPA workflow performs simulator checks before packaging a Release arm64 app; personal signing remains the sideloader's responsibility.

The current app is `6aecf0269562a7261fedc429`. [Build 6](VERIFICATION-0.2.3.md) is the latest delivered IPA, with the current settings and scanner changes. Its post-delivery account snapshot was 72.23 free minutes, no paid subscription/payment information and zero paid M2 seconds.

Historical [Build 5](https://codemagic.io/app/6aecf0269562a7261fedc429/build/6aee5bee24e1ec237556fd68) passed on November 6, 2026 in approximately 11m 17s. See the [build receipt](VERIFICATION-0.2.2.md) for the tested source and evidence boundaries. After the build, the personal account reported about 275.13 free minutes remaining, no paid subscription or payment information, and zero paid M2 seconds; this is an account-wide snapshot, not a promise of future availability.

Only after a future explicit IPA request: download the IPA and engineering evidence through authenticated APIs into ignored local build storage. Review results and package verification, then replace only Pearl's previous IPA in `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Deliver only the IPA. Keep logs, test bundles, screenshots and checksum records inside the repository, never as extra delivery files.

Sources checked November 5, 2026: [Codemagic pricing](https://docs.codemagic.io/billing/pricing/), [application API](https://docs.codemagic.io/rest-api/applications/), [API authentication](https://docs.codemagic.io/rest-api/codemagic-rest-api/). Historical GitHub attempts and the previous build 3 receipt remain in `VERIFICATION-0.2.1.md`.
