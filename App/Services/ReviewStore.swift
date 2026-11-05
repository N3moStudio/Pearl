import Foundation
import PearlCore

actor ReviewStore {
    private let url: URL
    private var savedRevision = 0
    init() {
        url = URL.applicationSupportDirectory.appending(path: "Pearl/review-v1.json")
    }
    func load() throws -> ReviewQueue {
        guard FileManager.default.fileExists(atPath: url.path) else { return ReviewQueue() }
        return try JSONDecoder().decode(ReviewQueue.self, from: Data(contentsOf: url))
    }
    func save(_ queue: ReviewQueue, revision: Int) throws {
        guard revision > savedRevision else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(queue).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var directory = url.deletingLastPathComponent()
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        savedRevision = revision
    }
}
