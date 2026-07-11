//
//  XTTStatisticsViewController.swift
//  WorkspaceOrganizer
//
//  Aggregate statistics: totals, status breakdown, category distribution.
//

import UIKit

final class XTTStatisticsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let emptyState = XTTEmptyStateView()

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Stats"
        setupScroll()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupScroll() {
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
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        emptyState.configure(symbol: "chart.bar.fill",
                             title: "No Data Yet",
                             message: "Create kits and add items to see your statistics here.")
        view.addSubview(emptyState)
        NSLayoutConstraint.activate([
            emptyState.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyState.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.xl),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.xl)
        ])
    }

    @objc private func reload() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let store = XTTDataStore.shared
        let hasData = store.totalItems > 0 || store.totalKits > 0
        emptyState.isHidden = hasData
        scrollView.isHidden = !hasData
        guard hasData else { return }

        contentStack.addArrangedSubview(makeTotalsCard())
        contentStack.addArrangedSubview(makeStatusCard())
        contentStack.addArrangedSubview(makeCategoryCard())
        contentStack.addArrangedSubview(makeKitBreakdownCard())
    }

    // MARK: - Cards

    private func makeTotalsCard() -> UIView {
        let store = XTTDataStore.shared
        let card = XTTCardView()

        let title = XTTSectionHeader.styled("Overview")

        let kits = makeTotalTile(value: "\(store.totalKits)", label: "Kits", tint: XTTTheme.accent)
        let items = makeTotalTile(value: "\(store.totalItems)", label: "Items", tint: XTTTheme.orange)
        let expiring = makeTotalTile(value: "\(store.expiringSoonItems.count)", label: "Expiring", tint: XTTTheme.statusLow)
        let expired = makeTotalTile(value: "\(store.expiredItems.count)", label: "Expired", tint: XTTTheme.statusExpired)

        let topRow = UIStackView(arrangedSubviews: [kits, items])
        topRow.distribution = .fillEqually
        topRow.spacing = 12
        let bottomRow = UIStackView(arrangedSubviews: [expiring, expired])
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 12

        let stack = UIStackView(arrangedSubviews: [title, topRow, bottomRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeTotalTile(value: String, label: String, tint: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = tint.withAlphaComponent(0.12)
        container.layer.cornerRadius = XTTTheme.Radius.small
        container.layer.cornerCurve = .continuous

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = XTTTheme.roundedFont(28, .bold)
        valueLabel.textColor = tint

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = XTTTheme.font(13, .medium)
        nameLabel.textColor = XTTTheme.textSecondary

        let stack = UIStackView(arrangedSubviews: [valueLabel, nameLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        stack.xtt_pinEdges(to: container, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        return container
    }

    private func makeStatusCard() -> UIView {
        let store = XTTDataStore.shared
        let card = XTTCardView()
        let title = XTTSectionHeader.styled("Status Breakdown")

        let data: [XTTBarDatum] = XTTItemStatus.allCases.map {
            XTTBarDatum(label: $0.rawValue, value: store.totalCount(for: $0), color: $0.color)
        }
        let chart = XTTBarChartView()
        chart.configure(data: data)
        chart.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, chart])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeCategoryCard() -> UIView {
        let store = XTTDataStore.shared
        let card = XTTCardView()
        let title = XTTSectionHeader.styled("Items by Category")

        let data: [XTTBarDatum] = store.itemCountByCategory().map {
            XTTBarDatum(label: $0.category.rawValue, value: $0.count, color: XTTTheme.accent)
        }
        let chart = XTTBarChartView()
        chart.configure(data: data)
        chart.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, chart])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeKitBreakdownCard() -> UIView {
        let card = XTTCardView()
        let title = XTTSectionHeader.styled("Readiness by Kit")

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(title)

        for kit in XTTDataStore.shared.kits {
            stack.addArrangedSubview(makeKitRow(kit: kit))
        }

        card.addSubview(stack)
        stack.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeKitRow(kit: XTTKit) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = kit.name
        nameLabel.font = XTTTheme.font(14, .semibold)
        nameLabel.textColor = XTTTheme.textPrimary

        let percentLabel = UILabel()
        percentLabel.text = "\(Int(kit.readiness * 100))%"
        percentLabel.font = XTTTheme.roundedFont(14, .bold)
        percentLabel.textColor = XTTTheme.statusReady
        percentLabel.textAlignment = .right

        let headerRow = UIStackView(arrangedSubviews: [nameLabel, percentLabel])
        headerRow.axis = .horizontal

        let track = UIView()
        track.backgroundColor = XTTTheme.separator.withAlphaComponent(0.4)
        track.layer.cornerRadius = 5
        track.translatesAutoresizingMaskIntoConstraints = false
        track.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let fill = UIView()
        fill.backgroundColor = XTTTheme.statusReady
        fill.layer.cornerRadius = 5
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: max(0.02, CGFloat(kit.readiness)))
        ])

        let stack = UIStackView(arrangedSubviews: [headerRow, track])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }
}
