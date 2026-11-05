import Foundation
import CryptoKit
import PearlCore

struct ScanProgress: Sendable {
    var checked = 0
    var total = 0
    var unavailable = 0
    var exactChecked = 0
    var groups: [MatchGroup] = []
}

actor SimilarityScanner {
    private let directory = URL.cachesDirectory.appending(path: "Pearl/fingerprints-v1")

    private func file(_ id: String) -> URL {
        let name = SHA256.hash(data: Data(id.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name + ".json")
    }
    private func read(_ item: MediaItem) -> Fingerprint? {
        guard let data = try? Data(contentsOf: file(item.id)),
              let print = try? JSONDecoder().decode(Fingerprint.self, from: data),
              print.version == Fingerprint.version, print.modified == item.modified else { return nil }
        return print
    }
    func clear() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
    private func prune() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }
        let sorted = files.sorted {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) >
            ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
        var bytes = 0
        for (index, url) in sorted.enumerated() {
            bytes += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if index >= 6000 || bytes > 128 * 1024 * 1024 { try? FileManager.default.removeItem(at: url) }
        }
    }

    func scan(_ items: [MediaItem], network: Bool,
              progress: @Sendable (ScanProgress) async -> Void) async throws -> ScanProgress {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { prune() }
        var state = ScanProgress(total: items.count)
        var index = CandidateIndex()
        var itemsByID: [String: MediaItem] = [:]
        var exactGroups: [String: Int] = [:]
        var exactFirst: [String: String] = [:]
        var memberGroup: [String: Int] = [:]
        await progress(state)
        for item in items {
            try Task.checkCancellation()
            guard ProcessInfo.processInfo.thermalState.rawValue < ProcessInfo.ThermalState.serious.rawValue,
                  !ProcessInfo.processInfo.isLowPowerModeEnabled else { throw ScanPause.power }
            do {
                let fingerprint: Fingerprint
                if let cached = read(item), !network || cached.exact != nil {
                    fingerprint = cached
                } else {
                    fingerprint = try await Fingerprints.make(item, network: network)
                    try JSONEncoder().encode(fingerprint).write(to: file(item.id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                }
                try Task.checkCancellation()
                var isExact = false
                if let digest = fingerprint.exact {
                    state.exactChecked += 1
                    if let group = exactGroups[digest] {
                        state.groups[group].members.append(item.id); isExact = true
                    } else if let first = exactFirst[digest] {
                        exactGroups[digest] = state.groups.count
                        state.groups.append(MatchGroup(kind: .exact, members: [first, item.id])); isExact = true
                    } else { exactFirst[digest] = item.id }
                }
                if !isExact {
                    let candidates = index.candidates(for: item, hash: fingerprint.hash)
                    for candidate in candidates {
                        guard let other = itemsByID[candidate] else { continue }
                        let existing = memberGroup[candidate]
                        let members = existing.map { state.groups[$0].members } ?? [candidate]
                        // Complete-link grouping avoids A~B~C chains where A and C differ.
                        guard members.count < 20 else { continue }
                        var matchesAll = true
                        for id in members {
                            guard let member = itemsByID[id], let prior = read(member),
                                  prior.prints.count == fingerprint.prints.count else { matchesAll = false; break }
                            let distances = try zip(prior.prints, fingerprint.prints).map { try Fingerprints.distance($0.0, $0.1) }
                            let match = item.isVideo ? MatchRules.similarVideo(item, member, distances: distances) :
                                (!member.isVideo && !member.isLive && !item.isLive && MatchRules.similarPhoto(distances))
                            if !match { matchesAll = false; break }
                        }
                        if matchesAll {
                            let group = existing ?? state.groups.count
                            if existing == nil {
                                state.groups.append(MatchGroup(kind: item.isVideo ? .video : .photo, members: [other.id]))
                                memberGroup[other.id] = group
                            }
                            state.groups[group].members.append(item.id); memberGroup[item.id] = group
                            break
                        }
                    }
                }
                index.insert(item, hash: fingerprint.hash)
                itemsByID[item.id] = item
            } catch is CancellationError { throw CancellationError() }
            catch { state.unavailable += 1 }
            state.checked += 1
            if state.checked % 5 == 0 || state.checked == state.total { await progress(state) }
        }
        return state
    }
    enum ScanPause: LocalizedError {
        case power
        var errorDescription: String? { "Scan paused to save power or let your iPhone cool down. Turn off Low Power Mode, then resume when you're ready." }
    }
}
