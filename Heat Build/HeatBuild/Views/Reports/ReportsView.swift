import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showShare = false
    @State private var exportText = ""
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Overview stats
                    overviewSection
                        .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                    // Status by room
                    statusByRoomSection
                        .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                    // Issues by type
                    issuesByTypeSection
                        .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appeared)

                    // Task progress
                    taskProgressSection
                        .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)

                    // Export
                    VStack(spacing: 10) {
                        Button {
                            exportText = buildReport()
                            showShare = true
                        } label: {
                            Label("Export / Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
                }
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Reports")
            .sheet(isPresented: $showShare) {
                ShareSheet(text: exportText)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
            }
            .onDisappear { appeared = false }
        }
    }

    // MARK: - Overview
    var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Overview", action: nil)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                StatCard(value: "\(store.projects.count)", label: "Projects", icon: "folder.fill", color: .accentBlue)
                StatCard(value: "\(store.rooms.count)", label: "Rooms", icon: "door.left.hand.open", color: .accentOrange)
                StatCard(value: "\(store.climatePoints.count)", label: "Points", icon: "thermometer", color: .statusWarning)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Status by Room
    var statusByRoomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Status by Room", action: nil)
                .padding(.horizontal, 4)

            let rooms = store.rooms
            if rooms.isEmpty {
                Text("No rooms yet.").font(AppFont.body()).foregroundColor(.textInactive).padding(.horizontal, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(rooms.prefix(6)) { room in
                        HStack(spacing: 10) {
                            Text(room.name)
                                .font(AppFont.medium(14))
                                .foregroundColor(.textPrimary)
                                .frame(width: 100, alignment: .leading)

                            let pCount = store.climatePoints.filter { $0.roomId == room.id }.count
                            let rCount = store.records.filter { $0.roomId == room.id }.count
                            let total = max(1, pCount + rCount)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.bgDepth).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(room.status.color)
                                        .frame(width: geo.size.width * min(1.0, Double(total) / 5.0), height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
                                }
                            }
                            .frame(height: 8)

                            StatusBadge(text: room.status.rawValue, color: room.status.color)
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
                .cardShadow()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Issues by Type
    var issuesByTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Issues by Type", action: nil)
                .padding(.horizontal, 4)

            let categories = Record.RecordCategory.allCases
            let total = max(1, store.records.count)

            VStack(spacing: 10) {
                ForEach(categories, id: \.rawValue) { cat in
                    let count = store.records.filter { $0.category == cat }.count
                    if count > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.accentBlue)
                                .frame(width: 24)

                            Text(cat.rawValue)
                                .font(AppFont.medium(13))
                                .foregroundColor(.textPrimary)
                                .frame(width: 90, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.bgDepth).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(colors: [.accentBlue, .accentBlueSoft], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * Double(count) / Double(total), height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)
                                }
                            }
                            .frame(height: 8)

                            Text("\(count)")
                                .font(AppFont.semibold(13))
                                .foregroundColor(.accentBlue)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
            .cardShadow()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Task Progress
    var taskProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Task Progress", action: nil)
                .padding(.horizontal, 4)

            let total = store.tasks.count
            let done = store.tasks.filter { $0.isCompleted }.count
            let overdue = store.overdueTasks.count

            VStack(spacing: 12) {
                HStack {
                    Text("Total Tasks")
                        .font(AppFont.medium(14)).foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(total)").font(AppFont.bold(16)).foregroundColor(.textPrimary)
                }

                if total > 0 {
                    ProgressBar(value: Double(done) / Double(total), color: .statusDone, label: "Completed: \(done)")
                    ProgressBar(value: Double(overdue) / Double(max(1, total)), color: .statusError, label: "Overdue: \(overdue)")
                }

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.statusDone).frame(width: 8, height: 8)
                        Text("Done: \(done)").font(AppFont.caption()).foregroundColor(.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.statusError).frame(width: 8, height: 8)
                        Text("Overdue: \(overdue)").font(AppFont.caption()).foregroundColor(.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.accentBlue).frame(width: 8, height: 8)
                        Text("Open: \(total - done)").font(AppFont.caption()).foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardWhite))
            .cardShadow()
        }
        .padding(.horizontal, 16)
    }

    func buildReport() -> String {
        var lines = ["Heat Build Report — \(Date().formatted())", ""]
        lines.append("Projects: \(store.projects.count)")
        lines.append("Rooms: \(store.rooms.count)")
        lines.append("Climate Points: \(store.climatePoints.count)")
        lines.append("Open Issues: \(store.totalProblems)")
        lines.append("Overdue Tasks: \(store.overdueTasks.count)")
        lines.append("Progress: \(Int(store.progressPercent * 100))%")
        lines.append("")
        lines.append("=== ROOMS ===")
        for r in store.rooms { lines.append("• \(r.name) [\(r.status.rawValue)] — \(r.area)m²") }
        lines.append("")
        lines.append("=== RECORDS ===")
        for rec in store.records { lines.append("• \(rec.title) [\(rec.status.rawValue)] — \(rec.value)") }
        return lines.joined(separator: "\n")
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(AppFont.caption()).foregroundColor(.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.bgDepth).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: value)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
