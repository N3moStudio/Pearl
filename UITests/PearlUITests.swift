import XCTest

final class PearlUITests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    @MainActor func testLargeTextAndDarkAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "--ui-test-dark"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.tabBars.buttons["Clean Up"].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Pearl-Large-Text-Dark"; screenshot.lifetime = .keepAlways; add(screenshot)
    }
    @MainActor func testLibraryReviewQueue() throws {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-review"]; app.launch()
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        let library = XCTAttachment(screenshot: app.screenshot()); library.name = "Pearl-Library"; library.lifetime = .keepAlways; add(library)
        app.buttons["mediaPhotos"].tap()
        let item = app.buttons.matching(identifier: "mediaItem").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10)); item.tap()
        let remove = app.buttons["stageRemoval"]
        XCTAssertTrue(remove.waitForExistence(timeout: 10)); remove.tap()
        XCTAssertTrue(app.buttons["undoReview"].isEnabled)
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
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-clear-scan", "--ui-test-reset-review"]; app.launch()
        XCTAssertTrue(app.navigationBars["Pearl"].waitForExistence(timeout: 20))
        app.tabBars.buttons["Clean Up"].tap()
        app.buttons["scanButton"].tap()
        let complete = app.staticTexts["Scan complete. You choose what stays."]
        XCTAssertTrue(complete.waitForExistence(timeout: 120))
        let cleanup = XCTAttachment(screenshot: app.screenshot()); cleanup.name = "Pearl-Clean-Up"; cleanup.lifetime = .keepAlways; add(cleanup)
        app.buttons["matchesphoto"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["matchGroup"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Review selection"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Review selection"].isEnabled)
        let comparison = XCTAttachment(screenshot: app.screenshot()); comparison.name = "Pearl-Compare"; comparison.lifetime = .keepAlways; add(comparison)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["matchesvideo"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10), "Synthetic re-encoded videos should match locally")
    }

    @MainActor func testMonthReviewFavoriteFilmstripAndContinuousSwipe() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-test-reset-review"]; app.launch()
        XCTAssertTrue(app.buttons["openSwipe"].waitForExistence(timeout: 20)); app.buttons["openSwipe"].tap()
        XCTAssertTrue(app.buttons["swipeMonth"].firstMatch.waitForExistence(timeout: 10))
        capture(app, "Pearl-Months")
        app.buttons["swipeMonth"].firstMatch.tap()
        let favorite = app.buttons["favoriteItem"], remove = app.buttons["stageRemoval"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 10))
        if favorite.label == "Remove from favorites" { favorite.tap(); waitEnabled(remove, true) }
        favorite.tap(); waitEnabled(remove, false)
        XCTAssertEqual(favorite.label, "Remove from favorites")
        favorite.tap(); waitEnabled(remove, true)
        let progress = app.staticTexts["reviewProgress"], before = progress.label
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 18, dy: 0)))
        XCTAssertEqual(progress.label, before, "A partial drag must not decide")
        capture(app, "Pearl-Fullscreen-Review")
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.45)))
        XCTAssertTrue(app.buttons["undoReview"].isEnabled)
        app.buttons["undoReview"].tap()
        XCTAssertEqual(progress.label, before)
        let second = app.buttons["reviewThumbnail1"]
        XCTAssertTrue(second.exists); second.tap()
        XCTAssertTrue(progress.label.hasPrefix("2 of"))
        app.buttons["closeReview"].tap()
        XCTAssertTrue(app.navigationBars["Swipe"].exists)
    }

    @MainActor func testScanContinuesAcrossTabsAndRestoresAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-clear-scan", "--ui-test-slow-scan"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Clean Up"].waitForExistence(timeout: 20))
        app.tabBars.buttons["Clean Up"].tap()
        let scan = app.buttons["scanButton"]
        waitEnabled(scan, true); scan.tap()
        app.tabBars.buttons["Albums"].tap()
        XCTAssertTrue(app.navigationBars["Albums"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars["Pearl"].exists)
        app.tabBars.buttons["Clean Up"].tap()
        let progress = app.staticTexts["scanProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        let advanced = NSPredicate(format: "label BEGINSWITH '5 of' OR label BEGINSWITH '10 of' OR label CONTAINS 'items checked'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: progress)], timeout: 30), .completed)
        if scan.label == "Pause scan" { scan.tap() }
        let paused = app.staticTexts["Scan paused. Your place is saved."]
        XCTAssertTrue(paused.waitForExistence(timeout: 15))
        waitEnabled(scan, true)
        let saved = progress.label
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.tabBars.buttons["Clean Up"].waitForExistence(timeout: 20)); app.tabBars.buttons["Clean Up"].tap()
        XCTAssertTrue(app.staticTexts["Your place is saved. Ready to resume."].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["scanProgress"].label, saved)
        app.buttons["scanButton"].tap()
        XCTAssertTrue(app.staticTexts["Scan complete. You choose what stays."].waitForExistence(timeout: 120))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Reused '")).firstMatch.exists)
        capture(app, "Pearl-Resumed-Scan")
    }

    @MainActor private func waitEnabled(_ element: XCUIElement, _ enabled: Bool) {
        let predicate = NSPredicate(format: "enabled == %@", NSNumber(value: enabled))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 15), .completed)
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
