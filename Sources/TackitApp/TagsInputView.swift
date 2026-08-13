import AppKit

final class TagPill: NSButton {
    private let tagText: String

    init(tag: String) {
        self.tagText = tag
        super.init(frame: .zero)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 9
        restyle()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var intrinsicContentSize: NSSize {
        let base = attributedTitle.size()
        return NSSize(width: ceil(base.width) + 18, height: 20)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }

    private func restyle() {
        attributedTitle = NSAttributedString(
            string: "#\(tagText)  ✕",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: Theme.overlaySelectionText.withAlphaComponent(0.92),
            ]
        )
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = Theme.overlayFocus.cgColor
        }
    }
}

final class TagInputField: NSTextField {
    override var intrinsicContentSize: NSSize {
        NSSize(width: 70, height: 20)
    }
}

final class TagsInputView: NSView {
    var onChange: (([String]) -> Void)?
    private(set) var tags: [String] = []

    private let input = TagInputField()
    private var pills: [TagPill] = []
    private var heightConstraint: NSLayoutConstraint!

    private let rowHeight: CGFloat = 20
    private let gap: CGFloat = 6

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        input.isBordered = false
        input.drawsBackground = false
        input.focusRingType = .none
        input.font = .systemFont(ofSize: 12)
        input.textColor = Theme.onOverlay
        input.placeholderAttributedString = NSAttributedString(
            string: "add tag…",
            attributes: [
                .foregroundColor: Theme.overlayPlaceholder,
                .font: NSFont.systemFont(ofSize: 12),
            ]
        )
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        addSubview(input)

        heightConstraint = heightAnchor.constraint(equalToConstant: rowHeight)
        heightConstraint.isActive = true
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    var textField: NSTextField { input }

    func setTags(_ newTags: [String]) {
        tags = newTags
        rebuildPills()
    }

    private func rebuildPills() {
        pills.forEach { $0.removeFromSuperview() }
        pills = tags.map { tag in
            let pill = TagPill(tag: tag)
            pill.target = self
            pill.action = #selector(removeTag(_:))
            pill.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pill)
            return pill
        }
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    @objc private func removeTag(_ sender: TagPill) {
        guard let index = pills.firstIndex(of: sender) else { return }
        tags.remove(at: index)
        rebuildPills()
        onChange?(tags)
    }

    private func addTag(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard !name.isEmpty, !tags.contains(name) else { input.stringValue = ""; return }
        tags.append(name)
        input.stringValue = ""
        rebuildPills()
        onChange?(tags)
    }

    override func layout() {
        super.layout()
        let width = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = bounds.height - rowHeight

        for pill in pills {
            let size = pill.intrinsicContentSize
            if x > 0, x + size.width > width {
                x = 0
                y -= rowHeight + gap
            }
            pill.frame = NSRect(x: x, y: y, width: size.width, height: rowHeight)
            x += size.width + gap
        }

        let inputWidth = max(70, width - x)
        if x > 0, inputWidth < 70 {
            x = 0
            y -= rowHeight + gap
        }
        input.frame = NSRect(x: x, y: y, width: max(70, width - x), height: rowHeight)

        let totalHeight = (bounds.height - y)
        if abs(heightConstraint.constant - totalHeight) > 0.5 {
            heightConstraint.constant = totalHeight
        }
    }
}

extension TagsInputView: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            addTag(input.stringValue)
            return true
        }
        if selector == #selector(NSResponder.deleteBackward(_:)), input.stringValue.isEmpty, !tags.isEmpty {
            tags.removeLast()
            rebuildPills()
            onChange?(tags)
            return true
        }
        return false
    }

    func controlTextDidChange(_ notification: Notification) {
        if input.stringValue.hasSuffix(",") {
            addTag(String(input.stringValue.dropLast()))
        }
    }
}
