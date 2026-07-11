//
//  XTTDashboardViewController.swift
//  WorkspaceOrganizer
//
//  Home overview: totals, readiness ring, alerts, quick actions, activity.
//

import UIKit

final class XTTDashboardViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Hero
    private let readinessRing = XTTRingView()
    private let heroKitsLabel = UILabel()
    private let heroItemsLabel = UILabel()

    // Stat cards
    private let expiringCard = XTTMetricCard()
    private let lowStockCard = XTTMetricCard()
    private let expiredCard = XTTMetricCard()
    private let readyCard = XTTMetricCard()

    // Activity
    private let activityStack = UIStackView()
    private let activityEmpty = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Home"
        setupLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Layout

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = XTTTheme.Spacing.l
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: XTTTheme.Spacing.s),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -XTTTheme.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * XTTTheme.Spacing.m)
        ])

        contentStack.addArrangedSubview(makeHeroCard())
        contentStack.addArrangedSubview(makeMetricsGrid())
        contentStack.addArrangedSubview(makeQuickActionsCard())
        contentStack.addArrangedSubview(makeActivityCard())
    }

    // MARK: Hero

    private func makeHeroCard() -> UIView {
        let card = XTTCardView()

        readinessRing.translatesAutoresizingMaskIntoConstraints = false
        readinessRing.progressColor = XTTTheme.statusReady

        let titleLabel = UILabel()
        titleLabel.text = "Kit Readiness"
        titleLabel.font = XTTTheme.font(13, .bold)
        titleLabel.textColor = XTTTheme.textTertiary

        heroKitsLabel.font = XTTTheme.roundedFont(22, .bold)
        heroKitsLabel.textColor = XTTTheme.textPrimary
        heroItemsLabel.font = XTTTheme.font(14)
        heroItemsLabel.textColor = XTTTheme.textSecondary

        let kitsRow = makeHeroStat(symbol: "shippingbox.fill", tint: XTTTheme.accent, label: heroKitsLabel)
        let itemsRow = makeHeroStat(symbol: "cube.box.fill", tint: XTTTheme.orange, label: heroItemsLabel)

        let statsStack = UIStackView(arrangedSubviews: [titleLabel, kitsRow, itemsRow])
        statsStack.axis = .vertical
        statsStack.spacing = 10
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsStack.setCustomSpacing(16, after: titleLabel)

        card.addSubview(readinessRing)
        card.addSubview(statsStack)

        NSLayoutConstraint.activate([
            readinessRing.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.l),
            readinessRing.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            readinessRing.topAnchor.constraint(equalTo: card.topAnchor, constant: XTTTheme.Spacing.l),
            readinessRing.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -XTTTheme.Spacing.l),
            readinessRing.widthAnchor.constraint(equalToConstant: 110),
            readinessRing.heightAnchor.constraint(equalToConstant: 110),

            statsStack.leadingAnchor.constraint(equalTo: readinessRing.trailingAnchor, constant: XTTTheme.Spacing.l),
            statsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -XTTTheme.Spacing.l),
            statsStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func makeHeroStat(symbol: String, tint: UIColor, label: UILabel) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    // MARK: Metrics grid

    private func makeMetricsGrid() -> UIView {
        expiringCard.configure(symbol: "clock.badge.exclamationmark.fill", tint: XTTTheme.orange, title: "Expiring Soon")
        lowStockCard.configure(symbol: "exclamationmark.triangle.fill", tint: XTTTheme.statusLow, title: "Low Stock")
        expiredCard.configure(symbol: "xmark.octagon.fill", tint: XTTTheme.statusExpired, title: "Expired")
        readyCard.configure(symbol: "checkmark.circle.fill", tint: XTTTheme.statusReady, title: "Ready")

        let topRow = UIStackView(arrangedSubviews: [expiringCard, lowStockCard])
        let bottomRow = UIStackView(arrangedSubviews: [expiredCard, readyCard])
        [topRow, bottomRow].forEach {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = XTTTheme.Spacing.m
        }
        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = XTTTheme.Spacing.m
        return grid
    }

    // MARK: Quick actions

    private func makeQuickActionsCard() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = XTTTheme.Spacing.s

        let header = XTTSectionHeader("Quick Actions")
        container.addArrangedSubview(header)

        let addKit = XTTQuickActionButton(symbol: "plus.square.on.square.fill", title: "Add Kit", tint: XTTTheme.accent)
        addKit.addTarget(self, action: #selector(quickAddKit), for: .touchUpInside)
        let addItem = XTTQuickActionButton(symbol: "plus.circle.fill", title: "Add Item", tint: XTTTheme.statusReady)
        addItem.addTarget(self, action: #selector(quickAddItem), for: .touchUpInside)
        let check = XTTQuickActionButton(symbol: "checklist", title: "Check Kit", tint: XTTTheme.orange)
        check.addTarget(self, action: #selector(quickCheckKit), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [addKit, addItem, check])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = XTTTheme.Spacing.s
        container.addArrangedSubview(row)
        return container
    }

    // MARK: Activity

    private func makeActivityCard() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = XTTTheme.Spacing.s

        container.addArrangedSubview(XTTSectionHeader("Recent Activity"))

        let card = XTTCardView()
        activityStack.axis = .vertical
        activityStack.spacing = 0
        activityStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(activityStack)
        activityStack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0))

        activityEmpty.text = "No activity yet. Create a kit to get started."
        activityEmpty.font = XTTTheme.font(14)
        activityEmpty.textColor = XTTTheme.textTertiary
        activityEmpty.numberOfLines = 0
        activityEmpty.translatesAutoresizingMaskIntoConstraints = false

        container.addArrangedSubview(card)
        return container
    }

    // MARK: - Refresh

    @objc private func refresh() {
        let store = XTTDataStore.shared
        let ready = store.totalCount(for: .ready)
        let totalItems = store.totalItems
        let ratio = totalItems > 0 ? CGFloat(ready) / CGFloat(totalItems) : 0
        readinessRing.configure(progress: ratio,
                                centerText: "\(Int(ratio * 100))%",
                                caption: "Ready")

        heroKitsLabel.text = "\(store.totalKits) Kits"
        heroItemsLabel.text = "\(totalItems) Items tracked"

        expiringCard.setValue("\(store.expiringSoonItems.count)")
        lowStockCard.setValue("\(store.totalCount(for: .lowStock) + store.totalCount(for: .needReplace))")
        expiredCard.setValue("\(store.totalCount(for: .expired))")
        readyCard.setValue("\(ready)")

        rebuildActivity()
    }

    private func rebuildActivity() {
        activityStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let activities = XTTDataStore.shared.recentActivities()
        if activities.isEmpty {
            let wrapper = UIView()
            wrapper.addSubview(activityEmpty)
            activityEmpty.xtt_pinEdges(to: wrapper, insets: UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16))
            activityStack.addArrangedSubview(wrapper)
            return
        }
        for (index, activity) in activities.enumerated() {
            activityStack.addArrangedSubview(makeActivityRow(activity))
            if index < activities.count - 1 {
                activityStack.addArrangedSubview(makeSeparator())
            }
        }
    }

    private func makeActivityRow(_ activity: XTTActivity) -> UIView {
        let destination = destination(for: activity)
        let row = XTTActivityRow()

        let badge = XTTIconBadge(size: 38)
        badge.configure(symbol: activity.kind.iconName, tint: activity.kind.tint)
        badge.isUserInteractionEnabled = false
        badge.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = activity.title
        titleLabel.font = XTTTheme.font(15, .medium)
        titleLabel.textColor = XTTTheme.textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = activity.subtitle.isEmpty ? relativeDate(activity.date) : "\(activity.subtitle) · \(relativeDate(activity.date))"
        subtitleLabel.font = XTTTheme.font(12)
        subtitleLabel.textColor = XTTTheme.textTertiary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(badge)
        row.addSubview(textStack)

        var constraints: [NSLayoutConstraint] = [
            badge.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            badge.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            badge.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            badge.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),

            textStack.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ]

        // Only rows that resolve to a destination get a chevron + tap handling.
        if destination != nil {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = XTTTheme.textTertiary
            chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            chevron.isUserInteractionEnabled = false
            chevron.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(chevron)
            constraints += [
                chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
                chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8)
            ]
            row.onTap = { [weak self] in self?.handle(destination) }
        } else {
            row.isUserInteractionEnabled = false
            constraints.append(textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14))
        }

        NSLayoutConstraint.activate(constraints)
        return row
    }

    // MARK: - Activity Navigation

    /// Where a tapped activity row should go, if anywhere.
    private enum XTTActivityDestination {
        case kit(id: String)
        case scheduleTab
    }

    /// Resolve an activity to a navigation destination.
    /// Kit-related activities carry the kit name in either title (addedKit/inspected)
    /// or subtitle (addedItem/updatedItem); we look the kit up by name.
    private func destination(for activity: XTTActivity) -> XTTActivityDestination? {
        switch activity.kind {
        case .addedKit, .inspected:
            return kitDestination(named: activity.title)
        case .addedItem, .updatedItem:
            return kitDestination(named: activity.subtitle)
        case .scheduled:
            return .scheduleTab
        }
    }

    private func kitDestination(named name: String) -> XTTActivityDestination? {
        guard let kit = XTTDataStore.shared.kits.first(where: { $0.name == name }) else { return nil }
        return .kit(id: kit.id)
    }

    private func handle(_ destination: XTTActivityDestination?) {
        guard let destination = destination else { return }
        switch destination {
        case .kit(let id):
            let detail = XTTKitDetailViewController(kitID: id)
            navigationController?.pushViewController(detail, animated: true)
        case .scheduleTab:
            // Schedule tab was inserted at index 1.
            tabBarController?.selectedIndex = 1
        }
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = XTTTheme.separator.withAlphaComponent(0.4)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let wrapper = UIView()
        wrapper.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 64),
            sep.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            sep.topAnchor.constraint(equalTo: wrapper.topAnchor),
            sep.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        return wrapper
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Quick Action Handlers

    @objc private func quickAddKit() {
        let editor = XTTEditKitViewController(kit: nil)
        presentInNav(editor)
    }

    @objc private func quickAddItem() {
        let store = XTTDataStore.shared
        guard !store.kits.isEmpty else {
            xtt_alert(title: "No Kits Yet", message: "Create a kit first, then add items to it.")
            return
        }
        // Add to the most recent kit for a fast path.
        if let kit = store.kits.first {
            let editor = XTTEditItemViewController(kitID: kit.id, item: nil)
            presentInNav(editor)
        }
    }

    @objc private func quickCheckKit() {
        // Kits tab moved to index 2 after Schedule was inserted at index 1.
        tabBarController?.selectedIndex = 2
    }

    private func presentInNav(_ vc: UIViewController) {
        let nav = UINavigationController(rootViewController: vc)
        XTTAppearance.applyNav(nav.navigationBar)
        present(nav, animated: true)
    }
}

// MARK: - Metric Card

/// A compact stat tile: icon badge, big number, caption.
final class XTTMetricCard: XTTCardView {

    private let badge = XTTIconBadge(size: 38)
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init() {
        super.init()
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        valueLabel.font = XTTTheme.roundedFont(30, .bold)
        valueLabel.textColor = XTTTheme.textPrimary
        titleLabel.font = XTTTheme.font(13, .medium)
        titleLabel.textColor = XTTTheme.textSecondary

        let stack = UIStackView(arrangedSubviews: [badge, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.setCustomSpacing(10, after: badge)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.xtt_pinEdges(to: self, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    func configure(symbol: String, tint: UIColor, title: String) {
        badge.configure(symbol: symbol, tint: tint)
        titleLabel.text = title
        valueLabel.textColor = tint
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - Activity Row

/// A tappable row in the Recent Activity list. Highlights on press and
/// invokes `onTap` when released inside.
final class XTTActivityRow: UIControl {

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        onTap?()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? XTTTheme.cardHighlight.withAlphaComponent(0.6)
                : .clear
        }
    }
}

// MARK: - Quick Action Button

final class XTTQuickActionButton: UIControl {

    private let badge = XTTIconBadge(size: 46)
    private let titleLabel = UILabel()

    init(symbol: String, title: String, tint: UIColor) {
        super.init(frame: .zero)
        backgroundColor = XTTTheme.card
        layer.cornerRadius = XTTTheme.Radius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.separator.withAlphaComponent(0.5).cgColor

        badge.configure(symbol: symbol, tint: tint)
        badge.isUserInteractionEnabled = false
        titleLabel.text = title
        titleLabel.font = XTTTheme.font(13, .semibold)
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [badge, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? XTTTheme.cardHighlight : XTTTheme.card }
    }
}
