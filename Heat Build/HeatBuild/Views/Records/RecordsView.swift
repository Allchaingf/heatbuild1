import SwiftUI

// MARK: - Add Record
struct AddRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let projectId: UUID
    var preselectedRoomId: UUID? = nil

    @State private var title = ""
    @State private var selectedRoomId: UUID? = nil
    @State private var date = Date()
    @State private var category: Record.RecordCategory = .temperature
    @State private var value = ""
    @State private var comment = ""
    @State private var status: Record.RecordStatus = .open
    @State private var showError = false
    @State private var showAnother = false
    @State private var addAnother = false

    var body: some View {
        NavigationView {
            Form {
                Section("Record Details") {
                    TextField("Title", text: $title)
                    Picker("Room", selection: $selectedRoomId) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.rooms(for: projectId)) { r in
                            Text(r.name).tag(UUID?.some(r.id))
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Category", selection: $category) {
                        ForEach(Record.RecordCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(Record.RecordStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Measurement") {
                    TextField("Value (e.g. 12.5°C, Strong)", text: $value)
                    TextEditor(text: $comment).frame(minHeight: 60)
                        .overlay(comment.isEmpty ? Text("Comment").foregroundColor(.textInactive).padding(.top, 8).padding(.leading, 4) : nil, alignment: .topLeading)
                }
                if showError {
                    Section { Text("Title and value are required.").foregroundColor(.statusError) }
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Save") { save(andAddAnother: false) }
                        Button("Save & Add Another") { save(andAddAnother: true) }
                    } label: {
                        Text("Save").font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                    }
                }
            }
            .onAppear { selectedRoomId = preselectedRoomId }
        }
    }

    func save(andAddAnother: Bool) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; return
        }
        let rec = Record(projectId: projectId, roomId: selectedRoomId, title: title, date: date, category: category, value: value, comment: comment, photoData: nil, status: status)
        store.addRecord(rec)
        if andAddAnother {
            title = ""; value = ""; comment = ""; showError = false
        } else {
            dismiss.wrappedValue.dismiss()
        }
    }
}

// MARK: - Record Detail
struct RecordDetailView: View {
    @EnvironmentObject var store: AppStore
    let record: Record
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var taskCreated = false
    @Environment(\.presentationMode) var dismiss

    var roomName: String {
        if let rid = record.roomId, let room = store.rooms.first(where: { $0.id == rid }) {
            return room.name
        }
        return "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status banner
                HStack {
                    Image(systemName: record.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(record.status.color)
                    Text(record.status.rawValue)
                        .font(AppFont.semibold(15))
                        .foregroundColor(record.status.color)
                    Spacer()
                    Text(record.category.rawValue)
                        .font(AppFont.medium(13))
                        .foregroundColor(.textSecondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(record.status.color.opacity(0.1)))
                .padding(.horizontal, 16)

                // Details
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Title", value: record.title)
                    Divider()
                    InfoRow(label: "Room", value: roomName)
                    Divider()
                    InfoRow(label: "Date", value: record.date.formatted(date: .long, time: .shortened))
                    Divider()
                    InfoRow(label: "Value", value: record.value)
                    if !record.comment.isEmpty {
                        Divider()
                        InfoRow(label: "Notes", value: record.comment)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
                .cardShadow()
                .padding(.horizontal, 16)

                if taskCreated {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                        Text("Task created!").font(AppFont.medium(14)).foregroundColor(.statusDone)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.statusDone.opacity(0.1)))
                    .padding(.horizontal, 16)
                }

                // Actions
                VStack(spacing: 10) {
                    Button { showEdit = true } label: {
                        Label("Edit Record", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        store.duplicateRecord(record)
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        let task = AppTask(projectId: record.projectId, title: "Fix: " + record.title, description: record.comment, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()), isCompleted: false, priority: .high)
                        store.addTask(task)
                        withAnimation { taskCreated = true }
                    } label: {
                        Label("Create Task", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OrangeButtonStyle())
                    .disabled(taskCreated)

                    Button { showDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
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
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditRecordView(record: record) }
        .alert("Delete Record?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.deleteRecord(record.id)
                dismiss.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Edit Record
struct EditRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let record: Record
    @State private var title: String
    @State private var date: Date
    @State private var category: Record.RecordCategory
    @State private var value: String
    @State private var comment: String
    @State private var status: Record.RecordStatus

    init(record: Record) {
        self.record = record
        _title = State(initialValue: record.title)
        _date = State(initialValue: record.date)
        _category = State(initialValue: record.category)
        _value = State(initialValue: record.value)
        _comment = State(initialValue: record.comment)
        _status = State(initialValue: record.status)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Category", selection: $category) {
                        ForEach(Record.RecordCategory.allCases, id: \.self) { Label($0.rawValue, systemImage: $0.icon) }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(Record.RecordStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    TextField("Value", text: $value)
                    TextEditor(text: $comment).frame(minHeight: 60)
                }
            }
            .navigationTitle("Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var r = record
                        r.title = title; r.date = date; r.category = category; r.value = value
                        r.comment = comment; r.status = status
                        store.updateRecord(r)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }
}
