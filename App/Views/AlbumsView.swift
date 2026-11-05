import SwiftUI
import PearlCore

struct AlbumsView: View {
    @Environment(PearlModel.self) private var model
    @State private var creating = false
    @State private var title = ""
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("A place for the things you keep.").foregroundStyle(.secondary)
                Button("New album", systemImage: "plus") { creating = true }.buttonStyle(.borderedProminent)
                ForEach(model.albums) { album in
                    NavigationLink { AlbumDetail(album: album) } label: {
                        MediaRow(title: album.title, subtitle: "\(album.count) items", symbol: "rectangle.stack",
                                 previews: model.items.filter { $0.id == album.cover })
                    }.buttonStyle(.plain)
                }
                if model.albums.isEmpty { ContentUnavailableView("Make room for a collection", systemImage: "rectangle.stack", description: Text("Create an album, then select items from any grid to add them.")) }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(PearlStyle.canvas).navigationTitle("Albums")
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
            .task { ids = await AlbumAccess.members(album.id) }
    }
}

struct AlbumPicker: View {
    let ids: Set<String>
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    var body: some View {
        NavigationStack {
            List {
                Text("Add \(ids.count) items. They'll still appear in your main library.").foregroundStyle(.secondary)
                ForEach(model.albums) { album in
                    Button(album.title) {
                        adding = true
                        Task { await model.addToAlbum(ids, album: album); dismiss() }
                    }.disabled(adding)
                }
                if model.albums.isEmpty { Text("Create an album in the Albums tab first.") }
            }.navigationTitle("Add to album").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() }.disabled(adding) } }
                .interactiveDismissDisabled(adding)
        }
    }
}
