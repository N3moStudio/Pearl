import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var limitedPicker = false
    var body: some View {
        NavigationStack {
            List {
                SettingsGroup("Your library") {
                    NavigationLink { photoAccess } label: {
                        SettingsRow("Photo access", symbol: "photo.on.rectangle", value: accessSummary)
                    }.accessibilityIdentifier("settingsPhotoAccess")
                    NavigationLink { scanning } label: {
                        SettingsRow("Scanning", symbol: "sparkles", value: "On device")
                    }.accessibilityIdentifier("settingsScanning")
                }
                SettingsGroup("Your data") {
                    NavigationLink { privacy } label: {
                        SettingsRow("Privacy", symbol: "hand.raised")
                    }
                    NavigationLink { cache } label: {
                        SettingsRow("Analysis cache", symbol: "internaldrive")
                    }.accessibilityIdentifier("settingsCache")
                }
                SettingsGroup("About") {
                    NavigationLink { about } label: {
                        SettingsRow("About Pearl", symbol: "info.circle", value: version)
                    }.accessibilityIdentifier("settingsAbout")
                    NavigationLink { noticesPage } label: {
                        SettingsRow("Open-source notices", symbol: "doc.text")
                    }
                }
            }
            .modifier(SettingsScreen())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("closeSettings")
                }
            }
        }
        .sheet(isPresented: $limitedPicker, onDismiss: { Task { await model.refresh() } }) { LimitedLibraryEditor() }
    }

    private var photoAccess: some View {
        List {
            SettingsGroup("Library access") {
                SettingsRow("Photos", symbol: "photo.on.rectangle", value: accessSummary)
                if model.authorization == .limited {
                    Button { limitedPicker = true } label: {
                        SettingsRow("Choose more photos", symbol: "plus.rectangle.on.rectangle")
                    }
                }
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    SettingsRow("Open iOS Settings", symbol: "gearshape")
                }
            }
        }.modifier(SettingsScreen()).navigationTitle("Photo access")
    }

    private var scanning: some View {
        @Bindable var model = model
        return List {
            Section {
                Toggle(isOn: $model.allowCloud) {
                    SettingsRow("iCloud downloads", symbol: "icloud.and.arrow.down")
                }
                .disabled(model.scanning)
                .accessibilityIdentifier("scanCloudDownloads")
            } footer: {
                Text(model.scanning ? "Available when the scan stops." : "For scans only. Off each launch; matching stays on your iPhone.")
            }.listRowBackground(PearlStyle.card)
            SettingsGroup("How it works") {
                SettingsHelp("Background scanning", symbol: "arrow.trianglehead.clockwise", lines: [
                    "On iOS 26 or later, a scan can continue outside Pearl with a system Live Activity when background processing is available.",
                    "iOS may pause work. Force-quitting stops the scan; Low Power Mode or excessive heat pauses it.",
                    "On earlier iOS versions, Pearl saves your place when you leave. Scanning continues while you switch tabs inside Pearl."
                ])
                SettingsHelp("Photo & video matching", symbol: "square.on.square", lines: [
                    "Exact matches compare single original resources. Live Photos, RAW pairs, and edited sets are excluded.",
                    "Similar photos use a conservative shortlist, so some matches may be missed.",
                    "Video suggestions compare five frames, not sound or every frame. You choose what to keep."
                ])
                SettingsHelp("iCloud downloads", symbol: "icloud", lines: [
                    "When enabled, Apple may download media for the scan. Analysis stays on your device.",
                    "This setting resets to off each time Pearl launches. Stop the current scan before changing it."
                ])
            }
        }.modifier(SettingsScreen()).navigationTitle("Scanning")
    }

    private var privacy: some View {
        List {
            SettingsGroup("On your iPhone") {
                SettingsRow("Local photo analysis", symbol: "iphone")
                SettingsRow("No photo uploads", symbol: "lock.shield")
                SettingsRow("No account or analytics", symbol: "person.crop.circle.badge.checkmark")
            }
            SettingsGroup("Your choices") {
                SettingsHelp("Review & removal", symbol: "checkmark.shield", lines: [
                    "Review choices stay on this iPhone. Nothing is selected for deletion automatically.",
                    "You review every removal, then confirm it with Photos. Clearing analysis data keeps your review queue and original photos."
                ])
            }
        }.modifier(SettingsScreen()).navigationTitle("Privacy")
    }

    private var cache: some View {
        List {
            Section {
                Button {
                    Task { await model.clearCache() }
                } label: {
                    SettingsRow(model.clearingCache ? "Clearing cache…" : "Clear analysis cache", symbol: "arrow.counterclockwise")
                }
                .disabled(model.scanning || model.clearingCache)
                .accessibilityIdentifier("clearAnalysisCache")
            } footer: {
                Text(model.scanning ? "Stop the scan to clear its cache. Photos and review choices stay." : "Photos and review choices stay. The next scan starts fresh.")
            }.listRowBackground(PearlStyle.card)
        }.modifier(SettingsScreen()).navigationTitle("Analysis cache")
    }

    private var about: some View {
        List {
            SettingsGroup("Pearl") {
                LabeledContent("Version", value: version)
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")
                LabeledContent("Made by", value: "N3mo Studio")
            }
        }.modifier(SettingsScreen()).navigationTitle("About Pearl")
    }

    private var noticesPage: some View {
        ScrollView {
            Text(notices).font(.footnote).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }.background(PearlStyle.canvas).navigationTitle("Notices").navigationBarTitleDisplayMode(.inline)
    }

    private var accessSummary: String {
        switch model.authorization {
        case .authorized: "All photos"
        case .limited: "Selected photos"
        case .denied: "Not allowed"
        case .restricted: "Restricted"
        case .notDetermined: "Not set"
        @unknown default: "Unavailable"
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var notices: String {
        guard let url = Bundle.main.url(forResource: "OpenSourceNotices", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "ThinkingOrbsKit · MIT · Jakub Antalik" }
        return text
    }
}

private struct SettingsScreen: ViewModifier {
    func body(content: Content) -> some View {
        content.listStyle(.insetGrouped).listSectionSpacing(20)
            .scrollContentBackground(.hidden).background(PearlStyle.canvas)
            .contentMargins(.top, 12, for: .scrollContent)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Section { content } header: {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).textCase(nil)
        }.listRowBackground(PearlStyle.card)
    }
}

private struct SettingsRow: View {
    let title: String
    let symbol: String
    var value: String?
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ title: String, symbol: String, value: String? = nil) {
        self.title = title; self.symbol = symbol; self.value = value
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.body).foregroundStyle(PearlStyle.sage)
                .frame(width: 32, height: 32)
                .background(PearlStyle.sage.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 8))
            layout {
                Text(title).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if let value { Text(value).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.frame(minHeight: 44).accessibilityElement(children: .combine)
    }
}

private struct SettingsHelp: View {
    let title: String
    let symbol: String
    let lines: [String]

    init(_ title: String, symbol: String, lines: [String]) {
        self.title = title; self.symbol = symbol; self.lines = lines
    }

    var body: some View {
        DisclosureGroup {
            ForEach(lines, id: \.self) { line in
                Text(line).font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
            }
        } label: { SettingsRow(title, symbol: symbol) }
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
