//
//  XTTSettings.swift
//  WorkspaceOrganizer
//
//  App preferences and session state persisted in UserDefaults.
//

import Foundation

final class XTTSettings {

    static let shared = XTTSettings()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Key {
        static let hasAccount = "xtt.hasAccount"
        static let accountEmail = "xtt.accountEmail"
        static let isLoggedIn = "xtt.isLoggedIn"
        static let isGuest = "xtt.isGuest"
        static let faceIDEnabled = "xtt.faceIDEnabled"
        static let autoLockEnabled = "xtt.autoLockEnabled"
        static let accentIsOrange = "xtt.accentIsOrange"
        static let expiryWindowDays = "xtt.expiryWindowDays"
    }

    // MARK: - Account

    var hasAccount: Bool {
        get { defaults.bool(forKey: Key.hasAccount) }
        set { defaults.set(newValue, forKey: Key.hasAccount) }
    }

    var accountEmail: String? {
        get { defaults.string(forKey: Key.accountEmail) }
        set { defaults.set(newValue, forKey: Key.accountEmail) }
    }

    var isLoggedIn: Bool {
        get { defaults.bool(forKey: Key.isLoggedIn) }
        set { defaults.set(newValue, forKey: Key.isLoggedIn) }
    }

    var isGuest: Bool {
        get { defaults.bool(forKey: Key.isGuest) }
        set { defaults.set(newValue, forKey: Key.isGuest) }
    }

    // MARK: - Preferences

    var faceIDEnabled: Bool {
        get { defaults.bool(forKey: Key.faceIDEnabled) }
        set { defaults.set(newValue, forKey: Key.faceIDEnabled) }
    }

    var autoLockEnabled: Bool {
        get { defaults.bool(forKey: Key.autoLockEnabled) }
        set { defaults.set(newValue, forKey: Key.autoLockEnabled) }
    }

    var accentIsOrange: Bool {
        get { defaults.bool(forKey: Key.accentIsOrange) }
        set { defaults.set(newValue, forKey: Key.accentIsOrange) }
    }

    /// Number of days that counts as "expiring soon". Defaults to 30.
    var expiryWindowDays: Int {
        get {
            let stored = defaults.integer(forKey: Key.expiryWindowDays)
            return stored == 0 ? 30 : stored
        }
        set { defaults.set(newValue, forKey: Key.expiryWindowDays) }
    }

    // MARK: - Session Helpers

    /// Clears session flags (keeps account credentials). Used on sign-out.
    func endSession() {
        isLoggedIn = false
        isGuest = false
    }

    /// Erases the account record and session flags. Used on account deletion.
    /// Credentials in the Keychain are removed separately by the caller.
    func resetAccount() {
        hasAccount = false
        accountEmail = nil
        isLoggedIn = false
        isGuest = false
    }
}
