# Pearl

A calm, native iPhone app for browsing, organizing, and reviewing a large photo library in manageable pieces.

**Latest delivered: Pearl 0.2.3 (6), November 7, 2026.** Built privately on Codemagic's free personal M2: 20 core tests, three native Mac Vision cases, seven iOS unit tests and ten simulator UI tests passed. The verified unsigned IPA replaced only the older Pearl IPA in the usual delivery folder. Personal signing and physical-device acceptance remain separate.

This version includes the Native Settings Kit adoption and scanner/Home shortcut corrections. The same local checkout is retained, with synchronized private GitHub (`origin`) and GitLab repositories; no paid billing, browser automation, desktop control or public release was used.

[Latest IPA verification](docs/VERIFICATION-0.2.3.md) · [Settings adoption and screenshots](docs/SETTINGS-0.2.3.md) · [Settings feature map](docs/SETTINGS-FEATURE-MAP.md) · [Scanner investigation](docs/SCAN-0.2.3.md) · [Private build instructions](docs/FREE-BUILD.md)

The user selected the **Pearl visual direction**: warm white, sage accents, rounded shapes, generous spacing, native system glass, textured loading placeholders, and small Thinking Orbs. The first app uses Pearl as its name and `com.n3mostudio.pearl` as its bundle ID, with iOS 18 as the baseline.

Implemented: media/year/month browsing and filters; photo zoom and video playback; full-screen month-based swipe review with direct drag feedback, a filmstrip, real favorite toggle, undo, persistent choices and protection safeguards and a final review queue; album creation and batch filing; streamed exact-file hashes; on-device Vision similar-photo suggestions and five-frame video suggestions. No default deletion selection. Every deletion requires review and the system confirmation.

Analysis is local. Optional iCloud downloads go through Apple; there is no analytics, cloud AI, account, advertising or subscription. On iOS 26+, user-started scans can continue outside Pearl with a system Live Activity when iOS grants background processing. Scans save their place and reuse previous analysis. Older iOS saves progress on leaving; Low Power Mode, heat or system limits can pause work. [Build, architecture and limitations](docs/BUILD.md).

## Start here

- [Feature checklist and acceptance criteria](docs/FEATURE-BACKLOG.md)
- [Product and interaction plan](docs/PRODUCT-PLAN.md)
- [Local similarity and technical groundwork](docs/TECHNICAL-PLAN.md)
- [Research: 29 products and projects](research/LANDSCAPE.md)
- [Existing-app screenshot references](research/VISUAL-REFERENCES.md)
- [Design decisions](design/DESIGN-SPEC.md)
- [Decisions and project status](docs/DECISIONS.md)

![Selected Pearl direction: library, cleanup, and similar-photo review](design/pearl-similarity.png)

![Earlier Pearl, Mist, and Ink directions](design/directions.png)

These are AI-generated concept images with sample media and counts. They do not demonstrate working scanning, performance, accessibility, or native Liquid Glass rendering.

## Workspace

Canonical local repository: `C:\Users\naith\Documents\GitHub\Photo Cleaner`, alongside Elsepin and Calc 84.

Latest tested IPA delivery folder: `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Only the current Pearl IPA is delivered there; older delivered Pearl versions are replaced. No ZIP or checksum sidecar is needed.

The folder is registered in GitHub Desktop's local repository list. Setup used background operations and did not take over the mouse, keyboard or active window.

Active private source/build remote: [gajula.naithik/pearl on GitLab](https://gitlab.com/gajula.naithik/pearl). The existing GitHub remote is preserved but unused. XcodeGen produces the native project from `project.yml`. Codemagic runs core and simulator checks, then builds and packages an unsigned arm64 IPA for personal signing. GitLab CI/CD and Pages are disabled. Signing credentials and personal media are never stored in this repository.

Research date: November 4, 2026, America/Los_Angeles. Sources are linked next to their claims. This is a broad survey, not an exhaustive census of every photo app.
