import SwiftUI

struct SalonSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // Form state
    @State private var seekingTalent = false
    @State private var selectedRoles: Set<String> = []
    @State private var genderPreference = "ANYONE"
    @State private var applicantMessage = ""

    private let maxMessageLength = 500

    // Role categories
    private var roleCategories: [(String, String, [RoleOption])] {
        [
            (appState.isSv ? "Hår" : "Hair", "scissors", [
                RoleOption(id: "BARBER", sv: "Barberare", en: "Barber"),
                RoleOption(id: "STYLIST", sv: "Stylist", en: "Stylist"),
                RoleOption(id: "COLORIST", sv: "Färgspecialist", en: "Colorist"),
            ]),
            (appState.isSv ? "Naglar" : "Nails", "hand.raised", [
                RoleOption(id: "NAIL_TECH", sv: "Nagelteknolog", en: "Nail tech"),
                RoleOption(id: "MANICURIST", sv: "Manikurist", en: "Manicurist"),
            ]),
            (appState.isSv ? "Fransar" : "Lashes", "eye", [
                RoleOption(id: "LASH_TECH", sv: "Fransspecialist", en: "Lash tech"),
            ]),
            // Built by Christos Ferlachidis & Daniel Hedenberg
            (appState.isSv ? "Hud" : "Skin", "drop", [
                RoleOption(id: "ESTHETICIAN", sv: "Hudterapeut", en: "Esthetician"),
                RoleOption(id: "FACIALIST", sv: "Ansiktsbehandlare", en: "Facialist"),
            ]),
            (appState.isSv ? "Tatuering" : "Tattoo", "pencil.tip", [
                RoleOption(id: "TATTOO_ARTIST", sv: "Tatuerare", en: "Tattoo artist"),
                RoleOption(id: "PIERCER", sv: "Piercingspecialist", en: "Piercer"),
            ]),
        ]
    }

    private let genderOptions = ["ANYONE", "MALE", "FEMALE"]

    var body: some View {
        Form {
            // Seeking talent toggle
            Section {
                Toggle(
                    appState.isSv ? "Söker personal" : "Seeking talent",
                    isOn: $seekingTalent
                )
                .tint(BokviaTheme.accent)
                .accessibilityLabel(appState.isSv ? "Söker personal" : "Seeking talent")
            } footer: {
                Text(appState.isSv
                     ? "Visa att din salong söker nya teammedlemmar"
                     : "Show that your salon is looking for new team members")
            }

            // Roles by category
            if seekingTalent {
                Section(appState.isSv ? "Roller vi söker" : "Roles we're looking for") {
                    ForEach(roleCategories, id: \.0) { category, icon, roles in
                        DisclosureGroup {
                            ForEach(roles) { role in
                                Button {
                                    toggleRole(role.id)
                                } label: {
                                    HStack {
                                        Text(appState.isSv ? role.sv : role.en)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedRoles.contains(role.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(BokviaTheme.accent)
                                        }
                                    }
                                }
                                .accessibilityAddTraits(selectedRoles.contains(role.id) ? .isSelected : [])
                            }
                        } label: {
                            Label(category, systemImage: icon)
                        }
                    }
                }

                // Gender preference
                Section(appState.isSv ? "Könspreferens" : "Gender preference") {
                    Picker(appState.isSv ? "Preferens" : "Preference", selection: $genderPreference) {
                        Text(appState.isSv ? "Alla" : "Anyone").tag("ANYONE")
                        Text(appState.isSv ? "Man" : "Male").tag("MALE")
                        Text(appState.isSv ? "Kvinna" : "Female").tag("FEMALE")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel(appState.isSv ? "Könspreferens" : "Gender preference")
                }

                // Message to applicants
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(
                            appState.isSv ? "Meddelande till sökande..." : "Message to applicants...",
                            text: $applicantMessage,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .onChange(of: applicantMessage) { _, newValue in
                            if newValue.count > maxMessageLength {
                                applicantMessage = String(newValue.prefix(maxMessageLength))
                            }
                        }

                        HStack {
                            Spacer()
                            Text("\(applicantMessage.count)/\(maxMessageLength)")
                                .font(.caption2)
                                .foregroundStyle(applicantMessage.count >= maxMessageLength ? .red : .secondary)
                        }
                    }
                } header: {
                    Text(appState.isSv ? "Meddelande till sökande" : "Message to applicants")
                } footer: {
                    Text(appState.isSv
                         ? "Visas för de som ansöker om att gå med i ditt team"
                         : "Shown to those applying to join your team")
                }
            }

            // Save button
            Section {
                Button {
                    Task { await saveSettings() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(appState.isSv ? "Spara" : "Save")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isSaving)
                .listRowBackground(BokviaTheme.accent)
                .foregroundStyle(.white)
                .accessibilityLabel(appState.isSv ? "Spara inställningar" : "Save settings")
            }

            // Feedback messages
            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let success = successMessage {
                Section {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Inställningar" : "Settings")
        .task { await loadProfile() }
    }

    // MARK: - Helpers

    private func toggleRole(_ roleId: String) {
        if selectedRoles.contains(roleId) {
            selectedRoles.remove(roleId)
        } else {
            selectedRoles.insert(roleId)
        }
    }

    private func loadProfile() async {
        isLoading = true
        if let profile = try? await APIClient.shared.get("/api/salons/me/profile", as: SalonProfileResponse.self) {
            seekingTalent = profile.seekingTalent
            selectedRoles = Set(profile.soughtRoles ?? [])
            genderPreference = profile.genderPreference ?? "ANYONE"
            applicantMessage = profile.applicantMessage ?? ""
        }
        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        let body = SalonProfileUpdateRequest(
            seekingTalent: seekingTalent,
            soughtRoles: seekingTalent ? Array(selectedRoles) : nil,
            genderPreference: seekingTalent ? genderPreference : nil,
            applicantMessage: seekingTalent ? applicantMessage : nil
        )

        do {
            _ = try await APIClient.shared.patch("/api/salons/me", body: body, as: EmptyResponse.self)
            successMessage = appState.isSv ? "Sparat!" : "Saved!"
            HapticManager.medium()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte spara" : "Failed to save"
        }

        isSaving = false
    }
}

struct RoleOption: Identifiable {
    let id: String
    let sv: String
    let en: String
}
