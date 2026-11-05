import SwiftUI
import Photos
import PearlCore

@MainActor @Observable
final class PearlModel: NSObject, PHPhotoLibraryChangeObserver {
    var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    var items: [MediaItem] = []
    var albums: [Album] = []
    var queue = ReviewQueue()
    var scan = ScanProgress()
    var scanning = false
    var stoppingScan = false
    var backgroundStatus = ""
    var reviewSession: ReviewSession?
    var selectedTab = 0
    var favoriting: Set<String> = []
    var clearingCache = false
    var scanMessage = "Find a little more space."
    var loading = false
    var deleting = false
    var error: String?
    var notice: String?
    var ready = false
    var allowCloud = false
    var showQueue = false
    @ObservationIgnored private let store = ReviewStore()
    @ObservationIgnored private let scanner = SimilarityScanner()
    @ObservationIgnored private let background = BackgroundScan()
    @ObservationIgnored private var scanItems: [String: MediaItem] = [:]
    private var itemLookup: [String: MediaItem] = [:]
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var revision = 0
    @ObservationIgnored private var loadGeneration = 0
    @ObservationIgnored private var scanGeneration = UUID()
    @ObservationIgnored private var observingPhotos = false

    var canRead: Bool { authorization == .authorized || authorization == .limited }
    var pendingItems: [MediaItem] { items.filter { queue.pending.contains($0.id) } }
    var remaining: [MediaItem] { items.filter { !queue.reviewed.contains($0.id) } }

    deinit {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in await self?.refresh() }
    }
    func start() async {
        guard !ready else { return }
        do {
            queue = try await store.load()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-test-clear-scan") { try await scanner.clear() }
            if ProcessInfo.processInfo.arguments.contains("--ui-test-reset-review") { queue = ReviewQueue() }
            #endif
            ready = true; await refresh()
            scan = await scanner.restore(items)
            if scan.checked > 0 { scanMessage = scan.phase == .complete ? "Scan complete. You choose what stays." : "Your place is saved. Ready to resume." }
        }
        catch { self.error = "Your saved review could not be opened. It has been left untouched. \(error.localizedDescription)" }
    }
    func requestAccess() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await refresh()
    }
    func refresh() async {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard canRead else {
            if observingPhotos {
                PHPhotoLibrary.shared().unregisterChangeObserver(self)
                observingPhotos = false
            }
            loadGeneration += 1
            loading = false
            stopScan(); items = []; itemLookup = [:]; albums = []; scan.groups = []; return
        }
        // Register only after the person has chosen photo access on the welcome screen.
        if !observingPhotos {
            PHPhotoLibrary.shared().register(self)
            observingPhotos = true
        }
        loadGeneration += 1
        let generation = loadGeneration
        loading = true
        async let fetched = PhotoAccess.library()
        async let collections = AlbumAccess.all()
        let (newItems, newAlbums) = await (fetched, collections)
        guard generation == loadGeneration else { return }
        let previousVersions = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.modified) })
        let changed = Set(newItems.filter { previousVersions[$0.id] != nil && previousVersions[$0.id] != $0.modified }.map(\.id))
        items = newItems; albums = newAlbums; loading = false
        itemLookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let accessible = Set(items.map(\.id))
        queue.reconcile(accessible: accessible)
        for item in items where item.favorite && queue.pending.contains(item.id) { queue.unstage(item.id) }
        scan.groups = scan.groups.compactMap { group in
            var updated = group; updated.members = group.members.filter { accessible.contains($0) && !changed.contains($0) }
            return updated.members.count > 1 ? updated : nil
        }
        persist()
    }
    private func persist() {
        guard ready else { return }
        revision += 1
        let revision = revision, snapshot = queue
        Task {
            do { try await store.save(snapshot, revision: revision) }
            catch { self.error = "Your latest review could not be saved. Keep Pearl open and try again. \(error.localizedDescription)" }
        }
    }
    @discardableResult func decide(_ item: MediaItem, remove: Bool) -> Bool {
        guard ready, !deleting else { return false }
        guard let current = itemLookup[item.id] else {
            notice = "This item is no longer accessible. Skip it to continue your review."; return false
        }
        let accepted = queue.decide(current, remove: remove)
        if accepted { persist() }
        else { notice = "Favorites and protected items stay safe. Unfavorite with the heart before considering removal." }
        return accepted
    }
    @discardableResult func undo() -> String? {
        guard !deleting else { return nil }
        let id = queue.lastUndoID; queue.undo(); persist(); return id
    }
    func item(_ id: String) -> MediaItem? { itemLookup[id] }
    func openReview(_ items: [MediaItem], title: String, startID: String? = nil) {
        guard !items.isEmpty else { return }
        let position = startID.flatMap { id in items.firstIndex { $0.id == id } } ?? items.firstIndex { !queue.reviewed.contains($0.id) } ?? 0
        reviewSession = ReviewSession(title: title, items: items, position: position)
    }
    func toggleFavorite(_ id: String) async {
        guard let current = itemLookup[id], !favoriting.contains(id), !deleting else { return }
        favoriting.insert(id); defer { favoriting.remove(id) }
        do {
            try await PhotoAccess.setFavorite(id, favorite: !current.favorite)
            if !current.favorite && queue.pending.contains(id) { queue.unstage(id); persist() }
            await refresh()
        } catch { self.error = "Couldn't change this favorite. \(error.localizedDescription)" }
    }
    func protect(_ id: String) { guard !deleting else { return }; queue.protect(id); persist() }
    func toggleProtection(_ id: String) {
        guard !deleting else { return }
        if queue.protected.contains(id) { queue.unprotect(id) } else { queue.protect(id) }
        persist()
    }
    func unstage(_ id: String) { guard !deleting else { return }; queue.unstage(id); persist() }
    func removeConfirmed() async {
        guard ready, !deleting else { return }
        let ids = Set(pendingItems.filter { !$0.favorite && !queue.protected.contains($0.id) }.map(\.id))
        guard !ids.isEmpty else { return }
        deleting = true
        defer { deleting = false }
        do {
            // Persist the exact review before requesting PhotoKit's destructive operation.
            revision += 1; try await store.save(queue, revision: revision)
            try await PhotoAccess.delete(ids)
            queue.completedDeletion(ids); persist()
            notice = "Removed \(ids.count) items. You can recover them in Photos → Recently Deleted."
            await refresh()
        } catch { self.error = "Nothing was cleared from your review queue. \(error.localizedDescription)" }
    }
    func beginScan() {
        guard canRead, !scanning, scanTask == nil, !clearingCache, !items.isEmpty else { return }
        let generation = UUID(); scanGeneration = generation
        scanning = true; stoppingScan = false; scanMessage = "Checking on your iPhone…"
        if background.request(start: { [weak self] in self?.runScan(generation: generation) }, expiration: { [weak self] in
            self?.stopScan(message: "Background scan paused. Your place is saved.")
        }) {
            backgroundStatus = "You can leave Pearl. Track progress in the Live Activity."
        } else {
            backgroundStatus = "Background scanning isn't available right now. Other Pearl tabs work; leaving the app saves your place."
            runScan(generation: generation)
        }
    }
    private func runScan(generation: UUID) {
        guard scanning, scanGeneration == generation else { background.finish(success: false); return }
        let input = items, network = allowCloud
        scanItems = Dictionary(uniqueKeysWithValues: input.map { ($0.id, $0) })
        scanTask = Task {
            var success = false
            do {
                let final = try await scanner.scan(input, network: network) { [weak self] progress in
                    await self?.updateScan(progress, generation: generation)
                }
                guard scanGeneration == generation else { return }
                updateScan(final, generation: generation); scanMessage = "Scan complete. You choose what stays."
                success = true
            } catch is CancellationError {
                guard scanGeneration == generation else { return }
                if !stoppingScan { scanMessage = "Scan paused. Your place is saved." }
            } catch {
                guard scanGeneration == generation else { return }
                scanMessage = error.localizedDescription
            }
            if scanGeneration == generation {
                background.finish(success: success)
                scanning = false; stoppingScan = false; scanTask = nil
            }
        }
    }
    private func updateScan(_ progress: ScanProgress, generation: UUID) {
        guard generation == scanGeneration else { return }
        var valid = progress
        valid.groups = progress.groups.compactMap { group in
            let ids = group.members.filter { id in
                guard let original = scanItems[id], let current = itemLookup[id] else { return false }
                return ScanRecord(item: original, hash: nil).matches(current)
            }
            return ids.count > 1 ? MatchGroup(kind: group.kind, members: ids) : nil
        }
        scan = valid; background.update(progress)
    }
    func stopScan(message: String = "Scan paused. Your place is saved.") {
        guard scanning else { return }
        stoppingScan = true; scanMessage = message
        if let scanTask { scanTask.cancel() }
        else { background.finish(success: false); scanning = false; stoppingScan = false }
    }
    func enteredBackground() {
        guard scanning, !background.running else { return }
        background.beginSaving()
        stopScan(message: "Your place is saved. Resume when you return to Pearl.")
    }
    func clearCache() async {
        guard !clearingCache else { return }
        clearingCache = true
        defer { clearingCache = false }
        stopScan()
        if let scanTask { await scanTask.value }
        do { try await scanner.clear(); scan = ScanProgress(); scanMessage = "Analysis cache cleared." }
        catch { self.error = error.localizedDescription }
    }
    func createAlbum(_ title: String) async {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do { try await AlbumAccess.create(title); albums = await AlbumAccess.all() }
        catch { self.error = error.localizedDescription }
    }
    func addToAlbum(_ ids: Set<String>, album: Album) async {
        do { try await AlbumAccess.add(ids, to: album.id); notice = "Added to \(album.title). Items also remain in your library."; albums = await AlbumAccess.all() }
        catch { self.error = error.localizedDescription }
    }
}

struct ReviewSession: Identifiable {
    let id = UUID()
    let title: String
    let items: [MediaItem]
    let position: Int
    let positions: [String: Int]
    init(title: String, items: [MediaItem], position: Int) {
        self.title = title; self.items = items; self.position = position
        positions = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($0.element.id, $0.offset) })
    }
}
