import AppKit
import ServiceManagement
import Carbon.HIToolbox

enum StickyPlacement: Int, CaseIterable {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight
}

enum AppearanceMode: Int, CaseIterable {
    case light, system, dark
}

struct KeyCombo: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32 // Carbon modifier mask
}

enum AppShortcut: String, CaseIterable {
    case configure, search, newNote, closeNote, actionMenu

    var label: String {
        switch self {
        case .configure: return "Configure note"
        case .search: return "Search notes"
        case .newNote: return "New note"
        case .closeNote: return "Close note"
        case .actionMenu: return "Action menu"
        }
    }

    var defaultCharacter: String {
        switch self {
        case .configure: return "e"
        case .search: return "o"
        case .newNote: return "n"
        case .closeNote: return "w"
        case .actionMenu: return "k"
        }
    }
}

final class SettingsStore {
    static let didChange = Notification.Name("TackitSettingsDidChange")

    private let defaults: UserDefaults

    private enum Key {
        static let width = "defaultWidth"
        static let height = "defaultHeight"
        static let placement = "placement"
        static let alwaysOnTop = "alwaysOnTop"
        static let appearance = "appearance"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
    }

    private static let ansiFallback: [String: UInt32] = [
        "n": 45, "w": 13, "o": 31, "k": 40, "e": 14,
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var registered: [String: Any] = [
            Key.width: 380.0,
            Key.height: 460.0,
            Key.placement: StickyPlacement.topRight.rawValue,
            Key.alwaysOnTop: true,
            Key.appearance: AppearanceMode.system.rawValue,
            Key.hotkeyKeyCode: Int(KeyboardLayout.keyCode(for: ".") ?? UInt32(kVK_ANSI_Period)),
            Key.hotkeyModifiers: Int(cmdKey | shiftKey),
        ]
        for shortcut in AppShortcut.allCases {
            let code = KeyboardLayout.keyCode(for: shortcut.defaultCharacter)
                ?? SettingsStore.ansiFallback[shortcut.defaultCharacter]
                ?? 0
            registered[Self.keyCodeKey(shortcut)] = Int(code)
            registered[Self.modifiersKey(shortcut)] = Int(cmdKey)
        }
        defaults.register(defaults: registered)
    }

    // MARK: - Window

    var defaultWidth: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.width)) }
        set { defaults.set(Double(newValue), forKey: Key.width); notify() }
    }

    var defaultHeight: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.height)) }
        set { defaults.set(Double(newValue), forKey: Key.height); notify() }
    }

    var defaultSize: NSSize { NSSize(width: defaultWidth, height: defaultHeight) }

    func setDefaultSize(_ size: NSSize) {
        defaults.set(Double(size.width), forKey: Key.width)
        defaults.set(Double(size.height), forKey: Key.height)
        notify()
    }

    var placement: StickyPlacement {
        get { StickyPlacement(rawValue: defaults.integer(forKey: Key.placement)) ?? .topRight }
        set { defaults.set(newValue.rawValue, forKey: Key.placement); notify() }
    }

    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: Key.alwaysOnTop) }
        set { defaults.set(newValue, forKey: Key.alwaysOnTop); notify() }
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: defaults.integer(forKey: Key.appearance)) ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Key.appearance); notify() }
    }

    func nsAppearance() -> NSAppearance? {
        switch appearance {
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        case .system: return nil
        }
    }

    // MARK: - Launch at login

    var openAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Diag.log("openAtLogin error: \(error)")
            }
        }
    }

    // MARK: - Global hotkey

    var globalHotkey: KeyCombo {
        KeyCombo(
            keyCode: UInt32(defaults.integer(forKey: Key.hotkeyKeyCode)),
            modifiers: UInt32(defaults.integer(forKey: Key.hotkeyModifiers))
        )
    }

    func setGlobalHotkey(_ combo: KeyCombo) {
        defaults.set(Int(combo.keyCode), forKey: Key.hotkeyKeyCode)
        defaults.set(Int(combo.modifiers), forKey: Key.hotkeyModifiers)
        notify()
    }

    // MARK: - In-app shortcuts

    func binding(for shortcut: AppShortcut) -> KeyCombo {
        KeyCombo(
            keyCode: UInt32(defaults.integer(forKey: Self.keyCodeKey(shortcut))),
            modifiers: UInt32(defaults.integer(forKey: Self.modifiersKey(shortcut)))
        )
    }

    func setBinding(_ combo: KeyCombo, for shortcut: AppShortcut) {
        defaults.set(Int(combo.keyCode), forKey: Self.keyCodeKey(shortcut))
        defaults.set(Int(combo.modifiers), forKey: Self.modifiersKey(shortcut))
        notify()
    }

    func allBindings() -> [AppShortcut: KeyCombo] {
        Dictionary(uniqueKeysWithValues: AppShortcut.allCases.map { ($0, binding(for: $0)) })
    }

    // Combos the sticky panel claims before user bindings: ⌘1–9 (18–28) and ⌘⌫ (51), when ⌘ is held without ⇧.
    private static let reservedKeyCodes: Set<UInt32> = [18, 19, 20, 21, 23, 22, 26, 28, 25, 51]

    func isReserved(_ combo: KeyCombo) -> Bool {
        let hasCommand = combo.modifiers & UInt32(cmdKey) != 0
        let hasShift = combo.modifiers & UInt32(shiftKey) != 0
        return hasCommand && !hasShift && Self.reservedKeyCodes.contains(combo.keyCode)
    }

    func isAcceptableBinding(_ combo: KeyCombo, for shortcut: AppShortcut) -> Bool {
        guard combo.modifiers & UInt32(cmdKey) != 0 else { return false } // in-app actions only dispatch with ⌘
        if isReserved(combo) { return false }
        if combo == globalHotkey { return false }
        return !AppShortcut.allCases.contains { $0 != shortcut && binding(for: $0) == combo }
    }

    private static func keyCodeKey(_ shortcut: AppShortcut) -> String { "sc_\(shortcut.rawValue)_key" }
    private static func modifiersKey(_ shortcut: AppShortcut) -> String { "sc_\(shortcut.rawValue)_mod" }

    // MARK: - Placement geometry

    func origin(for placement: StickyPlacement, size: NSSize, in visible: NSRect, stagger: CGFloat) -> NSPoint {
        let margin: CGFloat = 20
        let left = visible.minX + margin + stagger
        let centerX = visible.midX - size.width / 2 + stagger
        let right = visible.maxX - size.width - margin - stagger
        let top = visible.maxY - size.height - margin - stagger
        let centerY = visible.midY - size.height / 2 - stagger
        let bottom = visible.minY + margin + stagger
        switch placement {
        case .topLeft: return NSPoint(x: left, y: top)
        case .top: return NSPoint(x: centerX, y: top)
        case .topRight: return NSPoint(x: right, y: top)
        case .left: return NSPoint(x: left, y: centerY)
        case .center: return NSPoint(x: centerX, y: centerY)
        case .right: return NSPoint(x: right, y: centerY)
        case .bottomLeft: return NSPoint(x: left, y: bottom)
        case .bottom: return NSPoint(x: centerX, y: bottom)
        case .bottomRight: return NSPoint(x: right, y: bottom)
        }
    }

    private func notify() {
        NotificationCenter.default.post(name: SettingsStore.didChange, object: self)
    }
}
