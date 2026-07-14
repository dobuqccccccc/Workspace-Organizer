//
//  XTTTheme.swift
//  WorkspaceOrganizer
//
//  Dark Modern Utility Style — palette, typography, spacing.
//

import UIKit

/// Central design tokens for the app. Dark, modern, utility oriented.
enum XTTTheme {

    // MARK: - Core Palette

    /// Near-black app background.
    static let background = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
    /// Slightly lighter backdrop for grouped areas.
    static let backgroundElevated = UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
    /// Dark grey card surface.
    static let card = UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1.0)
    /// Card surface when highlighted / pressed.
    static let cardHighlight = UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1.0)
    /// Hairline separators.
    static let separator = UIColor(red: 0.20, green: 0.22, blue: 0.26, alpha: 1.0)

    // MARK: - Text

    static let textPrimary = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
    static let textSecondary = UIColor(red: 0.62, green: 0.65, blue: 0.71, alpha: 1.0)
    static let textTertiary = UIColor(red: 0.42, green: 0.45, blue: 0.51, alpha: 1.0)

    // MARK: - Accents

    /// Primary blue accent.
    static let accent = UIColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 1.0)
    static let accentDeep = UIColor(red: 0.10, green: 0.36, blue: 0.85, alpha: 1.0)
    /// Secondary orange accent.
    static let orange = UIColor(red: 1.0, green: 0.58, blue: 0.20, alpha: 1.0)
    static let orangeDeep = UIColor(red: 0.95, green: 0.42, blue: 0.10, alpha: 1.0)

    // MARK: - Status Colors

    static let statusReady = UIColor(red: 0.20, green: 0.80, blue: 0.52, alpha: 1.0)
    static let statusLow = UIColor(red: 1.0, green: 0.78, blue: 0.25, alpha: 1.0)
    static let statusReplace = UIColor(red: 1.0, green: 0.58, blue: 0.20, alpha: 1.0)
    static let statusExpired = UIColor(red: 1.0, green: 0.36, blue: 0.38, alpha: 1.0)

    // MARK: - Radius & Spacing

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let large: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 30
    }

    // MARK: - Typography

    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }

    static func roundedFont(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    // MARK: - Gradients

    static var accentGradient: [CGColor] {
        [accent.cgColor, accentDeep.cgColor]
    }

    static var orangeGradient: [CGColor] {
        [orange.cgColor, orangeDeep.cgColor]
    }

    /// A subtle top-to-bottom card sheen.
    static var cardGradient: [CGColor] {
        [
            UIColor(red: 0.14, green: 0.15, blue: 0.19, alpha: 1.0).cgColor,
            UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0).cgColor
        ]
    }
}
