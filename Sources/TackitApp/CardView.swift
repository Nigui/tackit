import AppKit

final class CardView: NSView {
    private let glow = CALayer()

    var focusedState = false { didSet { updateAppearance() } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = Theme.cornerRadius
        layer?.masksToBounds = true
        layer?.borderColor = Theme.accent.cgColor

        glow.masksToBounds = true
        glow.shadowColor = Theme.accent.cgColor
        glow.shadowOffset = .zero
        glow.shadowRadius = 7
        glow.shadowOpacity = 0
        glow.zPosition = 1000
        layer?.addSublayer(glow)

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override func layout() {
        super.layout()
        let b = bounds
        glow.frame = b
        let ring = NSBezierPath(rect: b.insetBy(dx: -40, dy: -40))
        ring.append(NSBezierPath(roundedRect: b, xRadius: Theme.cornerRadius, yRadius: Theme.cornerRadius).reversed)
        glow.shadowPath = ring.cgPath
        let mask = CAShapeLayer()
        mask.path = CGPath(roundedRect: b, cornerWidth: Theme.cornerRadius, cornerHeight: Theme.cornerRadius, transform: nil)
        glow.mask = mask
    }

    private func updateAppearance() {
        layer?.backgroundColor = NSColor.textBackgroundColor
            .withAlphaComponent(focusedState ? 0.98 : 0.86).cgColor
        layer?.borderWidth = focusedState ? 2.5 : 0
        glow.shadowOpacity = focusedState ? 0.9 : 0
    }
}
