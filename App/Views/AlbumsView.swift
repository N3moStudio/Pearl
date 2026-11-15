import SwiftUI
import NativeSettingsKit
import PearlCore

struct AlbumsView: View {
    @Environment(PearlModel.self) private var model
    @State private var creating = false
    @State private var title = ""
    var body: some View {
        NSKList {
            NSKSection {
                NavigationLink { UnfiledPhotosView() } label: {
                    NSKRow("Not in an album", symbol: "tray", detail:
                        model.authorization == .limited ? "Full photo access needed" : "\(model.unfiledItems.count) items to organize")
                }.accessibilityIdentifier("unfiledPhotos")
                Button { creating = true } label: {
                    NSKRow("New album", symbol: "plus")
                }
            }.font(.subheadline)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            albumSection("Favorites", favorites: true)
            albumSection(model.albumPreferences.favorites.isEmpty ? "Albums" : "Other albums", favorites: false)
            if model.albums.isEmpty {
                ContentUnavailableView("Make room for a collection", systemImage: "rectangle.stack", description: Text("Create an album, then select items from any grid to add them."))
                    .listRowBackground(Color.clear)
            }
        }.navigationTitle("Albums").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { AlbumOrderView() } label: { Label("Album order", systemImage: "arrow.up.arrow.down") }
                        .accessibilityIdentifier("albumOrder")
                }
            }
            .alert("New album", isPresented: $creating) {
                TextField("Album name", text: $title)
                Button("Create") { let name = title; title = ""; Task { await model.createAlbum(name) } }
                Button("Cancel", role: .cancel) { title = "" }
            }
    }
    @ViewBuilder private func albumSection(_ title: String, favorites: Bool) -> some View {
        let albums = model.orderedAlbums.filter { model.albumPreferences.favorites.contains($0.id) == favorites }
        if !albums.isEmpty {
            NSKSection(title) {
                ForEach(albums) { album in
                    NavigationLink { AlbumDetail(album: album) } label: {
                        AlbumListRow(album: album, favorite: favorites)
                    }
                }
            }.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
    }
}

/// Shared album density in browsing and destination selection. The native row
/// owns its interaction and separator; the label does not add another card.
private struct AlbumListRow: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    let album: Album
    let favorite: Bool
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let cover = album.cover { Thumbnail(id: cover, size: 160, modified: model.item(cover)?.modified ?? .distantPast) }
                else { Image(systemName: "rectangle.stack").foregroundStyle(colors.accent).frame(maxWidth: .infinity, maxHeight: .infinity).background(colors.canvas) }
            }.frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(album.title).font(.subheadline.weight(.medium)).foregroundStyle(colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(album.count) items").font(.caption).foregroundStyle(colors.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if favorite {
                Image(systemName: "star.fill").font(.caption).foregroundStyle(colors.accent)
                    .accessibilityHidden(true)
            }
        }.frame(minHeight: 44).contentShape(Rectangle())
    }
}

struct AlbumDetail: View {
    let album: Album
    @Environment(PearlModel.self) private var model
    @State private var ids: Set<String> = []
    var body: some View {
        MediaGrid(title: album.title, items: model.items.filter { ids.contains($0.id) })
            .task(id: model.albumRevision) { ids = await AlbumAccess.members(album.id) }
    }
}

struct UnfiledPhotosView: View {
    @Environment(PearlModel.self) private var model
    var body: some View {
        Group {
            if model.authorization == .limited {
                ContentUnavailableView {
                    Label("See which items need an album", systemImage: "rectangle.stack")
                } description: {
                    Text("Limited photo access hides album membership. Allow full access in iOS Settings so Pearl can check this accurately.")
                } actions: {
                    Button("Photo access settings") { model.showSettings = true }
                }.navigationTitle("Not in an album").navigationBarTitleDisplayMode(.inline)
            } else {
                MediaGrid(title: "Not in an album", items: model.unfiledItems, showsMediaTabs: true,
                          helper: "Outside your personal albums. Automatic categories and Shared Albums don't count. Tap to review, or select items to file them.")
            }
        }
    }
}

struct AlbumPicker: View {
    let ids: Set<String>
    var keepsReviewedItem = false
    var onAdded: () -> Void = {}
    @Environment(PearlModel.self) private var model
    @Environment(\.nskPalette) private var colors
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var creating = false
    @State private var title = ""
    @State private var failure: String?
    var body: some View {
        NavigationStack {
            NSKList {
                Section {
                    Button { creating = true } label: {
                        NSKRow("New album", symbol: "plus")
                    }.disabled(adding).accessibilityIdentifier("createAlbumWithSelection")
                    NavigationLink { AlbumOrderView(writableOnly: true) } label: {
                        NSKRow("Organize albums", symbol: "arrow.up.arrow.down")
                    }.disabled(adding).accessibilityIdentifier("organizePickerAlbums")
                } footer: {
                    Text(keepsReviewedItem ? "Adding keeps this item and continues swiping." : "Add \(ids.count) items. Originals stay in your library.")
                        .font(.footnote).foregroundStyle(colors.muted)
                }
                .font(.subheadline).listRowBackground(colors.surface)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                albumSection("Favorites", favorites: true)
                albumSection("Albums", favorites: false)
                if adding { ProgressView("Saving to Photos…") }
                if let failure { Text(failure).foregroundStyle(.red).accessibilityIdentifier("albumSaveError") }
            }.navigationTitle("Add to album").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() }.disabled(adding) } }
                .interactiveDismissDisabled(adding)
                .alert("New album", isPresented: $creating) {
                    TextField("Album name", text: $title)
                    Button("Create and add") {
                        let name = title
                        save { try await model.createAlbum(name, adding: ids) }
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Cancel", role: .cancel) { title = "" }
                } message: { Text("Create an album with your \(ids.count) selected items.") }
        }
    }
    @ViewBuilder private func albumSection(_ title: String, favorites: Bool) -> some View {
        let albums = model.orderedAlbums.filter { $0.canAdd && model.albumPreferences.favorites.contains($0.id) == favorites }
        if !albums.isEmpty {
            NSKSection(title) {
                ForEach(albums) { album in
                    Button { save { try await model.addToAlbum(ids, album: album) } } label: {
                        AlbumListRow(album: album, favorite: favorites)
                    }.disabled(adding).accessibilityLabel(album.title)
                        .accessibilityValue("\(album.count) items\(favorites ? ", Favorite" : "")")
                        .accessibilityIdentifier("albumDestination")
                }
            }.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
    }
    private func save(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !adding, !ids.isEmpty else { return }
        adding = true; failure = nil
        Task {
            do { try await operation(); onAdded(); dismiss() }
            catch { failure = "Couldn't save to the album. \(error.localizedDescription)" }
            adding = false
        }
    }
}
