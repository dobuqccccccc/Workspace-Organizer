//
//  XTTInspectionViewController.swift
//  WorkspaceOrganizer
//
//  Inspection history for a single kit + add-record flow.
//

import UIKit

final class XTTInspectionViewController: UIViewController {

    private let kitID: String
    private var records: [XTTInspection] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView()

    init(kitID: String) {
        self.kitID = kitID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Inspection Log"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addRecord))
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .xttDataChanged, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(XTTInspectionCell.self, forCellReuseIdentifier: XTTInspectionCell.reuseID)
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view.safeAreaLayoutGuide)
    }

    private func setupEmpty() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        emptyState.configure(symbol: "checklist",
                             title: "No Inspections",
                             message: "Record a check to keep a history of when this kit was last reviewed.")
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view)
    }

    @objc private func reload() {
        guard let kit = XTTDataStore.shared.kit(withID: kitID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        records = kit.inspections
        emptyState.isHidden = !records.isEmpty
        tableView.isHidden = records.isEmpty
        tableView.reloadData()
    }

    @objc private func addRecord() {
        guard let kit = XTTDataStore.shared.kit(withID: kitID) else { return }
        let alert = UIAlertController(title: "New Inspection",
                                      message: "Record the result of checking \"\(kit.name)\".",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Result (e.g. All items checked)"
        }
        alert.addTextField { tf in
            tf.placeholder = "Note (optional)"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let result = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let note = alert?.textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let record = XTTInspection(result: result.isEmpty ? "All items checked" : result,
                                       note: note,
                                       itemCount: kit.totalItems)
            XTTDataStore.shared.addInspection(record, toKit: self.kitID)
        })
        present(alert, animated: true)
    }
}

extension XTTInspectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTInspectionCell.reuseID, for: indexPath) as! XTTInspectionCell
        cell.configure(with: records[indexPath.row])
        return cell
    }
}

// MARK: - Inspection Cell

final class XTTInspectionCell: UITableViewCell {

    static let reuseID = "XTTInspectionCell"

    private let card = XTTCardView()
    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let resultLabel = UILabel()
    private let dateLabel = UILabel()
    private let noteLabel = UILabel()

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

        iconWrap.backgroundColor = XTTTheme.statusReady.withAlphaComponent(0.16)
        iconWrap.layer.cornerRadius = 12
        iconWrap.layer.cornerCurve = .continuous
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "checkmark.seal.fill")
        iconView.tintColor = XTTTheme.statusReady
        iconView.contentMode = .center
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        iconView.xtt_pinEdges(to: iconWrap)

        resultLabel.font = XTTTheme.font(16, .semibold)
        resultLabel.textColor = XTTTheme.textPrimary
        resultLabel.numberOfLines = 0

        dateLabel.font = XTTTheme.font(12, .medium)
        dateLabel.textColor = XTTTheme.accent

        noteLabel.font = XTTTheme.font(13)
        noteLabel.textColor = XTTTheme.textSecondary
        noteLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [dateLabel, resultLabel, noteLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconWrap)
        card.addSubview(textStack)
        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconWrap.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            iconWrap.widthAnchor.constraint(equalToConstant: 44),
            iconWrap.heightAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    func configure(with record: XTTInspection) {
        dateLabel.text = XTTDateFormat.long.string(from: record.date).uppercased()
        resultLabel.text = record.result
        noteLabel.text = record.note
        noteLabel.isHidden = record.note.isEmpty
    }
}
