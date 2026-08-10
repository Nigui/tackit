import Carbon.HIToolbox

enum KeyboardLayout {
    static func keyCode(for character: String) -> UInt32? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return layoutData.withUnsafeBytes { buffer -> UInt32? in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return nil }
            for keyCode in UInt16(0)..<UInt16(128) {
                if output(layout, keyCode: keyCode, shift: false) == character
                    || output(layout, keyCode: keyCode, shift: true) == character {
                    return UInt32(keyCode)
                }
            }
            return nil
        }
    }

    private static func output(_ layout: UnsafePointer<UCKeyboardLayout>, keyCode: UInt16, shift: Bool) -> String? {
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let modifiers = shift ? UInt32((shiftKey >> 8) & 0xFF) : 0
        let status = UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDown),
            modifiers,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            characters.count,
            &length,
            &characters
        )
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: characters, count: length)
    }
}
