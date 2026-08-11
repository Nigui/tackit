import AppKit
import TackitCore

final class ShadowCardView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func layout() {
        super.layout()
        layer?.shadowPath = CGPath(roundedRect: bounds, cornerWidth: 12, cornerHeight: 12, transform: nil)
    }
}

final class StickyPanel: NSPanel {
    let editorSurface: EditorSurface
    let noteId: UUID
    var onClose: (() -> Void)?
    var onNewNote: (() -> Void)?
    var onQuickOpen: (() -> Void)?
    var onSwitchTo: ((Int) -> Void)?
    var onFrameChanged: ((NSRect) -> Void)?
    private var header: NoteHeaderView?
    private let clipView = NSView()
    private let cardView = ShadowCardView()
    private let headerHeight: CGFloat = 116
    private let padding: CGFloat = 18
    static let accent = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1.0)

    init(surface: EditorSurface, index: Int, noteId: UUID) {
        self.editorSurface = surface
        self.noteId = noteId
        let card = NSSize(width: 380, height: 460)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: card.width + padding * 2, height: card.height + padding * 2),
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
        hasShadow = false

        guard let content = contentView else { return }
        content.wantsLayer = true
        content.layer?.masksToBounds = false

        cardView.frame = content.bounds.insetBy(dx: padding, dy: padding)
        cardView.autoresizingMask = [.width, .height]
        cardView.wantsLayer = true
        cardView.layer?.masksToBounds = false
        cardView.layer?.shadowColor = StickyPanel.accent.cgColor
        cardView.layer?.shadowOffset = .zero
        cardView.layer?.shadowRadius = 10
        cardView.layer?.shadowOpacity = 0
        content.addSubview(cardView)

        clipView.frame = cardView.bounds
        clipView.autoresizingMask = [.width, .height]
        clipView.wantsLayer = true
        clipView.layer?.cornerRadius = 12
        clipView.layer?.masksToBounds = true
        clipView.layer?.borderColor = StickyPanel.accent.cgColor
        cardView.addSubview(clipView)

        let bounds = clipView.bounds
        let headerView = NoteHeaderView(frame: NSRect(x: 0, y: bounds.height - headerHeight, width: bounds.width, height: headerHeight))
        headerView.autoresizingMask = [.width, .minYMargin]
        clipView.addSubview(headerView)
        header = headerView

        let editorView = surface.view
        editorView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - headerHeight)
        editorView.autoresizingMask = [.width, .height]
        clipView.addSubview(editorView)

        applyFocusState(true)
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private func applyFocusState(_ focused: Bool) {
        clipView.layer?.backgroundColor = NSColor.textBackgroundColor
            .withAlphaComponent(focused ? 0.98 : 0.86).cgColor
        clipView.layer?.borderWidth = focused ? 2.5 : 0
        cardView.layer?.shadowOpacity = focused ? 0.85 : 0
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
        default: return super.performKeyEquivalent(with: event)
        }
    }

    func update(note: Note) {
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
