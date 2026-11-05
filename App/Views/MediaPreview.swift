import SwiftUI
import AVKit
import PearlCore

/// The poster stays on top until AVKit has a displayable frame, including
/// during iCloud loading. Changing the asset destroys this view's task/state.
struct MediaPreview: View {
    let item: MediaItem
    @Environment(PearlModel.self) private var model
    @State private var playback = PreviewPlayback()
    @State private var attempt = 0
    @State private var download = false

    var body: some View {
        ZStack {
            if let player = playback.player {
                PreviewPlayer(player: player) { ready in
                    if playback.player === player { playback.ready = ready }
                }.id(ObjectIdentifier(player))
                    .accessibilityIdentifier("previewVideo")
                    .accessibilityValue(playback.ready ? "Ready" : "Loading")
            }
            Thumbnail(id: item.id, size: 1600, modified: item.modified, fit: true,
                      network: model.allowCloud || download, showStatus: !item.isVideo)
                .opacity(playback.ready ? 0 : 1)
                .allowsHitTesting(!playback.ready)
            if item.isVideo && !playback.ready {
                VStack(spacing: 12) {
                    if playback.loading {
                        ProgressView().tint(.white).accessibilityLabel("Loading video")
                        Button("Cancel") { attempt = 0; playback.stop() }
                    } else {
                        if let message = playback.message {
                            Text(message).font(.callout).multilineTextAlignment(.center)
                            if !model.allowCloud && !download {
                                Button("Download from iCloud") { download = true; attempt += 1 }
                            }
                        }
                        Button { attempt += 1 } label: {
                            Image(systemName: "play.circle.fill").font(.system(size: 52))
                        }.accessibilityLabel(playback.message == nil ? "Play video" : "Retry video")
                            .accessibilityIdentifier("playPreview")
                    }
                }.padding(18).foregroundStyle(.white)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .padding(24)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: attempt) {
                guard attempt > 0 else { return }
                await playback.load(item.id, network: model.allowCloud || download)
            }
            .onDisappear { playback.stop() }
    }
}

@MainActor @Observable private final class PreviewPlayback {
    var player: AVPlayer?
    var ready = false
    var loading = false
    var message: String?
    private var generation = UUID()

    func stop() {
        generation = UUID()
        player?.pause(); player = nil
        ready = false; loading = false
    }

    func load(_ id: String, network: Bool) async {
        stop(); message = nil; loading = true
        let request = generation
        // PhotoKit cancellation propagates to its image request. A stalled
        // download has a bounded wait and can also be cancelled immediately.
        let source = await withTaskGroup(of: VideoSource?.self) { group in
            group.addTask { await PhotoAccess.video(id, network: network) }
            group.addTask { try? await Task.sleep(for: .seconds(30)); return nil }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        guard !Task.isCancelled, generation == request else { return }
        guard let source else { fail(); return }
        let video = source.player()
        player = video; video.play()
        do {
            for _ in 0..<75 {
                try Task.checkCancellation()
                guard generation == request else { return }
                if ready { loading = false; return }
                if video.currentItem?.status == .failed { fail(); return }
                try await Task.sleep(for: .milliseconds(200))
            }
            if generation == request { fail() }
        } catch {
            if generation == request { stop() }
        }
    }

    private func fail() {
        stop()
        message = "This video couldn't load. Try again, or download it from iCloud."
    }
}

private struct PreviewPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let onReady: @MainActor (Bool) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onReady: onReady) }
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = false
        context.coordinator.observation = controller.observe(\.isReadyForDisplay, options: [.initial, .new]) { @Sendable [weak coordinator = context.coordinator] _, change in
            let ready = change.newValue ?? false
            Task { @MainActor in coordinator?.onReady(ready) }
        }
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        context.coordinator.onReady = onReady
    }
    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.observation?.invalidate()
        coordinator.observation = nil
        controller.player?.pause(); controller.player = nil
    }
    @MainActor final class Coordinator {
        var observation: NSKeyValueObservation?
        var onReady: @MainActor (Bool) -> Void
        init(onReady: @escaping @MainActor (Bool) -> Void) { self.onReady = onReady }
    }
}
