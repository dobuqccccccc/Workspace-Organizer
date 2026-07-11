//
//  XTTModels.swift
//  WorkspaceOrganizer
//
//  Domain models for kits, items, inspections and their enums.
//  All Codable for local JSON persistence.
//

import UIKit

// MARK: - Kit Category

enum XTTKitCategory: String, Codable, CaseIterable {
    case home = "Home"
    case car = "Car"
    case travel = "Travel"
    case outdoor = "Outdoor"
    case medical = "Medical"
    case other = "Other"

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .car: return "car.fill"
        case .travel: return "airplane"
        case .outdoor: return "leaf.fill"
        case .medical: return "cross.case.fill"
        case .other: return "shippingbox.fill"
        }
    }

    var tint: UIColor {
        switch self {
        case .home: return XTTTheme.accent
        case .car: return XTTTheme.orange
        case .travel: return UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1.0)
        case .outdoor: return XTTTheme.statusReady
        case .medical: return XTTTheme.statusExpired
        case .other: return XTTTheme.textSecondary
        }
    }
}

// MARK: - Item Category

enum XTTItemCategory: String, Codable, CaseIterable {
    case tools = "Tools"
    case food = "Food"
    case water = "Water"
    case medicine = "Medicine"
    case power = "Power"
    case lighting = "Lighting"
    case clothing = "Clothing"
    case documents = "Documents"
    case communication = "Communication"
    case other = "Other"

    var iconName: String {
        switch self {
        case .tools: return "wrench.and.screwdriver.fill"
        case .food: return "fork.knife"
        case .water: return "drop.fill"
        case .medicine: return "pills.fill"
        case .power: return "bolt.fill"
        case .lighting: return "flashlight.on.fill"
        case .clothing: return "tshirt.fill"
        case .documents: return "doc.text.fill"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .other: return "cube.box.fill"
        }
    }
}

// MARK: - Item Status

enum XTTItemStatus: String, Codable, CaseIterable {
    case ready = "Ready"
    case lowStock = "Low Stock"
    case needReplace = "Need Replace"
    case expired = "Expired"

    var color: UIColor {
        switch self {
        case .ready: return XTTTheme.statusReady
        case .lowStock: return XTTTheme.statusLow
        case .needReplace: return XTTTheme.statusReplace
        case .expired: return XTTTheme.statusExpired
        }
    }

    var iconName: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .lowStock: return "exclamationmark.triangle.fill"
        case .needReplace: return "arrow.triangle.2.circlepath"
        case .expired: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Item

struct XTTItem: Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var category: XTTItemCategory = .other
    var quantity: Int = 1
    var location: String = ""
    var status: XTTItemStatus = .ready
    var expirationDate: Date? = nil
    var notes: String = ""
    /// Relative filename inside the image store (nil when no photo).
    var photoFileName: String? = nil
    var createdAt: Date = Date()

    /// True when this item has an expiration date within the given window (days).
    func isExpiringSoon(within days: Int = 30, from reference: Date = Date()) -> Bool {
        guard let expiration = expirationDate else { return false }
        guard expiration >= reference else { return false }
        let interval = expiration.timeIntervalSince(reference)
        return interval <= Double(days) * 86_400
    }

    /// True when the expiration date is already in the past.
    func isExpired(from reference: Date = Date()) -> Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < reference
    }

    /// The status that best reflects the current data (used for auto-derivation hints).
    var effectiveStatus: XTTItemStatus {
        if isExpired() { return .expired }
        return status
    }
}

// MARK: - Inspection Record

struct XTTInspection: Codable, Equatable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var result: String
    var note: String = ""
    /// Count of items at inspection time (snapshot for history display).
    var itemCount: Int = 0
}

// MARK: - Kit

struct XTTKit: Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var category: XTTKitCategory = .home
    var detail: String = ""
    /// Relative filename inside the image store for the cover (nil when none).
    var coverFileName: String? = nil
    var items: [XTTItem] = []
    var inspections: [XTTInspection] = []
    var createdAt: Date = Date()

    // MARK: Derived Stats

    var totalItems: Int { items.count }

    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }

    var readyCount: Int { items.filter { $0.effectiveStatus == .ready }.count }

    var lowStockCount: Int { items.filter { $0.effectiveStatus == .lowStock }.count }

    var needReplaceCount: Int { items.filter { $0.effectiveStatus == .needReplace }.count }

    var expiredCount: Int { items.filter { $0.effectiveStatus == .expired }.count }

    var expiringSoonCount: Int { items.filter { $0.isExpiringSoon() }.count }

    /// 0...1 readiness ratio for progress rings.
    var readiness: Double {
        guard !items.isEmpty else { return 0 }
        return Double(readyCount) / Double(items.count)
    }

    func count(for status: XTTItemStatus) -> Int {
        items.filter { $0.effectiveStatus == status }.count
    }
}

// MARK: - Recent Activity

enum XTTActivityKind: String, Codable {
    case addedKit
    case addedItem
    case inspected
    case updatedItem
    case scheduled

    var iconName: String {
        switch self {
        case .addedKit: return "plus.square.fill.on.square.fill"
        case .addedItem: return "plus.circle.fill"
        case .inspected: return "checklist"
        case .updatedItem: return "pencil.circle.fill"
        case .scheduled: return "calendar.badge.plus"
        }
    }

    var tint: UIColor {
        switch self {
        case .addedKit: return XTTTheme.accent
        case .addedItem: return XTTTheme.statusReady
        case .inspected: return XTTTheme.orange
        case .updatedItem: return XTTTheme.textSecondary
        case .scheduled: return XTTTheme.accent
        }
    }
}

struct XTTActivity: Codable, Equatable {
    var id: String = UUID().uuidString
    var kind: XTTActivityKind
    var title: String
    var subtitle: String = ""
    var date: Date = Date()
}
