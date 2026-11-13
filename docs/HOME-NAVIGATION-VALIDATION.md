# Home navigation and media order

Home is now the single navigation root. Cleanup and Albums use native pushed pages and native Back/interactive edge-pop. Cleanup navigation does not start or pause a scan; Start/Resume remains explicit. The model and background task remain owned by the app.

The twelve Home categories follow the requested order. Native PhotoKit smart albums provide the specialized categories, intersected with the accessible library. Settings > Your library > Home order offers numbered native reorder handles and a restore-default action. Only `pearl.home.order` is new persistence; photo review, scan cache, appearance, permissions and album actions remain.

Validation: GitHub run 43380500806, production commit 2ec85529da1a59114c352de02e191487ca0ad0cb, compiled natively and passed all 8 iOS unit tests and all 11 main iOS UI tests. Core tests and both safety mutation checks passed. This includes cleanup opening, native edge-pop, Home order persistence, Settings navigation, theme changes during scans, scan progress across pages, checkpoint recovery after relaunch, and the simulator background fallback/continued-processing path.

The additional iPhone SE maximum-text test failed because the Home shortcut was below the fold, whereas its old tab-bar counterpart was always visible. The test now scrolls the Home scroll view before asserting reachability. That test-only correction has not been rerun; the overall cloud run is therefore not reported as green. The other SE appearance/navigation test passed.

Inspected native Home and Home order screenshots from run 43373093345 under ignored `.build/home-navigation/`. Complete diagnostic logs/artifacts remain there. Earlier runs exposed and led to fixes for scan-start semantics, sheet Back-button test targeting, Settings access on the pushed cleanup page, and a startup race between overlapping Photos refreshes and checkpoint restoration.

Physical-iPhone interactive gesture feel, large-library category counts, background grants/Live Activities, battery and limited-photo scenarios still need device acceptance. No IPA was packaged or replaced for this work. Earlier compression and broader settings-density requests remain separate unfinished work.
