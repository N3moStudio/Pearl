import Foundation

/// Durable, small scan metadata. Image data and Vision observations stay in the cache.
public struct ScanRecord: Codable, Sendable {
    public var item: MediaItem
    public var hash: UInt64?
    public var digest: String?
    public var exactAttempted: Bool
    public var verificationFailed: Bool?
    // Missing in older checkpoints: keep reusable fingerprints/digests but redo matching.
    public var comparisonRevision: Int?
    public var isCompared: Bool { comparisonRevision == ScanCheckpoint.matchingRevision }
    public init(item: MediaItem, hash: UInt64?, digest: String? = nil, exactAttempted: Bool = false, verificationFailed: Bool? = nil) {
        self.item = item; self.hash = hash; self.digest = digest; self.exactAttempted = exactAttempted
        self.verificationFailed = verificationFailed
        comparisonRevision = ScanCheckpoint.matchingRevision
    }
    public func matches(_ current: MediaItem) -> Bool {
        item.id == current.id && item.modified == current.modified && item.isVideo == current.isVideo &&
        item.isLive == current.isLive && item.width == current.width && item.height == current.height && item.duration == current.duration
    }
    /// A shortlist for expensive original-byte verification, never proof of equality.
    public var exactKey: String? {
        guard let hash, let resourceKey else { return nil }
        return "\(resourceKey):\(hash)"
    }
    public var resourceKey: String? {
        guard hash != nil, !item.isLive else { return nil }
        return "\(item.isVideo):\(item.width)x\(item.height):\(item.duration.bitPattern)"
    }
}

public struct ScanCheckpoint: Codable, Sendable {
    public static let matchingRevision = 2
    public var schema = 1
    public var runtime: String
    public var records: [String: ScanRecord] = [:]
    public var groups: [MatchGroup] = []
    public var complete = false
    public init(runtime: String) { self.runtime = runtime }
    public var checkedCount: Int { records.values.lazy.filter(\.isCompared).count }

    public mutating func resetComparisons() {
        records = records.mapValues { record in
            var value = record; value.comparisonRevision = nil; return value
        }
        groups.removeAll { $0.kind != .exact }
        complete = false
    }

    public mutating func reconcile(_ items: [MediaItem], runtime: String, retryUnavailable: Bool) {
        guard self.runtime == runtime, schema == 1 else { self = ScanCheckpoint(runtime: runtime); return }
        let current = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        records = records.filter { id, record in
            guard let item = current[id], record.matches(item) else { return false }
            return !retryUnavailable || record.hash != nil
        }
        groups = groups.compactMap { group in
            let members = group.members.filter {
                guard let record = records[$0], record.hash != nil else { return false }
                return group.kind == .exact || record.isCompared
            }
            return members.count > 1 ? MatchGroup(kind: group.kind, members: members) : nil
        }
        if checkedCount != items.count { complete = false }
    }

    public var exactCandidates: Set<String> {
        var buckets: [String: [String]] = [:]
        for (id, record) in records { if let key = record.exactKey { buckets[key, default: []].append(id) } }
        var candidates = Set(buckets.values.filter { $0.count > 1 }.flatMap { $0 })
        // Similar previews can have different tiny hashes. Verify their actual bytes
        // when the original media metadata is compatible, never infer equality here.
        for group in groups where group.kind != .exact {
            var compatible: [String: [String]] = [:]
            for id in group.members {
                if let key = records[id]?.resourceKey { compatible[key, default: []].append(id) }
            }
            for ids in compatible.values where ids.count > 1 { candidates.formUnion(ids) }
        }
        return candidates
    }
}

public struct ScanProgress: Sendable {
    public enum Phase: String, Sendable { case comparing, verifying, complete }
    public var checked = 0
    public var total = 0
    public var unavailable = 0
    public var exactChecked = 0
    public var verificationUnavailable = 0
    public var verified = 0
    public var verificationTotal = 0
    public var reused = 0
    public var phase = Phase.comparing
    public var groups: [MatchGroup] = []
    public init(total: Int = 0) { self.total = total }
    public var fraction: Double {
        guard total > 0 else { return 0 }
        if phase == .complete { return 1 }
        if phase == .comparing { return min(0.85, Double(checked) / Double(total) * 0.85) }
        return 0.85 + 0.15 * Double(verified) / Double(max(1, verificationTotal))
    }
    public var detail: String {
        switch phase {
        case .comparing: "\(checked.formatted()) of \(total.formatted()) checked"
        case .verifying: "Verifying \(verified.formatted()) of \(verificationTotal.formatted()) possible copies"
        case .complete: "\(checked.formatted()) items checked"
        }
    }
}
