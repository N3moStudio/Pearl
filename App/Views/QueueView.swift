import SwiftUI

struct QueueView: View {
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirm = false
    var body: some View {
        List {
            Section {
                Text("Only these items will be removed. If you use iCloud Photos, removal also syncs to your other devices.")
                    .foregroundStyle(.secondary)
            }
            Section("\(model.pendingItems.count) selected") {
                ForEach(model.pendingItems) { item in
                    HStack(spacing: 14) {
                        Thumbnail(id: item.id, modified: item.modified).frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading) {
                            Text(item.isVideo ? "Video" : "Photo").font(.headline)
                            Text(item.date.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Keep") { model.unstage(item.id) }.buttonStyle(.bordered).disabled(model.deleting)
                    }
                }
            }
            Section {
                Button("Remove \(model.pendingItems.count) items", role: .destructive) { confirm = true }
                    .disabled(model.pendingItems.isEmpty || model.deleting).accessibilityIdentifier("confirmRemoval")
            } footer: { Text("Apple asks you to confirm. Removed items are recoverable in Photos → Recently Deleted for the period shown there.") }
        }.navigationTitle("Review removal").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.disabled(model.deleting) } }
            .interactiveDismissDisabled(model.deleting)
            .confirmationDialog("Remove these \(model.pendingItems.count) items from your photo library?", isPresented: $confirm, titleVisibility: .visible) {
                Button("Continue to Apple confirmation", role: .destructive) { Task { await model.removeConfirmed() } }
            } message: { Text("The items will also be removed from synced iCloud devices. Nothing else in your library is selected.") }
            .overlay { if model.deleting { ProgressView("Waiting for Photos…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20)) } }
    }
}
