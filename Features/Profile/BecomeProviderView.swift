import SwiftUI

struct BecomeProviderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var businessName = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    var body: some View {
        Form {
            Section {
                Text(appState.isSv
                     ? "Registrera dig som behandlare och borja ta emot bokningar."
                     : "Register as a provider and start receiving bookings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            Section(appState.isSv ? "Dina uppgifter" : "Your details") {
                TextField(appState.isSv ? "Verksamhetsnamn" : "Business name", text: $businessName)
                    .textContentType(.organizationName)

                TextField(appState.isSv ? "Telefonnummer" : "Phone number", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            if let error = errorMessage {
                Text(error).foregroundStyle(.red).font(.caption)
            }

            if success {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text(appState.isSv ? "Behandlarkonto skapat!" : "Provider account created!")
                            .font(.headline)
                        Text(appState.isSv
                             ? "Byt roll i profilen for att komma igang."
                             : "Switch role in your profile to get started.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Bli behandlare" : "Become a provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if !success {
                    Button(appState.isSv ? "Skicka" : "Submit") {
                        Task { await submit() }
                    }
                    .disabled(businessName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        struct Body: Encodable {
            let businessName: String
            let phone: String?
        }
        do {
            _ = try await APIClient.shared.post(
                "/api/profiles/provider",
                body: Body(
                    businessName: businessName.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces)
                ),
                as: EmptyResponse.self
            )
            success = true
            HapticManager.success()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skapa konto. Forsok igen." : "Failed to create account. Try again."
            HapticManager.error()
        }
        isLoading = false
    }
}
