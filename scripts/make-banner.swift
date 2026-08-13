import AppKit

// Renders a README/product banner (1280×400) → assets/banner.png.

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "assets/banner.png"
let W: CGFloat = 1280
let H: CGFloat = 400
let gold = NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1)
let goldText = NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.22, alpha: 1)

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()

// background — warm near-black (reads in GitHub light + dark)
NSColor(calibratedRed: 0.07, green: 0.06, blue: 0.035, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// icon tile
let tile = NSRect(x: 96, y: H / 2 - 92, width: 184, height: 184)
gold.setFill()
NSBezierPath(roundedRect: tile, xRadius: 42, yRadius: 42).fill()
let tileGlyphAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 118, weight: .bold),
    .foregroundColor: NSColor.black.withAlphaComponent(0.82),
]
let tileGlyph = "T" as NSString
let tileGlyphSize = tileGlyph.size(withAttributes: tileGlyphAttrs)
tileGlyph.draw(
    at: NSPoint(x: tile.midX - tileGlyphSize.width / 2, y: tile.midY - tileGlyphSize.height / 2),
    withAttributes: tileGlyphAttrs
)

// wordmark
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 96, weight: .bold),
    .foregroundColor: goldText,
]
("Tackit" as NSString).draw(at: NSPoint(x: 328, y: 206), withAttributes: titleAttrs)

// tagline
let taglineAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 30, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.82, alpha: 1),
]
("Blazing-fast, keyboard-driven sticky notes for macOS" as NSString)
    .draw(at: NSPoint(x: 332, y: 150), withAttributes: taglineAttrs)

// hotkey hint
let hintAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 22, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1),
]
("⌘⇧.  to summon  ·  ⌘K  actions  ·  ⌘O  search" as NSString)
    .draw(at: NSPoint(x: 332, y: 104), withAttributes: hintAttrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render banner\n".utf8))
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
