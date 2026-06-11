import SwiftUI

struct TasksView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAdd = false
    @State private var filter: TaskFilter = .all
    @State private var appeared = false

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case overdue = "Overdue"
        case done = "Done"
    }

    var filteredTasks: [AppTask] {
        switch filter {
        case .all: return store.tasks.filter { !$0.isCompleted }
        case .today: return store.tasks.filter { $0.isDueToday && !$0.isCompleted }
        case .overdue: return store.tasks.filter { $0.isOverdue }
        case .done: return store.tasks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { f in
                            FilterChip(
                                label: badgeLabel(f),
                                isSelected: filter == f
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    filter = f
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.bgPrimary)

                ScrollView {
                    VStack(spacing: 10) {
                        if filteredTasks.isEmpty {
                            EmptyStateCard(
                                icon: "checklist",
                                title: emptyTitle,
                                subtitle: emptySubtitle
                            ) { showAdd = true }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        } else {
                            ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { idx, task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    TaskCard(task: task)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.05), value: appeared)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 24)
                }
                .background(Color.bgPrimary)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Tasks")
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
        .sheet(isPresented: $showAdd) { AddTaskView() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
        .onDisappear { appeared = false }
    }

    func badgeLabel(_ f: TaskFilter) -> String {
        switch f {
        case .all: return "All (\(store.tasks.filter { !$0.isCompleted }.count))"
        case .today: return "Today (\(store.todayTasks.count))"
        case .overdue: return "Overdue (\(store.overdueTasks.count))"
        case .done: return "Done (\(store.tasks.filter { $0.isCompleted }.count))"
        }
    }

    var emptyTitle: String {
        switch filter {
        case .all: return "No tasks yet"
        case .today: return "Nothing due today"
        case .overdue: return "No overdue tasks"
        case .done: return "No completed tasks"
        }
    }

    var emptySubtitle: String {
        switch filter {
        case .all: return "Add tasks to track your repair work"
        case .today: return "You're all caught up for today"
        case .overdue: return "Great — everything is on schedule"
        case .done: return "Complete tasks will appear here"
        }
    }
}

// MARK: - Task Card
struct TaskCard: View {
    @EnvironmentObject var store: AppStore
    let task: AppTask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    store.toggleTask(task.id)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(task.isCompleted ? Color.statusDone : Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(task.isCompleted ? Color.statusDone : Color.divider2, lineWidth: 1.5))
                    if task.isCompleted {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(AppFont.medium(15))
                    .foregroundColor(.textPrimary)
                    .strikethrough(task.isCompleted, color: .textInactive)
                    .lineLimit(2)

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(AppFont.caption())
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                if let due = task.dueDate {
                    Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(AppFont.caption())
                        .foregroundColor(task.isOverdue && !task.isCompleted ? .statusError : .textInactive)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
                Text(task.priority.rawValue)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(task.priority.color)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardWhite)
                .overlay(
                    task.isOverdue && !task.isCompleted ?
                    RoundedRectangle(cornerRadius: 14).stroke(Color.statusError.opacity(0.3), lineWidth: 1) : nil
                )
        )
        .cardShadow()
    }
}

// MARK: - Task Detail
struct TaskDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: SettingsStore
    let task: AppTask
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status
                HStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? .statusDone : .textInactive)
                    Text(task.isCompleted ? "Completed" : (task.isOverdue ? "Overdue" : "Open"))
                        .font(AppFont.semibold(16))
                        .foregroundColor(task.isCompleted ? .statusDone : (task.isOverdue ? .statusError : .textSecondary))
                    Spacer()
                    StatusBadge(text: task.priority.rawValue, color: task.priority.color)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.bgSecondary))
                .padding(.horizontal, 16)

                // Info
                VStack(alignment: .leading, spacing: 10) {
                    if !task.description.isEmpty {
                        InfoRow(label: "Notes", value: task.description)
                        Divider()
                    }
                    if let due = task.dueDate {
                        InfoRow(label: "Due", value: due.formatted(date: .long, time: .omitted))
                        Divider()
                    }
                    InfoRow(label: "Created", value: task.createdAt.formatted(date: .long, time: .omitted))
                    if let done = task.completedAt {
                        Divider()
                        InfoRow(label: "Completed", value: done.formatted(date: .long, time: .shortened))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
                .cardShadow()
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            store.toggleTask(task.id)
                        }
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Label(task.isCompleted ? "Mark as Open" : "Mark as Done", systemImage: task.isCompleted ? "circle" : "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(task.isCompleted ? SecondaryButtonStyle() : PrimaryButtonStyle())

                    Button { showEdit = true } label: {
                        Label("Edit Task", systemImage: "pencil").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button { showDeleteAlert = true } label: {
                        Label("Delete Task", systemImage: "trash").frame(maxWidth: .infinity)
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
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditTaskView(task: task) }
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.deleteTask(task.id)
                dismiss.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.presentationMode) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: AppTask.Priority = .medium
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description).frame(minHeight: 60)
                        .overlay(description.isEmpty ? Text("Description").foregroundColor(.textInactive).padding(.top, 8).padding(.leading, 4) : nil, alignment: .topLeading)
                    Picker("Priority", selection: $priority) {
                        ForEach(AppTask.Priority.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                if showError {
                    Section { Text("Please enter a task title.").foregroundColor(.statusError) }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }.font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }

    func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        let task = AppTask(projectId: store.selectedProjectId, title: title, description: description, dueDate: hasDueDate ? dueDate : nil, isCompleted: false, priority: priority)
        store.addTask(task)
        if hasDueDate { settings.scheduleDeadlineNotification(title: title, date: dueDate) }
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Task
struct EditTaskView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.presentationMode) var dismiss
    let task: AppTask
    @State private var title: String
    @State private var description: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var priority: AppTask.Priority

    init(task: AppTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _priority = State(initialValue: task.priority)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $description).frame(minHeight: 60)
                    Picker("Priority", selection: $priority) {
                        ForEach(AppTask.Priority.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate { DatePicker("Due Date", selection: $dueDate, displayedComponents: .date) }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var t = task
                        t.title = title; t.description = description
                        t.dueDate = hasDueDate ? dueDate : nil; t.priority = priority
                        store.updateTask(t)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }
}
