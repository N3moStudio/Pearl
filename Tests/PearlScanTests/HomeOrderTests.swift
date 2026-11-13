import XCTest
@testable import Pearl

final class HomeOrderTests: XCTestCase {
    @MainActor func testOrderRepairPersistenceAndReset() throws {
        let suite = "HomeOrderTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let expected = ["albums", "photos", "videos", "selfies", "lives", "portraits", "panoramas", "slomo", "cinematic", "bursts", "screenshots", "recordings"]
        XCTAssertEqual(HomeOrder(defaults: defaults).categories.map(\.rawValue), expected)
        defaults.set(["videos", "future", "videos"], forKey: HomeOrder.key)
        let order = HomeOrder(defaults: defaults)
        XCTAssertEqual(order.categories.first, .videos)
        XCTAssertEqual(order.categories.count, 12)
        XCTAssertEqual(Set(order.categories).count, 12)
        order.move(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(HomeOrder(defaults: defaults).categories, order.categories)
        defaults.set("ion", forKey: PearlAppearance.themeKey)
        order.reset()
        XCTAssertEqual(order.categories.map(\.rawValue), expected)
        XCTAssertEqual(defaults.string(forKey: PearlAppearance.themeKey), "ion")
    }
}
