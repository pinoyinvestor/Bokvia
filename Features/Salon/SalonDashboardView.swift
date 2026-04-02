import SwiftUI

struct SalonDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var stats: SalonStatsResponse?
    @State private var activity: [SalonActivityItem] = []
    @State private var todayBookings: [SalonTodayBooking] = []
    @State private var stations: SalonStationOverview?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // KPI Grid
                if let stats = stats {
                    kpiGrid(stats)
                }

                // Station overview
                if let stations = stations, stations.total > 0 {
                    NavigationLink {
                        StationManagerView()
                    } label: {
                        stationCard(stations)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel(appState.isSv ? "Hantera stationer" : "Manage stations")
                }

                // Built by Christos Ferlachidis & Daniel Hedenberg

                // Today's bookings
                if !todayBookings.isEmpty {
                    sectionHeader(appState.isSv ? "Dagens bokningar" : "Today's bookings")
                    LazyVStack(spacing: 10) {
                        ForEach(todayBookings) { booking in
                            todayBookingCard(booking)
                        }
                    }
                    .padding(.horizontal)
                }

                // Activity feed
                if !activity.isEmpty {
                    sectionHeader(appState.isSv ? "Aktivitet" : "Activity")
                    LazyVStack(spacing: 8) {
                        ForEach(activity) { item in
                            activityRow(item)
                        }
                    }
                    .padding(.horizontal)
                }

                if isLoading {
                    LoadingView()
                        .frame(height: 200)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(appState.isSv ? "Dashboard" : "Dashboard")
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    // MARK: - KPI Grid

    private func kpiGrid(_ stats: SalonStatsResponse) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            kpiCard(
                title: appState.isSv ? "Idag" : "Today",
                value: "\(stats.todayBookings)",
                icon: "calendar.badge.clock",
                color: BokviaTheme.accent
            )
            kpiCard(
                title: appState.isSv ? "Denna vecka" : "This week",
                value: "\(stats.weekBookings)",
                icon: "calendar",
                color: .blue
            )
            kpiCard(
                title: appState.isSv ? "Månadsintäkt" : "Monthly revenue",
                value: "\(Int(stats.monthlyRevenue)) kr",
                icon: "banknote",
                color: .green
            )
            kpiCard(
                title: appState.isSv ? "Teamstorlek" : "Team size",
                value: "\(stats.teamSize)",
                icon: "person.3",
                color: .orange
            )
        }
        .padding(.horizontal)
        .accessibilityLabel(appState.isSv ? "Nyckeltal" : "Key metrics")
    }

    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Stations

    private func stationCard(_ stations: SalonStationOverview) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chair.lounge")
                .font(.title2)
                .foregroundStyle(BokviaTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.isSv ? "Stationer" : "Stations")
                    .font(.subheadline.weight(.semibold))
                Text(appState.isSv
                     ? "\(stations.occupied) av \(stations.total) upptagna"
                     : "\(stations.occupied) of \(stations.total) occupied")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(BokviaTheme.gray200, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: stations.total > 0 ? Double(stations.occupied) / Double(stations.total) : 0)
                    .stroke(BokviaTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(stations.occupied)/\(stations.total)")
                    .font(.caption2.bold())
            }
            .frame(width: 44, height: 44)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityLabel(appState.isSv
                            ? "Stationer: \(stations.occupied) av \(stations.total) upptagna"
                            : "Stations: \(stations.occupied) of \(stations.total) occupied")
    }

    // MARK: - Today's Bookings

    private func todayBookingCard(_ booking: SalonTodayBooking) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: booking.customerAvatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
                    .overlay(
                        Text(String(booking.customerName?.prefix(1) ?? "?"))
                            .font(.caption.bold())
                            .foregroundStyle(BokviaTheme.accent)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                if let providerName = booking.providerName {
                    Text(providerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(booking.customerName ?? (appState.isSv ? "Kund" : "Customer"))
                    .font(.subheadline.weight(.semibold))
                if let service = booking.serviceName {
                    Text(service)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let family = booking.familyProfileName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text(family)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: booking.status)
                Text(booking.startTime)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Activity Feed

    private func activityRow(_ item: SalonActivityItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: activityIcon(for: item.type))
                .font(.caption)
                .foregroundStyle(BokviaTheme.accent)
                .frame(width: 28, height: 28)
                .background(BokviaTheme.accentLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                if let provider = item.providerName {
                    Text(provider)
                        .font(.caption.weight(.semibold))
                }
                Text(item.description ?? item.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.timestamp)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func activityIcon(for type: String) -> String {
        switch type {
        case "WORK_POSTED": return "photo"
        case "REVIEW_RECEIVED": return "star.fill"
        case "BOOKING_CREATED": return "calendar.badge.plus"
        case "BOOKING_COMPLETED": return "checkmark.circle"
        case "MEMBER_JOINED": return "person.badge.plus"
        default: return "bell"
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        async let statsResult: SalonStatsResponse? = try? await APIClient.shared.get(
            "/api/salons/me/stats", as: SalonStatsResponse.self
        )
        async let activityResult: SalonActivityFeed? = try? await APIClient.shared.get(
            "/api/salons/me/activity-feed", as: SalonActivityFeed.self
        )
        async let bookingsResult: SalonTodayBookingsResponse? = try? await APIClient.shared.get(
            "/api/salons/me/bookings", as: SalonTodayBookingsResponse.self
        )

        stats = await statsResult
        activity = await activityResult?.items ?? []
        todayBookings = await bookingsResult?.items ?? []

        // Stations need the salon ID from stats or profile
        if let salonId = appState.currentUser?.activeProfileId {
            stations = try? await APIClient.shared.get(
                "/api/stations/salon/\(salonId)", as: SalonStationOverview.self
            )
        }

        if stats == nil {
            errorMessage = appState.isSv ? "Kunde inte ladda dashboard" : "Failed to load dashboard"
        }

        isLoading = false
    }
}
