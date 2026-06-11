import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary = Color(hex: "#F8FAFC")
    static let bgSecondary = Color(hex: "#EEF2F7")
    static let bgDepth = Color(hex: "#E5EAF2")

    // Cards
    static let cardWhite = Color(hex: "#FFFFFF")
    static let cardLight = Color(hex: "#F1F5F9")

    // Dividers
    static let divider1 = Color(hex: "#E2E8F0")
    static let divider2 = Color(hex: "#CBD5E1")

    // Blue Accent
    static let accentBlue = Color(hex: "#3B82F6")
    static let accentBlueDark = Color(hex: "#2563EB")
    static let accentBlueSoft = Color(hex: "#60A5FA")

    // Orange Accent
    static let accentOrange = Color(hex: "#F97316")
    static let accentOrangeSoft = Color(hex: "#FB923C")
    static let accentOrangeLight = Color(hex: "#FDBA74")

    // Status
    static let statusDone = Color(hex: "#22C55E")
    static let statusProgress = Color(hex: "#3B82F6")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusError = Color(hex: "#EF4444")

    // Text
    static let textPrimary = Color(hex: "#0F172A")
    static let textSecondary = Color(hex: "#475569")
    static let textInactive = Color(hex: "#94A3B8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct AppFont {
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func title() -> Font { bold(28) }
    static func headline() -> Font { semibold(17) }
    static func body() -> Font { regular(15) }
    static func caption() -> Font { medium(12) }
}

// MARK: - Shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    func blueShadow() -> some View {
        self.shadow(color: Color(hex: "#3B82F6").opacity(0.25), radius: 12, x: 0, y: 4)
    }
    func orangeShadow() -> some View {
        self.shadow(color: Color(hex: "#F97316").opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentBlue)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
            .blueShadow()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.divider1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct OrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentOrange)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
            .orangeShadow()
    }
}

struct SmallPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(14))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentBlue))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SmallSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(14))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.divider1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
