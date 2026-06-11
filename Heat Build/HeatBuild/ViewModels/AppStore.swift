import Foundation
import SwiftUI
import Combine

class AppStore: ObservableObject {
    // MARK: - Published Data
    @Published var projects: [Project] = []
    @Published var rooms: [Room] = []
    @Published var climatePoints: [ClimatePoint] = []
    @Published var records: [Record] = []
    @Published var tasks: [AppTask] = []
    @Published var photos: [AppPhoto] = []
    @Published var recommendations: [Recommendation] = []
    @Published var calendarEvents: [CalendarEvent] = []

    @Published var selectedProjectId: UUID?

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    // MARK: - Init
    init() {
        loadAll()
        if projects.isEmpty { seedDemoData() }
    }

    // MARK: - Persistence
    private func key(_ name: String) -> String { "heatbuild_\(name)" }

    func saveAll() {
        save(projects, key: key("projects"))
        save(rooms, key: key("rooms"))
        save(climatePoints, key: key("climatePoints"))
        save(records, key: key("records"))
        save(tasks, key: key("tasks"))
        save(photos, key: key("photos"))
        save(recommendations, key: key("recommendations"))
        save(calendarEvents, key: key("calendarEvents"))
        if let id = selectedProjectId {
            UserDefaults.standard.set(id.uuidString, forKey: key("selectedProjectId"))
        }
    }

    func loadAll() {
        projects = load(key: key("projects")) ?? []
        rooms = load(key: key("rooms")) ?? []
        climatePoints = load(key: key("climatePoints")) ?? []
        records = load(key: key("records")) ?? []
        tasks = load(key: key("tasks")) ?? []
        photos = load(key: key("photos")) ?? []
        recommendations = load(key: key("recommendations")) ?? []
        calendarEvents = load(key: key("calendarEvents")) ?? []
        if let idStr = UserDefaults.standard.string(forKey: key("selectedProjectId")),
           let id = UUID(uuidString: idStr) {
            selectedProjectId = id
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Projects CRUD
    func addProject(_ project: Project) {
        projects.append(project)
        if selectedProjectId == nil { selectedProjectId = project.id }
        generateRecommendations(for: project.id)
        saveAll()
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var p = project; p.updatedAt = Date()
            projects[idx] = p
        }
        saveAll()
    }

    func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        rooms.removeAll { $0.projectId == id }
        records.removeAll { $0.projectId == id }
        tasks.removeAll { $0.projectId == id }
        photos.removeAll { $0.projectId == id }
        if selectedProjectId == id { selectedProjectId = projects.first?.id }
        saveAll()
    }

    func archiveProject(_ id: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].status = .archived
        }
        saveAll()
    }

    // MARK: - Rooms CRUD
    func addRoom(_ room: Room) {
        rooms.append(room)
        saveAll()
    }

    func updateRoom(_ room: Room) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[idx] = room
        }
        saveAll()
    }

    func deleteRoom(_ id: UUID) {
        rooms.removeAll { $0.id == id }
        climatePoints.removeAll { $0.roomId == id }
        records.removeAll { $0.roomId == id }
        saveAll()
    }

    func rooms(for projectId: UUID) -> [Room] {
        rooms.filter { $0.projectId == projectId }
    }

    // MARK: - Climate Points CRUD
    func addClimatePoint(_ point: ClimatePoint) {
        climatePoints.append(point)
        saveAll()
    }

    func updateClimatePoint(_ point: ClimatePoint) {
        if let idx = climatePoints.firstIndex(where: { $0.id == point.id }) {
            climatePoints[idx] = point
        }
        saveAll()
    }

    func deleteClimatePoint(_ id: UUID) {
        climatePoints.removeAll { $0.id == id }
        saveAll()
    }

    func climatePoints(for roomId: UUID) -> [ClimatePoint] {
        climatePoints.filter { $0.roomId == roomId }
    }

    // MARK: - Records CRUD
    func addRecord(_ record: Record) {
        records.append(record)
        saveAll()
    }

    func updateRecord(_ record: Record) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
        }
        saveAll()
    }

    func deleteRecord(_ id: UUID) {
        records.removeAll { $0.id == id }
        saveAll()
    }

    func duplicateRecord(_ record: Record) {
        var copy = record
        copy.id = UUID()
        copy.title = record.title + " (copy)"
        copy.createdAt = Date()
        records.append(copy)
        saveAll()
    }

    func records(for projectId: UUID) -> [Record] {
        records.filter { $0.projectId == projectId }
    }

    // MARK: - Tasks CRUD
    func addTask(_ task: AppTask) {
        tasks.append(task)
        saveAll()
    }

    func updateTask(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
        saveAll()
    }

    func toggleTask(_ id: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].isCompleted.toggle()
            tasks[idx].completedAt = tasks[idx].isCompleted ? Date() : nil
        }
        saveAll()
    }

    func deleteTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        saveAll()
    }

    var todayTasks: [AppTask] { tasks.filter { $0.isDueToday && !$0.isCompleted } }
    var overdueTasks: [AppTask] { tasks.filter { $0.isOverdue } }

    // MARK: - Photos CRUD
    func addPhoto(_ photo: AppPhoto) {
        photos.append(photo)
        saveAll()
    }

    func deletePhoto(_ id: UUID) {
        photos.removeAll { $0.id == id }
        saveAll()
    }

    // MARK: - Recommendations
    func addRecommendationToTasks(_ rec: Recommendation) {
        if let idx = recommendations.firstIndex(where: { $0.id == rec.id }) {
            recommendations[idx].isAddedToTasks = true
        }
        let task = AppTask(
            projectId: rec.projectId,
            title: rec.title,
            description: rec.description,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            isCompleted: false,
            priority: .medium
        )
        tasks.append(task)
        saveAll()
    }

    func dismissRecommendation(_ id: UUID) {
        if let idx = recommendations.firstIndex(where: { $0.id == id }) {
            recommendations[idx].isDismissed = true
        }
        saveAll()
    }

    func saveRecommendation(_ id: UUID) {
        // already saved, just mark it
        saveAll()
    }

    // MARK: - Calendar Events CRUD
    func addCalendarEvent(_ event: CalendarEvent) {
        calendarEvents.append(event)
        saveAll()
    }

    func updateCalendarEvent(_ event: CalendarEvent) {
        if let idx = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            calendarEvents[idx] = event
        }
        saveAll()
    }

    func deleteCalendarEvent(_ id: UUID) {
        calendarEvents.removeAll { $0.id == id }
        saveAll()
    }

    // MARK: - Analytics
    var totalProblems: Int {
        guard let pid = selectedProjectId else { return 0 }
        return records(for: pid).filter { $0.status == .open }.count
    }

    var progressPercent: Double {
        guard let pid = selectedProjectId else { return 0 }
        let all = records(for: pid)
        guard !all.isEmpty else { return 0 }
        let done = all.filter { $0.status == .resolved }.count
        return Double(done) / Double(all.count)
    }

    var warningCount: Int {
        climatePoints.filter { $0.problemType != .normal }.count
    }

    // MARK: - Auto Recommendations
    func generateRecommendations(for projectId: UUID) {
        let defaults: [Recommendation] = [
            Recommendation(projectId: projectId, title: "Check all window seals", description: "Inspect window frames and sealant for gaps causing drafts.", type: .check),
            Recommendation(projectId: projectId, title: "Install mineral wool insulation", description: "Add 100mm mineral wool to cold exterior walls.", type: .buy),
            Recommendation(projectId: projectId, title: "Fix moisture barrier", description: "Replace damaged vapor barrier in humid zones.", type: .fix),
            Recommendation(projectId: projectId, title: "Buy hygrometer set", description: "Place digital hygrometers in each room to track humidity continuously.", type: .buy),
            Recommendation(projectId: projectId, title: "Seal floor-wall junctions", description: "Apply expanding foam to all floor-wall connections.", type: .fix),
        ]
        recommendations.append(contentsOf: defaults)
        saveAll()
    }

    // MARK: - Seed Demo Data
    func seedDemoData() {
        let projId = UUID()
        let proj = Project(id: projId, name: "My Apartment", objectType: "Apartment", address: "ul. Lenina 5, Valencia", startDate: Date(), notes: "Main insulation audit", status: .active)
        projects.append(proj)
        selectedProjectId = projId

        let room1Id = UUID()
        let room2Id = UUID()
        rooms.append(Room(id: room1Id, projectId: projId, name: "Living Room", floor: "1", area: 24.5, notes: "", coverPhotoData: nil, status: .warning))
        rooms.append(Room(id: room2Id, projectId: projId, name: "Bedroom", floor: "1", area: 16.0, notes: "", coverPhotoData: nil, status: .critical))

        climatePoints.append(ClimatePoint(id: UUID(), roomId: room1Id, title: "Window corner", temperature: 12.5, humidity: 65, locationX: 0.2, locationY: 0.3, isDraftRisk: true, date: Date(), notes: "Cold near window"))
        climatePoints.append(ClimatePoint(id: UUID(), roomId: room1Id, title: "Center", temperature: 19.0, humidity: 50, locationX: 0.5, locationY: 0.5, isDraftRisk: false, date: Date(), notes: "Normal"))
        climatePoints.append(ClimatePoint(id: UUID(), roomId: room2Id, title: "North wall", temperature: 11.0, humidity: 75, locationX: 0.15, locationY: 0.2, isDraftRisk: false, date: Date(), notes: "Damp wall"))

        records.append(Record(id: UUID(), projectId: projId, roomId: room1Id, title: "Draft from balcony door", date: Date(), category: .draft, value: "Strong", comment: "Felt at 0.5m distance", photoData: nil, status: .open))
        records.append(Record(id: UUID(), projectId: projId, roomId: room2Id, title: "Wet spot on north wall", date: Date(), category: .humidity, value: "73%", comment: "Mold risk area", photoData: nil, status: .inProgress))

        tasks.append(AppTask(projectId: projId, title: "Buy draft excluder tape", description: "For balcony door bottom", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), isCompleted: false, priority: .high))
        tasks.append(AppTask(projectId: projId, title: "Call insulation contractor", description: "Get quote for north wall", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), isCompleted: false, priority: .medium))
        tasks.append(AppTask(projectId: projId, title: "Buy hygrometers x3", description: "", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), isCompleted: false, priority: .medium))

        calendarEvents.append(CalendarEvent(projectId: projId, title: "Contractor visit", date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(), type: .check, notes: "Estimate insulation cost"))

        generateRecommendations(for: projId)
        saveAll()
    }
}
