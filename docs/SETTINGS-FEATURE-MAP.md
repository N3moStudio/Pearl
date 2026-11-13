# Pearl settings adoption map

## Home navigation update

Existing settings, permissions, appearance keys, scan controls, cache actions and review storage remain unchanged. New Settings > Your library > Home order stores stable category IDs in `pearl.home.order`. Native numbered reorder rows change Home's row-major grid immediately; restore-default affects only this key. Albums moves from its tab/shortcut to the first Home grid tile by default; creation and add-to-album remain. Smart Cleanup moves from its tab to Home's native pushed destination; app-owned scan/background/checkpoint lifetime remains unchanged. No custom back gesture or navigation-root recreation is introduced.

Baseline: `e2dcba335fc202d4e2e8f4017d6aff3ef2446852`; clean tracked tree. Scanner fixes and diagnostics already belong to the active task and are preserved. Native Settings Kit 0.1.0 is adopted into this existing checkout, with iOS 18 support unchanged. Latest user scope permits simulator validation, not another IPA or release.

| Existing setting/action | Current model / storage | Current location → new location | Preserved behavior / checks |
|---|---|---|---|
| Open / dismiss Settings | RootView.settings; native modal; dismiss environment | Toolbar → same; Done → same | Keep one navigation owner, native Back and sheet dismissal |
| Photo authorization status | PearlModel.authorization from PhotoKit, no app preference | Your library → Photo access → same | All / selected / denied / restricted / not-set / unknown states |
| Choose more photos | limitedPicker state; LimitedLibraryEditor → PhotoKit | Photo access, limited authorization only → same | System picker, once-per-presentation guard, refresh on dismissal |
| Open iOS Settings | UIApplication.openSettingsURLString | Photo access → same | Actual system action, no simulated permission switch |
| iCloud downloads | PearlModel.allowCloud, intentionally in memory and off each launch | Scanning → same | Immediate real binding; disabled while scanning; retain explanatory footer |
| Background scanning explanation | Existing BGContinuedProcessingTask and saved-fallback policy | Scanning disclosure → Scanning → How scanning works detail | Retain iOS version, force-quit, power/heat and cancellation limits |
| Photo/video matching explanation | SimilarityScanner / MatchRules / ScanCheckpoint | Scanning disclosure → same focused help detail | Exact versus similar, Live stills, five frames, no automatic removal |
| iCloud explanation | Same optional per-launch scan permission | Scanning disclosure → same focused help detail | Downloads are through Apple, local analysis, reset policy retained |
| Privacy information | Actual local scan / ReviewStore / queue behavior | Your data → Privacy → same | Keep no-upload/no-account information and review-before-delete rules |
| Clear analysis cache | PearlModel.clearCache(); scanner.clear(); cache + checkpoint only | Analysis cache → same | Keep scanning/clearing gates, async completion, model errors/notices, original media and review choices |
| Version, build, maker | Installed bundle info; N3mo Studio | About Pearl → same | Read real installed metadata; no copied demo versions |
| Open-source notices | Bundled OpenSourceNotices.txt with fallback | About → Open-source notices → same | Selectable full notices; add retained kit attribution |
| Scan start/pause/recheck, Live Activity, review queue and confirmations | Existing app model / checkpoint / ReviewStore / PhotoKit | Feature screens → unchanged | Appearance changes must not recreate the app model, navigation or active task |

Pearl has no backup/import/export or account/subscription settings to move. Its review-v1 and scan-v1 files, bundle ID, permission flows and per-launch iCloud default stay unchanged by this adoption.

New appearance controls are real host-owned preferences: `pearl.appearance.theme` and `pearl.appearance.surface` in UserDefaults. Missing or unknown values are read without overwriting storage. The existing Pearl sage/ivory look remains the default; eight kit palettes are optional. Surface choices are Solid and Liquid Glass, independent of theme. Existing material presentation remains the initial surface. No font/density switch or demo state is added.

Validation completed: native preference round trips, theme/surface independence, preserved navigation and scan work, the app regression suite, kit contracts, narrow and maximum-text screenshots passed/reviewed. See [native evidence and remaining checks](SETTINGS-0.2.3.md). System permission denial/limited-picker paths, real device gestures/accessibility services, download/error scenarios and battery remain unverified; their production handlers were retained. No backup/import format exists to test.
