import SwiftUI
import AVKit
import PearlCore

struct ReviewView: View {
    let title: String
    @State private var session: [MediaItem]
    @State private var position = 0
    @State private var history: [Int] = []
    @State private var viewing = false
    @Environment(PearlModel.self) private var model
    init(items: [MediaItem], title: String) { self.title = title; _session = State(initialValue: items) }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if position < session.count {
                    let item = session[position]
                    Text("\(position + 1) of \(session.count)").font(.subheadline).foregroundStyle(.secondary)
                    Button { viewing = true } label: {
                        Thumbnail(id: item.id, size: 1000, modified: item.modified, fit: true)
                            .frame(minHeight: 270, idealHeight: 390, maxHeight: 430)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: item.isVideo ? "play.circle.fill" : "arrow.up.left.and.arrow.down.right")
                                    .font(.title).padding().foregroundStyle(.white).shadow(radius: 3)
                            }.clipShape(RoundedRectangle(cornerRadius: 26))
                    }.buttonStyle(.plain).accessibilityLabel(item.isVideo ? "Play video" : "Open full photo")
                        .simultaneousGesture(DragGesture(minimumDistance: 60).onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            if value.translation.width > 90 { decide(item, remove: false) }
                            if value.translation.width < -90 { decide(item, remove: true) }
                        })
                    VStack(spacing: 6) {
                        Text(item.date.formatted(date: .long, time: .shortened)).font(.headline)
                        Text("\(item.width) × \(item.height)\(item.isLive ? " · Live Photo" : "")\(item.isVideo ? " · \(Int(item.duration)) seconds" : "")")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if item.favorite || model.queue.protected.contains(item.id) {
                            Label("Protected", systemImage: "heart.fill").font(.footnote).foregroundStyle(PearlStyle.sage)
                        }
                    }
                    HStack(spacing: 16) {
                        Button("Keep", systemImage: "heart") { decide(item, remove: false) }.buttonStyle(.borderedProminent)
                        Button("Remove", systemImage: "tray") { decide(item, remove: true) }.buttonStyle(.bordered)
                            .disabled(item.favorite || model.queue.protected.contains(item.id))
                            .accessibilityIdentifier("stageRemoval")
                    }.controlSize(.large)
                    Text("Remove adds to your review. Nothing is deleted yet.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    HStack {
                        Button("Undo", systemImage: "arrow.uturn.backward") {
                            guard let previous = history.popLast() else { return }
                            model.undo(); position = previous
                        }.disabled(history.isEmpty).accessibilityIdentifier("undoReview")
                        Spacer()
                        Button("Skip") { position += 1 }
                        Spacer()
                        Button(model.queue.protected.contains(item.id) ? "Unprotect" : "Protect", systemImage: "lock") {
                            model.toggleProtection(item.id); history = []
                        }.disabled(item.favorite)
                    }.font(.subheadline)
                } else {
                    ContentUnavailableView("A little lighter", systemImage: "checkmark.circle", description: Text("This review is finished. Your choices are saved."))
                    if !history.isEmpty {
                        Button("Undo last choice") { if let previous = history.popLast() { model.undo(); position = previous } }
                    }
                    Button("Review selected items") { model.showQueue = true }.buttonStyle(.borderedProminent)
                        .disabled(model.pendingItems.isEmpty)
                }
            }.padding(22).frame(maxWidth: 650).frame(maxWidth: .infinity)
        }.background(PearlStyle.canvas).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewing) { if position < session.count { MediaViewer(item: session[position]) } }
    }
    private func decide(_ item: MediaItem, remove: Bool) {
        if model.decide(item, remove: remove) { history.append(position); position += 1 }
    }
}

struct MediaViewer: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @Environment(PearlModel.self) private var model
    @State private var image: UIImage?
    @State private var player: AVPlayer?
    @State private var loading = true
    @State private var cloud = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let player { VideoPlayer(player: player) }
                else if let image { ZoomPhoto(image: image) }
                else if loading { ProgressView().tint(.white).accessibilityLabel("Loading preview") }
                else {
                    VStack(spacing: 20) {
                        Text("This preview isn't available. The item may need iCloud access or may have changed in Photos.").foregroundStyle(.white)
                        if PhotoAccess.asset(item.id) != nil {
                            Button("Try downloading from iCloud") { cloud = true }.buttonStyle(.borderedProminent)
                        }
                    }.padding()
                }
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
                .task(id: cloud) {
                    loading = true
                    if item.isVideo, let asset = await PhotoAccess.video(item.id, network: cloud || model.allowCloud) {
                        guard !Task.isCancelled else { return }; player = asset.player()
                    } else if !item.isVideo { image = await PhotoAccess.image(item.id, size: 2000, network: cloud || model.allowCloud) }
                    loading = false
                }.onDisappear { player?.pause(); player = nil }
        }
    }
}

struct ZoomPhoto: UIViewRepresentable {
    let image: UIImage
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIScrollView {
        let view = UIScrollView(); view.minimumZoomScale = 1; view.maximumZoomScale = 5
        view.delegate = context.coordinator; view.backgroundColor = .black
        let imageView = context.coordinator.imageView
        imageView.image = image; imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
        view.accessibilityLabel = "Photo. Pinch to zoom."
        return view
    }
    func updateUIView(_ view: UIScrollView, context: Context) {
        context.coordinator.imageView.image = image
        if view.zoomScale == 1 { context.coordinator.imageView.frame = view.bounds }
    }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    }
}
