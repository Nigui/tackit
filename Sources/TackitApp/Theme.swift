import AppKit

enum Theme {
    static let accent = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1.0)
    static let cornerRadius: CGFloat = 12

    // Modal overlays (config / actions) — solid accent background (light mode).
    // Dark ink on top for contrast; dark focus/selection since accent is now the bg.
    static let overlayBackground = accent
    static let onOverlay = NSColor(calibratedWhite: 0.06, alpha: 1.0)
    static let onOverlaySecondary = NSColor(calibratedWhite: 0.06, alpha: 0.85)
    static let onOverlayTertiary = NSColor(calibratedWhite: 0.06, alpha: 0.62)
    static let overlayPlaceholder = NSColor(calibratedWhite: 0.06, alpha: 0.5)
    static let overlayField = NSColor(calibratedWhite: 0.0, alpha: 0.06)
    static let overlayFieldBorder = NSColor(calibratedWhite: 0.0, alpha: 0.28)
    static let overlayFocus = NSColor(calibratedWhite: 0.06, alpha: 0.95)
    static let overlaySelectionText = NSColor.white
}
