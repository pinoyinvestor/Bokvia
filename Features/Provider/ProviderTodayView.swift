import SwiftUI

struct ProviderTodayView: View {
    @Environment(AppState.self) private var appState
    @State private var bookings: [ProviderBooking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var actionError: String?

    private var totalCount: Int { bookings.count }
    private var freeSlots: Int {
        let booked = bookings.filter { $0.statusEnum.isActive }.count
        return max(0, 12 - booked)
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryBar

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            if let actionErr = actionError {
                Text(actionErr)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            if isLoading {
                LoadingView()
            } else if bookings.isEmpty {
                emptyState
            } else {
                bookingsList
            }
        }
        .navigationTitle(appState.isSv ? "Idag" : "Today")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadToday() }
        .refreshable { await loadToday() }
    }

    // MARK: - Summary Bar

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var summaryBar: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(BokviaTheme.accent)
                Text("\(totalCount)")
                    .font(.headline)
                Text(appState.isSv ? "bokningar" : "bookings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(.green)
                Text("\(freeSlots)")
                    .font(.headline)
                Text(appState.isSv ? "lediga" : "free")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(appState.isSv
            ? "\(totalCount) bokningar, \(freeSlots) lediga tider"
            : "\(totalCount) bookings, \(freeSlots) free slots")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sun.max")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(appState.isSv ? "Inga bokningar idag" : "No bookings today")
                .font(.headline)
            Text(appState.isSv ? "Njut av din lediga dag!" : "Enjoy your free day!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bookings List

    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(bookings) { booking in
                    bookingCard(booking)
                }
            }
            .padding()
        }
    }

    private func bookingCard(_ booking: ProviderBooking) -> some View {
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
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.customer?.fullName ?? "")
                        .font(.subheadline.weight(.semibold))
                    Text(booking.service?.nameSv ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(booking.startTime) - \(booking.endTime ?? "")")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 6) {
                    StatusBadge(status: booking.status)
                    if let duration = booking.duration {
                        Text("\(duration) min")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 8) {
                if booking.status == "PENDING" || booking.status == "PENDING_CONFIRMATION" {
                    actionButton(
                        label: appState.isSv ? "Acceptera" : "Accept",
                        icon: "checkmark",
                        bg: Color.green.opacity(0.15),
                        fg: .green,
                        accessLabel: appState.isSv ? "Acceptera bokning" : "Accept booking"
                    ) {
                        await performAction(bookingId: booking.id, action: "confirm")
                    }

                    actionButton(
                        label: appState.isSv ? "Neka" : "Decline",
                        icon: "xmark",
                        bg: Color.red.opacity(0.15),
                        fg: .red,
                        accessLabel: appState.isSv ? "Neka bokning" : "Decline booking"
                    ) {
                        await performAction(bookingId: booking.id, action: "cancel")
                    }
                }

                if booking.status == "CONFIRMED" {
                    actionButton(
                        label: appState.isSv ? "Slutför" : "Complete",
                        icon: "checkmark.circle.fill",
                        bg: BokviaTheme.accentLight,
                        fg: BokviaTheme.accent,
                        accessLabel: appState.isSv ? "Slutför bokning" : "Complete booking"
                    ) {
                        await performAction(bookingId: booking.id, action: "complete")
                    }

                    actionButton(
                        label: appState.isSv ? "Avboka" : "Cancel",
                        icon: "xmark.circle",
                        bg: Color.red.opacity(0.15),
                        fg: .red,
                        accessLabel: appState.isSv ? "Avboka" : "Cancel booking"
                    ) {
                        await performAction(bookingId: booking.id, action: "cancel")
                    }
                }

                Spacer()

                // Contact buttons
                if let phone = booking.customer?.phone, !phone.isEmpty {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .padding(8)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(appState.isSv ? "Ring kund" : "Call customer")
                }

                NavigationLink {
                    ChatDetailView(userId: booking.customer?.id ?? "")
                } label: {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption)
                        .padding(8)
                        .background(BokviaTheme.accentLight)
                        .foregroundStyle(BokviaTheme.accent)
                        .clipShape(Circle())
                }
                .accessibilityLabel(appState.isSv ? "Meddelande" : "Message")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func actionButton(label: String, icon: String, bg: Color, fg: Color, accessLabel: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(bg)
                .foregroundStyle(fg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(accessLabel)
    }

    // MARK: - Actions

    private func performAction(bookingId: String, action: String) async {
        actionError = nil
        struct Body: Encodable { let reason: String? }
        do {
            _ = try await APIClient.shared.patch(
                "/api/bookings/\(bookingId)/\(action)",
                body: Body(reason: nil),
                as: ProviderBooking.self
            )
            HapticManager.success()
            await loadToday()
        } catch {
            actionError = appState.isSv ? "Åtgärden misslyckades." : "Action failed."
            HapticManager.error()
        }
    }

    // MARK: - Data Loading

    private func loadToday() async {
        isLoading = true
        errorMessage = nil
        actionError = nil
        do {
            let result = try await APIClient.shared.get("/api/bookings/provider/today", as: ProviderTodayResponse.self)
            bookings = result.items
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda bokningar." : "Failed to load bookings."
        }
        isLoading = false
    }
}
