import AppKit

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

    func setIcon(_ icon: String) { title = icon.isEmpty ? "📝" : icon }

    @objc private func showPicker() {
        picker.onPick = { [weak self] icon in
            self?.setIcon(icon)
            self?.onPick?(icon)
        }
        picker.show(from: self)
    }
}

final class IconPicker {
    var onPick: ((String) -> Void)?

    private let popover = NSPopover()

    static let icons: [String] = [
        "📝", "✅", "📌", "🔖", "💡", "🔥",
        "⭐", "📅", "💰", "🔑", "📧", "📞",
        "🏠", "🛒", "✈️", "🎯", "📎", "📁",
        "❤️", "⚠️", "🎁", "🍎", "☕", "🎵",
    ]

    init() {
        popover.behavior = .transient
        popover.contentViewController = makeGridController()
    }

    func show(from view: NSView) {
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }

    private func makeGridController() -> NSViewController {
        let columns = 6
        let cell: CGFloat = 40
        let spacing: CGFloat = 6
        let inset: CGFloat = 12
        let rows = Int((Double(Self.icons.count) / Double(columns)).rounded(.up))
        let width = inset * 2 + CGFloat(columns) * cell + CGFloat(columns - 1) * spacing
        let height = inset * 2 + CGFloat(rows) * cell + CGFloat(rows - 1) * spacing

        let root = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        for (index, icon) in Self.icons.enumerated() {
            let column = index % columns
            let row = index / columns
            let button = NSButton(frame: NSRect(
                x: inset + CGFloat(column) * (cell + spacing),
                y: height - inset - cell - CGFloat(row) * (cell + spacing),
                width: cell,
                height: cell
            ))
            button.title = icon
            button.font = .systemFont(ofSize: 22)
            button.isBordered = false
            button.bezelStyle = .regularSquare
            button.setButtonType(.momentaryChange)
            button.target = self
            button.action = #selector(pick(_:))
            button.identifier = NSUserInterfaceItemIdentifier(icon)
            root.addSubview(button)
        }

        let controller = NSViewController()
        controller.view = root
        return controller
    }

    @objc private func pick(_ sender: NSButton) {
        onPick?(sender.title)
        popover.performClose(nil)
    }
}
