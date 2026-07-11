//
//  XTTScheduleViewController.swift
//  WorkspaceOrganizer
//
//  Work schedule: entries grouped by day, with a category filter, completion
//  toggle, swipe-to-delete and tap-to-edit.
//

import UIKit

final class XTTScheduleViewController: UIViewController {

    private let filterBar = XTTScheduleFilterBar()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let emptyState = XTTEmptyStateView()

    /// nil = show all categories.
    private var activeFilter: XTTScheduleCategory?
    private var sections: [(day: Date, entries: [XTTScheduleEntry])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Schedule"
        setupNav()
        setupFilterBar()
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

    // MARK: - Setup

    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addEntry))
    }

    private func setupFilterBar() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.onSelect = { [weak self] category in
            self?.activeFilter = category
            self?.reload()
        }
        view.addSubview(filterBar)
        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(XTTScheduleCell.self, forCellReuseIdentifier: XTTScheduleCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        emptyState.configure(symbol: "calendar.badge.plus",
                             title: "No Schedule Yet",
                             message: "Tap + to plan your first meeting, task or deadline.")
        view.addSubview(emptyState)
        NSLayoutConstraint.activate([
            emptyState.topAnchor.constraint(equalTo: filterBar.bottomAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyState.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data

    @objc private func reload() {
        var grouped = XTTDataStore.shared.schedulesByDay()
        if let filter = activeFilter {
            grouped = grouped
                .map { (day: $0.day, entries: $0.entries.filter { $0.category == filter }) }
                .filter { !$0.entries.isEmpty }
        }
        sections = grouped

        let isEmpty = sections.isEmpty
        emptyState.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        tableView.reloadData()
    }

    @objc private func addEntry() {
        presentEditor(for: nil)
    }

    private func presentEditor(for entry: XTTScheduleEntry?) {
        let editor = XTTEditScheduleViewController(entry: entry)
        let nav = UINavigationController(rootViewController: editor)
        XTTAppearance.applyNav(nav.navigationBar)
        present(nav, animated: true)
    }
}

// MARK: - Table Data

extension XTTScheduleViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTScheduleCell.reuseID, for: indexPath) as! XTTScheduleCell
        let entry = sections[indexPath.section].entries[indexPath.row]
        cell.configure(with: entry)
        cell.onToggle = { XTTDataStore.shared.toggleScheduleCompletion(entry) }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let day = sections[section].day
        let container = UIView()

        let label = UILabel()
        label.text = XTTScheduleFormat.dayLabel(for: day)
        label.font = XTTTheme.font(13, .bold)
        label.textColor = XTTTheme.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false

        let countLabel = UILabel()
        let count = sections[section].entries.count
        countLabel.text = "\(count)"
        countLabel.font = XTTTheme.roundedFont(13, .bold)
        countLabel.textColor = XTTTheme.textTertiary
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        container.addSubview(countLabel)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: XTTTheme.Spacing.m + 4),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -XTTTheme.Spacing.m - 4),
            countLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        32
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentEditor(for: sections[indexPath.section].entries[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = sections[indexPath.section].entries[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            XTTDataStore.shared.deleteSchedule(entry)
            done(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Filter Bar

/// A horizontally scrolling chip bar: "All" plus one chip per category.
final class XTTScheduleFilterBar: UIView {

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [UIButton] = []

    /// nil == "All".
    private let options: [XTTScheduleCategory?] = [nil] + XTTScheduleCategory.allCases.map { $0 }
    private var selectedIndex = 0

    var onSelect: ((XTTScheduleCategory?) -> Void)?

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
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: XTTTheme.Spacing.m),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -XTTTheme.Spacing.m),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])

        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option?.rawValue ?? "All", for: .normal)
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

    @objc private func tapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateStyles()
        onSelect?(options[sender.tag])
    }

    private func updateStyles() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            let color = options[index]?.tint ?? XTTTheme.accent
            if isSelected {
                button.backgroundColor = color.withAlphaComponent(0.22)
                button.setTitleColor(color, for: .normal)
                button.layer.borderColor = color.cgColor
            } else {
                button.backgroundColor = XTTTheme.card
                button.setTitleColor(XTTTheme.textSecondary, for: .normal)
                button.layer.borderColor = XTTTheme.separator.cgColor
            }
        }
    }
}

// MARK: - Schedule Cell

final class XTTScheduleCell: UITableViewCell {

    static let reuseID = "XTTScheduleCell"

    private let card = XTTCardView()
    private let checkButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    private let titleLabel = UILabel()
    private let categoryBadge = XTTIconBadge(size: 34)
    private let priorityDot = UIView()
    private let metaLabel = UILabel()

    /// Fired when the completion circle is tapped.
    var onToggle: (() -> Void)?

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

        checkButton.tintColor = XTTTheme.statusReady
        checkButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .regular), forImageIn: .normal)
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        categoryBadge.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = XTTTheme.roundedFont(13, .bold)
        timeLabel.textColor = XTTTheme.textSecondary

        titleLabel.font = XTTTheme.font(16, .semibold)
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.numberOfLines = 1

        metaLabel.font = XTTTheme.font(12)
        metaLabel.textColor = XTTTheme.textTertiary

        priorityDot.translatesAutoresizingMaskIntoConstraints = false
        priorityDot.layer.cornerRadius = 4

        let topRow = UIStackView(arrangedSubviews: [timeLabel, priorityDot])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [topRow, titleLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(checkButton)
        card.addSubview(categoryBadge)
        card.addSubview(textStack)

        NSLayoutConstraint.activate([
            checkButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: XTTTheme.Spacing.m),
            checkButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            checkButton.widthAnchor.constraint(equalToConstant: 30),
            checkButton.heightAnchor.constraint(equalToConstant: 30),

            categoryBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -XTTTheme.Spacing.m),
            categoryBadge.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            priorityDot.widthAnchor.constraint(equalToConstant: 8),
            priorityDot.heightAnchor.constraint(equalToConstant: 8),

            textStack.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: XTTTheme.Spacing.s + 2),
            textStack.trailingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: -XTTTheme.Spacing.s),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: XTTTheme.Spacing.m),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -XTTTheme.Spacing.m)
        ])
    }

    @objc private func toggleTapped() {
        onToggle?()
    }

    func configure(with entry: XTTScheduleEntry) {
        timeLabel.text = entry.timeText
        titleLabel.text = entry.title
        categoryBadge.configure(symbol: entry.category.iconName, tint: entry.category.tint)
        priorityDot.backgroundColor = entry.priority.color

        // Meta line: category + priority (+ overdue hint when applicable).
        var meta = "\(entry.category.rawValue) · \(entry.priority.rawValue)"
        if entry.isOverdue() { meta += " · Overdue" }
        metaLabel.text = meta
        metaLabel.textColor = entry.isOverdue() ? XTTTheme.statusExpired : XTTTheme.textTertiary

        // Completion state styling.
        let symbol = entry.isCompleted ? "checkmark.circle.fill" : "circle"
        checkButton.setImage(UIImage(systemName: symbol), for: .normal)
        checkButton.tintColor = entry.isCompleted ? XTTTheme.statusReady : XTTTheme.textTertiary

        if entry.isCompleted {
            let attributed = NSAttributedString(
                string: entry.title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: XTTTheme.textTertiary
                ])
            titleLabel.attributedText = attributed
            card.alpha = 0.6
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = entry.title
            card.alpha = 1.0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        card.alpha = 1.0
        onToggle = nil
    }
}
