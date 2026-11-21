import SwiftUI
import AppKit
import UniformTypeIdentifiers
import EMLCore

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage(AppPreferences.appearance) private var appearance = AppearanceMode.system

    var body: some View {
        ZStack {
            if let msg = state.message {
                MessageView(message: msg).id(msg.id)
            } else {
                WelcomeView()
            }
            ToastOverlay()
        }
        .background(Color(nsColor: .textBackgroundColor))
        .background(WindowAccessor())
        .onChange(of: appearance) { _, mode in
            mode.applyToApp()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Drop

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url = url else { return }
            Task { @MainActor in state.open(url) }
        }
        return true
    }
}

struct WindowAccessor: NSViewRepresentable {
    final class WindowView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, window.frameAutosaveName != "EMLViewerMainWindow" else { return }
            window.setFrameAutosaveName("EMLViewerMainWindow")
            window.setFrameUsingName("EMLViewerMainWindow")
        }
    }

    func makeNSView(context: Context) -> WindowView { WindowView() }

    func updateNSView(_ nsView: WindowView, context: Context) {}
}

// MARK: - Toast

struct ToastOverlay: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack {
            Spacer()
            if let text = state.toast {
                Text(text)
                    .font(.callout)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: state.toast)
        .allowsHitTesting(false)
    }
}

// MARK: - Message

struct MessageView: View {
    let message: LoadedMessage

    var body: some View {
        VStack(spacing: 0) {
            HeaderPanel(message: message.message)
            Divider().opacity(0.6)
            BodyView(message: message)
            if !message.attachments.isEmpty {
                Divider().opacity(0.6)
                AttachmentsBar(attachments: message.attachments)
            }
        }
    }
}

struct HeaderPanel: View {
    let message: Message
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(message.subject.isEmpty ? "(no subject)" : message.subject)
                    .font(.title2.weight(.semibold))
                    .textSelection(.enabled)
                    .lineLimit(3)
                Spacer()
                SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.borderless)
                    .help("Settings")
            }

            VStack(alignment: .leading, spacing: 3) {
                row("From", message.from)
                row("To", message.to)
                row("Cc", message.cc)
                row("Date", message.sentDate?.formatted(
                    Date.FormatStyle(locale: locale, timeZone: .current)
                        .weekday(.abbreviated).day().month(.abbreviated).year().hour().minute()
                ) ?? message.date)
            }
            .font(.system(size: 12))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        if !value.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
                Text(value)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct BodyView: View {
    let message: LoadedMessage
    @AppStorage(AppPreferences.fontSize) private var fontSize = 13.0
    @AppStorage(AppPreferences.fontFamily) private var fontFamily = AppPreferences.defaultFont

    var body: some View {
        Group {
            if let html = message.message.htmlBody {
                WebView(html: html, message: message)
            } else if let plain = message.message.plainBody {
                ScrollView {
                    Text(plain)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .font(AppPreferences.font(fontFamily, size: fontSize))
                }
            } else {
                Text("(no body)")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Attachments

struct AttachmentsBar: View {
    let attachments: [AttachmentItem]
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(attachments.count) attachment\(attachments.count == 1 ? "" : "s")")
                Spacer()
                Button {
                    state.saveAll(attachments.map(\.part))
                } label: {
                    Label("Save All…", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.borderless)
                .help("Save all attachments to a folder")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(attachments) { item in
                        AttachmentChip(item: item)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 12)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct AttachmentChip: View {
    let item: AttachmentItem
    @EnvironmentObject var state: AppState
    @State private var hovered = false
    private var part: Part { item.part }

    var body: some View {
        Button(action: { state.openAttachment(part) }) {
            HStack(spacing: 10) {
                FileIcon(part: part)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(part.filename ?? "attachment")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .leading)
                    Text(item.sizeText)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(hovered ? 0.45 : 0.18))
            )
            .shadow(color: .black.opacity(hovered ? 0.08 : 0.0), radius: 3, y: 1)
            .scaleEffect(hovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.12), value: hovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .contextMenu {
            Button("Open") { state.openAttachment(part) }
            Button("Save As…") { state.saveAsAttachment(part) }
        }
        .help("Open \(part.filename ?? "attachment")")
    }
}

// MARK: - System file icon

struct FileIcon: View {
    let part: Part

    var body: some View {
        Image(nsImage: icon())
            .resizable()
            .scaledToFit()
    }

    private func icon() -> NSImage {
        let ws = NSWorkspace.shared
        if let name = part.filename {
            let ext = (name as NSString).pathExtension
            if !ext.isEmpty, let type = UTType(filenameExtension: ext) {
                return ws.icon(for: type)
            }
        }
        if let type = UTType(mimeType: part.contentType) {
            return ws.icon(for: type)
        }
        return ws.icon(for: .data)
    }
}
