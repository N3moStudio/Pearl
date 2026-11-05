import Photos
import UIKit
import AVFoundation
import PearlCore

enum PhotoAccess {
    @concurrent static func library() async -> [MediaItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        let result = PHAsset.fetchAssets(with: options)
        var items: [MediaItem] = []
        result.enumerateObjects { asset, _, _ in
            guard asset.mediaType == .image || asset.mediaType == .video else { return }
            items.append(MediaItem(id: asset.localIdentifier, date: asset.creationDate ?? .distantPast,
                modified: asset.modificationDate ?? .distantPast, isVideo: asset.mediaType == .video,
                isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
                isLive: asset.mediaSubtypes.contains(.photoLive), favorite: asset.isFavorite,
                width: asset.pixelWidth, height: asset.pixelHeight, duration: asset.duration))
        }
        return items
    }

    static func asset(_ id: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }

    @concurrent static func image(_ id: String, size: CGFloat = 512, network: Bool = false) async -> UIImage? {
        guard !Task.isCancelled, let asset = asset(id) else { return nil }
        let manager = PHImageManager.default()
        let stream = AsyncStream<UIImage?> { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = network
            let request = manager.requestImage(for: asset,
                targetSize: CGSize(width: size, height: size), contentMode: .aspectFit, options: options) { image, info in
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
                continuation.yield(image)
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in manager.cancelImageRequest(request) }
        }
        for await image in stream { return Task.isCancelled ? nil : image }
        return nil
    }

    @concurrent static func video(_ id: String, network: Bool) async -> AVAsset? {
        guard !Task.isCancelled, let asset = asset(id) else { return nil }
        let manager = PHImageManager.default()
        let stream = AsyncStream<AVAsset?> { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = network
            options.deliveryMode = .highQualityFormat
            let request = manager.requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
                continuation.yield(asset); continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in manager.cancelImageRequest(request) }
        }
        for await asset in stream { return Task.isCancelled ? nil : asset }
        return nil
    }

    @concurrent static func delete(_ ids: Set<String>) async throws {
        try Task.checkCancellation()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(ids), options: nil)
        // Recheck live favorites and edit permission immediately before the system confirmation.
        var safe: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            if !asset.isFavorite && asset.canPerform(.delete) { safe.append(asset) }
        }
        guard safe.count == ids.count else { throw PhotoError.changedSelection }
        let selection = safe
        let changes: @Sendable () -> Void = { PHAssetChangeRequest.deleteAssets(selection as NSArray) }
        try await PHPhotoLibrary.shared().performChanges(changes)
    }

    enum PhotoError: LocalizedError {
        case changedSelection
        var errorDescription: String? { "Some items changed, became favorites, or cannot be deleted. Refresh your library and review the selection again." }
    }
}

struct Album: Identifiable, Sendable {
    let id: String
    let title: String
    let count: Int
    let cover: String?
}

enum AlbumAccess {
    @concurrent static func all() async -> [Album] {
        var albums: [Album] = []
        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil).enumerateObjects { collection, _, _ in
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            albums.append(Album(id: collection.localIdentifier, title: collection.localizedTitle ?? "Album",
                                count: assets.count, cover: assets.firstObject?.localIdentifier))
        }
        return albums.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    @concurrent static func members(_ id: String) async -> Set<String> {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject else { return [] }
        var ids: Set<String> = []
        PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in ids.insert(asset.localIdentifier) }
        return ids
    }
    @concurrent static func create(_ title: String) async throws {
        let changes: @Sendable () -> Void = { PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title) }
        try await PHPhotoLibrary.shared().performChanges(changes)
    }
    @concurrent static func add(_ ids: Set<String>, to albumID: String) async throws {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(ids), options: nil)
        let changes: @Sendable () -> Void = { PHAssetCollectionChangeRequest(for: album)?.addAssets(assets) }
        try await PHPhotoLibrary.shared().performChanges(changes)
    }
}
