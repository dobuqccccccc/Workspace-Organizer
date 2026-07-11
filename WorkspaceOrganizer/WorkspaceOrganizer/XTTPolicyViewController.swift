//
//  XTTPolicyViewController.swift
//  WorkspaceOrganizer
//
//  Static Privacy Policy / Terms of Use / About text screens.
//

import UIKit

final class XTTPolicyViewController: UIViewController {

    enum Kind {
        case privacy
        case terms
        case about

        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms of Use"
            case .about: return "About"
            }
        }
    }

    private let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        title = kind.title
        setupContent()
    }

    private func setupContent() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attributedBody()
        scroll.addSubview(label)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            label.topAnchor.constraint(equalTo: scroll.topAnchor, constant: XTTTheme.Spacing.l),
            label.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: XTTTheme.Spacing.l),
            label.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -XTTTheme.Spacing.l),
            label.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -XTTTheme.Spacing.xl),
            label.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -2 * XTTTheme.Spacing.l)
        ])
    }

    private func attributedBody() -> NSAttributedString {
        let result = NSMutableAttributedString()

        func heading(_ text: String) {
            let para = NSMutableParagraphStyle()
            para.paragraphSpacing = 6
            para.paragraphSpacingBefore = 16
            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: XTTTheme.font(18, .bold),
                .foregroundColor: XTTTheme.textPrimary,
                .paragraphStyle: para
            ]))
        }

        func body(_ text: String) {
            let para = NSMutableParagraphStyle()
            para.lineSpacing = 4
            para.paragraphSpacing = 8
            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: XTTTheme.font(15),
                .foregroundColor: XTTTheme.textSecondary,
                .paragraphStyle: para
            ]))
        }

        switch kind {
        case .privacy:
            body("Workspace Organizer is a personal emergency supply organization tool. Your privacy matters to us.")
            heading("Local Storage Only")
            body("All data you enter — kits, items, photos, inspection records and settings — is stored only on this device. The app works fully offline and does not require an account server.")
            heading("No Data Collection")
            body("We do not collect, transmit, sell or share any personal information. The app contains no advertising, no analytics SDKs, and no third-party tracking.")
            heading("Photos")
            body("Photos you attach to items are saved inside the app's private storage on your device. They are never uploaded anywhere.")
            heading("Your Control")
            body("You can delete any kit, item or record at any time. Removing the app deletes all associated local data.")
            heading("Contact")
            body("For questions about this policy, please use the support contact listed on the App Store product page.")
        case .terms:
            body("Please read these Terms of Use before using Workspace Organizer.")
            heading("Purpose")
            body("Workspace Organizer is an organizational tool that helps you record and manage your own personal emergency supplies. It is not a medical, safety-monitoring, or government emergency service.")
            heading("No Professional Advice")
            body("The app does not provide medical, safety, legal or emergency-response advice. In a real emergency, always contact your local emergency services.")
            heading("Your Responsibility")
            body("You are responsible for the accuracy of the information you enter and for maintaining your actual supplies. The app is a record-keeping aid only.")
            heading("Offline Use")
            body("The app stores data locally and does not sync to any cloud service. You are responsible for your own device backups.")
            heading("Acceptance")
            body("By using the app you agree to these terms. If you do not agree, please do not use the app.")
        case .about:
            body("Workspace Organizer")
            heading("Version")
            body("1.0")
            heading("What It Does")
            body("A clean, offline tool to organize your personal emergency supplies across different scenarios — home, car, travel, outdoor and medical kits. Track items, quantities, storage locations, status and expiration dates, and keep a simple inspection history.")
            heading("Privacy First")
            body("Everything stays on your device. No accounts required, no network, no ads, no tracking.")
        }

        return result
    }
}
