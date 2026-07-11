//
//  XTTUIComponents.swift
//  WorkspaceOrganizer
//
//  Reusable dark-utility UI building blocks, all iOS 14 safe.
//

import UIKit

// MARK: - Gradient View

/// A view whose layer is a gradient. Handy for cover art & accent chrome.
final class XTTGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(colors: [CGColor],
         start: CGPoint = CGPoint(x: 0, y: 0),
         end: CGPoint = CGPoint(x: 1, y: 1)) {
        super.init(frame: .zero)
        gradientLayer.colors = colors
        gradientLayer.startPoint = start
        gradientLayer.endPoint = end
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setColors(_ colors: [CGColor]) {
        gradientLayer.colors = colors
    }
}

// MARK: - Card View

/// A rounded dark card with a subtle gradient sheen and hairline border.
class XTTCardView: UIView {

    private let gradient = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = XTTTheme.card
        layer.cornerRadius = XTTTheme.Radius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.separator.withAlphaComponent(0.5).cgColor

        gradient.colors = XTTTheme.cardGradient
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.cornerRadius = XTTTheme.Radius.medium
        layer.insertSublayer(gradient, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}

// MARK: - Primary Button

/// Filled, gradient action button. Works on iOS 14 (no UIButton.Configuration).
final class XTTPrimaryButton: UIButton {

    private let gradient = CAGradientLayer()

    var useOrange: Bool = false {
        didSet { applyGradientColors() }
    }

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        setTitleColor(.white, for: .normal)
        titleLabel?.font = XTTTheme.font(17, .semibold)
        layer.cornerRadius = XTTTheme.Radius.small
        layer.cornerCurve = .continuous
        clipsToBounds = true

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
        applyGradientColors()
    }

    private func applyGradientColors() {
        gradient.colors = useOrange ? XTTTheme.orangeGradient : XTTTheme.accentGradient
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1.0 }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = max(size.height, 54)
        return size
    }
}

// MARK: - Ghost Button

/// Bordered, transparent secondary button.
final class XTTGhostButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        setTitleColor(XTTTheme.textPrimary, for: .normal)
        titleLabel?.font = XTTTheme.font(16, .medium)
        layer.cornerRadius = XTTTheme.Radius.small
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.separator.cgColor
        backgroundColor = XTTTheme.card
    }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? XTTTheme.cardHighlight : XTTTheme.card }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = max(size.height, 52)
        return size
    }
}

// MARK: - Status Pill

/// A small rounded label showing an item status with dot + text.
final class XTTStatusPill: UIView {

    private let dot = UIView()
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        layer.cornerRadius = XTTTheme.Radius.pill
        layer.cornerCurve = .continuous

        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.layer.cornerRadius = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = XTTTheme.font(12, .semibold)

        addSubview(dot)
        addSubview(label)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }

    func configure(status: XTTItemStatus) {
        label.text = status.rawValue.uppercased()
        label.textColor = status.color
        dot.backgroundColor = status.color
        backgroundColor = status.color.withAlphaComponent(0.14)
    }

    func configure(text: String, color: UIColor) {
        label.text = text.uppercased()
        label.textColor = color
        dot.backgroundColor = color
        backgroundColor = color.withAlphaComponent(0.14)
    }
}

// MARK: - Icon Badge

/// A rounded square tinted background holding an SF Symbol.
final class XTTIconBadge: UIView {

    private let imageView = UIImageView()

    init(size: CGFloat = 44) {
        super.init(frame: .zero)
        setup()
        widthAnchor.constraint(equalToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        layer.cornerRadius = XTTTheme.Radius.small
        layer.cornerCurve = .continuous
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(symbol: String, tint: UIColor) {
        imageView.image = UIImage(systemName: symbol)
        imageView.tintColor = tint
        backgroundColor = tint.withAlphaComponent(0.16)
    }
}

// MARK: - Section Header Label

final class XTTSectionHeader: UILabel {
    init(_ title: String) {
        super.init(frame: .zero)
        text = title.uppercased()
        font = XTTTheme.font(13, .bold)
        textColor = XTTTheme.textTertiary
        setContentHuggingPriority(.required, for: .vertical)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Convenience factory used by card layouts.
    static func styled(_ title: String) -> XTTSectionHeader {
        XTTSectionHeader(title)
    }
}

// MARK: - Empty State View

/// A friendly empty-state placeholder with icon, title and message.
final class XTTEmptyStateView: UIView {

    private let badge = XTTIconBadge(size: 72)
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: [badge, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = XTTTheme.Spacing.s
        stack.setCustomSpacing(XTTTheme.Spacing.m, after: badge)
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = XTTTheme.font(18, .semibold)
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.textAlignment = .center

        messageLabel.font = XTTTheme.font(14)
        messageLabel.textColor = XTTTheme.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
        ])
    }

    func configure(symbol: String, title: String, message: String, tint: UIColor = XTTTheme.accent) {
        badge.configure(symbol: symbol, tint: tint)
        titleLabel.text = title
        messageLabel.text = message
    }
}

// MARK: - Styled Text Field

/// A dark card-styled text field with left inset.
final class XTTTextField: UITextField {

    private let padding = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

    init(placeholder: String) {
        super.init(frame: .zero)
        setup(placeholder: placeholder)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(placeholder: String) {
        backgroundColor = XTTTheme.card
        textColor = XTTTheme.textPrimary
        tintColor = XTTTheme.accent
        font = XTTTheme.font(16)
        layer.cornerRadius = XTTTheme.Radius.small
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.separator.cgColor
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: XTTTheme.textTertiary]
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
}

