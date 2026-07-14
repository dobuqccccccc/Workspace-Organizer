//
//  XTTHelpers.swift
//  WorkspaceOrganizer
//
//  Shared extensions and small utilities used across the app.
//

import UIKit

// MARK: - Auto Layout

extension UIView {
    /// Pin all four edges to another view with optional insets.
    func xtt_pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)
        ])
    }

    /// Pin all four edges to a layout guide with optional insets.
    func xtt_pinEdges(to guide: UILayoutGuide, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom)
        ])
    }

    /// Center this view within another view.
    func xtt_centerIn(_ other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: other.centerXAnchor),
            centerYAnchor.constraint(equalTo: other.centerYAnchor)
        ])
    }
}

// MARK: - View Controller Chrome

extension UIViewController {
    /// Apply the standard dark background to a controller's view.
    func xtt_applyDarkBackground() {
        view.backgroundColor = XTTTheme.background
        overrideUserInterfaceStyle = .dark
    }

    /// Present a simple single-button alert.
    func xtt_alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Date Formatting

enum XTTDateFormat {
    /// e.g. "Jul 1, 2026"
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// e.g. "Jul 1, 2026 at 3:45 PM"
    static let long: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - JSON Coding

extension JSONEncoder {
    /// Shared encoder with ISO-8601 dates.
    static let xtt: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }()
}

extension JSONDecoder {
    /// Shared decoder with ISO-8601 dates.
    static let xtt: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - Relative Time

enum XTTRelativeTime {
    /// A short human string like "2h ago", "3d ago", "just now".
    static func string(from date: Date, reference: Date = Date()) -> String {
        let interval = reference.timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86_400 { return "\(Int(interval / 3600))h ago" }
        let days = Int(interval / 86_400)
        if days < 7 { return "\(days)d ago" }
        return XTTDateFormat.short.string(from: date)
    }

    /// Days until a future date (negative if in the past).
    static func daysUntil(_ date: Date, reference: Date = Date()) -> Int {
        let start = Calendar.current.startOfDay(for: reference)
        let end = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
