import AppKit

final class NoteFooterView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    private let updatedLabel = DraggableLabel(labelWithString: "")

    init() {
        super.init(frame: .zero)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        updatedLabel.font = .systemFont(ofSize: 11)
        updatedLabel.textColor = .tertiaryLabelColor
        updatedLabel.lineBreakMode = .byTruncatingTail
        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(updatedLabel)

        let actions = DraggableLabel(labelWithString: "⌘K  Actions")
        actions.font = .systemFont(ofSize: 11)
        actions.textColor = .tertiaryLabelColor
        actions.translatesAutoresizingMaskIntoConstraints = false
        actions.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(actions)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            updatedLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            updatedLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            updatedLabel.trailingAnchor.constraint(lessThanOrEqualTo: actions.leadingAnchor, constant: -8),
            actions.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            actions.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func setUpdated(_ date: Date) {
        updatedLabel.stringValue = "Updated " + Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter
    }()
}
