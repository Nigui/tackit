import AppKit

struct MenuAction {
    let title: String
    let hint: String
    let run: () -> Void
}

final class MenuRow: NSView {
    var onClick: (() -> Void)?
    var onHover: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "")
    private let hintLabel = NSTextField(labelWithString: "")
    private var tracking: NSTrackingArea?

    init(title: String, hint: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6

        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = Theme.onOverlay
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        hintLabel.stringValue = hint
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = Theme.onOverlaySecondary
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintLabel)

        titleLabel.stringValue = title
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: hintLabel.leadingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func setHighlighted(_ highlighted: Bool) {
        layer?.backgroundColor = highlighted ? Theme.overlayFocus.cgColor : nil
        titleLabel.textColor = highlighted ? Theme.overlaySelectionText : Theme.onOverlay
        hintLabel.textColor = highlighted ? NSColor.white.withAlphaComponent(0.7) : Theme.onOverlaySecondary
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(convert(point, from: superview)) ? self : nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) { onHover?() }
    override func mouseDown(with event: NSEvent) { onClick?() }
}

final class ActionMenuOverlay: NSVisualEffectView {
    var onClose: (() -> Void)?

    private let searchField = AccentTextField(placeholder: "Search actions…")
    private let listStack = NSStackView()
    private var actions: [MenuAction] = []
    private var filtered: [MenuAction] = []
    private var rows: [MenuRow] = []
    private var highlighted = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func buildUI() {
        let scrim = NSView()
        scrim.wantsLayer = true
        scrim.layer?.backgroundColor = Theme.overlayBackground.cgColor
        scrim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)
        NSLayoutConstraint.activate([
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrim.topAnchor.constraint(equalTo: topAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let heading = NSTextField(labelWithString: "Note actions")
        heading.font = .systemFont(ofSize: 18, weight: .bold)
        heading.textColor = Theme.onOverlay
        heading.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heading)

        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchField)

        listStack.orientation = .vertical
        listStack.alignment = .leading
        listStack.spacing = 2
        listStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(listStack)

        let footer = NSView()
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.10).cgColor
        footer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footer)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(separator)

        let hint = NSTextField(labelWithString: "↑ ↓ move · ⏎ run · Esc close")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = Theme.onOverlayTertiary
        hint.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(hint)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchField.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            listStack.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            listStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            listStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            footer.leadingAnchor.constraint(equalTo: leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: 30),
            separator.topAnchor.constraint(equalTo: footer.topAnchor),
            separator.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            hint.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            hint.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
        ])
    }

    func present(actions: [MenuAction]) {
        self.actions = actions
        searchField.stringValue = ""
        isHidden = false
        rebuild(filter: "")
        layoutSubtreeIfNeeded()
        window?.makeFirstResponder(searchField)
    }

    private func rebuild(filter: String) {
        let query = filter.trimmingCharacters(in: .whitespaces).lowercased()
        filtered = query.isEmpty ? actions : actions.filter { $0.title.lowercased().contains(query) }

        rows.forEach { $0.removeFromSuperview() }
        rows = filtered.enumerated().map { index, action in
            let row = MenuRow(title: action.title, hint: action.hint)
            row.onClick = { [weak self] in self?.run(index) }
            row.onHover = { [weak self] in
                self?.highlighted = index
                self?.updateHighlight()
            }
            listStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: listStack.widthAnchor).isActive = true
            return row
        }
        highlighted = 0
        updateHighlight()
    }

    private func updateHighlight() {
        for (index, row) in rows.enumerated() {
            row.setHighlighted(index == highlighted)
        }
    }

    private func moveHighlight(_ delta: Int) {
        guard !rows.isEmpty else { return }
        highlighted = max(0, min(rows.count - 1, highlighted + delta))
        updateHighlight()
    }

    private func run(_ index: Int) {
        guard filtered.indices.contains(index) else { return }
        let action = filtered[index]
        onClose?()
        action.run()
    }
}

extension ActionMenuOverlay: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        rebuild(filter: searchField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)): moveHighlight(1); return true
        case #selector(NSResponder.moveUp(_:)): moveHighlight(-1); return true
        case #selector(NSResponder.insertNewline(_:)): run(highlighted); return true
        case #selector(NSResponder.cancelOperation(_:)): onClose?(); return true
        default: return false
        }
    }
}
