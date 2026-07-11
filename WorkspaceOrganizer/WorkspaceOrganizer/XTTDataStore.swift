//
//  XTTDataStore.swift
//  WorkspaceOrganizer
//
//  Single source of truth for kits, items, inspections and activity.
//  Persists to a JSON file in Documents for logged-in users.
//  Guest sessions stay in memory only and are wiped on sign-out / relaunch.
//

import Foundation

extension Notification.Name {
    /// Posted whenever the store mutates so views can refresh.
    static let xttDataChanged = Notification.Name("xtt.dataChanged")
}

final class XTTDataStore {

    static let shared = XTTDataStore()

    private(set) var kits: [XTTKit] = []
    private(set) var activities: [XTTActivity] = []
    private(set) var schedules: [XTTScheduleEntry] = []

    /// When true, nothing is written to disk (guest mode).
    var isEphemeral: Bool = false

    private let fileName = "xtt_store.json"

    private init() {}

    // MARK: - Persistence Model

    private struct Snapshot: Codable {
        var kits: [XTTKit]
        var activities: [XTTActivity]
        /// Optional so older store files (pre-schedule) still decode cleanly.
        var schedules: [XTTScheduleEntry]?
    }

    private var storeURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(fileName)
    }

    // MARK: - Lifecycle

    /// Load persisted data from disk (skipped for guest mode).
    func loadFromDisk() {
        guard !isEphemeral else { return }
        guard let data = try? Data(contentsOf: storeURL),
              let snapshot = try? JSONDecoder.xtt.decode(Snapshot.self, from: data) else {
            kits = []
            activities = []
            schedules = []
            return
        }
        kits = snapshot.kits
        activities = snapshot.activities
        schedules = snapshot.schedules ?? []
    }

    /// Start a fresh in-memory guest session with a couple of sample kits.
    func startGuestSession() {
        isEphemeral = true
        kits = []
        activities = []
        schedules = []
        seedGuestSamples()
    }

    /// Wipe everything from memory (used when a guest session ends).
    func clearMemory() {
        kits = []
        activities = []
        schedules = []
    }

    /// Permanently delete all local data: photos, the JSON store file, and memory.
    /// Used by the "Delete Account" flow.
    func deleteAllData() {
        // Remove every stored photo (kit covers + item photos).
        for kit in kits {
            XTTImageStore.delete(kit.coverFileName)
            kit.items.forEach { XTTImageStore.delete($0.photoFileName) }
        }
        // Remove the persisted store file from disk.
        try? FileManager.default.removeItem(at: storeURL)
        // Clear in-memory state.
        kits = []
        activities = []
        schedules = []
        NotificationCenter.default.post(name: .xttDataChanged, object: nil)
    }

    private func persist() {
        NotificationCenter.default.post(name: .xttDataChanged, object: nil)
        guard !isEphemeral else { return }
        let snapshot = Snapshot(kits: kits, activities: activities, schedules: schedules)
        if let data = try? JSONEncoder.xtt.encode(snapshot) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    // MARK: - Kit CRUD

    func addKit(_ kit: XTTKit) {
        kits.insert(kit, at: 0)
        logActivity(.addedKit, title: kit.name, subtitle: kit.category.rawValue)
        persist()
    }

    func updateKit(_ kit: XTTKit) {
        guard let index = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        kits[index] = kit
        persist()
    }

    func deleteKit(_ kit: XTTKit) {
        XTTImageStore.delete(kit.coverFileName)
        kit.items.forEach { XTTImageStore.delete($0.photoFileName) }
        kits.removeAll { $0.id == kit.id }
        persist()
    }

    func kit(withID id: String) -> XTTKit? {
        kits.first { $0.id == id }
    }

    // MARK: - Item CRUD

    func addItem(_ item: XTTItem, toKit kitID: String) {
        guard let index = kits.firstIndex(where: { $0.id == kitID }) else { return }
        kits[index].items.insert(item, at: 0)
        logActivity(.addedItem, title: item.name, subtitle: kits[index].name)
        persist()
    }

    func updateItem(_ item: XTTItem, inKit kitID: String) {
        guard let kitIndex = kits.firstIndex(where: { $0.id == kitID }),
              let itemIndex = kits[kitIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        kits[kitIndex].items[itemIndex] = item
        logActivity(.updatedItem, title: item.name, subtitle: kits[kitIndex].name)
        persist()
    }

    func deleteItem(_ item: XTTItem, fromKit kitID: String) {
        guard let kitIndex = kits.firstIndex(where: { $0.id == kitID }) else { return }
        XTTImageStore.delete(item.photoFileName)
        kits[kitIndex].items.removeAll { $0.id == item.id }
        persist()
    }

    // MARK: - Schedule CRUD

    func addSchedule(_ entry: XTTScheduleEntry) {
        schedules.append(entry)
        logActivity(.scheduled, title: entry.title, subtitle: entry.category.rawValue)
        persist()
    }

    func updateSchedule(_ entry: XTTScheduleEntry) {
        guard let index = schedules.firstIndex(where: { $0.id == entry.id }) else { return }
        schedules[index] = entry
        persist()
    }

    func deleteSchedule(_ entry: XTTScheduleEntry) {
        schedules.removeAll { $0.id == entry.id }
        persist()
    }

    func toggleScheduleCompletion(_ entry: XTTScheduleEntry) {
        guard let index = schedules.firstIndex(where: { $0.id == entry.id }) else { return }
        schedules[index].isCompleted.toggle()
        persist()
    }

    /// Entries grouped by day (midnight), each group's entries sorted by time.
    /// Groups are returned in ascending day order.
    func schedulesByDay(includeCompleted: Bool = true) -> [(day: Date, entries: [XTTScheduleEntry])] {
        let source = includeCompleted ? schedules : schedules.filter { !$0.isCompleted }
        let grouped = Dictionary(grouping: source) { $0.day }
        return grouped
            .map { (day: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.day < $1.day }
    }

    /// Entries scheduled for today, sorted by time.
    func todaySchedules() -> [XTTScheduleEntry] {
        schedules
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var upcomingScheduleCount: Int {
        let now = Date()
        return schedules.filter { !$0.isCompleted && $0.date >= now }.count
    }

    var overdueScheduleCount: Int {
        schedules.filter { $0.isOverdue() }.count
    }

    // MARK: - Inspections

    func addInspection(_ inspection: XTTInspection, toKit kitID: String) {
        guard let index = kits.firstIndex(where: { $0.id == kitID }) else { return }
        kits[index].inspections.insert(inspection, at: 0)
        logActivity(.inspected, title: kits[index].name, subtitle: inspection.result)
        persist()
    }

    /// All inspections across all kits, newest first, paired with their kit name.
    func allInspections() -> [(kitName: String, inspection: XTTInspection)] {
        var results: [(String, XTTInspection)] = []
        for kit in kits {
            for inspection in kit.inspections {
                results.append((kit.name, inspection))
            }
        }
        return results.sorted { $0.1.date > $1.1.date }
    }

    // MARK: - Aggregate Stats

    var totalKits: Int { kits.count }

    var totalItems: Int { kits.reduce(0) { $0 + $1.totalItems } }

    var expiringSoonItems: [(kitName: String, item: XTTItem)] {
        collectItems { $0.isExpiringSoon(within: XTTSettings.shared.expiryWindowDays) }
            .sorted { ($0.item.expirationDate ?? .distantFuture) < ($1.item.expirationDate ?? .distantFuture) }
    }

    var expiredItems: [(kitName: String, item: XTTItem)] {
        collectItems { $0.isExpired() }
            .sorted { ($0.item.expirationDate ?? .distantPast) > ($1.item.expirationDate ?? .distantPast) }
    }

    var lowStockItems: [(kitName: String, item: XTTItem)] {
        collectItems { $0.effectiveStatus == .lowStock || $0.effectiveStatus == .needReplace }
    }

    func totalCount(for status: XTTItemStatus) -> Int {
        kits.reduce(0) { $0 + $1.count(for: status) }
    }

    func itemCountByCategory() -> [(category: XTTItemCategory, count: Int)] {
        var counts: [XTTItemCategory: Int] = [:]
        for kit in kits {
            for item in kit.items {
                counts[item.category, default: 0] += 1
            }
        }
        return XTTItemCategory.allCases
            .map { ($0, counts[$0] ?? 0) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    private func collectItems(_ predicate: (XTTItem) -> Bool) -> [(kitName: String, item: XTTItem)] {
        var results: [(String, XTTItem)] = []
        for kit in kits {
            for item in kit.items where predicate(item) {
                results.append((kit.name, item))
            }
        }
        return results
    }

    // MARK: - Activity

    private func logActivity(_ kind: XTTActivityKind, title: String, subtitle: String) {
        let activity = XTTActivity(kind: kind, title: title, subtitle: subtitle)
        activities.insert(activity, at: 0)
        if activities.count > 40 {
            activities = Array(activities.prefix(40))
        }
    }

    func recentActivities(limit: Int = 8) -> [XTTActivity] {
        Array(activities.prefix(limit))
    }

    // MARK: - Export

    /// Produce a human-readable plain-text export of all data.
    func exportText() -> String {
        var lines: [String] = []
        lines.append("X EMERGENCY KIT — DATA EXPORT")
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        lines.append("Generated: \(formatter.string(from: Date()))")
        lines.append("Total Kits: \(totalKits)   Total Items: \(totalItems)")
        lines.append(String(repeating: "=", count: 40))

        let dateOnly = DateFormatter()
        dateOnly.dateStyle = .medium

        for kit in kits {
            lines.append("")
            lines.append("KIT: \(kit.name)  [\(kit.category.rawValue)]")
            if !kit.detail.isEmpty { lines.append("  \(kit.detail)") }
            lines.append("  Items: \(kit.totalItems)  Ready: \(kit.readyCount)  Expired: \(kit.expiredCount)")
            for item in kit.items {
                var detail = "   • \(item.name) x\(item.quantity)  [\(item.effectiveStatus.rawValue)]"
                if !item.location.isEmpty { detail += "  @\(item.location)" }
                if let exp = item.expirationDate {
                    detail += "  exp: \(dateOnly.string(from: exp))"
                }
                lines.append(detail)
            }
            if !kit.inspections.isEmpty {
                lines.append("  Inspections:")
                for inspection in kit.inspections {
                    lines.append("   - \(dateOnly.string(from: inspection.date)): \(inspection.result)")
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Produce a pretty-printed JSON backup of all data.
    func exportJSON() -> Data? {
        let snapshot = Snapshot(kits: kits, activities: activities, schedules: schedules)
        return try? JSONEncoder.xtt.encode(snapshot)
    }

    // MARK: - Guest Samples

    private func seedGuestSamples() {
        var home = XTTKit(name: "Home Emergency Kit", category: .home,
                          detail: "Essentials kept at home for power outages and storms.")
        home.items = [
            XTTItem(name: "Flashlight", category: .lighting, quantity: 2, location: "Hall closet", status: .ready),
            XTTItem(name: "AA Batteries", category: .power, quantity: 4, location: "Drawer", status: .lowStock),
            XTTItem(name: "Bottled Water", category: .water, quantity: 12, location: "Pantry", status: .ready),
            XTTItem(name: "First Aid Box", category: .medicine, quantity: 1, location: "Bathroom", status: .ready)
        ]

        var car = XTTKit(name: "Car Emergency Kit", category: .car,
                         detail: "Roadside kit stored in the trunk.")
        car.items = [
            XTTItem(name: "Tool Set", category: .tools, quantity: 1, location: "Trunk", status: .ready),
            XTTItem(name: "Tire Repair", category: .tools, quantity: 1, location: "Trunk", status: .needReplace),
            XTTItem(name: "Emergency Charger", category: .power, quantity: 1, location: "Glovebox", status: .ready)
        ]

        kits = [home, car]
        activities = [
            XTTActivity(kind: .addedKit, title: "Home Emergency Kit", subtitle: "Home"),
            XTTActivity(kind: .addedKit, title: "Car Emergency Kit", subtitle: "Car")
        ]

        // A few sample schedule entries anchored to today for the guest demo.
        schedules = [
            XTTScheduleEntry(title: "Team Standup", category: .meeting, priority: .normal,
                             date: sampleDate(hour: 9, minute: 30, dayOffset: 0)),
            XTTScheduleEntry(title: "Prepare Weekly Report", category: .task, priority: .high,
                             date: sampleDate(hour: 14, minute: 0, dayOffset: 0)),
            XTTScheduleEntry(title: "Project Submission", category: .deadline, priority: .high,
                             date: sampleDate(hour: 17, minute: 0, dayOffset: 1)),
            XTTScheduleEntry(title: "Lunch Break", category: .breakTime, priority: .low,
                             date: sampleDate(hour: 12, minute: 0, dayOffset: 0))
        ]
    }

    /// Build a date at a given hour/minute, offset by whole days from today's midnight.
    private func sampleDate(hour: Int, minute: Int, dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let base = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }
}

