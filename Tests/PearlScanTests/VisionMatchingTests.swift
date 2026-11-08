import XCTest
import UIKit
import PearlCore
@testable import Pearl

final class VisionMatchingTests: XCTestCase {
    @MainActor func testIdenticalAndReencodedImagesMatchButUnrelatedImageDoesNot() throws {
        let image = scene()
        let original = try XCTUnwrap(image.cgImage)
        let jpeg = try XCTUnwrap(image.jpegData(compressionQuality: 0.55))
        let reencoded = try XCTUnwrap(UIImage(data: jpeg)?.cgImage)
        let unrelated = try XCTUnwrap(diagram().cgImage)
        let a = try Fingerprints.observation(original)
        let same = try Fingerprints.observation(original)
        let b = try Fingerprints.observation(reencoded)
        let c = try Fingerprints.observation(unrelated)
        let identical = try Fingerprints.distance(a, same)
        let compressed = try Fingerprints.distance(a, b)
        let different = try Fingerprints.distance(a, c)
        XCTAssertEqual(identical, 0, accuracy: 0.00001)
        XCTAssertTrue(MatchRules.similarPhoto([compressed]))
        XCTAssertFalse(MatchRules.similarPhoto([different]))
        // Measure the real Vision implementation; these aren't mocked distances.
        print("Vision fixture distances: identical=\(identical), reencoded=\(compressed), unrelated=\(different)")
    }

    @MainActor private func scene() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512)).image { context in
            let c = context.cgContext
            UIColor.systemCyan.setFill(); c.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
            UIColor.systemYellow.setFill(); c.fillEllipse(in: CGRect(x: 350, y: 60, width: 80, height: 80))
            UIColor.systemBlue.setFill(); c.fill(CGRect(x: 0, y: 280, width: 512, height: 232))
            UIColor.systemGreen.setFill()
            c.move(to: CGPoint(x: 0, y: 240)); c.addLine(to: CGPoint(x: 170, y: 180))
            c.addLine(to: CGPoint(x: 360, y: 512)); c.addLine(to: CGPoint(x: 0, y: 512)); c.fillPath()
        }
    }
    @MainActor private func diagram() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512)).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
            for row in 0..<8 {
                for column in 0..<8 where (row + column).isMultiple(of: 2) {
                    UIColor.black.setFill(); context.fill(CGRect(x: column * 64, y: row * 64, width: 64, height: 64))
                }
            }
        }
    }
}
