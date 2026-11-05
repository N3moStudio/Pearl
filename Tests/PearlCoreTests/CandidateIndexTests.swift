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
