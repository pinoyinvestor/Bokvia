import SwiftUI

struct ProviderCalendarView: View {
    @Environment(AppState.self) private var appState
    @State private var blocks: [CalendarBlock] = []
    @State private var bookings: [ProviderBooking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentWeekStart: Date = Self.mondayOfWeek(Date())
    @State private var showCreateSheet = false
    @State private var selectedBooking: ProviderBooking?
    @State private var selectedSlot: (date: String, time: String)?

    private let hours = Array(stride(from: 7, through: 19, by: 0.5)).map { $0 }
    private let dayLabels = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]
    private let dayLabelsEn = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 0) {
            weekNavigation

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            if isLoading {
                LoadingView()
            } else {
                calendarGrid
            }
        }
        .navigationTitle(appState.isSv ? "Kalender" : "Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWeekData() }
        .sheet(isPresented: $showCreateSheet) {
            createBlockSheet
        }
        .sheet(item: $selectedBooking) { booking in
            bookingDetailSheet(booking)
        }
    }

    // MARK: - Week Navigation

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var weekNavigation: some View {
        HStack {
            Button {
                currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart
                Task { await loadWeekData() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityLabel(appState.isSv ? "Föregående vecka" : "Previous week")

            Spacer()

            Text(weekRangeLabel)
                .font(.subheadline.weight(.medium))

            Spacer()

            Button {
                currentWeekStart = Self.mondayOfWeek(Date())
                Task { await loadWeekData() }
            } label: {
                Text(appState.isSv ? "Idag" : "Today")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BokviaTheme.accentLight)
                    .foregroundStyle(BokviaTheme.accent)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(appState.isSv ? "Gå till idag" : "Go to today")

            Spacer()

            Button {
                currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
                Task { await loadWeekData() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityLabel(appState.isSv ? "Nästa vecka" : "Next week")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var weekRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: appState.language)
        let end = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: end))"
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Day headers
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 50)
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: currentWeekStart) ?? currentWeekStart
                        let isToday = Calendar.current.isDateInToday(date)
                        VStack(spacing: 2) {
                            Text(appState.isSv ? dayLabels[dayIndex] : dayLabelsEn[dayIndex])
                                .font(.caption2.weight(.medium))
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption.weight(isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? BokviaTheme.accent : .primary)
                        }
                        .frame(width: 90)
                    }
                }
                .padding(.bottom, 4)

                // Time slots
                ForEach(hours, id: \.self) { hour in
                    HStack(spacing: 0) {
                        Text(formatHour(hour))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 50)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            let dateStr = dateString(for: dayIndex)
                            let timeStr = formatHour(hour)
                            let block = blockAt(date: dateStr, time: timeStr)
                            let booking = bookingAt(date: dateStr, time: timeStr)

                            ZStack {
                                Rectangle()
                                    .fill(cellColor(block: block, booking: booking))
                                    .border(BokviaTheme.gray200, width: 0.5)

                                if let booking = booking {
                                    Text(booking.customer?.firstName ?? "")
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .padding(2)
                                }
                            }
                            .frame(width: 90, height: 30)
                            .onTapGesture {
                                if let booking = booking {
                                    selectedBooking = booking
                                } else {
                                    selectedSlot = (dateStr, timeStr)
                                    showCreateSheet = true
                                }
                            }
                            .accessibilityLabel(cellAccessibilityLabel(block: block, booking: booking, day: dayIndex, hour: hour))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func cellColor(block: CalendarBlock?, booking: ProviderBooking?) -> Color {
        if let booking = booking {
            switch booking.status {
            case "PENDING", "PENDING_CONFIRMATION": return Color.orange.opacity(0.25)
            case "CONFIRMED": return Color.green.opacity(0.25)
            default: return Color(.secondarySystemBackground)
            }
        }
        if let block = block {
            switch block.type {
            case "SALON_TIME": return Color.blue.opacity(0.2)
            case "PRIVATE_TIME": return Color.green.opacity(0.15)
            case "BLOCKED": return BokviaTheme.gray200
            default: return Color(.secondarySystemBackground)
            }
        }
        return Color(.secondarySystemBackground)
    }

    private func cellAccessibilityLabel(block: CalendarBlock?, booking: ProviderBooking?, day: Int, hour: Double) -> String {
        let dayName = appState.isSv ? dayLabels[day] : dayLabelsEn[day]
        let time = formatHour(hour)
        if let booking = booking {
            return "\(dayName) \(time), \(booking.customer?.fullName ?? "") - \(booking.service?.nameSv ?? "")"
        }
        if let block = block {
            return "\(dayName) \(time), \(block.type)"
        }
        return "\(dayName) \(time), \(appState.isSv ? "Ledigt" : "Available")"
    }

    // MARK: - Create Block Sheet

    private var createBlockSheet: some View {
        NavigationStack {
            CreateBlockForm(
                date: selectedSlot?.date ?? "",
                time: selectedSlot?.time ?? "",
                isSv: appState.isSv
            ) {
                showCreateSheet = false
                Task { await loadWeekData() }
            }
        }
    }

    // MARK: - Booking Detail Sheet

    private func bookingDetailSheet(_ booking: ProviderBooking) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: booking.customer?.avatarUrl ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(BokviaTheme.gray200)
                            .overlay(Text(booking.customer?.initials ?? "?").font(.title3.bold()).foregroundStyle(BokviaTheme.gray500))
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())

                    Text(booking.customer?.fullName ?? "")
                        .font(.title3.bold())

                    StatusBadge(status: booking.status)

                    VStack(spacing: 8) {
                        detailRow(icon: "scissors", label: appState.isSv ? "Tjänst" : "Service", value: booking.service?.nameSv ?? "")
                        detailRow(icon: "calendar", label: appState.isSv ? "Datum" : "Date", value: booking.date)
                        detailRow(icon: "clock", label: appState.isSv ? "Tid" : "Time", value: "\(booking.startTime) - \(booking.endTime ?? "")")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if booking.statusEnum.isActive {
                        bookingActions(booking)
                    }
                }
                .padding()
            }
            .navigationTitle(appState.isSv ? "Bokningsdetaljer" : "Booking details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func bookingActions(_ booking: ProviderBooking) -> some View {
        VStack(spacing: 8) {
            if booking.status == "PENDING" || booking.status == "PENDING_CONFIRMATION" {
                Button {
                    Task {
                        struct Body: Encodable {}
                        do {
                            _ = try await APIClient.shared.patch("/api/bookings/\(booking.id)/confirm", body: Body(), as: ProviderBooking.self)
                            HapticManager.success()
                            selectedBooking = nil
                            await loadWeekData()
                        } catch {
                            errorMessage = appState.isSv ? "Kunde inte acceptera." : "Failed to accept."
                        }
                    }
                } label: {
                    Label(appState.isSv ? "Acceptera" : "Accept", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel(appState.isSv ? "Acceptera bokning" : "Accept booking")

                Button {
                    Task {
                        struct Body: Encodable { let reason: String? }
                        do {
                            _ = try await APIClient.shared.patch("/api/bookings/\(booking.id)/cancel", body: Body(reason: nil), as: ProviderBooking.self)
                            HapticManager.success()
                            selectedBooking = nil
                            await loadWeekData()
                        } catch {
                            errorMessage = appState.isSv ? "Kunde inte neka." : "Failed to decline."
                        }
                    }
                } label: {
                    Label(appState.isSv ? "Neka" : "Decline", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel(appState.isSv ? "Neka bokning" : "Decline booking")
            }

            if booking.status == "CONFIRMED" {
                Button {
                    Task {
                        struct Body: Encodable {}
                        do {
                            _ = try await APIClient.shared.patch("/api/bookings/\(booking.id)/complete", body: Body(), as: ProviderBooking.self)
                            HapticManager.success()
                            selectedBooking = nil
                            await loadWeekData()
                        } catch {
                            errorMessage = appState.isSv ? "Kunde inte slutföra." : "Failed to complete."
                        }
                    }
                } label: {
                    Label(appState.isSv ? "Slutför" : "Complete", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(BokviaTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel(appState.isSv ? "Slutför bokning" : "Complete booking")
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Double) -> String {
        let h = Int(hour)
        let m = Int((hour - Double(h)) * 60)
        return String(format: "%02d:%02d", h, m)
    }

    private func dateString(for dayIndex: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: currentWeekStart) ?? currentWeekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func blockAt(date: String, time: String) -> CalendarBlock? {
        blocks.first { $0.date == date && $0.startTime <= time && $0.endTime > time }
    }

    private func bookingAt(date: String, time: String) -> ProviderBooking? {
        bookings.first { $0.date == date && $0.startTime <= time && ($0.endTime ?? "23:59") > time }
    }

    static func mondayOfWeek(_ date: Date) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    // MARK: - Data Loading

    private func loadWeekData() async {
        isLoading = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let from = formatter.string(from: currentWeekStart)
        let to = formatter.string(from: Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart)

        do {
            async let blocksResult = APIClient.shared.get(
                "/api/providers/me/calendar?from=\(from)&to=\(to)",
                as: CalendarBlocksResponse.self
            )
            async let bookingsResult = APIClient.shared.get(
                "/api/bookings/provider?from=\(from)&to=\(to)",
                as: ProviderBookingsResponse.self
            )

            blocks = (try? await blocksResult)?.items ?? []
            bookings = (try? await bookingsResult)?.items ?? []
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda kalendern." : "Failed to load calendar."
        }

        isLoading = false
    }
}

// MARK: - Create Block Form

struct CreateBlockForm: View {
    let date: String
    let time: String
    let isSv: Bool
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var blockType: CalendarBlockType = .salonTime
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var note: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(isSv ? "Typ" : "Type") {
                Picker(isSv ? "Blocktyp" : "Block type", selection: $blockType) {
                    ForEach(CalendarBlockType.allCases, id: \.self) { type in
                        Text(isSv ? type.label : type.labelEn).tag(type)
                    }
                }
                .accessibilityLabel(isSv ? "Välj blocktyp" : "Select block type")
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            Section(isSv ? "Tid" : "Time") {
                TextField(isSv ? "Starttid (HH:MM)" : "Start time (HH:MM)", text: $startTime)
                    .accessibilityLabel(isSv ? "Starttid" : "Start time")
                TextField(isSv ? "Sluttid (HH:MM)" : "End time (HH:MM)", text: $endTime)
                    .accessibilityLabel(isSv ? "Sluttid" : "End time")
            }

            Section(isSv ? "Anteckning" : "Note") {
                TextField(isSv ? "Valfri anteckning..." : "Optional note...", text: $note)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle(isSv ? "Nytt block" : "New block")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSv ? "Spara" : "Save") {
                    Task { await saveBlock() }
                }
                .disabled(isSaving || startTime.isEmpty || endTime.isEmpty)
                .accessibilityLabel(isSv ? "Spara block" : "Save block")
            }
        }
        .onAppear {
            startTime = time
            let hourVal = (Double(time.prefix(2)) ?? 7) + 1
            endTime = String(format: "%02d:%02d", Int(hourVal), 0)
        }
    }

    private func saveBlock() async {
        isSaving = true
        errorMessage = nil
        let body = CreateCalendarBlockBody(
            type: blockType.rawValue,
            date: date,
            startTime: startTime,
            endTime: endTime,
            title: nil,
            note: note.isEmpty ? nil : note
        )
        do {
            _ = try await APIClient.shared.post("/api/providers/me/calendar", body: body, as: CalendarBlock.self)
            HapticManager.success()
            onSaved()
        } catch {
            errorMessage = isSv ? "Kunde inte spara blocket." : "Failed to save block."
            HapticManager.error()
        }
        isSaving = false
    }
}
