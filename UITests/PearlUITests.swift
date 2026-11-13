import XCTest
import UIKit

final class PearlUITests: XCTestCase {
    @MainActor func testHomeNavigationAndOrderSettings() {
        let app = XCUIApplication(); launchReady(app)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        let albums = app.buttons["mediaAlbums"], photos = app.buttons["mediaPhotos"]
        XCTAssertTrue(albums.waitForExistence(timeout: 10))
        XCTAssertLessThan(albums.frame.minX, photos.frame.minX)
        XCTAssertEqual(albums.frame.minY, photos.frame.minY, accuracy: 2)
        albums.tap()
        XCTAssertTrue(app.navigationBars["Albums"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["homeSmartCleanup"].tap()
        XCTAssertTrue(app.navigationBars["Smart Cleanup"].waitForExistence(timeout: 5))
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        app.buttons["settingsHomeOrder"].tap()
        XCTAssertTrue(app.navigationBars["Home order"].waitForExistence(timeout: 5))
        capture(app, "Pearl-Home-Order")
    }
    override func setUp() { super.setUp(); continueAfterFailure = false }
    @MainActor func testLargeTextAndDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "--ui-test-dark"]
        launchReady(app)
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["homeSmartCleanup"].isHittable)
        app.swipeUp()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Pearl-Large-Text-Dark"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let scanning = app.buttons["settingsScanning"]
        capture(app, "Pearl-Settings-Large-Text-Dark")
        reveal(scanning, in: app)
        XCTAssertGreaterThanOrEqual(scanning.frame.height, 44)
        scanning.tap()
        XCTAssertTrue(app.switches["scanCloudDownloads"].waitForExistence(timeout: 5))
        capture(app, "Pearl-Scanning-Large-Text-Dark")
    }

    @MainActor func testSettingsNavigationAndCloudPreference() {
        let app = XCUIApplication(); launchReady(app)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settingsPhotoAccess"].isHittable)
        XCTAssertTrue(app.buttons["settingsAppearance"].isHittable)
        capture(app, "Pearl-Settings")
        app.buttons["settingsPhotoAccess"].tap()
        XCTAssertTrue(app.buttons["Open iOS Settings"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["settingsScanning"].tap()
        let cloud = app.switches["scanCloudDownloads"]
        XCTAssertTrue(cloud.waitForExistence(timeout: 5))
        XCTAssertEqual(cloud.value as? String, "0")
        capture(app, "Pearl-Scanning-Settings")
        XCTAssertTrue(cloud.isEnabled)
        // SwiftUI exposes the whole labeled row as a switch. Target the thumb,
        // rather than the row's center, then wait for its accessible state.
        cloud.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        let enabledCloud = NSPredicate(format: "value == '1'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabledCloud, object: cloud)], timeout: 5), .completed)
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["settingsCache"].tap()
        XCTAssertTrue(app.buttons["clearAnalysisCache"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        reveal(app.buttons["settingsAbout"], in: app)
        app.buttons["settingsAbout"].tap()
        XCTAssertTrue(app.navigationBars["About Pearl"].waitForExistence(timeout: 5))
        capture(app, "Pearl-About-Settings")
        // LabeledContent can expose a combined label or an accessibility value.
        let version = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS '0.2.3' OR value == '0.2.3'")).firstMatch
        XCTAssertTrue(version.waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        reveal(app.buttons["settingsScanning"], in: app, towardEarlierRows: true)
        app.buttons["settingsScanning"].tap()
        XCTAssertEqual(cloud.value as? String, "1", "Navigating settings must keep the current scan preference")
        app.terminate(); launchReady(app)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settingsScanning"].waitForExistence(timeout: 5))
        app.buttons["settingsScanning"].tap()
        XCTAssertTrue(cloud.waitForExistence(timeout: 5))
        XCTAssertEqual(cloud.value as? String, "0", "iCloud downloads must remain off by default each launch")
    }
    @MainActor func testLibraryReviewQueue() throws {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-review"]; launchReady(app)
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        let library = XCTAttachment(screenshot: app.screenshot()); library.name = "Pearl-Library"; library.lifetime = .keepAlways; add(library)
        app.buttons["mediaPhotos"].tap()
        let item = app.buttons.matching(identifier: "mediaItem").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10)); item.tap()
        let remove = app.buttons["stageRemoval"]
        XCTAssertTrue(remove.waitForExistence(timeout: 10)); remove.tap()
        waitEnabled(app.buttons["undoReview"], true)
        app.buttons["undoReview"].tap()
        XCTAssertFalse(app.buttons["undoReview"].isEnabled)
        remove.tap()
        let review = XCTAttachment(screenshot: app.screenshot()); review.name = "Pearl-Review"; review.lifetime = .keepAlways; add(review)
        app.buttons["closeReview"].tap()
        XCTAssertTrue(app.buttons["reviewQueue"].waitForExistence(timeout: 5))
        app.buttons["reviewQueue"].tap()
        XCTAssertTrue(app.navigationBars["Review removal"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["confirmRemoval"].isEnabled)
        app.buttons["Keep"].firstMatch.tap()
        XCTAssertFalse(app.buttons["confirmRemoval"].isEnabled)
        app.buttons["Done"].tap()
    }
    @MainActor func testLocalPhotoAndVideoScan() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-clear-scan", "--ui-test-reset-review"]; launchReady(app)
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        let shortcut = app.buttons["homeSmartCleanup"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        // Hit the padded edge, not just the icon or text, and require a real scan.
        shortcut.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.4)).tap()
        XCTAssertTrue(app.navigationBars["Smart Cleanup"].waitForExistence(timeout: 10))
        app.buttons["scanButton"].tap()
        let complete = app.staticTexts["Scan complete. You choose what stays."]
        XCTAssertTrue(complete.waitForExistence(timeout: 120))
        let cleanup = XCTAttachment(screenshot: app.screenshot()); cleanup.name = "Pearl-Clean-Up"; cleanup.lifetime = .keepAlways; add(cleanup)
        app.buttons["matchesexact"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10), "The known byte-for-byte fixture copy must be found")
        XCTAssertEqual(app.buttons.matching(identifier: "matchGroup").count, 1, "Reencoded photos must not become exact copies")
        capture(app, "Pearl-Exact-Duplicates")
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["matchesphoto"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["matchGroup"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Review selection"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Review selection"].isEnabled)
        let comparison = XCTAttachment(screenshot: app.screenshot()); comparison.name = "Pearl-Compare"; comparison.lifetime = .keepAlways; add(comparison)
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["matchesvideo"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10), "Synthetic re-encoded videos should match locally")
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["scanOptions"].tap()
        app.buttons["Recheck all matches"].tap()
        XCTAssertTrue(complete.waitForExistence(timeout: 120))
        app.buttons["matchesexact"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10), "Rechecking must preserve verified duplicate results")
    }

    @MainActor func testMonthReviewFavoriteFilmstripAndContinuousSwipe() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-review"]; launchReady(app)
        XCTAssertTrue(app.buttons["openSwipe"].waitForExistence(timeout: 20)); app.buttons["openSwipe"].tap()
        XCTAssertTrue(app.buttons["swipeMonth"].firstMatch.waitForExistence(timeout: 10))
        capture(app, "Pearl-Months")
        app.buttons["swipeMonth"].firstMatch.tap()
        let favorite = app.buttons["favoriteItem"], remove = app.buttons["stageRemoval"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 10))
        assertVisibleMedia(app)
        if favorite.label == "Remove from favorites" { favorite.tap(); waitEnabled(remove, true) }
        favorite.tap(); waitEnabled(remove, false)
        XCTAssertEqual(favorite.label, "Remove from favorites")
        favorite.tap(); waitEnabled(remove, true)
        let progress = app.staticTexts["reviewProgress"], before = progress.label
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 18, dy: 0)))
        XCTAssertEqual(progress.label, before, "A partial drag must not decide")
        assertVisibleMedia(app)
        capture(app, "Pearl-Fullscreen-Review")
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.45)))
        waitEnabled(app.buttons["undoReview"], true)
        app.buttons["undoReview"].tap()
        XCTAssertEqual(progress.label, before)
        let second = app.buttons["reviewThumbnail1"]
        XCTAssertTrue(second.exists); second.tap()
        XCTAssertTrue(progress.label.hasPrefix("2 of"))
        assertVisibleMedia(app)
        app.buttons["reviewThumbnail0"].tap()
        assertVisibleMedia(app)
        app.buttons["closeReview"].tap()
        XCTAssertTrue(app.navigationBars["Swipe"].exists)
    }

    @MainActor func testVideoPosterPlaybackAndRapidNavigation() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-review"]; launchReady(app)
        XCTAssertTrue(app.buttons["mediaVideos"].waitForExistence(timeout: 20))
        app.buttons["mediaVideos"].tap()
        let item = app.buttons.matching(identifier: "mediaItem").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10)); item.tap()
        let play = app.buttons["playPreview"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        assertVisibleMedia(app)
        capture(app, "Pearl-Video-Poster")
        play.tap()
        let ready = NSPredicate { _, _ in
            app.descendants(matching: .any).matching(identifier: "previewVideo").allElementsBoundByIndex
                .contains { ($0.value as? String) == "Ready" }
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: app)], timeout: 25), .completed)
        assertVisibleMedia(app)
        capture(app, "Pearl-Video-Playback")
        app.buttons["reviewThumbnail1"].tap()
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        app.buttons["reviewThumbnail0"].tap()
        XCTAssertTrue(play.waitForExistence(timeout: 10), "Navigating away must cancel playback and discard the old player")
        assertVisibleMedia(app)
        app.buttons["closeReview"].tap()
    }

    /// Sample the photo region, excluding chrome/buttons and the filmstrip.
    /// All generated fixtures have colored landscapes here; a blank black
    /// player or a spinner must not satisfy the preview regression check.
    @MainActor private func assertVisibleMedia(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let visible = NSPredicate { _, _ in self.coloredMediaFraction(app) > 0.25 }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: app)], timeout: 15)
        if result != .completed { capture(app, "Pearl-Preview-Failure") }
        XCTAssertEqual(result, .completed, "Expected a visible colored photo/video, not a black preview", file: file, line: line)
    }

    @MainActor private func coloredMediaFraction(_ app: XCUIApplication) -> Double {
        guard let image = app.screenshot().image.cgImage else { return 0 }
        let rect = CGRect(x: Double(image.width) * 0.15, y: Double(image.height) * 0.32,
                          width: Double(image.width) * 0.7, height: Double(image.height) * 0.28)
        guard let crop = image.cropping(to: rect) else { return 0 }
        let size = 48
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        return pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: size, height: size, bitsPerComponent: 8,
                bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
            let data = bytes.bindMemory(to: UInt8.self)
            var colored = 0
            for offset in stride(from: 0, to: data.count, by: 4) {
                let high = max(data[offset], data[offset + 1], data[offset + 2])
                let low = min(data[offset], data[offset + 1], data[offset + 2])
                if high > 60 && high - low > 18 { colored += 1 }
            }
            return Double(colored) / Double(size * size)
        }
    }

    @MainActor func testScanContinuesAcrossPagesAndRestoresAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-clear-scan", "--ui-test-slow-scan"]
        launchReady(app)
        XCTAssertTrue(app.buttons["homeSmartCleanup"].waitForExistence(timeout: 20))
        app.buttons["homeSmartCleanup"].tap()
        let scan = app.buttons["scanButton"]
        waitEnabled(scan, true); scan.tap()
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["mediaAlbums"].tap()
        XCTAssertTrue(app.navigationBars["Albums"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Pearl"].exists)
        app.buttons["homeSmartCleanup"].tap()
        let progress = app.staticTexts["scanProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        let advanced = NSPredicate(format: "label BEGINSWITH '5 of' OR label BEGINSWITH '10 of' OR label CONTAINS 'items checked'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: progress)], timeout: 30), .completed)
        if scan.label == "Pause scan" { scan.tap() }
        let paused = app.staticTexts["Scan paused. Your place is saved."]
        XCTAssertTrue(paused.waitForExistence(timeout: 15))
        waitEnabled(scan, true)
        let saved = progress.label
        app.terminate(); app.launchArguments = []; launchReady(app)
        XCTAssertTrue(app.buttons["homeSmartCleanup"].waitForExistence(timeout: 20)); app.buttons["homeSmartCleanup"].tap()
        XCTAssertTrue(app.staticTexts["Your place is saved. Ready to resume."].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["scanProgress"].label, saved)
        app.buttons["scanButton"].tap()
        XCTAssertTrue(app.staticTexts["Scan complete. You choose what stays."].waitForExistence(timeout: 120))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Reused '")).firstMatch.exists)
        capture(app, "Pearl-Resumed-Scan")
    }

    @MainActor func testLeavingAppUsesBackgroundGrantOrSavedFallback() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-clear-scan", "--ui-test-slow-scan"]
        launchReady(app)
        XCTAssertTrue(app.buttons["homeSmartCleanup"].waitForExistence(timeout: 20))
        app.buttons["homeSmartCleanup"].tap(); waitEnabled(app.buttons["scanButton"], true)
        app.buttons["scanButton"].tap()
        let granted = app.staticTexts["You can leave Pearl. Track progress in the Live Activity."].exists
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10) || app.state == .runningBackgroundSuspended)
        let home = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        home.name = "Pearl-System-Background"; home.lifetime = .keepAlways; add(home)
        app.activate()
        XCTAssertTrue(app.buttons["scanButton"].waitForExistence(timeout: 10))
        if granted {
            XCTAssertTrue(app.buttons["scanButton"].label == "Pause scan" || app.staticTexts["Scan complete. You choose what stays."].exists)
            if app.buttons["scanButton"].label == "Pause scan" { app.buttons["scanButton"].tap() }
        } else {
            XCTAssertTrue(app.staticTexts["Your place is saved. Resume when you return to Pearl."].waitForExistence(timeout: 10))
        }
        print("Pearl background simulator path: \(granted ? "continued processing granted" : "saved fallback")")
    }

    @MainActor private func launchReady(_ app: XCUIApplication) {
        if !app.launchArguments.contains("--ui-test-preserve-appearance") && !app.launchArguments.contains("--ui-test-reset-appearance") {
            app.launchArguments.append("--ui-test-reset-appearance")
        }
        let permissionMonitor = addUIInterruptionMonitor(withDescription: "Synthetic Photos access") { alert in
            let allow = alert.buttons["Allow Full Access"]
            guard allow.exists else { return false }
            allow.tap()
            return true
        }
        defer { removeUIInterruptionMonitor(permissionMonitor) }
        app.launch()
        let access = app.buttons["chooseAccess"]
        let started = NSPredicate { _, _ in access.exists || app.navigationBars["Pearl"].exists }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: started, object: app)], timeout: 20)
        if result != .completed { capture(app, "Pearl-Launch-Failure") }
        XCTAssertEqual(result, .completed)
        if access.exists {
            // A fresh runner may reinstall the app after simctl grants access.
            // Exercise actual onboarding against synthetic simulator media.
            for _ in 0..<6 where access.exists && !access.isHittable { app.swipeUp() }
            if access.exists {
                XCTAssertTrue(access.isHittable)
                access.tap()
            }
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons["Allow Full Access"]
            let appAllow = app.buttons["Allow Full Access"]
            let prompt = NSPredicate { _, _ in allow.exists || appAllow.exists || app.navigationBars["Pearl"].exists }
            let promptResult = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: prompt, object: app)], timeout: 15)
            if promptResult != .completed {
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Pearl-Photo-Permission-Failure"; screenshot.lifetime = .keepAlways; add(screenshot)
                print(springboard.debugDescription)
            }
            XCTAssertEqual(promptResult, .completed)
            if allow.exists { allow.tap() }
            else if appAllow.exists { appAllow.tap() }
        }
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
    }

    @MainActor private func waitEnabled(_ element: XCUIElement, _ enabled: Bool) {
        let predicate = NSPredicate(format: "enabled == %@", NSNumber(value: enabled))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 15), .completed)
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication, towardEarlierRows: Bool = false) {
        if element.isHittable { return }
        // Scroll the actual List in the known direction. Swiping the whole app
        // downward at the top can dismiss its sheet on a compact phone.
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.exists)
        for _ in 0..<8 where !element.isHittable {
            if towardEarlierRows { list.swipeDown() } else { list.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor func testAppearancePersistsAndKeepsNativeNavigation() {
        let app = XCUIApplication(); launchReady(app)
        app.buttons["Settings"].tap(); app.buttons["settingsAppearance"].tap()
        XCTAssertTrue(app.navigationBars["Appearance"].waitForExistence(timeout: 5))
        let bloom = app.buttons["theme-bloom"], solid = app.buttons["surface-solid"]
        reveal(bloom, in: app); bloom.tap()
        XCTAssertTrue(app.navigationBars["Appearance"].exists, "Changing theme must not reset navigation")
        reveal(solid, in: app); solid.tap()
        XCTAssertEqual(solid.value as? String, "Selected")
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        capture(app, "Pearl-Settings-Bloom-Solid")
        app.terminate(); app.launchArguments = ["--ui-test-preserve-appearance"]; launchReady(app)
        app.buttons["Settings"].tap(); app.buttons["settingsAppearance"].tap()
        reveal(bloom, in: app)
        XCTAssertEqual(bloom.value as? String, "Selected")
        reveal(solid, in: app)
        XCTAssertEqual(solid.value as? String, "Selected")
        let ion = app.buttons["theme-ion"]
        reveal(ion, in: app, towardEarlierRows: true); ion.tap()
        reveal(solid, in: app)
        XCTAssertEqual(solid.value as? String, "Selected", "Theme and surface must stay independent")
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        capture(app, "Pearl-Settings-Ion-Solid")
        assertDarkSheet(app)
        app.buttons["settingsAppearance"].tap()
        let glass = app.buttons["surface-glass"]
        reveal(glass, in: app); glass.tap()
        capture(app, "Pearl-Appearance-Ion-Glass")
        assertDarkSheet(app)
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        // Native edge-pop on a real detail page, with no replacement gesture.
        app.buttons["settingsPhotoAccess"].tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5)).press(forDuration: 0.1,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    @MainActor private func assertDarkSheet(_ app: XCUIApplication) {
        // Sample the bare canvas beside rows, not imagery or system controls.
        guard let image = app.screenshot().image.cgImage,
              let crop = image.cropping(to: CGRect(x: 2, y: CGFloat(image.height) / 2, width: 4, height: 4)) else {
            return XCTFail("Missing screenshot canvas")
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        let rendered = pixel.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8,
                bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        XCTAssertTrue(rendered)
        XCTAssertLessThan(Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2]), 190,
            "Selecting Ion must update the open sheet to its dark palette")
    }

    @MainActor func testThemeChangeKeepsScanAndCloudRestrictions() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-clear-scan", "--ui-test-slow-scan"]; launchReady(app)
        app.buttons["homeSmartCleanup"].tap()
        XCTAssertTrue(app.buttons["scanButton"].waitForExistence(timeout: 10))
        app.buttons["scanButton"].tap()
        app.buttons["Settings"].tap(); app.buttons["settingsScanning"].tap()
        XCTAssertFalse(app.switches["scanCloudDownloads"].isEnabled)
        app.navigationBars.buttons["BackButton"].firstMatch.tap(); app.buttons["settingsAppearance"].tap()
        app.buttons["theme-glacier"].tap()
        XCTAssertTrue(app.navigationBars["Appearance"].exists)
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
        app.buttons["closeSettings"].tap()
        XCTAssertTrue(app.navigationBars["Smart Cleanup"].waitForExistence(timeout: 5))
        let scan = app.buttons["scanButton"]
        XCTAssertTrue(scan.label == "Pause scan" || app.staticTexts["Scan complete. You choose what stays."].exists)
        if scan.label == "Pause scan" { scan.tap(); XCTAssertTrue(app.staticTexts["Scan paused. Your place is saved."].waitForExistence(timeout: 15)) }
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
