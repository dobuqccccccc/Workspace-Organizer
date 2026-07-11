//
//  XTTItemListViewController.swift
//  WorkspaceOrganizer
//
//  Searchable / filterable / sortable list of a kit's items.
//

import UIKit

final class XTTItemListViewController: UIViewController {

    enum Sort: String, CaseIterable {
        case nameAsc = "Name A–Z"
        case quantity = "Quantity"
        case expiry = "Expiration"
        case status = "Status"
    }

    private let kitID: String
    private var allItems: [XTTItem] = []
    private var displayed: [XTTItem] = []

    private var searchText: String = ""
    private var statusFilter: XTTItemStatus?
    private var sort: Sort = .nameAsc

    private let searchController = UISearchController(searchResultsController: nil)
    private let filterBar = XTTChipSelector() // 0 = All, then status raw indices
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView()

    private let statusOptions: [XTTItemStatus] = XTTItemStatus.allCases

    init(kitID: String) {
        self.kitID = kitID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Items"
        navigationItem.largeTitleDisplayMode = .never
        setupSearch()
        setupNav()
        setupFilterBar()
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search items"
        searchController.searchBar.tintColor = XTTTheme.accent
        searchController.searchBar.searchTextField.textColor = XTTTheme.textPrimary
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupNav() {
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"),
                                         style: .plain, target: self, action: #selector(showSort))
        navigationItem.rightBarButtonItem = sortButton
    }

    private func setupFilterBar() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterBar)
        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            filterBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            filterBar.heightAnchor.constraint(equalToConstant: 40)
        ])

        var options: [(value: Int, title: String, color: UIColor)] = [(-1, "All", XTTTheme.accent)]
        for (index, status) in statusOptions.enumerated() {
            options.append((index, status.rawValue, status.color))
        }
        filterBar.configure(options: options, selected: -1)
        filterBar.onSelect = { [weak self] value in
            guard let self = self else { return }
            let index = (value.base as? Int) ?? -1
            self.statusFilter = (index == -1) ? nil : self.statusOptions[index]
            self.applyFilters()
        }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(XTTItemCell.self, forCellReuseIdentifier: XTTItemCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        emptyState.configure(symbol: "magnifyingglass",
                             title: "No Items Found",
                             message: "Try adjusting your search or filters.")
        view.addSubview(emptyState)
        NSLayoutConstraint.activate([
            emptyState.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyState.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.xl),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.xl)
        ])
    }

    @objc private func reload() {
        guard let kit = XTTDataStore.shared.kit(withID: kitID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        allItems = kit.items
        applyFilters()
    }

    private func applyFilters() {
        var result = allItems

        if let statusFilter = statusFilter {
            result = result.filter { $0.effectiveStatus == statusFilter }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.location.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        switch sort {
        case .nameAsc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .quantity:
            result.sort { $0.quantity > $1.quantity }
        case .expiry:
            result.sort { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
        case .status:
            result.sort { $0.effectiveStatus.rawValue < $1.effectiveStatus.rawValue }
        }

        displayed = result
        emptyState.isHidden = !displayed.isEmpty
        tableView.reloadData()
    }

    @objc private func showSort() {
        let sheet = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        for option in Sort.allCases {
            let action = UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                self?.sort = option
                self?.applyFilters()
            }
            if option == sort { action.setValue(true, forKey: "checked") }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }
}

// MARK: - Search

extension XTTItemListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        applyFilters()
    }
}

// MARK: - Table

extension XTTItemListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayed.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTItemCell.reuseID, for: indexPath) as! XTTItemCell
        cell.configure(with: displayed[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = XTTItemDetailViewController(kitID: kitID, item: displayed[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = displayed[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            XTTDataStore.shared.deleteItem(item, fromKit: self.kitID)
            done(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
