//
//  XTTFormComponents.swift
//  WorkspaceOrganizer
//
//  Reusable labeled form rows for the editor screens.
//

import UIKit

// MARK: - Field Row (label + text field)

final class XTTFieldRow: UIView {

    let textField: XTTTextField

    init(label: String, placeholder: String) {
        textField = XTTTextField(placeholder: placeholder)
        super.init(frame: .zero)

        let caption = UILabel()
        caption.text = label
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let stack = UIStackView(arrangedSubviews: [caption, textField])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Stepper Row (label + quantity stepper)

final class XTTStepperRow: UIView {

    private let valueLabel = UILabel()
    private(set) var value: Int {
        didSet { valueLabel.text = "\(value)" }
    }
    var onChange: ((Int) -> Void)?

    init(label: String, initial: Int) {
        value = max(0, initial)
        super.init(frame: .zero)

        let caption = UILabel()
        caption.text = label
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary

        valueLabel.text = "\(value)"
        valueLabel.font = XTTTheme.roundedFont(20, .bold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let minus = makeStepButton(symbol: "minus")
        minus.addTarget(self, action: #selector(decrement), for: .touchUpInside)
        let plus = makeStepButton(symbol: "plus")
        plus.addTarget(self, action: #selector(increment), for: .touchUpInside)

        let controlStack = UIStackView(arrangedSubviews: [minus, valueLabel, plus])
        controlStack.axis = .horizontal
        controlStack.alignment = .center
        controlStack.spacing = 8

        let container = UIView()
        container.backgroundColor = XTTTheme.card
        container.layer.cornerRadius = XTTTheme.Radius.small
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = XTTTheme.separator.cgColor
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(controlStack)
        controlStack.xtt_pinEdges(to: container, insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

        let stack = UIStackView(arrangedSubviews: [caption, container])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeStepButton(symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = XTTTheme.accent
        button.backgroundColor = XTTTheme.accent.withAlphaComponent(0.14)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 38).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return button
    }

    @objc private func increment() {
        value += 1
        onChange?(value)
    }

    @objc private func decrement() {
        if value > 0 { value -= 1; onChange?(value) }
    }

    func setValue(_ newValue: Int) {
        value = max(0, newValue)
    }
}

// MARK: - Chip Selector (single-select horizontal chips)

/// Single-select horizontal chips.
///
/// Deliberately NON-generic (values are type-erased through `AnyHashable`).
/// An earlier generic version (`XTTChipSelector<T>`) crashed the Release SIL
/// optimizer (`EarlyPerfInliner` on the generic class deinit) once enough
/// distinct `T` instantiations existed. `configure` stays generic as a *method*,
/// so call sites keep passing concrete `Hashable` values with no casts.
final class XTTChipSelector: UIView {

    private struct Option {
        let value: AnyHashable
        let title: String
        let color: UIColor
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var options: [Option] = []
    private var buttons: [UIButton] = []

    /// Currently selected value, type-erased. Use `selectedValue(_:)` for a typed read.
    private(set) var selected: AnyHashable?
    var onSelect: ((AnyHashable) -> Void)?

    init() {
        super.init(frame: .zero)
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 40),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Configure with typed options; values are stored type-erased.
    func configure<T: Hashable>(options: [(value: T, title: String, color: UIColor)], selected: T?) {
        self.options = options.map { Option(value: AnyHashable($0.value), title: $0.title, color: $0.color) }
        self.selected = selected.map { AnyHashable($0) }
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option.title, for: .normal)
            button.titleLabel?.font = XTTTheme.font(14, .semibold)
            button.tag = index
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.layer.cornerRadius = XTTTheme.Radius.pill
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
        updateStyles()
    }

    /// Typed read of the current selection.
    func selectedValue<T: Hashable>(_ type: T.Type) -> T? {
        selected?.base as? T
    }

    @objc private func tapped(_ sender: UIButton) {
        let option = options[sender.tag]
        selected = option.value
        updateStyles()
        onSelect?(option.value)
    }

    private func updateStyles() {
        for (index, button) in buttons.enumerated() {
            let option = options[index]
            let isSelected = option.value == selected
            if isSelected {
                button.backgroundColor = option.color.withAlphaComponent(0.22)
                button.setTitleColor(option.color, for: .normal)
                button.layer.borderColor = option.color.cgColor
            } else {
                button.backgroundColor = XTTTheme.card
                button.setTitleColor(XTTTheme.textSecondary, for: .normal)
                button.layer.borderColor = XTTTheme.separator.cgColor
            }
        }
    }
}

// MARK: - Multiline Notes Row

final class XTTNotesRow: UIView {

    let textView = UITextView()
    private let placeholderLabel = UILabel()

    init(label: String, placeholder: String) {
        super.init(frame: .zero)

        let caption = UILabel()
        caption.text = label
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary

        textView.backgroundColor = XTTTheme.card
        textView.textColor = XTTTheme.textPrimary
        textView.tintColor = XTTTheme.accent
        textView.font = XTTTheme.font(16)
        textView.layer.cornerRadius = XTTTheme.Radius.small
        textView.layer.cornerCurve = .continuous
        textView.layer.borderWidth = 1
        textView.layer.borderColor = XTTTheme.separator.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        textView.delegate = self

        placeholderLabel.text = placeholder
        placeholderLabel.font = XTTTheme.font(16)
        placeholderLabel.textColor = XTTTheme.textTertiary
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16)
        ])

        let stack = UIStackView(arrangedSubviews: [caption, textView])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            placeholderLabel.isHidden = !newValue.isEmpty
        }
    }
}

extension XTTNotesRow: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - Date Row (toggle + date picker)

final class XTTDateRow: UIView {

    private let toggle = UISwitch()
    private let picker = UIDatePicker()
    private let pickerContainer = UIView()

    init(label: String) {
        super.init(frame: .zero)

        let caption = UILabel()
        caption.text = label
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary

        let toggleCaption = UILabel()
        toggleCaption.text = "Has Expiration Date"
        toggleCaption.font = XTTTheme.font(16)
        toggleCaption.textColor = XTTTheme.textPrimary

        toggle.onTintColor = XTTTheme.accent
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        let toggleRow = UIStackView(arrangedSubviews: [toggleCaption, toggle])
        toggleRow.axis = .horizontal
        toggleRow.alignment = .center

        picker.datePickerMode = .date
        picker.tintColor = XTTTheme.accent
        picker.overrideUserInterfaceStyle = .dark
        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .inline
        }
        picker.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.addSubview(picker)
        picker.xtt_pinEdges(to: pickerContainer)
        pickerContainer.isHidden = true

        let stack = UIStackView(arrangedSubviews: [caption, toggleRow, pickerContainer])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func toggleChanged() {
        UIView.animate(withDuration: 0.2) {
            self.pickerContainer.isHidden = !self.toggle.isOn
        }
    }

    /// Configure with an existing date (nil = disabled).
    func configure(date: Date?) {
        if let date = date {
            toggle.isOn = true
            picker.date = date
            pickerContainer.isHidden = false
        } else {
            toggle.isOn = false
            pickerContainer.isHidden = true
        }
    }

    /// Returns the selected date, or nil if the toggle is off.
    var selectedDate: Date? {
        toggle.isOn ? picker.date : nil
    }
}

// MARK: - Date & Time Row (always-on combined picker)

/// A labeled inline date + time picker that is always visible (no toggle).
/// Used where a date is required, e.g. a schedule entry.
final class XTTDateTimeRow: UIView {

    private let picker = UIDatePicker()

    init(label: String) {
        super.init(frame: .zero)

        let caption = UILabel()
        caption.text = label
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary

        picker.datePickerMode = .dateAndTime
        picker.tintColor = XTTTheme.accent
        picker.overrideUserInterfaceStyle = .dark
        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .inline
        }

        let container = UIView()
        container.backgroundColor = XTTTheme.card
        container.layer.cornerRadius = XTTTheme.Radius.small
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = XTTTheme.separator.cgColor
        picker.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(picker)
        picker.xtt_pinEdges(to: container, insets: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))

        let stack = UIStackView(arrangedSubviews: [caption, container])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(date: Date) {
        picker.date = date
    }

    var selectedDate: Date {
        picker.date
    }
}
