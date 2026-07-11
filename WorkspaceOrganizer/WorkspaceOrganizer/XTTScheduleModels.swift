//
//  XTTScheduleModels.swift
//  WorkspaceOrganizer
//
//  Domain models for the work schedule feature.
//  Codable for local JSON persistence, matching the item/kit model style.
//

import UIKit

// MARK: - Schedule Category

enum XTTScheduleCategory: String, Codable, CaseIterable {
    case meeting = "Meeting"
    case task = "Task"
    case deadline = "Deadline"
    case reminder = "Reminder"
    case breakTime = "Break"
    case other = "Other"

    var iconName: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .task: return "checklist"
        case .deadline: return "flag.checkered"
        case .reminder: return "bell.fill"
        case .breakTime: return "cup.and.saucer.fill"
        case .other: return "calendar"
        }
    }

    var tint: UIColor {
        switch self {
        case .meeting: return XTTTheme.accent
        case .task: return XTTTheme.statusReady
        case .deadline: return XTTTheme.statusExpired
        case .reminder: return XTTTheme.orange
        case .breakTime: return UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1.0)
        case .other: return XTTTheme.textSecondary
        }
    }
}

// MARK: - Schedule Priority

enum XTTSchedulePriority: String, Codable, CaseIterable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"

    var color: UIColor {
        switch self {
        case .low: return XTTTheme.textSecondary
        case .normal: return XTTTheme.accent
        case .high: return XTTTheme.statusExpired
        }
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "minus.circle.fill"
        case .high: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Schedule Entry

struct XTTScheduleEntry: Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var category: XTTScheduleCategory = .task
    var priority: XTTSchedulePriority = .normal
    /// Combined date + time the entry is scheduled for.
    var date: Date = Date()
    var notes: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()

    /// The day (midnight) this entry belongs to — used for grouping.
    var day: Date {
        Calendar.current.startOfDay(for: date)
    }

    /// True when the scheduled time is in the past and not yet completed.
    func isOverdue(from reference: Date = Date()) -> Bool {
        !isCompleted && date < reference
    }

    /// "3:45 PM" style time-of-day string.
    var timeText: String {
        XTTScheduleFormat.time.string(from: date)
    }
}

// MARK: - Schedule Formatting

enum XTTScheduleFormat {
    /// e.g. "3:45 PM"
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// e.g. "Saturday, Jul 11" — the day-group header.
    static let dayHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    /// A friendly relative label for a day: "Today", "Tomorrow", "Yesterday" or the header date.
    static func dayLabel(for day: Date, reference: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return dayHeader.string(from: day)
    }
}
