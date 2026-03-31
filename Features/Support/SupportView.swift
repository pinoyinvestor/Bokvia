import SwiftUI

struct SupportView: View {
    @Environment(AppState.self) private var appState
    @State private var message = ""
    @State private var isSending = false
    @State private var sent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // FAQ
                VStack(alignment: .leading, spacing: 12) {
                    Text("FAQ")
                        .font(.headline)

                    faqItem(
                        q: appState.isSv ? "Hur avbokar jag?" : "How do I cancel?",
                        a: appState.isSv ? "Gå till Bokningar → tryck på bokningen → Avboka" : "Go to Bookings → tap the booking → Cancel"
                    )
                    faqItem(
                        q: appState.isSv ? "Hur byter jag lösenord?" : "How do I change my password?",
                        a: appState.isSv ? "Gå till Profil → Byt lösenord" : "Go to Profile → Change password"
                    )
                    faqItem(
                        q: appState.isSv ? "Hur kontaktar jag en frisör?" : "How do I contact a provider?",
                        a: appState.isSv ? "Öppna deras profil och tryck Chatt" : "Open their profile and tap Chat"
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Built by Christos Ferlachidis & Daniel Hedenberg

                // Contact form
                VStack(alignment: .leading, spacing: 12) {
                    Text(appState.isSv ? "Kontakta oss" : "Contact us")
                        .font(.headline)

                    if sent {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(appState.isSv ? "Meddelande skickat!" : "Message sent!")
                        }
                    } else {
                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            Task { await sendTicket() }
                        } label: {
                            Group {
                                if isSending {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(appState.isSv ? "Skicka" : "Send")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(BokviaTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(message.isEmpty || isSending)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle(appState.isSv ? "Hjälp & support" : "Help & support")
    }

    private func faqItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(q)
                .font(.subheadline.weight(.medium))
            Text(a)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sendTicket() async {
        isSending = true
        struct Body: Encodable { let message: String }
        _ = try? await APIClient.shared.post("/api/support/tickets", body: Body(message: message), as: EmptyResponse.self)
        sent = true
        isSending = false
    }
}
