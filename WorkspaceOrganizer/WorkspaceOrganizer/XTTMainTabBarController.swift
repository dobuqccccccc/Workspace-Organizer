//
//  XTTMainTabBarController.swift
//  WorkspaceOrganizer
//
//  Root tab bar hosting Dashboard, Kits, Expiration, Stats and Settings.
//

import UIKit

final class XTTMainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTabs()
    }

    private func setupTabs() {
        let dashboard = wrap(XTTDashboardViewController(),
                             title: "Home", symbol: "square.grid.2x2.fill")
        let schedule = wrap(XTTScheduleViewController(),
                            title: "Schedule", symbol: "calendar")
        let kits = wrap(XTTKitListViewController(),
                        title: "Kits", symbol: "shippingbox.fill")
        let expiration = wrap(XTTExpirationViewController(),
                              title: "Expiry", symbol: "clock.badge.exclamationmark.fill")
        let stats = wrap(XTTStatisticsViewController(),
                         title: "Stats", symbol: "chart.bar.fill")
        let settings = wrap(XTTSettingsViewController(),
                            title: "Settings", symbol: "gearshape.fill")

        viewControllers = [dashboard, schedule, kits, expiration, stats, settings]
    }

    private func wrap(_ controller: UIViewController, title: String, symbol: String) -> UINavigationController {
        controller.title = title
        let nav = UINavigationController(rootViewController: controller)
        nav.navigationBar.prefersLargeTitles = true
        XTTAppearance.applyNav(nav.navigationBar)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: symbol),
            selectedImage: UIImage(systemName: symbol)
        )
        return nav
    }

    private func setupAppearance() {
        XTTAppearance.applyTabBar(tabBar)
    }
}

// MARK: - Shared Appearance

enum XTTAppearance {

    static func applyNav(_ bar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = XTTTheme.background
        appearance.shadowColor = XTTTheme.separator.withAlphaComponent(0.4)
        appearance.titleTextAttributes = [.foregroundColor: XTTTheme.textPrimary]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: XTTTheme.textPrimary,
            .font: XTTTheme.roundedFont(32, .bold)
        ]
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = XTTTheme.accent
    }

    static func applyTabBar(_ bar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = XTTTheme.backgroundElevated

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = XTTTheme.textTertiary
        normal.titleTextAttributes = [.foregroundColor: XTTTheme.textTertiary]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = XTTTheme.accent
        selected.titleTextAttributes = [.foregroundColor: XTTTheme.accent]

        bar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            bar.scrollEdgeAppearance = appearance
        }
        bar.tintColor = XTTTheme.accent
    }
}
