import SwiftUI

struct BookingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    @State private var showCancelConfirm = false
    @State private var isCancelling = false
    @State private var showLeaveReview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Provider info
                VStack(spacing: 12) {
                    AsyncImage(url: URL(string: booking.provider?.avatarUrl ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(BokviaTheme.gray200)
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())

                    Text(booking.provider?.displayName ?? "")
                        .font(.title3.bold())

                    StatusBadge(status: booking.status)
                }
                .padding(.top, 8)

                // Details card
                VStack(spacing: 12) {
                    detailRow(icon: "scissors", label: appState.isSv ? "Tjänst" : "Service", value: booking.service?.nameSv ?? "")
                    detailRow(icon: "calendar", label: appState.isSv ? "Datum" : "Date", value: booking.date)
                    detailRow(icon: "clock", label: appState.isSv ? "Tid" : "Time", value: "\(booking.startTime) - \(booking.endTime ?? "")")
                    if let duration = booking.duration {
                        detailRow(icon: "hourglass", label: appState.isSv ? "Längd" : "Duration", value: "\(duration) min")
                    }
                    // Built by Christos Ferlachidis & Daniel Hedenberg
                    if let price = booking.service?.price {
                        detailRow(icon: "creditcard", label: appState.isSv ? "Pris" : "Price", value: "\(Int(price)) kr")
                    }
                    if let mode = booking.workMode {
                        detailRow(icon: "location", label: appState.isSv ? "Plats" : "Location", value: workModeLabel(mode))
                    }
                    if let family = booking.familyProfile {
                        detailRow(icon: "person.2", label: appState.isSv ? "Bokar för" : "Booking for", value: family.name)
                    }
                    if let notes = booking.notes, !notes.isEmpty {
                        detailRow(icon: "note.text", label: appState.isSv ? "Anteckningar" : "Notes", value: notes)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Cancellation policy
                if booking.statusEnum.isActive, let hours = booking.provider?.cancellationHours {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(appState.isSv
                            ? "Avboka senast \(hours)h innan bokad tid"
                            : "Cancel at least \(hours)h before appointment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Actions
                if booking.statusEnum.isActive {
                    VStack(spacing: 12) {
                        if let slug = booking.provider?.slug {
                            NavigationLink {
                                ProviderProfileView(slug: slug)
                            } label: {
                                HStack {
                                    Image(systemName: "person")
                                    Text(appState.isSv ? "Visa profil" : "View profile")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .foregroundStyle(.primary)
                        }

                        NavigationLink {
                            ChatDetailView(userId: booking.provider?.id ?? "")
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left")
                                Text(appState.isSv ? "Kontakta" : "Contact")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundStyle(.primary)

                        Button(role: .destructive) {
                            showCancelConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "xmark")
                                Text(appState.isSv ? "Avboka" : "Cancel booking")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal)
                }

                // Leave review for completed bookings
                if booking.statusEnum == .completed {
                    Button {
                        showLeaveReview = true
                    } label: {
                        HStack {
                            Image(systemName: "star")
                            Text(appState.isSv ? "Lämna omdöme" : "Leave a review")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(BokviaTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(appState.isSv ? "Bokningsdetaljer" : "Booking details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLeaveReview) {
            NavigationStack {
                LeaveReviewView(
                    providerId: booking.provider?.id ?? "",
                    bookingId: booking.id,
                    providerName: booking.provider?.displayName ?? ""
                )
            }
        }
        .alert(appState.isSv ? "Avboka?" : "Cancel booking?", isPresented: $showCancelConfirm) {
            Button(appState.isSv ? "Ja, avboka" : "Yes, cancel", role: .destructive) {
                Task { await cancelBooking() }
            }
            Button(appState.isSv ? "Nej" : "No", role: .cancel) {}
        } message: {
            Text(appState.isSv ? "Är du säker på att du vill avboka?" : "Are you sure you want to cancel this booking?")
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

    private func workModeLabel(_ mode: String) -> String {
        switch mode {
        case "AT_SALON": return appState.isSv ? "På salong" : "At salon"
        case "AT_PROVIDER": return appState.isSv ? "Hos frisör" : "At provider"
        case "HOME_VISIT": return appState.isSv ? "Hembesök" : "Home visit"
        default: return mode
        }
    }

    private func cancelBooking() async {
        isCancelling = true
        struct CancelBody: Encodable { let reason: String? }
        _ = try? await APIClient.shared.patch("/api/bookings/\(booking.id)/cancel", body: CancelBody(reason: nil), as: Booking.self)
        HapticManager.success()
        dismiss()
    }
}
