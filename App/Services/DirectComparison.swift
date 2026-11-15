import Foundation
import PearlCore

struct PhotoComparisonResult: Sendable {
    let verdict: PhotoComparisonVerdict
    let originalStatus: String
    let needsDownload: Bool
}

enum DirectComparison {
    /// Deliberately separate from the scanner's mutable cache/checkpoint. Two
    /// explicitly chosen assets bypass the automatic shortlist, not its rules.
    @concurrent static func compare(_ items: [MediaItem], network: Bool) async throws -> PhotoComparisonResult {
        guard items.count == 2, items[0].id != items[1].id, items.allSatisfy({ !$0.isVideo }) else {
            return PhotoComparisonResult(verdict: .unavailable, originalStatus: "Choose two different photos.", needsDownload: false)
        }
        try Task.checkCancellation()
        var prints: [Fingerprint] = []
        var needsDownload = false
        for item in items {
            do { prints.append(try await Fingerprints.make(item, network: network)) }
            catch is CancellationError { throw CancellationError() }
            catch { needsDownload = needsDownload || (error as? PhotoAccess.ReadError) == .downloadRequired }
        }
        var digests: [String] = []
        var originalUnavailable = false
        var unsupported = false
        for item in items {
            try Task.checkCancellation()
            do {
                if let digest = try await Fingerprints.exactDigest(item.id, network: network) { digests.append(digest) }
                else { unsupported = true }
            } catch is CancellationError { throw CancellationError() }
            catch { originalUnavailable = true }
        }
        try Task.checkCancellation()
        let exact = digests.count == 2 && digests[0] == digests[1]
        let distance: Float?
        if !exact, prints.count == 2, let a = prints[0].prints.first, let b = prints[1].prints.first {
            distance = try? Fingerprints.distance(a, b)
        } else { distance = nil }
        let status: String
        if exact { status = "Both original files have the same verified contents." }
        else if originalUnavailable { status = "Original files couldn't both be read. Exact-copy verification is incomplete." }
        else if unsupported { status = "Live Photos, edited sets and paired resources aren't verified as exact copies. Visual comparison uses their still images." }
        else { status = "The original files are different. Similar appearance does not make them identical copies." }
        return PhotoComparisonResult(verdict: .classify(exactConfirmed: exact, distance: distance),
                                     originalStatus: status, needsDownload: needsDownload || originalUnavailable)
    }
}
