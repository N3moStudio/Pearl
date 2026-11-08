import XCTest
import UIKit
import Vision
import CryptoKit
import PearlCore
@testable import Pearl

final class VisionMatchingTests: XCTestCase {
    @MainActor func testIdenticalAndReencodedImagesMatchButUnrelatedImageDoesNot() throws {
        let image = scene()
        let original = try XCTUnwrap(image.cgImage)
        let jpeg = try XCTUnwrap(image.jpegData(compressionQuality: 0.55))
        let reencoded = try XCTUnwrap(UIImage(data: jpeg)?.cgImage)
        let unrelated = try XCTUnwrap(diagram().cgImage)
        // Match production's immediate secure archive, then compare decoded prints.
        let a = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(original)))
        let same = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(original)))
        let b = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(reencoded)))
        let c = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(unrelated)))
        let identical = try Fingerprints.distance(a, same)
        let compressed = try Fingerprints.distance(a, b)
        let different = try Fingerprints.distance(a, c)
        XCTAssertEqual(a.data, same.data)
        XCTAssertTrue(MatchRules.similarPhoto([identical]))
        XCTAssertTrue(MatchRules.similarPhoto([compressed]))
        XCTAssertFalse(MatchRules.similarPhoto([different]))
        // Measure the real Vision implementation; these aren't mocked distances.
        print("Vision fixture distances: identical=\(identical), reencoded=\(compressed), unrelated=\(different)")
        print("Vision feature data identical to unrelated: \(a.data == c.data); elements: \(a.elementCount)")
        if MatchRules.similarPhoto([different]) {
            for (name, left, right) in [("raw", original, unrelated), ("software360", try normalized(original), try normalized(unrelated))] {
                for cpu in [true, false] {
                    let x = try diagnosticObservation(left, cpu: cpu), y = try diagnosticObservation(right, cpu: cpu)
                    print("Vision diagnostic \(name) cpu=\(cpu) sameData=\(x.data == y.data) distance=\(try Fingerprints.distance(x,y))")
                }
            }
        }
    }

    private func diagnosticObservation(_ image: CGImage, cpu: Bool) throws -> VNFeaturePrintObservation {
        if cpu { return try Fingerprints.observation(image) }
        let request = VNGenerateImageFeaturePrintRequest(); request.revision = VNGenerateImageFeaturePrintRequestRevision2
        request.imageCropAndScaleOption = .scaleFit
        try VNImageRequestHandler(cgImage: image).perform([request])
        return try XCTUnwrap(request.results?.first)
    }
    private func normalized(_ image: CGImage) throws -> CGImage {
        let c = try XCTUnwrap(CGContext(data: nil, width: 360, height: 360, bitsPerComponent: 8, bytesPerRow: 1440,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        c.draw(image, in: CGRect(x: 0, y: 0, width: 360, height: 360))
        let result = try XCTUnwrap(c.makeImage())
        let bytes = try XCTUnwrap(result.dataProvider?.data) as Data
        print("Vision diagnostic input: \(SHA256.hash(data: bytes).description)")
        return result
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
