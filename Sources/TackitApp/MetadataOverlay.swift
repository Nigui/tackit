import AppKit
import TackitCore

final class MetadataOverlay: NSVisualEffectView {
    var onCommit: ((NoteMetadata) -> Void)?
    var onClose: (() -> Void)?

    private var meta = NoteMetadata()

    private let iconButton = IconButton()
    private let titleField = AccentTextField(placeholder: "Title")
    private let descriptionField = AccentTextField(placeholder: "Description")
    private let groupField = GroupTypeaheadField()
    private let tagsView = TagsInputView()
    private let createdValue = MetadataOverlay.infoValue()
    private let updatedValue = MetadataOverlay.infoValue()
    private let fileValue = MetadataOverlay.infoValue()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func buildUI() {
        let heading = NSTextField(labelWithString: "Configure this note")
        heading.font = .systemFont(ofSize: 18, weight: .bold)
        heading.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heading)

        iconButton.onPick = { [weak self] icon in
            self?.meta.icon = icon
            self?.commit()
        }

        titleField.delegate = self
        descriptionField.delegate = self

        groupField.host = self
        groupField.onChange = { [weak self] group in
            self?.meta.group = group
            self?.commit()
        }

        tagsView.onChange = { [weak self] tags in
            self?.meta.tags = tags
            self?.commit()
        }

        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        content.addArrangedSubview(fieldRow("ICON", "⌘I", iconButton, fullWidth: false))
        for (name, key, field) in [
            ("TITLE", "⌘T", titleField as NSView),
            ("DESCRIPTION", "⌘D", descriptionField),
            ("GROUP", "⌘G", groupField),
            ("TAGS", "⌘⇧T", tagsView),
        ] {
            let row = fieldRow(name, key, field, fullWidth: true)
            content.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        }

        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true

        let info = NSStackView(views: [
            infoRow("Created", createdValue),
            infoRow("Updated", updatedValue),
            infoRow("File", fileValue),
        ])
        info.orientation = .vertical
        info.alignment = .leading
        info.spacing = 3
        content.addArrangedSubview(info)
        info.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true

        let footer = makeFooter()
        addSubview(footer)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            content.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(lessThanOrEqualTo: footer.topAnchor, constant: -12),
            footer.leadingAnchor.constraint(equalTo: leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: 30),
        ])

        titleField.nextKeyView = descriptionField
        descriptionField.nextKeyView = groupField.textField
        groupField.textField.nextKeyView = tagsView.textField
        tagsView.textField.nextKeyView = titleField
    }

    private func makeFooter() -> NSView {
        let footer = NSView()
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
        footer.translatesAutoresizingMaskIntoConstraints = false

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(separator)

        let hint = NSTextField(labelWithString: "⌘K or Esc to close")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .tertiaryLabelColor
        hint.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(hint)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: footer.topAnchor),
            separator.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            hint.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            hint.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
        ])
        return footer
    }

    private func fieldRow(_ name: String, _ key: String, _ field: NSView, fullWidth: Bool) -> NSStackView {
        let row = NSStackView(views: [captionLabel(name, key), field])
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 6
        if fullWidth {
            field.widthAnchor.constraint(equalTo: row.widthAnchor).isActive = true
        }
        return row
    }

    private func captionLabel(_ name: String, _ key: String) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        let string = NSMutableAttributedString(
            string: name,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor,
                .kern: 0.8,
            ]
        )
        string.append(NSAttributedString(
            string: "  " + key,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.tertiaryLabelColor,
            ]
        ))
        label.attributedStringValue = string
        return label
    }

    private func infoRow(_ caption: String, _ value: NSTextField) -> NSStackView {
        let label = NSTextField(labelWithString: caption)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabelColor
        label.widthAnchor.constraint(equalToConstant: 64).isActive = true
        let row = NSStackView(views: [label, value])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        value.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }

    private static func infoValue() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.cell?.truncatesLastVisibleLine = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard !isHidden, event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        let shift = event.modifierFlags.contains(.shift)
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "i" where !shift: iconButton.performClick(nil); return true
        case "t" where !shift: window?.makeFirstResponder(titleField); return true
        case "d" where !shift: window?.makeFirstResponder(descriptionField); return true
        case "g" where !shift: window?.makeFirstResponder(groupField.textField); return true
        case "t" where shift: window?.makeFirstResponder(tagsView.textField); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }

    func present(metadata: NoteMetadata, groups: [String], filePath: String) {
        meta = metadata
        iconButton.setIcon(metadata.icon)
        titleField.stringValue = metadata.title
        descriptionField.stringValue = metadata.description
        groupField.configure(groups: groups, selected: metadata.group)
        tagsView.setTags(metadata.tags)
        createdValue.stringValue = Self.dateFormatter.string(from: metadata.createdAt)
        updatedValue.stringValue = Self.dateFormatter.string(from: metadata.updatedAt)
        fileValue.stringValue = filePath
        fileValue.toolTip = filePath
        isHidden = false
        layoutSubtreeIfNeeded()
        window?.makeFirstResponder(titleField)
    }

    private func commit() { onCommit?(meta) }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension MetadataOverlay: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        if control === titleField {
            meta.title = titleField.stringValue
            commit()
        } else if control === descriptionField {
            meta.description = descriptionField.stringValue
            commit()
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            onClose?()
            return true
        }
        return false
    }
}
