import AppKit
import WebKit

enum ToastType {
    case error, warning, success, info

    var color: NSColor {
        switch self {
        case .error: return .systemRed
        case .warning: return .systemYellow
        case .success: return .systemGreen
        case .info: return .systemBlue
        }
    }

    var symbolName: String {
        switch self {
        case .error: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

final class ToastContentView: NSView {
    var onClick: (() -> Void)?
    private let tint: NSColor

    init(tint: NSColor) {
        self.tint = tint
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = tint.withAlphaComponent(0.55).cgColor
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) { onClick?() }
}

final class UndoToast {
    private var panel: NSPanel?
    private var monitor: Any?
    private var timer: Timer?
    private var undoAction: (() -> Void)?

    func show(message: String, tip: String, type: ToastType, undo: @escaping () -> Void) {
        dismiss()
        undoAction = undo

        let size = NSSize(width: 300, height: 56)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let content = ToastContentView(tint: type.color)
        content.onClick = { [weak self] in self?.performUndo() }
        panel.contentView = content

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: type.symbolName, accessibilityDescription: nil)
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        icon.contentTintColor = type.color
        icon.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(icon)

        let messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .labelColor

        let tipLabel = NSTextField(labelWithString: tip)
        tipLabel.font = .systemFont(ofSize: 11)
        tipLabel.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [messageLabel, tipLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            icon.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            icon.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: icon.leadingAnchor, constant: -12),
        ])

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: visible.midX - size.width / 2,
                y: visible.maxY - size.height - 40
            ))
        }
        panel.orderFrontRegardless()
        self.panel = panel

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers?.lowercased() == "z",
               !UndoToast.isEditingText() {
                self?.performUndo()
                return nil
            }
            return event
        }

        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    // ⌘Z belongs to the focused editor when the user is typing (a note's web editor
    // or an overlay text field); only treat it as "undo delete" otherwise.
    private static func isEditingText() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        if responder is NSText { return true }
        var view = responder as? NSView
        while let current = view {
            if current is WKWebView { return true }
            view = current.superview
        }
        return false
    }

    private func performUndo() {
        let action = undoAction
        dismiss()
        action?()
    }

    func dismiss() {
        timer?.invalidate()
        timer = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        panel?.orderOut(nil)
        panel = nil
        undoAction = nil
    }
}
