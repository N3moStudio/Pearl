import SwiftUI
import PearlCore

struct MediaGrid: View {
    let title: String
    let items: [MediaItem]
    @Environment(PearlModel.self) private var model
    @State private var selected: Set<String> = []
    @State private var selecting = false
    @State private var albumPicker = false
    @State private var oldest = false
    @State private var unreviewed = false
    @State private var mediaType = "All media"
    @State private var favoritesOnly = false
    private var visible: [MediaItem] {
        return items.compactMap { model.item($0.id) }.filter { item in
            let typeMatches = switch mediaType {
            case "Photos": !item.isVideo
            case "Videos": item.isVideo
            case "Screenshots": item.isScreenshot
            case "Live Photos": item.isLive
            default: true
            }
            return (!unreviewed || !model.queue.reviewed.contains(item.id)) &&
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
                        } else { model.openReview(visible, title: title, startID: item.id) }
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
        .sheet(isPresented: $albumPicker) { AlbumPicker(ids: selected) }
    }
}
