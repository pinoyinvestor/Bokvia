import SwiftUI

struct StatusBadge: View {
    let status: String

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var label: String {
        switch status {
        case "PENDING": return "Väntande"
        case "PENDING_CONFIRMATION": return "Inväntar bekräftelse"
        case "CONFIRMED": return "Bekräftad"
        case "CANCELLED_BY_CUSTOMER": return "Avbokad"
        case "CANCELLED_BY_PROVIDER": return "Avbokad av frisör"
        case "NO_SHOW": return "Utebliven"
        case "COMPLETED": return "Slutförd"
        case "DISPUTED": return "Ifrågasatt"
        default: return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(BokviaTheme.statusBgColor(for: status))
            .foregroundStyle(BokviaTheme.statusColor(for: status))
            .clipShape(Capsule())
    }
}
