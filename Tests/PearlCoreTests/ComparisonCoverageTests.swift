import Foundation
import Testing
@testable import PearlCore

@Test func directComparisonNeverCallsVisualSimilarityAnExactCopy() {
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: false, distance: 0) == .similar)
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: true, distance: nil) == .exact)
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: false, distance: 0.8) == .different)
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: false, distance: .nan) == .unavailable)
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: false, distance: -1) == .unavailable)
    #expect(PhotoComparisonVerdict.classify(exactConfirmed: false, distance: nil) == .unavailable)
}

@Test func coverageAndRetryPreserveSuccessfulWorkAndDistinctFailures() throws {
    let items = ["a", "b", "cloud", "failed", "verify", "new"].map { MediaItem(id: $0) }
    var saved = ScanCheckpoint(runtime: "r2")
    for item in items.prefix(2) {
        saved.records[item.id] = ScanRecord(item: item, hash: 7, digest: "verified", exactAttempted: true)
    }
    var cloud = ScanRecord(item: items[2], hash: nil); cloud.failure = .downloadRequired
    saved.records["cloud"] = cloud
    saved.records["failed"] = ScanRecord(item: items[3], hash: nil)
    saved.records["verify"] = ScanRecord(item: items[4], hash: 7, verificationFailed: true)
    saved.groups = [MatchGroup(kind: .photo, members: ["a", "b"])]
    saved = try JSONDecoder().decode(ScanCheckpoint.self, from: JSONEncoder().encode(saved))
    let state = saved.progress(for: items)
    #expect(state.analyzed == 3)
    #expect(state.unavailable == 2)
    #expect(state.downloadRequired == 1)
    #expect(state.pending == 1)
    #expect(state.verificationUnavailable == 1)
    #expect(state.uncheckedIDs == ["cloud", "failed", "verify", "new"])
    saved.reconcile(items, runtime: "r2", retryUnavailable: true)
    #expect(saved.checkedCount == 3)
    #expect(saved.records["a"]?.digest == "verified")
    #expect(saved.records["b"]?.isCompared == true)
    #expect(saved.records["verify"]?.verificationFailed == true)
    #expect(saved.records["cloud"] == nil && saved.records["failed"] == nil)
    #expect(saved.groups.first?.members == ["a", "b"])
}

@Test func oldFailureRecordsDecodeAndMatchingUpgradeKeepsFingerprints() throws {
    let item = MediaItem(id: "a")
    var record = ScanRecord(item: item, hash: 7, digest: "verified", exactAttempted: true)
    record.comparisonRevision = 2
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
    json.removeValue(forKey: "failure")
    let old = try JSONDecoder().decode(ScanRecord.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(old.failure == nil && !old.isCompared)
    var saved = ScanCheckpoint(runtime: "r2"); saved.records[item.id] = old
    saved.reconcile([item], runtime: "r2", retryUnavailable: true)
    #expect(saved.records[item.id]?.hash == 7)
    #expect(saved.records[item.id]?.digest == "verified")
    #expect(saved.progress(for: [item]).uncheckedIDs == ["a"])
}

@Test func interruptedOriginalVerificationRemainsRetryable() {
    let items = [MediaItem(id: "a"), MediaItem(id: "b")]
    var saved = ScanCheckpoint(runtime: "r2")
    for item in items { saved.records[item.id] = ScanRecord(item: item, hash: 7) }
    let progress = saved.progress(for: items)
    #expect(progress.analyzed == 2 && progress.pending == 0)
    #expect(progress.verificationTotal == 2 && progress.verified == 0)
    #expect(progress.uncheckedIDs == ["a", "b"])
}
