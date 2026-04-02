import SwiftUI

struct WaitlistView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let providerId: String
    let serviceId: String
    let providerName: String
    let serviceName: String

    @State private var desiredDate = Date()
    @State private var timePreference: TimePreference = .any
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
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 36))
                    .foregroundStyle(BokviaTheme.accent)

                Text(appState.isSv ? "Ställ dig i kö" : "Join waitlist")
                    .font(.title3.bold())

                Text(appState.isSv
                    ? "Vi meddelar dig när en tid blir ledig hos \(providerName)"
                    : "We'll notify you when a slot opens with \(providerName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                // Service info
                HStack {
                    Image(systemName: "scissors")
                        .foregroundStyle(BokviaTheme.accent)
                    Text(serviceName)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.isSv ? "Önskat datum" : "Preferred date")
                        .font(.subheadline.weight(.medium))
                    DatePicker("", selection: $desiredDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(BokviaTheme.accent)
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Time preference
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.isSv ? "Tidsönskemål" : "Time preference")
                        .font(.subheadline.weight(.medium))
                    Picker("", selection: $timePreference) {
                        ForEach(TimePreference.allCases) { pref in
                            Text(pref.label(isSv: appState.isSv)).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                Task { await submitWaitlist() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Ställ mig i kö" : "Join waitlist")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(BokviaTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSubmitting)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .accessibilityLabel(appState.isSv ? "Ställ mig i kö" : "Join waitlist")
        }
        .navigationTitle(appState.isSv ? "Väntelista" : "Waitlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text(appState.isSv ? "Du står nu i kö!" : "You're on the waitlist!")
                .font(.title2.bold())
            Text(appState.isSv
                ? "Vi meddelar dig så snart en tid blir ledig"
                : "We'll notify you as soon as a slot opens")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

    private func submitWaitlist() async {
        isSubmitting = true
        errorMessage = nil
        let dateStr = DateFormatter.apiDate.string(from: desiredDate)
        let body = WaitlistRequest(
            providerId: providerId,
            serviceId: serviceId,
            desiredDate: dateStr,
            timePreference: timePreference.rawValue
        )
        do {
            _ = try await APIClient.shared.post("/api/waitlist", body: body, as: WaitlistResponse.self)
            HapticManager.success()
            isSuccess = true
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ansluta till väntelistan." : "Failed to join waitlist."
            HapticManager.error()
        }
        isSubmitting = false
    }
}
