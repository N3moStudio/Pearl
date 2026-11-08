import SwiftUI
import NativeSettingsKit

struct AppearanceView: View {
    @Environment(PearlAppearance.self) private var appearance
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.colorScheme) private var scheme
    @Environment(\.nskPalette) private var colors
    var body: some View {
        NSKList {
            NSKSection("Theme") {
                LazyVGrid(columns: size.isAccessibilitySize ? [GridItem(.flexible())] :
                    [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ForEach(PearlTheme.allCases) { choice in
                        let palette = choice.palette(dark: (choice.kit?.preferredColorScheme ?? scheme) == .dark)
                        Button { appearance.theme = choice } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Circle().fill(palette.accent).frame(width: 18, height: 18)
                                    Circle().fill(palette.muted).frame(width: 18, height: 18)
                                    Spacer(minLength: 4)
                                    Image(systemName: appearance.theme == choice ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(palette.accent)
                                }.accessibilityHidden(true)
                                Text(choice.title).font(.subheadline.weight(.semibold)).foregroundStyle(palette.text)
                                    .fixedSize(horizontal: false, vertical: true)
                            }.padding(12).frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(palette.accent.opacity(appearance.theme == choice ? 1 : 0.25), lineWidth: appearance.theme == choice ? 2 : 1))
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain).accessibilityLabel(choice.title)
                            .accessibilityValue(appearance.theme == choice ? "Selected" : "")
                            .accessibilityAddTraits(appearance.theme == choice ? [.isSelected] : [])
                            .accessibilityIdentifier("theme-\(choice.rawValue)")
                    }
                }.padding(.vertical, 8)
            }
            NSKSection("Surface") {
                ForEach(NSKSurface.allCases) { choice in
                    Button { appearance.surface = choice } label: {
                        HStack {
                            Text(choice.title).foregroundStyle(colors.text)
                            Spacer(minLength: 8)
                            if appearance.surface == choice { Image(systemName: "checkmark").accessibilityHidden(true) }
                        }.frame(minHeight: 44).contentShape(Rectangle())
                    }.accessibilityValue(appearance.surface == choice ? "Selected" : "")
                        .accessibilityAddTraits(appearance.surface == choice ? [.isSelected] : [])
                        .accessibilityIdentifier("surface-\(choice.rawValue)")
                }
            }
        }.navigationTitle("Appearance").navigationBarTitleDisplayMode(.inline)
    }
}
