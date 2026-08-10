import AppKit
import Carbon.HIToolbox
import TackitCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pool: EditorSurfacePool!
    private var panels: [StickyPanel] = []
    private var hotkey: GlobalHotkey?
    private let metrics = LatencyMetrics()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Diag.log("launch: applicationDidFinishLaunching")
        setupStatusItem()

        let dotKeyCode = KeyboardLayout.keyCode(for: ".") ?? UInt32(kVK_ANSI_Period)
        Diag.log("resolved '.' keyCode=\(dotKeyCode) (ANSI period=\(kVK_ANSI_Period))")
        hotkey = GlobalHotkey(
            keyCode: dotKeyCode,
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [weak self] in
            Diag.log("hotkey fired (Cmd+Shift+.)")
            self?.toggleStickies()
        }
        if hotkey?.isRegistered != true {
            reportHotkeyFailure()
        }
        Diag.log("ready + hotkey live (pool warming async). Press Cmd+Shift+.")

        pool = EditorSurfacePool(size: 3)
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

    private func reportHotkeyFailure() {
        Diag.log("ERROR: global hotkey NOT registered — surfacing to user")
        statusItem?.button?.title = "📌⚠️"
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Tackit couldn’t register its global shortcut"
        alert.informativeText = "⌘⇧. may be in use by another app. You can still open notes from the 📌 menu; a rebindable shortcut is coming."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func toggleStickies() {
        if panels.contains(where: { $0.isVisible }) {
            Diag.log("toggle: hiding \(panels.count) panel(s)")
            panels.forEach { $0.orderOut(nil) }
            return
        }
        if panels.isEmpty {
            openNewSticky()
        } else {
            panels.forEach { $0.orderFrontRegardless() }
            focusTop()
        }
    }

    func openNewSticky() {
        let surface = pool.acquire()
        surface.onMetric = { [weak self] name, ms in
            self?.metrics.recordKeystroke(ms: ms, first: name == "firstKeystroke")
        }
        surface.onDocChanged = { markdown in
            Diag.log("docChanged (\(markdown.count) chars) — persistence lands in M1.1")
        }

        let index = panels.count
        let panel = StickyPanel(surface: surface, index: index)
        panels.append(panel)
        panel.onClose = { [weak self, weak panel] in
            guard let self, let panel else { return }
            self.closeSticky(panel)
        }
        panel.onNewNote = { [weak self] in self?.openNewSticky() }
        panel.placeTopRight(offsetIndex: index)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        surface.focus()

        Diag.log("openNewSticky index=\(index) frame=\(NSStringFromRect(panel.frame)) visible=\(panel.isVisible)")
        metrics.printMemory(context: "\(panels.count) sticky(ies) open")
    }

    private func focusTop() {
        guard let top = panels.last else { return }
        top.makeKeyAndOrderFront(nil)
        top.editorSurface.focus()
    }

    private func closeSticky(_ panel: StickyPanel) {
        Diag.log("close sticky (Cmd+W)")
        panel.orderOut(nil)
        if let index = panels.firstIndex(where: { $0 === panel }) {
            panels.remove(at: index)
        }
        let surface = panel.editorSurface
        surface.view.removeFromSuperview()
        if let webSurface = surface as? WebEditorSurface {
            pool.release(webSurface)
        }
        panel.close()
    }
}
