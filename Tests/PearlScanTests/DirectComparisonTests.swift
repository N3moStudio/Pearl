import XCTest
import Photos
import PearlCore
@testable import Pearl

final class DirectComparisonTests: XCTestCase {
    @MainActor func testDirectComparisonVerifiesOriginalFixtureCopies() async throws {
        let library = await PhotoAccess.library()
        let pair = library.filter { item in
            guard let asset = PhotoAccess.asset(item.id) else { return false }
            let name = PHAssetResource.assetResources(for: asset).first?.originalFilename
            return name == "scene-0-a.jpg" || name == "exact-copy.jpg"
        }
        XCTAssertEqual(pair.count, 2, "CI must install both exact-copy fixtures")
        let result = try await DirectComparison.compare(pair, network: false)
        XCTAssertEqual(result.verdict, .exact)
        XCTAssertFalse(result.needsDownload)
    }
    @MainActor func testMissingPhotosAreIncompleteRatherThanDifferent() async throws {
        let result = try await DirectComparison.compare([MediaItem(id: "missing-a"), MediaItem(id: "missing-b")], network: false)
        XCTAssertEqual(result.verdict, .unavailable)
    }
}
