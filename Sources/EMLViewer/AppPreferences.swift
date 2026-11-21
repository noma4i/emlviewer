import SwiftUI
import AppKit

enum AppPreferences {
    static let appearance = "com.noma4i.emlviewer.appearance"
    static let fontSize = "com.noma4i.emlviewer.fontSize"
    static let fontFamily = "com.noma4i.emlviewer.fontFamily"

    static var defaultFontFamily: String {
        let defaults = UserDefaults.standard
        if let family = defaults.string(forKey: fontFamily) { return family }
        let family = defaults.string(forKey: "com.noma4i.emlviewer.plainFont") == "proportional" ? "System" : "Menlo"
        defaults.set(family, forKey: fontFamily)
        return family
    }

    static let fontFamilies = [
        "System", "SF Mono", "Menlo", "Monaco", "Courier New", "Helvetica Neue", "Helvetica", "Arial",
        "Avenir Next", "Futura", "Gill Sans", "Optima", "Lucida Grande", "Verdana", "Tahoma", "Trebuchet MS",
        "Georgia", "Times New Roman", "Palatino", "Baskerville", "Charter", "Iowan Old Style"
    ]

    static func font(_ family: String, size: CGFloat) -> Font {
        switch family {
        case "System": .system(size: size)
        case "SF Mono": .system(size: size, design: .monospaced)
        default: .custom(family, size: size)
        }
    }
}

struct SettingsView: View {
    @AppStorage(AppPreferences.appearance) private var appearance = AppearanceMode.system
    @AppStorage(AppPreferences.fontSize) private var fontSize = 13.0
    @AppStorage(AppPreferences.fontFamily) private var fontFamily = AppPreferences.defaultFontFamily

    var body: some View {
        Form {
            Picker("Appearance", selection: $appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Picker("Message text size", selection: $fontSize) {
                ForEach([10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24], id: \.self) { size in
                    Text("\(size) pt").tag(Double(size))
                }
            }
            .pickerStyle(.menu)
            Picker("Font", selection: $fontFamily) {
                ForEach(AppPreferences.fontFamilies.filter {
                    $0 == "System" || NSFontManager.shared.availableFontFamilies.contains($0)
                }, id: \.self) { family in
                    Text(family).font(AppPreferences.font(family, size: NSFont.systemFontSize)).tag(family)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }
}
