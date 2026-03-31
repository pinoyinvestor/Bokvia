import SwiftUI

struct ChatDetailView: View {
    var chatId: String?
    var userId: String?
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var resolvedChatId: String?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var selectedMessage: ChatMessage?
    @State private var reportReason: ReportReason?
    @State private var showBlockedAlert = false
    @State private var otherUserId: String?

    enum ReportReason: String, CaseIterable, Identifiable {
        case spam, harassment, inappropriate, other
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                                    .contextMenu {
                                        if message.senderId != appState.currentUser?.id {
                                            Button(role: .destructive) {
                                                selectedMessage = message
                                                showReportSheet = true
                                            } label: {
                                                Label(appState.isSv ? "Rapportera meddelande" : "Report message", systemImage: "exclamationmark.bubble")
                                            }
                                            Button(role: .destructive) {
                                                selectedMessage = message
                                                showBlockConfirm = true
                                            } label: {
                                                Label(appState.isSv ? "Blockera användare" : "Block user", systemImage: "person.slash")
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                // Built by Christos Ferlachidis & Daniel Hedenberg

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }

                // Input bar
                HStack(spacing: 8) {
                    TextField(appState.isSv ? "Skriv meddelande..." : "Type a message...", text: $newMessage)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(newMessage.isEmpty ? .secondary : BokviaTheme.accent)
                    }
                    .disabled(newMessage.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await initChat()
            await loadMessages()
        }
        .confirmationDialog(
            appState.isSv ? "Varför rapporterar du?" : "Why are you reporting?",
            isPresented: $showReportSheet,
            titleVisibility: .visible
        ) {
            Button(appState.isSv ? "Spam" : "Spam") { reportReason = .spam; submitReport() }
            Button(appState.isSv ? "Trakasserier" : "Harassment") { reportReason = .harassment; submitReport() }
            Button(appState.isSv ? "Olämpligt innehåll" : "Inappropriate content") { reportReason = .inappropriate; submitReport() }
            Button(appState.isSv ? "Annat" : "Other") { reportReason = .other; submitReport() }
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) { selectedMessage = nil }
        }
        .confirmationDialog(
            appState.isSv ? "Blockera denna användare?" : "Block this user?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button(appState.isSv ? "Blockera" : "Block", role: .destructive) { blockUser() }
            Button(appState.isSv ? "Avbryt" : "Cancel", role: .cancel) { selectedMessage = nil }
        } message: {
            Text(appState.isSv ? "Du kommer inte längre att kunna ta emot meddelanden från denna person." : "You will no longer receive messages from this person.")
        }
        .alert(
            appState.isSv ? "Användare blockerad" : "User blocked",
            isPresented: $showBlockedAlert
        ) {
            Button("OK") { dismiss() }
        } message: {
            Text(appState.isSv ? "Du kommer inte längre se meddelanden från denna person." : "You will no longer see messages from this person.")
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isMine = message.senderId == appState.currentUser?.id
        return HStack {
            if isMine { Spacer() }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                if let text = message.text {
                    Text(text)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMine ? BokviaTheme.accent : Color(.secondarySystemBackground))
                        .foregroundStyle(isMine ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if let imageUrl = message.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text(timeLabel(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            if !isMine { Spacer() }
        }
    }

    private func timeLabel(_ isoDate: String) -> String {
        guard let date = DateFormatter.apiDateTime.date(from: isoDate) else { return "" }
        return DateFormatter.displayTime.string(from: date)
    }

    private func initChat() async {
        if let cid = chatId {
            resolvedChatId = cid
        } else if let uid = userId {
            struct Empty: Encodable {}
            do {
                let chat = try await APIClient.shared.post("/api/chat/start/\(uid)", body: Empty(), as: Chat.self)
                resolvedChatId = chat.id
            } catch {
                errorMessage = appState.isSv ? "Kunde inte starta chatten." : "Failed to start chat."
            }
        }
    }

    private func loadMessages() async {
        guard let cid = resolvedChatId else { isLoading = false; return }
        do {
            let result = try await APIClient.shared.get("/api/chat/\(cid)/messages", as: MessagesResponse.self)
            messages = result.messages.reversed()
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda meddelanden." : "Failed to load messages."
        }
        // Mark as read
        struct Empty: Encodable {}
        _ = try? await APIClient.shared.patch("/api/chat/\(cid)/read", body: Empty(), as: EmptyResponse.self)
        isLoading = false
    }

    private func sendMessage() async {
        guard let cid = resolvedChatId, !newMessage.isEmpty else { return }
        let text = newMessage
        newMessage = ""
        errorMessage = nil

        struct SendBody: Encodable { let text: String }
        do {
            let msg = try await APIClient.shared.post("/api/chat/\(cid)/messages", body: SendBody(text: text), as: ChatMessage.self)
            messages.append(msg)
            HapticManager.light()
        } catch {
            newMessage = text
            errorMessage = appState.isSv ? "Kunde inte skicka meddelandet." : "Failed to send message."
        }
    }

    private func submitReport() {
        guard let message = selectedMessage, let reason = reportReason else { return }
        Task {
            struct ReportBody: Encodable { let reason: String }
            _ = try? await APIClient.shared.post("/api/chat/messages/\(message.id)/report", body: ReportBody(reason: reason.rawValue), as: EmptyResponse.self)
            HapticManager.light()
            selectedMessage = nil
            reportReason = nil
        }
    }

    private func blockUser() {
        let uid = selectedMessage?.senderId ?? otherUserId
        guard let blockId = uid else { return }
        Task {
            struct Empty: Encodable {}
            _ = try? await APIClient.shared.post("/api/users/\(blockId)/block", body: Empty(), as: EmptyResponse.self)
            HapticManager.light()
            selectedMessage = nil
            showBlockedAlert = true
        }
    }
}
