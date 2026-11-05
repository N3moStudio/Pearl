import Foundation

/// Durable, small scan metadata. Image data and Vision observations stay in the cache.
public struct ScanRecord: Codable, Sendable {
    public var item: MediaItem
    public var hash: UInt64?
    public var digest: String?
    public var exactAttempted: Bool
    public init(item: MediaItem, hash: UInt64?, digest: String? = nil, exactAttempted: Bool = false) {
        self.item = item; self.hash = hash; self.digest = digest; self.exactAttempted = exactAttempted
    }
    public func matches(_ current: MediaItem) -> Bool {
        item.id == current.id && item.modified == current.modified && item.isVideo == current.isVideo &&
        item.isLive == current.isLive && item.width == current.width && item.height == current.height && item.duration == current.duration
    }
    /// A shortlist for expensive original-byte verification, never proof of equality.
    public var exactKey: String? {
        guard let hash, !item.isLive else { return nil }
        return "\(item.isVideo):\(item.width)x\(item.height):\(item.duration.bitPattern):\(hash)"
    }
}

public struct ScanCheckpoint: Codable, Sendable {
    public var schema = 1
    public var runtime: String
    public var records: [String: ScanRecord] = [:]
    public var groups: [MatchGroup] = []
    public var complete = false
    public init(runtime: String) { self.runtime = runtime }

    public mutating func reconcile(_ items: [MediaItem], runtime: String, retryUnavailable: Bool) {
        guard self.runtime == runtime, schema == 1 else { self = ScanCheckpoint(runtime: runtime); return }
        let current = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        records = records.filter { id, record in
            guard let item = current[id], record.matches(item) else { return false }
            return !retryUnavailable || record.hash != nil
        }
        groups = groups.compactMap { group in
            let members = group.members.filter { records[$0]?.hash != nil }
            return members.count > 1 ? MatchGroup(kind: group.kind, members: members) : nil
        }
        if records.count != items.count { complete = false }
    }

    public var exactCandidates: Set<String> {
        var buckets: [String: [String]] = [:]
        for (id, record) in records { if let key = record.exactKey { buckets[key, default: []].append(id) } }
        return Set(buckets.values.filter { $0.count > 1 }.flatMap { $0 })
    }
}

public struct ScanProgress: Sendable {
    public enum Phase: String, Sendable { case comparing, verifying, complete }
    public var checked = 0
    public var total = 0
    public var unavailable = 0
    public var exactChecked = 0
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
