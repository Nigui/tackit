import AppKit
import Carbon.HIToolbox
import TackitCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pool: EditorSurfacePool!
    private var panels: [StickyPanel] = []
    private var hotkey: GlobalHotkey?
    private let metrics = LatencyMetrics()
    private var statusItem: NSStatusItem?

    private var store: NoteStore?
    private var openNotes: [UUID: Note] = [:]
    private var saveWork: [UUID: DispatchWorkItem] = [:]
    private let searchIndex = InMemorySearchIndex()
    private lazy var quickOpen = QuickOpenController(index: searchIndex)
    private let windowState = WindowStateStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Diag.log("launch: applicationDidFinishLaunching")
        setupStatusItem()
        setupStore()

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

        quickOpen.onOpen = { [weak self] id in self?.openNote(id: id) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        for note in openNotes.values {
            try? store?.save(note)
        }
    }

    private func setupStore() {
        do {
            let root = try NoteStore.defaultRootURL()
            store = try NoteStore(rootURL: root)
            Diag.log("store at \(root.path)")
        } catch {
            Diag.log("ERROR: store init failed: \(error)")
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "📌"
        let menu = NSMenu()
        menu.addItem(withTitle: "New Sticky", action: #selector(menuNewSticky), keyEquivalent: "")
        menu.addItem(withTitle: "Quick Open…", action: #selector(menuQuickOpen), keyEquivalent: "o")
        menu.addItem(withTitle: "Show / Hide All", action: #selector(menuToggle), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tackit", action: #selector(menuQuit), keyEquivalent: "q")
        for menuItem in menu.items { menuItem.target = self }
        item.menu = menu
        statusItem = item
        Diag.log("status item installed (look for 📌 in the menu bar)")
    }

    @objc private func menuNewSticky() { openNewSticky() }
    @objc private func menuQuickOpen() { openQuickOpen() }
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
            if let last = mostRecentNote() {
                openNewSticky(existing: last)
            } else {
                openNewSticky()
            }
        } else {
            panels.forEach { $0.orderFrontRegardless() }
            focusTop()
        }
    }

    private func mostRecentNote() -> Note? {
        (try? store?.loadAll())?.max(by: { $0.metadata.updatedAt < $1.metadata.updatedAt })
    }

    func openNewSticky(existing: Note? = nil) {
        let note = existing ?? Note()
        if existing == nil { try? store?.save(note) }
        openNotes[note.id] = note

        let surface = pool.acquire()
        surface.onMetric = { [weak self] name, ms in
            self?.metrics.recordKeystroke(ms: ms, first: name == "firstKeystroke")
        }
        surface.onDocChanged = { [weak self] markdown in
            self?.handleDocChanged(id: note.id, markdown: markdown)
        }

        let index = panels.count
        let panel = StickyPanel(surface: surface, index: index, noteId: note.id)
        panels.append(panel)
        panel.onClose = { [weak self, weak panel] in
            guard let self, let panel else { return }
            self.closeSticky(panel)
        }
        panel.onNewNote = { [weak self] in self?.openNewSticky() }
        panel.onQuickOpen = { [weak self] in self?.openQuickOpen() }
        panel.onSwitchTo = { [weak self] number in self?.switchTo(number) }
        panel.onFrameChanged = { [weak self] frame in self?.windowState.save(frame, for: note.id) }
        if let saved = windowState.frame(for: note.id) {
            panel.setFrame(saved, display: false)
        } else {
            panel.placeTopRight(offsetIndex: index)
        }
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        surface.load(markdown: note.body)
        panel.update(note: note)
        surface.focus()

        Diag.log("openNewSticky note=\(note.id) index=\(index) visible=\(panel.isVisible)")
        metrics.printMemory(context: "\(panels.count) sticky(ies) open")
    }

    private func handleDocChanged(id: UUID, markdown: String) {
        guard var note = openNotes[id] else { return }
        note.body = markdown
        note.metadata.updatedAt = Date()
        openNotes[id] = note
        scheduleSave(id)
    }

    private func scheduleSave(_ id: UUID) {
        saveWork[id]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let note = self.openNotes[id] else { return }
            do {
                try self.store?.save(note)
                Diag.log("saved note \(id) (\(note.body.count) chars)")
            } catch {
                Diag.log("ERROR: save failed: \(error)")
            }
        }
        saveWork[id] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func focusTop() {
        guard let top = panels.last else { return }
        top.makeKeyAndOrderFront(nil)
        top.editorSurface.focus()
    }

    private func openQuickOpen() {
        let notes = (try? store?.loadAll()) ?? []
        quickOpen.show(notes: notes)
    }

    private func switchTo(_ number: Int) {
        let visible = panels.filter { $0.isVisible }
        guard (1...visible.count).contains(number) else { return }
        let target = visible[number - 1]
        target.makeKeyAndOrderFront(nil)
        target.orderFrontRegardless()
        target.editorSurface.focus()
    }

    private func openNote(id: UUID) {
        if let existing = panels.first(where: { $0.noteId == id }) {
            existing.makeKeyAndOrderFront(nil)
            existing.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            existing.editorSurface.focus()
            return
        }
        guard let note = try? store?.load(id: id) else { return }
        openNewSticky(existing: note)
    }

    private func closeSticky(_ panel: StickyPanel) {
        Diag.log("close sticky (Cmd+W)")
        let id = panel.noteId
        saveWork[id]?.cancel()
        if let note = openNotes[id] { try? store?.save(note) }
        openNotes[id] = nil

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
