import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("folder.fill", "Projects"),
        ("thermometer.medium", "Heat Map"),
        ("checklist", "Tasks"),
        ("chart.bar.fill", "Reports")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView().tag(0)
                ProjectsView().tag(1)
                HeatMapTabView().tag(2)
                TasksView().tag(3)
                ReportsView().tag(4)
            }
            .padding(.bottom, 72)

            CustomTabBar(selectedTab: $selectedTab, tabs: tabs)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentBlue.opacity(0.12))
                                    .frame(width: 44, height: 30)
                            }
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 20, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .accentBlue : .textInactive)
                        }

                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == i ? .accentBlue : .textInactive)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            Color.white
                .clipShape(RoundedTopCorners(radius: 20))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -2)
        )
    }
}

struct RoundedTopCorners: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(to: CGPoint(x: radius, y: 0), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: radius), control: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Wrapper for heat map tab (needs room selection)
struct HeatMapTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationView {
            RoomsView()
        }
    }
}
