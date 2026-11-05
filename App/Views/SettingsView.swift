import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var limitedPicker = false
    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Photo access") {
                    Text(model.authorization == .limited ? "Selected photos" : "Full library access")
                    if model.authorization == .limited {
                        Button("Choose more photos") { limitedPicker = true }
                    }
                    Button("Open iOS Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                }
                Section {
                    Toggle("Allow iCloud downloads for scans", isOn: $model.allowCloud).disabled(model.scanning)
                } header: { Text("On-device matching") } footer: {
                    Text("Off by default each launch. When enabled, Apple may download originals using your connection. Analysis stays on this device. Keep Pearl open to scan; it pauses in the background, Low Power Mode, or excessive heat.")
                }
                Section("Your data") {
                    Label("No account, analytics, or photo uploads", systemImage: "lock.shield")
                    Button("Clear analysis cache") { Task { await model.clearCache() } }.disabled(model.scanning)
                    Text("Review choices stay on this iPhone. Clearing the cache keeps your review queue and original photos.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("About Pearl") {
                    Text("Pearl 0.1.0 · N3mo Studio")
                    Text("Exact matches compare single original resources. Live Photos, RAW pairs, and edited sets are excluded. Similarity uses a conservative shortlist, so it can miss matches. Video suggestions compare five frames, not sound or every frame.").font(.footnote).foregroundStyle(.secondary)
                    NavigationLink("Open-source notices") {
                        ScrollView { Text((try? String(contentsOf: Bundle.main.url(forResource: "OpenSourceNotices", withExtension: "txt")!, encoding: .utf8)) ?? "ThinkingOrbsKit · MIT")
                            .font(.footnote).padding() }.navigationTitle("Notices")
                    }
                }
            }.navigationTitle("Settings").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
                .sheet(isPresented: $limitedPicker, onDismiss: { Task { await model.refresh() } }) { LimitedLibraryEditor() }
        }
    }
}

struct LimitedLibraryEditor: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> PickerHost {
        let host = PickerHost(); host.done = { dismiss() }; return host
    }
    func updateUIViewController(_ uiViewController: PickerHost, context: Context) {}
    final class PickerHost: UIViewController {
        var done: (() -> Void)?
        private var shown = false
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !shown else { return }; shown = true
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self) { [weak self] _ in
                Task { @MainActor in self?.done?() }
            }
        }
    }
}
