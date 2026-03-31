import SwiftUI

enum BokviaTheme {
    // Bokvia brand purple
    static let accent = Color(hex: "AF52DE")
    static let accentLight = Color(hex: "F5E6FF")
    static let accentDark = Color(hex: "8B3BB5")

    // Gray palette
    static let gray50 = Color(hex: "F9FAFB")
    static let gray100 = Color(hex: "F3F4F6")
    static let gray200 = Color(hex: "E5E7EB")
    static let gray300 = Color(hex: "D1D5DB")
    static let gray400 = Color(hex: "9CA3AF")
    static let gray500 = Color(hex: "6B7280")
    static let gray700 = Color(hex: "374151")
    static let gray800 = Color(hex: "1F2937")
    static let gray900 = Color(hex: "111827")

    // Built by Christos Ferlachidis & Daniel Hedenberg

    static func statusColor(for status: String) -> Color {
        let dark = isDarkMode
        switch status {
        case "CONFIRMED": return dark ? Color(hex: "34D399") : Color(hex: "065F46")
        case "PENDING", "PENDING_CONFIRMATION": return dark ? Color(hex: "FBBF24") : Color(hex: "92400E")
        case "CANCELLED_BY_CUSTOMER", "CANCELLED_BY_PROVIDER": return dark ? Color(hex: "F87171") : Color(hex: "991B1B")
        case "COMPLETED": return dark ? Color(hex: "60A5FA") : Color(hex: "1E40AF")
        case "NO_SHOW": return dark ? Color(hex: "FB923C") : Color(hex: "9A3412")
        case "DISPUTED": return dark ? Color(hex: "F87171") : Color(hex: "991B1B")
        default: return .secondary
        }
    }

    static func statusBgColor(for status: String) -> Color {
        let dark = isDarkMode
        switch status {
        case "CONFIRMED": return dark ? Color(hex: "065F46").opacity(0.3) : Color(hex: "D1FAE5")
        case "PENDING", "PENDING_CONFIRMATION": return dark ? Color(hex: "78350F").opacity(0.3) : Color(hex: "FEF3C7")
        case "CANCELLED_BY_CUSTOMER", "CANCELLED_BY_PROVIDER": return dark ? Color(hex: "7F1D1D").opacity(0.3) : Color(hex: "FEE2E2")
        case "COMPLETED": return dark ? Color(hex: "1E3A8A").opacity(0.3) : Color(hex: "DBEAFE")
        case "NO_SHOW": return dark ? Color(hex: "7C2D12").opacity(0.3) : Color(hex: "FFEDD5")
        case "DISPUTED": return dark ? Color(hex: "7F1D1D").opacity(0.3) : Color(hex: "FEE2E2")
        default: return .secondary.opacity(0.15)
        }
    }

    private static var isDarkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }
}
