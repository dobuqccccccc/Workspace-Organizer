//
//  XTTKitDetailViewController.swift
//  WorkspaceOrganizer
//
//  Kit header (cover + info), status breakdown, and the item list.
//

import UIKit

final class XTTKitDetailViewController: UIViewController {

    private let kitID: String
    private var kit: XTTKit?

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerContainer = UIView()

    // Header pieces
    private let coverView = XTTGradientView(colors: XTTTheme.accentGradient)
    private let coverImageView = UIImageView()
    private let coverIcon = UIImageView()
    private let nameLabel = UILabel()
    private let categoryPill = XTTStatusPill()
    private let descriptionLabel = UILabel()
    private let statsRow = UIStackView()
    private let emptyItems = UILabel()

    private var items: [XTTItem] = []

    init(kitID: String) {
        self.kitID = kitID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        navigationItem.largeTitleDisplayMode = .never
        setupTable()
        setupNav()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupNav() {
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
                                         style: .plain, target: self, action: #selector(showMenu))
        navigationItem.rightBarButtonItem = menuButton
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tableView.register(XTTItemCell.self, forCellReuseIdentifier: XTTItemCell.reuseID)
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)

        // Floating add-item button
        let addButton = XTTPrimaryButton(title: "  Add Item")
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addItem), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.xl),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.xl),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -XTTTheme.Spacing.m),
            addButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func reload() {
        guard let kit = XTTDataStore.shared.kit(withID: kitID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        self.kit = kit
        self.items = kit.items
        title = kit.name
        rebuildHeader(kit: kit)
        tableView.reloadData()
    }

    // MARK: - Header

    private func rebuildHeader(kit: XTTKit) {
        headerContainer.subviews.forEach { $0.removeFromSuperview() }
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        // Cover
        coverView.setColors([kit.category.tint.cgColor,
                             kit.category.tint.withAlphaComponent(0.55).cgColor])
        coverView.layer.cornerRadius = XTTTheme.Radius.large
        coverView.layer.cornerCurve = .continuous
        coverView.clipsToBounds = true
        coverView.translatesAutoresizingMaskIntoConstraints = false

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.image = XTTImageStore.load(kit.coverFileName)
        coverImageView.isHidden = (coverImageView.image == nil)

        coverIcon.image = UIImage(systemName: kit.category.iconName)
        coverIcon.tintColor = UIColor.white.withAlphaComponent(0.9)
        coverIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        coverIcon.translatesAutoresizingMaskIntoConstraints = false
        coverIcon.isHidden = !coverImageView.isHidden

        coverView.addSubview(coverImageView)
        coverView.addSubview(coverIcon)
        coverImageView.xtt_pinEdges(to: coverView)
        NSLayoutConstraint.activate([
            coverIcon.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            coverIcon.centerYAnchor.constraint(equalTo: coverView.centerYAnchor)
        ])

        // Name + category
        nameLabel.text = kit.name
        nameLabel.font = XTTTheme.roundedFont(24, .bold)
        nameLabel.textColor = XTTTheme.textPrimary
        nameLabel.numberOfLines = 0

        categoryPill.configure(text: kit.category.rawValue, color: kit.category.tint)

        descriptionLabel.text = kit.detail.isEmpty ? "No description." : kit.detail
        descriptionLabel.font = XTTTheme.font(14)
        descriptionLabel.textColor = XTTTheme.textSecondary
        descriptionLabel.numberOfLines = 0

        // Stats row
        statsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsRow.spacing = 10
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.addArrangedSubview(makeMiniStat(value: "\(kit.totalItems)", label: "Items", color: XTTTheme.accent))
        statsRow.addArrangedSubview(makeMiniStat(value: "\(kit.readyCount)", label: "Ready", color: XTTTheme.statusReady))
        statsRow.addArrangedSubview(makeMiniStat(value: "\(kit.expiringSoonCount)", label: "Expiring", color: XTTTheme.orange))
        statsRow.addArrangedSubview(makeMiniStat(value: "\(kit.expiredCount)", label: "Expired", color: XTTTheme.statusExpired))

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, categoryPill, descriptionLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 10
        infoStack.alignment = .leading
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        categoryPill.setContentHuggingPriority(.required, for: .horizontal)

        headerContainer.addSubview(coverView)
        headerContainer.addSubview(infoStack)
        headerContainer.addSubview(statsRow)

        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: XTTTheme.Spacing.m),
            coverView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: XTTTheme.Spacing.m),
            coverView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -XTTTheme.Spacing.m),
            coverView.heightAnchor.constraint(equalToConstant: 130),

            infoStack.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: XTTTheme.Spacing.m),
            infoStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: XTTTheme.Spacing.m),
            infoStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -XTTTheme.Spacing.m),

            statsRow.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: XTTTheme.Spacing.m),
            statsRow.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: XTTTheme.Spacing.m),
            statsRow.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -XTTTheme.Spacing.m),
            statsRow.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -XTTTheme.Spacing.s),
            statsRow.heightAnchor.constraint(equalToConstant: 64)
        ])

        layoutHeader()
    }

    private func makeMiniStat(value: String, label: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = XTTTheme.backgroundElevated
        card.layer.cornerRadius = XTTTheme.Radius.small
        card.layer.cornerCurve = .continuous

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = XTTTheme.roundedFont(20, .bold)
        valueLabel.textColor = color
        valueLabel.textAlignment = .center

        let captionLabel = UILabel()
        captionLabel.text = label
        captionLabel.font = XTTTheme.font(11, .medium)
        captionLabel.textColor = XTTTheme.textSecondary
        captionLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.xtt_centerIn(card)
        return card
    }

    private func layoutHeader() {
        headerContainer.setNeedsLayout()
        headerContainer.layoutIfNeeded()
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerContainer.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        headerContainer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
        tableView.tableHeaderView = headerContainer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tableView.tableHeaderView != nil { layoutHeader() }
    }

    // MARK: - Actions

    @objc private func addItem() {
        let editor = XTTEditItemViewController(kitID: kitID, item: nil)
        let nav = UINavigationController(rootViewController: editor)
        XTTAppearance.applyNav(nav.navigationBar)
        present(nav, animated: true)
    }

    @objc private func showMenu() {
        let sheet = UIAlertController(title: kit?.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Edit Kit", style: .default) { [weak self] _ in
            guard let self = self, let kit = self.kit else { return }
            let editor = XTTEditKitViewController(kit: kit)
            let nav = UINavigationController(rootViewController: editor)
            XTTAppearance.applyNav(nav.navigationBar)
            self.present(nav, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Inspection History", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let history = XTTInspectionViewController(kitID: self.kitID)
            self.navigationController?.pushViewController(history, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Log Inspection", style: .default) { [weak self] _ in
            self?.presentLogInspection()
        })
        sheet.addAction(UIAlertAction(title: "Delete Kit", style: .destructive) { [weak self] _ in
            self?.confirmDeleteKit()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func presentLogInspection() {
        let inspections = XTTInspectionViewController(kitID: kitID)
        navigationController?.pushViewController(inspections, animated: true)
    }

    private func confirmDeleteKit() {
        guard let kit = kit else { return }
        let alert = UIAlertController(title: "Delete Kit?",
                                      message: "\"\(kit.name)\" and all items will be removed.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            XTTDataStore.shared.deleteKit(kit)
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - Table

extension XTTKitDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(items.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if items.isEmpty {
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.text = "No items yet. Tap Add Item to begin."
            cell.textLabel?.font = XTTTheme.font(14)
            cell.textLabel?.textColor = XTTTheme.textTertiary
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.numberOfLines = 0
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTItemCell.reuseID, for: indexPath) as! XTTItemCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        items.isEmpty ? 0.01 : 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !items.isEmpty else { return nil }
        let header = UIView()
        let label = UILabel()
        label.text = "ITEMS"
        label.font = XTTTheme.font(13, .bold)
        label.textColor = XTTTheme.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: XTTTheme.Spacing.m + 4),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -6)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !items.isEmpty else { return }
        let detail = XTTItemDetailViewController(kitID: kitID, item: items[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !items.isEmpty else { return nil }
        let item = items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            XTTDataStore.shared.deleteItem(item, fromKit: self.kitID)
            done(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
