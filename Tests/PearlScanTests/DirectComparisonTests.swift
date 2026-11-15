import XCTest
import Photos
import PearlCore
@testable import Pearl

final class DirectComparisonTests: XCTestCase {
    // Real PhotoKit originals are verified through the authorized UI integration
    // flow in testDirectComparisonAndCoverageRetry, not an unapproved unit host.
    @MainActor func testMissingPhotosAreIncompleteRatherThanDifferent() async throws {
        let result = try await DirectComparison.compare([MediaItem(id: "missing-a"), MediaItem(id: "missing-b")], network: false)
        XCTAssertEqual(result.verdict, .unavailable)
    }
}
