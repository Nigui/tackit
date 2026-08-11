import AppKit

final class DragStrip: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

final class StickyPanel: NSPanel {
    let editorSurface: EditorSurface
    let noteId: UUID
    var onClose: (() -> Void)?
    var onNewNote: (() -> Void)?
    var onQuickOpen: (() -> Void)?
    var onSwitchTo: ((Int) -> Void)?
    private let headerHeight: CGFloat = 22

    init(surface: EditorSurface, index: Int, noteId: UUID) {
        self.editorSurface = surface
        self.noteId = noteId
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.985)
        hasShadow = true

        guard let content = contentView else { return }
        let bounds = content.bounds

        let header = DragStrip(frame: NSRect(x: 0, y: bounds.height - headerHeight, width: bounds.width, height: headerHeight))
        header.autoresizingMask = [.width, .minYMargin]
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 0.16).cgColor
        content.addSubview(header)

        let editorView = surface.view
        editorView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - headerHeight)
        editorView.autoresizingMask = [.width, .height]
        content.addSubview(editorView)

        if index == 0 {
            setFrameAutosaveName("TackitStickyM0")
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

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
