import SwiftUI

struct RoomsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var filterStatus: Room.RoomStatus? = nil
    @State private var appeared = false

    var filteredRooms: [Room] {
        guard let pid = store.selectedProjectId else { return [] }
        let all = store.rooms(for: pid)
        if let f = filterStatus { return all.filter { $0.status == f } }
        return all
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: filterStatus == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { filterStatus = nil }
                        }
                        ForEach(Room.RoomStatus.allCases, id: \.rawValue) { s in
                            FilterChip(label: s.rawValue, isSelected: filterStatus == s, color: s.color) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if filteredRooms.isEmpty {
                    EmptyStateCard(icon: "door.left.hand.open", title: "No rooms yet", subtitle: "Add rooms to start mapping climate problems") {
                        showAdd = true
                    }
                    .padding(.horizontal, 16)
                } else {
                    ForEach(Array(filteredRooms.enumerated()), id: \.element.id) { idx, room in
                        NavigationLink(destination: RoomDetailView(room: room)) {
                            RoomCard(room: room, recordCount: store.records.filter { $0.roomId == room.id }.count, pointCount: store.climatePoints.filter { $0.roomId == room.id }.count)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.06), value: appeared)
                    }
                }
            }
            .padding(.vertical, 14)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Rooms")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddRoomView() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

struct RoomCard: View {
    let room: Room
    let recordCount: Int
    let pointCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name)
                        .font(AppFont.semibold(16))
                        .foregroundColor(.textPrimary)
                    Text("Floor \(room.floor) • \(String(format: "%.1f", room.area)) m²")
                        .font(AppFont.caption())
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                StatusBadge(text: room.status.rawValue, color: room.status.color)
            }

            Divider()

            HStack(spacing: 16) {
                Label("\(pointCount) points", systemImage: "thermometer")
                    .font(AppFont.caption())
                    .foregroundColor(.textInactive)
                Label("\(recordCount) records", systemImage: "doc.text")
                    .font(AppFont.caption())
                    .foregroundColor(.textInactive)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textInactive)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
        .cardShadow()
    }
}

// MARK: - Room Detail
struct RoomDetailView: View {
    @EnvironmentObject var store: AppStore
    let room: Room
    @State private var showEdit = false
    @State private var showAddRecord = false
    @State private var showHeatMap = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var dismiss

    var points: [ClimatePoint] { store.climatePoints(for: room.id) }
    var records: [Record] { store.records.filter { $0.roomId == room.id } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Room info
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Floor", value: room.floor)
                    Divider()
                    InfoRow(label: "Area", value: "\(String(format: "%.1f", room.area)) m²")
                    Divider()
                    InfoRow(label: "Status", value: room.status.rawValue)
                    if !room.notes.isEmpty {
                        Divider()
                        InfoRow(label: "Notes", value: room.notes)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
                .cardShadow()
                .padding(.horizontal, 16)

                // Climate stats
                if !points.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Climate Points (\(points.count))", action: nil)
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            let avgTemp = points.map(\.temperature).reduce(0, +) / Double(points.count)
                            let avgHum = points.map(\.humidity).reduce(0, +) / Double(points.count)
                            StatCard(value: String(format: "%.1f°", avgTemp), label: "Avg Temp", icon: "thermometer", color: avgTemp < 15 ? .accentBlueSoft : .statusDone)
                            StatCard(value: String(format: "%.0f%%", avgHum), label: "Avg Humidity", icon: "humidity", color: avgHum > 70 ? .accentOrange : .statusDone)
                        }

                        NavigationLink(destination: HeatMapView(room: room)) {
                            Label("View Heat Map", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 16)
                }

                // Records
                if !records.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Records (\(records.count))", action: nil)
                            .padding(.horizontal, 4)
                        ForEach(records.prefix(5)) { rec in
                            NavigationLink(destination: RecordDetailView(record: rec)) {
                                RecordRowCompact(record: rec)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Actions
                VStack(spacing: 10) {
                    NavigationLink(destination: HeatMapView(room: room)) {
                        Label("Open Heat Map", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button { showAddRecord = true } label: {
                        Label("Add Record", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button { showDeleteAlert = true } label: {
                        Label("Delete Room", systemImage: "trash")
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
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: { Text("Edit").foregroundColor(.accentBlue) }
            }
        }
        .sheet(isPresented: $showEdit) { EditRoomView(room: room) }
        .sheet(isPresented: $showAddRecord) {
            if let pid = store.selectedProjectId {
                AddRecordView(projectId: pid, preselectedRoomId: room.id)
            }
        }
        .alert("Delete Room?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.deleteRoom(room.id)
                dismiss.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct RecordRowCompact: View {
    let record: Record
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(record.status.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: record.category.icon).font(.system(size: 14)).foregroundColor(record.status.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title).font(AppFont.medium(14)).foregroundColor(.textPrimary).lineLimit(1)
                Text(record.category.rawValue + " • " + record.value)
                    .font(AppFont.caption()).foregroundColor(.textSecondary)
            }
            Spacer()
            StatusBadge(text: record.status.rawValue, color: record.status.color)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var floor = "1"
    @State private var area: Double = 20.0
    @State private var notes = ""
    @State private var status: Room.RoomStatus = .ok
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $name)
                    TextField("Floor", text: $floor)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Area")
                            Spacer()
                            Text(String(format: "%.1f m²", area))
                                .foregroundColor(.accentBlue)
                        }
                        Slider(value: $area, in: 1...200, step: 0.5).tint(.accentBlue)
                    }
                    Picker("Status", selection: $status) {
                        ForEach(Room.RoomStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
                if showError {
                    Section { Text("Please enter a room name.").foregroundColor(.statusError) }
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }.font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }

    func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        guard let pid = store.selectedProjectId else { return }
        let room = Room(projectId: pid, name: name, floor: floor, area: area, notes: notes, coverPhotoData: nil, status: status)
        store.addRoom(room)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Room
struct EditRoomView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let room: Room
    @State private var name: String
    @State private var floor: String
    @State private var area: Double
    @State private var notes: String
    @State private var status: Room.RoomStatus

    init(room: Room) {
        self.room = room
        _name = State(initialValue: room.name)
        _floor = State(initialValue: room.floor)
        _area = State(initialValue: room.area)
        _notes = State(initialValue: room.notes)
        _status = State(initialValue: room.status)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $name)
                    TextField("Floor", text: $floor)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Area")
                            Spacer()
                            Text(String(format: "%.1f m²", area)).foregroundColor(.accentBlue)
                        }
                        Slider(value: $area, in: 1...200, step: 0.5).tint(.accentBlue)
                    }
                    Picker("Status", selection: $status) {
                        ForEach(Room.RoomStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Notes") { TextEditor(text: $notes).frame(minHeight: 60) }
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var r = room
                        r.name = name; r.floor = floor; r.area = area; r.notes = notes; r.status = status
                        store.updateRoom(r)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .accentBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.semibold(13))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? color : Color.cardWhite)
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.divider1, lineWidth: 1))
                .cardShadow()
        }
        .buttonStyle(.plain)
    }
}
