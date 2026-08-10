import WebKit

final class WeakScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}

final class Bridge: NSObject, WKScriptMessageHandler {
    static let channel = "tackit"
    private weak var webView: WKWebView?
    var onEvent: ((String, [String: Any]) -> Void)?

    func attach(to webView: WKWebView, controller: WKUserContentController) {
        self.webView = webView
        controller.add(WeakScriptMessageProxy(self), name: Bridge.channel)
    }

    func send(_ type: String, payload: [String: Any] = [:]) {
        let envelope: [String: Any] = ["v": 1, "id": UUID().uuidString, "type": type, "payload": payload]
        guard JSONSerialization.isValidJSONObject(envelope),
              let data = try? JSONSerialization.data(withJSONObject: envelope),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.__tackitReceive && window.__tackitReceive(\(json))")
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Bridge.channel,
              let body = message.body as? [String: Any],
              (body["v"] as? Int) == 1,
              body["id"] is String,
              let type = body["type"] as? String else {
            Diag.log("bridge: rejected malformed message")
            return
        }
        let payload = (body["payload"] as? [String: Any]) ?? [:]
        onEvent?(type, payload)
    }
}
