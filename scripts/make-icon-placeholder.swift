import AppKit

// Renders a 1024×1024 placeholder app icon (gold rounded square + "T").
// Replace packaging/AppIcon.png with real branding, then run scripts/make-icon.sh.

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "packaging/AppIcon.png"
let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

let full = NSRect(x: 0, y: 0, width: side, height: side)
let card = full.insetBy(dx: 84, dy: 84)
let path = NSBezierPath(roundedRect: card, xRadius: 190, yRadius: 190)
NSColor(calibratedRed: 0.941, green: 0.725, blue: 0.043, alpha: 1).setFill()
path.fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 560, weight: .bold),
    .foregroundColor: NSColor.black.withAlphaComponent(0.82),
    .paragraphStyle: paragraph,
]
let glyph = "T" as NSString
let glyphSize = glyph.size(withAttributes: attributes)
glyph.draw(
    at: NSPoint(x: card.midX - glyphSize.width / 2, y: card.midY - glyphSize.height / 2),
    withAttributes: attributes
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render icon\n".utf8))
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
