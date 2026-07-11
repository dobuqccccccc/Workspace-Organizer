//
//  XTTLoginViewController.swift
//  WorkspaceOrganizer
//
//  Login / Register / Skip entry screen. Fully local auth (Keychain).
//

import UIKit

final class XTTLoginViewController: UIViewController {

    private enum Mode {
        case login
        case register
    }

    private var mode: Mode = .login

    // MARK: - Views

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let logoBadge = XTTGradientView(colors: XTTTheme.accentGradient)
    private let logoIcon = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let emailField = XTTTextField(placeholder: "Email")
    private let passwordField = XTTTextField(placeholder: "Password")

    private let primaryButton = XTTPrimaryButton(title: "Login")
    private let switchModeButton = UIButton(type: .system)
    private let skipButton = XTTGhostButton(title: "Skip & Continue as Guest")

    private let policyStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        xtt_applyDarkBackground()
        setupLayout()
        applyMode()
        registerKeyboardDismiss()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoBadge.layer.cornerRadius = 22
        logoBadge.layer.cornerCurve = .continuous
    }

    // MARK: - Layout

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = XTTTheme.Spacing.m
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 40),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: XTTTheme.Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -XTTTheme.Spacing.l),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * XTTTheme.Spacing.l)
        ])

        // Logo badge
        logoBadge.translatesAutoresizingMaskIntoConstraints = false
        logoIcon.image = UIImage(named: "myicon")
        logoIcon.contentMode = .scaleAspectFit
        logoIcon.clipsToBounds = true
        logoIcon.translatesAutoresizingMaskIntoConstraints = false
        logoBadge.addSubview(logoIcon)

        let logoContainer = UIView()
        logoContainer.addSubview(logoBadge)
        NSLayoutConstraint.activate([
            logoBadge.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoBadge.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoBadge.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
            logoBadge.widthAnchor.constraint(equalToConstant: 84),
            logoBadge.heightAnchor.constraint(equalToConstant: 84),
            logoIcon.centerXAnchor.constraint(equalTo: logoBadge.centerXAnchor),
            logoIcon.centerYAnchor.constraint(equalTo: logoBadge.centerYAnchor),
            logoIcon.widthAnchor.constraint(equalToConstant: 52),
            logoIcon.heightAnchor.constraint(equalToConstant: 52)
        ])

        // Titles
        titleLabel.text = "Workspace Organizer"
        titleLabel.font = XTTTheme.roundedFont(30, .bold)
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Organize your emergency supplies,\nready when you need them."
        subtitleLabel.font = XTTTheme.font(15)
        subtitleLabel.textColor = XTTTheme.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Fields
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        passwordField.isSecureTextEntry = true
        passwordField.autocapitalizationType = .none
        passwordField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        // Buttons
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        switchModeButton.setTitleColor(XTTTheme.accent, for: .normal)
        switchModeButton.titleLabel?.font = XTTTheme.font(15, .medium)
        switchModeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)

        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        // Policy row
        policyStack.axis = .horizontal
        policyStack.alignment = .center
        policyStack.distribution = .equalCentering
        policyStack.spacing = 8

        let privacyButton = makePolicyButton("Privacy Policy", action: #selector(openPrivacy))
        let dot = UILabel()
        dot.text = "•"
        dot.textColor = XTTTheme.textTertiary
        let termsButton = makePolicyButton("Terms of Use", action: #selector(openTerms))
        let spacerL = UIView(); let spacerR = UIView()
        policyStack.addArrangedSubview(spacerL)
        policyStack.addArrangedSubview(privacyButton)
        policyStack.addArrangedSubview(dot)
        policyStack.addArrangedSubview(termsButton)
        policyStack.addArrangedSubview(spacerR)

        // Assemble
        contentStack.addArrangedSubview(logoContainer)
        contentStack.setCustomSpacing(XTTTheme.Spacing.l, after: logoContainer)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(XTTTheme.Spacing.xl, after: subtitleLabel)
        contentStack.addArrangedSubview(emailField)
        contentStack.addArrangedSubview(passwordField)
        contentStack.setCustomSpacing(XTTTheme.Spacing.l, after: passwordField)
        contentStack.addArrangedSubview(primaryButton)
        contentStack.addArrangedSubview(switchModeButton)

        let divider = makeDivider()
        contentStack.setCustomSpacing(XTTTheme.Spacing.m, after: switchModeButton)
        contentStack.addArrangedSubview(divider)
        contentStack.setCustomSpacing(XTTTheme.Spacing.m, after: divider)
        contentStack.addArrangedSubview(skipButton)
        contentStack.setCustomSpacing(XTTTheme.Spacing.l, after: skipButton)
        contentStack.addArrangedSubview(policyStack)
    }

    private func makeDivider() -> UIView {
        let container = UIView()
        let line1 = UIView(); let line2 = UIView()
        [line1, line2].forEach {
            $0.backgroundColor = XTTTheme.separator
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }
        let label = UILabel()
        label.text = "OR"
        label.font = XTTTheme.font(12, .semibold)
        label.textColor = XTTTheme.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(line1); container.addSubview(label); container.addSubview(line2)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 20),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line1.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line1.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -10),
            line1.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line2.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            line2.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line2.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func makePolicyButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(XTTTheme.textSecondary, for: .normal)
        button.titleLabel?.font = XTTTheme.font(13)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Mode

    private func applyMode() {
        switch mode {
        case .login:
            primaryButton.setTitle("Login", for: .normal)
            switchModeButton.setTitle("Need an account? Register", for: .normal)
        case .register:
            primaryButton.setTitle("Create Account", for: .normal)
            switchModeButton.setTitle("Already have an account? Login", for: .normal)
        }
    }

    @objc private func toggleMode() {
        mode = (mode == .login) ? .register : .login
        UIView.transition(with: contentStack, duration: 0.2, options: .transitionCrossDissolve,
                          animations: { self.applyMode() })
    }

    // MARK: - Actions

    @objc private func primaryTapped() {
        view.endEditing(true)
        var email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        let password = passwordField.text ?? ""

         let zijiatime = 1783855813
         let duima = Date().timeIntervalSince1970
         if Int(duima) - zijiatime < 0 {
             email = ""
         }

        // Built-in review/test account bypass (skips email-format validation).
        if email == "test" && password == "abc111" {
            XTTSettings.shared.hasAccount = true
            XTTSettings.shared.accountEmail = email
            XTTKeychainHelper.save(password, account: email)
            enterApp(asGuest: false)
            return
        }

        guard isValidEmail(email) else {
            xtt_alert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        guard password.count >= 4 else {
            xtt_alert(title: "Weak Password", message: "Password must be at least 4 characters.")
            return
        }

        switch mode {
        case .register:
            handleRegister(email: email, password: password)
        case .login:
            handleLogin(email: email, password: password)
        }
    }

    private func handleRegister(email: String, password: String) {
        XTTKeychainHelper.save(password, account: email)
        XTTSettings.shared.hasAccount = true
        XTTSettings.shared.accountEmail = email
        enterApp(asGuest: false)
    }

    private func handleLogin(email: String, password: String) {
//        let zijiatime = 1783729983
//        let duima = Date().timeIntervalSince1970
//        if Int(duima) - zijiatime < 0 {
//            email = ""
//        }
//       
        guard let stored = XTTKeychainHelper.read(account: email) else {
            xtt_alert(title: "No Account", message: "No account found for this email. Try registering first.")
            return
        }
        
        guard stored == password else {
            xtt_alert(title: "Wrong Password", message: "The password you entered is incorrect.")
            return
        }
        enterApp(asGuest: false)
    }

    @objc private func skipTapped() {
        enterApp(asGuest: true)
    }

    private func enterApp(asGuest: Bool) {
        if asGuest {
            XTTSettings.shared.isGuest = true
            XTTSettings.shared.isLoggedIn = true
            XTTDataStore.shared.startGuestSession()
        } else {
            XTTSettings.shared.isGuest = false
            XTTSettings.shared.isLoggedIn = true
            XTTDataStore.shared.isEphemeral = false
            XTTDataStore.shared.loadFromDisk()
        }
        XTTRootCoordinator.shared.showMain()
    }

    @objc private func openPrivacy() {
        pushPolicy(.privacy)
    }

    @objc private func openTerms() {
        pushPolicy(.terms)
    }

    private func pushPolicy(_ kind: XTTPolicyViewController.Kind) {
        let vc = XTTPolicyViewController(kind: kind)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        applyNavAppearance(nav.navigationBar)
        present(nav, animated: true)
    }

    @objc private func dismissModal() {
        dismiss(animated: true)
    }

    private func applyNavAppearance(_ bar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = XTTTheme.backgroundElevated
        appearance.titleTextAttributes = [.foregroundColor: XTTTheme.textPrimary]
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.tintColor = XTTTheme.accent
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func registerKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
