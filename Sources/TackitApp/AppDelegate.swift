import AppKit
import Carbon.HIToolbox
import WebKit
import TackitCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pool: WebViewPool!
    private var panels: [StickyPanel] = []
    private var hotkey: GlobalHotkey?
    private let metrics = LatencyMetrics()
    private var lastShowTime: CFAbsoluteTime = 0
    private var statusItem: NSStatusItem?
    private var pendingFocus: WKWebView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Diag.log("launch: applicationDidFinishLaunching")
        setupStatusItem()
        pool = WebViewPool(size: 3, messageHandler: self)

        let dotKeyCode = KeyboardLayout.keyCode(for: ".") ?? UInt32(kVK_ANSI_Period)
        Diag.log("resolved '.' keyCode=\(dotKeyCode) (ANSI period=\(kVK_ANSI_Period))")
        hotkey = GlobalHotkey(
            keyCode: dotKeyCode,
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [weak self] in
            Diag.log("hotkey fired (Cmd+Shift+.)")
            self?.toggleStickies()
        }

        Diag.log("ready + hotkey live (pool warming async). Press Cmd+Shift+.")
        pool.warmUp()
        metrics.printMemory(context: "launch")
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "📌"
        let menu = NSMenu()
        menu.addItem(withTitle: "New Sticky", action: #selector(menuNewSticky), keyEquivalent: "")
        menu.addItem(withTitle: "Show / Hide All", action: #selector(menuToggle), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tackit", action: #selector(menuQuit), keyEquivalent: "q")
        for menuItem in menu.items { menuItem.target = self }
        item.menu = menu
        statusItem = item
        Diag.log("status item installed (look for 📌 in the menu bar)")
    }

    @objc private func menuNewSticky() { openNewSticky() }
    @objc private func menuToggle() { toggleStickies() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    private func toggleStickies() {
        if panels.contains(where: { $0.isVisible }) {
            Diag.log("toggle: hiding \(panels.count) panel(s)")
            panels.forEach { $0.orderOut(nil) }
            return
        }
        if panels.isEmpty {
            openNewSticky()
        } else {
            lastShowTime = CFAbsoluteTimeGetCurrent()
            panels.forEach { $0.orderFrontRegardless() }
            focusTop()
        }
    }

    func openNewSticky() {
        lastShowTime = CFAbsoluteTimeGetCurrent()
        let webView = pool.acquire()
        let index = panels.count
        let panel = StickyPanel(webView: webView, index: index)
        panels.append(panel)
        panel.onClose = { [weak self, weak panel] in
            guard let self, let panel else { return }
            self.closeSticky(panel)
        }
        panel.onNewNote = { [weak self] in self?.openNewSticky() }
        panel.placeTopRight(offsetIndex: index)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        pendingFocus = webView
        requestFocus(webView)
        let screenInfo = NSScreen.main.map { NSStringFromRect($0.visibleFrame) } ?? "nil"
        Diag.log("openNewSticky index=\(index) frame=\(NSStringFromRect(panel.frame)) visible=\(panel.isVisible) screen=\(screenInfo)")
        metrics.printMemory(context: "\(panels.count) sticky(ies) open")
    }

    private func focusTop() {
        guard let top = panels.last else { return }
        top.makeKeyAndOrderFront(nil)
        pendingFocus = top.editorWebView
        requestFocus(top.editorWebView)
    }

    private func requestFocus(_ webView: WKWebView) {
        webView.evaluateJavaScript("window.focusEditor ? (window.focusEditor(), true) : false")
    }

    private func closeSticky(_ panel: StickyPanel) {
        Diag.log("close sticky (Cmd+W)")
        panel.orderOut(nil)
        if let index = panels.firstIndex(where: { $0 === panel }) {
            panels.remove(at: index)
        }
        panel.close()
    }
}

extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let event = body["event"] as? String else { return }
        switch event {
        case "editorCreated":
            Diag.log("editor bundle loaded in a webview")
            if let webView = message.webView, webView === pendingFocus {
                requestFocus(webView)
            }
        case "focused":
            let deltaMs = (CFAbsoluteTimeGetCurrent() - lastShowTime) * 1000
            metrics.recordReadiness(ms: deltaMs)
        case "firstKeystroke", "keystroke":
            if let latency = body["latency"] as? Double {
                metrics.recordKeystroke(ms: latency, first: event == "firstKeystroke")
            }
        default:
            break
        }
    }
}
