import SwiftUI

// MARK: - OnboardingView container
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingPage1().tag(0)
                OnboardingPage2().tag(1)
                OnboardingPage3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

            VStack(spacing: 20) {
                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.accentBlue : Color.divider2)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }

                HStack(spacing: 12) {
                    if currentPage < 2 {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Next") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Get Started") {
                            hasCompletedOnboarding = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.bgPrimary)
    }
}

// MARK: - Page 1: Understand the problem (tap-to-burst)
struct OnboardingPage1: View {
    @State private var isVisible = true
    @State private var tapped = false
    @State private var burst = false
    @State private var particles: [ParticleData] = []

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Cold gradient bg
                RadialGradient(
                    colors: [Color(hex: "#DBEAFE"), Color(hex: "#EEF2F7")],
                    center: .center,
                    startRadius: 60,
                    endRadius: 200
                )

                // Burst particles
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .offset(x: burst ? p.endX : 0, y: burst ? p.endY : 0)
                        .opacity(burst ? 0 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(p.delay), value: burst)
                }

                // House icon with cold indicator
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .cardShadow()

                    VStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 44))
                            .foregroundColor(tapped ? Color.accentOrange : Color.accentBlue)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: tapped)

                        Image(systemName: "wind")
                            .font(.system(size: 18))
                            .foregroundColor(Color.accentBlueSoft)
                            .opacity(tapped ? 0 : 1)
                            .animation(.easeOut(duration: 0.3), value: tapped)
                    }
                }
                .scaleEffect(tapped ? 1.15 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: tapped)
                .onTapGesture { triggerBurst() }

                VStack {
                    Spacer()
                    Text("Tap to see the problem")
                        .font(AppFont.caption())
                        .foregroundColor(.textInactive)
                        .padding(.bottom, 12)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.52)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text("Understand\nthe problem")
                    .font(AppFont.title())
                    .foregroundColor(.textPrimary)

                Text("Из окна дует. Cold walls, drafts, moisture — all invisible until it's too late. Heat Build makes the invisible visible.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .onAppear { setupParticles() }
        .onDisappear { isVisible = false; tapped = false; burst = false }
    }

    func triggerBurst() {
        tapped = true
        burst = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            burst = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tapped = false
            }
        }
    }

    func setupParticles() {
        particles = (0..<12).map { i in
            let angle = Double(i) * 30.0 * .pi / 180.0
            let dist = Double.random(in: 80...140)
            return ParticleData(
                id: UUID(),
                endX: CGFloat(cos(angle) * dist),
                endY: CGFloat(sin(angle) * dist),
                size: CGFloat.random(in: 6...14),
                color: i % 2 == 0 ? Color.accentBlue.opacity(0.6) : Color.accentOrange.opacity(0.5),
                delay: Double(i) * 0.03
            )
        }
    }
}

struct ParticleData: Identifiable {
    let id: UUID
    let endX, endY: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
}

// MARK: - Page 2: Track everything (drag gesture)
struct OnboardingPage2: View {
    @State private var isVisible = true
    @State private var dragOffset: CGSize = .zero
    @State private var pinColor: Color = Color.accentBlue
    @State private var pinScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: "#EEF2F7")

                // Floor plan grid
                FloorPlanGrid()

                // Draggable temperature pin
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: 48, height: 48)
                        .shadow(color: pinColor.opacity(0.4), radius: 10)

                    Image(systemName: "thermometer")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(pinScale)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            dragOffset = val.translation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                pinScale = 1.2
                                pinColor = temperatureColor(for: val.location)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                                pinScale = 1.0
                                pinColor = Color.accentBlue
                            }
                        }
                )

                VStack {
                    Spacer()
                    Text("Drag the pin to map a problem")
                        .font(AppFont.caption())
                        .foregroundColor(.textInactive)
                        .padding(.bottom, 12)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.52)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text("Track\neverything")
                    .font(AppFont.title())
                    .foregroundColor(.textPrimary)

                Text("Keep important details in one place. Drop climate points directly on your room map to pinpoint cold zones and humidity problems.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .onDisappear { isVisible = false; dragOffset = .zero }
    }

    func temperatureColor(for point: CGPoint) -> Color {
        let x = point.x / UIScreen.main.bounds.width
        if x < 0.3 { return Color.accentBlueSoft }
        if x < 0.6 { return Color.statusWarning }
        return Color.accentOrange
    }
}

struct FloorPlanGrid: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Rooms
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.divider2, lineWidth: 1.5)
                    .frame(width: w * 0.55, height: h * 0.5)
                    .position(x: w * 0.3, y: h * 0.35)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.divider2, lineWidth: 1.5)
                    .frame(width: w * 0.35, height: h * 0.4)
                    .position(x: w * 0.75, y: h * 0.3)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.divider2, lineWidth: 1.5)
                    .frame(width: w * 0.45, height: h * 0.35)
                    .position(x: w * 0.5, y: h * 0.72)

                // Existing sample points
                ForEach([(0.2, 0.25, Color.accentBlueSoft), (0.6, 0.45, Color.statusWarning), (0.8, 0.7, Color.statusDone)], id: \.0) { x, y, c in
                    Circle().fill(c).frame(width: 10, height: 10)
                        .position(x: w * CGFloat(x), y: h * CGFloat(y))
                }
            }
        }
    }
}

// MARK: - Page 3: Get better results (scroll parallax)
struct OnboardingPage3: View {
    @State private var isVisible = true
    @State private var scrollY: CGFloat = 0
    @State private var checkStates = [false, false, false]
    @State private var autoCheck = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#DBEAFE"), Color(hex: "#EEF2F7")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Parallax layers
                VStack(spacing: 0) {
                    // Layer 1 — far (slow)
                    HStack(spacing: 20) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: ["doc.text", "chart.bar", "bell"][i])
                                        .foregroundColor(.accentBlue)
                                )
                        }
                    }
                    .offset(y: scrollY * 0.3)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 30)

                // Interactive checklist
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        ChecklistRow(
                            title: ["Weekly climate check", "Seal drafty windows", "Review humidity report"][i],
                            isChecked: checkStates[i]
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                checkStates[i] = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: scrollY * -0.1)
            }
            .frame(height: UIScreen.main.bounds.height * 0.52)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { v in scrollY = v.translation.height * 0.5 }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { scrollY = 0 }
                    }
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Get better\nresults")
                    .font(AppFont.title())
                    .foregroundColor(.textPrimary)

                Text("Use clear checks, reports and reminders. Tap the checkboxes above — that's exactly how Heat Build tracks your progress.")
                    .font(AppFont.body())
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard isVisible else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { checkStates[0] = true }
            }
        }
        .onDisappear { isVisible = false; checkStates = [false, false, false] }
    }
}

struct ChecklistRow: View {
    let title: String
    let isChecked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isChecked ? Color.statusDone : Color.white)
                        .frame(width: 26, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(isChecked ? Color.statusDone : Color.divider2, lineWidth: 1.5)
                        )
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isChecked)

                Text(title)
                    .font(AppFont.medium(15))
                    .foregroundColor(.textPrimary)
                    .strikethrough(isChecked, color: .textInactive)

                Spacer()
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}
