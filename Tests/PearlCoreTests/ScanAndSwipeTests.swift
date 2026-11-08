import Foundation
import Testing
@testable import PearlCore

@Test func checkpointSurvivesRelaunchAndReconcilesEdits() throws {
    let a = MediaItem(id: "a"), b = MediaItem(id: "b"), c = MediaItem(id: "c")
    var saved = ScanCheckpoint(runtime: "r2")
    for item in [a, b, c] { saved.records[item.id] = ScanRecord(item: item, hash: 42) }
    saved.groups = [MatchGroup(kind: .photo, members: ["a", "b", "c"])]
    saved.complete = true
    var restored = try JSONDecoder().decode(ScanCheckpoint.self, from: JSONEncoder().encode(saved))
    var edited = b; edited.modified = .now
    restored.reconcile([a, edited, MediaItem(id: "new")], runtime: "r2", retryUnavailable: true)
    #expect(Set(restored.records.keys) == ["a"])
    #expect(restored.groups.isEmpty)
    #expect(!restored.complete)
    restored.reconcile([a], runtime: "r3", retryUnavailable: true)
    #expect(restored.records.isEmpty)
}

@Test func tenThousandItemsResumeWithoutLosingOldDuplicateCandidates() throws {
    var saved = ScanCheckpoint(runtime: "r2")
    let items = (0..<10_001).map { MediaItem(id: "\($0)", date: Date(timeIntervalSince1970: Double($0) * 200)) }
    for (n, item) in items.enumerated() { saved.records[item.id] = ScanRecord(item: item, hash: n == 10_000 ? 0 : UInt64(n)) }
    let encoded = try JSONEncoder().encode(saved)
    var restored = try JSONDecoder().decode(ScanCheckpoint.self, from: encoded)
    restored.reconcile(items, runtime: "r2", retryUnavailable: true)
    #expect(restored.records.count == 10_001)
    #expect(restored.exactCandidates == ["0", "10000"])
    #expect(items.filter { restored.records[$0.id] == nil }.isEmpty)
}

@Test func inaccessibleAssetsRetryAndLivePhotosNeverBecomeExactCandidates() {
    var saved = ScanCheckpoint(runtime: "r2")
    let unavailable = MediaItem(id: "cloud"), live = MediaItem(id: "live", isLive: true)
    saved.records[unavailable.id] = ScanRecord(item: unavailable, hash: nil)
    saved.records[live.id] = ScanRecord(item: live, hash: 7)
    saved.records["photo"] = ScanRecord(item: MediaItem(id: "photo"), hash: 7)
    #expect(saved.exactCandidates.isEmpty)
    saved.reconcile([unavailable, live], runtime: "r2", retryUnavailable: true)
    #expect(saved.records["cloud"] == nil)
}

@Test func scanPhasesNeverReportCompletionBeforeVerification() {
    var progress = ScanProgress(total: 10_000)
    progress.checked = 10_000
    #expect(progress.fraction == 0.85)
    progress.phase = .verifying; progress.verificationTotal = 100; progress.verified = 50
    #expect(abs(progress.fraction - 0.925) < 0.00001)
    progress.phase = .complete
    #expect(progress.fraction == 1)
}

@Test func swipeFollowsIntentAndSmallOrVerticalDragsDoNotDecide() {
    #expect(SwipeDecision.released(x: 20, y: 0, predictedX: 900, width: 400) == nil)
    #expect(SwipeDecision.released(x: 80, y: 100, predictedX: 400, width: 400) == nil)
    #expect(SwipeDecision.released(x: -60, y: 0, predictedX: -80, width: 400) == nil)
    #expect(SwipeDecision.released(x: -130, y: 20, predictedX: -200, width: 400) == .remove)
    #expect(SwipeDecision.released(x: 50, y: 0, predictedX: 350, width: 400) == .keep)
}

@Test func legacyCheckpointRechecksMatchesWithoutDiscardingVerifiedBytes() throws {
    let items = [MediaItem(id: "a"), MediaItem(id: "b")]
    var saved = ScanCheckpoint(runtime: "r2")
    for item in items { saved.records[item.id] = ScanRecord(item: item, hash: 42, digest: "same-original", exactAttempted: true) }
    saved.groups = [MatchGroup(kind: .photo, members: ["a", "b"]), MatchGroup(kind: .exact, members: ["a", "b"])]
    saved.complete = true
    // Recreate the actual previous Codable format, which has no revision key.
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any])
    var records = try #require(json["records"] as? [String: [String: Any]])
    for id in records.keys { records[id]?.removeValue(forKey: "comparisonRevision") }
    json["records"] = records
    var restored = try JSONDecoder().decode(ScanCheckpoint.self, from: JSONSerialization.data(withJSONObject: json))
    restored.reconcile(items, runtime: "r2", retryUnavailable: true)
    #expect(restored.checkedCount == 0)
    #expect(restored.records.count == 2)
    #expect(restored.records["a"]?.digest == "same-original")
    #expect(restored.groups.map(\.kind) == [.exact])
    #expect(!restored.complete)
}

@Test func manualRecheckKeepsOriginalVerificationAndRebuildsVisualGroups() {
    var saved = ScanCheckpoint(runtime: "r2")
    for id in ["a", "b"] { saved.records[id] = ScanRecord(item: MediaItem(id: id), hash: 3, digest: "verified", exactAttempted: true) }
    saved.groups = [MatchGroup(kind: .photo, members: ["a", "b"]), MatchGroup(kind: .exact, members: ["a", "b"])]
    saved.complete = true; saved.resetComparisons()
    #expect(saved.checkedCount == 0)
    #expect(saved.records["b"]?.exactAttempted == true)
    #expect(saved.records["a"]?.hash == 3)
    #expect(saved.groups.map(\.kind) == [.exact])
    #expect(!saved.complete)
}

@Test func visuallyMatchingDifferentHashesStillGetOriginalVerification() {
    var saved = ScanCheckpoint(runtime: "r2")
    saved.records["a"] = ScanRecord(item: MediaItem(id: "a"), hash: 1)
    saved.records["b"] = ScanRecord(item: MediaItem(id: "b"), hash: 2)
    saved.records["live"] = ScanRecord(item: MediaItem(id: "live", isLive: true), hash: 3)
    saved.records["unrelated"] = ScanRecord(item: MediaItem(id: "unrelated"), hash: 4)
    saved.groups = [MatchGroup(kind: .photo, members: ["a", "b", "live"])]
    #expect(saved.exactCandidates == ["a", "b"])
    #expect(saved.groups.allSatisfy { $0.kind != .exact }, "Shortlisting is never proof of equal originals")
}
