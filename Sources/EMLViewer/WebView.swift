import SwiftUI
import WebKit
import EMLCore

struct WebView: NSViewRepresentable {
    let html: String
    let message: LoadedMessage
    @Environment(\.colorScheme) private var scheme
    @AppStorage(AppPreferences.appearance) private var appearance = Theme.system
    private var palette: ThemePalette { appearance.palette(scheme) }
    @AppStorage(AppPreferences.fontSize) private var fontSize = 13.0
    @AppStorage(AppPreferences.fontFamily) private var fontFamily = AppPreferences.defaultFont

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let handler = CIDSchemeHandler()
        config.setURLSchemeHandler(handler, forURLScheme: "cid")
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        context.coordinator.handler = handler

        let view = WKWebView(frame: .zero, configuration: config)
        view.underPageBackgroundColor = palette.nsColor(palette.background)
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        view.underPageBackgroundColor = palette.nsColor(palette.background)
        let zoom = fontSize / 13
        if view.pageZoom != zoom { view.pageZoom = zoom }
        if context.coordinator.loadedID != message.id || context.coordinator.loadedFont != fontFamily
            || context.coordinator.loadedTheme != appearance || context.coordinator.loadedScheme != scheme {
            context.coordinator.handler?.message = message.message
            view.loadHTMLString(wrappedHTML(html), baseURL: URL(string: "cid:/"))
            context.coordinator.loadedID = message.id
            context.coordinator.loadedFont = fontFamily
            context.coordinator.loadedTheme = appearance
            context.coordinator.loadedScheme = scheme
        }
    }

    private func wrappedHTML(_ inner: String) -> String {
        let family = fontFamily == "System" ? "-apple-system" : "\"\(fontFamily)\""
        let dark = appearance == .system ? scheme == .dark : appearance.isDark
        let style = """
        <style>
        :root{color-scheme:\(dark ? "dark" : "light")}
        html,body{background:\(palette.background) !important;color:\(palette.text) !important}
        body{font-family:\(family)}
        body :where(*:not(img):not(svg):not(video):not(picture)){color:inherit !important;
        background-color:transparent !important;border-color:\(palette.border) !important}
        a,a *{color:\(palette.link) !important}
        blockquote{border-left:3px solid \(palette.border) !important;color:\(palette.secondaryText) !important;padding-left:10px}
        hr{border-color:\(palette.border) !important}
        </style>
        """
        if let headEnd = inner.range(of: "</head\\s*>", options: [.regularExpression, .caseInsensitive]) {
            var document = inner
            document.insert(contentsOf: style, at: headEnd.lowerBound)
            return document
        }
        if let body = inner.range(of: "<body\\b[^>]*>", options: [.regularExpression, .caseInsensitive]) {
            var document = inner
            document.insert(contentsOf: style, at: body.upperBound)
            return document
        }
        return "<!doctype html><html><head><meta charset=\"utf-8\">\(style)</head><body>\(inner)</body></html>"
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var handler: CIDSchemeHandler?
        var loadedID: UUID?
        var loadedFont: String?
        var loadedTheme: Theme?
        var loadedScheme: ColorScheme?

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow); return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if navigationAction.navigationType == .linkActivated,
               ["http", "https", "mailto"].contains(scheme) {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

final class CIDSchemeHandler: NSObject, WKURLSchemeHandler {
    var message: Message?

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(NSError(domain: "cid", code: -1))
            return
        }
        let raw = url.absoluteString
        let cid = raw
            .replacingOccurrences(of: "cid:/", with: "")
            .replacingOccurrences(of: "cid:", with: "")
            .removingPercentEncoding ?? ""

        guard !cid.isEmpty, let part = message?.partByContentID(cid) else {
            task.didFailWithError(NSError(domain: "cid", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "cid not found: \(cid)"
            ]))
            return
        }
        let data = part.decodedBody()
        let response = URLResponse(
            url: url,
            mimeType: part.contentType,
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
