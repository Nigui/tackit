import AppKit

final class DraggableLabel: NSTextField {
    override var mouseDownCanMoveWindow: Bool { true }
}

final class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
}

final class NoteHeaderView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    private let iconLabel = DraggableLabel(labelWithString: "📝")
    private let titleLabel = DraggableLabel(labelWithString: "")
    private let descriptionLabel = DraggableLabel(labelWithString: "")
    private let categoryLabel = DraggableLabel(labelWithString: "")
    private let tagsLabel = DraggableLabel(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.alignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconCard = DraggableView()
        iconCard.wantsLayer = true
        iconCard.layer?.cornerRadius = 10
        iconCard.layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.14).cgColor
        iconCard.translatesAutoresizingMaskIntoConstraints = false
        iconCard.addSubview(iconLabel)

        titleLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.lineBreakMode = .byTruncatingTail

        let titleStack = NSStackView(views: [titleLabel, descriptionLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let topRow = NSStackView(views: [iconCard, titleStack])
        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 12

        categoryLabel.font = .systemFont(ofSize: 11, weight: .medium)
        categoryLabel.textColor = .secondaryLabelColor
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        let categoryPill = DraggableView()
        categoryPill.wantsLayer = true
        categoryPill.layer?.cornerRadius = 6
        categoryPill.layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.14).cgColor
        categoryPill.translatesAutoresizingMaskIntoConstraints = false
        categoryPill.addSubview(categoryLabel)

        tagsLabel.font = .systemFont(ofSize: 11)
        tagsLabel.textColor = .tertiaryLabelColor
        tagsLabel.lineBreakMode = .byTruncatingTail

        let metaRow = NSStackView(views: [categoryPill, tagsLabel])
        metaRow.orientation = .horizontal
        metaRow.alignment = .centerY
        metaRow.spacing = 10

        let stack = NSStackView(views: [topRow, metaRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconCard.widthAnchor.constraint(equalToConstant: 40),
            iconCard.heightAnchor.constraint(equalToConstant: 40),
            iconLabel.centerXAnchor.constraint(equalTo: iconCard.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconCard.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryPill.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryPill.trailingAnchor, constant: -8),
            categoryLabel.topAnchor.constraint(equalTo: categoryPill.topAnchor, constant: 3),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryPill.bottomAnchor, constant: -3),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func configure(icon: String, title: String, description: String, category: String, tags: [String]) {
        iconLabel.stringValue = icon.isEmpty ? "📝" : icon
        let hasDescription = !description.isEmpty
        titleLabel.font = .systemFont(ofSize: hasDescription ? 14 : 19, weight: .semibold)
        titleLabel.stringValue = title
        descriptionLabel.stringValue = description
        descriptionLabel.isHidden = !hasDescription
        categoryLabel.stringValue = category
        tagsLabel.stringValue = tags.map { "#\($0)" }.joined(separator: " ")
        tagsLabel.isHidden = tags.isEmpty
    }
}
