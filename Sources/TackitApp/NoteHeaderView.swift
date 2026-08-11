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
        addSubview(iconCard)

        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.cell?.truncatesLastVisibleLine = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.cell?.truncatesLastVisibleLine = true
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        descriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let titleStack = NSStackView(views: [titleLabel, descriptionLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 2
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleStack)

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
        tagsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let metaRow = NSStackView(views: [categoryPill, tagsLabel])
        metaRow.orientation = .horizontal
        metaRow.alignment = .centerY
        metaRow.spacing = 10
        metaRow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metaRow)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        let metaTopFromIcon = metaRow.topAnchor.constraint(greaterThanOrEqualTo: iconCard.bottomAnchor, constant: 10)
        let metaTopFromTitle = metaRow.topAnchor.constraint(greaterThanOrEqualTo: titleStack.bottomAnchor, constant: 10)

        NSLayoutConstraint.activate([
            iconCard.widthAnchor.constraint(equalToConstant: 40),
            iconCard.heightAnchor.constraint(equalToConstant: 40),
            iconCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconCard.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconLabel.centerXAnchor.constraint(equalTo: iconCard.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconCard.centerYAnchor),

            titleStack.leadingAnchor.constraint(equalTo: iconCard.trailingAnchor, constant: 12),
            titleStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),
            titleStack.centerYAnchor.constraint(equalTo: iconCard.centerYAnchor),

            categoryLabel.leadingAnchor.constraint(equalTo: categoryPill.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryPill.trailingAnchor, constant: -8),
            categoryLabel.topAnchor.constraint(equalTo: categoryPill.topAnchor, constant: 3),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryPill.bottomAnchor, constant: -3),

            metaTopFromIcon,
            metaTopFromTitle,
            metaRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            metaRow.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),
            metaRow.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -10),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func configure(icon: String, title: String, description: String, category: String, tags: [String]) {
        iconLabel.stringValue = icon.isEmpty ? "📝" : icon
        let hasDescription = !description.isEmpty
        titleLabel.font = .systemFont(ofSize: hasDescription ? 14 : 19, weight: .semibold)
        titleLabel.stringValue = title
        titleLabel.toolTip = title
        descriptionLabel.stringValue = description
        descriptionLabel.toolTip = description
        descriptionLabel.isHidden = !hasDescription
        categoryLabel.stringValue = category
        tagsLabel.stringValue = tags.map { "#\($0)" }.joined(separator: " ")
        tagsLabel.isHidden = tags.isEmpty
    }
}
