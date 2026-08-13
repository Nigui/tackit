import AppKit

// Renders a GitHub social-preview image (1280×640) → assets/social-preview.png.

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "assets/social-preview.png"
let W: CGFloat = 1280
let H: CGFloat = 640
let gold = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1)
let goldText = NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.22, alpha: 1)

func drawCentered(_ text: String, baselineY: CGFloat, attrs: [NSAttributedString.Key: Any]) {
    let string = text as NSString
    let width = string.size(withAttributes: attrs).width
    string.draw(at: NSPoint(x: (W - width) / 2, y: baselineY), withAttributes: attrs)
}

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()

// background — warm near-black
NSColor(calibratedRed: 0.07, green: 0.06, blue: 0.035, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// icon tile (centered, upper area)
let tileSide: CGFloat = 220
let tile = NSRect(x: (W - tileSide) / 2, y: H - 96 - tileSide, width: tileSide, height: tileSide)
gold.setFill()
NSBezierPath(roundedRect: tile, xRadius: 48, yRadius: 48).fill()
let tileGlyphAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 142, weight: .bold),
    .foregroundColor: NSColor.black.withAlphaComponent(0.82),
]
let tileGlyph = "T" as NSString
let tileGlyphSize = tileGlyph.size(withAttributes: tileGlyphAttrs)
tileGlyph.draw(
    at: NSPoint(x: tile.midX - tileGlyphSize.width / 2, y: tile.midY - tileGlyphSize.height / 2),
    withAttributes: tileGlyphAttrs
)

// wordmark
drawCentered("Tackit", baselineY: 214, attrs: [
    .font: NSFont.systemFont(ofSize: 104, weight: .bold),
    .foregroundColor: goldText,
])

// tagline
drawCentered("Blazing-fast, keyboard-driven sticky notes for macOS", baselineY: 158, attrs: [
    .font: NSFont.systemFont(ofSize: 30, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.82, alpha: 1),
])

// hotkey hint
drawCentered("⌘⇧.  summon   ·   ⌘K  actions   ·   ⌘O  search", baselineY: 104, attrs: [
    .font: NSFont.monospacedSystemFont(ofSize: 22, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1),
])

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render social preview\n".utf8))
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
