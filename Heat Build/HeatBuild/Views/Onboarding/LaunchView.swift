import SwiftUI

struct LaunchView: View {
    var onFinish: () -> Void

    @State private var isVisible = true
    @State private var bgShift = false
    @State private var particle1 = false
    @State private var particle2 = false
    @State private var particle3 = false
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    @State private var heatRing1 = false
    @State private var heatRing2 = false
    @State private var heatRing3 = false
    @State private var floatY: CGFloat = 0

    var body: some View {
        ZStack {
            // Phase 1: Background gradient
            LinearGradient(
                colors: bgShift
                    ? [Color(hex: "#0F172A"), Color(hex: "#1E3A5F"), Color(hex: "#0F172A")]
                    : [Color(hex: "#0F172A"), Color(hex: "#1a2744"), Color(hex: "#0F172A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: bgShift)

            // Phase 2: Heat map rings (thematic)
            ZStack {
                // Cold zone rings emanating from center
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.accentBlue.opacity(0.6), Color.accentOrange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: CGFloat(120 + i * 80), height: CGFloat(120 + i * 80))
                        .scaleEffect(i == 0 ? (heatRing1 ? 1.15 : 0.85) :
                                     i == 1 ? (heatRing2 ? 1.1 : 0.9) : (heatRing3 ? 1.08 : 0.92))
                        .opacity(i == 0 ? (heatRing1 ? 0.2 : 0.5) :
                                 i == 1 ? (heatRing2 ? 0.15 : 0.4) : (heatRing3 ? 0.1 : 0.3))
                        .animation(
                            Animation.easeInOut(duration: Double(2 + i) * 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.3),
                            value: i == 0 ? heatRing1 : i == 1 ? heatRing2 : heatRing3
                        )
                }

                // Heat map dot grid
                if isVisible {
                    HeatDotGrid()
                        .opacity(0.3)
                }
            }

            // Floating particles
            ForEach(0..<8) { i in
                Circle()
                    .fill(i % 2 == 0 ? Color.accentBlue.opacity(0.4) : Color.accentOrange.opacity(0.3))
                    .frame(width: CGFloat(3 + i % 4), height: CGFloat(3 + i % 4))
                    .offset(
                        x: CGFloat([-80, 60, -40, 90, -70, 50, -20, 75][i]),
                        y: particle1
                            ? CGFloat([-120, -80, -60, -100, 80, 60, 40, 90][i])
                            : CGFloat([-100, -60, -40, -80, 60, 40, 20, 70][i])
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.0 + Double(i) * 0.3).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                        value: particle1
                    )
            }

            // Phase 3: Logo + title
            VStack(spacing: 0) {
                Spacer()

                // Animated icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#1E40AF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.accentBlue.opacity(0.5), radius: 20)

                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: floatY)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .padding(.bottom, 28)

                Text("Heat Build")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    .padding(.bottom, 8)

                Text("Smart repair assistant")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.accentBlueSoft.opacity(0.8))
                    .opacity(subtitleOpacity)

                Spacer()
                Spacer()
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear { startSequence() }
        .onDisappear { stopAnimations() }
    }

    private func startSequence() {
        // Phase 1: background
        withAnimation { bgShift = true }
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            floatY = -6
        }

        // Phase 2: rings + particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard isVisible else { return }
            heatRing1 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { heatRing2 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { heatRing3 = true }
            particle1 = true
            particle2 = true
            particle3 = true
        }

        // Phase 3: logo entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard isVisible else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                subtitleOpacity = 1.0
            }
        }

        // Phase 4: designed exit — logo scales up and screen collapses
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                exitScale = 1.08
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.1)) {
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onFinish()
            }
        }
    }

    private func stopAnimations() {
        isVisible = false
        bgShift = false
        heatRing1 = false; heatRing2 = false; heatRing3 = false
        particle1 = false; particle2 = false; particle3 = false
        floatY = 0
    }
}

// MARK: - Heat Dot Grid
struct HeatDotGrid: View {
    let cols = 8
    let rows = 12

    var body: some View {
        GeometryReader { geo in
            let cw = geo.size.width / CGFloat(cols)
            let rh = geo.size.height / CGFloat(rows)
            ForEach(0..<rows, id: \.self) { r in
                ForEach(0..<cols, id: \.self) { c in
                    let heat = heatValue(r: r, c: c)
                    Circle()
                        .fill(heatColor(heat))
                        .frame(width: 4, height: 4)
                        .position(x: cw * CGFloat(c) + cw/2, y: rh * CGFloat(r) + rh/2)
                }
            }
        }
    }

    func heatValue(r: Int, c: Int) -> Double {
        let cx = Double(c) / 8.0
        let cy = Double(r) / 12.0
        let d = sqrt(pow(cx - 0.3, 2) + pow(cy - 0.3, 2))
        return max(0, 1 - d * 2.5)
    }

    func heatColor(_ v: Double) -> Color {
        if v > 0.6 { return Color(hex: "#F97316").opacity(v) }
        if v > 0.3 { return Color(hex: "#FACC15").opacity(v) }
        return Color(hex: "#3B82F6").opacity(max(0.15, v))
    }
}
