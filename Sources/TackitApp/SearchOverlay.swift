import AppKit

struct NoteSearchResult {
    let id: UUID
    let icon: String
    let title: String
    let description: String
    let updatedAt: Date
}

final class SearchResultRow: NSView {
    var onClick: (() -> Void)?
    var onHover: (() -> Void)?

    private let iconLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let descLabel = NSTextField(labelWithString: "")
    private let dateLine = NSTextField(labelWithString: "")
    private let timeLine = NSTextField(labelWithString: "")
    private var tracking: NSTrackingArea?

    init(result: NoteSearchResult, dateText: String, timeText: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6

        iconLabel.stringValue = result.icon.isEmpty ? "📝" : result.icon
        iconLabel.font = .systemFont(ofSize: 17)
        iconLabel.alignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconLabel)

        titleLabel.stringValue = result.title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = Theme.onOverlay
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.cell?.truncatesLastVisibleLine = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descLabel.stringValue = result.description
        descLabel.font = .systemFont(ofSize: 11)
        descLabel.textColor = Theme.onOverlaySecondary
        descLabel.lineBreakMode = .byTruncatingTail
        descLabel.cell?.truncatesLastVisibleLine = true
        descLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        descLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descLabel.isHidden = result.description.isEmpty

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        if !descLabel.isHidden { addSubview(descLabel) }

        dateLine.stringValue = dateText
        dateLine.font = .systemFont(ofSize: 11, weight: .medium)
        dateLine.alignment = .right
        dateLine.textColor = Theme.onOverlaySecondary
        timeLine.stringValue = timeText
        timeLine.font = .systemFont(ofSize: 11)
        timeLine.alignment = .right
        timeLine.textColor = Theme.onOverlayTertiary

        let dateStack = NSStackView(views: [dateLine, timeLine])
        dateStack.orientation = .vertical
        dateStack.alignment = .trailing
        dateStack.spacing = 1
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dateStack.setContentHuggingPriority(.required, for: .horizontal)
        dateStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(dateStack)

        var constraints: [NSLayoutConstraint] = [
            heightAnchor.constraint(equalToConstant: 52),
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),
            dateStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            dateStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: dateStack.leadingAnchor, constant: -10),
        ]
        if descLabel.isHidden {
            constraints.append(titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        } else {
            constraints.append(contentsOf: [
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 9),
                descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            ])
        }
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private var isHighlighted = false

    func setHighlighted(_ highlighted: Bool) {
        isHighlighted = highlighted
        titleLabel.textColor = highlighted ? Theme.overlaySelectionText : Theme.onOverlay
        descLabel.textColor = highlighted ? Theme.overlaySelectionText.withAlphaComponent(0.8) : Theme.onOverlaySecondary
        dateLine.textColor = highlighted ? Theme.overlaySelectionText.withAlphaComponent(0.8) : Theme.onOverlaySecondary
        timeLine.textColor = highlighted ? Theme.overlaySelectionText.withAlphaComponent(0.6) : Theme.onOverlayTertiary
        needsDisplay = true
    }

    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        layer?.cornerRadius = 6
        layer?.backgroundColor = isHighlighted ? Theme.overlayFocus.cgColor : nil
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }

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

final class SearchOverlay: NSVisualEffectView {
    var onQuery: ((String) -> [NoteSearchResult])?
    var onOpen: ((UUID, Bool) -> Void)?
    var onClose: (() -> Void)?

    private let searchField = AccentTextField(placeholder: "Search notes…")
    private let scrollView = NSScrollView()
    private let document = FlippedView()
    private let rowsStack = NSStackView()
    private let emptyLabel = NSTextField(labelWithString: "No matching notes")
    private var rows: [SearchResultRow] = []
    private var results: [NoteSearchResult] = []
    private var highlighted = 0
    private var lastMouseLocation: NSPoint?

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
        let scrim = ThemedView(fill: { Theme.overlayBackground })
        scrim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)

        let heading = NSTextField(labelWithString: "Search notes")
        heading.font = .systemFont(ofSize: 18, weight: .bold)
        heading.textColor = Theme.onOverlay
        heading.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heading)

        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchField)

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.documentView = document
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        document.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 0
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(rowsStack)

        emptyLabel.font = .systemFont(ofSize: 12)
        emptyLabel.textColor = Theme.onOverlaySecondary
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        let footer = ThemedView(fill: { Theme.overlayFooter })
        footer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footer)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(separator)

        let hint = NSTextField(labelWithString: "↑↓ · ⏎ here · ⌘⏎ new · Esc")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = Theme.onOverlayTertiary
        hint.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(hint)

        NSLayoutConstraint.activate([
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrim.topAnchor.constraint(equalTo: topAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomAnchor),
            heading.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchField.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            scrollView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -8),
            document.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            document.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            rowsStack.topAnchor.constraint(equalTo: document.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: document.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
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

    func present() {
        searchField.stringValue = ""
        isHidden = false
        layoutSubtreeIfNeeded()
        rebuild(onQuery?("") ?? [])
        window?.makeFirstResponder(searchField)
    }

    private func rebuild(_ newResults: [NoteSearchResult]) {
        results = newResults
        rows.forEach { $0.removeFromSuperview() }
        rows = results.enumerated().map { index, result in
            let row = SearchResultRow(
                result: result,
                dateText: Self.dayFormatter.string(from: result.updatedAt),
                timeText: Self.timeFormatter.string(from: result.updatedAt)
            )
            row.onClick = { [weak self] in self?.open(index, inNewPanel: false) }
            row.onHover = { [weak self] in self?.hoverHighlight(index) }
            rowsStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: rowsStack.widthAnchor).isActive = true
            return row
        }
        emptyLabel.isHidden = !results.isEmpty
        lastMouseLocation = NSEvent.mouseLocation
        highlighted = 0
        updateHighlight()
    }

    // Honor hover only when the mouse actually moved. When keyboard navigation scrolls
    // the list, rows slide under a stationary cursor and fire mouseEntered; ignoring
    // those keeps the keyboard in control.
    private func hoverHighlight(_ index: Int) {
        let location = NSEvent.mouseLocation
        if location == lastMouseLocation { return }
        lastMouseLocation = location
        highlighted = index
        updateHighlight()
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
        lastMouseLocation = NSEvent.mouseLocation
        highlighted = max(0, min(rows.count - 1, highlighted + delta))
        updateHighlight()
    }

    private func open(_ index: Int, inNewPanel: Bool) {
        guard results.indices.contains(index) else { return }
        let id = results[index].id
        onClose?()
        onOpen?(id, inNewPanel)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if !isHidden, event.modifierFlags.contains(.command), event.keyCode == 36 {
            if !rows.isEmpty { open(highlighted, inNewPanel: true) }
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter
    }()
}

extension SearchOverlay: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        rebuild(onQuery?(searchField.stringValue) ?? [])
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)): moveHighlight(1); return true
        case #selector(NSResponder.moveUp(_:)): moveHighlight(-1); return true
        case #selector(NSResponder.insertNewline(_:)):
            if !rows.isEmpty { open(highlighted, inNewPanel: false) }
            return true
        case #selector(NSResponder.cancelOperation(_:)): onClose?(); return true
        default: return false
        }
    }
}
