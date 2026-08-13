import AppKit

final class PaddingTextFieldCell: NSTextFieldCell {
    var inset = NSSize(width: 9, height: 6)

    private func padded(_ rect: NSRect) -> NSRect {
        let dx = min(inset.width, rect.width / 2)
        let dy = min(inset.height, rect.height / 2)
        return rect.insetBy(dx: dx, dy: dy)
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        super.drawingRect(forBounds: padded(rect))
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: padded(rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: padded(rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}

final class AccentTextField: NSTextField {
    private let height: CGFloat = 30
    private let placeholderText: String
    private var focused = false

    init(placeholder: String) {
        placeholderText = placeholder
        super.init(frame: .zero)
        let paddedCell = PaddingTextFieldCell(textCell: "")
        paddedCell.isEditable = true
        paddedCell.isSelectable = true
        paddedCell.isScrollable = true
        paddedCell.wraps = false
        paddedCell.usesSingleLineMode = true
        cell = paddedCell

        font = .systemFont(ofSize: 13)
        focusRingType = .none
        drawsBackground = false
        wantsLayer = true
        layer?.cornerRadius = 6
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        restyle()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { focused = true; restyle() }
        return accepted
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        focused = false
        restyle()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        restyle()
    }

    private func restyle() {
        textColor = Theme.onOverlay
        placeholderAttributedString = NSAttributedString(
            string: placeholderText,
            attributes: [
                .foregroundColor: Theme.overlayPlaceholder,
                .font: NSFont.systemFont(ofSize: 13),
            ]
        )
        layer?.borderWidth = focused ? 2 : 1
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = Theme.overlayField.cgColor
            layer?.borderColor = (focused ? Theme.overlayFocus : Theme.overlayFieldBorder).cgColor
        }
    }
}
