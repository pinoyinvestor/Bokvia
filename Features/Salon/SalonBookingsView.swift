import SwiftUI

struct SalonBookingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDate = Date()
    @State private var bookings: [SalonTodayBooking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date picker
            DatePicker(
                appState.isSv ? "Datum" : "Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding()
            .onChange(of: selectedDate) { _, _ in
                Task { await loadBookings() }
            }

            Divider()

            // Built by Christos Ferlachidis & Daniel Hedenberg

            if isLoading {
                LoadingView()
            } else if bookings.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga bokningar detta datum" : "No bookings on this date",
                    systemImage: "calendar"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(bookings) { booking in
                            salonBookingCard(booking)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .navigationTitle(appState.isSv ? "Bokningar" : "Bookings")
        .task { await loadBookings() }
        .refreshable { await loadBookings() }
    }

    private func salonBookingCard(_ booking: SalonTodayBooking) -> some View {
        HStack(spacing: 12) {
            // Customer avatar
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
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // Provider name
                if let providerName = booking.providerName {
                    Text(providerName)
                        .font(.caption)
                        .foregroundStyle(BokviaTheme.accent)
                }

                // Customer name
                Text(booking.customerName ?? (appState.isSv ? "Kund" : "Customer"))
                    .font(.subheadline.weight(.semibold))

                // Service
                if let service = booking.serviceName {
                    Text(service)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(booking.startTime)
                        .font(.caption.weight(.medium))
                    if let end = booking.endTime {
                        Text("–")
                            .font(.caption)
                        Text(end)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)

                // Family profile
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

            StatusBadge(status: booking.status)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(booking.customerName ?? "") \(booking.serviceName ?? "") \(booking.startTime)")
    }

    private func loadBookings() async {
        isLoading = true
        errorMessage = nil

        if let result = try? await APIClient.shared.get(
            "/api/salon/bookings?date=\(dateString)",
            as: SalonTodayBookingsResponse.self
        ) {
            bookings = result.items
        } else {
            errorMessage = appState.isSv ? "Kunde inte ladda bokningar" : "Failed to load bookings"
        }

        isLoading = false
    }
}
