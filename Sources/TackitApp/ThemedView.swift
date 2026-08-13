import AppKit

/// A layer-backed view whose fill/border follow the (dynamic) Theme colors and
/// re-resolve on appearance changes — `updateLayer` runs with the view's
/// effectiveAppearance current, so dynamic `NSColor.cgColor` resolves correctly.
final class ThemedView: NSView {
    private let fill: () -> NSColor
    private let border: (() -> NSColor)?
    private let corner: CGFloat
    private let borderWidth: CGFloat

    init(fill: @escaping () -> NSColor, cornerRadius: CGFloat = 0, border: (() -> NSColor)? = nil, borderWidth: CGFloat = 0) {
        self.fill = fill
        self.border = border
        self.corner = cornerRadius
        self.borderWidth = borderWidth
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.cornerRadius = corner
        layer?.masksToBounds = corner > 0
        layer?.backgroundColor = fill().cgColor
        if let border {
            layer?.borderWidth = borderWidth
            layer?.borderColor = border().cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
