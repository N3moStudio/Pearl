import SwiftUI

@main
struct PearlApp: App {
    @State private var model = PearlModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().environment(model).tint(PearlStyle.sage)
                .task { await model.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { model.stopScan() }
                    else if model.ready { Task { await model.refresh() } }
                }
        }
    }
}

struct RootView: View {
    @Environment(PearlModel.self) private var model
    @State private var settings = false
    var body: some View {
        @Bindable var model = model
        Group {
            if model.canRead {
                TabView {
                    Tab("Library", systemImage: "photo.on.rectangle") { destination { LibraryView() } }
                    Tab("Clean Up", systemImage: "sparkles") { destination { CleanupView() } }
                    Tab("Albums", systemImage: "rectangle.stack") { destination { AlbumsView() } }
                }
            } else { WelcomeView() }
        }
        .sheet(isPresented: $settings) { SettingsView() }
        .sheet(isPresented: $model.showQueue) { NavigationStack { QueueView() } }
        .alert("Pearl", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .alert("Pearl", isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button("OK") { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }
    private func destination<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationStack {
            content().toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "slider.horizontal.3") { settings = true }
                }
                ReviewQueueToolbar()
            }
        }
    }
}

struct WelcomeView: View {
    @Environment(PearlModel.self) private var model
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 50)
                Image(systemName: "circle.hexagongrid.fill").font(.system(size: 60)).foregroundStyle(PearlStyle.sage).accessibilityHidden(true)
                Text("A little space.\nA lighter library.").font(.largeTitle.bold())
                Text("Meet Pearl.").font(.title2.weight(.semibold))
                Text("Find similar moments, revisit old photos, and keep what matters. At your pace.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 20) {
                    Label("Photo and video matching stays on your device", systemImage: "iphone")
                    Label("No account. No ads. No subscriptions.", systemImage: "leaf")
                    Label("You review every removal", systemImage: "checkmark.shield")
                }.font(.callout)
                if model.authorization == .denied || model.authorization == .restricted {
                    Button("Open Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                        .buttonStyle(.borderedProminent)
                    Text("Allow Photos access in Settings to get started.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    Button("Choose photo access") { Task { await model.requestAccess() } }
                        .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("chooseAccess")
                    Text("Choose a few photos or your whole library. You can change this anytime.").font(.footnote).foregroundStyle(.secondary)
                }
            }.padding(28).frame(maxWidth: 550, alignment: .leading).frame(maxWidth: .infinity)
        }.background(PearlStyle.canvas)
    }
}
