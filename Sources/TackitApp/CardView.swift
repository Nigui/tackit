import AppKit

final class CardView: NSView {
    var focusedState = false { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.cornerRadius = Theme.cornerRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.textBackgroundColor
            .withAlphaComponent(focusedState ? 0.98 : 0.86).cgColor
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
