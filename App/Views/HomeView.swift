import SwiftUI
import NativeSettingsKit
import PearlCore

struct LibraryView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var capacity: Int64 = 0
    @State private var available: Int64 = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Room for what matters.").font(.title2.weight(.semibold))
                    if capacity > 0 {
                        Text("\(ByteCountFormatter.string(fromByteCount: capacity - available, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)) used")
                            .font(.subheadline).foregroundStyle(.secondary)
                        ProgressView(value: Double(capacity - available), total: Double(capacity)).tint(colors.accent)
                            .accessibilityLabel("Device storage used")
                    }
                    Text("\(model.items.count.formatted()) photos & videos").font(.subheadline).foregroundStyle(.secondary)
                    if model.loading { OrbStatus(title: "Opening your library…") }
                    if model.authorization == .limited {
                        Label("Showing your selected photos", systemImage: "photo.badge.checkmark").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if typeSize.isAccessibilitySize { VStack(spacing: 14) { shortcuts }.buttonStyle(.plain) }
                else { HStack(alignment: .top, spacing: 20) { shortcuts }.buttonStyle(.plain) }
                if model.scanning {
                    NavigationLink { CleanupView() } label: {
                        HStack {
                            OrbStatus(title: model.scan.detail)
                            Spacer()
                            Text(model.scan.fraction, format: .percent.precision(.fractionLength(0))).font(.subheadline.monospacedDigit())
                        }.pearlCard()
                    }.buttonStyle(.plain)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                    ForEach(model.homeOrder.categories) { category in
                        if category == .albums {
                            NavigationLink { AlbumsView() } label: {
                                PhotoTile(title: "Albums", subtitle: "\(model.albums.count) albums", symbol: category.symbol,
                                          cover: model.albums.first?.cover.flatMap(model.item))
                            }.buttonStyle(.plain).accessibilityIdentifier("mediaAlbums")
                        } else {
                            media(category.title, symbol: category.symbol, items: categoryItems(category))
                        }
                    }
                }
                if model.items.isEmpty && !model.loading {
                    ContentUnavailableView("A fresh start", systemImage: "photo", description: Text("Your accessible photos and videos will appear here."))
                }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background {
            colors.canvas.ignoresSafeArea()
            VStack {
                LinearGradient(colors: [colors.accent.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom).frame(height: 320)
                Spacer()
            }.ignoresSafeArea()
        }
        .navigationTitle("Pearl").refreshable { await model.refresh() }
        .task {
            let disk = await DeviceStorage.read()
            capacity = disk.total; available = disk.free
        }
    }
    @ViewBuilder private var shortcuts: some View {
        NavigationLink { CleanupView() } label: { HomeAction(title: "Smart cleanup", symbol: "sparkles") }
            .accessibilityIdentifier("homeSmartCleanup")
        NavigationLink { SwipeLibraryView() } label: { HomeAction(title: "Swipe", symbol: "hand.draw") }
            .accessibilityIdentifier("openSwipe")
    }
    private func categoryItems(_ category: HomeCategory) -> [MediaItem] {
        switch category {
        case .photos: model.items.filter { !$0.isVideo }
        case .videos: model.items.filter(\.isVideo)
        default: model.items.filter { model.categoryIDs[category]?.contains($0.id) == true }
        }
    }
    private func media(_ title: String, symbol: String, items: [MediaItem]) -> some View {
        NavigationLink { MediaGrid(title: title, items: items) } label: {
            PhotoTile(title: title, subtitle: "\(items.count.formatted()) items", symbol: symbol, cover: items.first)
        }.buttonStyle(.plain).accessibilityIdentifier("media\(title)")
    }
}

private struct HomeAction: View {
    @Environment(\.nskPalette) private var colors
    let title: String
    let symbol: String
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if typeSize.isAccessibilitySize {
            HStack(spacing: 16) {
                icon
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
            }.pearlCard().contentShape(Rectangle())
        } else {
            VStack(spacing: 10) {
                icon
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.primary).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).contentShape(Rectangle())
        }
    }
    private var icon: some View {
        Image(systemName: symbol).font(.system(size: 28, weight: .regular)).foregroundStyle(colors.accent)
            .frame(width: 68, height: 68).background { PearlFloatingBackground(shape: Circle()) }
            .overlay(Circle().strokeBorder(colors.accent.opacity(0.14)))
    }
}

struct PhotoTile: View {
    @Environment(\.nskPalette) private var colors
    let title: String
    let subtitle: String
    let symbol: String
    let cover: MediaItem?
    var height: CGFloat = 210
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let cover { Thumbnail(id: cover.id, size: 550, modified: cover.modified) }
            else {
                PearlPlaceholder()
                Image(systemName: symbol).font(.system(size: 35)).foregroundStyle(colors.accent.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.bottom, 30)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.12), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }.padding(16)
        }.frame(height: height).clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .ignore).accessibilityLabel("\(title), \(subtitle)")
    }
}

struct SwipeLibraryView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    @State private var oldest = false
    @State private var year: Int?
    private var months: [(key: String, items: [MediaItem])] {
        Dictionary(grouping: model.items.filter { year == nil || Calendar.current.component(.year, from: $0.date) == year }) { MatchRules.monthKey($0.date) }
            .map { (key: $0.key, items: $0.value) }.sorted { oldest ? $0.key < $1.key : $0.key > $1.key }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(model.items.count.formatted()) moments").font(.title2.weight(.semibold))
                    Text("A month at a time. Your choices are saved.").font(.subheadline).foregroundStyle(.secondary)
                }.padding(.horizontal, 20)
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        category("Recent", items: model.items)
                        category("Random", items: model.items, random: true)
                        category("Favorites", items: model.items.filter(\.favorite))
                        category("Screenshots", items: model.items.filter(\.isScreenshot))
                        category("Videos", items: model.items.filter(\.isVideo))
                    }.padding(.horizontal, 20)
                }.scrollIndicators(.hidden)
                LazyVStack(spacing: 10) {
                    ForEach(months, id: \.key) { month in
                        let title = month.items.first?.date.formatted(.dateTime.month(.wide).year()) ?? month.key
                        let count = month.items.filter { model.queue.reviewed.contains($0.id) }.count
                        Button { model.openReview(month.items, title: title) } label: {
                            HStack(spacing: 18) {
                                if let cover = month.items.first {
                                    Thumbnail(id: cover.id, modified: cover.modified).frame(width: 66, height: 76)
                                        .clipShape(RoundedRectangle(cornerRadius: 14)).rotationEffect(.degrees(-5))
                                }
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(title).font(.headline).foregroundStyle(.primary)
                                    Text(count == 0 ? "\(month.items.count) items" : "\(count) of \(month.items.count) sorted")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                MonthRing(done: count, total: month.items.count)
                            }.pearlCard()
                        }.buttonStyle(.plain).accessibilityIdentifier("swipeMonth")
                    }
                }.padding(.horizontal, 20)
                if months.isEmpty { ContentUnavailableView("No moments here yet", systemImage: "calendar") }
            }.padding(.vertical, 12).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle("Swipe")
            .toolbar {
                ReviewQueueToolbar()
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Sort and filter", systemImage: "arrow.up.arrow.down") {
                        Toggle("Oldest first", isOn: $oldest)
                        Picker("Year", selection: $year) {
                            Text("All years").tag(nil as Int?)
                            ForEach(Array(Set(model.items.map { Calendar.current.component(.year, from: $0.date) })).sorted(by: >), id: \.self) { Text(String($0)).tag(Optional($0)) }
                        }
                    }
                }
            }
    }
    private func category(_ title: String, items: [MediaItem], random: Bool = false) -> some View {
        Button { model.openReview(random ? items.shuffled() : items, title: title) } label: {
            PhotoTile(title: title, subtitle: "\(items.count.formatted())", symbol: "photo", cover: items.first, height: 145).frame(width: 130)
        }.buttonStyle(.plain).disabled(items.isEmpty)
    }
}

private struct MonthRing: View {
    @Environment(\.nskPalette) private var colors
    let done: Int
    let total: Int
    var body: some View {
        ZStack {
            Circle().stroke(colors.accent.opacity(0.12), lineWidth: 5)
            Circle().trim(from: 0, to: Double(done) / Double(max(total, 1)))
                .stroke(colors.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
            if done == total { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(colors.accent) }
        }.frame(width: 38, height: 38).accessibilityLabel("\(done) of \(total) sorted")
    }
}

private enum DeviceStorage {
    @concurrent static func read() async -> (total: Int64, free: Int64) {
        let values = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (values?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (values?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        return (total, min(total, max(0, free)))
    }
}
