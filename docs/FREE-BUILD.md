# Private GitLab and free Codemagic builds

Current authorization, November 5, 2026: use CLI/API access only. Keep the existing checkout at `C:\Users\naith\Documents\GitHub\Photo Cleaner`; its `gitlab` remote is `https://gitlab.com/gajula.naithik/pearl.git`. The GitHub remote stays configured but unused while the account is suspended. GitLab source is private, with GitLab CI/CD and Pages disabled.

Codemagic uses a repository-specific read-only SSH deployment key. Private keys and the encrypted API token stay outside the repository and must never appear in command output or logs. The personal account, rather than a paid Team, owns the app.

Before dispatch, check the personal account's remaining free M2 time and billing state through the API. The personal plan includes 500 monthly M2 minutes. Never enable billing, add payment information, switch to paid machines or raise concurrency. Let Pearl queue if Tendelm is running; do not cancel or modify Tendelm.

Push the reviewed source to `gitlab`, then manually request workflow `pearl-private-ipa` on `main`, instance `mac_mini_m2`, with remote access disabled. The workflow is capped at 30 minutes, uses Xcode 26.6 and has no automatic triggers, publication or notification steps.

The workflow runs 14 core tests and seven simulator UI tests before producing a Release arm64 IPA. It verifies identity, version, privacy resources, architecture and the absence of provisioning/signature material. Build 4 is unsigned; the user's sideloader supplies personal signing.

Download the IPA and engineering evidence through authenticated APIs into ignored local build storage. Review results and package verification, then replace only Pearl's previous IPA in `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Deliver only the IPA. Keep logs, test bundles, screenshots and checksum records inside the repository, never as extra delivery files.

Sources checked November 5, 2026: [Codemagic pricing](https://docs.codemagic.io/billing/pricing/), [application API](https://docs.codemagic.io/rest-api/applications/), [API authentication](https://docs.codemagic.io/rest-api/codemagic-rest-api/). Historical GitHub attempts and the previous build 3 receipt remain in `VERIFICATION-0.2.1.md`.
