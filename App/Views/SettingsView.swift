import SwiftUI
import NativeSettingsKit
import PhotosUI

struct SettingsView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    @Environment(PearlAppearance.self) private var appearance
    @Environment(\.dismiss) private var dismiss
    @State private var limitedPicker = false
    var body: some View {
        NavigationStack {
            NSKList {
                SettingsGroup {
                    NavigationLink { AppearanceView() } label: {
                        NSKIdentityLabel(title: "Make Pearl yours.", subtitle: "\(appearance.theme.title) \u{00B7} \(appearance.surface.title)") {
                            Image("PearlMark").resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }.accessibilityIdentifier("settingsAppearance")
                }
                SettingsGroup("Your library") {
                    NavigationLink { HomeOrderView() } label: { SettingsRow("Home order", symbol: "arrow.up.arrow.down") }.accessibilityIdentifier("settingsHomeOrder")
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
            .navigationBarTitleDisplayMode(.inline)
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
        NSKList {
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
        }.navigationBarTitleDisplayMode(.inline).navigationTitle("Photo access")
    }

    private var scanning: some View {
        @Bindable var model = model
        return NSKList {
            Section {
                Toggle(isOn: $model.allowCloud) {
                    HStack(spacing: 12) {
                        SettingsIcon(symbol: "icloud.and.arrow.down")
                        Text("iCloud downloads").fixedSize(horizontal: false, vertical: true)
                    }.frame(minHeight: 44)
                }
                .disabled(model.scanning)
                .accessibilityIdentifier("scanCloudDownloads")
            } footer: {
                Text(model.scanning ? "Available when the scan stops." : "For scans only. Off each launch; matching stays on your iPhone.")
            }.listRowBackground(colors.surface)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            SettingsGroup {
                NavigationLink { scanningHelp } label: {
                    SettingsRow("How scanning works", symbol: "info.circle")
                }.accessibilityIdentifier("scanningHelp")
            }
        }.navigationBarTitleDisplayMode(.inline).navigationTitle("Scanning")
    }

    private var scanningHelp: some View {
        NSKList {
                SettingsGroup("Background scanning") {
                    ForEach([
                    "On iOS 26 or later, a scan can continue outside Pearl with a system Live Activity when background processing is available.",
                    "iOS may pause work. Force-quitting stops the scan; Low Power Mode or excessive heat pauses it.",
                    "On earlier iOS versions, Pearl saves your place when you leave. Scanning continues while you switch tabs inside Pearl."
                    ], id: \.self) { Text($0).font(.footnote).foregroundStyle(colors.muted).fixedSize(horizontal: false, vertical: true) }
                }
                SettingsGroup("Photo & video matching") {
                    ForEach([
                    "Exact matches compare single original resources. Live Photos, RAW pairs, and edited sets are excluded.",
                    "Similar photos include Live Photo stills. Results use a conservative shortlist, so some matches may be missed. Recheck all matches from Clean Up to compare again without clearing your cache.",
                    "Video suggestions compare five frames, not sound or every frame. You choose what to keep."
                    ], id: \.self) { Text($0).font(.footnote).foregroundStyle(colors.muted).fixedSize(horizontal: false, vertical: true) }
                }
                SettingsGroup("iCloud downloads") {
                    ForEach([
                    "When enabled, Apple may download media for the scan. Analysis stays on your device.",
                    "This setting resets to off each time Pearl launches. Stop the current scan before changing it."
                    ], id: \.self) { Text($0).font(.footnote).foregroundStyle(colors.muted).fixedSize(horizontal: false, vertical: true) }
                }
        }.navigationTitle("How scanning works").navigationBarTitleDisplayMode(.inline)
    }

    private var privacy: some View {
        NSKList {
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
        }.navigationBarTitleDisplayMode(.inline).navigationTitle("Privacy")
    }

    private var cache: some View {
        NSKList {
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
            }.listRowBackground(colors.surface)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }.navigationBarTitleDisplayMode(.inline).navigationTitle("Analysis cache")
    }

    private var about: some View {
        NSKList {
            SettingsGroup("Pearl") {
                LabeledContent("Version", value: version)
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")
                LabeledContent("Made by", value: "N3mo Studio")
            }
        }.navigationBarTitleDisplayMode(.inline).navigationTitle("About Pearl")
    }

    private var noticesPage: some View {
        ScrollView {
            Text(notices).font(.footnote).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }.background(colors.canvas).navigationTitle("Notices").navigationBarTitleDisplayMode(.inline)
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

private typealias SettingsGroup<Content: View> = NSKSection<Content>
private typealias SettingsRow = NSKRow

private struct SettingsIcon: View {
    @Environment(\.nskPalette) private var colors
    let symbol: String
    var body: some View {
        // Decorative badges stay contained while the adjacent text scales.
        Image(systemName: symbol).resizable().scaledToFit().frame(width: 18, height: 18)
            .foregroundStyle(colors.accent).frame(width: 32, height: 32)

            .accessibilityHidden(true)
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
