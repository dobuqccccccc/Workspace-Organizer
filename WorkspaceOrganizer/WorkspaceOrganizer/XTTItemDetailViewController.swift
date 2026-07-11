//
//  XTTItemDetailViewController.swift
//  WorkspaceOrganizer
//
//  Read-only detail for a single item, with edit / delete actions.
//

import UIKit

final class XTTItemDetailViewController: UIViewController {

    private let kitID: String
    private var itemID: String
    private var item: XTTItem?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(kitID: String, item: XTTItem) {
        self.kitID = kitID
        self.itemID = item.id
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"), style: .plain,
            target: self, action: #selector(showMenu))
        setupScroll()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = XTTTheme.Spacing.m
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: XTTTheme.Spacing.m),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -XTTTheme.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * XTTTheme.Spacing.m)
        ])
    }

    @objc private func reload() {
        guard let kit = XTTDataStore.shared.kit(withID: kitID),
              let fresh = kit.items.first(where: { $0.id == itemID }) else {
            navigationController?.popViewController(animated: true)
            return
        }
        item = fresh
        title = fresh.name
        rebuild(item: fresh)
    }

    private func rebuild(item: XTTItem) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        contentStack.addArrangedSubview(makeHeaderCard(item: item))
        if item.isExpired() || item.isExpiringSoon(within: XTTSettings.shared.expiryWindowDays) {
            contentStack.addArrangedSubview(makeExpiryBanner(item: item))
        }
        contentStack.addArrangedSubview(makeDetailCard(item: item))
        if !item.notes.isEmpty {
            contentStack.addArrangedSubview(makeNotesCard(item: item))
        }
    }

    // MARK: - Cards

    private func makeHeaderCard(item: XTTItem) -> UIView {
        let card = XTTCardView()

        let visual = UIView()
        visual.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = XTTTheme.roundedFont(24, .bold)
        nameLabel.textColor = XTTTheme.textPrimary
        nameLabel.numberOfLines = 0

        let categoryLabel = UILabel()
        categoryLabel.text = item.category.rawValue
        categoryLabel.font = XTTTheme.font(14, .medium)
        categoryLabel.textColor = XTTTheme.textSecondary

        let pill = XTTStatusPill()
        pill.configure(status: item.effectiveStatus)
        pill.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, categoryLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let imageWrap = UIView()
        imageWrap.translatesAutoresizingMaskIntoConstraints = false
        imageWrap.layer.cornerRadius = 16
        imageWrap.layer.cornerCurve = .continuous
        imageWrap.clipsToBounds = true
        imageWrap.widthAnchor.constraint(equalToConstant: 72).isActive = true
        imageWrap.heightAnchor.constraint(equalToConstant: 72).isActive = true

        if let photo = XTTImageStore.load(item.photoFileName) {
            let iv = UIImageView(image: photo)
            iv.contentMode = .scaleAspectFill
            iv.translatesAutoresizingMaskIntoConstraints = false
            imageWrap.addSubview(iv)
            iv.xtt_pinEdges(to: imageWrap)
        } else {
            imageWrap.backgroundColor = item.effectiveStatus.color.withAlphaComponent(0.16)
            let icon = UIImageView(image: UIImage(systemName: item.category.iconName))
            icon.tintColor = item.effectiveStatus.color
            icon.contentMode = .center
            icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
            icon.translatesAutoresizingMaskIntoConstraints = false
            imageWrap.addSubview(icon)
            icon.xtt_pinEdges(to: imageWrap)
        }

        let topRow = UIStackView(arrangedSubviews: [imageWrap, textStack])
        topRow.axis = .horizontal
        topRow.spacing = 14
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(topRow)
        card.addSubview(pill)
        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: card.topAnchor, constant: XTTTheme.Spacing.m),
            topRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.m),
            topRow.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -XTTTheme.Spacing.m),

            pill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.m),
            pill.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 14),
            pill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -XTTTheme.Spacing.m)
        ])
        return card
    }

    private func makeExpiryBanner(item: XTTItem) -> UIView {
        let isExpired = item.isExpired()
        let color = isExpired ? XTTTheme.statusExpired : XTTTheme.orange
        let banner = UIView()
        banner.backgroundColor = color.withAlphaComponent(0.14)
        banner.layer.cornerRadius = XTTTheme.Radius.small
        banner.layer.cornerCurve = .continuous

        let icon = UIImageView(image: UIImage(systemName: isExpired ? "xmark.octagon.fill" : "clock.badge.exclamationmark.fill"))
        icon.tintColor = color
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.font = XTTTheme.font(14, .semibold)
        label.textColor = color
        label.numberOfLines = 0
        if let expiration = item.expirationDate {
            let days = XTTRelativeTime.daysUntil(expiration)
            if isExpired {
                label.text = "Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago"
            } else {
                label.text = "Expires in \(days) day\(days == 1 ? "" : "s")"
            }
        }
        label.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(icon)
        banner.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -12)
        ])
        return banner
    }

    private func makeDetailCard(item: XTTItem) -> UIView {
        let card = XTTCardView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))

        stack.addArrangedSubview(makeRow(title: "Quantity", value: "\(item.quantity)"))
        stack.addArrangedSubview(makeDivider())
        stack.addArrangedSubview(makeRow(title: "Location", value: item.location.isEmpty ? "—" : item.location))
        stack.addArrangedSubview(makeDivider())
        stack.addArrangedSubview(makeRow(title: "Status", value: item.effectiveStatus.rawValue))
        if let expiration = item.expirationDate {
            stack.addArrangedSubview(makeDivider())
            stack.addArrangedSubview(makeRow(title: "Expiration", value: XTTDateFormat.short.string(from: expiration)))
        }
        return card
    }

    private func makeNotesCard(item: XTTItem) -> UIView {
        let card = XTTCardView()
        let title = UILabel()
        title.text = "Notes"
        title.font = XTTTheme.font(13, .bold)
        title.textColor = XTTTheme.textTertiary
        let body = UILabel()
        body.text = item.notes
        body.font = XTTTheme.font(15)
        body.textColor = XTTTheme.textPrimary
        body.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    // MARK: - Row helpers

    private func makeRow(title: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = XTTTheme.font(15)
        titleLabel.textColor = XTTTheme.textSecondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = XTTTheme.font(15, .semibold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
        return container
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = XTTTheme.separator.withAlphaComponent(0.5)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    // MARK: - Actions

    @objc private func showMenu() {
        let sheet = UIAlertController(title: item?.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.editItem()
        })
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteItem()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }

    private func editItem() {
        guard let item = item else { return }
        let editor = XTTEditItemViewController(kitID: kitID, item: item)
        let nav = UINavigationController(rootViewController: editor)
        XTTAppearance.applyNav(nav.navigationBar)
        present(nav, animated: true)
    }

    private func deleteItem() {
        guard let item = item else { return }
        let alert = UIAlertController(title: "Delete Item?",
                                      message: "\"\(item.name)\" will be removed.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            XTTDataStore.shared.deleteItem(item, fromKit: self.kitID)
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
