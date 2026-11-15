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

    @MainActor func testCreateAndAddUpdatesActualPhotoLibraryMembership() async throws {
        let items = await PhotoAccess.library()
        XCTAssertGreaterThanOrEqual(items.count, 2)
        let first = try XCTUnwrap(items.first?.id), second = try XCTUnwrap(items.dropFirst().first?.id)
        let title = "Pearl CI \(UUID().uuidString)"
        try await AlbumAccess.create(title, adding: [first])
        let created = await AlbumAccess.all()
        let album = try XCTUnwrap(created.first { $0.title == title })
        addTeardownBlock {
            let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.id], options: nil)
            try await PHPhotoLibrary.shared().performChanges { PHAssetCollectionChangeRequest.deleteAssetCollections(collections) }
        }
        let firstMembers = await AlbumAccess.members(album.id)
        XCTAssertEqual(firstMembers, [first])
        try await AlbumAccess.add([second], to: album.id)
        let members = await AlbumAccess.members(album.id)
        XCTAssertEqual(members, [first, second])
        let snapshot = await AlbumAccess.snapshot()
        XCTAssertTrue(snapshot.organizedIDs.isSuperset(of: [first, second]))
        do {
            try await AlbumAccess.add(["missing-asset"], to: album.id)
            XCTFail("Changed selections must fail without a partial add")
        } catch AlbumAccess.AlbumError.selectionChanged { }
        let unchanged = await AlbumAccess.members(album.id)
        XCTAssertEqual(unchanged, members)
    }
}
