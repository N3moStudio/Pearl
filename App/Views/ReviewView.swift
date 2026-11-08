import SwiftUI
import NativeSettingsKit
import AVKit
import PearlCore

struct MediaViewer: View {
    @Environment(\.nskPalette) private var colors
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @Environment(PearlModel.self) private var model
    @State private var image: UIImage?
    @State private var loading = true
    @State private var cloud = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if item.isVideo { MediaPreview(item: item).id(item.id) }
                else if let image { ZoomPhoto(image: image) }
                else if loading { ProgressView().tint(.white).accessibilityLabel("Loading preview") }
                else {
                    VStack(spacing: 20) {
                        Text("This preview isn't available. The item may need iCloud access or may have changed in Photos.").foregroundStyle(.white)
                        if PhotoAccess.asset(item.id) != nil {
                            Button("Try downloading from iCloud") { cloud = true }.buttonStyle(.borderedProminent).foregroundStyle(colors.onAccent)
                        }
                    }.padding()
                }
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
                .task(id: cloud) {
                    loading = true
                    guard !item.isVideo else { return }
                    let result = await PhotoAccess.image(item.id, size: 2000, network: cloud || model.allowCloud)
                    guard !Task.isCancelled else { return }
                    image = result
                    loading = false
                }
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
