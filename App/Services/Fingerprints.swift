import Vision
import UIKit
import CryptoKit
import Photos
import AVFoundation
import Synchronization
import CoreImage
import CoreML
import PearlCore

struct Fingerprint: Codable, Sendable {
    static let version = 1
    static var runtimeKey: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "vision-r2-\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    let version: Int
    let runtime: String
    let modified: Date
    let prints: [Data]
    let hash: UInt64
    let exact: String?
}

enum Fingerprints {
    static func observation(_ image: CGImage) throws -> VNFeaturePrintObservation {
        let request = VNGenerateImageFeaturePrintRequest()
        request.revision = VNGenerateImageFeaturePrintRequestRevision2
        request.imageCropAndScaleOption = .scaleFit
        // CPU-only work remains eligible for background processing with personal sideload signing.
        // Do not silently use a GPU/Neural Engine without their background entitlements.
        for (stage, devices) in try request.supportedComputeStageDevices {
            guard let cpu = devices.first(where: { if case .cpu = $0 { return true }; return false }) else {
                throw ScanError.unavailable
            }
            request.setComputeDevice(cpu, for: stage)
        }
        try VNImageRequestHandler(cgImage: image).perform([request])
        guard let result = request.results?.first else { throw ScanError.unavailable }
        return result
    }
    static func archive(_ observation: VNFeaturePrintObservation) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }
    static func distance(_ a: Data, _ b: Data) throws -> Float {
        try distance(decode(a), decode(b))
    }
    static func decode(_ data: Data) throws -> VNFeaturePrintObservation {
        guard let result = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data) else { throw ScanError.unavailable }
        return result
    }
    static func distance(_ lhs: VNFeaturePrintObservation, _ rhs: VNFeaturePrintObservation) throws -> Float {
        var distance: Float = 0
        try lhs.computeDistance(&distance, to: rhs)
        return distance
    }
    static func perceptualHash(_ image: CGImage) -> UInt64 {
        var pixels = [UInt8](repeating: 0, count: 72)
        guard let context = CGContext(data: &pixels, width: 9, height: 8, bitsPerComponent: 8,
                                      bytesPerRow: 9, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else { return 0 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: 9, height: 8))
        var hash: UInt64 = 0
        for y in 0..<8 { for x in 0..<8 where pixels[y * 9 + x] > pixels[y * 9 + x + 1] {
            hash |= 1 << (y * 8 + x)
        }}
        return hash
    }
    // Only single, unedited resource assets qualify. Live Photos, RAW pairs and edits are excluded.
    static func exactDigest(_ id: String, network: Bool) async throws -> String? {
        guard let asset = PhotoAccess.asset(id) else { return nil }
        let resources = PHAssetResource.assetResources(for: asset)
        guard resources.count == 1, let resource = resources.first,
              resource.type == .photo || resource.type == .video else { return nil }
        let digest = Mutex(SHA256())
        let manager = PHAssetResourceManager.default()
        let stream = AsyncThrowingStream<String, Error> { continuation in
            let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = network
            let request = manager.requestData(for: resource, options: options, dataReceivedHandler: { data in
                digest.withLock { $0.update(data: data) }
            }, completionHandler: { error in
                if let error { continuation.finish(throwing: error); return }
                let hash = digest.withLock { $0.finalize().map { String(format: "%02x", $0) }.joined() }
                continuation.yield("\(resource.type.rawValue):\(hash)"); continuation.finish()
            })
            continuation.onTermination = { @Sendable _ in manager.cancelDataRequest(request) }
        }
        for try await hash in stream { try Task.checkCancellation(); return hash }
        throw CancellationError()
    }
    @concurrent static func make(_ item: MediaItem, network: Bool) async throws -> Fingerprint {
        try Task.checkCancellation()
        var prints: [Data] = []
        var hash: UInt64 = 0
        if item.isVideo {
            guard let asset = await PhotoAccess.video(item.id, network: network) else { throw ScanError.unavailable }
            for frame in try await asset.frames(duration: item.duration) {
                try Task.checkCancellation()
                if prints.isEmpty { hash = perceptualHash(frame) }
                prints.append(try archive(observation(frame)))
            }
        } else {
            guard let preview = await PhotoAccess.image(item.id, network: network),
                  let image = uprightImage(preview) else { throw ScanError.unavailable }
            hash = perceptualHash(image)
            prints = [try archive(observation(image))]
        }
        try Task.checkCancellation()
        return Fingerprint(version: Fingerprint.version, runtime: Fingerprint.runtimeKey,
                           modified: item.modified, prints: prints, hash: hash, exact: nil)
    }
    enum ScanError: Error { case unavailable }
    private static func uprightImage(_ image: UIImage) -> CGImage? {
        guard let raw = image.cgImage else { return nil }
        let orientation: CGImagePropertyOrientation = switch image.imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
        if orientation == .up { return raw }
        let oriented = CIImage(cgImage: raw).oriented(orientation)
        return CIContext(options: [.useSoftwareRenderer: true]).createCGImage(oriented, from: oriented.extent)
    }
}
