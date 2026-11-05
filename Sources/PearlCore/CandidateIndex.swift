import Foundation

/// A bounded shortlist, not an exhaustive all-pairs search. Cross-date copies are
/// retrieved through hash bands; nearby shots are also considered despite edits.
public struct CandidateIndex: Sendable {
    private var buckets: [UInt32: [String]] = [:]
    private var recent: [MediaItem] = []
    private var hashes: [String: UInt64] = [:]
    public init() {}
    private func keys(_ hash: UInt64) -> [UInt32] {
        (0..<4).map { UInt32(($0 << 16)) | UInt32((hash >> ($0 * 16)) & 0xffff) }
    }
    public func candidates(for item: MediaItem, hash: UInt64) -> [String] {
        var ids: [String] = []
        var seen: Set<String> = []
        for prior in recent.reversed() where prior.isVideo == item.isVideo && abs(prior.date.timeIntervalSince(item.date)) < 120 {
            if seen.insert(prior.id).inserted { ids.append(prior.id) }
        }
        for key in keys(hash) {
            for id in (buckets[key] ?? []).reversed() where seen.insert(id).inserted {
                if let value = hashes[id], MatchRules.hamming(value, hash) <= 12 { ids.append(id) }
                if ids.count >= 160 { return ids }
            }
        }
        return ids
    }
    public mutating func insert(_ item: MediaItem, hash: UInt64) {
        hashes[item.id] = hash
        recent.append(item)
        if recent.count > 32 { recent.removeFirst() }
        for key in keys(hash) {
            buckets[key, default: []].append(item.id)
            if buckets[key, default: []].count > 80 { buckets[key]?.removeFirst() }
        }
    }
}
