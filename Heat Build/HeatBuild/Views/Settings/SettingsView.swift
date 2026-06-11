import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    @State private var showExport = false
    @State private var exportText = ""
    @State private var notifPermissionAlert = false
    @State private var saved = false

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $settings.themeMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.themeMode) { _ in
                        // @AppStorage persists automatically; color scheme applied via .preferredColorScheme in App struct
                    }
                }

                // MARK: - Units
                Section("Units & Currency") {
                    Picker("Units", selection: $settings.units) {
                        Text("Metric (°C, m²)").tag("metric")
                        Text("Imperial (°F, ft²)").tag("imperial")
                    }
                    Picker("Currency", selection: $settings.currency) {
                        Text("EUR €").tag("EUR")
                        Text("USD $").tag("USD")
                        Text("GBP £").tag("GBP")
                        Text("RUB ₽").tag("RUB")
                    }
                }

                // MARK: - Notifications
                Section("Notifications") {
                    Toggle("Deadline reminders", isOn: $settings.notifyDeadlines)
                        .onChange(of: settings.notifyDeadlines) { val in
                            if val { requestNotifPermission() }
                        }
                    Toggle("Climate warnings", isOn: $settings.notifyWarnings)
                        .onChange(of: settings.notifyWarnings) { val in
                            if val { requestNotifPermission() }
                        }
                    Toggle("Weekly check-in", isOn: $settings.notifyWeeklyCheck)
                        .onChange(of: settings.notifyWeeklyCheck) { val in
                            if val {
                                requestNotifPermission()
                                settings.scheduleWeeklyCheck()
                            } else {
                                settings.scheduleWeeklyCheck() // will cancel since toggle is off
                            }
                        }

                    Button("Save Notifications") {
                        settings.scheduleWeeklyCheck()
                        withAnimation { saved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { saved = false }
                        }
                    }
                    .foregroundColor(.accentBlue)

                    if saved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                            Text("Notification settings saved").foregroundColor(.statusDone)
                        }
                    }
                }

                // MARK: - Data
                Section("Data") {
                    Button("Export Data") {
                        exportText = settings.exportData(from: store)
                        showExport = true
                    }
                    .foregroundColor(.accentBlue)

                    NavigationLink(destination: HistoryView()) {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                    }

                    NavigationLink(destination: PhotosView()) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                    }

                    NavigationLink(destination: NotificationsListView()) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: RecommendationsView()) {
                        Label("Recommendations", systemImage: "lightbulb")
                    }
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.textInactive)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1").foregroundColor(.textInactive)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }
                        .font(AppFont.semibold(15))
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showExport) {
            ShareSheet(text: exportText)
        }
        .alert("Enable Notifications", isPresented: $notifPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notification permission was denied. Please enable it in Settings.")
        }
    }

    func requestNotifPermission() {
        settings.requestNotificationPermission { granted in
            if !granted { notifPermissionAlert = true }
        }
    }
}
