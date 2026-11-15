import SwiftUI
import NativeSettingsKit
import PearlCore

struct MediaGrid: View {
    @Environment(\.nskPalette) private var colors
    let title: String
    let items: [MediaItem]
    var comparisonMode = false
    var showsMediaTabs = false
    var helper: String?
    @Environment(PearlModel.self) private var model
    @State private var selected: Set<String> = []
    @State private var selecting = false
    @State private var albumPicker = false
    @State private var comparison: ComparisonSelection?
    @State private var albumSaved = false
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
            if showsMediaTabs {
                Picker("Unfiled media", selection: $mediaType) {
                    Text("All").tag("All media")
                    Text("Photos").tag("Photos")
                    Text("Videos").tag("Videos")
                }.pickerStyle(.segmented).padding(.horizontal).padding(.top, 8).accessibilityIdentifier("unfiledMediaFilter")
            }
            if let helper { Text(helper).font(.footnote).foregroundStyle(.secondary).padding(.horizontal).padding(.top, 8) }
            if showsMediaTabs {
                Button("Swipe through \(visible.count) items", systemImage: "hand.draw") {
                    model.openReview(visible, title: mediaType == "All media" ? title : "Unfiled \(mediaType.lowercased())", startID: visible.first?.id)
                }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                    .disabled(visible.isEmpty).padding(.top, 8).accessibilityIdentifier("swipeUnfiledItems")
            }
            if albumSaved { Label("Added to your album", systemImage: "checkmark.circle").font(.subheadline).padding(.top, 8).accessibilityIdentifier("albumSaved") }
            if visible.isEmpty {
                ContentUnavailableView("All clear here", systemImage: "leaf", description: Text("No items match this view."))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 4)], spacing: 4) {
                ForEach(visible) { item in
                    Button {
                        if selecting || comparisonMode {
                            if selected.contains(item.id) { selected.remove(item.id) }
                            else if !comparisonMode || selected.count < 2 { selected.insert(item.id) }
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
                        .accessibilityLabel(mediaLabel(item))
                }
            }.padding(12)
        }.background(colors.canvas).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ReviewQueueToolbar()
            ToolbarItem(placement: .topBarTrailing) {
                if !comparisonMode { Button(selecting ? "Done" : "Select") { selecting.toggle(); selected = [] } }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Filter", systemImage: "line.3.horizontal.decrease") {
                    Toggle("Oldest first", isOn: $oldest)
                    Toggle("Not reviewed yet", isOn: $unreviewed)
                    Toggle("Favorites only", isOn: $favoritesOnly)
                    if !showsMediaTabs {
                        Picker("Media type", selection: $mediaType) {
                            ForEach(["All media", "Photos", "Videos", "Screenshots", "Live Photos"], id: \.self) { Text($0) }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if comparisonMode || (selecting && !selected.isEmpty) {
                VStack(spacing: 12) {
                    if comparisonMode { Text("Choose two photos · \(selected.count) of 2").font(.subheadline) }
                    if comparisonMode || (selected.count == 2 && selected.allSatisfy({ model.item($0)?.isVideo == false })) {
                        Button("Compare photos", systemImage: "rectangle.split.2x1") {
                            comparison = ComparisonSelection(ids: selected.sorted())
                        }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                            .disabled(selected.count != 2).accessibilityIdentifier("compareSelectedPhotos")
                    }
                    if !comparisonMode {
                        HStack {
                            Button("Add to album", systemImage: "rectangle.stack.badge.plus") { albumPicker = true }
                            Spacer()
                            Button("Stage \(selected.count)", systemImage: "tray") {
                                for item in items where selected.contains(item.id) { model.decide(item, remove: true) }
                                selected = []; selecting = false
                            }
                        }
                    }
                }.font(.subheadline).padding().frame(maxWidth: .infinity).nativeSettingsFloatingSurface()
            }
        }
        .sheet(isPresented: $albumPicker) {
            AlbumPicker(ids: selected) { selected = []; selecting = false; albumSaved = true }
        }
        .navigationDestination(item: $comparison) { DirectComparisonView(selection: $0) }
        .onChange(of: model.items) { _, current in selected.formIntersection(Set(current.map(\.id))) }
        .onChange(of: items) { _, current in selected.formIntersection(Set(current.map(\.id))) }
        .onChange(of: mediaType) { _, _ in selected = [] }
    }
    private func mediaLabel(_ item: MediaItem) -> String {
        var label = "\(item.isVideo ? "Video" : "Photo"), \(item.date.formatted(date: .abbreviated, time: .omitted))\(selected.contains(item.id) ? ", selected" : "")"
        #if DEBUG
        // Only the synthetic UI suite opts into fixture names; absent in IPA builds.
        if ProcessInfo.processInfo.arguments.contains("--ui-test-fixture-labels"),
           let name = PhotoAccess.fixtureName(item.id) { label += ", \(name)" }
        #endif
        return label
    }
}
