import SwiftUI

struct HeatMapView: View {
    @EnvironmentObject var store: AppStore
    let room: Room
    @State private var showAddPoint = false
    @State private var selectedPoint: ClimatePoint? = nil
    @State private var mapBuilt = false
    @State private var appeared = false

    var points: [ClimatePoint] { store.climatePoints(for: room.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Legend
                HStack(spacing: 12) {
                    ForEach([
                        ("Cold Zone", Color.accentBlueSoft),
                        ("Humidity", Color.accentOrangeSoft),
                        ("Draft", Color.statusWarning),
                        ("Normal", Color.statusDone)
                    ], id: \.0) { label, color in
                        HStack(spacing: 4) {
                            Circle().fill(color).frame(width: 8, height: 8)
                            Text(label).font(AppFont.caption()).foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // Map Canvas
                ZStack {
                    // Background grid
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bgSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.divider1, lineWidth: 1)
                        )

                    // Heat overlay when built
                    if mapBuilt {
                        HeatMapOverlay(points: points)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .transition(.opacity)
                    }

                    // Room outline
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.divider2, lineWidth: 2)
                        .padding(24)

                    // Points
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        ForEach(points) { point in
                            ClimatePointPin(
                                point: point,
                                isSelected: selectedPoint?.id == point.id
                            )
                            .position(
                                x: w * point.locationX,
                                y: h * point.locationY
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedPoint = selectedPoint?.id == point.id ? nil : point
                                }
                            }
                        }
                    }

                    if points.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 36))
                                .foregroundColor(.textInactive)
                            Text("Add climate points to build map")
                                .font(AppFont.medium(14))
                                .foregroundColor(.textInactive)
                        }
                    }
                }
                .frame(height: 280)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.5), value: mapBuilt)

                // Selected Point Detail
                if let point = selectedPoint {
                    PointDetailCard(point: point) {
                        store.deleteClimatePoint(point.id)
                        selectedPoint = nil
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Actions
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            mapBuilt.toggle()
                        }
                    } label: {
                        Label(mapBuilt ? "Hide Map" : "Build Map", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(mapBuilt ? SecondaryButtonStyle() : PrimaryButtonStyle())

                    Button { showAddPoint = true } label: {
                        Label("Add Point", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OrangeButtonStyle())
                }
                .padding(.horizontal, 16)

                // Points list
                if !points.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Climate Points (\(points.count))", action: nil)
                            .padding(.horizontal, 16)

                        ForEach(points) { point in
                            ClimatePointRow(point: point)
                                .padding(.horizontal, 16)
                        }
                    }
                }

                // Summary stats
                if !points.isEmpty {
                    SummaryStatsView(points: points)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Heat Map — \(room.name)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPoint) { AddClimatePointView(roomId: room.id) }
    }
}

// MARK: - Heat Map Overlay
struct HeatMapOverlay: View {
    let points: [ClimatePoint]

    var body: some View {
        Canvas { context, size in
            for point in points {
                let center = CGPoint(x: size.width * point.locationX, y: size.height * point.locationY)
                let radius: CGFloat = 60
                let gradient = RadialGradient(
                    colors: [point.problemType.color.opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )),
                    with: .linearGradient(
                        Gradient(colors: [point.problemType.color.opacity(0.4), .clear]),
                        startPoint: center,
                        endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
                    )
                )
            }
        }
    }
}

// MARK: - Climate Point Pin
struct ClimatePointPin: View {
    let point: ClimatePoint
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(point.problemType.color.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: isSelected ? 48 : 36, height: isSelected ? 48 : 36)

            Circle()
                .fill(point.problemType.color)
                .frame(width: isSelected ? 24 : 18, height: isSelected ? 24 : 18)
                .overlay(
                    Text(String(format: "%.0f°", point.temperature))
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Point Detail Card
struct PointDetailCard: View {
    let point: ClimatePoint
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(point.title)
                    .font(AppFont.semibold(16))
                    .foregroundColor(.textPrimary)
                Spacer()
                StatusBadge(text: point.problemType.label, color: point.problemType.color)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Temperature")
                        .font(AppFont.caption())
                        .foregroundColor(.textInactive)
                    Text(String(format: "%.1f°C", point.temperature))
                        .font(AppFont.bold(18))
                        .foregroundColor(point.temperature < 15 ? .accentBlueSoft : .textPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Humidity")
                        .font(AppFont.caption())
                        .foregroundColor(.textInactive)
                    Text(String(format: "%.0f%%", point.humidity))
                        .font(AppFont.bold(18))
                        .foregroundColor(point.humidity > 70 ? .accentOrange : .textPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Draft Risk")
                        .font(AppFont.caption())
                        .foregroundColor(.textInactive)
                    Image(systemName: point.isDraftRisk ? "wind" : "checkmark.circle")
                        .font(.system(size: 18))
                        .foregroundColor(point.isDraftRisk ? .statusWarning : .statusDone)
                }
            }

            if !point.notes.isEmpty {
                Text(point.notes)
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
            }

            HStack {
                Text(point.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.caption())
                    .foregroundColor(.textInactive)
                Spacer()
                Button("Delete", action: onDelete)
                    .font(AppFont.semibold(13))
                    .foregroundColor(.statusError)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(point.problemType.color.opacity(0.3), lineWidth: 1.5))
        .cardShadow()
    }
}

// MARK: - Climate Point Row
struct ClimatePointRow: View {
    let point: ClimatePoint

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(point.problemType.color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(format: "%.0f°", point.temperature))
                        .font(AppFont.bold(13))
                        .foregroundColor(point.problemType.color)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(point.title)
                    .font(AppFont.medium(14))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 8) {
                    Text(String(format: "%.0f%% humidity", point.humidity))
                        .font(AppFont.caption())
                        .foregroundColor(.textSecondary)
                    if point.isDraftRisk {
                        Label("Draft", systemImage: "wind")
                            .font(AppFont.caption())
                            .foregroundColor(.statusWarning)
                    }
                }
            }
            Spacer()
            StatusBadge(text: point.problemType.label, color: point.problemType.color)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

// MARK: - Summary Stats
struct SummaryStatsView: View {
    let points: [ClimatePoint]

    var coldCount: Int { points.filter { $0.problemType == .cold }.count }
    var humidityCount: Int { points.filter { $0.problemType == .humidity }.count }
    var draftCount: Int { points.filter { $0.isDraftRisk }.count }
    var avgTemp: Double { points.isEmpty ? 0 : points.map(\.temperature).reduce(0,+) / Double(points.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(AppFont.semibold(15))
                .foregroundColor(.textPrimary)

            HStack(spacing: 10) {
                MiniStatCard(value: "\(coldCount)", label: "Cold", color: .accentBlueSoft)
                MiniStatCard(value: "\(humidityCount)", label: "Humid", color: .accentOrange)
                MiniStatCard(value: "\(draftCount)", label: "Draft", color: .statusWarning)
                MiniStatCard(value: String(format: "%.1f°", avgTemp), label: "Avg T", color: .textSecondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
        .cardShadow()
    }
}

struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.bold(18)).foregroundColor(color)
            Text(label).font(AppFont.caption()).foregroundColor(.textInactive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary))
    }
}

// MARK: - Add Climate Point
struct AddClimatePointView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let roomId: UUID

    @State private var title = ""
    @State private var temperature: Double = 18.0
    @State private var humidity: Double = 55.0
    @State private var locationX: Double = 0.5
    @State private var locationY: Double = 0.5
    @State private var isDraftRisk = false
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Point Info") {
                    TextField("Title (e.g. Window corner)", text: $title)
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .overlay(notes.isEmpty ? Text("Notes").foregroundColor(.textInactive).padding(.top, 8).padding(.leading, 4) : nil, alignment: .topLeading)
                }
                Section("Measurements") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f°C", temperature)).foregroundColor(.accentBlue)
                        }
                        Slider(value: $temperature, in: -20...40, step: 0.5).tint(.accentBlue)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Humidity")
                            Spacer()
                            Text(String(format: "%.0f%%", humidity)).foregroundColor(.accentOrange)
                        }
                        Slider(value: $humidity, in: 0...100, step: 1).tint(.accentOrange)
                    }
                    Toggle("Draft Risk", isOn: $isDraftRisk)
                }
                Section("Location on Map") {
                    VStack(spacing: 8) {
                        Text("Horizontal position: \(Int(locationX * 100))%")
                            .font(AppFont.caption()).foregroundColor(.textSecondary)
                        Slider(value: $locationX, in: 0.05...0.95).tint(.accentBlue)
                        Text("Vertical position: \(Int(locationY * 100))%")
                            .font(AppFont.caption()).foregroundColor(.textSecondary)
                        Slider(value: $locationY, in: 0.05...0.95).tint(.accentBlue)
                    }
                }
                if showError {
                    Section { Text("Please enter a title.").foregroundColor(.statusError) }
                }
            }
            .navigationTitle("Add Climate Point")
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
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        let point = ClimatePoint(roomId: roomId, title: title, temperature: temperature, humidity: humidity, locationX: locationX, locationY: locationY, isDraftRisk: isDraftRisk, date: Date(), notes: notes)
        store.addClimatePoint(point)
        dismiss.wrappedValue.dismiss()
    }
}
