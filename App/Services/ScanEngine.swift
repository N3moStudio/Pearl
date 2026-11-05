import Foundation
import CryptoKit
import Vision
import PearlCore

actor SimilarityScanner {
    private let directory = URL.cachesDirectory.appending(path: "Pearl/fingerprints-v1")
    private let checkpointURL = URL.applicationSupportDirectory.appending(path: "Pearl/scan-v1.plist")
    // Decoded observations are actor-confined and bounded, avoiding repeated unarchives.
    private var decoded: [String: [VNFeaturePrintObservation]] = [:]
    private var decodedOrder: [String] = []

    private func file(_ id: String) -> URL {
        let name = SHA256.hash(data: Data(id.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name + ".json")
    }
    private func read(_ item: MediaItem) -> Fingerprint? {
        guard let data = try? Data(contentsOf: file(item.id)),
              let print = try? JSONDecoder().decode(Fingerprint.self, from: data),
              print.version == Fingerprint.version, print.runtime == Fingerprint.runtimeKey,
              print.modified == item.modified else { return nil }
        return print
    }
    private func fingerprint(_ item: MediaItem, network: Bool) async throws -> Fingerprint {
        if let cached = read(item) { return cached }
        let result = try await Fingerprints.make(item, network: network)
        try JSONEncoder().encode(result).write(to: file(item.id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return result
    }
    private func observations(_ item: MediaItem, network: Bool) async throws -> [VNFeaturePrintObservation] {
        if let cached = decoded[item.id] { return cached }
        let value = try await fingerprint(item, network: network)
        let result = try value.prints.map(Fingerprints.decode)
        decoded[item.id] = result; decodedOrder.append(item.id)
        if decodedOrder.count > 192 { decoded.removeValue(forKey: decodedOrder.removeFirst()) }
        return result
    }
    private func loadCheckpoint() -> ScanCheckpoint {
        guard let data = try? Data(contentsOf: checkpointURL),
              let result = try? PropertyListDecoder().decode(ScanCheckpoint.self, from: data) else {
            return ScanCheckpoint(runtime: Fingerprint.runtimeKey)
        }
        return result
    }
    private func save(_ checkpoint: ScanCheckpoint) throws {
        var folder = checkpointURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
        let encoder = PropertyListEncoder(); encoder.outputFormat = .binary
        try encoder.encode(checkpoint).write(to: checkpointURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    func restore(_ items: [MediaItem]) -> ScanProgress {
        var saved = loadCheckpoint()
        saved.reconcile(items, runtime: Fingerprint.runtimeKey, retryUnavailable: false)
        var state = ScanProgress(total: items.count)
        state.checked = saved.records.count; state.groups = saved.groups
        state.unavailable = saved.records.values.filter { $0.hash == nil }.count
        state.exactChecked = saved.records.values.filter { $0.digest != nil }.count
        if saved.complete { state.phase = .complete }
        return state
    }
    func clear() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
        if FileManager.default.fileExists(atPath: checkpointURL.path) { try FileManager.default.removeItem(at: checkpointURL) }
        decoded = [:]; decodedOrder = []
    }
    private func prune() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }
        let entries = files.map { url in (url, try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])) }
            .sorted { ($0.1?.contentModificationDate ?? .distantPast) > ($1.1?.contentModificationDate ?? .distantPast) }
        var bytes = 0
        for (url, values) in entries {
            bytes += values?.fileSize ?? 0
            if bytes > 128 * 1024 * 1024 { try? FileManager.default.removeItem(at: url) }
        }
    }
    private func checkBudget() throws {
        try Task.checkCancellation()
        guard ProcessInfo.processInfo.thermalState.rawValue < ProcessInfo.ThermalState.serious.rawValue,
              !ProcessInfo.processInfo.isLowPowerModeEnabled else { throw ScanPause.power }
    }

    func scan(_ items: [MediaItem], network: Bool,
              progress: @Sendable (ScanProgress) async -> Void) async throws -> ScanProgress {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        decoded = [:]; decodedOrder = []
        defer { decoded = [:]; decodedOrder = []; prune() }
        var saved = loadCheckpoint()
        saved.reconcile(items, runtime: Fingerprint.runtimeKey, retryUnavailable: true)
        saved.complete = false
        var state = ScanProgress(total: items.count)
        state.checked = saved.records.count; state.reused = state.checked; state.groups = saved.groups
        var index = CandidateIndex()
        let itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var memberGroup: [String: Int] = [:]
        for (n, group) in saved.groups.enumerated() where group.kind != .exact {
            for id in group.members { memberGroup[id] = n }
        }
        // Rebuild only the cheap index; completed similarity comparisons are retained.
        for (n, item) in items.enumerated() {
            if let hash = saved.records[item.id]?.hash { index.insert(item, hash: hash) }
            if n % 128 == 0 { try Task.checkCancellation(); await Task.yield() }
        }
        await progress(state)
        var lastSave = Date()
        do {
            for item in items where saved.records[item.id] == nil {
                try checkBudget()
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--ui-test-slow-scan") {
                    try await Task.sleep(for: .milliseconds(1500))
                }
                #endif
                do {
                    let print = try await fingerprint(item, network: network)
                    let current = try await observations(item, network: network)
                    try Task.checkCancellation()
                    var visitedGroups: Set<Int> = []
                    for candidate in index.candidates(for: item, hash: print.hash) {
                        guard let other = itemsByID[candidate], other.isVideo == item.isVideo,
                              !item.isLive, !other.isLive else { continue }
                        if item.isVideo && !MatchRules.compatibleVideo(item, other) { continue }
                        let existing = memberGroup[candidate]
                        if let existing, !visitedGroups.insert(existing).inserted { continue }
                        let members = existing.map { saved.groups[$0].members } ?? [candidate]
                        guard members.count < 20 else { continue }
                        var matchesAll = true
                        for id in members {
                            try Task.checkCancellation()
                            guard let member = itemsByID[id] else { matchesAll = false; break }
                            let prior: [VNFeaturePrintObservation]
                            do { prior = try await observations(member, network: network) }
                            catch is CancellationError { throw CancellationError() }
                            catch { matchesAll = false; break }
                            guard prior.count == current.count else { matchesAll = false; break }
                            let distances = try zip(prior, current).map { try Fingerprints.distance($0.0, $0.1) }
                            let match = item.isVideo ? MatchRules.similarVideo(item, member, distances: distances) : MatchRules.similarPhoto(distances)
                            if !match { matchesAll = false; break }
                        }
                        if matchesAll {
                            let group = existing ?? saved.groups.count
                            if existing == nil {
                                saved.groups.append(MatchGroup(kind: item.isVideo ? .video : .photo, members: [other.id]))
                                memberGroup[other.id] = group
                            }
                            saved.groups[group].members.append(item.id); memberGroup[item.id] = group
                            break
                        }
                    }
                    index.insert(item, hash: print.hash)
                    saved.records[item.id] = ScanRecord(item: item, hash: print.hash, digest: print.exact, exactAttempted: print.exact != nil)
                } catch is CancellationError { throw CancellationError() }
                catch {
                    try Task.checkCancellation()
                    saved.records[item.id] = ScanRecord(item: item, hash: nil); state.unavailable += 1
                }
                state.checked += 1
                if state.checked % 128 == 0 || Date().timeIntervalSince(lastSave) > 15 {
                    try save(saved); lastSave = Date()
                }
                if state.checked % 5 == 0 || state.checked == state.total {
                    state.groups = saved.groups; await progress(state)
                }
            }
            // First show visual matches, then read original bytes only for plausible copies.
            try checkBudget()
            let candidates = saved.exactCandidates
            state.phase = .verifying; state.verificationTotal = candidates.count
            saved.groups.removeAll { $0.kind == .exact }
            var digestGroups: [String: Int] = [:]
            var first: [String: String] = [:]
            try save(saved)
            for item in items where candidates.contains(item.id) {
                try checkBudget()
                guard var record = saved.records[item.id] else { continue }
                if !record.exactAttempted {
                    do {
                        record.digest = try await Fingerprints.exactDigest(item.id, network: network)
                        record.exactAttempted = true
                    } catch is CancellationError { throw CancellationError() }
                    catch { /* Retry unavailable originals on a later scan. */ }
                    saved.records[item.id] = record
                }
                if let digest = record.digest {
                    state.exactChecked += 1
                    if let group = digestGroups[digest] { saved.groups[group].members.append(item.id) }
                    else if let prior = first[digest] {
                        digestGroups[digest] = saved.groups.count
                        saved.groups.append(MatchGroup(kind: .exact, members: [prior, item.id]))
                    } else { first[digest] = item.id }
                }
                state.verified += 1
                if state.verified % 128 == 0 || Date().timeIntervalSince(lastSave) > 15 {
                    try save(saved); lastSave = Date()
                }
                state.groups = saved.groups; await progress(state)
            }
            try checkBudget()
            saved.complete = true; try save(saved)
            state.phase = .complete; state.groups = saved.groups
            await progress(state)
            return state
        } catch {
            // Acknowledge cancellation after the last completed item is durable.
            try save(saved)
            state.groups = saved.groups; await progress(state)
            throw error
        }
    }
    enum ScanPause: LocalizedError {
        case power
        var errorDescription: String? { "Paused to save power or cool down. Your place is saved. Resume when Low Power Mode is off and your iPhone has cooled." }
    }
}
