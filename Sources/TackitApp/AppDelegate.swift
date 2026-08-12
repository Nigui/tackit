import AppKit
import Carbon.HIToolbox
import TackitCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pool: EditorSurfacePool!
    private var panels: [StickyPanel] = []
    private var hotkey: GlobalHotkey?
    private var registeredCombo: KeyCombo?
    private let metrics = LatencyMetrics()
    private var statusItem: NSStatusItem?

    private var store: NoteStore?
    private var openNotes: [UUID: Note] = [:]
    private var saveWork: [UUID: DispatchWorkItem] = [:]
    private let searchIndex = InMemorySearchIndex()
    private let windowState = WindowStateStore()
    private let undoToast = UndoToast()
    private let settings = SettingsStore()
    private var settingsController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Diag.log("launch: applicationDidFinishLaunching")
        setupStatusItem()
        setupStore()

        installHotkey()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: SettingsStore.didChange,
            object: nil
        )
        Diag.log("ready + hotkey live (pool warming async)")

        pool = EditorSurfacePool(size: 3)
        pool.warmUp()
        metrics.printMemory(context: "launch")
    }

    private func installHotkey() {
        hotkey = nil // release the previous registration before registering the new combo
        let combo = settings.globalHotkey
        let newHotkey = GlobalHotkey(
            keyCode: combo.keyCode,
            modifiers: combo.modifiers
        ) { [weak self] in
            Diag.log("hotkey fired")
            self?.toggleStickies()
        }
        hotkey = newHotkey
        if newHotkey.isRegistered {
            registeredCombo = combo
            statusItem?.button?.title = "📌"
        } else {
            reportHotkeyFailure()
        }
    }

    private func suspendHotkey() { hotkey = nil }
    private func resumeHotkey() { installHotkey() }

    @objc private func settingsChanged() {
        if settings.globalHotkey != registeredCombo {
            installHotkey()
        }
        let level: NSWindow.Level = settings.alwaysOnTop ? .floating : .normal
        let bindings = settings.allBindings()
        for panel in panels {
            panel.level = level
            panel.shortcuts = bindings
        }
    }

    private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(
                settings: settings,
                onRecordingChange: { [weak self] recording in
                    if recording { self?.suspendHotkey() } else { self?.resumeHotkey() }
                }
            )
        }
        settingsController?.show()
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
        menu.addItem(withTitle: "Show / Hide All", action: #selector(menuToggle), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…", action: #selector(menuSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tackit", action: #selector(menuQuit), keyEquivalent: "q")
        for menuItem in menu.items { menuItem.target = self }
        item.menu = menu
        statusItem = item
        Diag.log("status item installed (look for 📌 in the menu bar)")
    }

    @objc private func menuNewSticky() { openNewSticky() }
    @objc private func menuToggle() { toggleStickies() }
    @objc private func menuSettings() { openSettings() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    private func reportHotkeyFailure() {
        Diag.log("ERROR: global hotkey NOT registered — surfacing to user")
        statusItem?.button?.title = "📌⚠️"
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Tackit couldn’t register its global shortcut"
        alert.informativeText = "The shortcut may be in use by another app. Open notes from the 📌 menu, and set a different shortcut in Settings (⌘,)."
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
        panel.onSwitchTo = { [weak self] number in self?.switchTo(number) }
        panel.onFrameChanged = { [weak self] frame in self?.windowState.save(frame, for: note.id) }
        panel.onRequestGroups = { [weak self] in self?.allGroups() ?? [] }
        panel.onFilePath = { [weak self] in self?.store?.fileURL(for: note.id).path ?? "" }
        panel.onMetadataCommit = { [weak self] meta in self?.applyMetadata(id: note.id, meta: meta) }
        panel.onDelete = { [weak self] in self?.requestDelete(id: note.id) }
        panel.onSearch = { [weak self] query in self?.searchNotes(query) ?? [] }
        panel.onOpenNote = { [weak self, weak panel] id, inNewPanel in
            self?.openFromSearch(selectedId: id, from: panel, inNewPanel: inNewPanel)
        }
        panel.onSettings = { [weak self] in self?.openSettings() }
        panel.shortcuts = settings.allBindings()
        panel.level = settings.alwaysOnTop ? .floating : .normal
        if let saved = windowState.frame(for: note.id) {
            panel.setFrame(saved, display: false)
        } else {
            panel.setContentSize(settings.defaultSize)
            if let screen = NSScreen.main ?? NSScreen.screens.first {
                let stagger = CGFloat(index) * 28
                let origin = settings.origin(for: settings.placement, size: panel.frame.size, in: screen.visibleFrame, stagger: stagger)
                panel.setFrameOrigin(origin)
            }
        }
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        surface.load(markdown: note.body)
        panel.update(note: note)
        surface.focus()

        Diag.log("openNewSticky note=\(note.id) index=\(index) visible=\(panel.isVisible)")
        metrics.printMemory(context: "\(panels.count) sticky(ies) open")
    }

    private func requestDelete(id: UUID) {
        guard let note = openNotes[id] ?? (try? store?.load(id: id)) else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Delete this note?"
        alert.informativeText = "“\(NoteDisplay.title(for: note))” will be removed from disk. You can undo for a few seconds."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        if let panel = panels.first(where: { $0.noteId == id }) {
            closeSticky(panel)
        }
        try? store?.delete(id: id)
        searchIndex.remove(id: id)
        openNotes[id] = nil

        undoToast.show(message: "Note deleted — click or ⌘Z to undo") { [weak self] in
            guard let self else { return }
            try? self.store?.save(note)
            self.searchIndex.upsert(note)
            self.openNote(id: note.id)
        }
    }

    private func searchNotes(_ query: String) -> [NoteSearchResult] {
        let notes = (try? store?.loadAll()) ?? []
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let matched: [Note]
        if q.isEmpty {
            matched = notes
        } else {
            matched = notes.filter { note in
                NoteDisplay.title(for: note).lowercased().contains(q)
                    || note.metadata.description.lowercased().contains(q)
                    || note.body.lowercased().contains(q)
                    || note.metadata.tags.contains { $0.lowercased().contains(q) }
            }
        }
        return matched
            .sorted { $0.metadata.updatedAt > $1.metadata.updatedAt }
            .prefix(50)
            .map { note in
                NoteSearchResult(
                    id: note.id,
                    icon: note.metadata.icon,
                    title: NoteDisplay.title(for: note),
                    description: note.metadata.description,
                    updatedAt: note.metadata.updatedAt
                )
            }
    }

    private func openFromSearch(selectedId: UUID, from currentPanel: StickyPanel?, inNewPanel: Bool) {
        if inNewPanel {
            openNote(id: selectedId)
            return
        }
        guard let currentPanel else { openNote(id: selectedId); return }
        if selectedId == currentPanel.noteId { return }
        if let other = panels.first(where: { $0.noteId == selectedId }) {
            other.makeKeyAndOrderFront(nil)
            other.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            other.editorSurface.focus()
            return
        }
        guard let selected = try? store?.load(id: selectedId) else { return }
        let oldId = currentPanel.noteId
        saveWork[oldId]?.cancel()
        if let oldNote = openNotes[oldId] { try? store?.save(oldNote) }
        openNotes[oldId] = nil
        openNotes[selectedId] = selected
        rebind(panel: currentPanel, to: selected)
    }

    private func rebind(panel: StickyPanel, to note: Note) {
        panel.rebind(noteId: note.id)
        let surface = panel.editorSurface
        surface.onDocChanged = { [weak self] markdown in self?.handleDocChanged(id: note.id, markdown: markdown) }
        panel.onFrameChanged = { [weak self] frame in self?.windowState.save(frame, for: note.id) }
        panel.onFilePath = { [weak self] in self?.store?.fileURL(for: note.id).path ?? "" }
        panel.onMetadataCommit = { [weak self] meta in self?.applyMetadata(id: note.id, meta: meta) }
        panel.onDelete = { [weak self] in self?.requestDelete(id: note.id) }
        panel.onOpenNote = { [weak self, weak panel] id, inNewPanel in
            self?.openFromSearch(selectedId: id, from: panel, inNewPanel: inNewPanel)
        }
        windowState.save(panel.frame, for: note.id)
        surface.load(markdown: note.body)
        panel.update(note: note)
        surface.focus()
    }

    private func allGroups() -> [String] {
        let notes = (try? store?.loadAll()) ?? []
        let groups = Set(notes.compactMap { $0.metadata.group }.filter { !$0.isEmpty })
        return groups.sorted()
    }

    private func applyMetadata(id: UUID, meta: NoteMetadata) {
        guard var note = openNotes[id] else { return }
        var updated = meta
        updated.createdAt = note.metadata.createdAt
        updated.updatedAt = Date()
        note.metadata = updated
        openNotes[id] = note
        panels.first(where: { $0.noteId == id })?.update(note: note)
        searchIndex.upsert(note)
        scheduleSave(id)
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
