import AppKit

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

final class DropdownRow: NSView {
    var onClick: (() -> Void)?
    var onHover: (() -> Void)?

    private let label = NSTextField(labelWithString: "")
    private let baseColor: NSColor
    private var tracking: NSTrackingArea?

    init(text: String, accent: Bool) {
        baseColor = accent ? Theme.accent : .labelColor
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6
        label.stringValue = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = baseColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func setHighlighted(_ highlighted: Bool) {
        layer?.backgroundColor = highlighted ? Theme.accent.cgColor : nil
        label.textColor = highlighted ? .black : baseColor
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

final class GroupTypeaheadField: NSView {
    var onChange: ((String?) -> Void)?
    weak var host: NSView?

    let input = AccentTextField(placeholder: "uncategorized")
    private var groups: [String] = []
    private var dropdown: NSView?
    private var rows: [DropdownRow] = []
    private var values: [String] = []
    private var highlighted = 0

    private let rowHeight: CGFloat = 30
    private let rowGap: CGFloat = 2
    private let pad: CGFloat = 6
    private let maxVisibleRows = 6

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        addSubview(input)
        NSLayoutConstraint.activate([
            input.leadingAnchor.constraint(equalTo: leadingAnchor),
            input.trailingAnchor.constraint(equalTo: trailingAnchor),
            input.topAnchor.constraint(equalTo: topAnchor),
            input.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    var textField: NSTextField { input }

    func configure(groups: [String], selected: String?) {
        self.groups = groups
        input.stringValue = selected ?? ""
    }

    private func matches(for text: String) -> [String] {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty { return groups }
        return groups.filter { $0.lowercased().contains(query) }
    }

    private func hasExactMatch(_ text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        return groups.contains { $0.lowercased() == query }
    }

    private func showDropdown() {
        guard let host else { return }
        dropdown?.removeFromSuperview()
        dropdown = nil

        let text = input.stringValue
        let found = matches(for: text)
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let showCreate = !trimmed.isEmpty && !hasExactMatch(text)

        if found.isEmpty && !showCreate {
            rows = []
            values = []
            return
        }

        let rect = host.convert(input.frame, from: self)
        let width = rect.width
        let innerWidth = width - pad * 2

        rows = []
        values = []
        let document = FlippedView()
        for group in found {
            addRow(to: document, text: group, accent: false, value: group, innerWidth: innerWidth)
        }
        if showCreate {
            addRow(to: document, text: "Create “\(trimmed)”    ⏎", accent: true, value: trimmed, innerWidth: innerWidth)
        }

        let count = rows.count
        let contentHeight = pad * 2 + CGFloat(count) * rowHeight + CGFloat(max(0, count - 1)) * rowGap
        let visibleHeight = min(contentHeight, pad * 2 + CGFloat(maxVisibleRows) * rowHeight + CGFloat(maxVisibleRows - 1) * rowGap)
        document.frame = NSRect(x: 0, y: 0, width: width, height: contentHeight)

        let container = NSView(frame: NSRect(x: rect.minX, y: rect.minY - visibleHeight - 4, width: width, height: visibleHeight))
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.separatorColor.cgColor
        container.layer?.masksToBounds = true

        let scroll = NSScrollView(frame: container.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.documentView = document
        container.addSubview(scroll)

        host.addSubview(container)
        dropdown = container
        highlighted = 0
        updateHighlight()
    }

    private func addRow(to document: NSView, text: String, accent: Bool, value: String, innerWidth: CGFloat) {
        let index = rows.count
        let row = DropdownRow(text: text, accent: accent)
        row.frame = NSRect(x: pad, y: pad + CGFloat(index) * (rowHeight + rowGap), width: innerWidth, height: rowHeight)
        row.onClick = { [weak self] in self?.select(index) }
        row.onHover = { [weak self] in
            self?.highlighted = index
            self?.updateHighlight()
        }
        document.addSubview(row)
        rows.append(row)
        values.append(value)
    }

    private func updateHighlight() {
        for (index, row) in rows.enumerated() {
            row.setHighlighted(index == highlighted)
        }
        if rows.indices.contains(highlighted) {
            rows[highlighted].scrollToVisible(rows[highlighted].bounds)
        }
    }

    private func moveHighlight(_ delta: Int) {
        guard !rows.isEmpty else { return }
        highlighted = max(0, min(rows.count - 1, highlighted + delta))
        updateHighlight()
    }

    private func select(_ index: Int) {
        guard values.indices.contains(index) else { return }
        input.stringValue = values[index]
        commit()
        hideDropdown()
    }

    private func hideDropdown() {
        dropdown?.removeFromSuperview()
        dropdown = nil
        rows = []
        values = []
    }

    private func commit() {
        let name = input.stringValue.trimmingCharacters(in: .whitespaces)
        onChange?(name.isEmpty ? nil : name)
    }
}

extension GroupTypeaheadField: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ notification: Notification) { showDropdown() }

    func controlTextDidChange(_ notification: Notification) { showDropdown() }

    func controlTextDidEndEditing(_ notification: Notification) {
        commit()
        DispatchQueue.main.async { [weak self] in self?.hideDropdown() }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            if dropdown != nil { moveHighlight(1); return true }
        case #selector(NSResponder.moveUp(_:)):
            if dropdown != nil { moveHighlight(-1); return true }
        case #selector(NSResponder.insertNewline(_:)):
            if dropdown != nil, !rows.isEmpty {
                select(highlighted)
            } else {
                commit()
                hideDropdown()
            }
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            if dropdown != nil { hideDropdown(); return true }
        default:
            break
        }
        return false
    }
}
