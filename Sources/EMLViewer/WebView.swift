import SwiftUI
import WebKit
import EMLCore

struct WebView: NSViewRepresentable {
    let html: String
    let message: LoadedMessage
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
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        let zoom = fontSize / 13
        if view.pageZoom != zoom { view.pageZoom = zoom }
        if context.coordinator.loadedID != message.id || context.coordinator.loadedFont != fontFamily {
            context.coordinator.handler?.message = message.message
            view.loadHTMLString(wrappedHTML(html), baseURL: URL(string: "cid:/"))
            context.coordinator.loadedID = message.id
            context.coordinator.loadedFont = fontFamily
        }
    }

    private func wrappedHTML(_ inner: String) -> String {
        let family = fontFamily == "System" ? "-apple-system" : "\"\(fontFamily)\""
        let style = "<style>body{font-family:\(family);}</style>"
        if inner.range(of: "<html\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            if let head = inner.range(of: "<head\\b[^>]*>", options: [.regularExpression, .caseInsensitive]) {
                var document = inner
                document.insert(contentsOf: style, at: head.upperBound)
                return document
            }
            if let html = inner.range(of: "<html\\b[^>]*>", options: [.regularExpression, .caseInsensitive]) {
                var document = inner
                document.insert(contentsOf: "<head>\(style)</head>", at: html.upperBound)
                return document
            }
        }
        return """
        <!doctype html>
        <html><head><meta charset="utf-8">
        <style>body{font-family:\(family);padding:16px;color:#222;}</style>
        </head><body>\(inner)</body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var handler: CIDSchemeHandler?
        var loadedID: UUID?
        var loadedFont: String?

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
