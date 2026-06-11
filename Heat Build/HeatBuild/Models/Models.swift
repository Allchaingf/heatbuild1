import Foundation
import SwiftUI

// MARK: - Project
struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var objectType: String
    var address: String
    var startDate: Date
    var notes: String
    var status: ProjectStatus
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    enum ProjectStatus: String, Codable, CaseIterable {
        case active = "Active"
        case inProgress = "In Progress"
        case completed = "Completed"
        case archived = "Archived"

        var color: Color {
            switch self {
            case .active: return .accentBlue
            case .inProgress: return .accentOrange
            case .completed: return .statusDone
            case .archived: return .textInactive
            }
        }
    }
}

// MARK: - Room
struct Room: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var name: String
    var floor: String
    var area: Double
    var notes: String
    var coverPhotoData: Data?
    var status: RoomStatus
    var createdAt: Date = Date()

    enum RoomStatus: String, Codable, CaseIterable {
        case ok = "OK"
        case warning = "Warning"
        case critical = "Critical"

        var color: Color {
            switch self {
            case .ok: return .statusDone
            case .warning: return .statusWarning
            case .critical: return .statusError
            }
        }
    }
}

// MARK: - ClimatePoint
struct ClimatePoint: Identifiable, Codable {
    var id: UUID = UUID()
    var roomId: UUID
    var title: String
    var temperature: Double
    var humidity: Double
    var locationX: Double // 0..1 normalized
    var locationY: Double // 0..1 normalized
    var isDraftRisk: Bool
    var date: Date = Date()
    var notes: String

    var problemType: ProblemType {
        if temperature < 15 { return .cold }
        if humidity > 70 { return .humidity }
        if isDraftRisk { return .draft }
        return .normal
    }

    enum ProblemType {
        case cold, humidity, draft, normal

        var color: Color {
            switch self {
            case .cold: return .accentBlueSoft
            case .humidity: return .accentOrangeSoft
            case .draft: return .statusWarning
            case .normal: return .statusDone
            }
        }

        var label: String {
            switch self {
            case .cold: return "Cold Zone"
            case .humidity: return "Humidity"
            case .draft: return "Draft Risk"
            case .normal: return "Normal"
            }
        }
    }
}

// MARK: - Record
struct Record: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID?
    var title: String
    var date: Date
    var category: RecordCategory
    var value: String
    var comment: String
    var photoData: Data?
    var status: RecordStatus
    var createdAt: Date = Date()

    enum RecordCategory: String, Codable, CaseIterable {
        case temperature = "Temperature"
        case humidity = "Humidity"
        case draft = "Draft"
        case damage = "Damage"
        case insulation = "Insulation"
        case other = "Other"

        var icon: String {
            switch self {
            case .temperature: return "thermometer"
            case .humidity: return "humidity"
            case .draft: return "wind"
            case .damage: return "exclamationmark.triangle"
            case .insulation: return "house.fill"
            case .other: return "doc.text"
            }
        }
    }

    enum RecordStatus: String, Codable, CaseIterable {
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"

        var color: Color {
            switch self {
            case .open: return .statusError
            case .inProgress: return .accentOrange
            case .resolved: return .statusDone
            }
        }
    }
}

// MARK: - Task
struct AppTask: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID?
    var title: String
    var description: String
    var dueDate: Date?
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date = Date()
    var completedAt: Date?

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .statusDone
            case .medium: return .statusWarning
            case .high: return .statusError
            }
        }
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
}

// MARK: - Photo
struct AppPhoto: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID?
    var category: PhotoCategory
    var imageData: Data
    var caption: String
    var date: Date = Date()

    enum PhotoCategory: String, Codable, CaseIterable {
        case before = "Before"
        case problem = "Problem"
        case progress = "Progress"
        case after = "After"

        var color: Color {
            switch self {
            case .before: return .textSecondary
            case .problem: return .statusError
            case .progress: return .accentOrange
            case .after: return .statusDone
            }
        }
    }
}

// MARK: - Recommendation
struct Recommendation: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID?
    var title: String
    var description: String
    var type: RecommendationType
    var isAddedToTasks: Bool = false
    var isDismissed: Bool = false

    enum RecommendationType: String, Codable, CaseIterable {
        case fix = "What to fix"
        case buy = "What to buy"
        case check = "What to check"

        var icon: String {
            switch self {
            case .fix: return "wrench.and.screwdriver"
            case .buy: return "cart"
            case .check: return "checkmark.shield"
            }
        }

        var color: Color {
            switch self {
            case .fix: return .statusError
            case .buy: return .accentOrange
            case .check: return .accentBlue
            }
        }
    }
}

// MARK: - CalendarEvent
struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID?
    var title: String
    var date: Date
    var type: EventType
    var notes: String

    enum EventType: String, Codable, CaseIterable {
        case check = "Check"
        case task = "Task"
        case deadline = "Deadline"

        var color: Color {
            switch self {
            case .check: return .accentBlue
            case .task: return .accentOrange
            case .deadline: return .statusError
            }
        }
    }
}
