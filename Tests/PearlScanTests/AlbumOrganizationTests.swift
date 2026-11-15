import XCTest
import Photos
@testable import Pearl

final class AlbumOrganizationTests: XCTestCase {
    @MainActor func testFavoriteOrderPersistsWithoutDiscardingUnavailableAlbums() throws {
        let suite = "AlbumOrderTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["missing", "b", "b", "a"], forKey: AlbumPreferences.orderKey)
        let a = Album(id: "a", title: "A", count: 0, cover: nil, canAdd: true)
        let b = Album(id: "b", title: "B", count: 0, cover: nil, canAdd: true)
        let c = Album(id: "c", title: "C", count: 0, cover: nil, canAdd: true)
        let all = [a, b, c], preferences = AlbumPreferences(defaults: defaults)
        XCTAssertEqual(preferences.sorted(all).map(\.id), ["b", "a", "c"])
        preferences.move(preferences.sorted(all), in: all, from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(preferences.sorted(all).map(\.id), ["c", "b", "a"])
        preferences.toggleFavorite("a")
        let restored = AlbumPreferences(defaults: defaults)
        XCTAssertEqual(restored.sorted(all).map(\.id), ["a", "c", "b"])
        XCTAssertTrue(restored.order.contains("missing"))
        restored.toggleFavorite("a")
        XCTAssertEqual(restored.sorted(all).map(\.id), ["c", "b", "a"])
    }

    @MainActor func testChangedAlbumSelectionFailsBeforeWriting() async throws {
        // Create/add/membership are checked after real authorization in the UI
        // suite. This guard must reject an absent selection before a transaction.
        do {
            try await AlbumAccess.create("Must not be created", adding: ["missing-asset"])
            XCTFail("Changed selections must fail without a partial add")
        } catch AlbumAccess.AlbumError.selectionChanged { }
    }
}
