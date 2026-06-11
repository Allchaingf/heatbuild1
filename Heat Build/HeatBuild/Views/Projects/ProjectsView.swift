import SwiftUI

// MARK: - Projects List
struct ProjectsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var showArchived = false
    @State private var appeared = false

    var activeProjects: [Project] { store.projects.filter { $0.status != .archived } }
    var archivedProjects: [Project] { store.projects.filter { $0.status == .archived } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if activeProjects.isEmpty {
                        EmptyStateCard(icon: "folder.badge.plus", title: "No projects yet", subtitle: "Create your first insulation audit project") {
                            showAdd = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    } else {
                        ForEach(Array(activeProjects.enumerated()), id: \.element.id) { idx, project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectCard(project: project, isActive: project.id == store.selectedProjectId)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.06), value: appeared)
                        }
                    }

                    if !archivedProjects.isEmpty {
                        DisclosureGroup(isExpanded: $showArchived) {
                            ForEach(archivedProjects) { project in
                                ProjectCard(project: project, isActive: false)
                                    .padding(.horizontal, 16)
                                    .opacity(0.6)
                            }
                        } label: {
                            Text("Archived (\(archivedProjects.count))")
                                .font(AppFont.semibold(14))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentBlue)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddProjectView() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(project.name)
                            .font(AppFont.semibold(16))
                            .foregroundColor(.textPrimary)
                        if isActive {
                            Text("Active")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.accentBlue))
                        }
                    }
                    Text(project.objectType + " • " + project.address)
                        .font(AppFont.caption())
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                StatusBadge(text: project.status.rawValue, color: project.status.color)
            }

            HStack {
                Label(project.startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(AppFont.caption())
                    .foregroundColor(.textInactive)
                Spacer()
                Label("Updated " + project.updatedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "arrow.clockwise")
                    .font(AppFont.caption())
                    .foregroundColor(.textInactive)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardWhite)
                .overlay(
                    isActive ?
                    RoundedRectangle(cornerRadius: 16).stroke(Color.accentBlue.opacity(0.3), lineWidth: 1.5) : nil
                )
        )
        .cardShadow()
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppFont.caption())
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)))
    }
}

// MARK: - Project Detail
struct ProjectDetailView: View {
    @EnvironmentObject var store: AppStore
    let project: Project
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info Card
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Type", value: project.objectType)
                    Divider()
                    InfoRow(label: "Address", value: project.address)
                    Divider()
                    InfoRow(label: "Start Date", value: project.startDate.formatted(date: .long, time: .omitted))
                    if !project.notes.isEmpty {
                        Divider()
                        InfoRow(label: "Notes", value: project.notes)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
                .cardShadow()
                .padding(.horizontal, 16)

                // Rooms
                let rooms = store.rooms(for: project.id)
                if !rooms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Rooms (\(rooms.count))", action: nil)
                            .padding(.horizontal, 4)
                        ForEach(rooms) { room in
                            RoomRowCompact(room: room)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Actions
                VStack(spacing: 10) {
                    Button {
                        store.selectedProjectId = project.id
                    } label: {
                        Label("Set as Active Project", systemImage: "star.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(store.selectedProjectId == project.id)

                    Button {
                        store.archiveProject(project.id)
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Label("Archive Project", systemImage: "archivebox")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.statusError)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.statusError.opacity(0.1)))
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color.bgPrimary)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: {
                    Text("Edit").foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditProjectView(project: project) }
        .alert("Delete Project?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.deleteProject(project.id)
                dismiss.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all rooms, records and tasks associated with this project.")
        }
    }
}

struct RoomRowCompact: View {
    let room: Room
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(room.status.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "door.left.hand.open").foregroundColor(room.status.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name).font(AppFont.medium(14)).foregroundColor(.textPrimary)
                Text("Floor \(room.floor) • \(String(format: "%.1f", room.area)) m²")
                    .font(AppFont.caption()).foregroundColor(.textSecondary)
            }
            Spacer()
            StatusBadge(text: room.status.rawValue, color: room.status.color)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(AppFont.caption()).foregroundColor(.textInactive).frame(width: 80, alignment: .leading)
            Text(value).font(AppFont.medium(14)).foregroundColor(.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var objectType = "Apartment"
    @State private var address = ""
    @State private var startDate = Date()
    @State private var notes = ""
    @State private var showError = false

    let objectTypes = ["Apartment", "House", "Office", "Warehouse", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)
                    Picker("Object Type", selection: $objectType) {
                        ForEach(objectTypes, id: \.self) { Text($0) }
                    }
                    TextField("Address / Label", text: $address)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                if showError {
                    Section {
                        Text("Please enter a project name.").foregroundColor(.statusError)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(AppFont.semibold(15))
                        .foregroundColor(.accentBlue)
                }
            }
        }
    }

    func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; return
        }
        let proj = Project(name: name, objectType: objectType, address: address, startDate: startDate, notes: notes, status: .active)
        store.addProject(proj)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Project
struct EditProjectView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let project: Project
    @State private var name: String
    @State private var objectType: String
    @State private var address: String
    @State private var startDate: Date
    @State private var notes: String
    @State private var status: Project.ProjectStatus

    let objectTypes = ["Apartment", "House", "Office", "Warehouse", "Other"]

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _objectType = State(initialValue: project.objectType)
        _address = State(initialValue: project.address)
        _startDate = State(initialValue: project.startDate)
        _notes = State(initialValue: project.notes)
        _status = State(initialValue: project.status)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)
                    Picker("Object Type", selection: $objectType) {
                        ForEach(objectTypes, id: \.self) { Text($0) }
                    }
                    TextField("Address / Label", text: $address)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        ForEach(Project.ProjectStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var p = project
                        p.name = name; p.objectType = objectType; p.address = address
                        p.startDate = startDate; p.notes = notes; p.status = status
                        store.updateProject(p)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }
}
