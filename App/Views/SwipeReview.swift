import SwiftUI
import AVKit
import PearlCore

struct ReviewView: View {
    let session: ReviewSession
    @Environment(PearlModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: Int
    @State private var leaving = false
    @State private var exitOffset = CGSize.zero
    @State private var queue = false
    @State private var zoom: CGFloat = 1
    @State private var pan = CGSize.zero
    @State private var reviewedCount = 0
    @GestureState(resetTransaction: Transaction(animation: .spring(duration: 0.28, bounce: 0.12))) private var drag = CGSize.zero
    @GestureState private var magnification: CGFloat = 1
    private let ink = Color.white
    private let keepColor = Color(red: 0.68, green: 0.81, blue: 0.64)
    private let deleteColor = Color(red: 0.87, green: 0.60, blue: 0.51)
    init(session: ReviewSession) { self.session = session; _position = State(initialValue: session.position) }
    private var current: MediaItem? {
        guard session.items.indices.contains(position) else { return nil }
        return model.item(session.items[position].id)
    }
    private var undoAvailable: Bool {
        guard let id = model.queue.lastUndoID else { return false }
        return session.positions[id] != nil
    }
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 12) {
                header
                if let item = current {
                    photo(item, width: proxy.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                    filmstrip
                    actions(item, width: proxy.size.width)
                } else if position < session.items.count {
                    ContentUnavailableView("Photo no longer available", systemImage: "photo", description: Text("It may have been removed or its access changed."))
                    Button("Continue") { position += 1 }.buttonStyle(.bordered)
                    Spacer()
                } else {
                    Spacer()
                    Image(systemName: "checkmark.circle").font(.system(size: 50)).foregroundStyle(keepColor)
                    Text("A little lighter").font(.title.bold())
                    Text("Your choices are saved.").foregroundStyle(.secondary)
                    Button("Review selected items") { queue = true }.buttonStyle(.borderedProminent).tint(PearlStyle.sage)
                        .disabled(model.pendingItems.isEmpty)
                    Button("Back to months") { dismiss() }.buttonStyle(.bordered)
                    Spacer()
                    filmstrip
                }
            }.padding(.top, 8).padding(.bottom, 10)
                .frame(maxWidth: 1000).frame(maxWidth: .infinity)
        }
        .background(Color.black.ignoresSafeArea()).foregroundStyle(ink).preferredColorScheme(.dark)
        .statusBarHidden().interactiveDismissDisabled()
        .sheet(isPresented: $queue) { NavigationStack { QueueView() } }
        .onAppear { updateReviewedCount() }
        .onChange(of: model.queue.reviewed) { _, _ in updateReviewedCount() }
        .onChange(of: position) { _, _ in zoom = 1; pan = .zero }
        .alert("Pearl", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .alert("Pearl", isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button("OK") { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }
    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: { Image(systemName: "xmark").font(.title3.weight(.medium)).frame(width: 48, height: 48) }
                .buttonStyle(PearlRoundButton()).accessibilityLabel("Close review").accessibilityIdentifier("closeReview")
            VStack(spacing: 4) {
                Text(session.title).font(.headline).multilineTextAlignment(.center).lineLimit(2)
                Text("\(min(position + 1, session.items.count)) of \(session.items.count) · \(Int(Double(reviewedCount) / Double(max(1, session.items.count)) * 100))%")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    .accessibilityIdentifier("reviewProgress")
            }.frame(maxWidth: .infinity)
            Button {
                if let id = model.undo(), let index = session.positions[id] { position = index }
            } label: { Image(systemName: "arrow.uturn.backward").font(.title3).frame(width: 48, height: 48) }
                .buttonStyle(PearlRoundButton()).disabled(!undoAvailable || leaving)
                .accessibilityLabel("Undo last choice").accessibilityIdentifier("undoReview")
        }.padding(.horizontal, 18)
    }
    private func photo(_ item: MediaItem, width: CGFloat) -> some View {
        let offset = leaving ? exitOffset : drag
        return ZStack {
            if position + 1 < session.items.count {
                let next = session.items[position + 1]
                Thumbnail(id: next.id, size: 1400, modified: next.modified, fit: true)
                    .opacity(min(abs(offset.width) / 100, 1)).accessibilityHidden(true)
            }
            ZStack {
                MediaPreview(item: item).id(item.id)
                    .scaleEffect(zoom * magnification)
                    .offset(x: zoom > 1 ? pan.width + drag.width : 0, y: zoom > 1 ? pan.height + drag.height : 0)
                    .clipped()
                if zoom == 1, abs(offset.width) > 5 {
                    Text(offset.width < 0 ? "Delete" : "Keep")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(offset.width < 0 ? deleteColor : keepColor, lineWidth: 3))
                        .opacity(min(abs(offset.width) / (width * 0.25), 1)).accessibilityHidden(true)
                }
            }
            .rotationEffect(.degrees(zoom > 1 || reduceMotion ? 0 : Double(offset.width / width) * 12))
            .offset(x: zoom > 1 ? 0 : offset.width, y: zoom > 1 ? 0 : offset.height * 0.18)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 8)
                .updating($drag) { value, state, transaction in
                    guard !leaving else { return }
                    transaction.animation = nil
                    if zoom > 1 || abs(value.translation.width) > abs(value.translation.height) * 1.25 { state = value.translation }
                }
                .onEnded { value in
                    guard !leaving else { return }
                    if zoom > 1 {
                        pan.width = max(-width, min(width, pan.width + value.translation.width))
                        pan.height = max(-width, min(width, pan.height + value.translation.height))
                    } else if let choice = SwipeDecision.released(x: value.translation.width, y: value.translation.height,
                                                                  predictedX: value.predictedEndTranslation.width, width: width) {
                        decide(item, remove: choice == .remove, width: width, origin: value.translation)
                    }
                })
            .simultaneousGesture(MagnifyGesture().updating($magnification) { value, state, _ in state = value.magnification }
                .onEnded { value in zoom = min(4, max(1, zoom * value.magnification)); if zoom == 1 { pan = .zero } })
            .onTapGesture(count: 2) { zoom = zoom > 1 ? 1 : 2; pan = .zero }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(item.isVideo ? "Video" : "Photo")
            .accessibilityIdentifier("reviewPhoto")
            .accessibilityAction(named: "Keep") { decide(item, remove: false, width: width) }
            .accessibilityAction(named: "Add to removal review") { decide(item, remove: true, width: width) }
        }.clipped()
    }
    private var filmstrip: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 7) {
                    ForEach(session.items.indices, id: \.self) { index in
                        let item = session.items[index]
                        Button {
                            guard !leaving else { return }; position = index
                        } label: {
                            Thumbnail(id: item.id, size: 150, modified: item.modified)
                                .frame(width: 48, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
                                .opacity(index == position ? 1 : 0.55)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(index == position ? ink : .clear, lineWidth: 2))
                                .overlay(alignment: .bottomTrailing) {
                                    if model.queue.reviewed.contains(item.id) {
                                        Image(systemName: model.queue.pending.contains(item.id) ? "trash.circle.fill" : "checkmark.circle.fill")
                                            .font(.caption).foregroundStyle(model.queue.pending.contains(item.id) ? deleteColor : keepColor).padding(3)
                                    }
                                }
                        }.buttonStyle(.plain).id(index)
                            .accessibilityLabel("Jump to item \(index + 1)").accessibilityIdentifier("reviewThumbnail\(index)")
                    }
                }.padding(.horizontal, 20)
            }.scrollIndicators(.hidden).frame(height: 62)
                .onAppear { reader.scrollTo(position, anchor: .center) }
                .onChange(of: position) { _, value in
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) { reader.scrollTo(value, anchor: .center) }
                }
        }
    }
    private func actions(_ item: MediaItem, width: CGFloat) -> some View {
        HStack(spacing: 14) {
            Button { decide(item, remove: true, width: width) } label: {
                Label("Delete", systemImage: "trash").font(.headline).frame(maxWidth: .infinity, minHeight: 56)
            }.buttonStyle(PearlReviewButton(tint: deleteColor))
                .disabled(item.favorite || model.queue.protected.contains(item.id) || leaving || model.favoriting.contains(item.id))
                .accessibilityIdentifier("stageRemoval").accessibilityHint("Adds to review. Nothing is deleted until you confirm.")
            Button { Task { await model.toggleFavorite(item.id) } } label: {
                Image(systemName: item.favorite ? "heart.fill" : "heart").font(.title2)
                    .contentTransition(.symbolEffect(.replace)).frame(width: 56, height: 56)
            }.buttonStyle(PearlRoundButton()).foregroundStyle(item.favorite ? deleteColor : ink)
                .disabled(leaving || model.favoriting.contains(item.id))
                .accessibilityLabel(item.favorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityIdentifier("favoriteItem").sensoryFeedback(.selection, trigger: item.favorite)
                .contextMenu {
                    Button(model.queue.protected.contains(item.id) ? "Unprotect" : "Protect", systemImage: "lock") {
                        model.toggleProtection(item.id)
                    }.disabled(item.favorite)
                }
            Button { decide(item, remove: false, width: width) } label: {
                Label("Keep", systemImage: "checkmark").font(.headline).frame(maxWidth: .infinity, minHeight: 56)
            }.buttonStyle(PearlReviewButton(tint: keepColor)).disabled(leaving || model.favoriting.contains(item.id))
                .accessibilityIdentifier("keepItem")
        }.padding(.horizontal, 18).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    private func decide(_ item: MediaItem, remove: Bool, width: CGFloat, origin: CGSize = .zero) {
        guard !leaving, !model.favoriting.contains(item.id), model.decide(item, remove: remove) else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if reduceMotion { position += 1; return }
        leaving = true; exitOffset = origin
        withAnimation(.spring(duration: 0.26, bounce: 0), completionCriteria: .logicallyComplete) {
            exitOffset = CGSize(width: (remove ? -1 : 1) * width * 1.3, height: origin.height)
        } completion: {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { position += 1; exitOffset = .zero; leaving = false }
        }
    }
    private func updateReviewedCount() {
        reviewedCount = session.items.reduce(0) { $0 + (model.queue.reviewed.contains($1.id) ? 1 : 0) }
    }
}

struct PearlRoundButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.12)))
            .opacity(!enabled ? 0.35 : (configuration.isPressed ? 0.65 : 1))
    }
}
private struct PearlReviewButton: ButtonStyle {
    let tint: Color
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(tint)
            .background(tint.opacity(configuration.isPressed ? 0.28 : 0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.3)))
            .opacity(enabled ? 1 : 0.35)
    }
}
