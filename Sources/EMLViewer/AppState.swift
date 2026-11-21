import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import EMLCore

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    static let supportedTypes: [UTType] = [
        UTType(filenameExtension: "eml") ?? UTType("public.email-message"),
        UTType(filenameExtension: "msg") ?? UTType("com.microsoft.outlook-email-message"),
    ].compactMap { $0 }

    @Published var message: Message?
    @Published var sourceURL: URL?
    @Published var errorText: String?
    @Published var toast: String?
    private var toastTask: Task<Void, Never>?

    private init() {}

    // MARK: - Loading

    func open(_ url: URL) {
        do {
            let msg = try Message(url: url)
            self.message = msg
            self.sourceURL = url
            self.errorText = nil
        } catch {
            self.errorText = "Failed to open: \(error.localizedDescription)"
            self.message = nil
            self.sourceURL = url
        }
    }

    func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = Self.supportedTypes
        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
    }

    // MARK: - Attachment actions

    func openAttachment(_ part: Part) {
        guard let url = writeToTemp(part) else {
            NSSound.beep(); return
        }
        NSWorkspace.shared.open(url)
    }

    func saveAsAttachment(_ part: Part) {
        let panel = NSSavePanel()
        let name = sanitizedFilename(part.filename ?? "attachment")
        panel.nameFieldStringValue = name
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try part.decodedBody().write(to: url)
            } catch {
                showToast("Could not save \(name): \(error.localizedDescription)")
            }
        }
    }

    func downloadAll(_ attachments: [Part]) {
        guard !attachments.isEmpty else { return }
        let dir = downloadsDirectory()
        var saved: [URL] = []
        var failure: String?

        for part in attachments {
            let base = sanitizedFilename(part.filename ?? "attachment")
            let target = uniqueURL(in: dir, filename: base)
            do {
                try part.decodedBody().write(to: target, options: .atomic)
                saved.append(target)
            } catch {
                failure = "Could not save \(base): \(error.localizedDescription)"
            }
        }

        if !saved.isEmpty {
            NSWorkspace.shared.activateFileViewerSelecting(saved)
            let n = saved.count
            if failure == nil {
                showToast("Saved \(n) file\(n == 1 ? "" : "s") to Downloads")
            }
        }
        if let failure { showToast(failure) }
    }

    func showToast(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            do {
                try await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation(.easeOut(duration: 0.25)) { toast = nil }
            } catch { return }
        }
    }

    // MARK: - Helpers

    private func writeToTemp(_ part: Part) -> URL? {
        let base = part.filename ?? "attachment.bin"
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EMLViewer", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let url = uniqueURL(in: tmpDir, filename: base)
        do {
            try part.decodedBody().write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func downloadsDirectory() -> URL {
        if let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            return url
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }

    private func uniqueURL(in dir: URL, filename: String) -> URL {
        let filename = sanitizedFilename(filename)
        var candidate = dir.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

        let ns = filename as NSString
        let name = ns.deletingPathExtension
        let ext = ns.pathExtension
        var i = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let suffix = ext.isEmpty ? " (\(i))" : " (\(i)).\(ext)"
            candidate = dir.appendingPathComponent(name + suffix)
            i += 1
        }
        return candidate
    }

    private func sanitizedFilename(_ filename: String) -> String {
        let component = (filename as NSString).lastPathComponent
        let replaced = String(component.unicodeScalars.map {
            CharacterSet.controlCharacters.contains($0) || $0 == "/" || $0 == ":" ? "_" : Character($0)
        })
        let name = String(replaced.drop(while: { $0 == "." || $0.isWhitespace }))
        return name.isEmpty ? "attachment" : name
    }
}
