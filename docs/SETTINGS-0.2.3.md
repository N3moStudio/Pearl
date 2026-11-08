# Pearl Native Settings Kit adoption

## Result and preservation

Settings now uses the local Native Settings Kit with compact rounded text, a larger Pearl appearance card, native grouped rows and focused details. Pearl's sage/ivory default remains available alongside the eight kit palettes. Solid and Liquid Glass are independently selectable. Ordinary text uses the kit's one-step compact policy; accessibility sizes pass through unchanged. Decorative symbols stay contained while labels wrap.

The [pre-edit feature map](SETTINGS-FEATURE-MAP.md) records all existing settings/actions and storage owners. No existing setting was removed. PhotoKit permission flows, per-launch iCloud consent, scan/cache guards, async actions, error/notice handling, review decisions, deletion confirmations and cancellation remain with their real models. Pearl has no backup/import/export controls to migrate. Existing review and scan file formats/locations remain compatible; appearance adds only two host-owned UserDefaults keys and never rewrites unknown values on read.

The app model and appearance model are created once. Theme/surface updates change environments, not view IDs or navigation owners. An already-open Settings or queue sheet resolves its selected palette and native scheme explicitly. This fixes a mixed light/dark sheet caught during screenshot inspection. Photo/video previews and the black full-screen swipe presentation keep their existing behavior.

Only this Pearl checkout changed. The original shared kit, Elsepin and Tendelm were not edited. No source was sent to another AI service. Private GitLab and cloud simulator access used CLI/API calls, without browser or desktop control.

## Validation record

- Portable kit validation: eight palettes, 144 solid contrast pairs, minimum 5.09:1; files, links, source ownership and navigation guardrails passed.
- Pearl's light/dark palette: 18 solid contrast pairs, minimum 5.43:1. Translucent backgrounds and physical accessibility usability are separate checks.
- Native validation run `6aefef8024e1ec23755761e7`, source `1a23c163c2b5af325c512b660af7892df4d57dde`: compiled app/package/tests; 20 core tests, three native macOS Vision cases, seven iOS unit tests and ten regular-phone UI tests passed. The small-phone appearance test failed while its whole-app search swiped downward for a lower row; one of two small-phone tests passed. The test now scrolls the actual List in the expected direction. Screenshot review separately found and corrected the mixed Ion sheet colors, with a new dark-canvas assertion. The unsuccessful run is retained in ignored build evidence.
- Final source `ed7886207ad757c887a9109e36452a58d1199136`: [validation run 6aeff49324e1ec23755762f0](https://codemagic.io/app/6aecf0269562a7261fedc429/build/6aeff49324e1ec23755762f0) passed on November 7 at 20:32 PST (13m 10s of execution). All 20 core tests, three native macOS Vision cases, seven iOS unit tests, ten iPhone 17 Pro UI tests and two iPhone SE (3rd generation) UI tests passed. These include persisted choices, independent theme/surface selection, native Back/edge-pop, active scan continuity, cloud restrictions, and maximum accessibility text size. The archive was inspected and contains no IPA. See [structured evidence](SETTINGS-VALIDATION-0.2.3.json).
- The existing no-AppIntents-dependency metadata warning remains nonfatal. Full logs and xcresults are retained under ignored `.build/cloud-0.2.3-settings-verified`; no failing tests were hidden or treated as successful.

The cloud uses the existing personal free M2 account. Before the final dispatch it reported 129.78 free minutes, no subscription/payment information and no paid M2 usage. Pearl queued behind another app without canceling it. After completion it reported 95.18 free minutes, still no subscription/payment information and zero paid M2 seconds. Quota is an account-wide point-in-time snapshot.

## Inspected native captures

These are actual simulator screenshots of the tested source, using synthetic media. The default Pearl and Bloom cards retain the brand artwork; Ion now has consistent dark canvas, rows, toolbar and legible controls. The narrow layouts remain scrollable. At accessibility5 the identity stacks, text wraps and decorative icons remain contained; the native switch stays visible. No text-size cap was added to settings.

| Capture | Regular iPhone | Narrow iPhone SE |
|---|---|---|
| Pearl default | [Settings](screenshots-0.2.3/Pearl-Settings.png) | Default-dark coverage below |
| Bloom / Solid | [Settings](screenshots-0.2.3/Pearl-Settings-Bloom-Solid.png) | [Settings](screenshots-0.2.3/SE-Pearl-Settings-Bloom-Solid.png) |
| Ion / Solid | [Settings](screenshots-0.2.3/Pearl-Settings-Ion-Solid.png) | [Settings](screenshots-0.2.3/SE-Pearl-Settings-Ion-Solid.png) |
| Ion / Liquid Glass | [Appearance](screenshots-0.2.3/Pearl-Appearance-Ion-Glass.png) | [Appearance](screenshots-0.2.3/SE-Pearl-Appearance-Ion-Glass.png) |
| Accessibility5 / dark | [Overview](screenshots-0.2.3/Pearl-Settings-Large-Text-Dark.png), [Scanning](screenshots-0.2.3/Pearl-Scanning-Large-Text-Dark.png) | [Overview](screenshots-0.2.3/SE-Pearl-Settings-Large-Text-Dark.png), [Scanning](screenshots-0.2.3/SE-Pearl-Scanning-Large-Text-Dark.png) |

## Remaining acceptance

Real iPhone permission denial/limited-library picker, cloud download/error paths, VoiceOver/Switch Control, physical gestures, older iOS material fallback, Reduce Transparency/Increase Contrast rendering, landscape/iPad/RTL, battery/thermal behavior and background Live Activity acceptance remain unverified. Automated contract checks cover accessibility category preservation and opaque-fallback policy, not those runtime experiences.

Synthetic simulator flows demonstrate navigation and scan plumbing. Native macOS Vision fixtures demonstrate those production helper/rule cases; neither establishes real iPhone duplicate recall or precision. See [scanner investigation](SCAN-0.2.3.md).

## Delivery boundary

This is source plus simulator validation only. No new IPA or release was built/published. The existing `Pearl-0.2.2.ipa` remains the only Pearl IPA in the user's delivery folder. A new device build requires the user's next explicit request.
