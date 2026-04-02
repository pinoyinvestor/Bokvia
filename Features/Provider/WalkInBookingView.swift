import SwiftUI

struct WalkInBookingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var customerName = ""
    @State private var customerPhone = ""
    @State private var services: [Service] = []
    @State private var selectedService: Service?
    @State private var isLoadingServices = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            if isSuccess {
                successView
            } else {
                formView
            }
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 36))
                        .foregroundStyle(BokviaTheme.accent)

                    Text(appState.isSv ? "Walk-in bokning" : "Walk-in booking")
                        .font(.title3.bold())

                    Text(appState.isSv
                        ? "Skapa en bokning för en kund som just kommit in"
                        : "Create a booking for a customer who just walked in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                VStack(spacing: 16) {
                    // Customer name
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appState.isSv ? "Kundnamn" : "Customer name")
                            .font(.subheadline.weight(.medium))
                        TextField(appState.isSv ? "Namn..." : "Name...", text: $customerName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Customer phone (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(appState.isSv ? "Telefon" : "Phone")
                                .font(.subheadline.weight(.medium))
                            Text(appState.isSv ? "(valfritt)" : "(optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        TextField(appState.isSv ? "Telefonnummer..." : "Phone number...", text: $customerPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }

                    // Service selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appState.isSv ? "Välj tjänst" : "Select service")
                            .font(.subheadline.weight(.medium))

                        if isLoadingServices {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if services.isEmpty {
                            Text(appState.isSv ? "Inga tjänster hittades" : "No services found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(services) { service in
                                Button {
                                    selectedService = service
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(service.name(locale: appState.language))
                                                .font(.subheadline)
                                            HStack(spacing: 6) {
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
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedService?.id == service.id ? BokviaTheme.accentLight : Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .contentShape(Rectangle())
                                }
                                .foregroundStyle(.primary)
                                .accessibilityLabel("\(service.name(locale: appState.language)), \(service.priceFormatted)")
                            }
                        }
                    }
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    Task { await submitWalkIn() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Label(
                                appState.isSv ? "Starta nu" : "Start now",
                                systemImage: "play.fill"
                            )
                            .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? BokviaTheme.accent : BokviaTheme.gray300)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)
                .accessibilityLabel(appState.isSv ? "Starta walk-in bokning" : "Start walk-in booking")
            }
            .padding(.bottom, 16)
        }
        .navigationTitle(appState.isSv ? "Walk-in" : "Walk-in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
        }
        .task { await loadServices() }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text(appState.isSv ? "Walk-in startad!" : "Walk-in started!")
                .font(.title2.bold())
            Text(appState.isSv
                ? "Bokningen har skapats och startat"
                : "The booking has been created and started")
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
        .navigationTitle("")
    }

    private var canSubmit: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty && selectedService != nil
    }

    private func loadServices() async {
        isLoadingServices = true
        do {
            let result = try await APIClient.shared.get("/api/providers/me/services", as: ProviderServicesResponse.self)
            services = result.items
        } catch {
            // Silently fail
        }
        isLoadingServices = false
    }

    private func submitWalkIn() async {
        guard let serviceId = selectedService?.id else { return }
        isSubmitting = true
        errorMessage = nil

        struct WalkInBody: Encodable {
            let customerName: String
            let customerPhone: String?
            let serviceId: String
        }

        let body = WalkInBody(
            customerName: customerName.trimmingCharacters(in: .whitespaces),
            customerPhone: customerPhone.isEmpty ? nil : customerPhone,
            serviceId: serviceId
        )

        do {
            _ = try await APIClient.shared.post("/api/bookings/walkin", body: body, as: ProviderBooking.self)
            HapticManager.success()
            isSuccess = true
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skapa walk-in bokning." : "Failed to create walk-in booking."
            HapticManager.error()
        }
        isSubmitting = false
    }
}

struct ProviderServicesResponse: Decodable {
    let items: [Service]
}
