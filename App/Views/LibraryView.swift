import SwiftUI
import PearlCore

struct LibraryView: View {
    @Environment(PearlModel.self) private var model
    @State private var oldest = false
    private var years: [Int] { Array(Set(model.items.map { Calendar.current.component(.year, from: $0.date) })).sorted(by: oldest ? (<) : (>)) }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                Text("A little space, at your pace.").foregroundStyle(.secondary)
                if model.loading { OrbStatus(title: "Opening your library…") }
                if model.authorization == .limited {
                    Label("Showing the photos you chose. Manage access in Settings.", systemImage: "photo.badge.checkmark").font(.footnote).foregroundStyle(.secondary)
                }
                if !model.remaining.isEmpty {
                    NavigationLink {
                        ReviewView(items: model.remaining, title: "Your next moments")
                    } label: {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 5) {
                                ForEach(Array(model.remaining.prefix(3))) { item in
                                    Thumbnail(id: item.id, modified: item.modified).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("A few moments at a time").font(.headline).foregroundStyle(.primary)
                                    Text("\(model.remaining.count) left to review").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill").font(.title).foregroundStyle(PearlStyle.sage)
                            }
                        }.padding(16).background(PearlStyle.sage.opacity(0.10), in: RoundedRectangle(cornerRadius: 26))
                    }.buttonStyle(.plain)
                }
                Text("Media").font(.title2.bold())
                VStack(spacing: 10) {
                    media("Photos", symbol: "photo", items: model.items.filter { !$0.isVideo })
                    media("Videos", symbol: "play.rectangle", items: model.items.filter(\.isVideo))
                    media("Screenshots", symbol: "viewfinder", items: model.items.filter(\.isScreenshot))
                    media("Live Photos", symbol: "livephoto", items: model.items.filter(\.isLive))
                    media("Favorites", symbol: "heart", items: model.items.filter(\.favorite))
                }
                HStack {
                    Text("By date").font(.title2.bold())
                    Spacer()
                    Button(oldest ? "Oldest first" : "Newest first", systemImage: "arrow.up.arrow.down") { oldest.toggle() }
                        .font(.subheadline)
                }
                ForEach(years, id: \.self) { year in
                    let items = model.items.filter { Calendar.current.component(.year, from: $0.date) == year }
                    NavigationLink {
                        MonthView(year: year, items: items)
                    } label: {
                        MediaRow(title: String(year), subtitle: "\(items.count) moments", symbol: "calendar", previews: items)
                    }.buttonStyle(.plain)
                }
                if model.items.isEmpty && !model.loading {
                    ContentUnavailableView("A fresh start", systemImage: "photo", description: Text("Your accessible photos and videos will appear here."))
                }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(PearlStyle.canvas).navigationTitle("Your library").refreshable { await model.refresh() }
    }
    private func media(_ title: String, symbol: String, items: [MediaItem]) -> some View {
        NavigationLink {
            MediaGrid(title: title, items: items)
        } label: { MediaRow(title: title, subtitle: "\(items.count) items", symbol: symbol, previews: items) }
            .buttonStyle(.plain).accessibilityIdentifier("media\(title)")
    }
}

struct MonthView: View {
    let year: Int
    let items: [MediaItem]
    var body: some View {
        let months = Dictionary(grouping: items) { Calendar.current.component(.month, from: $0.date) }
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(months.keys.sorted(by: >), id: \.self) { month in
                    let entries = months[month] ?? []
                    let title = entries.first?.date.formatted(.dateTime.month(.wide)) ?? "Month"
                    NavigationLink { MediaGrid(title: title + " \(year)", items: entries) } label: {
                        MediaRow(title: title, subtitle: "\(entries.count) moments", symbol: "calendar", previews: entries)
                    }.buttonStyle(.plain)
                }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(PearlStyle.canvas).navigationTitle(String(year))
    }
}

struct MediaGrid: View {
    let title: String
    let items: [MediaItem]
    @Environment(PearlModel.self) private var model
    @State private var selected: Set<String> = []
    @State private var selecting = false
    @State private var preview: MediaItem?
    @State private var albumPicker = false
    @State private var oldest = false
    @State private var unreviewed = false
    @State private var mediaType = "All media"
    @State private var favoritesOnly = false
    private var visible: [MediaItem] {
        let accessible = Set(model.items.map(\.id))
        return items.filter { item in
            let typeMatches = switch mediaType {
            case "Photos": !item.isVideo
            case "Videos": item.isVideo
            case "Screenshots": item.isScreenshot
            case "Live Photos": item.isLive
            default: true
            }
            return accessible.contains(item.id) && (!unreviewed || !model.queue.reviewed.contains(item.id)) &&
                (!favoritesOnly || item.favorite) && typeMatches
        }
            .sorted { oldest ? $0.date < $1.date : $0.date > $1.date }
    }
    var body: some View {
        ScrollView {
            if visible.isEmpty {
                ContentUnavailableView("All clear here", systemImage: "leaf", description: Text("No items match this view."))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 4)], spacing: 4) {
                ForEach(visible) { item in
                    Button {
                        if selecting {
                            if !selected.insert(item.id).inserted { selected.remove(item.id) }
                        } else { preview = item }
                    } label: {
                        Thumbnail(id: item.id, modified: item.modified).aspectRatio(1, contentMode: .fit)
                            .overlay(alignment: .bottomTrailing) {
                                HStack(spacing: 4) {
                                    if item.favorite { Image(systemName: "heart.fill") }
                                    if item.isVideo { Image(systemName: "play.fill") }
                                    if selected.contains(item.id) { Image(systemName: "checkmark.circle.fill") }
                                    if model.queue.pending.contains(item.id) { Image(systemName: "tray.fill") }
                                }.font(.caption).padding(7).foregroundStyle(.white).shadow(radius: 2)
                            }.clipShape(RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).accessibilityIdentifier("mediaItem")
                        .accessibilityLabel("\(item.isVideo ? "Video" : "Photo"), \(item.date.formatted(date: .abbreviated, time: .omitted))\(selected.contains(item.id) ? ", selected" : "")")
                }
            }.padding(12)
        }.background(PearlStyle.canvas).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ReviewQueueToolbar()
            ToolbarItem(placement: .topBarTrailing) {
                Button(selecting ? "Done" : "Select") { selecting.toggle(); selected = [] }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Filter", systemImage: "line.3.horizontal.decrease") {
                    Toggle("Oldest first", isOn: $oldest)
                    Toggle("Not reviewed yet", isOn: $unreviewed)
                    Toggle("Favorites only", isOn: $favoritesOnly)
                    Picker("Media type", selection: $mediaType) {
                        ForEach(["All media", "Photos", "Videos", "Screenshots", "Live Photos"], id: \.self) { Text($0) }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if selecting && !selected.isEmpty {
                HStack {
                    Button("Add to album", systemImage: "rectangle.stack.badge.plus") { albumPicker = true }
                    Spacer()
                    Button("Stage \(selected.count)", systemImage: "tray") {
                        for item in items where selected.contains(item.id) { model.decide(item, remove: true) }
                        selected = []; selecting = false
                    }
                }.font(.subheadline).padding().background(.regularMaterial)
            }
        }
        .navigationDestination(item: $preview) { item in
            ReviewView(items: [item] + visible.filter { $0.id != item.id }, title: title)
        }
        .sheet(isPresented: $albumPicker) { AlbumPicker(ids: selected) }
    }
}
