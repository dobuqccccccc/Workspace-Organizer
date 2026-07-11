//
//  XTTItemCell.swift
//  WorkspaceOrganizer
//
//  Card-style table cell representing a single item.
//

import UIKit

final class XTTItemCell: UITableViewCell {

    static let reuseID = "XTTItemCell"

    private let card = XTTCardView()
    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let photoView = UIImageView()
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private let statusPill = XTTStatusPill()
    private let quantityLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: XTTTheme.Spacing.m),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -XTTTheme.Spacing.m)
        ])

        iconWrap.backgroundColor = XTTTheme.accent.withAlphaComponent(0.14)
        iconWrap.layer.cornerRadius = 12
        iconWrap.layer.cornerCurve = .continuous
        iconWrap.clipsToBounds = true
        iconWrap.translatesAutoresizingMaskIntoConstraints = false

        iconView.tintColor = XTTTheme.accent
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(photoView)
        photoView.xtt_pinEdges(to: iconWrap)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor)
        ])

        nameLabel.font = XTTTheme.font(16, .semibold)
        nameLabel.textColor = XTTTheme.textPrimary
        nameLabel.numberOfLines = 1

        metaLabel.font = XTTTheme.font(13)
        metaLabel.textColor = XTTTheme.textSecondary
        metaLabel.numberOfLines = 1

        quantityLabel.font = XTTTheme.roundedFont(15, .bold)
        quantityLabel.textColor = XTTTheme.textPrimary
        quantityLabel.textAlignment = .right
        quantityLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        statusPill.translatesAutoresizingMaskIntoConstraints = false
        statusPill.setContentHuggingPriority(.required, for: .horizontal)

        [iconWrap, textStack, statusPill, quantityLabel].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconWrap.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 46),
            iconWrap.heightAnchor.constraint(equalToConstant: 46),
            iconView.widthAnchor.constraint(equalToConstant: 46),
            iconView.heightAnchor.constraint(equalToConstant: 46),

            textStack.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -8),

            quantityLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            quantityLabel.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),

            statusPill.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            statusPill.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 8),
            statusPill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    func configure(with item: XTTItem) {
        nameLabel.text = item.name
        iconView.image = UIImage(systemName: item.category.iconName)

        if let photo = XTTImageStore.load(item.photoFileName) {
            photoView.image = photo
            photoView.isHidden = false
            iconView.isHidden = true
            iconWrap.backgroundColor = .clear
        } else {
            photoView.image = nil
            photoView.isHidden = true
            iconView.isHidden = false
            iconWrap.backgroundColor = XTTTheme.accent.withAlphaComponent(0.14)
        }

        var metaParts: [String] = [item.category.rawValue]
        if !item.location.isEmpty { metaParts.append(item.location) }
        if let expiration = item.expirationDate {
            metaParts.append("Exp " + XTTDateFormat.short.string(from: expiration))
        }
        metaLabel.text = metaParts.joined(separator: " · ")

        quantityLabel.text = "×\(item.quantity)"
        statusPill.configure(status: item.effectiveStatus)
    }
}
