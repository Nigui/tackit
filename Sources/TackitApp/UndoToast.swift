import AppKit

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
            icon.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -16),
        ])

        addLifetimeBar(to: content, width: size.width, color: type.color, duration: 6)

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
               event.charactersIgnoringModifiers?.lowercased() == "z" {
                self?.performUndo()
                return nil
            }
            return event
        }

        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    // A thin bar along the bottom that drains right-to-left over the toast's lifetime.
    private func addLifetimeBar(to content: NSView, width: CGFloat, color: NSColor, duration: CFTimeInterval) {
        let fill = CALayer()
        fill.anchorPoint = CGPoint(x: 0, y: 0)
        fill.frame = CGRect(x: 0, y: 0, width: width, height: 3)
        content.effectiveAppearance.performAsCurrentDrawingAppearance {
            fill.backgroundColor = color.cgColor
        }
        content.layer?.addSublayer(fill)

        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.fromValue = width
        animation.toValue = 0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        fill.add(animation, forKey: "deplete")
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
