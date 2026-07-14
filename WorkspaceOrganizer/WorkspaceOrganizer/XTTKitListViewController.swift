//
//  XTTKitListViewController.swift
//  WorkspaceOrganizer
//
//  Lists all emergency kits as rich cards.
//

import UIKit

final class XTTKitListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView()
    private var kits: [XTTKit] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Kits"
        setupNav()
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

    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addKit))
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(XTTKitCell.self, forCellReuseIdentifier: XTTKitCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        emptyState.configure(symbol: "shippingbox.fill",
                             title: "No Kits Yet",
                             message: "Tap + to create your first emergency kit and start adding supplies.")
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view)
    }

    @objc private func reload() {
        kits = XTTDataStore.shared.kits
        emptyState.isHidden = !kits.isEmpty
        tableView.isHidden = kits.isEmpty
        tableView.reloadData()
    }

    @objc private func addKit() {
        let editor = XTTEditKitViewController(kit: nil)
        let nav = UINavigationController(rootViewController: editor)
        XTTAppearance.applyNav(nav.navigationBar)
        present(nav, animated: true)
    }
}

// MARK: - Table Data

extension XTTKitListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        kits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTKitCell.reuseID, for: indexPath) as! XTTKitCell
        cell.configure(with: kits[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = XTTKitDetailViewController(kitID: kits[indexPath.row].id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let kit = kits[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.confirmDelete(kit: kit, done: done)
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(kit: XTTKit, done: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete Kit?",
            message: "\"\(kit.name)\" and all its items will be removed. This cannot be undone.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in done(false) })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteKit(kit)
            done(true)
        })
        present(alert, animated: true)
    }
}

// MARK: - Kit Cell

final class XTTKitCell: UITableViewCell {

    static let reuseID = "XTTKitCell"

    private let card = XTTCardView()
    private let coverBadge = XTTGradientView(colors: XTTTheme.accentGradient)
    private let coverIcon = UIImageView()
    private let coverImageView = UIImageView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let itemCountLabel = UILabel()
    private let segmentBar = XTTSegmentBar()
    private let chevron = UIImageView()

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
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: XTTTheme.Spacing.m),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -XTTTheme.Spacing.m)
        ])

        // Cover: badge with icon, overlaid by image if present.
        coverBadge.translatesAutoresizingMaskIntoConstraints = false
        coverBadge.layer.cornerRadius = XTTTheme.Radius.small
        coverBadge.layer.cornerCurve = .continuous
        coverBadge.clipsToBounds = true

        coverIcon.tintColor = .white
        coverIcon.contentMode = .scaleAspectFit
        coverIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        coverIcon.translatesAutoresizingMaskIntoConstraints = false
        coverBadge.addSubview(coverIcon)

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = XTTTheme.Radius.small
        coverImageView.layer.cornerCurve = .continuous
        coverImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = XTTTheme.font(17, .bold)
        nameLabel.textColor = XTTTheme.textPrimary

        categoryLabel.font = XTTTheme.font(12, .semibold)
        categoryLabel.textColor = XTTTheme.textTertiary

        itemCountLabel.font = XTTTheme.font(13)
        itemCountLabel.textColor = XTTTheme.textSecondary

        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = XTTTheme.textTertiary
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, categoryLabel, itemCountLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        segmentBar.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(coverBadge)
        card.addSubview(coverImageView)
        card.addSubview(textStack)
        card.addSubview(chevron)
        card.addSubview(segmentBar)

        NSLayoutConstraint.activate([
            coverBadge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.m),
            coverBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: XTTTheme.Spacing.m),
            coverBadge.widthAnchor.constraint(equalToConstant: 56),
            coverBadge.heightAnchor.constraint(equalToConstant: 56),

            coverIcon.centerXAnchor.constraint(equalTo: coverBadge.centerXAnchor),
            coverIcon.centerYAnchor.constraint(equalTo: coverBadge.centerYAnchor),

            coverImageView.leadingAnchor.constraint(equalTo: coverBadge.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: coverBadge.trailingAnchor),
            coverImageView.topAnchor.constraint(equalTo: coverBadge.topAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: coverBadge.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: coverBadge.trailingAnchor, constant: XTTTheme.Spacing.m),
            textStack.topAnchor.constraint(equalTo: coverBadge.topAnchor, constant: 2),
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -XTTTheme.Spacing.m),
            chevron.centerYAnchor.constraint(equalTo: coverBadge.centerYAnchor),

            segmentBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.m),
            segmentBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -XTTTheme.Spacing.m),
            segmentBar.topAnchor.constraint(equalTo: coverBadge.bottomAnchor, constant: XTTTheme.Spacing.m),
            segmentBar.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -XTTTheme.Spacing.m),
            segmentBar.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func configure(with kit: XTTKit) {
        nameLabel.text = kit.name
        categoryLabel.text = kit.category.rawValue.uppercased()
        itemCountLabel.text = "\(kit.totalItems) items · \(kit.readyCount) ready"

        coverIcon.image = UIImage(systemName: kit.category.iconName)
        coverBadge.setColors([kit.category.tint.cgColor,
                              kit.category.tint.withAlphaComponent(0.6).cgColor])

        if let image = XTTImageStore.load(kit.coverFileName) {
            coverImageView.image = image
            coverImageView.isHidden = false
        } else {
            coverImageView.image = nil
            coverImageView.isHidden = true
        }

        segmentBar.configure(segments: [
            (XTTTheme.statusReady, kit.count(for: .ready)),
            (XTTTheme.statusLow, kit.count(for: .lowStock)),
            (XTTTheme.statusReplace, kit.count(for: .needReplace)),
            (XTTTheme.statusExpired, kit.count(for: .expired))
        ])
    }
}
