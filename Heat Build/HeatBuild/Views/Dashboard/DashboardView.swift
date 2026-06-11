import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAddProject = false
    @State private var showQuickCheck = false
    @State private var showReport = false
    @State private var showSettings = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Active Project Card
                    activeProjectSection
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                    // Stats row
                    statsRow
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                    // Warnings
                    if store.warningCount > 0 {
                        warningsSection
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)
                    }

                    // Today Actions
                    todayActionsSection
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)

                    // Progress
                    progressSection
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)

                    // Quick Actions
                    quickActionsRow
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Heat Build")
                            .font(AppFont.bold(20))
                            .foregroundColor(.textPrimary)
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(AppFont.caption())
                            .foregroundColor(.textInactive)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddProject) { AddProjectView() }
        .sheet(isPresented: $showQuickCheck) { QuickCheckView() }
        .sheet(isPresented: $showReport) { ReportsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }

    // MARK: - Active Project
    var activeProjectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Active Project", action: nil)

            if let project = store.selectedProject {
                NavigationLink(destination: ProjectDetailView(project: project)) {
                    ProjectCard(project: project, isActive: true)
                }
                .buttonStyle(.plain)
            } else {
                EmptyStateCard(icon: "folder.badge.plus", title: "No active project", subtitle: "Add your first project to get started") {
                    showAddProject = true
                }
            }
        }
    }

    // MARK: - Stats Row
    var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(store.totalProblems)",
                label: "Open Issues",
                icon: "exclamationmark.triangle.fill",
                color: .statusError
            )
            StatCard(
                value: "\(store.warningCount)",
                label: "Climate Alerts",
                icon: "thermometer.medium",
                color: .accentOrange
            )
            StatCard(
                value: "\(store.overdueTasks.count)",
                label: "Overdue",
                icon: "clock.fill",
                color: store.overdueTasks.isEmpty ? .statusDone : .statusError
            )
        }
    }

    // MARK: - Warnings
    var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Warnings", action: nil)

            let problems = store.climatePoints.filter { $0.problemType != .normal }.prefix(3)
            ForEach(Array(problems)) { point in
                WarningRow(point: point)
            }
        }
    }

    // MARK: - Today Actions
    var todayActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today Actions", action: nil)

            if store.todayTasks.isEmpty && store.overdueTasks.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusDone)
                    Text("All clear for today!")
                        .font(AppFont.medium(14))
                        .foregroundColor(.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
                .cardShadow()
            } else {
                let tasks = (store.overdueTasks + store.todayTasks).prefix(3)
                ForEach(Array(tasks)) { task in
                    DashboardTaskRow(task: task)
                }
            }
        }
    }

    // MARK: - Progress
    var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Progress", action: nil)

            VStack(spacing: 10) {
                HStack {
                    Text("Overall completion")
                        .font(AppFont.medium(14))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(Int(store.progressPercent * 100))%")
                        .font(AppFont.semibold(15))
                        .foregroundColor(.accentBlue)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.bgDepth)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.accentBlue, .statusDone], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * store.progressPercent, height: 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.progressPercent)
                    }
                }
                .frame(height: 10)

                HStack {
                    Label("\(store.records.filter { $0.status == .resolved }.count) resolved", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.statusDone)
                    Spacer()
                    Label("\(store.records.filter { $0.status == .open }.count) open", systemImage: "circle")
                        .foregroundColor(.statusError)
                }
                .font(AppFont.caption())
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
            .cardShadow()
        }
    }

    // MARK: - Quick Actions
    var quickActionsRow: some View {
        HStack(spacing: 12) {
            Button { showAddProject = true } label: {
                Label("Add Project", systemImage: "plus.circle.fill")
                    .font(AppFont.semibold(14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentBlue))
                    .blueShadow()
            }

            Button { showQuickCheck = true } label: {
                Label("Quick Check", systemImage: "bolt.fill")
                    .font(AppFont.semibold(14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentOrange))
                    .orangeShadow()
            }
        }
    }
}

// MARK: - Helper Components
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.semibold(16))
                .foregroundColor(.textPrimary)
            Spacer()
            if let action = action {
                Button("See all", action: action)
                    .font(AppFont.medium(13))
                    .foregroundColor(.accentBlue)
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(AppFont.bold(22))
                .foregroundColor(.textPrimary)

            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
        .cardShadow()
    }
}

struct WarningRow: View {
    let point: ClimatePoint

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(point.problemType.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(point.problemType.color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(point.title)
                    .font(AppFont.medium(14))
                    .foregroundColor(.textPrimary)
                Text("\(point.problemType.label) — \(String(format: "%.0f°", point.temperature)), \(String(format: "%.0f%%", point.humidity))")
                    .font(AppFont.caption())
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(point.problemType.label)
                .font(AppFont.caption())
                .foregroundColor(point.problemType.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(point.problemType.color.opacity(0.12)))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

struct DashboardTaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: AppTask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTask(task.id)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(task.isCompleted ? Color.statusDone : Color.white)
                        .frame(width: 26, height: 26)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(task.isCompleted ? Color.statusDone : Color.divider2, lineWidth: 1.5))
                    if task.isCompleted {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(AppFont.medium(14))
                    .foregroundColor(.textPrimary)
                    .strikethrough(task.isCompleted)

                if let due = task.dueDate {
                    Text(due.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFont.caption())
                        .foregroundColor(task.isOverdue ? .statusError : .textInactive)
                }
            }

            Spacer()

            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.textInactive)
            Text(title)
                .font(AppFont.semibold(15))
                .foregroundColor(.textSecondary)
            Text(subtitle)
                .font(AppFont.caption())
                .foregroundColor(.textInactive)
                .multilineTextAlignment(.center)
            Button("Add Now", action: action)
                .buttonStyle(SmallPrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
        .cardShadow()
    }
}

// MARK: - Quick Check Sheet
struct QuickCheckView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    @State private var temp: Double = 18.0
    @State private var humidity: Double = 55.0
    @State private var isDraft = false
    @State private var selectedRoomId: UUID? = nil
    @State private var saved = false

    var body: some View {
        NavigationView {
            Form {
                Section("Room") {
                    if let pid = store.selectedProjectId {
                        Picker("Select Room", selection: $selectedRoomId) {
                            Text("None").tag(UUID?.none)
                            ForEach(store.rooms(for: pid)) { r in
                                Text(r.name).tag(UUID?.some(r.id))
                            }
                        }
                    }
                }
                Section("Climate") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f°C", temp))
                                .foregroundColor(.accentBlue)
                        }
                        Slider(value: $temp, in: -10...40, step: 0.5)
                            .tint(.accentBlue)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Humidity")
                            Spacer()
                            Text(String(format: "%.0f%%", humidity))
                                .foregroundColor(.accentOrange)
                        }
                        Slider(value: $humidity, in: 0...100, step: 1)
                            .tint(.accentOrange)
                    }
                    Toggle("Draft Risk", isOn: $isDraft)
                }

                if saved {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                            Text("Point saved!")
                        }
                    }
                }
            }
            .navigationTitle("Quick Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { savePoint() }
                        .font(AppFont.semibold(15))
                        .foregroundColor(.accentBlue)
                }
            }
        }
    }

    func savePoint() {
        guard let rid = selectedRoomId else { return }
        let point = ClimatePoint(
            roomId: rid,
            title: "Quick Check \(Date().formatted(date: .abbreviated, time: .shortened))",
            temperature: temp,
            humidity: humidity,
            locationX: 0.5,
            locationY: 0.5,
            isDraftRisk: isDraft,
            date: Date(),
            notes: ""
        )
        store.addClimatePoint(point)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss.wrappedValue.dismiss()
        }
    }
}
