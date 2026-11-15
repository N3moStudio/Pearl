import SwiftUI
import NativeSettingsKit

@MainActor @Observable final class AlbumPreferences {
    static let orderKey = "pearl.albums.order"
    static let favoritesKey = "pearl.albums.favorites"
    private let defaults: UserDefaults
    private(set) var order: [String]
    private(set) var favorites: Set<String>
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var seen = Set<String>()
        order = (defaults.stringArray(forKey: Self.orderKey) ?? []).filter { seen.insert($0).inserted }
        favorites = Set(defaults.stringArray(forKey: Self.favoritesKey) ?? [])
    }
    func sorted(_ albums: [Album]) -> [Album] {
        let ranks = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
        return albums.sorted { a, b in
            if favorites.contains(a.id) != favorites.contains(b.id) { return favorites.contains(a.id) }
            let ar = ranks[a.id] ?? Int.max, br = ranks[b.id] ?? Int.max
            if ar != br { return ar < br }
            let comparison = a.title.localizedStandardCompare(b.title)
            return comparison == .orderedSame ? a.id < b.id : comparison == .orderedAscending
        }
    }
    func toggleFavorite(_ id: String) {
        if !favorites.insert(id).inserted { favorites.remove(id) }
        defaults.set(favorites.sorted(), forKey: Self.favoritesKey)
    }
    func move(_ group: [Album], in albums: [Album], from source: IndexSet, to destination: Int) {
        var moved = group.map(\.id)
        moved.move(fromOffsets: source, toOffset: destination)
        let groupIDs = Set(moved)
        var iterator = moved.makeIterator()
        let visible = sorted(albums).map { groupIDs.contains($0.id) ? iterator.next()! : $0.id }
        let visibleIDs = Set(visible)
        // Retain temporarily inaccessible album choices, including limited access.
        order = visible + order.filter { !visibleIDs.contains($0) }
        defaults.set(order, forKey: Self.orderKey)
    }
}

struct AlbumOrderView: View {
    var writableOnly = false
    @Environment(PearlModel.self) private var model
    @Environment(\.nskPalette) private var colors
    var body: some View {
        NSKList {
            albumSection("Favorites", favorites: true)
            albumSection("Other albums", favorites: false)
        }.environment(\.editMode, .constant(.active))
            .navigationTitle("Album order").navigationBarTitleDisplayMode(.inline)
    }
    @ViewBuilder private func albumSection(_ title: String, favorites: Bool) -> some View {
        let albums = model.orderedAlbums.filter { (!writableOnly || $0.canAdd) && model.albumPreferences.favorites.contains($0.id) == favorites }
        if !albums.isEmpty || !favorites {
            Section {
                ForEach(albums) { album in
                    HStack(spacing: 8) {
                        Button { model.albumPreferences.toggleFavorite(album.id) } label: {
                            Image(systemName: favorites ? "star.fill" : "star").frame(minWidth: 44, minHeight: 44)
                        }.buttonStyle(.borderless)
                            .accessibilityLabel("\(favorites ? "Unfavorite" : "Favorite") album \(album.title)")
                            .accessibilityIdentifier("favoriteAlbum")
                        Text(album.title).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }.onMove { model.albumPreferences.move(albums, in: model.albums, from: $0, to: $1) }
            } header: {
                Text(title).textCase(nil)
            } footer: {
                if !favorites {
                    Text("Star favorites. Drag the handles to reorder each group. This order is used throughout Pearl.")
                        .font(.footnote).foregroundStyle(colors.muted)
                }
            }
            .listRowBackground(colors.surface)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 16))
        }
    }
}
