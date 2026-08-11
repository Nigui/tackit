import AppKit
import TackitCore

final class StickyPanel: NSPanel {
    let editorSurface: EditorSurface
    let noteId: UUID
    var onClose: (() -> Void)?
    var onNewNote: (() -> Void)?
    var onQuickOpen: (() -> Void)?
    var onSwitchTo: ((Int) -> Void)?
    var onFrameChanged: ((NSRect) -> Void)?
    var onRequestGroups: (() -> [String])?
    var onFilePath: (() -> String)?
    var onMetadataCommit: ((NoteMetadata) -> Void)?
    private var header: NoteHeaderView?
    private var currentNote: Note?
    private var overlay: MetadataOverlay?
    private let card = CardView()
    private let headerHeight: CGFloat = 96

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
        editorView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - headerHeight)
        editorView.autoresizingMask = [.width, .height]
        card.addSubview(editorView)

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
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "w": onClose?(); return true
        case "n": onNewNote?(); return true
        case "o": onQuickOpen?(); return true
        case "k": toggleMetadata(); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }

    private func toggleMetadata() {
        if let overlay, !overlay.isHidden {
            dismissMetadata()
            return
        }
        guard let note = currentNote else { return }
        let view = overlay ?? makeOverlay()
        view.present(
            metadata: note.metadata,
            groups: onRequestGroups?() ?? [],
            filePath: onFilePath?() ?? ""
        )
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

    private func dismissMetadata() {
        overlay?.isHidden = true
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
    }

    func placeTopRight(offsetIndex: Int) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let margin: CGFloat = 20
        let stagger = CGFloat(offsetIndex) * 28
        let x = visible.maxX - frame.width - margin - stagger
        let y = visible.maxY - frame.height - margin - stagger
        setFrameOrigin(NSPoint(x: x, y: y))
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
