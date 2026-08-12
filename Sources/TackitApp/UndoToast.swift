import AppKit

final class ClickView: NSView {
    var onClick: (() -> Void)?
    override func mouseDown(with event: NSEvent) { onClick?() }
}

final class UndoToast {
    private var panel: NSPanel?
    private var monitor: Any?
    private var timer: Timer?
    private var undoAction: (() -> Void)?

    func show(message: String, undo: @escaping () -> Void) {
        dismiss()
        undoAction = undo

        let size = NSSize(width: 320, height: 46)
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

        let content = ClickView()
        content.wantsLayer = true
        content.layer?.cornerRadius = 10
        content.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.98).cgColor
        content.layer?.borderWidth = 1
        content.layer?.borderColor = NSColor.separatorColor.cgColor
        content.onClick = { [weak self] in self?.performUndo() }
        panel.contentView = content

        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -16),
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
            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "z" {
                self?.performUndo()
                return nil
            }
            return event
        }

        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
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
