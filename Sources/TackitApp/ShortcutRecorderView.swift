import AppKit
import Carbon.HIToolbox

private final class KeyCap: NSView {
    init(_ text: String) {
        super.init(frame: .zero)
        wantsLayer = true
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = Theme.onOverlay
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 21),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 21),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        layer?.cornerRadius = 4
        layer?.backgroundColor = Theme.keyCapBackground.cgColor
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
}

final class ShortcutRecorderView: NSView {
    var onRecord: ((KeyCombo) -> Void)?
    var onRecordingChange: ((Bool) -> Void)?
    var accepts: ((KeyCombo) -> Bool)?

    private var combo: KeyCombo
    private var recording = false
    private var isFocused = false

    private let content = NSStackView()
    private let hint = NSTextField(labelWithString: "press new keys…")

    init(combo: KeyCombo) {
        self.combo = combo
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6
        focusRingType = .none

        content.orientation = .horizontal
        content.spacing = 4
        content.alignment = .centerY
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        hint.font = .systemFont(ofSize: 11)
        hint.textColor = Theme.onOverlaySecondary

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    override func becomeFirstResponder() -> Bool { isFocused = true; refresh(); return super.becomeFirstResponder() }
    override func resignFirstResponder() -> Bool {
        if recording { stopRecording(commit: nil) }
        isFocused = false
        refresh()
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        if recording { stopRecording(commit: nil) } else { startRecording() }
    }

    override func keyDown(with event: NSEvent) {
        if recording {
            if !record(event) { super.keyDown(with: event) }
            return
        }
        switch Int(event.keyCode) {
        case kVK_Tab:
            if event.modifierFlags.contains(.shift) { window?.selectPreviousKeyView(nil) }
            else { window?.selectNextKeyView(nil) }
        case kVK_Space, kVK_Return, kVK_ANSI_KeypadEnter:
            startRecording()
        default:
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if recording { return record(event) }
        return super.performKeyEquivalent(with: event)
    }

    private func startRecording() {
        guard !recording else { return }
        recording = true
        refresh()
        onRecordingChange?(true)
    }

    private func stopRecording(commit: KeyCombo?) {
        guard recording else { return }
        recording = false
        if let commit { combo = commit }
        refresh()
        onRecordingChange?(false)
        if let commit { onRecord?(commit) }
    }

    @discardableResult
    private func record(_ event: NSEvent) -> Bool {
        guard recording else { return false }
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording(commit: nil)
            return true
        }
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            return true
        }
        let candidate = KeyCombo(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        if let accepts, !accepts(candidate) {
            NSSound.beep()
            return true
        }
        stopRecording(commit: candidate)
        return true
    }

    private func refresh() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for symbol in Self.capSymbols(combo) {
            content.addArrangedSubview(KeyCap(symbol))
        }
        content.addArrangedSubview(hint)
        hint.isHidden = !recording

        layer?.borderWidth = (recording || isFocused) ? 1.5 : 0
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.borderColor = Theme.overlayFocus.cgColor
            layer?.backgroundColor = (recording ? Theme.overlayField : NSColor.clear).cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refresh()
    }

    // MARK: - Formatting

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    static func capSymbols(_ combo: KeyCombo) -> [String] {
        var symbols: [String] = []
        if combo.modifiers & UInt32(controlKey) != 0 { symbols.append("⌃") }
        if combo.modifiers & UInt32(optionKey) != 0 { symbols.append("⌥") }
        if combo.modifiers & UInt32(shiftKey) != 0 { symbols.append("⇧") }
        if combo.modifiers & UInt32(cmdKey) != 0 { symbols.append("⌘") }
        symbols.append(keyLabel(for: combo.keyCode))
        return symbols
    }

    static func display(_ combo: KeyCombo) -> String {
        capSymbols(combo).joined()
    }

    private static func keyLabel(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "␣"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        default:
            return KeyboardLayout.character(for: UInt16(keyCode))?.uppercased() ?? "?"
        }
    }
}
