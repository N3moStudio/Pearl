import XCTest
import Photos
import PearlCore
@testable import Pearl

enum SyntheticPhotoLibrary {
    @MainActor static func ready() async throws -> [MediaItem] {
        // Xcode may reinstall the host after simctl's initial privacy grant.
        // CI reapplies that grant briefly; never skip integration checks when
        // the fixture/permission precondition isn't met.
        for _ in 0..<45 {
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
                let items = await PhotoAccess.library()
                if items.count >= 2 { return items }
            }
            try await Task.sleep(for: .seconds(1))
        }
        XCTFail("Synthetic Photos library was not accessible. Authorization: \(PHPhotoLibrary.authorizationStatus(for: .readWrite).rawValue)")
        throw SetupError.inaccessible
    }
    private enum SetupError: Error { case inaccessible }
}
