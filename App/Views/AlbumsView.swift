import SwiftUI
import NativeSettingsKit
import PearlCore

struct AlbumsView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    @State private var creating = false
    @State private var title = ""
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("A place for the things you keep.").foregroundStyle(.secondary)
                NavigationLink { UnfiledPhotosView() } label: {
                    MediaRow(title: "Not in an album",
                             subtitle: model.authorization == .limited ? "Full photo access needed" : "\(model.unfiledItems.count) items to organize",
                             symbol: "tray", previews: Array(model.unfiledItems.prefix(3)))
                }.buttonStyle(.plain).accessibilityIdentifier("unfiledPhotos")
                Button("New album", systemImage: "plus") { creating = true }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                ForEach(model.orderedAlbums) { album in
                    NavigationLink { AlbumDetail(album: album) } label: {
                        MediaRow(title: album.title, subtitle: "\(album.count) items\(model.albumPreferences.favorites.contains(album.id) ? " · Favorite" : "")", symbol: "rectangle.stack",
                                 previews: model.items.filter { $0.id == album.cover })
                    }.buttonStyle(.plain)
                }
                if model.albums.isEmpty { ContentUnavailableView("Make room for a collection", systemImage: "rectangle.stack", description: Text("Create an album, then select items from any grid to add them.")) }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle("Albums")
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
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var creating = false
    @State private var title = ""
    @State private var failure: String?
    var body: some View {
        NavigationStack {
            List {
                Text(keepsReviewedItem ? "Add this item, keep it, and continue swiping. Your original stays in Photos." : "Add \(ids.count) items. They'll still appear in your main library.").foregroundStyle(.secondary)
                Button("New album", systemImage: "plus") { creating = true }.disabled(adding)
                    .accessibilityIdentifier("createAlbumWithSelection")
                ForEach(model.orderedAlbums.filter(\.canAdd)) { album in
                    Button {
                        save { try await model.addToAlbum(ids, album: album) }
                    } label: {
                        HStack {
                            Text(album.title)
                            if model.albumPreferences.favorites.contains(album.id) { Image(systemName: "star.fill").accessibilityLabel("Favorite album") }
                        }
                    }.disabled(adding)
                }
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
