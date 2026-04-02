import SwiftUI

struct BookingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let providerId: String
    let providerName: String
    let services: [Service]

    @State private var step: BookingStep = .selectService
    @State private var selectedService: Service?
    @State private var selectedDate = Date()
    @State private var slots: [Slot] = []
    @State private var selectedSlot: Slot?
    @State private var isLoadingSlots = false
    @State private var isBooking = false
    @State private var errorMessage: String?
    @State private var bookingComplete = false
    @State private var customerNote = ""
    @State private var showWaitlist = false

    enum BookingStep: Int {
        case selectService, selectDate, selectSlot, confirm
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= step.rawValue ? BokviaTheme.accent : BokviaTheme.gray200)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Built by Christos Ferlachidis & Daniel Hedenberg

            if bookingComplete {
                confirmationView
            } else {
                switch step {
                case .selectService:
                    serviceSelectionView
                case .selectDate:
                    dateSelectionView
                case .selectSlot:
                    slotSelectionView
                case .confirm:
                    confirmView
                }
            }
        }
        .navigationTitle(appState.isSv ? "Boka tid" : "Book appointment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Step 1: Select Service
    private var serviceSelectionView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(appState.isSv ? "Välj tjänst" : "Select service")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(services) { service in
                    Button {
                        selectedService = service
                        step = .selectDate
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.name(locale: appState.language))
                                    .font(.subheadline.weight(.medium))
                                HStack(spacing: 8) {
                                    Text(service.priceFormatted)
                                        .font(.caption.weight(.medium))
                                    if !service.durationFormatted.isEmpty {
                                        Text("· \(service.durationFormatted)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: selectedService?.id == service.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedService?.id == service.id ? BokviaTheme.accent : .secondary)
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.primary)
                    Divider().padding(.leading)
                }
            }
        }
    }

    // MARK: - Step 2: Select Date
    private var dateSelectionView: some View {
        VStack(spacing: 16) {
            Text(appState.isSv ? "Välj datum" : "Select date")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(BokviaTheme.accent)
                .padding(.horizontal)

            Button {
                step = .selectSlot
                Task { await loadSlots() }
            } label: {
                Text(appState.isSv ? "Visa tider" : "Show times")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Step 3: Select Slot
    private var slotSelectionView: some View {
        VStack(spacing: 16) {
            Text(appState.isSv ? "Välj tid" : "Select time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            Text(DateFormatter.displayDate.string(from: selectedDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            } else if isLoadingSlots {
                LoadingView()
            } else if slots.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        appState.isSv ? "Inga lediga tider" : "No available times",
                        systemImage: "clock"
                    )

                    Button {
                        showWaitlist = true
                    } label: {
                        Label(
                            appState.isSv ? "Ställ dig i kö" : "Join waitlist",
                            systemImage: "bell.badge"
                        )
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(BokviaTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(appState.isSv ? "Ställ dig i kö för denna tid" : "Join the waitlist for this time")
                    .sheet(isPresented: $showWaitlist) {
                        if let service = selectedService {
                            WaitlistView(
                                providerId: providerId,
                                serviceId: service.id,
                                providerName: providerName,
                                serviceName: service.name(locale: appState.language)
                            )
                        }
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(slots) { slot in
                            Button {
                                selectedSlot = slot
                                step = .confirm
                            } label: {
                                Text(slot.startTime)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedSlot?.id == slot.id ? BokviaTheme.accent : Color(.secondarySystemBackground))
                                    .foregroundStyle(selectedSlot?.id == slot.id ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Step 4: Confirm
    private var confirmView: some View {
        VStack(spacing: 20) {
            Text(appState.isSv ? "Bekräfta bokning" : "Confirm booking")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            VStack(spacing: 12) {
                confirmRow(icon: "person", label: appState.isSv ? "Hos" : "With", value: providerName)
                confirmRow(icon: "scissors", label: appState.isSv ? "Tjänst" : "Service", value: selectedService?.name(locale: appState.language) ?? "")
                confirmRow(icon: "calendar", label: appState.isSv ? "Datum" : "Date", value: DateFormatter.displayDate.string(from: selectedDate))
                confirmRow(icon: "clock", label: appState.isSv ? "Tid" : "Time", value: selectedSlot?.startTime ?? "")
                if let price = selectedService?.priceFormatted {
                    confirmRow(icon: "creditcard", label: appState.isSv ? "Pris" : "Price", value: price)
                }

                if let member = appState.activeBookingProfile {
                    confirmRow(icon: "person.2", label: appState.isSv ? "Bokar för" : "Booking for", value: member.name)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Optional message to provider
            TextField(
                appState.isSv ? "Meddelande till frisören (valfritt)" : "Message to provider (optional)",
                text: $customerNote,
                axis: .vertical
            )
            .lineLimit(2...4)
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                Task { await book() }
            } label: {
                Group {
                    if isBooking {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Boka nu" : "Book now")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isBooking)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 8)
    }

    // MARK: - Confirmation
    private var confirmationView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text(appState.isSv ? "Bokning bekräftad!" : "Booking confirmed!")
                .font(.title2.bold())
            Text(appState.isSv ? "Du får en bekräftelse via e-post" : "You'll receive a confirmation email")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text(appState.isSv ? "Stäng" : "Close")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BokviaTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private func confirmRow(icon: String, label: String, value: String) -> some View {
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

    private func loadSlots() async {
        isLoadingSlots = true
        errorMessage = nil
        let dateStr = DateFormatter.apiDate.string(from: selectedDate)
        do {
            let result = try await APIClient.shared.getNoAuth("/api/slots/provider/\(providerId)?date=\(dateStr)", as: SlotsResponse.self)
            slots = result.slots.filter { $0.isAvailable ?? true }
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda lediga tider." : "Failed to load available times."
        }
        isLoadingSlots = false
    }

    private func book() async {
        guard let slotId = selectedSlot?.id, let serviceId = selectedService?.id else { return }
        isBooking = true
        errorMessage = nil

        struct BookRequest: Encodable {
            let serviceId: String
            let familyProfileId: String?
            let customerNote: String?
        }
        let body = BookRequest(
            serviceId: serviceId,
            familyProfileId: appState.activeBookingProfile?.id,
            customerNote: customerNote.isEmpty ? nil : customerNote
        )

        do {
            _ = try await APIClient.shared.post("/api/slots/\(slotId)/book", body: body, as: Booking.self)
            HapticManager.success()
            bookingComplete = true
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
        isBooking = false
    }
}
