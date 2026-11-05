import XCTest

final class PearlUITests: XCTestCase {
    @MainActor func testLibraryReviewAndLocalScan() throws {
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.navigationBars["Your library"].waitForExistence(timeout: 20))
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
        app.buttons["reviewQueue"].tap()
        XCTAssertTrue(app.navigationBars["Review removal"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["confirmRemoval"].isEnabled)
        app.buttons["Keep"].firstMatch.tap()
        XCTAssertFalse(app.buttons["confirmRemoval"].isEnabled)
        app.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Clean Up"].tap()
        app.buttons["scanButton"].tap()
        let complete = app.staticTexts["Scan complete. You choose what stays."]
        XCTAssertTrue(complete.waitForExistence(timeout: 120))
        let cleanup = XCTAttachment(screenshot: app.screenshot()); cleanup.name = "Pearl-Clean-Up"; cleanup.lifetime = .keepAlways; add(cleanup)
        app.buttons["matchesphoto"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["matchGroup"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Nothing is selected for removal."].waitForExistence(timeout: 5))
        let comparison = XCTAttachment(screenshot: app.screenshot()); comparison.name = "Pearl-Compare"; comparison.lifetime = .keepAlways; add(comparison)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["matchesvideo"].tap()
        XCTAssertTrue(app.buttons["matchGroup"].firstMatch.waitForExistence(timeout: 10), "Synthetic re-encoded videos should match locally")
    }
}
