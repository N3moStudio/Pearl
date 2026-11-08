import XCTest
import UIKit
@testable import Pearl

final class VisionMatchingTests: XCTestCase {
    // Accuracy runs through scripts/vision_native_check.py on native macOS using
    // these exact production helpers. This cloud iOS simulator returns nearly
    // constant embeddings even for unrelated inputs; it cannot validate recall.
    @MainActor func testFeaturePrintArchiveRoundTripPreservesObservation() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { context in
            UIColor.systemGreen.setFill(); context.fill(CGRect(x: 0, y: 0, width: 128, height: 128))
            UIColor.systemYellow.setFill(); context.fill(CGRect(x: 20, y: 20, width: 50, height: 70))
        }
        let original = try Fingerprints.observation(XCTUnwrap(image.cgImage))
        let decoded = try Fingerprints.decode(Fingerprints.archive(original))
        XCTAssertEqual(original.data, decoded.data)
        XCTAssertEqual(original.elementCount, decoded.elementCount)
        XCTAssertGreaterThan(decoded.elementCount, 0)
        XCTAssertTrue(try Fingerprints.distance(original, decoded).isFinite)
    }
}
