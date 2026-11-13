import SwiftUI
import NativeSettingsKit

@main
struct PearlApp: App {
    @State private var model = PearlModel()
    @State private var appearance = PearlAppearance()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().modifier(PearlAppearanceRoot()).environment(model).environment(appearance)
                .preferredColorScheme(testAppearance ?? appearance.theme.kit?.preferredColorScheme)
                .task { await model.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { model.enteredBackground() }
                    else if phase == .active, model.ready { Task { await model.refresh() } }
                }
        }
    }
    private var testAppearance: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-dark") { return .dark }
        #endif
        return nil
    }
}

struct RootView: View {
    @Environment(PearlModel.self) private var model
    @Environment(PearlAppearance.self) private var appearance

    var body: some View {
        @Bindable var model = model
        Group {
            if model.canRead {
                destination { LibraryView() }
            } else { WelcomeView() }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView().modifier(PearlAppearanceRoot())
                .preferredColorScheme(appearance.theme.kit?.preferredColorScheme)
        }
        .sheet(isPresented: $model.showQueue) {
            NavigationStack { QueueView() }.modifier(PearlAppearanceRoot())
                .preferredColorScheme(appearance.theme.kit?.preferredColorScheme)
        }
        .fullScreenCover(item: $model.reviewSession) { session in
            ReviewView(session: session).interactiveDismissDisabled()
        }
        .alert("Pearl", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .alert("Pearl", isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button("OK") { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }
    private func destination<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationStack {
            content().modifier(PearlNavigationSurface()).toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "slider.horizontal.3") { model.showSettings = true }
                }
                ReviewQueueToolbar()
            }
        }
    }
}

struct WelcomeView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 50)
                Image(systemName: "circle.hexagongrid.fill").font(.system(size: 60)).foregroundStyle(colors.accent).accessibilityHidden(true)
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
                        .buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                    Text("Allow Photos access in Settings to get started.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    Button("Choose photo access") { Task { await model.requestAccess() } }
                        .buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent).controlSize(.large).accessibilityIdentifier("chooseAccess")
                    Text("Choose a few photos or your whole library. You can change this anytime.").font(.footnote).foregroundStyle(.secondary)
                }
            }.padding(28).frame(maxWidth: 550, alignment: .leading).frame(maxWidth: .infinity)
        }.background(colors.canvas)
    }
}
