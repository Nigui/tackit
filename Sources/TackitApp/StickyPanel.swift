import AppKit
import TackitCore

final class StickyPanel: NSPanel {
    let editorSurface: EditorSurface
    private(set) var noteId: UUID
    var onClose: (() -> Void)?
    var onNewNote: (() -> Void)?
    var onSwitchTo: ((Int) -> Void)?
    var onFrameChanged: ((NSRect) -> Void)?
    var onRequestGroups: (() -> [String])?
    var onFilePath: (() -> String)?
    var onMetadataCommit: ((NoteMetadata) -> Void)?
    var onDelete: (() -> Void)?
    var onSearch: ((String) -> [NoteSearchResult])?
    var onOpenNote: ((UUID, Bool) -> Void)?
    var onSettings: (() -> Void)?
    var shortcuts: [AppShortcut: KeyCombo] = [:]
    private var header: NoteHeaderView?
    private var footer: NoteFooterView?
    private var currentNote: Note?
    private var overlay: MetadataOverlay?
    private var actionMenu: ActionMenuOverlay?
    private var searchOverlay: SearchOverlay?
    private let card = CardView()
    private let headerHeight: CGFloat = 96
    private let footerHeight: CGFloat = 32

    init(surface: EditorSurface, index: Int, noteId: UUID) {
        self.editorSurface = surface
        self.noteId = noteId
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        contentMinSize = NSSize(width: 260, height: 220)

        guard let content = contentView else { return }
        content.wantsLayer = true

        card.frame = content.bounds
        card.autoresizingMask = [.width, .height]
        content.addSubview(card)

        let bounds = card.bounds
        let headerView = NoteHeaderView(frame: NSRect(x: 0, y: bounds.height - headerHeight, width: bounds.width, height: headerHeight))
        headerView.autoresizingMask = [.width, .minYMargin]
        card.addSubview(headerView)
        header = headerView

        let editorView = surface.view
        editorView.frame = NSRect(x: 0, y: footerHeight, width: bounds.width, height: bounds.height - headerHeight - footerHeight)
        editorView.autoresizingMask = [.width, .height]
        card.addSubview(editorView)

        let footerView = NoteFooterView()
        footerView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: footerHeight)
        footerView.autoresizingMask = [.width, .maxYMargin]
        card.addSubview(footerView)
        footer = footerView

        applyFocusState(true)
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private var cmdDragOrigin: NSPoint?
    private var cmdWindowOrigin: NSPoint?

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown where event.modifierFlags.contains(.command):
            cmdDragOrigin = NSEvent.mouseLocation
            cmdWindowOrigin = frame.origin
            return
        case .leftMouseDragged where cmdDragOrigin != nil:
            let now = NSEvent.mouseLocation
            setFrameOrigin(NSPoint(
                x: cmdWindowOrigin!.x + (now.x - cmdDragOrigin!.x),
                y: cmdWindowOrigin!.y + (now.y - cmdDragOrigin!.y)
            ))
            return
        case .leftMouseUp where cmdDragOrigin != nil:
            cmdDragOrigin = nil
            cmdWindowOrigin = nil
            onFrameChanged?(frame)
            return
        default:
            break
        }
        super.sendEvent(event)
    }

    private func applyFocusState(_ focused: Bool) {
        card.focusedState = focused
    }

    private static let numberKeyCodes: [UInt16: Int] = [
        18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9,
    ]

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        if !event.modifierFlags.contains(.shift), let number = StickyPanel.numberKeyCodes[event.keyCode] {
            onSwitchTo?(number)
            return true
        }
        if event.keyCode == 51 {
            onDelete?()
            return true
        }
        let mods = ShortcutRecorderView.carbonModifiers(from: event.modifierFlags)
        for action in AppShortcut.allCases {
            if let combo = shortcuts[action], combo.keyCode == UInt32(event.keyCode), combo.modifiers == mods {
                run(action)
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    private func run(_ action: AppShortcut) {
        switch action {
        case .configure: showMetadata(focus: .title)
        case .search: toggleSearch()
        case .newNote: onNewNote?()
        case .closeNote: onClose?()
        case .actionMenu: handleCommandK()
        }
    }

    private func hint(_ action: AppShortcut) -> String {
        guard let combo = shortcuts[action] else { return "" }
        return ShortcutRecorderView.display(combo)
    }

    private func handleCommandK() {
        if let overlay, !overlay.isHidden {
            dismissMetadata()
        } else if let actionMenu, !actionMenu.isHidden {
            dismissActionMenu()
        } else if let searchOverlay, !searchOverlay.isHidden {
            dismissSearch()
        } else {
            showActionMenu()
        }
    }

    private func showActionMenu() {
        dismissMetadata()
        dismissSearch()
        let view = actionMenu ?? makeActionMenu()
        view.present(actions: buildActions())
    }

    private func buildActions() -> [MenuAction] {
        [
            MenuAction(title: "Configure note", hint: hint(.configure)) { [weak self] in self?.showMetadata(focus: .title) },
            MenuAction(title: "Search notes", hint: hint(.search)) { [weak self] in self?.showSearch() },
            MenuAction(title: "New note", hint: hint(.newNote)) { [weak self] in self?.onNewNote?() },
            MenuAction(title: "Close note", hint: hint(.closeNote)) { [weak self] in self?.onClose?() },
            MenuAction(title: "Delete note", hint: "⌘⌫") { [weak self] in self?.onDelete?() },
            MenuAction(title: "Settings", hint: "") { [weak self] in self?.onSettings?() },
        ]
    }

    private func showMetadata(focus: MetadataField) {
        dismissActionMenu()
        dismissSearch()
        guard let note = currentNote else { return }
        let view = overlay ?? makeOverlay()
        view.present(
            metadata: note.metadata,
            groups: onRequestGroups?() ?? [],
            filePath: onFilePath?() ?? "",
            focus: focus
        )
    }

    private func toggleSearch() {
        if let searchOverlay, !searchOverlay.isHidden {
            dismissSearch()
        } else {
            showSearch()
        }
    }

    private func showSearch() {
        dismissMetadata()
        dismissActionMenu()
        let view = searchOverlay ?? makeSearchOverlay()
        view.present()
    }

    private func makeOverlay() -> MetadataOverlay {
        let view = MetadataOverlay(frame: card.bounds)
        view.autoresizingMask = [.width, .height]
        view.onCommit = { [weak self] meta in self?.onMetadataCommit?(meta) }
        view.onClose = { [weak self] in self?.dismissMetadata() }
        card.addSubview(view)
        overlay = view
        return view
    }

    private func makeActionMenu() -> ActionMenuOverlay {
        let view = ActionMenuOverlay(frame: card.bounds)
        view.autoresizingMask = [.width, .height]
        view.onClose = { [weak self] in self?.dismissActionMenu() }
        card.addSubview(view)
        actionMenu = view
        return view
    }

    private func makeSearchOverlay() -> SearchOverlay {
        let view = SearchOverlay(frame: card.bounds)
        view.autoresizingMask = [.width, .height]
        view.onQuery = { [weak self] query in self?.onSearch?(query) ?? [] }
        view.onOpen = { [weak self] id, inNewPanel in self?.onOpenNote?(id, inNewPanel) }
        view.onClose = { [weak self] in self?.dismissSearch() }
        card.addSubview(view)
        searchOverlay = view
        return view
    }

    private func dismissMetadata() {
        overlay?.isHidden = true
        editorSurface.focus()
    }

    private func dismissActionMenu() {
        actionMenu?.isHidden = true
        editorSurface.focus()
    }

    private func dismissSearch() {
        searchOverlay?.isHidden = true
        editorSurface.focus()
    }

    func update(note: Note) {
        currentNote = note
        header?.configure(
            icon: note.metadata.icon,
            title: NoteDisplay.title(for: note),
            description: NoteDisplay.description(for: note),
            category: NoteDisplay.category(for: note),
            tags: note.metadata.tags
        )
        footer?.setUpdated(note.metadata.updatedAt)
    }

    func rebind(noteId: UUID) {
        self.noteId = noteId
    }
}

extension StickyPanel: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) { onFrameChanged?(frame) }
    func windowDidResize(_ notification: Notification) { onFrameChanged?(frame) }

    func windowDidBecomeKey(_ notification: Notification) {
        applyFocusState(true)
    }

    func windowDidResignKey(_ notification: Notification) {
        applyFocusState(false)
    }
}
