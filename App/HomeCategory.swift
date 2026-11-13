import SwiftUI
import Photos
import PearlCore
import NativeSettingsKit

enum HomeCategory: String, CaseIterable, Identifiable, Sendable {
    case albums, photos, videos, selfies, lives, portraits, panoramas, slomo, cinematic, bursts, screenshots, recordings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .albums: "Albums"
        case .photos: "Photos"
        case .videos: "Videos"
        case .selfies: "Selfies"
        case .lives: "Live Photos"
        case .portraits: "Portraits"
        case .panoramas: "Panoramas"
        case .slomo: "Slow-mo"
        case .cinematic: "Cinematic"
        case .bursts: "Bursts"
        case .screenshots: "Screenshots"
        case .recordings: "Screen recordings"
        }
    }
    var symbol: String {
        switch self {
        case .albums: "rectangle.stack"
        case .photos: "photo"
        case .videos, .cinematic: "film"
        case .selfies, .portraits: "person.crop.square"
        case .lives: "livephoto"
        case .panoramas: "pano"
        case .slomo: "slowmo"
        case .bursts: "square.stack.3d.up"
        case .screenshots: "viewfinder"
        case .recordings: "record.circle"
        }
    }
    var smartAlbum: PHAssetCollectionSubtype? {
        switch self {
        case .selfies: .smartAlbumSelfPortraits
        case .lives: .smartAlbumLivePhotos
        case .portraits: .smartAlbumDepthEffect
        case .panoramas: .smartAlbumPanoramas
        case .slomo: .smartAlbumSlomoVideos
        case .cinematic: .smartAlbumCinematic
        case .bursts: .smartAlbumBursts
        case .screenshots: .smartAlbumScreenshots
        case .recordings: .smartAlbumScreenRecordings
        default: nil
        }
    }
    static func normalized(_ raw: [String]) -> [HomeCategory] {
        var seen = Set<HomeCategory>()
        return (raw.compactMap(HomeCategory.init(rawValue:)) + allCases).filter { seen.insert($0).inserted }
    }
}

@MainActor @Observable final class HomeOrder {
    static let key = "pearl.home.order"
    private let defaults: UserDefaults
    private(set) var categories: [HomeCategory]
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        categories = HomeCategory.normalized(defaults.stringArray(forKey: Self.key) ?? [])
    }
    func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        defaults.set(categories.map(\.rawValue), forKey: Self.key)
    }
    func reset() {
        categories = HomeCategory.allCases
        defaults.removeObject(forKey: Self.key)
    }
}

struct HomeOrderView: View {
    @Environment(PearlModel.self) private var model
    var body: some View {
        NSKList {
            Section {
                ForEach(model.homeOrder.categories) { category in
                    HStack(spacing: 12) {
                        Text("\((model.homeOrder.categories.firstIndex(of: category) ?? 0) + 1)")
                            .monospacedDigit().foregroundStyle(.secondary).frame(minWidth: 24)
                        Label(category.title, systemImage: category.symbol)
                    }.frame(minHeight: 44).accessibilityElement(children: .combine)
                }.onMove { model.homeOrder.move(from: $0, to: $1) }
            } footer: {
                Text("Read left to right: 1 is top left, 2 top right, then 3 below 1. Large accessibility text uses one column in the same order.")
            }
            Section { Button("Restore default order") { model.homeOrder.reset() } }
        }.environment(\.editMode, .constant(.active))
            .navigationTitle("Home order").navigationBarTitleDisplayMode(.inline)
    }
}
