import SwiftUI
import NativeSettingsKit
import PearlCore

struct ComparisonSelection: Hashable {
    let ids: [String]
}

struct DirectComparisonView: View {
    let selection: ComparisonSelection
    @Environment(PearlModel.self) private var model
    @Environment(\.nskPalette) private var colors
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var result: PhotoComparisonResult?
    @State private var running = false
    @State private var stopped = false
    @State private var network = false
    @State private var attempt = 0
    @State private var message: String?
    @State private var removals: Set<String> = []
    @State private var viewing: MediaItem?
    private var items: [MediaItem] { selection.ids.compactMap(model.item) }
    private var eligible: Set<String> {
        Set(items.filter { !$0.favorite && !model.queue.protected.contains($0.id) && !model.favoriting.contains($0.id) }.map(\.id))
    }
    private struct Work: Hashable {
        let items: [MediaItem]
        let network: Bool
        let attempt: Int
        let stopped: Bool
    }
    private var work: Work { Work(items: items, network: network, attempt: attempt, stopped: stopped) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if items.count != 2 {
                    ContentUnavailableView("Photo no longer available", systemImage: "photo",
                        description: Text("Its access may have changed. Go back and choose two available photos."))
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 14) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                Button { viewing = item } label: {
                                    Thumbnail(id: item.id, size: 1000, modified: item.modified, fit: true)
                                        .frame(height: 230).clipShape(RoundedRectangle(cornerRadius: 18))
                                }.buttonStyle(.plain).accessibilityLabel("Inspect photo. Opens zoomable preview.")
                                Text(item.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                                Text("\(item.width) × \(item.height)\(item.isLive ? " · Live Photo" : "")").font(.caption).foregroundStyle(.secondary)
                                if !eligible.contains(item.id) {
                                    Label("Protected", systemImage: "lock").font(.subheadline)
                                }
                                Button {
                                    if !removals.insert(item.id).inserted { removals.remove(item.id) }
                                } label: {
                                    Label(removals.contains(item.id) ? "Selected" : "Select for removal",
                                          systemImage: removals.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.subheadline).frame(minHeight: 44)
                                }.disabled(!eligible.contains(item.id) || model.deleting)
                                    .accessibilityIdentifier("compareRemoval")
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        if running {
                            OrbStatus(title: network ? "Loading and comparing…" : "Comparing on your iPhone…")
                            Button("Stop comparison") { stopped = true }.accessibilityIdentifier("stopComparison")
                        } else if let result {
                            Text(title(result.verdict)).font(.title3.weight(.semibold)).accessibilityIdentifier("comparisonResult")
                            Text(explanation(result.verdict)).font(.subheadline)
                            Text(result.originalStatus).font(.footnote).foregroundStyle(.secondary)
                        } else if let message {
                            Text(message).font(.subheadline).accessibilityIdentifier("comparisonMessage")
                        }
                        if !running {
                            Button("Compare again", systemImage: "arrow.clockwise") { stopped = false; attempt += 1 }
                                .accessibilityIdentifier("retryComparison")
                            if !network, result?.needsDownload == true || result?.verdict == .unavailable {
                                Button("Download from iCloud and compare", systemImage: "icloud.and.arrow.down") {
                                    network = true; stopped = false; attempt += 1
                                }
                                Text("Apple may download these two photos. Analysis stays on your iPhone.").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }.pearlCard()
                    Text("This checks your chosen pair directly, even if the scan didn't group it. Visual matches are suggestions; inspect both photos before choosing.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.padding(20).frame(maxWidth: 750).frame(maxWidth: .infinity)
        }.background(colors.canvas).navigationTitle("Compare photos").navigationBarTitleDisplayMode(.inline)
            .toolbar { ReviewQueueToolbar() }
            .safeAreaInset(edge: .bottom) {
                if items.count == 2 {
                    Button("Review \(removals.intersection(eligible).count) selected") {
                        for item in items where removals.intersection(eligible).contains(item.id) { model.decide(item, remove: true) }
                        removals = []; model.showQueue = true
                    }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                        .disabled(removals.intersection(eligible).isEmpty || model.deleting)
                        .accessibilityIdentifier("reviewComparisonSelection")
                        .padding().frame(maxWidth: .infinity).nativeSettingsFloatingSurface()
                }
            }
            .sheet(item: $viewing) { MediaViewer(item: $0) }
            .onChange(of: eligible) { _, valid in removals.formIntersection(valid) }
            .onChange(of: scenePhase) { _, phase in if phase == .background { stopped = true } }
            .task(id: work) {
                result = nil; message = nil
                guard items.count == 2 else { running = false; return }
                guard !stopped else { running = false; message = "Comparison stopped. Your photos haven't changed."; return }
                running = true
                do {
                    let value = try await DirectComparison.compare(items, network: network)
                    guard !Task.isCancelled else { return }
                    result = value; running = false
                } catch is CancellationError {
                    // The replacement task or disappearance owns the next UI state.
                } catch {
                    guard !Task.isCancelled else { return }
                    message = "Couldn't finish comparing. Try again; your photos haven't changed."; running = false
                }
            }
    }
    private func title(_ verdict: PhotoComparisonVerdict) -> String {
        switch verdict {
        case .exact: "Exact copies"
        case .similar: "Visually similar"
        case .different: "Not a close visual match"
        case .unavailable: "Comparison incomplete"
        }
    }
    private func explanation(_ verdict: PhotoComparisonVerdict) -> String {
        switch verdict {
        case .exact: "Original contents match. Your favorite and review protections still apply."
        case .similar: "Apple's on-device visual analysis places these photos within Pearl's matching rules."
        case .different: "These photos fall outside Pearl's close-match rules. Crops or edits can affect this result."
        case .unavailable: "Both images couldn't be analyzed. An item may need a download or may no longer be available."
        }
    }
}
