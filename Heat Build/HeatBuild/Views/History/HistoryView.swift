import SwiftUI

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case created = "Created"
        case updated = "Updated"
        case completed = "Completed"
    }

    var historyItems: [(date: Date, title: String, subtitle: String, icon: String, color: Color)] {
        var items: [(date: Date, title: String, subtitle: String, icon: String, color: Color)] = []

        switch filter {
        case .all, .created:
            for r in store.records { items.append((r.createdAt, r.title, "Record created — " + r.category.rawValue, r.category.icon, r.status.color)) }
            for t in store.tasks { items.append((t.createdAt, t.title, "Task created — " + t.priority.rawValue, "checkmark.circle", t.priority.color)) }
        case .updated:
            for p in store.projects { items.append((p.updatedAt, p.name, "Project updated", "folder", p.status.color)) }
        case .completed:
            for t in store.tasks.filter({ $0.isCompleted }) {
                if let d = t.completedAt { items.append((d, t.title, "Task completed", "checkmark.circle.fill", Color.statusDone)) }
            }
        }

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HistoryFilter.allCases, id: \.rawValue) { f in
                        FilterChip(label: f.rawValue, isSelected: filter == f) {
                            withAnimation { filter = f }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.bgPrimary)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<historyItems.count, id: \.self) { idx in
                        let item = historyItems[idx]
                        HStack(spacing: 14) {
                            VStack {
                                Circle()
                                    .fill(item.color.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(Image(systemName: item.icon).font(.system(size: 14)).foregroundColor(item.color))
                                if idx < historyItems.count - 1 {
                                    Rectangle().fill(Color.divider1).frame(width: 1).frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 36)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(AppFont.medium(14)).foregroundColor(.textPrimary).lineLimit(1)
                                Text(item.subtitle).font(AppFont.caption()).foregroundColor(.textSecondary)
                                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppFont.caption()).foregroundColor(.textInactive)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    if historyItems.isEmpty {
                        Text("No history yet.").font(AppFont.body()).foregroundColor(.textInactive).padding(32)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color.bgPrimary)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Photos View
struct PhotosView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedCategory: AppPhoto.PhotoCategory? = nil
    @State private var showAdd = false

    var photos: [AppPhoto] {
        if let cat = selectedCategory { return store.photos.filter { $0.category == cat } }
        return store.photos
    }

    let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: selectedCategory == nil) {
                        withAnimation { selectedCategory = nil }
                    }
                    ForEach(AppPhoto.PhotoCategory.allCases, id: \.rawValue) { cat in
                        FilterChip(label: cat.rawValue, isSelected: selectedCategory == cat, color: cat.color) {
                            withAnimation { selectedCategory = selectedCategory == cat ? nil : cat }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            if photos.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 44)).foregroundColor(.textInactive)
                    Text("No photos yet").font(AppFont.medium(15)).foregroundColor(.textSecondary)
                    Button("Add Photo") { showAdd = true }
                        .buttonStyle(SmallPrimaryButtonStyle())
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 2) {
                        ForEach(photos) { photo in
                            if let uiImg = UIImage(data: photo.imageData) {
                                ZStack(alignment: .bottomLeading) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()

                                    Text(photo.category.rawValue)
                                        .font(AppFont.caption())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(Capsule().fill(photo.category.color.opacity(0.85)))
                                        .padding(4)
                                }
                                .frame(height: 120)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddPhotoView() }
    }
}

struct AddPhotoView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    @State private var category: AppPhoto.PhotoCategory = .problem
    @State private var caption = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        NavigationView {
            Form {
                Section("Photo") {
                    Button("Select Photo") { showImagePicker = true }
                        .foregroundColor(.accentBlue)
                    if let img = selectedImage {
                        Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 200).cornerRadius(8)
                    }
                }
                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(AppPhoto.PhotoCategory.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    TextField("Caption", text: $caption)
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let pid = store.selectedProjectId, let img = selectedImage, let data = img.jpegData(compressionQuality: 0.7) else { return }
                        let photo = AppPhoto(projectId: pid, category: category, imageData: data, caption: caption)
                        store.addPhoto(photo)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Notifications List
struct NotificationsListView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: AppStore
    @State private var saved = false

    var body: some View {
        Form {
            Section("Notification Types") {
                Toggle("Deadline reminders", isOn: $settings.notifyDeadlines)
                Toggle("Climate warnings", isOn: $settings.notifyWarnings)
                Toggle("Weekly check-in (Mon 10:00)", isOn: $settings.notifyWeeklyCheck)
                    .onChange(of: settings.notifyWeeklyCheck) { _ in settings.scheduleWeeklyCheck() }
            }

            Section("Upcoming Deadlines") {
                let upcoming = store.tasks.filter { t in
                    guard let due = t.dueDate, !t.isCompleted else { return false }
                    return due > Date()
                }.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }

                if upcoming.isEmpty {
                    Text("No upcoming deadlines").foregroundColor(.textInactive)
                } else {
                    ForEach(upcoming.prefix(5)) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(AppFont.medium(14))
                                if let due = task.dueDate {
                                    Text(due.formatted(date: .abbreviated, time: .omitted))
                                        .font(AppFont.caption()).foregroundColor(.textInactive)
                                }
                            }
                            Spacer()
                            StatusBadge(text: task.priority.rawValue, color: task.priority.color)
                        }
                    }
                }
            }

            Section {
                Button("Save Notification Settings") {
                    settings.scheduleWeeklyCheck()
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { saved = false } }
                }
                .foregroundColor(.accentBlue)

                if saved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                        Text("Saved").foregroundColor(.statusDone)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
