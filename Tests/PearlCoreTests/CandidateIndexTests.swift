import Foundation
import Testing
@testable import PearlCore

@Test func candidateIndexFindsCrossDateCopiesWithoutAllPairs() {
    var index = CandidateIndex()
    index.insert(MediaItem(id: "old", date: .distantPast), hash: 0x123456789abcdef0)
    let candidates = index.candidates(for: MediaItem(id: "new", date: .now), hash: 0x123456789abcdeff)
    #expect(candidates == ["old"])
}

@Test func candidateShortlistStaysBoundedForUniformImages() {
    var index = CandidateIndex()
    for i in 0..<1000 { index.insert(MediaItem(id: "\(i)", date: .now), hash: 0) }
    let candidates = index.candidates(for: MediaItem(id: "next", date: .now), hash: 0)
    #expect(candidates.count <= 160)
    #expect(Set(candidates).count == candidates.count)
    #expect(candidates.contains("999"))
}

@Test func cachedLibraryRebuildRetainsNeighborsForNewPhotos() {
    var index = CandidateIndex()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    index.insert(MediaItem(id: "neighbor", date: now.addingTimeInterval(-30)), hash: UInt64.max)
    // PhotoKit returns newest first. The old last-32 list forgot this neighbor.
    for i in 1...500 {
        index.insert(MediaItem(id: "older-\(i)", date: now.addingTimeInterval(Double(-i * 3600))), hash: 0xaaaaaaaaaaaaaaaa)
    }
    let result = index.candidates(for: MediaItem(id: "new", date: now), hash: 0)
    #expect(result.contains("neighbor"))
}

@Test func smallHashDifferencesAcrossEveryOldBandStillReachVerification() {
    var index = CandidateIndex()
    index.insert(MediaItem(id: "old", date: .distantPast), hash: 0)
    // One differing bit in each 16-bit band defeated the old four-band index.
    let result = index.candidates(for: MediaItem(id: "new", date: .now), hash: 0x0001000100010001)
    #expect(result == ["old"])
}

@Test func videoBucketsCannotEvictPhotoCandidatesAndSelfIsExcluded() {
    var index = CandidateIndex()
    let photo = MediaItem(id: "photo", date: .distantPast)
    index.insert(photo, hash: 0)
    for i in 0..<200 { index.insert(MediaItem(id: "video-\(i)", date: .now, isVideo: true), hash: 0) }
    #expect(index.candidates(for: MediaItem(id: "new", date: .now), hash: 0) == ["photo"])
    #expect(index.candidates(for: photo, hash: 0).isEmpty)
}
