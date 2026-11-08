import XCTest
import NativeSettingsKit
@testable import Pearl

final class PearlAppearanceTests: XCTestCase {
    @MainActor func testExistingDefaultAndUnknownValuesAreNotRewritten() throws {
        let suite = "PearlAppearanceTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let empty = PearlAppearance(defaults: defaults)
        XCTAssertEqual(empty.theme, .pearl); XCTAssertEqual(empty.surface, .glass)
        XCTAssertNil(defaults.object(forKey: PearlAppearance.themeKey))
        defaults.set("future-theme", forKey: PearlAppearance.themeKey)
        defaults.set("future-surface", forKey: PearlAppearance.surfaceKey)
        let future = PearlAppearance(defaults: defaults)
        XCTAssertEqual(future.theme, .pearl); XCTAssertEqual(future.surface, .glass)
        XCTAssertEqual(defaults.string(forKey: PearlAppearance.themeKey), "future-theme")
        XCTAssertEqual(defaults.string(forKey: PearlAppearance.surfaceKey), "future-surface")
    }
    @MainActor func testAppearanceChoicesPersistIndependently() throws {
        let suite = "PearlAppearanceTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let appearance = PearlAppearance(defaults: defaults)
        appearance.surface = .solid; appearance.theme = .ion
        let restored = PearlAppearance(defaults: defaults)
        XCTAssertEqual(restored.theme, .ion); XCTAssertEqual(restored.surface, .solid)
        restored.theme = .bloom
        XCTAssertEqual(restored.surface, .solid)
        restored.surface = .glass
        XCTAssertEqual(restored.theme, .bloom)
    }
}
