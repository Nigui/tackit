import AppKit
import Carbon.HIToolbox

final class SegmentedBar: NSControl {
    private let segments: [String]
    private(set) var selectedIndex: Int
    var onChange: ((Int) -> Void)?

    private var cellRects: [NSRect] = []
    private static let font = NSFont.systemFont(ofSize: 12, weight: .medium)
    private let hInset: CGFloat = 12

    init(segments: [String], selectedIndex: Int) {
        self.segments = segments
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)
        wantsLayer = true
        focusRingType = .none
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override var intrinsicContentSize: NSSize {
        let width = segments.reduce(0) { $0 + cellWidth($1) }
        return NSSize(width: width, height: 28)
    }

    private func cellWidth(_ text: String) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: Self.font]).width) + hInset * 2
    }

    override func layout() {
        super.layout()
        cellRects = []
        var x: CGFloat = 0
        for text in segments {
            let width = cellWidth(text)
            cellRects.append(NSRect(x: x, y: 0, width: width, height: bounds.height))
            x += width
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.10).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 7, yRadius: 7).fill()

        for (index, rect) in cellRects.enumerated() {
            let selected = index == selectedIndex
            if selected {
                Theme.overlayFocus.setFill()
                NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 5, yRadius: 5).fill()
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: Self.font,
                .foregroundColor: selected ? NSColor.white : Theme.onOverlay,
            ]
            let text = segments[index] as NSString
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
        }

        if window?.firstResponder === self {
            let ring = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 7, yRadius: 7)
            Theme.overlayFocus.setStroke()
            ring.lineWidth = 1.5
            ring.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let index = cellRects.firstIndex(where: { $0.contains(point) }) { select(index) }
    }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Tab:
            if event.modifierFlags.contains(.shift) { window?.selectPreviousKeyView(nil) }
            else { window?.selectNextKeyView(nil) }
        case kVK_LeftArrow:
            select(max(0, selectedIndex - 1))
        case kVK_RightArrow:
            select(min(segments.count - 1, selectedIndex + 1))
        default:
            super.keyDown(with: event)
        }
    }

    override func becomeFirstResponder() -> Bool { needsDisplay = true; return super.becomeFirstResponder() }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return super.resignFirstResponder() }

    private func select(_ index: Int) {
        guard segments.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        needsDisplay = true
        onChange?(index)
    }
}
