import AppKit
import WebKit

protocol EditorSurface: AnyObject {
    var view: NSView { get }
    var onReady: (() -> Void)? { get set }
    var onDocChanged: ((String) -> Void)? { get set }
    var onMetric: ((String, Double) -> Void)? { get set }
    func load(markdown: String)
    func focus()
    func reset()
    func setTheme(dark: Bool)
}

final class WebEditorSurface: EditorSurface {
    let webView: WKWebView
    private let bridge = Bridge()
    private(set) var isReady = false
    private var pending: [() -> Void] = []

    var view: NSView { webView }
    var onReady: (() -> Void)?
    var onDocChanged: ((String) -> Void)?
    var onMetric: ((String, Double) -> Void)?

    init(indexURL: URL?, readAccessURL: URL?, navigationDelegate: WKNavigationDelegate) {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        configuration.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = navigationDelegate
        webView.setValue(false, forKey: "drawsBackground")

        bridge.attach(to: webView, controller: controller)
        bridge.onEvent = { [weak self] type, payload in
            self?.handle(type: type, payload: payload)
        }

        if let indexURL, let readAccessURL {
            webView.loadFileURL(indexURL, allowingReadAccessTo: readAccessURL)
        } else {
            Diag.log("ERROR: editor bundle not found in resources")
        }
    }

    private func handle(type: String, payload: [String: Any]) {
        switch type {
        case "ready":
            isReady = true
            let queued = pending
            pending.removeAll()
            queued.forEach { $0() }
            onReady?()
        case "docChanged":
            if let markdown = payload["markdown"] as? String { onDocChanged?(markdown) }
        case "metric":
            if let name = payload["name"] as? String, let ms = payload["ms"] as? Double { onMetric?(name, ms) }
        default:
            break
        }
    }

    private func whenReady(_ block: @escaping () -> Void) {
        if isReady { block() } else { pending.append(block) }
    }

    func load(markdown: String) {
        whenReady { [weak self] in self?.bridge.send("load", payload: ["markdown": markdown]) }
    }

    func focus() {
        whenReady { [weak self] in self?.bridge.send("focus") }
    }

    func reset() {
        whenReady { [weak self] in self?.bridge.send("reset") }
    }

    func setTheme(dark: Bool) {
        whenReady { [weak self] in self?.bridge.send("theme", payload: ["dark": dark]) }
    }
}
