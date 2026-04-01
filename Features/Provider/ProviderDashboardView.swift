import SwiftUI
import Charts

struct ProviderDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var stats: ProviderStatsResponse?
    @State private var todayBookings: [ProviderBooking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPeriod: Period = .week
    @State private var actionError: String?

    enum Period: String, CaseIterable {
        case day, week, month
        var labelSv: String {
            switch self { case .day: return "Dag"; case .week: return "Vecka"; case .month: return "Månad" }
        }
        var labelEn: String {
            switch self { case .day: return "Day"; case .week: return "Week"; case .month: return "Month" }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingSection

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else {
                    periodPicker
                    statsGrid
                    revenueChart
                    quickActions

                    // Built by Christos Ferlachidis & Daniel Hedenberg

                    todaySection

                    if let actionErr = actionError {
                        Text(actionErr)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(appState.isSv ? "Dashboard" : "Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2.bold())
                if let next = nextBooking {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(appState.isSv ? "Nästa: \(next.startTime)" : "Next: \(next.startTime)")
                            .font(.caption)
                    }
                    .foregroundStyle(BokviaTheme.accent)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.currentUser?.firstName ?? ""
        let prefix: String
        if hour < 10 { prefix = appState.isSv ? "God morgon" : "Good morning" }
        else if hour < 18 { prefix = appState.isSv ? "Hej" : "Hi" }
        else { prefix = appState.isSv ? "God kväll" : "Good evening" }
        return name.isEmpty ? prefix : "\(prefix), \(name)"
    }

    private var nextBooking: ProviderBooking? {
        todayBookings.first { $0.statusEnum.isActive }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(appState.isSv ? period.labelSv : period.labelEn).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadData() }
        }
        .accessibilityLabel(appState.isSv ? "Välj period" : "Select period")
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                icon: "calendar.badge.clock",
                title: appState.isSv ? "Bokningar" : "Bookings",
                value: "\(stats?.totalBookings ?? 0)"
            )
            statCard(
                icon: "banknote",
                title: appState.isSv ? "Intäkter" : "Revenue",
                value: "\(Int(stats?.revenue ?? 0)) kr"
            )
            statCard(
                icon: "checkmark.circle",
                title: appState.isSv ? "Slutförda" : "Completed",
                value: "\(stats?.completedBookings ?? 0)"
            )
            statCard(
                icon: "chart.line.uptrend.xyaxis",
                title: appState.isSv ? "Slutförandegrad" : "Completion rate",
                value: String(format: "%.0f%%", (stats?.completionRate ?? 0) * 100)
            )
        }
        .padding(.horizontal)
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(BokviaTheme.accent)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title3.bold())
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Revenue Chart

    private var revenueChart: some View {
        Group {
            if let breakdown = stats?.revenueBreakdown, !breakdown.labels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.isSv ? "Intäkter" : "Revenue")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart {
                        ForEach(Array(zip(breakdown.labels, breakdown.values)), id: \.0) { label, value in
                            BarMark(
                                x: .value("Period", label),
                                y: .value("Revenue", value)
                            )
                            .foregroundStyle(BokviaTheme.accent)
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                    .accessibilityLabel(appState.isSv ? "Intäktsdiagram" : "Revenue chart")
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                quickActionButton(icon: "calendar", label: appState.isSv ? "Kalender" : "Calendar") {
                    // Navigation handled by parent
                }
                quickActionButton(icon: "person.2", label: appState.isSv ? "Kunder" : "Clients") {}
                quickActionButton(icon: "clock", label: appState.isSv ? "Schema" : "Schedule") {}
                quickActionButton(icon: "person.crop.circle", label: appState.isSv ? "Profil" : "Profile") {}
            }
            .padding(.horizontal)
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(BokviaTheme.accent)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .frame(width: 80, height: 70)
            .background(BokviaTheme.accentLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
    }

    // MARK: - Today's Bookings

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appState.isSv ? "Dagens bokningar" : "Today's bookings")
                .font(.headline)
                .padding(.horizontal)

            if todayBookings.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(appState.isSv ? "Inga bokningar idag" : "No bookings today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                ForEach(todayBookings) { booking in
                    todayBookingCard(booking)
                }
            }
        }
    }

    private func todayBookingCard(_ booking: ProviderBooking) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: booking.customer?.avatarUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(BokviaTheme.gray200)
                        .overlay(
                            Text(booking.customer?.initials ?? "?")
                                .font(.caption.bold())
                                .foregroundStyle(BokviaTheme.gray500)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.customer?.fullName ?? "")
                        .font(.subheadline.weight(.semibold))
                    Text(booking.service?.nameSv ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(booking.startTime) - \(booking.endTime ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                StatusBadge(status: booking.status)
            }

            if booking.statusEnum.isActive {
                HStack(spacing: 8) {
                    if booking.status == "PENDING" || booking.status == "PENDING_CONFIRMATION" {
                        Button {
                            Task { await acceptBooking(booking.id) }
                        } label: {
                            Label(appState.isSv ? "Acceptera" : "Accept", systemImage: "checkmark")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel(appState.isSv ? "Acceptera bokning" : "Accept booking")

                        Button {
                            Task { await declineBooking(booking.id) }
                        } label: {
                            Label(appState.isSv ? "Neka" : "Decline", systemImage: "xmark")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel(appState.isSv ? "Neka bokning" : "Decline booking")
                    }

                    if booking.status == "CONFIRMED" {
                        Button {
                            Task { await completeBooking(booking.id) }
                        } label: {
                            Label(appState.isSv ? "Slutför" : "Complete", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(BokviaTheme.accentLight)
                                .foregroundStyle(BokviaTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel(appState.isSv ? "Slutför bokning" : "Complete booking")
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func acceptBooking(_ id: String) async {
        struct Body: Encodable {}
        do {
            _ = try await APIClient.shared.patch("/api/bookings/\(id)/confirm", body: Body(), as: ProviderBooking.self)
            HapticManager.success()
            await loadData()
        } catch {
            actionError = appState.isSv ? "Kunde inte acceptera bokningen." : "Failed to accept booking."
            HapticManager.error()
        }
    }

    private func declineBooking(_ id: String) async {
        struct Body: Encodable { let reason: String? }
        do {
            _ = try await APIClient.shared.patch("/api/bookings/\(id)/cancel", body: Body(reason: nil), as: ProviderBooking.self)
            HapticManager.success()
            await loadData()
        } catch {
            actionError = appState.isSv ? "Kunde inte neka bokningen." : "Failed to decline booking."
            HapticManager.error()
        }
    }

    private func completeBooking(_ id: String) async {
        struct Body: Encodable {}
        do {
            _ = try await APIClient.shared.patch("/api/bookings/\(id)/complete", body: Body(), as: ProviderBooking.self)
            HapticManager.success()
            await loadData()
        } catch {
            actionError = appState.isSv ? "Kunde inte slutföra bokningen." : "Failed to complete booking."
            HapticManager.error()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        actionError = nil

        do {
            async let statsResult = APIClient.shared.get(
                "/api/bookings/provider/stats?period=\(selectedPeriod.rawValue)",
                as: ProviderStatsResponse.self
            )
            async let todayResult = APIClient.shared.get(
                "/api/bookings/provider/today",
                as: ProviderTodayResponse.self
            )

            stats = try await statsResult
            todayBookings = (try? await todayResult)?.items ?? []
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda data. Försök igen." : "Failed to load data. Try again."
        }

        isLoading = false
    }
}
