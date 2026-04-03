import SwiftUI

struct CreateSalonView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var salonName = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    var body: some View {
        Form {
            Section {
                Text(appState.isSv
                     ? "Skapa en salong och bjud in behandlare till ditt team."
                     : "Create a salon and invite providers to your team.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            Section(appState.isSv ? "Salonguppgifter" : "Salon details") {
                TextField(appState.isSv ? "Salongnamn" : "Salon name", text: $salonName)
                    .textContentType(.organizationName)

                TextField(appState.isSv ? "Adress" : "Address", text: $address)
                    .textContentType(.fullStreetAddress)

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
                        Text(appState.isSv ? "Salong skapad!" : "Salon created!")
                            .font(.headline)
                        Text(appState.isSv
                             ? "Byt roll i profilen for att hantera din salong."
                             : "Switch role in your profile to manage your salon.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Skapa salong" : "Create salon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if !success {
                    Button(appState.isSv ? "Skapa" : "Create") {
                        Task { await submit() }
                    }
                    .disabled(salonName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        struct Body: Encodable {
            let name: String
            let address: String?
            let phone: String?
        }
        do {
            _ = try await APIClient.shared.post(
                "/api/profiles/salon",
                body: Body(
                    name: salonName.trimmingCharacters(in: .whitespaces),
                    address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces)
                ),
                as: EmptyResponse.self
            )
            success = true
            HapticManager.success()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte skapa salong. Forsok igen." : "Failed to create salon. Try again."
            HapticManager.error()
        }
        isLoading = false
    }
}
