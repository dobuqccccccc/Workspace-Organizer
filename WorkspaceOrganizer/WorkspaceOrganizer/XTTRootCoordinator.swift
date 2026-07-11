//
//  XTTRootCoordinator.swift
//  WorkspaceOrganizer
//
//  Owns the root window transitions between Login and the main tab bar.
//

import UIKit

final class XTTRootCoordinator {

    static let shared = XTTRootCoordinator()
    private weak var window: UIWindow?
    private init() {}

    func attach(to window: UIWindow) {
        self.window = window
        if XTTSettings.shared.isLoggedIn && !XTTSettings.shared.isGuest {
            XTTDataStore.shared.isEphemeral = false
            XTTDataStore.shared.loadFromDisk()
            window.rootViewController = makeMain()
        } else {
            // Ensure any prior guest data is cleared on cold launch.
            XTTSettings.shared.endSession()
            window.rootViewController = makeLogin()
        }
    }

    // MARK: - Transitions

    func showMain(animated: Bool = true) {
        guard let window = window else { return }
        let main = makeMain()
        transition(to: main, in: window, animated: animated)
    }

    func showLogin(animated: Bool = true) {
        guard let window = window else { return }
        // Ending a session wipes guest data from memory.
        if XTTSettings.shared.isGuest {
            XTTDataStore.shared.clearMemory()
        }
        XTTSettings.shared.endSession()
        XTTDataStore.shared.isEphemeral = false
        let login = makeLogin()
        transition(to: login, in: window, animated: animated)
    }

    private func transition(to controller: UIViewController, in window: UIWindow, animated: Bool) {
        guard animated else {
            window.rootViewController = controller
            return
        }
        UIView.transition(with: window, duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { window.rootViewController = controller },
                          completion: nil)
    }

    // MARK: - Builders

    private func makeLogin() -> UIViewController {
        let login = XTTLoginViewController()
        return login
    }

    private func makeMain() -> UIViewController {
        return XTTMainTabBarController()
    }
}
    