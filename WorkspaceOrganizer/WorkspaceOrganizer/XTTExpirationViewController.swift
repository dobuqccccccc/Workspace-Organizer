//
//  XTTExpirationViewController.swift
//  WorkspaceOrganizer
//
//  Central view of expiring-soon and already-expired items across all kits.
//

import UIKit

final class XTTExpirationViewController: UIViewController {

    private enum Segment: Int {
        case expiringSoon = 0
        case expired = 1
    }

    private let segmented = UISegmentedControl(items: ["Expiring Soon", "Expired"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView()

    private var current: Segment = .expiringSoon
    private var rows: [(kitName: String, item: XTTItem, kitID: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Expiration"
        setupSegmented()
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentTintColor = XTTTheme.accent
        segmented.backgroundColor = XTTTheme.card
        segmented.setTitleTextAttributes([.foregroundColor: XTTTheme.textSecondary], for: .normal)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmented)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            segmented.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 24, right: 0)
        tableView.register(XTTExpiryCell.self, forCellReuseIdentifier: XTTExpiryCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        NSLayoutConstraint.activate([
            emptyState.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyState.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.xl),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.xl)
        ])
    }

    @objc private func segmentChanged() {
        current = Segment(rawValue: segmented.selectedSegmentIndex) ?? .expiringSoon
        reload()
    }

    @objc private func reload() {
        let source: [(kitName: String, item: XTTItem)]
        switch current {
        case .expiringSoon:
            source = XTTDataStore.shared.expiringSoonItems
            emptyState.configure(symbol: "checkmark.circle.fill",
                                 title: "Nothing Expiring Soon",
                                 message: "Items with an upcoming expiration date will appear here.")
        case .expired:
            source = XTTDataStore.shared.expiredItems
            emptyState.configure(symbol: "checkmark.circle.fill",
                                 title: "No Expired Items",
                                 message: "Great — none of your supplies have expired.")
        }

        // Map kit names back to IDs for navigation.
        rows = source.compactMap { entry in
            guard let kit = XTTDataStore.shared.kits.first(where: { $0.name == entry.kitName && $0.items.contains(where: { $0.id == entry.item.id }) }) else {
                return nil
            }
            return (entry.kitName, entry.item, kit.id)
        }

        emptyState.isHidden = !rows.isEmpty
        tableView.isHidden = rows.isEmpty
        tableView.reloadData()
    }
}

extension XTTExpirationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTExpiryCell.reuseID, for: indexPath) as! XTTExpiryCell
        let row = rows[indexPath.row]
        cell.configure(item: row.item, kitName: row.kitName)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rows[indexPath.row]
        let detail = XTTItemDetailViewController(kitID: row.kitID, item: row.item)
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Expiry Cell

final class XTTExpiryCell: UITableViewCell {

    static let reuseID = "XTTExpiryCell"

    private let card = XTTCardView()
    private let nameLabel = UILabel()
    private let kitLabel = UILabel()
    private let daysLabel = UILabel()
    private let daysCaption = UILabel()

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

        nameLabel.font = XTTTheme.font(16, .semibold)
        nameLabel.textColor = XTTTheme.textPrimary

        kitLabel.font = XTTTheme.font(13)
        kitLabel.textColor = XTTTheme.textSecondary

        daysLabel.font = XTTTheme.roundedFont(20, .bold)
        daysLabel.textAlignment = .center

        daysCaption.font = XTTTheme.font(10, .medium)
        daysCaption.textColor = XTTTheme.textTertiary
        daysCaption.textAlignment = .center

        let textStack = UIStackView(arrangedSubviews: [nameLabel, kitLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let daysStack = UIStackView(arrangedSubviews: [daysLabel, daysCaption])
        daysStack.axis = .vertical
        daysStack.spacing = 0
        daysStack.alignment = .center
        daysStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(textStack)
        card.addSubview(daysStack)
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: daysStack.leadingAnchor, constant: -10),

            daysStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            daysStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            daysStack.widthAnchor.constraint(equalToConstant: 62)
        ])
    }

    func configure(item: XTTItem, kitName: String) {
        nameLabel.text = item.name
        kitLabel.text = kitName
        guard let expiration = item.expirationDate else {
            daysLabel.text = "--"
            daysCaption.text = ""
            return
        }
        let days = XTTRelativeTime.daysUntil(expiration)
        if days < 0 {
            daysLabel.text = "\(-days)"
            daysCaption.text = days == -1 ? "DAY AGO" : "DAYS AGO"
            daysLabel.textColor = XTTTheme.statusExpired
        } else {
            daysLabel.text = "\(days)"
            daysCaption.text = days == 1 ? "DAY LEFT" : "DAYS LEFT"
            daysLabel.textColor = days <= 7 ? XTTTheme.statusReplace : XTTTheme.statusLow
        }
    }
}
