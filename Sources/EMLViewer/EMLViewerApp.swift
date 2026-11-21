import SwiftUI
import AppKit

@main
struct EMLViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 520, minHeight: 380)
                .task {
                    openFromCommandLine()
                }
        }
        .defaultSize(width: 900, height: 640)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { state.openPanel() }
                    .keyboardShortcut("o")
            }
        }
    }

    @MainActor
    private func openFromCommandLine() {
        for arg in CommandLine.arguments.dropFirst() {
            if arg.hasPrefix("-") { continue }
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                state.open(url)
                return
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        AppearanceMode.load().applyToApp()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Task { @MainActor in
            AppState.shared.open(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
