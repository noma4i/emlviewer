import SwiftUI
import AppKit

struct ThemePalette {
    let background: String
    let surface: String
    let text: String
    let secondaryText: String
    let link: String
    let border: String
    let quote: String

    func color(_ hex: String) -> Color { Color(nsColor: nsColor(hex)) }

    func nsColor(_ hex: String) -> NSColor {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        return NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255,
                       green: CGFloat((value >> 8) & 255) / 255,
                       blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case system, light, dark, solarizedLight, solarizedDark, nord, dracula, gruvboxDark, oneDark, sepia
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        case .solarizedLight: "Solarized Light"
        case .solarizedDark: "Solarized Dark"
        case .nord: "Nord"
        case .dracula: "Dracula"
        case .gruvboxDark: "Gruvbox Dark"
        case .oneDark: "One Dark"
        case .sepia: "Sepia"
        }
    }

    var nsAppearance: NSAppearance? {
        if self == .system { return nil }
        return NSAppearance(named: isDark ? .darkAqua : .aqua)
    }

    var isDark: Bool {
        switch self {
        case .dark, .solarizedDark, .nord, .dracula, .gruvboxDark, .oneDark: true
        default: false
        }
    }

    func palette(_ scheme: ColorScheme) -> ThemePalette {
        if self == .system { return (scheme == .dark ? Theme.dark : .light).palette(scheme) }
        return switch self {
        case .system, .light: .init(background: "#ffffff", surface: "#f5f5f7", text: "#1d1d1f",
                              secondaryText: "#6e6e73", link: "#0066cc",
                              border: "#d2d2d7", quote: "#6e6e73")
        case .dark: .init(background: "#1e1e1e", surface: "#2c2c2e", text: "#e6e6e6",
                              secondaryText: "#b0b0b0", link: "#64aaff",
                              border: "#555555", quote: "#b0b0b0")
        case .solarizedLight: .init(background: "#fdf6e3", surface: "#eee8d5", text: "#586e75",
                              secondaryText: "#657b83", link: "#268bd2",
                              border: "#93a1a1", quote: "#586e75")
        case .solarizedDark: .init(background: "#002b36", surface: "#073642", text: "#93a1a1",
                              secondaryText: "#839496", link: "#268bd2",
                              border: "#586e75", quote: "#93a1a1")
        case .nord: .init(background: "#2e3440", surface: "#3b4252", text: "#eceff4",
                              secondaryText: "#d8dee9", link: "#88c0d0",
                              border: "#4c566a", quote: "#d8dee9")
        case .dracula: .init(background: "#282a36", surface: "#44475a", text: "#f8f8f2",
                              secondaryText: "#bfbfc9", link: "#bd93f9",
                              border: "#6272a4", quote: "#bfbfc9")
        case .gruvboxDark: .init(background: "#282828", surface: "#3c3836", text: "#ebdbb2",
                              secondaryText: "#bdae93", link: "#83a598",
                              border: "#665c54", quote: "#bdae93")
        case .oneDark: .init(background: "#282c34", surface: "#21252b", text: "#abb2bf",
                              secondaryText: "#9da5b4", link: "#61afef",
                              border: "#5c6370", quote: "#9da5b4")
        case .sepia: .init(background: "#f4ecd8", surface: "#e8dcc2", text: "#5b4636",
                              secondaryText: "#78624c", link: "#805b32",
                              border: "#bca98b", quote: "#78624c")
        }
    }

    static func load() -> Theme {
        let raw = UserDefaults.standard.string(forKey: AppPreferences.appearance) ?? Theme.system.rawValue
        return Theme(rawValue: raw) ?? .system
    }

    func applyToApp() { NSApp.appearance = nsAppearance }
}

struct ThemePicker: View {
    @Binding var selection: Theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Picker("Theme", selection: $selection) {
            ForEach(Theme.allCases) { theme in
                let palette = theme.palette(scheme)
                HStack {
                    Circle().fill(palette.color(palette.background)).frame(width: 14, height: 14)
                        .overlay(Circle().fill(palette.color(palette.text)).frame(width: 6, height: 6))
                        .overlay(Circle().strokeBorder(palette.color(palette.border)))
                    Text(theme.label)
                }.tag(theme)
            }
        }.pickerStyle(.menu)
    }
}
