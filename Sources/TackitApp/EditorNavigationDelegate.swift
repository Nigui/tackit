import AppKit
import WebKit

final class EditorNavigationDelegate: NSObject, WKNavigationDelegate {
    private let basePath: String

    init(baseDirectory: URL) {
        self.basePath = baseDirectory.standardizedFileURL.path
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.isFileURL {
            if url.standardizedFileURL.path.hasPrefix(basePath) {
                decisionHandler(.allow)
            } else {
                Diag.log("blocked file navigation: \(url.path)")
                decisionHandler(.cancel)
            }
            return
        }

        if let scheme = url.scheme?.lowercased(), ["http", "https", "mailto"].contains(scheme) {
            NSWorkspace.shared.open(url)
        } else {
            Diag.log("blocked navigation: \(url.absoluteString)")
        }
        decisionHandler(.cancel)
    }
}
