import SwiftUI
import NativeSettingsKit
import PearlCore

struct CleanupView: View {
    @Environment(\.nskPalette) private var colors
    @Environment(PearlModel.self) private var model
    private func groups(_ kind: MatchGroup.Kind) -> [MatchGroup] {
        model.scan.groups.filter { $0.kind == kind && !$0.members.allSatisfy(model.queue.reviewed.contains) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 15) {
                    if model.scanning { OrbStatus(title: model.stoppingScan ? "Saving your place…" : model.scan.detail) }
                    else { Label(model.scanMessage, systemImage: "leaf").foregroundStyle(.secondary) }
                    if model.authorization == .limited {
                        Label("Checking selected photos only", systemImage: "photo.badge.checkmark")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if model.scan.total > 0 {
                        ProgressView(value: model.scan.fraction)
                        Text(model.scan.detail).accessibilityIdentifier("scanProgress")
                            .font(.footnote).foregroundStyle(.secondary)
                        if model.scan.reused > 0 {
                            Text("Reused \(model.scan.reused.formatted()) · Checked \(max(0, model.scan.checked - model.scan.reused).formatted()) this scan")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if model.scan.unavailable > 0 {
                        Text("\(model.scan.unavailable) items couldn't be analyzed. Some may need an iCloud download.").font(.footnote).foregroundStyle(.secondary)
                    }
                    if model.scan.verificationUnavailable > 0 {
                        Text("\(model.scan.verificationUnavailable) originals couldn't be verified. Try again with iCloud downloads enabled in Scanning settings.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Button(model.scanning ? "Pause scan" : (model.scan.checked > 0 && model.scan.phase != .complete ? "Resume scan" : "Find similar moments"),
                           systemImage: model.scanning ? "pause" : "sparkles") {
                        if model.scanning { model.stopScan() } else { model.beginScan() }
                    }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent).controlSize(.large).disabled(model.items.isEmpty || model.clearingCache || model.stoppingScan)
                        .accessibilityIdentifier("scanButton")
                    if model.scanning { Text(model.backgroundStatus).font(.footnote).foregroundStyle(.secondary) }
                }.pearlCard()
                groupRow("Exact duplicates", subtitle: "Matching original files", kind: .exact, symbol: "square.on.square")
                groupRow("Similar photos", subtitle: "Same moment. A few versions.", kind: .photo, symbol: "photo.stack")
                groupRow("Possible similar videos", subtitle: "Five frames compared. Review the sound too.", kind: .video, symbol: "play.rectangle.on.rectangle")
                NavigationLink { MediaGrid(title: "Screenshots", items: model.items.filter(\.isScreenshot)) } label: {
                    MediaRow(title: "Screenshots", subtitle: "Revisit older captures", symbol: "viewfinder", previews: model.items.filter(\.isScreenshot))
                }.buttonStyle(.plain)
                NavigationLink { MediaGrid(title: "Long videos", items: model.items.filter { $0.isVideo && $0.duration >= 60 }) } label: {
                    MediaRow(title: "Long videos", subtitle: "One minute or more", symbol: "film")
                }.buttonStyle(.plain)
                Text("Matching stays on your device. Live Photos are compared as stills. Exact matches require verified original files; Live Photos and edited sets aren't labeled exact.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("You choose what stays.").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical)
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle("Clean Up")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Scan options", systemImage: "ellipsis.circle") {
                    Button("Recheck all matches", systemImage: "arrow.clockwise") { model.beginScan(recheck: true) }
                        .disabled(model.scanning || model.clearingCache || model.items.isEmpty)
                }.accessibilityIdentifier("scanOptions")
            }
        }
    }
    private func groupRow(_ title: String, subtitle: String, kind: MatchGroup.Kind, symbol: String) -> some View {
        let matches = groups(kind)
        let ids = Set(matches.first?.members ?? [])
        return NavigationLink { GroupList(title: title, kind: kind) } label: {
            MediaRow(title: title, subtitle: "\(matches.count) groups · \(subtitle)", symbol: symbol, previews: model.items.filter { ids.contains($0.id) })
        }.buttonStyle(.plain).accessibilityIdentifier("matches\(kind.rawValue)")
    }
}

struct GroupList: View {
    @Environment(\.nskPalette) private var colors
    let title: String
    let kind: MatchGroup.Kind
    @Environment(PearlModel.self) private var model
    private var groups: [MatchGroup] { model.scan.groups.filter { $0.kind == kind && !$0.members.allSatisfy(model.queue.reviewed.contains) } }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if groups.isEmpty {
                    ContentUnavailableView(model.scanning ? "Still looking" : "No groups to review", systemImage: "sparkles",
                                           description: Text("Run a scan to look for matches. Results are suggestions, and some matches may be missed."))
                }
                ForEach(groups) { group in
                    NavigationLink { GroupDetail(group: group) } label: {
                        let items = model.items.filter { group.members.contains($0.id) }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                ForEach(Array(items.prefix(3))) { item in
                                    Thumbnail(id: item.id, modified: item.modified).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            Text("\(items.count) \(kind == .video ? "videos" : "items") to compare").font(.headline)
                        }.pearlCard()
                    }.buttonStyle(.plain).accessibilityIdentifier("matchGroup")
                }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

struct GroupDetail: View {
    @Environment(\.nskPalette) private var colors
    let group: MatchGroup
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []
    @State private var viewing: MediaItem?
    private var items: [MediaItem] { model.items.filter { group.members.contains($0.id) }.sorted { $0.width * $0.height > $1.width * $1.height } }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text(group.kind == .video ? "Watch each version. Sound and edits can differ." : "Same moment. You decide which stays.")
                    .foregroundStyle(.secondary)
                if let first = items.first, group.kind != .video {
                    Label("Largest resolution: \(first.width) × \(first.height)", systemImage: "sparkles").font(.subheadline).foregroundStyle(colors.accent)
                }
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        Button { viewing = item } label: {
                            Thumbnail(id: item.id, size: 700, modified: item.modified, fit: true)
                                .frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(Image(systemName: item.isVideo ? "play.circle.fill" : "plus.magnifyingglass").font(.largeTitle).foregroundStyle(.white).shadow(radius: 3))
                        }.buttonStyle(.plain).accessibilityLabel(item.isVideo ? "Play this video" : "Inspect this photo")
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline)
                                Text("\(item.width) × \(item.height)\(item.isVideo ? " · \(Int(item.duration)) sec" : "")").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(selected.contains(item.id) ? "Selected" : "Select", systemImage: selected.contains(item.id) ? "checkmark.circle.fill" : "circle") {
                                if !selected.insert(item.id).inserted { selected.remove(item.id) }
                            }.buttonStyle(.bordered).disabled(item.favorite || model.queue.protected.contains(item.id))
                        }
                        if item.favorite || model.queue.protected.contains(item.id) { Label("Protected", systemImage: "lock").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                Text(selected.isEmpty ? "Nothing is selected for removal." : "\(selected.count) selected. \(selected.count == items.count ? "Consider keeping at least one version." : "Nothing is deleted yet.")")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 650).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle("Compare").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Keep all") { for item in items { model.decide(item, remove: false) }; dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Review selection") {
                    for item in items where selected.contains(item.id) { model.decide(item, remove: true) }
                    selected = []; model.showQueue = true
                }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent).disabled(selected.isEmpty)
            }.padding().nativeSettingsFloatingSurface()
        }.sheet(item: $viewing) { MediaViewer(item: $0) }
    }
}
