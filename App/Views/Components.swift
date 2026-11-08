import SwiftUI
import NativeSettingsKit
import ThinkingOrbsKit
import PearlCore

struct ReviewQueueToolbar: ToolbarContent {
    @Environment(PearlModel.self) private var model
    var body: some ToolbarContent {
        if !model.pendingItems.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Review \(model.pendingItems.count) selected", systemImage: "tray") { model.showQueue = true }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("reviewQueue")
            }
        }
    }
}

extension View {
    func pearlCard() -> some View { modifier(PearlCard()) }
}
private struct PearlCard: ViewModifier {
    @Environment(\.nskPalette) private var colors
    func body(content: Content) -> some View {
        content.padding(18).background(colors.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(colors.text.opacity(0.055)))
    }
}

struct OrbStatus: View {
    let title: String
    @Environment(\.scenePhase) private var scene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false
    var body: some View {
        HStack(spacing: 10) {
            ThinkingOrb(state: .searching, size: .px20, theme: .auto,
                        paused: !visible || scene != .active || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled,
                        displaySize: 22).accessibilityHidden(true)
            Text(title).font(.subheadline).foregroundStyle(.secondary)
        }.accessibilityElement(children: .ignore).accessibilityLabel(title)
            .onAppear { visible = true }.onDisappear { visible = false }
    }
}

struct PearlPlaceholder: View {
    @Environment(\.nskPalette) private var colors
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(colors.accent.opacity(0.06)))
            // Deterministic pearl grain, no artificial wait or perpetual shimmer.
            for i in 0..<450 {
                let x = CGFloat((i * 73) % 997) / 997 * size.width
                let y = CGFloat((i * 137) % 991) / 991 * size.height
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(colors.accent.opacity(0.12)))
            }
        }.accessibilityHidden(true)
    }
}

@MainActor private enum ThumbnailCache {
    static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>(); cache.totalCostLimit = 40 * 1024 * 1024; cache.countLimit = 150; return cache
    }()
}

struct Thumbnail: View {
    let id: String
    var size: CGFloat = 260
    var modified: Date = .distantPast
    var fit = false
    var network = false
    var showStatus = false
    @State private var image: UIImage?
    @State private var finished = false
    @State private var loadedID: String?
    @State private var download = false
    @State private var retry = 0
    private var requestKey: String { "\(id)-\(size)-\(modified.timeIntervalSince1970)-\(network || download)-\(retry)" }
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if fit && image != nil { Color.black } else { PearlPlaceholder() }
                if let image {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: fit ? .fit : .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height).clipped()
                        .accessibilityLabel("Media preview").accessibilityIdentifier("previewImage")
                } else if showStatus && finished {
                    VStack(spacing: 12) {
                        Image(systemName: "icloud")
                        Text("Preview unavailable").font(.headline)
                        Button(network || download ? "Retry preview" : "Download preview from iCloud") {
                            download = true; retry += 1
                        }.buttonStyle(.bordered)
                    }.padding().foregroundStyle(.white)
                } else if showStatus {
                    ProgressView().tint(.white).accessibilityLabel("Loading preview")
                } else if finished {
                    Image(systemName: "icloud").foregroundStyle(.secondary)
                }
            }
        }
        .task(id: requestKey) {
            // Keep the same asset's poster through a favorite/metadata update.
            // Never show a previous asset while rapidly jumping the filmstrip.
            if loadedID != id { image = nil; download = false }
            loadedID = id; finished = false
            let key = "\(id)-\(size)-\(modified.timeIntervalSince1970)" as NSString
            if let cached = ThumbnailCache.images.object(forKey: key) { image = cached; finished = true; return }
            if fit && size > 300 && image == nil {
                let poster = await PhotoAccess.image(id, size: 300)
                guard !Task.isCancelled else { return }
                image = poster
            }
            let result = await PhotoAccess.image(id, size: size, network: network || download)
            guard !Task.isCancelled else { return }
            if let result { image = result }
            finished = true
            if let result {
                let cost = result.cgImage.map { $0.bytesPerRow * $0.height } ??
                    Int(result.size.width * result.size.height * result.scale * result.scale * 4)
                ThumbnailCache.images.setObject(result, forKey: key, cost: cost)
            }
        }.accessibilityHidden(!showStatus)
    }
}

struct MediaRow: View {
    @Environment(\.nskPalette) private var colors
    let title: String
    let subtitle: String
    let symbol: String
    var previews: [MediaItem] = []
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(colors.accent).frame(width: 26)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if let item = previews.first {
                Thumbnail(id: item.id, modified: item.modified).frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 13))
            }
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }.frame(minHeight: 44).pearlCard().contentShape(Rectangle())
    }
}
