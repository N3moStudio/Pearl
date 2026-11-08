import SwiftUI
import Observation
import NativeSettingsKit

enum PearlTheme: String, CaseIterable, Identifiable {
    case pearl, glacier, afterhours, porcelain, ion, ember, bloom, blueprint, titanium
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var kit: NSKTheme? { NSKTheme(rawValue: rawValue) }
    func palette(dark: Bool) -> NSKPalette {
        if let kit { return kit.palette(dark: dark) }
        return NSKPalette(hex: dark
            ? [0xA6C495, 0x122012, 0xAEC4A7, 0x121412, 0x1C1C1E, 0xF2F4EE, 0xB3B9AE]
            : [0x4D6E40, 0xFFFFFF, 0x52674B, 0xFBF9F6, 0xFFFFFF, 0x222820, 0x61695C])
    }
}

@MainActor @Observable final class PearlAppearance {
    static let themeKey = "pearl.appearance.theme"
    static let surfaceKey = "pearl.appearance.surface"
    @ObservationIgnored private let defaults: UserDefaults
    private var rawTheme: String?
    private var rawSurface: String?
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-reset-appearance") {
            defaults.removeObject(forKey: Self.themeKey); defaults.removeObject(forKey: Self.surfaceKey)
        }
        #endif
        rawTheme = defaults.string(forKey: Self.themeKey)
        rawSurface = defaults.string(forKey: Self.surfaceKey)
    }
    var theme: PearlTheme {
        get { rawTheme.flatMap(PearlTheme.init(rawValue:)) ?? .pearl }
        set { rawTheme = newValue.rawValue; defaults.set(newValue.rawValue, forKey: Self.themeKey) }
    }
    var surface: NSKSurface {
        get { rawSurface.flatMap(NSKSurface.init(rawValue:)) ?? .glass }
        set { rawSurface = newValue.rawValue; defaults.set(newValue.rawValue, forKey: Self.surfaceKey) }
    }
}

struct PearlAppearanceRoot: ViewModifier {
    @Environment(PearlAppearance.self) private var appearance
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let colors = appearance.theme.palette(dark: (appearance.theme.kit?.preferredColorScheme ?? scheme) == .dark)
        content.nativeSettingsAppearance(theme: appearance.theme.kit ?? .glacier, surface: appearance.surface)
            // Resolve once from the selected theme so an already-presented sheet
            // cannot mix a stale system scheme with newly selected accent colors.
            .environment(\.nskPaletteOverride, colors)
            .tint(colors.accent).foregroundStyle(colors.text)
    }
}

struct PearlFloatingBackground<S: Shape>: View {
    let shape: S
    @Environment(\.nskPalette) private var colors
    @Environment(\.nskSurface) private var surface
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduced
    var body: some View {
        if surface.allowsTransparency(reduceTransparency: reduced, increasedContrast: contrast == .increased) {
            if #available(iOS 26.0, *) { shape.fill(.clear).glassEffect(.regular, in: shape) }
            else { shape.fill(.regularMaterial) }
        } else { shape.fill(colors.surface) }
    }
}

struct PearlNavigationSurface: ViewModifier {
    @Environment(\.nskPalette) private var colors
    @Environment(\.nskSurface) private var surface
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduced
    func body(content: Content) -> some View {
        let glass = surface.allowsTransparency(reduceTransparency: reduced, increasedContrast: contrast == .increased)
        content.toolbarBackground(colors.surface, for: .navigationBar, .tabBar)
            .toolbarBackground(glass ? .automatic : .visible, for: .navigationBar, .tabBar)
    }
}
