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
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var revision = 0
    @ObservationIgnored private var loadGeneration = 0
    @ObservationIgnored private var scanGeneration = UUID()

    var canRead: Bool { authorization == .authorized || authorization == .limited }
    var pendingItems: [MediaItem] { items.filter { queue.pending.contains($0.id) } }
    var remaining: [MediaItem] { items.filter { !queue.reviewed.contains($0.id) } }

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    deinit { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in await self?.refresh() }
    }
    func start() async {
        guard !ready else { return }
        do { queue = try await store.load(); ready = true; await refresh() }
        catch { self.error = "Your saved review could not be opened. It has been left untouched. \(error.localizedDescription)" }
    }
    func requestAccess() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await refresh()
    }
    func refresh() async {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard canRead else { stopScan(); items = []; albums = []; return }
        loadGeneration += 1
        let generation = loadGeneration
        loading = true
        async let fetched = PhotoAccess.library()
        async let collections = AlbumAccess.all()
        let (newItems, newAlbums) = await (fetched, collections)
        guard generation == loadGeneration else { return }
        if items != newItems, scanning { stopScan() }
        items = newItems; albums = newAlbums; loading = false
        let accessible = Set(items.map(\.id))
        queue.reconcile(accessible: accessible)
        for item in items where item.favorite && queue.pending.contains(item.id) { queue.unstage(item.id) }
        scan.groups = scan.groups.compactMap { group in
            var updated = group; updated.members = group.members.filter(accessible.contains)
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
        let accepted = queue.decide(item, remove: remove)
        if accepted { persist() }
        else { notice = "Favorites and protected items stay safe. Unfavorite in Photos before considering removal." }
        return accepted
    }
    func undo() { guard !deleting else { return }; queue.undo(); persist() }
    func protect(_ id: String) { guard !deleting else { return }; queue.protect(id); persist() }
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
        guard canRead, !scanning, !items.isEmpty else { return }
        let generation = UUID(); scanGeneration = generation
        scanning = true; scanMessage = "Checking on your iPhone…"
        let input = items, network = allowCloud
        scanTask = Task {
            do {
                let final = try await scanner.scan(input, network: network) { [weak self] progress in
                    await self?.updateScan(progress, generation: generation)
                }
                guard scanGeneration == generation else { return }
                scan = final; scanMessage = "Scan complete. You choose what stays."
            } catch is CancellationError {
                guard scanGeneration == generation else { return }
                scanMessage = "Scan paused. Your results are still here."
            } catch {
                guard scanGeneration == generation else { return }
                scanMessage = error.localizedDescription
            }
            if scanGeneration == generation { scanning = false; scanTask = nil }
        }
    }
    private func updateScan(_ progress: ScanProgress, generation: UUID) {
        guard generation == scanGeneration else { return }; scan = progress
    }
    func stopScan() {
        guard scanning else { return }
        scanGeneration = UUID()
        scanTask?.cancel()
        scanning = false
        scanMessage = "Scan paused. Your results are still here."
    }
    func clearCache() async {
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
