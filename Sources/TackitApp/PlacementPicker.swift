import AppKit
import Carbon.HIToolbox

final class PlacementCell: NSView {
    var onClick: (() -> Void)?
    var isSelected = false { didSet { updateAppearance() } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderColor = Theme.overlayFocus.cgColor
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(convert(point, from: superview)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) { onClick?() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    private func updateAppearance() {
        layer?.borderWidth = isSelected ? 2 : 0
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = Theme.onOverlay.withAlphaComponent(isSelected ? 0.24 : 0.12).cgColor
            layer?.borderColor = Theme.overlayFocus.cgColor
        }
    }
}

final class PlacementPicker: NSView {
    var onSelect: ((StickyPlacement) -> Void)?

    private var cells: [PlacementCell] = []
    private var current: StickyPlacement

    init(selected: StickyPlacement, onSelect: ((StickyPlacement) -> Void)? = nil) {
        self.current = selected
        super.init(frame: .zero)
        self.onSelect = onSelect

        cells = StickyPlacement.allCases.map { placement in
            let cell = PlacementCell()
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.widthAnchor.constraint(equalToConstant: 30).isActive = true
            cell.heightAnchor.constraint(equalToConstant: 22).isActive = true
            cell.onClick = { [weak self] in self?.pick(placement) }
            return cell
        }

        let rowStacks = (0..<3).map { row -> NSStackView in
            let stack = NSStackView(views: Array(cells[(row * 3)..<(row * 3 + 3)]))
            stack.orientation = .horizontal
            stack.spacing = 6
            return stack
        }
        let grid = NSStackView(views: rowStacks)
        grid.orientation = .vertical
        grid.spacing = 6
        grid.alignment = .leading
        grid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            grid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
        ])
        focusRingType = .none
        select(selected)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    override func becomeFirstResponder() -> Bool { needsDisplay = true; return super.becomeFirstResponder() }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return super.resignFirstResponder() }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }

    override func draw(_ dirtyRect: NSRect) {
        if window?.firstResponder === self {
            let ring = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 7, yRadius: 7)
            Theme.overlayFocus.setStroke()
            ring.lineWidth = 1.5
            ring.stroke()
        }
    }

    override func keyDown(with event: NSEvent) {
        var row = current.rawValue / 3
        var col = current.rawValue % 3
        switch Int(event.keyCode) {
        case kVK_Tab:
            if event.modifierFlags.contains(.shift) { window?.selectPreviousKeyView(nil) }
            else { window?.selectNextKeyView(nil) }
            return
        case kVK_LeftArrow: col = max(0, col - 1)
        case kVK_RightArrow: col = min(2, col + 1)
        case kVK_UpArrow: row = max(0, row - 1)
        case kVK_DownArrow: row = min(2, row + 1)
        default: super.keyDown(with: event); return
        }
        if let placement = StickyPlacement(rawValue: row * 3 + col) { pick(placement) }
    }

    private func pick(_ placement: StickyPlacement) {
        current = placement
        select(placement)
        onSelect?(placement)
    }

    private func select(_ placement: StickyPlacement) {
        current = placement
        for (index, cell) in cells.enumerated() {
            cell.isSelected = (index == placement.rawValue)
        }
    }
}
