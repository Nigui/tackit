import AppKit
import Carbon.HIToolbox

final class IconButton: NSButton {
    var onPick: ((String) -> Void)?
    private lazy var picker = IconPicker()

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 48, height: 48))
        isBordered = true
        bezelStyle = .regularSquare
        font = .systemFont(ofSize: 26)
        setButtonType(.momentaryChange)
        target = self
        action = #selector(showPicker)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    func setIcon(_ icon: String) { title = icon.isEmpty ? "📝" : icon }

    @objc private func showPicker() {
        picker.onPick = { [weak self] icon in
            self?.setIcon(icon)
            self?.onPick?(icon)
        }
        picker.show(from: self, current: title)
    }
}

final class IconGridView: NSView {
    var onPick: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let icons: [String]
    private let columns: Int
    private let cell: CGFloat = 40
    private let spacing: CGFloat = 6
    private let inset: CGFloat = 12
    private var cellRects: [NSRect] = []
    private var selected = 0

    init(icons: [String], columns: Int) {
        self.icons = icons
        self.columns = columns
        let rows = Int((Double(icons.count) / Double(columns)).rounded(.up))
        let width = inset * 2 + CGFloat(columns) * cell + CGFloat(columns - 1) * spacing
        let height = inset * 2 + CGFloat(rows) * cell + CGFloat(rows - 1) * spacing
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        for index in icons.indices {
            let column = index % columns
            let row = index / columns
            cellRects.append(NSRect(
                x: inset + CGFloat(column) * (cell + spacing),
                y: height - inset - cell - CGFloat(row) * (cell + spacing),
                width: cell,
                height: cell
            ))
        }
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func select(icon: String) {
        selected = icons.firstIndex(of: icon) ?? 0
        needsDisplay = true
    }

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }

    override func draw(_ dirtyRect: NSRect) {
        for (index, rect) in cellRects.enumerated() {
            if index == selected {
                let path = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 8, yRadius: 8)
                Theme.overlayFocus.setFill()
                path.fill()
            }
            let attributed = NSAttributedString(
                string: icons[index],
                attributes: [.font: NSFont.systemFont(ofSize: 22)]
            )
            let size = attributed.size()
            attributed.draw(at: NSPoint(
                x: rect.midX - size.width / 2,
                y: rect.midY - size.height / 2
            ))
        }
    }

    private func move(by delta: Int) {
        let next = selected + delta
        guard next >= 0, next < icons.count else { return }
        selected = next
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_LeftArrow: move(by: -1)
        case kVK_RightArrow: move(by: 1)
        case kVK_UpArrow: move(by: -columns)
        case kVK_DownArrow: move(by: columns)
        case kVK_Return, kVK_ANSI_KeypadEnter, kVK_Space:
            onPick?(icons[selected])
        case kVK_Escape:
            onCancel?()
        default:
            super.keyDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let index = cellRects.firstIndex(where: { $0.contains(point) }) else { return }
        selected = index
        onPick?(icons[index])
    }
}

final class IconPicker {
    var onPick: ((String) -> Void)?

    private let popover = NSPopover()
    private let grid: IconGridView

    static let icons: [String] = [
        "📝", "✅", "📌", "🔖", "💡", "🔥",
        "⭐", "📅", "💰", "🔑", "📧", "📞",
        "🏠", "🛒", "✈️", "🎯", "📎", "📁",
        "❤️", "⚠️", "🎁", "🍎", "☕", "🎵",
    ]

    init() {
        grid = IconGridView(icons: Self.icons, columns: 6)
        popover.behavior = .transient
        let controller = NSViewController()
        controller.view = grid
        popover.contentViewController = controller
        grid.onPick = { [weak self] icon in
            self?.onPick?(icon)
            self?.popover.performClose(nil)
        }
        grid.onCancel = { [weak self] in self?.popover.performClose(nil) }
    }

    func show(from view: NSView, current: String) {
        grid.select(icon: current)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
        grid.window?.makeFirstResponder(grid)
    }
}
