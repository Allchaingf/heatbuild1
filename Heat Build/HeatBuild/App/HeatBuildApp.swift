import SwiftUI

@main
struct HeatBuildApp: App {
    @StateObject private var appStore = AppStore()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appStore)
                .environmentObject(settingsStore)
                .preferredColorScheme(settingsStore.colorScheme)
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if !splashDone {
                LaunchView {
                    withAnimation {
                        splashDone = true
                    }
                }
                .zIndex(2)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashDone)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
