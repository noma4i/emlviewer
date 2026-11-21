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
            .pickerStyle(.segmented)
            Picker("Message text size", selection: $fontSize) {
                ForEach([10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24], id: \.self) { size in
                    Text("\(size) pt").tag(Double(size))
                }
            }
            .pickerStyle(.menu)
            Picker("Plain text font", selection: $plainFont) {
                Text("Monospaced").tag("monospaced")
                Text("Proportional").tag("proportional")
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }
}
