import SwiftUI

enum AppPreferences {
    static let appearance = "com.noma4i.emlviewer.appearance"
    static let fontSize = "com.noma4i.emlviewer.fontSize"
    static let plainFont = "com.noma4i.emlviewer.plainFont"
}

struct SettingsView: View {
    @AppStorage(AppPreferences.appearance) private var appearance = AppearanceMode.system
    @AppStorage(AppPreferences.fontSize) private var fontSize = 13.0
    @AppStorage(AppPreferences.plainFont) private var plainFont = "monospaced"

    var body: some View {
        Form {
            Picker("Appearance", selection: $appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            Stepper("Message text size: \(Int(fontSize)) pt", value: $fontSize, in: 10...24, step: 1)
            Picker("Plain text font", selection: $plainFont) {
                Text("Monospaced").tag("monospaced")
                Text("Proportional").tag("proportional")
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
