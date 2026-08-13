import AppKit

final class SettingsWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func cancelOperation(_ sender: Any?) { close() }
}

final class SettingsWindowController: NSWindowController {
    private let settings: SettingsStore
    private let onRecordingChange: (Bool) -> Void

    private static let sizePresets: [NSSize] = [
        NSSize(width: 320, height: 388),
        NSSize(width: 380, height: 460),
        NSSize(width: 460, height: 557),
    ]

    private var focusables: [NSView] = []

    init(settings: SettingsStore, onRecordingChange: @escaping (Bool) -> Void) {
        self.settings = settings
        self.onRecordingChange = onRecordingChange
        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        super.init(window: window)
        buildContent()
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func buildContent() {
        let card = ThemedView(fill: { Theme.overlayBackground }, cornerRadius: 12, border: { NSColor.separatorColor }, borderWidth: 1)

        let title = titleLabel("Settings", size: 18, weight: .bold)
        card.addSubview(title)

        let sizeControl = SegmentedBar(
            segments: ["Small", "Medium", "Large"],
            selectedIndex: Self.sizePresets.firstIndex { abs($0.width - settings.defaultWidth) < 1 } ?? 1
        )
        sizeControl.onChange = { [weak self] index in
            guard let self else { return }
            self.settings.setDefaultSize(Self.sizePresets[min(index, Self.sizePresets.count - 1)])
        }

        let placement = PlacementPicker(selected: settings.placement) { [weak self] in self?.settings.placement = $0 }

        let alwaysSwitch = ToggleSwitch(isOn: settings.alwaysOnTop)
        alwaysSwitch.onToggle = { [weak self] in self?.settings.alwaysOnTop = $0 }

        let loginSwitch = ToggleSwitch(isOn: settings.openAtLogin)
        loginSwitch.onToggle = { [weak self] in self?.settings.openAtLogin = $0 }

        let themeControl = SegmentedBar(segments: ["Light", "System", "Dark"], selectedIndex: settings.appearance.rawValue)
        themeControl.onChange = { [weak self] index in
            if let mode = AppearanceMode(rawValue: index) { self?.settings.appearance = mode }
        }

        var elements: [NSView] = [
            heading("Appearance"),
            row("Theme", "Light, follow macOS, or dark", control: themeControl, focusable: themeControl),
            spacer(),
            heading("Window"),
            row("Default size", nil, control: sizeControl, focusable: sizeControl),
            row("Default placement", "Where a note floats in", control: placement, focusable: placement),
            row("Always on top", "Float above other apps", control: alwaysSwitch, focusable: alwaysSwitch),
            row("Open at login", "Launch Tackit at startup", control: loginSwitch, focusable: loginSwitch),
            spacer(),
            heading("Keyboard shortcuts"),
            shortcutRow("Show / hide all notes", "Global", recorder: makeRecorder(settings.globalHotkey) { [weak self] in self?.settings.setGlobalHotkey($0) }),
        ]
        for shortcut in AppShortcut.allCases {
            let recorder = makeRecorder(
                settings.binding(for: shortcut),
                accepts: { [weak self] combo in self?.settings.isAcceptableBinding(combo, for: shortcut) ?? true }
            ) { [weak self] in self?.settings.setBinding($0, for: shortcut) }
            elements.append(shortcutRow(shortcut.label, nil, recorder: recorder))
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        var previousWasRow = false
        for element in elements {
            let isRow = element is RowView
            if isRow, previousWasRow {
                let separator = self.separator()
                stack.addArrangedSubview(separator)
                separator.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            }
            stack.addArrangedSubview(element)
            if isRow {
                element.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            }
            previousWasRow = isRow
        }
        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.documentView = document
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(scrollView)

        let footerBar = ThemedView(fill: { Theme.overlayFooter })
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(footerBar)

        let footerSeparator = NSBox()
        footerSeparator.boxType = .separator
        footerSeparator.translatesAutoresizingMaskIntoConstraints = false
        footerBar.addSubview(footerSeparator)

        let footerLabel = titleLabel("Esc to close", size: 11, weight: .regular)
        footerLabel.textColor = Theme.onOverlayTertiary
        footerBar.addSubview(footerLabel)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            scrollView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: footerBar.topAnchor),
            document.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            document.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor),
            footerBar.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            footerBar.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            footerBar.heightAnchor.constraint(equalToConstant: 32),
            footerSeparator.topAnchor.constraint(equalTo: footerBar.topAnchor),
            footerSeparator.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            footerSeparator.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor, constant: -18),
            footerLabel.centerYAnchor.constraint(equalTo: footerBar.centerYAnchor),
        ])
        window?.contentView = card

        wireKeyLoop()
    }

    private func wireKeyLoop() {
        for (index, view) in focusables.enumerated() {
            view.nextKeyView = focusables[(index + 1) % focusables.count]
        }
        window?.initialFirstResponder = focusables.first
    }

    // MARK: - Builders

    private func titleLabel(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = Theme.onOverlay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func heading(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = Theme.onOverlay
        return label
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.heightAnchor.constraint(equalToConstant: 10).isActive = true
        return view
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func row(_ title: String, _ description: String?, control: NSView, focusable: NSView?) -> NSView {
        if let focusable { focusables.append(focusable) }
        return rowContainer(title, description, control: control)
    }

    private func shortcutRow(_ title: String, _ description: String?, recorder: ShortcutRecorderView?, readOnly: String? = nil) -> NSView {
        let control: NSView
        if let recorder {
            focusables.append(recorder)
            control = recorder
        } else {
            let label = NSTextField(labelWithString: readOnly ?? "")
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = Theme.onOverlaySecondary
            control = label
        }
        return rowContainer(title, description, control: control)
    }

    private func rowContainer(_ title: String, _ description: String?, control: NSView) -> NSView {
        let container = RowView()

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = Theme.onOverlay

        var textViews: [NSView] = [titleLabel]
        if let description {
            let descLabel = NSTextField(labelWithString: description)
            descLabel.font = .systemFont(ofSize: 11)
            descLabel.textColor = Theme.onOverlaySecondary
            textViews.append(descLabel)
        }
        let textStack = NSStackView(views: textViews)
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)

        control.translatesAutoresizingMaskIntoConstraints = false
        control.setContentHuggingPriority(.required, for: .horizontal)
        container.addSubview(control)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 11),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -11),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -12),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            control.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 9),
            control.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -9),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 46),
        ])
        return container
    }

    private func makeRecorder(_ combo: KeyCombo, accepts: ((KeyCombo) -> Bool)? = nil, onRecord: @escaping (KeyCombo) -> Void) -> ShortcutRecorderView {
        let recorder = ShortcutRecorderView(combo: combo)
        recorder.onRecord = onRecord
        recorder.accepts = accepts
        recorder.onRecordingChange = { [weak self] recording in self?.onRecordingChange(recording) }
        return recorder
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        if let first = focusables.first { window?.makeFirstResponder(first) }
    }
}

/// Full-width settings row; participates in the vertical stack's width matching.
final class RowView: NSView {}
