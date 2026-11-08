import Foundation

/// A bounded shortlist. Date buckets survive cache rebuilds and insertion order;
/// eight hash bands retrieve cross-date candidates before Vision verifies them.
public struct CandidateIndex: Sendable {
    public static let maxCandidates = 160
    private struct TimeKey: Hashable, Sendable { let slot: Int; let video: Bool }
    private struct Entry: Sendable { let item: MediaItem; let hash: UInt64 }
    private var buckets: [UInt32: [String]] = [:]
    private var timeline: [TimeKey: [String]] = [:]
    private var entries: [String: Entry] = [:]
    public init() {}
    private func keys(_ hash: UInt64, video: Bool) -> [UInt32] {
        (0..<8).map { UInt32(video ? 1 << 16 : 0) | UInt32($0 << 8) | UInt32((hash >> ($0 * 8)) & 0xff) }
    }
    private func slot(_ item: MediaItem) -> Int {
        Int(floor(item.date.timeIntervalSinceReferenceDate / 600))
    }
    public func candidates(for item: MediaItem, hash: UInt64) -> [String] {
        let time = slot(item)
        let nearby = ((time - 1)...(time + 1)).flatMap { timeline[TimeKey(slot: $0, video: item.isVideo)] ?? [] }
            .compactMap { entries[$0] }
            .filter { $0.item.id != item.id && abs($0.item.date.timeIntervalSince(item.date)) < 600 }
            .sorted {
                let lhs = abs($0.item.date.timeIntervalSince(item.date)), rhs = abs($1.item.date.timeIntervalSince(item.date))
                if lhs != rhs { return lhs < rhs }
                let a = MatchRules.hamming($0.hash, hash), b = MatchRules.hamming($1.hash, hash)
                return a != b ? a < b : $0.item.id > $1.item.id
            }
        var ids: [String] = []
        var seen: Set<String> = []
        for prior in nearby.prefix(64) {
            if seen.insert(prior.item.id).inserted { ids.append(prior.item.id) }
        }
        var visual: [(id: String, distance: Int)] = []
        for key in keys(hash, video: item.isVideo) {
            for id in buckets[key] ?? [] where id != item.id && seen.insert(id).inserted {
                if let entry = entries[id] {
                    let distance = MatchRules.hamming(entry.hash, hash)
                    if distance <= 12 { visual.append((id, distance)) }
                }
            }
        }
        visual.sort { $0.distance != $1.distance ? $0.distance < $1.distance : $0.id > $1.id }
        ids.append(contentsOf: visual.prefix(Self.maxCandidates - ids.count).map(\.id))
        return ids
    }
    public mutating func insert(_ item: MediaItem, hash: UInt64) {
        guard entries[item.id] == nil else { return }
        entries[item.id] = Entry(item: item, hash: hash)
        let time = TimeKey(slot: slot(item), video: item.isVideo)
        timeline[time, default: []].append(item.id)
        if timeline[time, default: []].count > 128 { timeline[time]?.removeFirst() }
        for key in keys(hash, video: item.isVideo) {
            buckets[key, default: []].append(item.id)
            if buckets[key, default: []].count > 80 { buckets[key]?.removeFirst() }
        }
    }
}
