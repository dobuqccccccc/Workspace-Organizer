//
//  XTTEditScheduleViewController.swift
//  WorkspaceOrganizer
//
//  Add or edit a work schedule entry (title, date/time, category,
//  priority, completion, notes).
//

import UIKit

final class XTTEditScheduleViewController: UIViewController {

    private let existingEntry: XTTScheduleEntry?
    private var isEditingEntry: Bool { existingEntry != nil }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleRow = XTTFieldRow(label: "Title", placeholder: "e.g. Team Standup")
    private let dateRow = XTTDateTimeRow(label: "Date & Time")
    private let categorySelector = XTTChipSelector()
    private let prioritySelector = XTTChipSelector()
    private let notesRow = XTTNotesRow(label: "Notes", placeholder: "Optional notes about this entry")

    private let completeToggle = UISwitch()

    init(entry: XTTScheduleEntry?) {
        self.existingEntry = entry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = isEditingEntry ? "Edit Entry" : "New Entry"
        setupNavButtons()
        setupLayout()
        populate()
    }

    private func setupNavButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(saveTapped))
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = XTTTheme.Spacing.l
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: XTTTheme.Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.m),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -XTTTheme.Spacing.xl),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * XTTTheme.Spacing.m)
        ])

        contentStack.addArrangedSubview(titleRow)
        contentStack.addArrangedSubview(dateRow)
        contentStack.addArrangedSubview(makeSelectorSection(caption: "Category", selector: categorySelector))
        contentStack.addArrangedSubview(makeSelectorSection(caption: "Priority", selector: prioritySelector))
        contentStack.addArrangedSubview(makeCompletionRow())
        contentStack.addArrangedSubview(notesRow)

        categorySelector.configure(
            options: XTTScheduleCategory.allCases.map { ($0, $0.rawValue, $0.tint) },
            selected: existingEntry?.category ?? .task)
        prioritySelector.configure(
            options: XTTSchedulePriority.allCases.map { ($0, $0.rawValue, $0.color) },
            selected: existingEntry?.priority ?? .normal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeSelectorSection(caption text: String, selector: UIView) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        let caption = UILabel()
        caption.text = text
        caption.font = XTTTheme.font(13, .semibold)
        caption.textColor = XTTTheme.textSecondary
        container.addArrangedSubview(caption)
        container.addArrangedSubview(selector)
        return container
    }

    private func makeCompletionRow() -> UIView {
        let caption = UILabel()
        caption.text = "Completed"
        caption.font = XTTTheme.font(16)
        caption.textColor = XTTTheme.textPrimary

        completeToggle.onTintColor = XTTTheme.statusReady

        let row = UIStackView(arrangedSubviews: [caption, completeToggle])
        row.axis = .horizontal
        row.alignment = .center

        let container = UIView()
        container.backgroundColor = XTTTheme.card
        container.layer.cornerRadius = XTTTheme.Radius.small
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = XTTTheme.separator.cgColor
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        row.xtt_pinEdges(to: container, insets: UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        return container
    }

    private func populate() {
        if let entry = existingEntry {
            titleRow.textField.text = entry.title
            dateRow.configure(date: entry.date)
            notesRow.text = entry.notes
            completeToggle.isOn = entry.isCompleted
        } else {
            // Default new entries to the next round hour.
            dateRow.configure(date: defaultStartDate())
        }
    }

    /// The upcoming top-of-the-hour, a sensible default for a new entry.
    private func defaultStartDate() -> Date {
        let calendar = Calendar.current
        let next = calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: next)
        components.minute = 0
        return calendar.date(from: components) ?? next
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let title = (titleRow.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            xtt_alert(title: "Title Required", message: "Please give your schedule entry a title.")
            return
        }

        let category = categorySelector.selectedValue(XTTScheduleCategory.self) ?? .task
        let priority = prioritySelector.selectedValue(XTTSchedulePriority.self) ?? .normal
        let notes = notesRow.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if var entry = existingEntry {
            entry.title = title
            entry.category = category
            entry.priority = priority
            entry.date = dateRow.selectedDate
            entry.notes = notes
            entry.isCompleted = completeToggle.isOn
            XTTDataStore.shared.updateSchedule(entry)
        } else {
            let entry = XTTScheduleEntry(title: title,
                                         category: category,
                                         priority: priority,
                                         date: dateRow.selectedDate,
                                         notes: notes,
                                         isCompleted: completeToggle.isOn)
            XTTDataStore.shared.addSchedule(entry)
        }
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
