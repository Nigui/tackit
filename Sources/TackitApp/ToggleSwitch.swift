import AppKit
import Carbon.HIToolbox

final class ToggleSwitch: NSControl {
    private(set) var isOn: Bool
    var onToggle: ((Bool) -> Void)?

    init(isOn: Bool) {
        self.isOn = isOn
        super.init(frame: NSRect(x: 0, y: 0, width: 42, height: 24))
        wantsLayer = true
        focusRingType = .none
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var intrinsicContentSize: NSSize { NSSize(width: 48, height: 28) }
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    private var trackRect: NSRect { bounds.insetBy(dx: 5, dy: 5) }

    override func draw(_ dirtyRect: NSRect) {
        let track = trackRect
        let radius = track.height / 2
        (isOn ? Theme.overlayFocus : NSColor(calibratedWhite: 0.5, alpha: 0.30)).setFill()
        NSBezierPath(roundedRect: track, xRadius: radius, yRadius: radius).fill()

        let diameter = track.height - 4
        let knobX = isOn ? track.maxX - diameter - 2 : track.minX + 2
        let knob = NSRect(x: knobX, y: track.minY + 2, width: diameter, height: diameter)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knob).fill()

        if window?.firstResponder === self {
            let ring = NSBezierPath(roundedRect: track.insetBy(dx: -2.5, dy: -2.5), xRadius: radius + 2.5, yRadius: radius + 2.5)
            Theme.overlayFocus.setStroke()
            ring.lineWidth = 1.5
            ring.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) { toggle() }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Tab:
            if event.modifierFlags.contains(.shift) { window?.selectPreviousKeyView(nil) }
            else { window?.selectNextKeyView(nil) }
        case kVK_Space, kVK_Return, kVK_ANSI_KeypadEnter:
            toggle()
        default:
            super.keyDown(with: event)
        }
    }

    override func becomeFirstResponder() -> Bool { needsDisplay = true; return super.becomeFirstResponder() }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return super.resignFirstResponder() }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }

    func setOn(_ on: Bool) { isOn = on; needsDisplay = true }

    private func toggle() {
        isOn.toggle()
        needsDisplay = true
        onToggle?(isOn)
    }
}
