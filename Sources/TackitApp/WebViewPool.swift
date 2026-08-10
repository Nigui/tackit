import WebKit

final class WebViewPool {
    private var warm: [WKWebView] = []
    private weak var messageHandler: WKScriptMessageHandler?
    private let size: Int

    var warmCount: Int { warm.count }

    init(size: Int, messageHandler: WKScriptMessageHandler) {
        self.size = size
        self.messageHandler = messageHandler
    }

    func warmUp() {
        scheduleWarm()
    }

    private func scheduleWarm() {
        guard warm.count < size else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.warm.count < self.size else { return }
            let start = CFAbsoluteTimeGetCurrent()
            let webView = self.makeWebView()
            self.warm.append(webView)
            let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
            Diag.log(String(format: "pool warmed %d/%d (create %.0f ms)", self.warm.count, self.size, ms))
            self.scheduleWarm()
        }
    }

    private func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        if let handler = messageHandler {
            controller.add(handler, name: "metrics")
        }
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")

        if let editorDir = Bundle.module.resourceURL?.appendingPathComponent("editor"),
           let indexURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "editor") {
            webView.loadFileURL(indexURL, allowingReadAccessTo: editorDir)
        } else {
            Diag.log("ERROR: editor bundle not found in resources")
        }
        return webView
    }

    func acquire() -> WKWebView {
        let webView: WKWebView
        if warm.isEmpty {
            Diag.log("pool empty on acquire; creating on demand")
            webView = makeWebView()
        } else {
            webView = warm.removeFirst()
        }
        scheduleWarm()
        return webView
    }
}
