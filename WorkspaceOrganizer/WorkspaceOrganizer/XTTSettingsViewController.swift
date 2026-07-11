//
//  XTTSettingsViewController.swift
//  WorkspaceOrganizer
//
//  App preferences: security, appearance, data export, legal, session.
//

import UIKit
import LocalAuthentication

final class XTTSettingsViewController: UIViewController {

    private enum RowKind {
        case toggle(isOn: () -> Bool, onChange: (Bool) -> Void)
        case disclosure(action: () -> Void)
        case value(text: String, action: () -> Void)
    }

    private struct Row {
        let icon: String
        let tint: UIColor
        let title: String
        let subtitle: String?
        let kind: RowKind
    }

    private struct Section {
        let title: String
        var rows: [Row]
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = "Settings"
        setupTable()
        buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildSections()
        tableView.reloadData()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = XTTTheme.separator
        tableView.register(XTTSettingsCell.self, forCellReuseIdentifier: XTTSettingsCell.reuseID)
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)
    }

    // MARK: - Sections

    private func buildSections() {
        let settings = XTTSettings.shared

        let security = Section(title: "Security", rows: [
            Row(icon: "faceid", tint: XTTTheme.accent, title: "Face ID Lock",
                subtitle: "Require Face ID to open the app",
                kind: .toggle(isOn: { settings.faceIDEnabled },
                              onChange: { [weak self] on in self?.setFaceID(on) })),
            Row(icon: "lock.rotation", tint: XTTTheme.accent, title: "Auto Lock",
                subtitle: "Lock when returning to the app",
                kind: .toggle(isOn: { settings.autoLockEnabled },
                              onChange: { on in settings.autoLockEnabled = on }))
        ])

        let appearance = Section(title: "Appearance", rows: [
            Row(icon: "paintpalette.fill", tint: XTTTheme.orange, title: "Orange Accent",
                subtitle: "Use orange as the primary accent",
                kind: .toggle(isOn: { settings.accentIsOrange },
                              onChange: { [weak self] on in
                                  settings.accentIsOrange = on
                                  self?.xtt_alert(title: "Accent Updated",
                                                  message: "The new accent will fully apply next launch.")
                              }))
        ])

        let expiryText = "\(settings.expiryWindowDays) days"
        let data = Section(title: "Data", rows: [
            Row(icon: "calendar.badge.clock", tint: XTTTheme.statusLow, title: "Expiry Window",
                subtitle: "How early to flag expiring items",
                kind: .value(text: expiryText, action: { [weak self] in self?.chooseExpiryWindow() })),
            Row(icon: "square.and.arrow.up.fill", tint: XTTTheme.statusReady, title: "Export Data",
                subtitle: "Share a JSON backup of your kits",
                kind: .disclosure(action: { [weak self] in self?.exportData() }))
        ])

        let about = Section(title: "About", rows: [
            Row(icon: "hand.raised.fill", tint: XTTTheme.accent, title: "Privacy Policy",
                subtitle: nil, kind: .disclosure(action: { [weak self] in self?.openPolicy(.privacy) })),
            Row(icon: "doc.text.fill", tint: XTTTheme.accent, title: "Terms of Use",
                subtitle: nil, kind: .disclosure(action: { [weak self] in self?.openPolicy(.terms) })),
            Row(icon: "info.circle.fill", tint: XTTTheme.accent, title: "About",
                subtitle: nil, kind: .disclosure(action: { [weak self] in self?.openPolicy(.about) }))
        ])

        let isGuest = XTTSettings.shared.isGuest
        let sessionTitle = isGuest ? "Exit Guest Session" : "Sign Out"
        var sessionRows = [
            Row(icon: "rectangle.portrait.and.arrow.right", tint: XTTTheme.statusExpired,
                title: sessionTitle, subtitle: nil,
                kind: .disclosure(action: { [weak self] in self?.confirmSignOut() }))
        ]
        // Delete Account is only meaningful for registered accounts (not guests).
        if !isGuest {
            sessionRows.append(
                Row(icon: "trash.fill", tint: XTTTheme.statusExpired, title: "Delete Account",
                    subtitle: "Permanently remove your account and all local data",
                    kind: .disclosure(action: { [weak self] in self?.confirmDeleteAccount() })))
        }
        let session = Section(title: "Session", rows: sessionRows)

        sections = [security, appearance, data, about, session]
    }

    // MARK: - Actions

    private func setFaceID(_ on: Bool) {
        guard on else {
            XTTSettings.shared.faceIDEnabled = false
            return
        }
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            XTTSettings.shared.faceIDEnabled = true
        } else {
            XTTSettings.shared.faceIDEnabled = false
            xtt_alert(title: "Unavailable",
                      message: "Face ID / passcode is not set up on this device.")
            tableView.reloadData()
        }
    }

    private func chooseExpiryWindow() {
        let alert = UIAlertController(title: "Expiry Window",
                                      message: "Flag items expiring within:",
                                      preferredStyle: .actionSheet)
        for days in [7, 14, 30, 60, 90] {
            alert.addAction(UIAlertAction(title: "\(days) days", style: .default) { [weak self] _ in
                XTTSettings.shared.expiryWindowDays = days
                self?.buildSections()
                self?.tableView.reloadData()
                NotificationCenter.default.post(name: .xttDataChanged, object: nil)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    private func exportData() {
        guard XTTDataStore.shared.totalKits > 0, let data = XTTDataStore.shared.exportJSON() else {
            xtt_alert(title: "Export Failed", message: "There is no data to export yet.")
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceOrganizer-Backup.json")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            xtt_alert(title: "Export Failed", message: "Could not create the backup file.")
            return
        }
        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = share.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(share, animated: true)
    }

    private func openPolicy(_ kind: XTTPolicyViewController.Kind) {
        navigationController?.pushViewController(XTTPolicyViewController(kind: kind), animated: true)
    }

    private func confirmSignOut() {
        let isGuest = XTTSettings.shared.isGuest
        let alert = UIAlertController(
            title: isGuest ? "Exit Guest Session?" : "Sign Out?",
            message: isGuest
                ? "Guest data is temporary and will be cleared."
                : "You can sign back in anytime. Your saved data stays on this device.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: isGuest ? "Exit" : "Sign Out", style: .destructive) { _ in
            XTTRootCoordinator.shared.showLogin()
        })
        present(alert, animated: true)
    }

    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account?",
            message: "This permanently deletes your account and all kits, items, photos and inspection records on this device. This cannot be undone.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        present(alert, animated: true)
    }

    private func performDeleteAccount() {
        // Remove stored credentials from Keychain.
        if let email = XTTSettings.shared.accountEmail {
            XTTKeychainHelper.delete(account: email)
        }
        // Wipe all local data (kits, items, photos) and reset the account state.
        XTTDataStore.shared.deleteAllData()
        XTTSettings.shared.resetAccount()
        // Return to the login screen.
        XTTRootCoordinator.shared.showLogin()
    }
}

// MARK: - Table

extension XTTSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: XTTSettingsCell.reuseID, for: indexPath) as! XTTSettingsCell
        let row = sections[indexPath.section].rows[indexPath.row]

        var valueText: String?
        var showToggle = false
        var toggleOn = false
        var showChevron = false
        var onToggle: ((Bool) -> Void)?

        switch row.kind {
        case .toggle(let isOn, let change):
            showToggle = true
            toggleOn = isOn()
            onToggle = change
        case .disclosure:
            showChevron = true
        case .value(let text, _):
            valueText = text
            showChevron = true
        }

        cell.configure(with: XTTSettingsCell.Display(
            icon: row.icon,
            tint: row.tint,
            title: row.title,
            subtitle: row.subtitle,
            valueText: valueText,
            showToggle: showToggle,
            toggleOn: toggleOn,
            showChevron: showChevron,
            onToggle: onToggle))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .disclosure(let action): action()
        case .value(_, let action): action()
        case .toggle: break
        }
    }
}

// MARK: - Settings Cell

final class XTTSettingsCell: UITableViewCell {

    static let reuseID = "XTTSettingsCell"

    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()
    private let toggle = UISwitch()
    private var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        backgroundColor = XTTTheme.card
        selectionStyle = .default
        let selectedBG = UIView()
        selectedBG.backgroundColor = XTTTheme.cardHighlight
        selectedBackgroundView = selectedBG

        iconWrap.layer.cornerRadius = 8
        iconWrap.layer.cornerCurve = .continuous
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .center
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        iconView.xtt_pinEdges(to: iconWrap)

        titleLabel.font = XTTTheme.font(16)
        titleLabel.textColor = XTTTheme.textPrimary

        subtitleLabel.font = XTTTheme.font(12)
        subtitleLabel.textColor = XTTTheme.textTertiary
        subtitleLabel.numberOfLines = 0

        valueLabel.font = XTTTheme.font(15)
        valueLabel.textColor = XTTTheme.textSecondary

        toggle.onTintColor = XTTTheme.accent
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let accessory = UIStackView(arrangedSubviews: [valueLabel, toggle])
        accessory.axis = .horizontal
        accessory.spacing = 8
        accessory.alignment = .center
        accessory.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconWrap)
        contentView.addSubview(textStack)
        contentView.addSubview(accessory)

        NSLayoutConstraint.activate([
            iconWrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconWrap.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 30),
            iconWrap.heightAnchor.constraint(equalToConstant: 30),

            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            textStack.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: accessory.leadingAnchor, constant: -8),

            accessory.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            accessory.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    /// Display model passed from the controller (keeps the cell decoupled).
    struct Display {
        let icon: String
        let tint: UIColor
        let title: String
        let subtitle: String?
        let valueText: String?
        let showToggle: Bool
        let toggleOn: Bool
        let showChevron: Bool
        let onToggle: ((Bool) -> Void)?
    }

    func configure(with display: Display) {
        iconWrap.backgroundColor = display.tint
        iconView.image = UIImage(systemName: display.icon)
        titleLabel.text = display.title
        subtitleLabel.text = display.subtitle
        subtitleLabel.isHidden = (display.subtitle == nil)

        valueLabel.text = display.valueText
        valueLabel.isHidden = (display.valueText == nil)

        toggle.isHidden = !display.showToggle
        toggle.isOn = display.toggleOn
        onToggle = display.onToggle

        accessoryType = display.showChevron ? .disclosureIndicator : .none
        selectionStyle = display.showToggle ? .none : .default
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
