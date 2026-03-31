import SwiftUI

struct BookingsView: View {
    @Environment(AppState.self) private var appState
    @State private var segment: BookingSegment = .upcoming
    @State private var bookings: [Booking] = []
    @State private var isLoading = true

    enum BookingSegment: String, CaseIterable {
        case upcoming, past
        var label: String {
            switch self {
            case .upcoming: return "Kommande"
            case .past: return "Tidigare"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                ForEach(BookingSegment.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: segment) { _, _ in
                Task { await loadBookings() }
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            if isLoading {
                LoadingView()
            } else if bookings.isEmpty {
                ContentUnavailableView(
                    segment == .upcoming
                        ? (appState.isSv ? "Inga kommande bokningar" : "No upcoming bookings")
                        : (appState.isSv ? "Inga tidigare bokningar" : "No past bookings"),
                    systemImage: "calendar"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(bookings) { booking in
                            NavigationLink {
                                BookingDetailView(booking: booking)
                            } label: {
                                BookingCard(booking: booking, locale: appState.language)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Bokningar" : "Bookings")
        .task { await loadBookings() }
        .refreshable { await loadBookings() }
    }

    private func loadBookings() async {
        isLoading = true
        let status = segment == .upcoming ? "upcoming" : "past"
        if let result = try? await APIClient.shared.get("/api/bookings/my?status=\(status)", as: BookingsResponse.self) {
            bookings = result.items
        }
        isLoading = false
    }
}

struct BookingCard: View {
    let booking: Booking
    let locale: String

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: booking.provider?.avatarUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BokviaTheme.gray200)
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.provider?.displayName ?? "")
                    .font(.subheadline.weight(.semibold))

                Text(booking.service?.nameSv ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Built by Christos Ferlachidis & Daniel Hedenberg

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(booking.date)
                        .font(.caption)
                    Text("·")
                    Text(booking.startTime)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)

                if let family = booking.familyProfile {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text(family.name)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: booking.status)
                if let duration = booking.duration {
                    Text("\(duration) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
