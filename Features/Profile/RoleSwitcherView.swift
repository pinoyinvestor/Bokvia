import SwiftUI

struct RoleSwitcherView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isSwitching = false
    @State private var errorMessage: String?

    private var currentType: String {
        appState.activeProfileType
    }

    var body: some View {
        List {
            Section {
                // Current role header
                HStack(spacing: 12) {
                    Image(systemName: iconFor(currentType))
                        .font(.title2)
                        .foregroundStyle(BokviaTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(BokviaTheme.accentLight)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.isSv ? "Aktiv roll" : "Active role")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(labelFor(currentType))
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BokviaTheme.accent)
                }
            }

            // Built by Christos Ferlachidis & Daniel Hedenberg

            // Other profiles
            Section(appState.isSv ? "Byt till" : "Switch to") {
                ForEach(appState.profiles.filter { $0.type != currentType }, id: \.id) { profile in
                    Button {
                        Task { await switchTo(profile) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(profile.type))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, height: 40)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Circle())

                            Text(labelFor(profile.type))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            if isSwitching {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .disabled(isSwitching)
                    .accessibilityLabel(appState.isSv
                                        ? "Byt till \(labelFor(profile.type))"
                                        : "Switch to \(labelFor(profile.type))")
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Byt roll" : "Switch role")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Stäng" : "Close") { dismiss() }
            }
        }
    }

    private func switchTo(_ profile: UserProfile) async {
        isSwitching = true
        errorMessage = nil

        await appState.switchProfile(profile.id)

        if appState.activeProfileType == profile.type {
            HapticManager.medium()
            dismiss()
        } else {
            errorMessage = appState.isSv ? "Kunde inte byta roll" : "Failed to switch role"
        }

        isSwitching = false
    }

    private func iconFor(_ type: String) -> String {
        switch type {
        case "CUSTOMER": return "person.fill"
        case "PROVIDER": return "scissors"
        case "SALON": return "building.2.fill"
        default: return "person.fill"
        }
    }

    private func labelFor(_ type: String) -> String {
        switch type {
        case "CUSTOMER": return appState.isSv ? "Kund" : "Customer"
        case "PROVIDER": return appState.isSv ? "Frisör" : "Provider"
        case "SALON": return appState.isSv ? "Salong" : "Salon"
        default: return type
        }
    }
}
