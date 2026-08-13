import AppKit

enum Theme {
    static let accent = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1.0)
    static let cornerRadius: CGFloat = 12

    private static func dynamic(_ light: NSColor, _ dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    private static func w(_ white: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(calibratedWhite: white, alpha: alpha)
    }

    // Modal overlays (config / actions / search / settings).
    // Light: solid accent-gold surface with dark ink and dark selection.
    // Dark: inverted — a dark surface with light ink and accent-gold selection.
    static let overlayBackground = dynamic(accent, NSColor(calibratedRed: 0.12, green: 0.115, blue: 0.10, alpha: 1))
    static let overlayFooter = dynamic(w(0, 0.10), w(1, 0.06))
    static let onOverlay = dynamic(w(0.08, 1), w(0.96, 1))
    static let onOverlaySecondary = dynamic(w(0.08, 0.85), w(0.96, 0.72))
    static let onOverlayTertiary = dynamic(w(0.08, 0.60), w(0.96, 0.50))
    static let overlayPlaceholder = dynamic(w(0.08, 0.50), w(0.96, 0.40))
    static let overlayField = dynamic(w(0, 0.06), w(1, 0.08))
    static let overlayFieldBorder = dynamic(w(0, 0.28), w(1, 0.22))
    static let overlayFocus = dynamic(w(0.06, 0.95), accent)
    static let overlaySelectionText = dynamic(.white, .black)
    static let keyCapBackground = dynamic(w(1, 0.55), w(1, 0.16))
}
