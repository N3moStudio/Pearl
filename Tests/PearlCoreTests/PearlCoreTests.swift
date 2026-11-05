import Foundation
import Testing
@testable import PearlCore

@Test func selectionIsReversibleAndNeverAutomatic() {
    var queue = ReviewQueue()
    let a = MediaItem(id: "a"), b = MediaItem(id: "b")
    #expect(queue.pending.isEmpty)
    let accepted1 = queue.decide(a, remove: true)
    #expect(accepted1)
    let accepted2 = queue.decide(b, remove: false)
    #expect(accepted2)
    #expect(queue.pending == ["a"])
    queue.undo()
    #expect(!queue.reviewed.contains("b"))
    queue.undo()
    #expect(queue.pending.isEmpty)
    #expect(queue.reviewed.isEmpty)
}

@Test func favoritesAndProtectedAssetsCannotBeQueued() {
    var queue = ReviewQueue()
    let accepted3 = queue.decide(MediaItem(id: "fav", favorite: true), remove: true)
    #expect(!accepted3)
    let accepted4 = queue.decide(MediaItem(id: "a"), remove: true)
    #expect(accepted4)
    queue.protect("a")
    #expect(queue.pending.isEmpty)
    let accepted5 = queue.decide(MediaItem(id: "a"), remove: true)
    #expect(!accepted5)
    queue.undo()
    #expect(queue.pending.isEmpty)
}

@Test func inaccessibleItemsAndSuccessfulDeletionsLeaveNoStaleUndo() {
    var queue = ReviewQueue()
    _ = queue.decide(MediaItem(id: "gone"), remove: true)
    _ = queue.decide(MediaItem(id: "here"), remove: true)
    queue.reconcile(accessible: ["here"])
    #expect(queue.pending == ["here"])
    queue.completedDeletion(["here"])
    queue.undo()
    #expect(queue.pending.isEmpty)
}

@Test func persistenceKeepsDecisions() throws {
    var queue = ReviewQueue()
    _ = queue.decide(MediaItem(id: "a"), remove: true)
    queue.protect("b")
    let restored = try JSONDecoder().decode(ReviewQueue.self, from: JSONEncoder().encode(queue))
    #expect(restored.pending == ["a"])
    #expect(restored.protected == ["b"])
    #expect(restored.canUndo)
}

@Test func photoGroupsMustMatchEveryMemberNotJustAnIntermediate() {
    #expect(MatchRules.similarPhoto([0.08, 0.19]))
    #expect(!MatchRules.similarPhoto([0.08, 0.40]))
    #expect(!MatchRules.similarPhoto([]))
    #expect(!MatchRules.similarPhoto([.nan]))
    #expect(!MatchRules.similarPhoto([-0.1]))
}

@Test func videosRequireAllFiveFramesAndCompatibleDurations() {
    let a = MediaItem(id: "a", isVideo: true, duration: 10)
    var b = MediaItem(id: "b", isVideo: true, duration: 10.1)
    #expect(MatchRules.similarVideo(a, b, distances: [0.1, 0.1, 0.1, 0.1, 0.1]))
    #expect(!MatchRules.similarVideo(a, b, distances: [0.1, 0.1]))
    #expect(!MatchRules.similarVideo(a, b, distances: [0.1, 0.1, 0.5, 0.1, 0.1]))
    b.duration = 12
    #expect(!MatchRules.similarVideo(a, b, distances: Array(repeating: 0.1, count: 5)))
}

@Test func perceptualDistanceAndMonthGrouping() {
    #expect(MatchRules.hamming(0, UInt64.max) == 64)
    #expect(MatchRules.hamming(0b1100, 0b1010) == 2)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!
    #expect(MatchRules.monthKey(date, calendar: calendar) == "2026-11")
}
